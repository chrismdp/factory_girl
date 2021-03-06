require 'spec_helper'

describe FactoryGirl::DefinitionProxy do
  let(:factory) { FactoryGirl::Factory.new(:object) }
  subject { FactoryGirl::DefinitionProxy.new(factory) }

  it "should add a static attribute for type" do
    subject.type 'value'
    factory.attributes.last.should be_kind_of(FactoryGirl::Attribute::Static)
  end

  it "should add a static attribute for id" do
    subject.id 'value'
    factory.attributes.last.should be_kind_of(FactoryGirl::Attribute::Static)
  end

  it "should add a static attribute when an attribute is defined with a value" do
    attribute = stub('attribute', :name => :name)
    FactoryGirl::Attribute::Static.stubs(:new => attribute)
    factory.stubs(:define_attribute)
    subject.add_attribute(:name, 'value')
    factory.should have_received(:define_attribute).with(attribute)
    FactoryGirl::Attribute::Static.should have_received(:new).with(:name, "value")
  end

  it "should add a dynamic attribute when an attribute is defined with a block" do
    attribute = stub('attribute', :name => :name)
    block     = lambda {}
    FactoryGirl::Attribute::Dynamic.stubs(:new => attribute)
    factory.stubs(:define_attribute)
    subject.add_attribute(:name, &block)
    FactoryGirl::Attribute::Dynamic.should have_received(:new).with(:name, block)
    factory.should have_received(:define_attribute).with(attribute)
  end

  it "should raise for an attribute with a value and a block" do
    lambda {
      subject.add_attribute(:name, 'value') {}
    }.should raise_error(FactoryGirl::AttributeDefinitionError)
  end

  it "should add an attribute with a built-in private method" do
    subject.instance_eval { sleep(0.1) }
    factory.attributes.map { |attribute| attribute.name }.should == [:sleep]
  end

  describe "child factories" do
    its(:child_factories) { should == [] }

    it "should be able to add child factories" do
      block = lambda {}
      subject.factory(:admin, { :aliases => [:great] }, &block)
      subject.child_factories.should == [[:admin, { :aliases => [:great] }, block]]
    end
  end

  describe "adding an attribute using a in-line sequence" do
    it "should create the sequence" do
      FactoryGirl::Sequence.stubs(:new)
      subject.sequence(:name) {}
      FactoryGirl::Sequence.should have_received(:new).with(:name, 1)
    end

    it "should create the sequence with a custom default value" do
      FactoryGirl::Sequence.stubs(:new)
      subject.sequence(:name, "A") {}
      FactoryGirl::Sequence.should have_received(:new).with(:name, "A")
    end
  end

  it "adds an implicit attribute when passed an undefined method without arguments or a block" do
    factory.stubs(:define_attribute)
    attribute = stub('attribute', :name => :name)
    FactoryGirl::Attribute::Implicit.stubs(:new => attribute)
    subject.send(:name)
    FactoryGirl::Attribute::Implicit.should have_received(:new).with(:name, factory)
    factory.should have_received(:define_attribute).with(attribute)
  end
end

describe FactoryGirl::DefinitionProxy, "with a factory mock" do
  before do
    define_class("FactoryMock") do
      def add_callback(callback, &block)
        [callback, block.call]
      end

      def to_create(&block)
        block.call
      end
    end
  end

  let(:factory_mock) { FactoryMock.new }
  subject { FactoryGirl::DefinitionProxy.new(factory_mock) }

  it "defines after_build callbacks" do
    subject.after_build { "after_build value" }.should == [:after_build, "after_build value"]
  end

  it "defines after_create callbacks" do
    subject.after_create { "after_create value" }.should == [:after_create, "after_create value"]
  end

  it "defines after_stub callbacks" do
    subject.after_stub { "after_stub value" }.should == [:after_stub, "after_stub value"]
  end

  it "defines to_create" do
    subject.to_create { "to_create value" }.should == "to_create value"
  end
end

describe FactoryGirl::DefinitionProxy, "adding attributes" do
  let(:factory)         { FactoryGirl::Factory.new(:object) }
  subject               { FactoryGirl::DefinitionProxy.new(factory) }
  let(:attribute)       { stub("created attribute") }
  let(:block)           { lambda { } }
  let(:attribute_name)  { :full_name }
  let(:attribute_value) { "passed value" }

  before { factory.stubs(:define_attribute) }

  context "when a block is passed" do
    before { FactoryGirl::Attribute::Dynamic.stubs(:new => attribute) }

    it "creates a dynamic attribute" do
      subject.add_attribute(attribute_name, &block)
      FactoryGirl::Attribute::Dynamic.should have_received(:new).with(attribute_name, block)
      factory.should have_received(:define_attribute).with(attribute)
    end

    it "creates a dynamic attribute without the method being defined" do
      subject.send(attribute_name, &block)
      FactoryGirl::Attribute::Dynamic.should have_received(:new).with(attribute_name, block)
      factory.should have_received(:define_attribute).with(attribute)
    end
  end

  context "when a value is passed" do
    before { FactoryGirl::Attribute::Static.stubs(:new => attribute) }

    it "creates a static attribute" do
      subject.add_attribute(attribute_name, attribute_value)
      FactoryGirl::Attribute::Static.should have_received(:new).with(attribute_name, attribute_value)
      factory.should have_received(:define_attribute).with(attribute)
    end

    it "creates a static attribute without the method being defined" do
      subject.send(attribute_name, attribute_value)
      FactoryGirl::Attribute::Static.should have_received(:new).with(attribute_name, attribute_value)
      factory.should have_received(:define_attribute).with(attribute)
    end
  end

  context "when a block and value are passed" do
    it "raises an exception" do
      expect do
        subject.add_attribute(attribute_name, attribute_value) { "block" }
      end.to raise_error(FactoryGirl::AttributeDefinitionError, "Both value and block given")
    end
  end
end

describe FactoryGirl::DefinitionProxy, "#association" do
  let(:factory)          { FactoryGirl::Factory.new(:object) }
  subject                { FactoryGirl::DefinitionProxy.new(factory) }
  let(:attribute)        { stub("attribute") }
  let(:association_name) { :author }
  let(:factory_name)     { :user }

  before do
    FactoryGirl::Attribute::Association.stubs(:new => attribute)
    factory.stubs(:define_attribute)
  end

  context "with a factory set in the hash" do
    let(:options) { { :factory => factory_name, :name => "John Doe" } }

    it "defines an association attribute with the factory name" do
      subject.association(association_name, options)

      factory.should have_received(:define_attribute).with(attribute)
      FactoryGirl::Attribute::Association.should have_received(:new).with(association_name, factory_name, :name => "John Doe")
    end

    it "defines an association attribute when the association is called implicitly" do
      subject.send(association_name, options)

      factory.should have_received(:define_attribute).with(attribute)
      FactoryGirl::Attribute::Association.should have_received(:new).with(association_name, factory_name, :name => "John Doe")
    end
  end

  context "without a factory set in the hash" do
    let(:options) { { :name => "Jane Doe" } }

    it "defines an association attribute with the association name" do
      subject.association(association_name, options)

      factory.should have_received(:define_attribute).with(attribute)
      FactoryGirl::Attribute::Association.should have_received(:new).with(association_name, association_name, options)
    end
  end
end
