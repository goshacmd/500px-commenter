require 'oauth'
require 'multi_json'
require 'unidecoder'

require './five_hundred'
require './commenter'

CONSUMER_KEY = ENV['CONSUMER_KEY']
CONSUMER_SECRET = ENV['CONSUMER_SECRET']
USERNAME = ENV['USERNAME']
PASSWORD = ENV['PASSWORD']

CommentTextGenerator.read_texts 'texts.txt'

CommentAction.perform \
  five_hundred: {
    key: CONSUMER_KEY, secret: CONSUMER_SECRET,
    username: USERNAME, password: PASSWORD
  },
  features: ['fresh_today', 'upcoming', 'popular'],
  photo_count: 30,
  sleep_range: (2..20),
  policy: {
    dismiss_nsfw: true,
    rating_threshold: 25,
    votes_threshold: 5,
    favorites_threshold: 1,
    exclude_user: USERNAME
  }
