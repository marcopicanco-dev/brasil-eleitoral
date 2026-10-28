class Administration < ApplicationRecord
  POSITIONS = {
    "center_left" => "Centro-esquerda",
    "center" => "Centro",
    "center_right" => "Centro-direita",
    "right" => "Direita"
  }.freeze

  ACCESSION_METHODS = {
    "direct_election" => "Eleição direta",
    "succession" => "Sucessão pela Vice-Presidência"
  }.freeze

  belongs_to :president
  scope :chronological, -> { order(:started_on) }
  validates :slug, :label, :party, :started_on, :economic_headline,
    :economic_policy, :political_context, presence: true
  validates :slug, uniqueness: true
  validates :position, inclusion: { in: POSITIONS.keys }
  validate :end_follows_start
  validate :accession_structure

  def position_label = POSITIONS.fetch(position)
  def period = "#{started_on.year}–#{ended_on&.year || 'atual'}"
  def to_param = slug
  def accession_method_label = ACCESSION_METHODS.fetch(accession.fetch("method"))

  def self.filtered(params)
    records = includes(:president).chronological
    if params[:q].present?
      term = "%#{sanitize_sql_like(params[:q].to_s.strip.first(100))}%"
      records = records.joins(:president).where(
        "presidents.name ILIKE :term OR administrations.label ILIKE :term OR administrations.party ILIKE :term OR administrations.economic_headline ILIKE :term", term: term
      )
    end
    records = records.where(position: params[:position]) if POSITIONS.key?(params[:position])
    if params[:era].to_s.match?(/\A(1980|1990|2000|2010|2020)\z/)
      start_date = Date.new(params[:era].to_i)
      records = records.where("started_on < ? AND (ended_on IS NULL OR ended_on >= ?)", start_date + 10.years, start_date)
    end
    records
  end

  private

  def accession_structure
    return if accession.blank?

    valid = accession.is_a?(Hash) &&
      ACCESSION_METHODS.key?(accession["method"]) &&
      accession["summary"].is_a?(String) && accession["summary"].present? &&
      accession["elections"].is_a?(Array) && accession["elections"].any? &&
      accession["sources"].is_a?(Array)
    errors.add(:accession, "deve informar a forma de chegada ao poder, eleições e fontes") unless valid
  end

  def end_follows_start
    errors.add(:ended_on, "deve ser posterior ao início") if ended_on && started_on && ended_on < started_on
  end
end
