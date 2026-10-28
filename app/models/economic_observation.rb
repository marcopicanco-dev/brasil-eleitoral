class EconomicObservation < ApplicationRecord
  validates :year, uniqueness: true, numericality: { only_integer: true }
  validates :inflation, numericality: true
  validates :source_url, presence: true
end
