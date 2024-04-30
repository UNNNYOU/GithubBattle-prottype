class UsersController < ApplicationController
  before_action :authenticate_user!
  Query = GitHubClient::Client.parse <<~GRAPHQL
    query($userName: String!) {
      user(login: $userName){
        contributionsCollection {
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                contributionCount
                date
              }
            }
          }
        }
      }
    }
  GRAPHQL

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  private

  def result
    countcontributions = 0
    response = GitHubClient::Client.query(UsersController::Query, variables: { userName: current_user.github_name })
    contribution_week_data = response.original_hash.dig('data', 'user', 'contributionsCollection', 'contributionCalendar',
                                                        'weeks')
    all_contibution = contribution_week_data.last(2)[0]['contributionDays'].each do |contribution|
      countcontributions += contribution['contributionCount']
    end
    current_user.update(contributions: countcontributions)
  end
end
