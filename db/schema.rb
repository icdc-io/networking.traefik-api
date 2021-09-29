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

ActiveRecord::Schema.define(version: 2021_09_20_145712) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificates", force: :cascade do |t|
    t.text "cert"
    t.text "key"
    t.text "ca"
    t.text "dest_ca"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "cloud_gateways", force: :cascade do |t|
    t.string "name"
    t.string "account"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "routes", force: :cascade do |t|
    t.string "name"
    t.string "hostname"
    t.string "path"
    t.decimal "target_port"
    t.string "insecure"
    t.string "tls_termination"
    t.jsonb "labels"
    t.bigint "cloud_gateway_id", null: false
    t.bigint "certificate_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["certificate_id"], name: "index_routes_on_certificate_id"
    t.index ["cloud_gateway_id"], name: "index_routes_on_cloud_gateway_id"
  end

  create_table "routes_services", id: false, force: :cascade do |t|
    t.bigint "route_id", null: false
    t.bigint "service_id", null: false
    t.index ["route_id"], name: "index_routes_services_on_route_id"
    t.index ["service_id"], name: "index_routes_services_on_service_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.integer "ext_id"
    t.string "ipaddresses"
    t.string "owner"
    t.string "account"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "routes", "certificates"
  add_foreign_key "routes", "cloud_gateways"
end
