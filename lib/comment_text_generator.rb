class CommentTextGenerator
  class << self
    attr_accessor :data

    def probability(thing)
      case thing
      when :name
        0.66
      when :trash
        0.25
      when :noun
        0.75
      when :sign
        0.9
      end
    end

    def probable?(thing)
      rand < probability(thing)
    end

    def read_data(file_path)
      data = YAML.load_file(file_path)

      data['adjective'].map! do |s|
        th, _, txt = s.partition(' ')
        [th.to_i, txt.strip]
      end

      self.data = data
    end

    def random_text(photo)
      rating = photo.rating
      name = photo.user_firstname

      scheme = random_scheme(name)
      prefill = prefill_scheme(scheme, rating: rating, name: name)
      transformed = transform_prefill(prefill)
      
      join_prefill(transformed)
    end

    def random_scheme(name = nil)
      scheme = []

      scheme << :trash if probable?(:trash)
      scheme << :adjective
      scheme << :noun if probable?(:noun)

      if name && probable?(:name)
        rand > 0.5 ? scheme.unshift(:name) : scheme.push(:name)
      end

      scheme << :sign if probable?(:sign)

      scheme
    end

    def prefill_scheme(scheme, rating:, name: nil)
      scheme.map do |type|
        val = type == :name ? name.strip.to_ascii : random_component(type, rating)
        [type, val]
      end
    end

    def transform_prefill(prefill)
      prefill.map do |(type, value)|
        [type, transform(type, value, prefill)]
      end
    end

    def join_prefill(prefill)
      processed = []
      buf = ""

      prefill.each do |(type, value)|
        first = processed.empty?
        value = value.capitalize if first
        needs_space = !first && type != :sign

        if type == :name
          final = first ? "#{value}," : ", #{value}"
        else
          final = needs_space ? " #{value}" : value
        end

        processed << type
        buf << final
      end

      buf
    end

    def transform(type, value, prefill)
      case type
      when :trash
        if !!value[' (a)']
          has_noun = prefill.map(&:first).include?(:noun)

          if has_noun
            adj_first = prefill.find { |(t, _)| t == :adjective }[1][0]
            noun_last = prefill.find { |(t, _)| t == :noun }[1][-1]

            plural = noun_last == 's'
            vowel = %w(a e i o u y).include? adj_first
            rep = plural ? '' : (vowel ? ' an' : ' a')
          else
            rep = ''
          end

          value.gsub(' (a)', rep)
        else
          value
        end
      else
        value
      end
    end

    def random_component(type, rating)
      available = data[type.to_s]

      if type == :adjective
        available = available.select do |(threshold, _)|
          rating >= threshold
        end.map(&:last)
      end

      available.sample
    end
  end
end
