class Commenter
  attr_reader :base, :policy, :generator

  def initialize(base, policy = Polciy.new, generator = CommentTextGenerator)
    @base = base
    @policy = policy
    @generator = generator
  end

  def random_text(name, rating)
    generator.random_text(name: name, rating: rating)
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
