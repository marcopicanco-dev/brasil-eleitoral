require "yaml"
require "json"

catalog = YAML.safe_load_file(Rails.root.join("db/data/administrations.yml"))
elections = YAML.safe_load_file(Rails.root.join("db/data/elections.yml"))
  .fetch("elections").index_by { |election| election.fetch("year") }
accessions = YAML.safe_load_file(Rails.root.join("db/data/accessions.yml")).fetch("accessions")
ApplicationRecord.transaction do
  catalog.fetch("presidents").each do |attributes|
    President.find_or_initialize_by(slug: attributes.fetch("slug")).update!(attributes)
  end
  catalog.fetch("administrations").each do |attributes|
    attributes = attributes.dup
    president = President.find_by!(slug: attributes.delete("president"))
    accession = accessions.fetch(attributes.fetch("slug")).deep_dup
    accession["elections"] = accession.delete("election_years").map { |year| elections.fetch(year) }
    attributes["accession"] = accession
    Administration.find_or_initialize_by(slug: attributes.fetch("slug")).update!(attributes.merge("president" => president))
  end
  JSON.parse(Rails.root.join("db/data/ipca.json").read).each do |attributes|
    EconomicObservation.find_or_initialize_by(year: attributes.fetch("year")).update!(attributes)
  end
end
puts "Base carregada: #{President.count} presidentes, #{Administration.count} governos e #{EconomicObservation.count} observações do IPCA." unless Rails.env.test?
