# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  Query = GitHubClient::Client.parse <<~GRAPHQL
      query ($name: String!, $from: DateTime!, $to: DateTime!) {
        user(login: $name) {
          contributionsCollection(from: $from, to: $to) {
            contributionCalendar {
              weeks {
                contributionDays {
                  contributionCount
              }
            }
          }
        }
      }
    }
  GRAPHQL

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  #  end

  # パスワードなしで更新
  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  # The path used after sign up.
  def after_sign_up_path_for(_resource)
    update_status
    users_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(_resource)
    users_path
  end

  def update_status
    week_contributions = 0
    response = GitHubClient::Client.query(Query,
      variables: {name: current_user.github_name,
                  to: Date.yesterday.beginning_of_day.iso8601,
                  from: Date.yesterday.ago(7.days).beginning_of_day.iso8601})
    contribution_week = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
      "weeks")
    contribution_week.each do |contributions|
      contributions["contributionDays"].each do |day|
        week_contributions += day["contributionCount"]
      end
    end
    current_user.update(contributions: week_contributions)
  end
end
