require "csv"

class DashboardController < ApplicationController
  before_action :load_timeline

  def index
    @administrations = Administration.filtered(params)
    @observations = EconomicObservation.order(:year).to_a
  end

  def presidents
    @administrations = Administration.filtered(params)
  end

  def show
    @administration = Administration.includes(:president).find_by!(slug: params[:slug])
  end

  def compare
    @left = @timeline.find { |government| government.slug == params[:left] } || @timeline.find { |government| government.slug == "fhc" } || @timeline.first
    @right = @timeline.find { |government| government.slug == params[:right] } || @timeline.find { |government| government.slug == "lula-1-2" } || @timeline.last
  end

  def methodology; end

  def export
    data = CSV.generate(col_sep: ";") do |csv|
      csv << ["Presidente", "Governo", "Início", "Fim", "Partido no governo", "Posição (síntese editorial)", "Economia", "Políticas públicas", "Fontes"]
      Administration.filtered(params).each do |government|
        csv << [government.president.name, government.label, government.started_on, government.ended_on,
          government.party, government.position_label, government.economic_policy,
          government.policies.map { |policy| policy.fetch("name") }.join(" | "),
          government.sources.map { |source| source.fetch("url") }.join(" | ")]
      end
    end
    send_data "\uFEFF#{data}", filename: "brasil-eleitoral-governos.csv", type: "text/csv; charset=utf-8"
  end

  private

  def load_timeline
    @timeline = Administration.includes(:president).chronological.to_a
    @president_count = @timeline.map(&:president_id).uniq.count
  end
end
