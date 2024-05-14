#!/bin/sh
set -e

bundle exec rake update_status_task:fetch_contributions
bundle exec rake update_status_task:update_status
