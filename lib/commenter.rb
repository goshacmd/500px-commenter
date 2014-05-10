class Commenter
  attr_reader :base, :policy, :generator

  def initialize(base, policy = Polciy.new, generator = CommentTextGenerator)
    @base = base
    @policy = policy
    @generator = generator
  end

  def random_text(photo)
    generator.random_text(photo)
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
      ret = process(photo)
      yield :finished, photo, ret
    end
  end

  def should_process?(photo)
    return if photo.liked?

    policy.check(photo)
  end

  def process(photo)
    text = random_text(photo)

    photo.comment text
    photo.like

    text
  end
end
