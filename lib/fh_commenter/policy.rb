module FHCommenter
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
end
