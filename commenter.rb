class CommentTextGenerator
  class << self
    attr_accessor :texts

    def random_text(name, rating)
      available_phrases = texts.select do |(threshold, _)|
        rating >= threshold
      end

      _, phrase = available_phrases.sample
      return unless phrase

      sign = rand > 0.5 ? '!' : '.'

      if name && name != '' && rand > 0.33
        name = name.strip.to_ascii
        parts = rand > 0.5 ? [name, phrase] : [phrase.capitalize, name]
      else
        parts = [phrase.capitalize]
      end

      "#{parts.join(', ')}#{sign}"
    end

    def read_texts(file_path)
      self.texts = File.readlines(file_path).map do |line|
        th, _, txt = line.partition(' ')
        [th.to_i, txt.strip]
      end
    end
  end
end

class Policy
  attr_reader :dismiss_nsfw, :rating_threshold, :votes_threshold,
    :favorites_threshold, :exclude_user

  alias_method :dismiss_nsfw?, :dismiss_nsfw

  def initialize(dismiss_nsfw: false, rating_threshold: 0, votes_threshold: 0,
                 favorites_threshold: 0, exclude_user: nil)
    @dismiss_nsfw = dismiss_nsfw
    @rating_threshold = rating_threshold
    @votes_threshold = votes_threshold
    @favorites_threshold = favorites_threshold
    @exclude_user = exclude_user
  end

  def check(photo)
    return false if dismiss_nsfw? && photo.nsfw?
    return false if exclude_user && photo.username == exclude_user

    photo.rating >= rating_threshold &&
      photo.votes_count >= votes_threshold &&
      photo.favorites_count >= favorites_threshold
  end
end

class Commenter
  attr_reader :base, :policy

  def initialize(base, policy = Polciy.new)
    @base = base
    @policy = policy
  end

  def random_text(name, rating)
    CommentTextGenerator.random_text(name, rating)
  end

  def select_photos(features, count: 30)
    photos = features.map do |feature|
      base.photos(feature: feature, rpp: count)
    end.inject(:concat).uniq

    photos.select { |p| should_process?(p) }
  end

  def comment(features, options = {}, &block)
    selected = select_photos(features, options)

    selected.each do |photo|
      yield :started, photo
      process(photo)
      yield :finished, photo
    end
  end

  def should_process?(photo)
    return if photo.liked?

    policy.check(photo)
  end

  def process(photo)
    photo.comment random_text(photo.user_firstname, photo.rating)
    photo.like
  end
end

class CommentAction
  attr_reader :commenter, :features, :photo_count, :sleep_range

  def self.perform(options = {})
    new(options).perform
  end

  def initialize(options = {})
    base = FiveHundred.new(options[:five_hundred])
    policy = Policy.new(options[:policy])
    @commenter = Commenter.new(base, policy)
    @features = options[:features] || ['fresh_today']
    @photo_count = options[:photo_count] || 25
    @sleep_range = options[:sleep] || (2..20)
  end

  def perform
    timing do
      processed = commenter.comment features, count: photo_count do |c, photo|
        if c == :started
          puts "++ Processing photo #{photo.web_page} #{photo.info}"
        else
          sl = sleep_range.to_a.sample
          puts "  (sleeping #{sl})"
          sleep sl
        end
      end

      puts "+ Processed #{processed.size} photos"
    end
  end

  def timing(&block)
    now = Time.now

    puts "^ Started #{now}"

    block.call

    thn = Time.now
    diff = (thn - now).to_i

    puts "^ Finished #{thn}. Processing took #{diff}s = #{diff/60}min"
  end
end
