require "test_helper"

class DashboardHelperTest < ActionView::TestCase
  test "bilateral projection accounts for the entire period and preserves historical cutoff" do
    Rails.application.load_seed
    governments = Administration.chronological.to_a
    cutoff = Date.new(2026, 10, 29)
    series = political_tenure_series(governments, through: Date.new(2031, 1, 4), include_center: true, observed_through: cutoff)
    historical = political_tenure_series(governments, through: cutoff, include_center: true)
    assert_equal historical.last, series.find { |row| row[:date] == cutoff }
    last = series.last
    total = ((Date.new(2031, 1, 4) - Date.new(1985, 3, 15)).to_i + 1) / 365.2425
    assert_in_delta total, last[:left] + last[:right]
    assert_in_delta 21.37, last[:left], 0.02
    assert_in_delta 24.44, last[:right], 0.02
  end

  test "tenure counts inclusive days on each side of a transition and excludes center" do
    government = Struct.new(:started_on, :ended_on, :position)
    governments = [
      government.new(Date.new(1985, 3, 15), Date.new(1985, 12, 31), "center"),
      government.new(Date.new(1986, 1, 1), Date.new(1986, 5, 11), "center_right"),
      government.new(Date.new(1986, 5, 12), nil, "center_left")
    ]

    series = political_tenure_series(governments, through: Date.new(1986, 12, 31))
    assert_equal Date.new(1985, 3, 15), series.first[:date]
    assert_equal 0, series.first[:right]
    assert_equal 0, series.first[:left]
    assert_equal 0, series[1][:right]
    assert_in_delta 131 / 365.2425, series.last[:right]
    assert_in_delta 234 / 365.2425, series.last[:left]
  end

  test "open government stops at cutoff and future governments add no time" do
    government = Struct.new(:started_on, :ended_on, :position)
    governments = [
      government.new(Date.new(2023, 1, 1), nil, "center_left"),
      government.new(Date.new(2027, 1, 1), nil, "right")
    ]
    series = political_tenure_series(governments, through: Date.new(2024, 2, 29))
    assert_equal Date.new(2024, 2, 29), series.last[:date]
    assert_in_delta 425 / 365.2425, series.last[:left]
    assert_equal 0, series.last[:right]
  end
end
