class Category < ActiveRecord::Base
  belongs_to :parent, :class_name => Option
  belongs_to :category
  attr_accessible :content, :survey_id, :order_number, :category_id, :parent_id, :type, :mandatory
  has_many :questions, :dependent => :destroy
  has_many :categories, :dependent => :destroy
  validates_presence_of :content
  belongs_to :survey

  delegate :question, :to => :parent, :prefix => true, :allow_nil => true

  def elements
    (questions + categories).sort_by(&:order_number)
  end

  def with_sub_questions_in_order
    elements.map(&:with_sub_questions_in_order).flatten
  end

  def as_json(opts={})
    super(opts.merge({ :methods => :type }))
  end

  def nesting_level
    return parent_question.nesting_level + 1 if parent
    return category.nesting_level + 1 if category
    return 1
  end

  def sub_question?
    parent || category.try(:sub_question?)
  end

  def duplicate(survey_id)
    category = self.dup
    category.survey_id = survey_id
    category.questions << questions.map { |question| question.duplicate(survey_id) } if self.respond_to? :questions
    category.categories << categories.map { |category| category.duplicate(survey_id) } if self.respond_to? :categories
    category.save(:validate => false)
    category
  end

  def copy_with_order
    duplicated_category = duplicate(survey_id)
    duplicated_category.order_number += 1
    return false unless duplicated_category.save
    true
  end

  def has_questions?
    questions.count > 0 || categories.any? { |x| x.has_questions? }
  end

  def categories_with_questions
    categories.select { |x| x.has_questions? }
  end

  def index_of_parent_option
    parent_options = parent_question.options
    parent_options.index(parent)
  end

  def has_multi_record_ancestor?
    category.try(:is_a?, MultiRecordCategory) || category.try(:has_multi_record_ancestor?) || parent.try(:has_multi_record_ancestor?)
  end
end
