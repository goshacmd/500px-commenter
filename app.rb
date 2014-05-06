require 'oauth'
require 'multi_json'

require './five_hundred'
require './commenter'

CONSUMER_KEY = ENV['CONSUMER_KEY']
CONSUMER_SECRET = ENV['CONSUMER_SECRET']
USERNAME = ENV['USERNAME']
PASSWORD = ENV['PASSWORD']

base = FiveHundred.new key: CONSUMER_KEY, secret: CONSUMER_SECRET, username: USERNAME, password: PASSWORD

commenter = Commenter.new base
commenter.perform
