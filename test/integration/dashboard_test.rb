require "test_helper"
require "csv"

class DashboardTest < ActionDispatch::IntegrationTest
  setup { Rails.application.load_seed }

  test "dashboard presents all governments and sourced inflation data" do
    get root_path
    assert_response :success
    assert_select "html[lang='pt-BR']"
    assert_select "h1", "O Brasil, governo a governo."
    assert_select ".governments-table tbody tr", 9
    assert_select ".timeline-item", 9
    assert_select ".chart-point", 30
    assert_select ".chart-summary strong", /4,83/
  end

  test "presidents can be searched and filtered" do
    get presidents_path, params: { q: "Lula", position: "center_left", era: "2020" }
    assert_response :success
    assert_select ".governments-table tbody tr", 1
    assert_select ".president-cell small", "Lula · 3º mandato"
  end

  test "empty searches explain how to recover" do
    get root_path, params: { q: "nenhum-presidente-com-esse-nome" }
    assert_response :success
    assert_select ".empty-state", /Nenhum governo encontrado/
  end

  test "all government profiles render and expose sources" do
    Administration.find_each do |government|
      get administration_path(government)
      assert_response :success
      assert_select ".sources-list a", government.sources.size
      assert_select ".policy-list h4", government.policies.size
    end
  end

  test "unknown government returns 404" do
    get administration_path("inexistente")
    assert_response :not_found
  end

  test "comparison accepts the selected governments" do
    get compare_path, params: { left: "sarney", right: "bolsonaro" }
    assert_response :success
    assert_select ".comparison-grid .profile-top h2", text: "José Sarney"
    assert_select ".comparison-grid .profile-top h2", text: "Jair Bolsonaro"
    assert_select "select#left option[selected][value='sarney']"
  end

  test "CSV export respects filters and is readable as UTF-8" do
    get export_path, params: { q: "Lula", era: "2020" }
    assert_response :success
    assert_includes response.media_type, "text/csv"
    assert_includes response.headers["Content-Disposition"], "brasil-eleitoral-governos.csv"
    records = CSV.parse(response.body.delete_prefix("\uFEFF"), col_sep: ";", headers: true)
    assert_equal 1, records.size
    assert_equal "Lula · 3º mandato", records.first["Governo"]
    assert_includes records.first["Fontes"], "https://"
  end

  test "methodology documents exercise dates and editorial classifications" do
    get methodology_path
    assert_response :success
    assert_select "h3", "Datas e transições"
    assert_select ".prose-content", /sínteses editoriais/
    assert_select ".source-link[href*='scielo.br']"
  end
end
