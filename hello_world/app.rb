# require 'httparty'
require 'json'

def response(message = '')
  {
    statusCode: 200,
    body: {
      message: message
    }.to_json
  }
end

def handle_event(event)
  # noop!
end

def lambda_handler(event:, context:)
  body = JSON.parse(event['body'])
  return response(challenge: body['challenge']) if body['type'] == 'url_verification'

  handle_event(body['event']) if body['type'] == 'event_callback'
  response
end
