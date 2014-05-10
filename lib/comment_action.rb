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
