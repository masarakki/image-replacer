# require 'httparty'
require 'json'

def lambda_handler(event:, context:)
  body = JSON.parse(event['body'])

  message = case body['type']
            when 'url_verification'
              { challenge: body['challenge'] }
            else
              {}
            end

  {
    statusCode: 200,
    body: {
      message: message
    }.to_json
  }
end
