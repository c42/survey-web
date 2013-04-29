class ResponsesController < ApplicationController
  load_and_authorize_resource :survey
  load_and_authorize_resource :through => :survey

  before_filter :survey_finalized
  before_filter :authorize_public_response, :only => :create
  before_filter :survey_not_expired, :only => :create

  def index
    @user_names = User.names_for_ids(access_token, @responses.map(&:user_id).uniq)
    @organization_names = Organization.all(access_token)
    @complete_responses_count = @responses.where(:status => 'complete').order('updated_at').count
    @responses = @responses.where(:blank => false).paginate(:page => params[:page], :per_page => 10).order('created_at DESC, status')
  end

  def generate_excel
    authorize! :generate_excel, @survey
    @responses = Reports::Excel::Responses.new(@responses).build(:from => params[:from], :to => params[:to]).all
    data = Reports::Excel::Data.new(@survey, @responses, server_url, access_token)
    job = Reports::Excel::Job.new(data)
    job.start
    render :json => { :excel_path => data.file_name, :id => job.delayed_job_id }
  end

  def create
    response = ResponseDecorator.new(Response.new(:blank => true))
    response.set(params[:survey_id], current_user, current_user_org, session_token)
    response.save
    survey = Survey.find(params[:survey_id])
    response.create_blank_answers
    response.ip_address = request.remote_ip
    response.save(:validate => false)
    redirect_to edit_survey_response_path(:id => response.id)
  end

  def edit
    @survey = Survey.find(params[:survey_id])
    @response = ResponseDecorator.find(params[:id])
    @disabled = false
    @public_response = public_response?
  end

  def show
    @survey = Survey.find(params[:survey_id])
    @response = ResponseDecorator.find(params[:id])
    @disabled = true
    @marker = @response.to_gmaps4rails
    render :edit
  end

  def update
    @response = ResponseDecorator.find(params[:id])
    @response.update_column(:blank, false)
    if @response.update_attributes(params[:response])
      redirect_to :back, :notice => "Successfully updated"
    else
      flash[:error] = "Error"
      render :edit
    end
  end

  def complete
    @response = ResponseDecorator.find(params[:id])
    @response.update_column(:blank, false)
    was_complete = @response.complete?
    answers_attributes = params.try(:[],:response).try(:[], :answers_attributes)
    @response.valid_for?(answers_attributes) ? complete_valid_response : revert_response(was_complete, params[:response])
  end

  def destroy
    response = Response.find(params[:id])
    response.destroy
    flash[:notice] = t "flash.response_deleted"
    redirect_to(survey_responses_path)
  end

  private

  def complete_valid_response
    @response.update_column('status', 'complete')
    if @response.survey_public? && !user_currently_logged_in?
      @public_response = public_response?
      render "thank_you"
    else
      redirect_to survey_responses_path(@response.survey_id), :notice => "Successfully updated"
    end
  end

  def revert_response(was_complete, response)
    if was_complete
      @response.complete
    else
      @response.incomplete
    end
    @response.attributes = response
    flash[:error] = t("responses.edit.error_saving_response")
    @disabled = false
    render :edit
  end

  def survey_finalized
    survey = Survey.find(params[:survey_id])
    unless survey.finalized
      flash[:error] = t "flash.response_to_draft_survey", :survey_name => survey.name
      redirect_to surveys_path
    end
  end

  def authorize_public_response
    survey = Survey.find(params[:survey_id])
    if public_response?
      raise CanCan::AccessDenied.new("Not authorized!", :create, Response) unless params[:auth_key] == survey.auth_key
    end
  end

  def public_response?
    survey = Survey.find(params[:survey_id])
    survey.public? && !user_currently_logged_in?
  end

  def survey_not_expired
    survey = Survey.find(params[:survey_id])
    if survey.expired?
      flash[:error] = t "flash.response_to_expired_survey", :survey_name => survey.name
      redirect_to surveys_path
    end
  end
end
