require 'json'
require 'aws-sdk'
require 'faraday'

def response(message = '')
  {
    statusCode: 200,
    body: {
      message: message
    }.to_json
  }
end

def handle_event(event)
  if event['type'] == 'message' && event['files']
    s3 = Aws::S3::Client.new
    if event['user'] == 'UBYV3DW5S'
      event['files'].select { |file| file['mimetype'].match?(/image/) && !file['is_external'] }.map do |file|
        response = Faraday.get(file['url_private_download']) do |req|
          req.headers['Authorization'] = "Bearer #{ENV['SLACK_ACCESS_TOKEN']}"
        end
        if response.status == 200
          key = "#{file['id']}.#{file['filetype']}"
          s3.put_object(acl: 'public-read', body: response.body, bucket: ENV['BUCKET_NAME'], key: key)
          key
        end
      end
    end
  end

  # noop!
end

def lambda_handler(event:, context:)
  body = JSON.parse(event['body'])
  return response(challenge: body['challenge']) if body['type'] == 'url_verification'

  handle_event(body['event']) if body['type'] == 'event_callback'
  response
end
