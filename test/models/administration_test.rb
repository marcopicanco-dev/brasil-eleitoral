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
end
