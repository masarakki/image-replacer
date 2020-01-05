require 'json'
require 'aws-sdk'
require 'faraday'
require 'faraday_middleware'

def response(message = '')
  {
    statusCode: 200,
    body: {
      message: message
    }.to_json
  }
end

def enabled?(event)
  event['type'] == 'message' && event['channel'] == 'CC2BFGC2Z' && event['user'] == 'UBYV3DW5S' && event['files']
end

def handle_event(event)
  slack = Faraday.new('https://slack.com/') do |conn|
    conn.request :multipart
    conn.response :json, content_type: /json/

    conn.adapter :net_http
  end

  s3 = Aws::S3::Client.new
  event['files'].select { |file| file['mimetype'].match?(/image/) && !file['is_external'] }.map do |file|
    image = Faraday.get file['url_private_download'] do |req|
      req.headers['Authorization'] = "Bearer #{ENV['USER_ACCESS_TOKEN']}"
    end
    thumb = Faraday.get file['thumb_720']  do |req|
      req.headers['Authorization'] = "Bearer #{ENV['USER_ACCESS_TOKEN']}"
    end
    return p(:error_in_fetch_images, image.body, thumb.body) unless image.success? && thumb.success?

    key = "#{file['id']}.#{file['filetype']}"
    s3.put_object(acl: 'public-read', body: image.body, content_type: file['mimetype'],
                  bucket: ENV['BUCKET_NAME'], key: key)
    object = Aws::S3::Object.new(bucket_name: ENV['BUCKET_NAME'], key: key)
    thumbnail = Faraday::UploadIO.new(StringIO.new(thumb.body), file['mimetype'])
    remote_file = slack.post('/api/files.remote.add',
                             token: ENV['BOT_ACCESS_TOKEN'],
                             external_id: file['id'], title: file['title'],
                             external_url: object.public_url, preview_image: thumbnail)
    return p(:error_in_remote_file_create, remote_file.body) unless remote_file.success?

    slack.get('/api/files.remote.share', token: ENV['USER_ACCESS_TOKEN'], channels: event['channel'], file: remote_file.body['file']['id'])
  end

  # noop!
end

def lambda_handler(event:, context:)
  p event
  body = JSON.parse(event['body'])
  return response(challenge: body['challenge']) if body['type'] == 'url_verification'

  p body
  handle_event(body['event']) if body['type'] == 'event_callback' && enabled?(body['event'])
  response
end
