namespace :update_status_task do
  desc "週に一度、全ユーザーのステータスを更新する"
  task update_status: :environment do
    User.all.each do |user|
      week_contributions = 0
      response = GitHubClient::Client.query(Users::RegistrationsController::Query,
        variables: {name: user.github_name,
                    to: Date.yesterday.end_of_day.iso8601,
                    from: Date.today.ago(7.days).end_of_day.iso8601})
      contribution_week = response.original_hash.dig("data", "user", "contributionsCollection", "contributionCalendar",
        "weeks")
      contribution_week.each do |contributions|
        contributions["contributionDays"].each do |day|
          week_contributions += day["contributionCount"]
        end
      end
      user.update!(contributions: week_contributions)
    end
  end
end
