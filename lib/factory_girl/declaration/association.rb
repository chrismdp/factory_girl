module FactoryGirl
  module Declaration
    class Association
      def initialize(name, options)
        @name = name
        @options = options
      end

      def to_attribute
        factory_name = @options.delete(:factory) || @name
        Attribute::Association.new(@name, factory_name, @options)
      end
    end
  end
end
