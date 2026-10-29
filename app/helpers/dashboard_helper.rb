module DashboardHelper
  ICONS = {
    grid: '<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
    users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2m20 0v-2a4 4 0 0 0-3-3.87"/><circle cx="9" cy="7" r="4"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
    timeline: '<path d="M4 6h16M4 18h16M8 6v12m8-12v12"/><circle cx="8" cy="9" r="2"/><circle cx="16" cy="15" r="2"/>',
    chart: '<path d="M3 3v18h18M7 14l4-5 4 3 5-7"/>',
    book: '<path d="M12 7v14m0-14C9 4 5 3 2 4v15c3-1 7 0 10 2m0-14c3-3 7-4 10-3v15c-3-1-7 0-10 2"/>',
    compare: '<path d="M4 7h15m-4-4 4 4-4 4M20 17H5m4-4-4 4 4 4"/>',
    download: '<path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5"/>',
    arrow: '<path d="M5 12h14m-5-5 5 5-5 5"/>',
    search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
    chevron: '<path d="m9 5 7 7-7 7"/>',
    external: '<path d="M14 3h7v7m0-7L10 14M10 3H3v18h18v-7"/>',
    menu: '<path d="M3 6h18M3 12h18M3 18h18"/>',
    close: '<path d="m6 6 12 12M6 18 18 6"/>',
    flag: '<path d="M4 22V3m0 0c5-4 11 4 16 0v11c-5 4-11-4-16 0"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6m0-11v1"/>',
    calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 11h18"/>'
  }.freeze

  def icon(name, css: "")
    tag.svg(ICONS.fetch(name).html_safe, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 1.7, "stroke-linecap": "round",
      "stroke-linejoin": "round", class: "icon #{css}", "aria-hidden": true)
  end

  def position_badge(government)
    tag.span(government.position_label, class: "badge position-#{government.position}")
  end

  def nav_link(label, path, symbol, active: false)
    link_to path, class: "nav-link #{'active' if active}", aria: { current: active ? "page" : nil } do
      safe_join([icon(symbol), tag.span(label), (tag.span("08", class: "nav-count") if symbol == :users)].compact)
    end
  end

  def inflation_points(observations)
    return [] if observations.empty?
    observations.each_with_index.map do |observation, index|
      [48 + index * 680.0 / [observations.size - 1, 1].max, 207 - observation.inflation.to_f / 25 * 175]
    end
  end

  def chart_coordinate(value) = format("%.2f", value)

  def political_tenure_series(governments, through: Date.current, include_center: false, observed_through: nil)
    origin = Date.new(1985, 3, 15)
    return [] if through < origin

    dates = [origin] + (1985..through.year).map { |year| [Date.new(year, 12, 31), through].min }
    dates << observed_through if observed_through && observed_through.between?(origin, through)
    dates.uniq.sort.map do |date|
      totals = { right: 0.0, left: 0.0 }
      governments.each do |government|
        field = { "right" => :right, "center_right" => :right, "center_left" => :left }[government.position]
        field = :right if include_center && government.position == "center"
        next unless field

        first = [government.started_on, origin].max
        last = [government.ended_on || through, date].min
        # The origin is the zero point; later samples include the whole cutoff day.
        days = date == origin ? 0 : [(last - first).to_i + 1, 0].max
        totals[field] += days / 365.2425
      end
      totals.merge(date: date)
    end
  end
end
