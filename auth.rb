CONSUMER_KEY = ENV['CONSUMER_KEY']
CONSUMER_SECRET = ENV['CONSUMER_SECRET']
USERNAME = ENV['USERNAME']
PASSWORD = ENV['PASSWORD']

BASE_URL = 'https://api.500px.com'

def get_access_token
  consumer = OAuth::Consumer.new CONSUMER_KEY, CONSUMER_SECRET, {
    site: BASE_URL,
    request_token_path: "/v1/oauth/request_token",
    access_token_path: "/v1/oauth/access_token",
    authorize_path: "/v1/oauth/authorize"
  }

  request_token = consumer.get_request_token()
  access_token = consumer.get_access_token request_token, {}, { x_auth_mode: 'client_auth', x_auth_username: USERNAME, x_auth_password: PASSWORD }
  access_token
end

