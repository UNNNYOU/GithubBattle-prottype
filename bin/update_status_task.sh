set -o errexit

bundle exec rake update_status_task:update_status
bundle exec rake update_status_task:fetch_contributions
