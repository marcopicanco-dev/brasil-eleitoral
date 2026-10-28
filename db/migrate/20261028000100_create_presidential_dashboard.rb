class CreatePresidentialDashboard < ActiveRecord::Migration[8.1]
  def change
    create_table :presidents do |t|
      t.string :name, null: false
      t.string :short_name, null: false
      t.string :slug, null: false
      t.string :initials, null: false
      t.timestamps
    end
    add_index :presidents, :slug, unique: true

    create_table :administrations do |t|
      t.references :president, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :label, null: false
      t.date :started_on, null: false
      t.date :ended_on
      t.string :party, null: false
      t.string :position, null: false
      t.string :economic_headline, null: false
      t.text :economic_policy, null: false
      t.text :political_context, null: false
      t.text :notes
      t.jsonb :policies, null: false, default: []
      t.jsonb :milestones, null: false, default: []
      t.jsonb :sources, null: false, default: []
      t.timestamps
    end
    add_index :administrations, :slug, unique: true
    add_index :administrations, :started_on
    add_index :administrations, :position
    add_check_constraint :administrations, "ended_on IS NULL OR ended_on >= started_on", name: "administration_date_order"

    create_table :economic_observations do |t|
      t.integer :year, null: false
      t.decimal :inflation, precision: 7, scale: 2, null: false
      t.string :source_url, null: false
      t.timestamps
    end
    add_index :economic_observations, :year, unique: true
  end
end
