require 'oauth'
require 'multi_json'

COMMENT_TEXTS = [
  'Great shot!',
  'I like it.',
  'Exciting. Your work is neat.',
  'No doubt, cool photo.',
  'Excellent work!',
  'Awesome capture.',
  'Nice!',
  'Wow, excellent!',
  'Awesome shot.'
].map { |text| "#{text}\nPlease, find time to visit back." }

class Commenter
  # Public: Initializes the Commenter.
  #
  # access_token - The Oauth::AccessToken object.
  def initialize(access_token)
    @access_token = get_access_token
  end

  # Public: Get a random comment text from pre-set ones.
  def random_text
    COMMENT_TEXTS.sample
  end

  # Public: Comment on photo.
  #
  # photo   - The Integer photo id.
  # comment - The String comment text.
  def comment_on(photo, comment)
    @access_token.post("/v1/photos/#{photo}/comments", body: comment)
  end

  # Public: Leave a like on photo.
  #
  # photo - The Integer photo id.
  def like_on(photo)
    @access_token.post("/v1/photos/#{photo}/vote", vote: 1)
  end

  # Public: Leave random comments and likes on given set of photos.
  #
  # photos - The Array photo ids.
  def comment_random_and_like_on_set(photos)
    photos.each do |photo|
      comment_on photo, random_text
      like_on photo
    end
  end
end
