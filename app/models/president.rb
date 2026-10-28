class President < ApplicationRecord
  has_many :administrations, dependent: :restrict_with_exception
  validates :name, :short_name, :initials, :slug, presence: true
  validates :slug, uniqueness: true
end
