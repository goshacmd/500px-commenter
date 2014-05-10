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
