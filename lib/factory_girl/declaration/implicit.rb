module FactoryGirl
  module Declaration
    class Implicit
      def initialize(name, factory = nil)
        @name = name
        @factory = factory
      end

      def to_attribute
        if FactoryGirl.factories.registered?(@name)
          Attribute::Association.new(@name, @name, {})
        elsif FactoryGirl.sequences.registered?(@name)
          Attribute::Sequence.new(@name, @name)
        else
          Attribute::Trait.new(@name, @factory)
        end
      end
    end
  end
end
