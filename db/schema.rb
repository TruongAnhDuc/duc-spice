# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 38) do

  create_table "addresses", :force => true do |t|
    t.string "name",     :limit => 64
    t.string "address",  :limit => 128
    t.string "city",     :limit => 128
    t.string "postcode", :limit => 32
    t.string "country",  :limit => 64
    t.string "phone_no", :limit => 32
  end

  create_table "categories", :force => true do |t|
    t.integer "parent_id"
    t.string  "name",              :limit => 64
    t.string  "filename",          :limit => 48
    t.string  "path"
    t.text    "description"
    t.string  "title",             :limit => 128
    t.text    "meta_keywords"
    t.text    "meta_description"
    t.integer "sequence",                         :default => 0, :null => false
    t.text    "short_description"
  end

  add_index "categories", ["parent_id"], :name => "parent_id"

  create_table "categories_features", :id => false, :force => true do |t|
    t.integer "category_id", :default => 0, :null => false
    t.integer "feature_id",  :default => 0, :null => false
  end

  add_index "categories_features", ["category_id", "feature_id"], :name => "categories_features_category_id_index", :unique => true

  create_table "categories_products", :id => false, :force => true do |t|
    t.integer "category_id", :default => 0, :null => false
    t.integer "product_id",  :default => 0, :null => false
  end

  add_index "categories_products", ["category_id"], :name => "category_id"
  add_index "categories_products", ["product_id"], :name => "product_id"

  create_table "countries", :force => true do |t|
    t.string  "name",             :limit => 64, :default => "", :null => false
    t.integer "shipping_zone_id",               :default => 0,  :null => false
  end

  add_index "countries", ["name"], :name => "country_name"
  add_index "countries", ["shipping_zone_id"], :name => "country_zone"

  create_table "currencies", :force => true do |t|
    t.string   "name",          :limit => 32
    t.string   "abbreviation",  :limit => 8
    t.string   "symbol",        :limit => 16, :default => "$",   :null => false
    t.float    "exchange_rate", :limit => 6,  :default => 1.0,   :null => false
    t.datetime "updated_at"
    t.integer  "update_every",                :default => 86400, :null => false
    t.integer  "is_default",                  :default => 0,     :null => false
  end

  add_index "currencies", ["abbreviation"], :name => "abbr"

  create_table "draft_items", :force => true do |t|
    t.integer "draft_id",        :default => 0, :null => false
    t.integer "product_id",      :default => 0, :null => false
    t.integer "option_value_id", :default => 0, :null => false
    t.integer "quantity",        :default => 0, :null => false
  end

  create_table "drafts", :force => true do |t|
    t.integer  "user_id",    :default => 0,    :null => false
    t.datetime "created_at"
    t.boolean  "priced",     :default => true, :null => false
  end

  create_table "features", :force => true do |t|
    t.integer "product_id",  :default => 0, :null => false
    t.text    "description"
    t.integer "weighting",   :default => 0, :null => false
    t.boolean "all_levels"
    t.date    "until"
    t.boolean "in_layout"
  end

  add_index "features", ["product_id"], :name => "features_product_id_index"

  create_table "features_static_pages", :id => false, :force => true do |t|
    t.integer "feature_id",     :default => 0, :null => false
    t.integer "static_page_id", :default => 0, :null => false
  end

  add_index "features_static_pages", ["feature_id", "static_page_id"], :name => "features_static_pages_feature_id_index", :unique => true

  create_table "images", :force => true do |t|
    t.string  "type",          :limit => 64
    t.integer "product_id",                  :default => 0,  :null => false
    t.integer "thumbnail_of"
    t.string  "filename",                    :default => "", :null => false
    t.string  "content_type",  :limit => 64
    t.binary  "data"
    t.integer "width",                       :default => 0,  :null => false
    t.integer "height",                      :default => 0,  :null => false
    t.text    "caption"
    t.integer "display_order",               :default => 0,  :null => false
  end

  add_index "images", ["product_id"], :name => "product_id"
  add_index "images", ["thumbnail_of"], :name => "thumbnail_of"

  create_table "line_item_option_values", :id => false, :force => true do |t|
    t.integer "line_item_id",                                                    :null => false
    t.integer "option_value_id",                                                 :null => false
    t.decimal "extra_cost",      :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.decimal "extra_weight",    :precision => 8,  :scale => 3, :default => 0.0, :null => false
  end

  create_table "line_items", :force => true do |t|
    t.integer "product_id",                                     :default => 0,     :null => false
    t.integer "order_id",                                       :default => 0,     :null => false
    t.integer "quantity",                                       :default => 1,     :null => false
    t.decimal "unit_price",      :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.text    "options"
    t.decimal "unit_weight",     :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.float   "discount",                                       :default => 0.0,   :null => false
    t.boolean "discount_is_abs",                                :default => false, :null => false
    t.boolean "wholesale",                                      :default => false, :null => false
  end

  add_index "line_items", ["product_id"], :name => "product_id"
  add_index "line_items", ["order_id"], :name => "order_id"

  create_table "nested_category", :primary_key => "category_id", :force => true do |t|
    t.string  "name", :limit => 20, :null => false
    t.integer "lft",                :null => false
    t.integer "rgt",                :null => false
  end

  create_table "newsletter_signups", :force => true do |t|
    t.string "email",      :limit => 128
    t.string "first_name", :limit => 32
    t.string "last_name",  :limit => 32
  end

  create_table "option_values", :force => true do |t|
    t.integer "option_id",                                           :default => 0,     :null => false
    t.text    "value"
    t.integer "position",                                            :default => 0,     :null => false
    t.float   "extra_cost",                                          :default => 0.0,   :null => false
    t.float   "extra_weight",                                        :default => 0.0,   :null => false
    t.boolean "wholesale_only",                                      :default => false, :null => false
    t.decimal "wholesale_extra_cost", :precision => 10, :scale => 2, :default => 0.0,   :null => false
  end

  add_index "option_values", ["option_id"], :name => "option_id"

  create_table "options", :force => true do |t|
    t.string "name",          :limit => 64
    t.string "type",          :limit => 64
    t.text   "default_value"
    t.text   "comment"
  end

  create_table "orders", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.string   "shipping_email",      :limit => 128
    t.integer  "billing_address_id"
    t.decimal  "shipping_cost",                      :precision => 10, :scale => 2
    t.integer  "shipping_zone_id"
    t.string   "status",              :limit => 20,                                 :default => "in_progress", :null => false
    t.integer  "delivery_address_id"
    t.string   "gateway_used",        :limit => 32
    t.text     "response"
    t.boolean  "is_draft",                                                          :default => false,         :null => false
    t.boolean  "wholesale",                                                         :default => false,         :null => false
    t.decimal  "paid",                               :precision => 8,  :scale => 3, :default => 0.0,           :null => false
    t.boolean  "priced",                                                            :default => true,          :null => false
    t.boolean  "printed_invoice",                                                   :default => false,         :null => false
    t.decimal  "subtotal",                           :precision => 10, :scale => 2, :default => 0.0,           :null => false
    t.decimal  "total",                              :precision => 10, :scale => 2, :default => 0.0,           :null => false
  end

  add_index "orders", ["billing_address_id"], :name => "orders_ibfk_1"

  create_table "plugin_parameters", :force => true do |t|
    t.integer "plugin_id"
    t.string  "name",      :limit => 64
    t.text    "value"
  end

  create_table "plugins", :force => true do |t|
    t.string  "type",        :limit => 64
    t.string  "name",        :limit => 64
    t.text    "description"
    t.string  "script",      :limit => 128
    t.string  "config",      :limit => 128
    t.integer "active",                     :default => 0, :null => false
  end

  create_table "product_option_values", :id => false, :force => true do |t|
    t.integer "option_value_id", :default => 0, :null => false
    t.integer "product_id",      :default => 0, :null => false
    t.integer "position",        :default => 0, :null => false
    t.text    "default_value"
  end

  add_index "product_option_values", ["option_value_id"], :name => "option_value_id"
  add_index "product_option_values", ["product_id"], :name => "product_id"

  create_table "product_options", :force => true do |t|
    t.integer "option_id",     :default => 0, :null => false
    t.integer "product_id",    :default => 0, :null => false
    t.integer "position",      :default => 0, :null => false
    t.text    "default_value"
    t.text    "values"
  end

  add_index "product_options", ["option_id"], :name => "option_id"
  add_index "product_options", ["product_id"], :name => "product_id"

  create_table "product_types", :force => true do |t|
    t.string "name", :limit => 32, :null => false
  end

  create_table "products", :force => true do |t|
    t.string  "product_code",         :limit => 16
    t.string  "product_name",         :limit => 64
    t.text    "description"
    t.decimal "base_price",                          :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.decimal "discount",                            :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.decimal "base_weight",                         :precision => 8,  :scale => 3, :default => 0.0,   :null => false
    t.integer "available",                                                          :default => 1,     :null => false
    t.text    "meta_keywords"
    t.text    "meta_description"
    t.text    "image_alt_tag"
    t.string  "page_title",           :limit => 100
    t.boolean "discount_is_abs",                                                    :default => false, :null => false
    t.string  "h1",                   :limit => 64
    t.date    "featured_until"
    t.date    "expiry_date"
    t.text    "short_description"
    t.integer "product_type_id",                                                    :default => 0,     :null => false
    t.boolean "wholesale_only",                                                     :default => false, :null => false
    t.decimal "wholesale_base_price",                :precision => 8,  :scale => 3, :default => 0.0,   :null => false
  end

  create_table "quirk_values", :force => true do |t|
    t.integer "product_id", :default => 0, :null => false
    t.integer "quirk_id",   :default => 0, :null => false
    t.text    "value"
  end

  create_table "quirks", :force => true do |t|
    t.integer "product_type_id",               :default => 0, :null => false
    t.string  "name",            :limit => 32,                :null => false
    t.string  "type",            :limit => 16,                :null => false
    t.boolean "required"
    t.integer "position",                      :default => 0, :null => false
  end

  create_table "reviews", :force => true do |t|
    t.integer  "product_id",              :default => 0, :null => false
    t.integer  "user_id",                 :default => 0, :null => false
    t.text     "comments"
    t.integer  "rating"
    t.datetime "created_at"
    t.string   "allowed",    :limit => 1,                :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shipping_zones", :force => true do |t|
    t.string  "name",                :limit => 64,                                :default => "",  :null => false
    t.decimal "per_item",                          :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.decimal "per_kg",                            :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.decimal "flat_rate",                         :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.integer "default_zone",                                                     :default => 0,   :null => false
    t.integer "position",                                                         :default => 0,   :null => false
    t.string  "formula"
    t.string  "formula_description"
  end

  create_table "static_pages", :force => true do |t|
    t.string "name",             :limit => 128
    t.string "path"
    t.string "title",            :limit => 128
    t.text   "body"
    t.text   "meta_keywords"
    t.text   "meta_description"
    t.string "form_name",        :limit => 32
  end

  add_index "static_pages", ["path"], :name => "path"

  create_table "users", :force => true do |t|
    t.integer "user_level",                           :default => 0,     :null => false
    t.string  "first_name",            :limit => 32
    t.string  "last_name",             :limit => 32
    t.string  "email",                 :limit => 128, :default => "",    :null => false
    t.string  "hashed_password",       :limit => 64
    t.integer "hash_algorithm",                       :default => 2
    t.boolean "active",                               :default => true,  :null => false
    t.boolean "sees_wholesale",                       :default => false, :null => false
    t.string  "wholesale_application", :limit => 1,   :default => "-",   :null => false
  end

end
