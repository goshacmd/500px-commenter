class CommentTextGenerator
  COMMENT_TEXTS = [
    [10, "great shot"],
    [10, "I like it"],
    [10, "nice"],
    [10, "it's good"],
    [15, "great"],
    [15, "great tones"],
    [20, "nice colors"],
    [20, "no doubt, cool photo"],
    [20, "excellent work"],
    [25, "awesome capture"],
    [30, "really cool"],
    [30, "good job"],
    [35, "wow, excellent"],
    [35, "what a beautiful shot"],
    [40, "awesome shot"],
    [40, "lovely"],
    [40, "sweet"],
    [40, "perfect"],
    [45, "marvellous frame"],
    [45, "that's stunning"],
    [45, "exciting. Your work is neat"],
    [45, "whoa, that's terrific"],
    [50, "gorgeous"],
    [55, "superb photo"],
    [60, "oh my! It's totally amazing"],
    [80, "totally stunning"],
    [80, "impressive capture"],
    [90, "unbelievably incredible"],
  ]

  def self.random_text(name, rating)
    available_phrases = COMMENT_TEXTS.select do |(threshold, _)|
      rating >= threshold
    end

    _, phrase = available_phrases.sample
    return unless phrase

    sign = rand > 0.5 ? '!' : '.'

    if name && name != '' && rand > 0.33
      parts = rand > 0.5 ? [name, phrase] : [phrase.capitalize, name]
    else
      parts = [phrase.capitalize]
    end

    "#{parts.join(', ')}#{sign}"
  end
end

class Policy
  attr_reader :dismiss_nsfw, :rating_threshold, :votes_threshold,
    :favorites_threshold, :exclude_user

  alias_method :dismiss_nsfw?, :dismiss_nsfw

  def initialize(dismiss_nsfw: true, rating_threshold: 25, votes_threshold: 5,
                 favorites_threshold: 1, exclude_user: nil)
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

  def initialize(base)
    @base = base
    @policy = Policy.new(exclude_user: username)
  end

  def username
    base.username
  end

  def random_text(name, rating)
    CommentTextGenerator.random_text(name, rating)
  end

  def perform
    comment_random_and_like_on_set('fresh_today', 'upcoming', 'popular')
  end

  def comment_random_and_like_on_set(*features)
    photos = features.map do |feature|
      base.photos(feature: feature, rpp: 30)
    end.inject(:concat)

    selected = photos.select { |p| should_process?(p) }

    puts "+ Starting to process #{selected.size} photos"

    selected.each do |photo|
      process(photo)
      sl = (2..20).to_a.sample
      puts "  (sleeping #{sl})"
      sleep sl
    end

    puts "- #{selected.size} photos processed"
  end

  def should_process?(photo)
    return if photo.liked?

    policy.check(photo)
  end

  def process(photo)
    puts "++ Processing photo #{photo.id} #{photo.info} #{photo.web_page}"

    photo.comment random_text(photo.user_firstname, photo.rating)
    photo.like

    puts "-- Done"
  end
end
