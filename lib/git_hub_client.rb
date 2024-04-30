require 'graphql/client'
require 'graphql/client/http'
require 'dotenv'
# GraphQL クライアントを作成

module GitHubClient
  AUTH_HEADER = ENV['GIT_HUB_API_TOKEN']
  # http アダプターを設定
  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(_context)
      { Authorization: AUTH_HEADER }
    end
  end

  # 上記を使用して、API サーバーから GraphQL Schema を取得
  Schema = GraphQL::Client.load_schema(HTTP)

  # 上記を使ってクライアント作成
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end
