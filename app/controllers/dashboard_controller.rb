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
      csv << ["Presidente", "Governo", "Início", "Fim", "Partido no governo", "Posição (síntese editorial)", "Como chegou ao poder", "Resultados eleitorais", "Alianças eleitorais", "Economia", "Políticas públicas", "Fontes"]
      Administration.filtered(params).each do |government|
        elections = government.accession.fetch("elections", [])
        electoral_sources = government.accession.fetch("sources", []) + elections.flat_map { |election| election.fetch("sources") }
        csv << [government.president.name, government.label, government.started_on, government.ended_on,
          government.party, government.position_label, government.accession["summary"],
          electoral_results_for(elections),
          elections.map { |election| "#{election.fetch("year")}: #{election.fetch("coalition")} (#{election.fetch("parties").join(', ')})" }.join(" | "),
          government.economic_policy,
          government.policies.map { |policy| policy.fetch("name") }.join(" | "),
          (government.sources + electoral_sources).map { |source| source.fetch("url") }.uniq.join(" | ")]
      end
    end
    send_data "\uFEFF#{data}", filename: "brasil-eleitoral-governos.csv", type: "text/csv; charset=utf-8"
  end

  private

  def electoral_results_for(elections)
    elections.map do |election|
      election.fetch("rounds").map do |round|
        turn = election.fetch("kind") == "indirect" ? "Colégio Eleitoral" : "#{round.fetch("number")}º turno"
        candidates = round.fetch("candidates").map do |candidate|
          percentage = candidate["percentage"] ? " (#{format('%.2f', candidate.fetch("percentage")).tr('.', ',')}%)" : ""
          votes = candidate["votes"].nil? ? "votos não computados" : "#{candidate.fetch("votes")} votos"
          status = candidate["status_note"].present? ? " [#{candidate.fetch("status_note")}]" : ""
          "#{candidate.fetch("name")}: #{votes}#{percentage}#{status}"
        end.join("; ")
        "#{election.fetch("year")} · #{turn}: #{candidates}"
      end.join(" / ")
    end.join(" | ")
  end

  def load_timeline
    @timeline = Administration.includes(:president).chronological.to_a
    @president_count = @timeline.map(&:president_id).uniq.count
  end
end
