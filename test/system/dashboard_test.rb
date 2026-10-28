require "application_system_test_case"

class DashboardSystemTest < ApplicationSystemTestCase
  test "filter and open a president profile through Turbo" do
    visit presidents_path
    fill_in "Buscar presidente, partido ou agenda", with: "Lula"
    select "Centro-esquerda", from: "Posição política"
    select "Década de 2020", from: "Década em exercício"
    click_on "Filtrar"
    assert_selector ".governments-table tbody tr", count: 1
    click_on "Explorar governo Lula · 3º mandato"
    assert_selector "h1", text: "Lula · 3º mandato"
    assert_text "Novo arcabouço fiscal"
    assert_selector ".sources-list a", count: 3
  end

  test "comparison changes the displayed governments" do
    visit compare_path
    select "José Sarney (1985–1990)", from: "PRIMEIRO GOVERNO"
    select "Jair Bolsonaro (2019–2022)", from: "SEGUNDO GOVERNO"
    click_on "Comparar", exact: true
    assert_selector ".comparison-grid .profile-top h2", text: "José Sarney"
    assert_selector ".comparison-grid .profile-top h2", text: "Jair Bolsonaro"
  end

  test "mobile navigation opens closes and remains within the viewport" do
    page.current_window.resize_to(390, 844)
    visit root_path
    assert_selector "h1", text: "O Brasil, governo a governo."
    assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
    click_on "Abrir menu"
    assert_selector ".sidebar.is-open"
    page.driver.browser.action.move_to_location(350, 120).click.perform
    assert_no_selector ".sidebar.is-open"
    click_on "Abrir menu"
    within ".sidebar" do
      click_on "Presidentes"
    end
    assert_selector "h1", text: "Quem governou o Brasil."
    assert_no_selector ".sidebar.is-open"
  ensure
    page.current_window.resize_to(1440, 1100)
  end
end
