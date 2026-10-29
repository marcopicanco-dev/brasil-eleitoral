require "test_helper"

class CandidatePortraitTest < ActiveSupport::TestCase
  test "portraits have local image files and official provenance" do
    CandidatePortrait::RECORDS.each do |name, portrait|
      file = Rails.root.join("app/assets/images", portrait.fetch("asset"))
      assert file.file?, "Missing portrait for #{name}"
      header = file.binread(8)
      assert header.start_with?("\xFF\xD8\xFF".b, "\x89PNG".b), "Invalid image for #{name}"
      assert_match(/\Ahttps:\/\/(?:[^\/]+\.)?(?:tse\.jus\.br|camara\.leg\.br|senado\.leg\.br|gov\.br)\//, portrait.fetch("source_url"))
    end
  end

  test "all presidents have portraits and Lula resolves by full name" do
    Rails.application.load_seed
    President.find_each do |president|
      assert CandidatePortrait.for_name(president.name), "Missing portrait for #{president.name}"
    end
    assert_equal CandidatePortrait.for_name("Lula"), CandidatePortrait.for_name("Luiz Inácio Lula da Silva")
    assert_nil CandidatePortrait.for_name("Sem foto identificada")
  end
end
