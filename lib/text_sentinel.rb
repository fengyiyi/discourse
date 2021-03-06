#
# Given a string, tell us whether or not is acceptable. Also, remove stuff we don't like
# such as leading / trailing space.
#
class TextSentinel

  attr_accessor :text

  def self.non_symbols_regexp
    /[\ -\/\[-\`\:-\@\{-\~]/m
  end

  def initialize(text, opts=nil)
    @opts = opts || {}

    if text.present?
      @text = text.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      @text.gsub!(/ +/m, ' ') if @opts[:remove_interior_spaces]
      @text.strip! if @opts[:strip]
    end
  end

  def self.title_sentinel(text)
    TextSentinel.new(text,
                     min_entropy: SiteSetting.title_min_entropy,
                     max_word_length: SiteSetting.max_word_length,
                     remove_interior_spaces: true,
                     strip: true)
  end

  # Entropy is a number of how many unique characters the string needs.
  def entropy
    return 0 if @text.blank?
    @entropy ||= @text.strip.each_char.to_a.uniq.size
  end

  def valid?

    # Blank strings are not valid
    return false if @text.blank? || @text.strip.blank?

    # Entropy check if required
    return false if @opts[:min_entropy].present? and (entropy < @opts[:min_entropy])

    # We don't have a comprehensive list of symbols, but this will eliminate some noise
    non_symbols = @text.gsub(TextSentinel.non_symbols_regexp, '').size
    return false if non_symbols == 0

    # Don't allow super long strings without spaces

    return false if @opts[:max_word_length] and @text =~ /\w{#{@opts[:max_word_length]},}(\s|$)/

    # We don't allow all upper case content in english
    return false if (@text =~ /[A-Z]+/) and (@text == @text.upcase)

    true
  end

end
