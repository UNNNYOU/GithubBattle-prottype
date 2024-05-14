# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  Query = GitHubClient::Client.parse <<~GRAPHQL
      query ($name: String!, $from: DateTime!, $to: DateTime!) {
        user(login: $name) {
          contributionsCollection(from: $from, to: $to) {
            contributionCalendar {
              totalContributions
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
    set_experience_points
    set_contributions
    users_path
  end

  def after_update_path_for(_resource)
    set_contributions
    root_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(_resource)
    users_path
  end

  def set_contributions
    week_contribution_data = 0
    response = GitHubClient::Client.query(Query,
      variables: {name: current_user.github_name,
                  to: Time.current.yesterday.end_of_day.iso8601,
                  from: Time.current.ago(7.days).beginning_of_day.iso8601})
    contribution_week = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
      "weeks")

    return unless contribution_week.presence

    contribution_week.each do |contributions|
      contributions["contributionDays"].each do |day|
        week_contribution_data += day["contributionCount"]
      end
    end
    current_user.profile.update(week_contributions: week_contribution_data)
  end

  def set_experience_points
    # ユーザーが登録した際にプロフィールを作成
    Profile.create!(user_id: current_user.id)

    # githubに対してgraphqlリクエストを送信
    response = GitHubClient::Client.query(Users::RegistrationsController::Query,
      variables: {name: current_user.github_name,
                  to: Time.current.yesterday.end_of_day.iso8601,
                  from: Time.current.ago(30.days).beginning_of_day.iso8601})

    # 一番新しい日にちのコントリビューション数
    latest_date_contributions = response.original_hash.dig("data", "user", "contributionsCollection",
      "contributionCalendar", "weeks", -1, "contributionDays", -1, "contributionCount")

    # 一番古い日にちのコントリビューション数
    oldest_date_contributions = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
      "weeks", 0, "contributionDays", 0, "contributionCount")

    # 約１ヶ月分全てのコントリビューション数
    all_contributions = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
      "totalContributions")

    # データがない場合にはスキップ
    return if all_contributions.blank?

    # 経験値の計算
    experience_point_data = latest_date_contributions

    # 次回の経験値の計算の際、前日のコントリビューション数を保存するためのデータ
    temporal_contributions = all_contributions - oldest_date_contributions

    # ユーザーデータからlevelを取得
    level = current_user.profile.level

    # 経験値が10以上の場合、レベルアップする
    if experience_point_data >= 10
      while experience_point_data >= 10
        experience_point_data -= 10
        level += 1
      end
      current_user.profile.update!(level:, temporal_contribution_data: temporal_contributions,
        experience_points: experience_point_data)
    else
      current_user.profile.update!(temporal_contribution_data: temporal_contributions,
        experience_points: experience_point_data)
    end
  end
end
