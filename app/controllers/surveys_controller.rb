require 'will_paginate/array'

class SurveysController < ApplicationController
  load_and_authorize_resource

  before_filter :survey_unpublished, :only => [:build]

  def index
    @surveys ||= []
    @surveys = @surveys.select { |survey| survey.published.to_s == params[:published] } if params[:published].present?
    @surveys = @surveys.paginate(:page => params[:page], :per_page => 10)
    if access_token.present?
      organizations = access_token.get('api/organizations').parsed
      @organization_names = organizations.reduce({}) do |hash, org|
        hash[org['id']] = org['name']
        hash
      end
    end
  end

  def destroy
    survey = Survey.find(params[:id])
    survey.destroy
    flash[:notice] = t "flash.survey_deleted"
    redirect_to(surveys_path)
  end

  def new
    @survey = Survey.new
  end

  def create
    @survey = Survey.new(params[:survey])
    @survey.organization_id = session[:user_info][:org_id]

    @survey.name ||= "Untitled Survey"
    @survey.expiry_date ||= 5.days.from_now
    @survey.description ||= "Description goes here"

    @survey.save
    flash[:notice] = t "flash.survey_created"
    redirect_to surveys_build_path(:id => @survey.id)
  end

  def build
    @survey = SurveyDecorator.find(params[:id])
  end

  def publish_to_users
    @survey = Survey.find(params[:survey_id])
    users = Organization.users(access_token, current_user_org).reject { |user| user.id == current_user }
    @shared_users = @survey.users(access_token, current_user_org)
    @unshared_users = users.reject { |user| @shared_users.map(&:id).include?(user.id) }
  end

  def update_publish_to_users
    survey = Survey.find(params[:survey_id])
    users = Sanitizer.clean_params(params[:survey][:user_ids])
    if users.present?
      survey.publish_to_users(users)
      survey.publish unless survey.published
      flash[:notice] = t "flash.survey_published", :survey_name => survey.name
      redirect_to surveys_path
    else
      flash[:error] = t "flash.user_not_selected"
      redirect_to(:back)
    end
  end

  def share_with_organizations
    @survey = Survey.find(params[:survey_id])
    if @survey.published?
      other_organizations = Organization.all_except(access_token, @survey.organization_id)
      @shared_organizations = @survey.organizations(access_token, current_user_org)
      @unshared_organizations = other_organizations.reject { |org| @shared_organizations.map(&:id).include?(org.id) }
    else
      redirect_to surveys_path
      flash[:error] = t "flash.sharing_unpublished_survey"
    end
  end

  def update_share_with_organizations
    survey = Survey.find(params[:survey_id])
    organizations = Sanitizer.clean_params(params[:survey][:participating_organization_ids])
    if organizations.present?
      survey.share_with_organizations(organizations)
      flash[:notice] = t "flash.survey_shared", :survey_name => survey.name
      redirect_to surveys_path
    else
      flash[:error] = t "flash.organizations_not_selected"
      redirect_to(:back)
    end
  end

  private
  def survey_unpublished
    survey = Survey.find(params[:id])
    if survey.published?
      flash[:error] = t "flash.edit_published_survey"
      redirect_to root_path
    end
  end
end
