#!/bin/sh

# RAILS_ENVを設定してRakeタスクを実行
bundle exec rake update_status_task:update_status
bundle exec rake update_status_task:fetch_contributions
