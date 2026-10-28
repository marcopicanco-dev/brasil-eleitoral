require "test_helper"

class AdministrationTest < ActiveSupport::TestCase
  setup { Rails.application.load_seed }

  test "catalog distinguishes people from periods of government" do
    assert_equal 8, President.count
    assert_equal 9, Administration.count
    assert_equal 2, President.find_by!(slug: "lula").administrations.count
    assert_equal 30, EconomicObservation.count
  end

  test "exercise dates cover transitions without overlaps or gaps" do
    Administration.chronological.each_cons(2) do |previous, current|
      assert_equal current.started_on, previous.ended_on + 1.day
    end
  end

  test "filters intersect search position and decade" do
    results = Administration.filtered(q: "Lula", position: "center_left", era: "2020")
    assert_equal ["lula-3"], results.pluck(:slug)
  end

  test "decade includes governments that started before it" do
    assert_equal ["fhc", "lula-1-2"], Administration.filtered(era: "2000").pluck(:slug)
  end

  test "SQL wildcard search is literal" do
    assert_empty Administration.filtered(q: "%")
    assert_empty Administration.filtered(q: "' OR 1=1 --")
  end

  test "unknown filter values do not create unsupported query conditions" do
    assert_equal 9, Administration.filtered(position: "unknown", era: "2000 OR 1=1").count
  end

  test "rejects a government ending before it starts" do
    government = Administration.find_by!(slug: "fhc")
    government.ended_on = government.started_on - 1.day
    assert_not government.valid?
    assert government.errors[:ended_on].any?
  end

  test "every government has policy context and primary sources" do
    Administration.find_each do |government|
      assert government.policies.any?
      assert government.sources.any?
      assert government.policies.all? { |policy| policy.values_at("name", "area", "description").all?(&:present?) }
      assert government.sources.all? { |source| URI(source.fetch("url")).scheme == "https" }
    end
  end

  test "seeds can be applied again without duplicate records" do
    assert_no_difference ["President.count", "Administration.count", "EconomicObservation.count"] do
      Rails.application.load_seed
    end
  end

  test "every government explains its accession with sourced elections" do
    Administration.find_each do |government|
      assert government.accession.fetch("summary").present?
      assert government.accession.fetch("elections").any?
      assert Administration::ACCESSION_METHODS.key?(government.accession.fetch("method"))
      government.accession.fetch("elections").each do |election|
        assert election.fetch("parties").any?
        assert election.fetch("sources").any?
        assert election.fetch("rounds").all? { |round| round.fetch("candidates").all? { |candidate| candidate["votes"].nil? ? candidate["status_note"].present? : candidate.fetch("votes").is_a?(Integer) && candidate.fetch("votes") >= 0 } }
      end
    end
  end

  test "vice presidential succession is not presented as a new popular election" do
    { "sarney" => [1985], "itamar" => [1989], "temer" => [2014] }.each do |slug, years|
      government = Administration.find_by!(slug: slug)
      assert_equal "succession", government.accession.fetch("method")
      assert_equal years, government.accession.fetch("elections").map { |election| election.fetch("year") }
    end
    election = Administration.find_by!(slug: "sarney").accession.fetch("elections").first
    assert_equal "indirect", election.fetch("kind")
    assert_equal 480, election.fetch("rounds").first.fetch("candidates").first.fetch("votes")
    assert_nil election.fetch("rounds").first.fetch("candidates").first["percentage"]
  end

  test "consecutive mandates preserve separate elections and coalitions" do
    government = Administration.find_by!(slug: "fhc")
    elections = government.accession.fetch("elections")
    assert_equal [1994, 1998], elections.map { |election| election.fetch("year") }
    assert elections.all? { |election| election.fetch("rounds").map { |round| round.fetch("number") } == [1] }
    assert_not_includes elections.first.fetch("parties"), "PSD"
    assert_includes elections.last.fetch("parties"), "PSD"
    assert_equal [2002, 2006], Administration.find_by!(slug: "lula-1-2").accession.fetch("elections").map { |election| election.fetch("year") }
    assert_equal [2010, 2014], Administration.find_by!(slug: "dilma").accession.fetch("elections").map { |election| election.fetch("year") }
  end

  test "all candidates account for the complete vote total and rounded percentages" do
    elections = Administration.all.flat_map { |government| government.accession.fetch("elections") }.uniq { |election| election.fetch("year") }
    elections.each do |election|
      election.fetch("rounds").each do |round|
        next unless round["valid_votes"]
        assert_equal round.fetch("valid_votes"), round.fetch("candidates").sum { |candidate| candidate["votes"] || 0 }
        round.fetch("candidates").each do |candidate|
          next if candidate["percentage"].nil?
          calculated = (candidate.fetch("votes") * 100.0 / round.fetch("valid_votes")).round(2)
          assert_in_delta calculated, candidate.fetch("percentage"), 0.001, "#{election.fetch("year")} turno #{round.fetch("number")}"
        end
      end
    end
  end

  test "first rounds contain every historical candidacy including the least voted" do
    elections = Administration.all.flat_map { |government| government.accession.fetch("elections") }.uniq { |election| election.fetch("year") }
    counts = { 1985 => 2, 1989 => 22, 1994 => 8, 1998 => 12, 2002 => 6, 2006 => 8, 2010 => 9, 2014 => 11, 2018 => 13, 2022 => 11 }
    elections.each do |election|
      candidates = election.fetch("rounds").first.fetch("candidates")
      assert_equal counts.fetch(election.fetch("year")), candidates.size
      assert_equal candidates.size, candidates.map { |candidate| candidate.fetch("name") }.uniq.size
      assert_equal candidates.map { |candidate| candidate["votes"] || 0 }.sort.reverse, candidates.map { |candidate| candidate["votes"] || 0 }
      next if election.fetch("kind") == "indirect"
      assert_equal candidates.size, candidates.map { |candidate| candidate.fetch("number") }.uniq.size
    end
  end

  test "second round contains only its finalists and one elected president" do
    elections = Administration.all.flat_map { |government| government.accession.fetch("elections") }.uniq { |election| election.fetch("year") }
    elections.each do |election|
      final = election.fetch("rounds").last.fetch("candidates")
      assert_equal 1, final.count { |candidate| candidate["elected"] }
      next unless election.fetch("rounds").size == 2
      assert_equal 2, final.size
      advanced = election.fetch("rounds").first.fetch("candidates").select { |candidate| candidate["advanced"] }
      assert_equal final.map { |candidate| candidate.fetch("number") }.sort, advanced.map { |candidate| candidate.fetch("number") }.sort
    end
  end

  test "uncomputed votes remain distinct from a genuine zero" do
    elections = Administration.find_by!(slug: "lula-1-2").accession.fetch("elections")
    rui = elections.find { |election| election.fetch("year") == 2006 }.fetch("rounds").first.fetch("candidates").find { |candidate| candidate.fetch("number") == 29 }
    assert_nil rui["votes"]
    assert_nil rui["percentage"]
    assert_match /indeferida/, rui.fetch("status_note")
    correa = Administration.find_by!(slug: "collor").accession.fetch("elections").first.fetch("rounds").first.fetch("candidates").last
    assert_equal 0, correa.fetch("votes")
    assert_match /inapto/, correa.fetch("status_note")
  end
end
