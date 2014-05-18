module FHCommenter
  class CommentTextGenerator
    class Token
      class << self
        attr_accessor :type

        def lookup(type)
          const_get type.to_s.capitalize
        end

        def build(type)
          Token === type ? type : lookup(type).new
        end
      end

      attr_reader :fill

      def initialize(fill = nil)
        @fill = fill
      end

      def filled?
        !!fill
      end

      def fill_in(fill)
        self.class.new(fill)
      end

      def transform(prefill)
      end

      def type
        self.class.type
      end

      class Name < Token
        self.type = :name
      end

      class Adjective < Token
        self.type = :adjective
      end

      class Noun < Token
        self.type = :noun
      end

      class Sign < Token
        self.type = :sign
      end

      class Trash < Token
        self.type = :trash

        ARTICLE_PLACEHOLDER = ' (a)'

        def transform(prefill)
          if ends_in_article?
            sub = article_sub(prefill)
            fill.gsub!(ARTICLE_PLACEHOLDER, sub)
          end
        end

        def ends_in_article?
          !!fill[ARTICLE_PLACEHOLDER]
        end

        def article_sub(prefill)
          if prefill.has?(:noun)
            adj = prefill.find(:adjective).fill
            noun = prefill.find(:noun).fill

            plural = noun[-1] == 's'
            vowel = %w(a e i o u y).include? adj[0]

            plural ? '' : (vowel ? ' an' : ' a')
          else
            ''
          end
        end
      end
    end

    class SentenceScheme
      attr_reader :tokens

      def initialize(tokens)
        @tokens = tokens.map do |token|
          Token.build(token)
        end
      end
    end

    class SentencePrefill
      attr_reader :tokens

      def initialize(tokens, fills)
        @tokens = tokens.zip(fills).map do |raw_token, fill|
          raw_token.fill_in(fill)
        end
      end

      def transform
        tokens.each { |token| token.transform(self) }

        self
      end

      def has?(token_type)
        tokens.map(&:type).include?(token_type)
      end

      def find(token_type)
        tokens.find { |token| token.type == token_type }
      end

      def to_s
        processed = []
        buf = ""

        tokens.each do |token|
          type = token.type
          value = token.fill

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
    end

    class << self
      attr_accessor :data, :probabilities

      def probability(thing)
        {
          name: 0.66,
          trash: 0.25,
          noun: 0.75,
          sign: 0.9,
          name_in_the_end: 0.5
        }.merge(probabilities || {})[thing]
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
        if Hash === photo
          rating, name = *photo.values_at(:rating, :name)
        else
          rating = photo.rating
          name = photo.user_firstname
        end

        scheme = random_scheme(name)
        prefill = prefill_scheme(scheme, rating: rating, name: name)
        prefill.transform.to_s
      end

      def random_scheme(name = nil)
        scheme = []

        scheme << :trash if probable?(:trash)
        scheme << :adjective
        scheme << :noun if probable?(:noun)

        if name && probable?(:name) && pos = probable?(:name_in_the_end)
          pos ? scheme.push(:name) : scheme.unshift(:name)
        end

        scheme << :sign if probable?(:sign)

        SentenceScheme.new(scheme)
      end

      def prefill_scheme(scheme, rating:, name: nil)
        tokens = scheme.tokens

        fills = tokens.map do |token|
          type = token.type

          type == :name ? name.strip.to_ascii : random_component(type, rating)
        end

        SentencePrefill.new tokens, fills
      end

      def join_prefill(prefill)
        processed = []
        buf = ""

        prefill.tokens.each do |token|
          type = token.type
          value = token.fill

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
end
