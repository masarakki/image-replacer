namespace :deploy do
  task :build do
    sh 'sam build'
  end

  task package: :build do
    sh 'sam package --output-template packaged.yaml --s3-bucket masarakki-sam-deploy'
  end

  task deploy: :package do
    sh 'sam deploy --template-file packaged.yaml --region us-east-1 --capabilities CAPABILITY_IAM --stack-name image-replacer'
  end
end

desc 'deploy'
task deploy: 'deploy:deploy'
