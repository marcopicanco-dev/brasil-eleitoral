class AddAccessionToAdministrations < ActiveRecord::Migration[8.1]
  def change
    add_column :administrations, :accession, :jsonb, default: {}, null: false
  end
end
