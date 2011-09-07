module FactoryGirl
  module Declaration
    class Dynamic
      def initialize(name, block)
        @name = name
        @block = block
      end

      def to_attribute
        Attribute::Dynamic.new(@name, @block)
      end
    end
  end
end
