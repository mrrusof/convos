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

ActiveRecord::Schema[8.1].define(version: 1) do
  create_table "comments", id: :string, force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.string "predecessor_id"
    t.integer "status", default: 0, null: false
    t.string "thread_id"
    t.datetime "updated_at", null: false
    t.string "user_id", null: false
    t.index ["predecessor_id"], name: "index_comments_on_predecessor_id", unique: true
    t.index ["thread_id"], name: "index_comments_on_thread_id", unique: true
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "comments", "comments", column: "predecessor_id"
end
