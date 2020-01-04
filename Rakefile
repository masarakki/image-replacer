require 'aws-sdk'

namespace :deploy do
  task :build do
    sh 'sam build'
  end

  task package: :build do
    sh 'sam package --output-template-file packaged.yaml --s3-bucket masarakki-sam-deploy'
  end

  task deploy: :package do
    client = Aws::SecretsManager::Client.new
    secrets = JSON.parse(client.get_secret_value(secret_id: 'image-replacer-secrets').secret_string)

    sh "aws cloudformation deploy --template-file packaged.yaml --region us-east-1 --capabilities CAPABILITY_IAM --stack-name image-replacer --parameter-overrides UserAccessToken=#{secrets['USER_ACCESS_TOKEN']} BotAccessToken=#{secrets['BOT_ACCESS_TOKEN']}"
  end
end

desc 'deploy'
task deploy: 'deploy:deploy'
