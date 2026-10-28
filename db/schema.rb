# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_28_000100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "administrations", force: :cascade do |t|
    t.bigint "president_id", null: false
    t.string "slug", null: false
    t.string "label", null: false
    t.date "started_on", null: false
    t.date "ended_on"
    t.string "party", null: false
    t.string "position", null: false
    t.string "economic_headline", null: false
    t.text "economic_policy", null: false
    t.text "political_context", null: false
    t.text "notes"
    t.jsonb "policies", default: [], null: false
    t.jsonb "milestones", default: [], null: false
    t.jsonb "sources", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_administrations_on_position"
    t.index ["president_id"], name: "index_administrations_on_president_id"
    t.index ["slug"], name: "index_administrations_on_slug", unique: true
    t.index ["started_on"], name: "index_administrations_on_started_on"
    t.check_constraint "ended_on IS NULL OR ended_on >= started_on", name: "administration_date_order"
  end

  create_table "economic_observations", force: :cascade do |t|
    t.integer "year", null: false
    t.decimal "inflation", precision: 7, scale: 2, null: false
    t.string "source_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year"], name: "index_economic_observations_on_year", unique: true
  end

  create_table "presidents", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", null: false
    t.string "slug", null: false
    t.string "initials", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_presidents_on_slug", unique: true
  end

  add_foreign_key "administrations", "presidents"
end
