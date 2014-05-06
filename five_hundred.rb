class FiveHundred
  USER_ATTRS = %w(id username firstname lastname fullname)
  PHOTO_ATTRS = %w(id name rating category times_viewed votes_count favorites_count nsfw liked)

  class User < Struct.new(:base, *USER_ATTRS)
  end

  class Photo < Struct.new(:base, *PHOTO_ATTRS, :user)
    def like
      base.like(id)
    end

    def comment(text)
      base.comment(id, text)
    end

    def user_firstname
      user.firstname
    end

    def username
      user.username
    end

    def web_page
      "http://500px.com/photo/#{id}"
    end

    def info
      "r: #{rating}, v: #{votes_count}, f: #{favorites_count}"
    end

    alias_method :nsfw?, :nsfw
    alias_method :liked?, :liked
  end

  attr_reader :key, :secret, :username, :password

  BASE_URL = 'https://api.500px.com/v1'

  def initialize(options = {})
    @key = options[:key]
    @secret = options[:secret]
    @username = options[:username]
    @password = options[:password]

    access_token
  end

  def access_token
    @token ||= get_access_token
  end

  def get_access_token
    consumer = OAuth::Consumer.new key, secret, {
      site: BASE_URL,
      request_token_path: "/oauth/request_token",
      access_token_path: "/oauth/access_token",
      authorize_path: "/oauth/authorize"
    }

    request_token = consumer.get_request_token()
    consumer.get_access_token request_token, {}, { x_auth_mode: 'client_auth', x_auth_username: username, x_auth_password: password }
  end

  def photos(feature: 'fresh_today', rpp: 20)
    result = access_token.get("/photos.json?include_states=1&feature=#{feature}&rpp=#{rpp}")

    body = MultiJson.decode(result.body)['photos']

    body.map do |photo|
      user_attrs = photo.delete('user').values_at(*USER_ATTRS)
      user = User.new(self, *user_attrs)
      photo_attrs = photo.values_at(*PHOTO_ATTRS)
      Photo.new(self, *photo_attrs, user)
    end
  end

  def comment(photo_id, text)
    access_token.post("/photos/#{photo_id}/comments", body: text)
  end

  def like(photo_id)
    access_token.post("/photos/#{photo_id}/vote", vote: 1)
  end
end
