# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120917071502) do

  create_table "answers", :force => true do |t|
    t.text     "content"
    t.integer  "question_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "response_id"
  end

  add_index "answers", ["question_id"], :name => "index_answers_on_question_id"

  create_table "choices", :force => true do |t|
    t.integer  "answer_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "option_id"
  end

  add_index "choices", ["answer_id"], :name => "index_choices_on_answer_id"

  create_table "options", :force => true do |t|
    t.string   "content"
    t.integer  "question_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "order_number"
  end

  add_index "options", ["question_id"], :name => "index_options_on_question_id"

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "questions", :force => true do |t|
    t.text     "content"
    t.integer  "survey_id"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.boolean  "mandatory",          :default => false
    t.integer  "max_length"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "type"
    t.integer  "max_value"
    t.integer  "min_value"
    t.integer  "order_number"
  end

  add_index "questions", ["survey_id"], :name => "index_questions_on_survey_id"

  create_table "responses", :force => true do |t|
    t.integer  "survey_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "responses", ["survey_id"], :name => "index_responses_on_survey_id"

  create_table "surveys", :force => true do |t|
    t.string   "name"
    t.date     "expiry_date"
    t.text     "description"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "published",      :default => false
    t.integer  "owner_org_id"
    t.string   "shared_org_ids"
  end

end
