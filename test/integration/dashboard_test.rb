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
    assert_select "#esquerda-direita h2", "Esquerda versus Direita"
    assert_select ".tenure-line[stroke='#2563eb']", 1
    assert_select ".tenure-line[stroke='#dc2626']", 1
    assert_select ".tenure-projection", 2
    assert_select ".tenure-table tbody tr:last-child", /04\/01\/2031.*projeção/
    assert_select ".tenure-legend", /Centro, centro-direita e direita/
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
    assert_includes records.first["Como chegou ao poder"], "2022"
    assert_includes records.first["Resultados eleitorais"], "60345999 votos (50,90%)"
    assert_includes records.first["Alianças eleitorais"], "Brasil da Esperança"
    assert_includes records.first["Resultados eleitorais"], "Simone Tebet: 4915423 votos"
    assert_includes records.first["Resultados eleitorais"], "Constituinte Eymael: 16604 votos"
  end

  test "methodology documents exercise dates and editorial classifications" do
    get methodology_path
    assert_response :success
    assert_select "h3", "Datas e transições"
    assert_select ".prose-content", /sínteses editoriais/
    assert_select ".source-link[href*='scielo.br']"
  end

  test "profiles display election results and formal alliances for every government" do
    Administration.find_each do |government|
      get administration_path(government)
      assert_response :success
      assert_select ".accession-section h3", "Como chegou ao poder?"
      assert_select ".election-card", government.accession.fetch("elections").size
      assert_select ".alliance-parties", government.accession.fetch("elections").size
      assert_select ".election-sources a"
    end
  end

  test "Sarney profile distinguishes the electoral college from popular votes" do
    get administration_path("sarney")
    assert_select ".accession-method", /Sucessão pela Vice-Presidência/
    assert_select ".election-card", /Não houve eleição popular nem segundo turno/
    assert_select ".candidate-result strong", count: 0
    assert_select ".candidate-result", /480 votos no Colégio/
  end

  test "comparison includes separate reelection histories" do
    get compare_path, params: { left: "fhc", right: "lula-1-2" }
    assert_select ".accession-section", 2
    assert_select ".election-card", 4
    assert_select ".election-heading h4", "Eleição de 1998"
    assert_select ".election-heading h4", "Eleição de 2006"
  end

  test "profiles show every first round candidate and only second round finalists" do
    get administration_path("collor")
    assert_select ".election-card[data-election-year='1989'] .election-round[data-round='1'] .election-candidate", count: 22
    assert_select ".election-card[data-election-year='1989'] .election-round[data-round='2'] .election-candidate", count: 2
    assert_select ".candidate-name", /Leonel Brizola/
    assert_select ".candidate-name", /Armando Corrêa/
    get administration_path("lula-3")
    assert_select ".election-round[data-round='1'] .election-candidate", count: 11
    assert_select ".election-round[data-round='2'] .election-candidate", count: 2
    assert_select ".candidate-name", /Simone Tebet/
    assert_select ".candidate-name", /Constituinte Eymael/
  end

  test "profile and CSV explain the candidacy with uncomputed votes" do
    get administration_path("lula-1-2")
    assert_select ".election-card[data-election-year='2006'] .election-round[data-round='1'] .election-candidate", count: 8
    assert_select ".candidate-status-note", /indeferida/
    assert_select ".candidate-result", /Votos não computados/
    get export_path, params: { q: "Lula", era: "2000" }
    records = CSV.parse(response.body.delete_prefix("\uFEFF"), col_sep: ";", headers: true)
    assert_includes records.first["Resultados eleitorais"], "Rui Costa Pimenta: votos não computados"
  end
end
