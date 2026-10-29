class CandidatePortrait
  RECORDS = JSON.parse(Rails.root.join("config/candidate_portraits.json").read).freeze
  ALIASES = {
    "Fernando Collor de Mello" => "Fernando Collor",
    "Luiz Inácio Lula da Silva" => "Lula",
    "José Maria de Almeida" => "Zé Maria",
    "José Maria Eymael" => "Constituinte Eymael"
  }.freeze

  def self.for_name(name)
    RECORDS[name] || RECORDS[ALIASES[name]]
  end
end
