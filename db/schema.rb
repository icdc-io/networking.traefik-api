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

ActiveRecord::Schema.define(version: 2023_02_17_124807) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificates", force: :cascade do |t|
    t.text "cert_path"
    t.text "key_path"
    t.text "ca_path"
    t.text "dest_ca_path"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "owner"
    t.string "name"
    t.string "account"
  end

  create_table "cloud_gateways", force: :cascade do |t|
    t.string "name"
    t.string "account"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "cloudgw_id"
  end

  create_table "healthchecks", force: :cascade do |t|
    t.string "path", default: "/"
    t.string "scheme"
    t.integer "port"
    t.integer "interval", default: 30
    t.integer "timeout", default: 3
    t.string "hostname"
    t.jsonb "headers"
    t.string "method", default: "GET"
    t.boolean "follow_redirects", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "route_id"
    t.index ["route_id"], name: "index_healthchecks_on_route_id"
  end

  create_table "routes", force: :cascade do |t|
    t.string "name"
    t.string "hostname"
    t.string "path"
    t.integer "target_port"
    t.string "insecure"
    t.string "tls_termination"
    t.jsonb "labels"
    t.bigint "cloud_gateway_id", null: false
    t.bigint "certificate_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "owner"
    t.string "source_proto"
    t.string "destination_proto"
    t.string "ip_version"
    t.boolean "healthcheck_enabled", default: false
    t.index ["certificate_id"], name: "index_routes_on_certificate_id"
    t.index ["cloud_gateway_id"], name: "index_routes_on_cloud_gateway_id"
  end

  create_table "routes_services", force: :cascade do |t|
    t.bigint "route_id"
    t.bigint "service_id"
    t.string "balance_type"
    t.float "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.index ["route_id"], name: "index_routes_services_on_route_id"
    t.index ["service_id"], name: "index_routes_services_on_service_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.bigint "ext_id"
    t.string "ipaddresses"
    t.string "owner"
    t.string "account"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "weights", force: :cascade do |t|
    t.bigint "route_id"
    t.bigint "service_id"
    t.integer "weight"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["route_id"], name: "index_weights_on_route_id"
    t.index ["service_id"], name: "index_weights_on_service_id"
  end

  add_foreign_key "healthchecks", "routes"
  add_foreign_key "routes", "certificates"
  add_foreign_key "routes", "cloud_gateways"
end
