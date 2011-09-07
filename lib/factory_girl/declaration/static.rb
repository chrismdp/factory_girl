module FactoryGirl
  module Declaration
    class Static
      def initialize(name, value)
        @name = name
        @value = value
      end

      def to_attribute
        Attribute::Static.new(@name, @value)
      end
    end
  end
end
