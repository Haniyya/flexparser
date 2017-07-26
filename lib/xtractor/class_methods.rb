module Xtractor
  #
  # The ClassMethods defined on the including base.
  #
  module ClassMethods
    #
    # Applies the previously set up node-structure to the given xml
    # and returns Instances of the including Class.
    #
    def parse(xml, _options = {})
      return if parsers.empty?
      @doc = FragmentBuilder.build(xml)
      new.tap do |instance|
        parsers.each do |parser|
          instance.public_send("#{parser.name}=", parser.parse(@doc))
        end
      end
    end

    # no-doc
    def parsers
      @parsers ||= []
    end

    protected

    #
    # Defines a TagParser belonging to the including class.
    # This Tag parser is used in #parse to parse a piece of xml.
    # @param [Array<String>] tags The list of tags the parser rattles through.
    # @option opts [String] :name the name this property should have.
    #   Overrides the naming derived from the `tags` list.
    # @option opts [Symbol] :transform a method that will be sent to the
    #   resulting value to transofrm it. Like `:to_i` or `:to_sym`.
    # @option opts [Class] :type a class that implements `::parse` to
    #   return an instance of itself, parsed from the resulting value.
    # @option opts [Boolean] :required if true, raises an
    #   `Xtractor::RequiredMissingError` if the resulting value is `nil`.
    #
    def node(tags, **opts, &block)
      add_parser(TagParser, tags, opts, &block)
    end

    #
    # Defines a CollectionParser belonging to the including class.
    # @see self#node
    # @param sub_parser [Xtractor] a class that defines the `#parse` method that
    #   can deal with the data it receives.
    #
    def collection(tags, **opts, &block)
      add_parser(CollectionParser, tags, opts, &block)
    end

    #
    # Adds a parser with a given class and options to the list
    # of parsers this class holds.
    # @see self#node
    # @param klass [Xtractor::TagParser] either a collection or a single
    #   {TagParser}
    #
    def add_parser(klass, tags, **opts, &block)
      tags = Array(tags).flatten
      define_accessors(opts[:name] || tags.first)
      opts[:sub_parser] = new_parser(&block) if block_given?
      parsers << klass.new(tags, opts)
    end

    #
    # Creates a new anonymous Parser class based on {Xtractor::AnonymousParser}.
    # @param block [Block] The block that holds the classes parser,
    #   methods and so on.
    #
    def new_parser(&block)
      klass = Class.new(AnonymousParser)
      klass.instance_eval(&block)
      klass
    end

    #
    # Defines accesors with a given name after sanitizing that name.
    # @param name [String] the name the accessors shoudl have.
    #   Will most likely be a tag.
    #
    def define_accessors(name)
      attr_accessor name.to_s.sub(/^@/, '').gsub(/([[:punct:]]|-)+/, '_')
    end
  end
end
