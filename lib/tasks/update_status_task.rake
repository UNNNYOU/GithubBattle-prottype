namespace :update_status_task do
  # 毎日、全ユーザーのステータスを更新する
  desc "初期データの作成"
  task create_status: :environment do
    User.all.each do |user|
      Profile.create!(user_id: user.id)

      response = GitHubClient::Client.query(Users::RegistrationsController::Query,
        variables: {name: user.github_name,
                    to: Time.current.yesterday.end_of_day.iso8601,
                    from: Time.current.ago(30.days).beginning_of_day.iso8601})
      latest_date_contributions = response.original_hash.dig("data", "user", "contributionsCollection",
        "contributionCalendar", "weeks", -1, "contributionDays", -1, "contributionCount")
      oldest_date_contributions = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
        "weeks", 0, "contributionDays", 0, "contributionCount")
      all_contributions = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
        "totalContributions")

      next if all_contributions.blank?

      # 経験値の計算
      experience_point_data = latest_date_contributions

      # 次回の経験値の計算の際、前日のコントリビューション数を保存するためのデータ
      temporal_contributions = all_contributions - oldest_date_contributions

      user.profile.update!(temporal_contribution_data: temporal_contributions, experience_points: experience_point_data)
    end
  end

  # 毎日、全ユーザーのステータスを更新する
  desc "直近１週間のコントリビューション数の取得"
  task fetch_contributions: :environment do
    User.all.each do |user|
      response = GitHubClient::Client.query(Users::RegistrationsController::Query,
        variables: {name: user.github_name,
                    to: Time.current.yesterday.end_of_day.iso8601,
                    from: Time.current.ago(7.days).beginning_of_day.iso8601})
      contributions = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
        "totalContributions")
      next if contributions.blank?

      user.profile.update!(week_contributions: contributions)
    end
  end

  desc "毎日、全ユーザーに経験値を付与する"
  task update_status: :environment do
    User.all.each do |user|
      response = GitHubClient::Client.query(Users::RegistrationsController::Query,
        variables: {name: user.github_name,
                    to: Time.current.yesterday.end_of_day.iso8601,
                    from: Time.current.ago(30.days).beginning_of_day.iso8601})
      oldest_date_contributions = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
        "weeks", 0, "contributionDays", 0, "contributionCount")
      all_contributions = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
        "totalContributions")

      next if all_contributions.blank?

      # 経験値の計算
      experience_point_data = all_contributions - user.profile.temporal_contribution_data

      # 次回の経験値の計算の際、前日のコントリビューション数を保存するためのデータ
      temporal_contributions = all_contributions - oldest_date_contributions

      level = user.profile.level

      if experience_point_data > 10
        while experience_point_data >= 10
          experience_point_data -= 10
          level += 1
        end
        user.profile.update!(level:, temporal_contribution_data: temporal_contributions,
          experience_points: experience_point_data)
      else
        user.profile.update!(temporal_contribution_data: temporal_contributions,
          experience_points: experience_point_data)
      end
    end
  end
end
