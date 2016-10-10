##= require ./question_with_options_view

class SurveyBuilderV2.Views.LeftPane.MultiChoiceQuestionView extends SurveyBuilderV2.Views.LeftPane.QuestionWithOptionsView
  events:
    "click": "makeActive"
    "click .question-delete-button": "destroyQuestion"

  initialize: (attributes) =>
    @model = new SurveyBuilderV2.Models.MultiChoiceQuestionModel(attributes.question)
    super(attributes)

    rightPaneParams = model: @model, leftPaneView: this, question: attributes.question
    @rightPaneView = new SurveyBuilderV2.Views.RightPane.MultiChoiceQuestionView(rightPaneParams)
    @survey_id= attributes.question.survey_id

  loadOptions: =>
    optionsParent = this.$el.find('.question-options')

    @model.get('options').each((optionModel) =>
      optionView = new SurveyBuilderV2.Views.LeftPane.MultiChoiceOptionView(model: optionModel, survey_id: @survey_id )
      optionsParent.append(optionView.render().el))