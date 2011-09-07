module FactoryGirl
  class Trait
    attr_reader :name

    def initialize(name, &block) #:nodoc:
      @name = name
      @declarations = []
      @attribute_list = AttributeList.new

      proxy = FactoryGirl::DefinitionProxy.new(self)
      proxy.instance_eval(&block) if block_given?
    end

    def declare_attribute(attribute)
      @declarations << attribute
      attribute
    end

    def add_callback(name, &block)
      @attribute_list.add_callback(name, &block)
    end

    def attributes
      @declarations.map { |declaration| declaration.to_attribute } +
        @attribute_list.to_a
    end

    def names
      [@name]
    end
  end
end
