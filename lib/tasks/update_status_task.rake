namespace :update_status_task do
  desc '週に一度、全ユーザーのステータスを更新する'
  task update_status: :environment do
    User.all.each do |user|
      countcontributions = 0
      response = GitHubClient::Client.query(Users::RegistrationsController::Query,
                                            variables: { userName: user.github_name })
      contribution_week_data = response.original_hash.dig('data', 'user', 'contributionsCollection', 'contributionCalendar',
                                                          'weeks')
      all_contibution = contribution_week_data.last(2)[0]['contributionDays'].each do |contribution|
        countcontributions += contribution['contributionCount']
      end
      user.update(contributions: countcontributions)
    end
  end
end
