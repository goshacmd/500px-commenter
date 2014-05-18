module FHCommenter
  class FiveHundred
    class User
      include Virtus.model

      attribute :id, Integer
      attribute :username, String
      attribute :firstname, String
      attribute :lastname, String
      attribute :fullname, String
      attribute :affection, Integer
      attribute :photos_count, Integer
    end

    class Photo
      include Virtus.model

      attr_reader :base

      def initialize(base, attrs)
        @base = base
        super(attrs)
      end

      attribute :id, Integer
      attribute :name, String
      attribute :rating, Float
      attribute :category, Integer
      attribute :times_viewed, Integer
      attribute :votes_count, Integer
      attribute :favorites_count, Integer
      attribute :nsfw, Boolean
      attribute :liked, Boolean

      attribute :user, User

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

    def photos(feature: 'fresh_today', rpp: 20, full_user: false)
      result = get("/photos.json?include_states=1&feature=#{feature}&rpp=#{rpp}")

      body = result['photos']

      body.map do |photo|
        if full_user
          photo[:user] = user_attrs(photo['user']['username'])
        end

        Photo.new(self, photo)
      end
    end

    def user_attrs(username)
      get("/users/show?username=#{username}")['user']
    end

    def comment(photo_id, text)
      access_token.post("/photos/#{photo_id}/comments", body: text)
    end

    def like(photo_id)
      access_token.post("/photos/#{photo_id}/vote", vote: 1)
    end

    def get(url)
      result = access_token.get(url)
      MultiJson.decode(result.body)
    end
  end
end
