require 'spec_helper'

class FactoryTestPage
end

class AnotherPage
end

class YetAnotherPage
end

class TestNavigator
  include PageNavigation
  attr_accessor :current_page

  def on(cls)
    cls.new
  end

  def class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  end
end

describe PageNavigation do
  before(:each) do
    @navigator = TestNavigator.new
  end

  it "should raise an error when you do not provide a default route" do
    expect { TestNavigator.routes = {:another => []} }.to raise_error
  end

  it "should store the routes" do
    routes = ['a', 'b', 'c']
    TestNavigator.routes = {:default => routes}
    TestNavigator.routes[:default].should == routes
  end

  it "should navigate to a page calling the default methods" do
    pages = [[FactoryTestPage, :a_method], [AnotherPage, :b_method]]
    TestNavigator.routes = {:default => pages}
    fake_page = double('a_page')
    FactoryTestPage.should_receive(:new).and_return(fake_page)
    fake_page.should_receive(:a_method)
    @navigator.navigate_to(AnotherPage).class.should == AnotherPage
  end

  it "should pass parameters to methods when navigating" do
    pages = [[FactoryTestPage, :a_method, 'blah'], [AnotherPage, :b_method]]
    TestNavigator.routes = {:default => pages}
    fake_page = double('a_page')
    FactoryTestPage.should_receive(:new).and_return(fake_page)
    fake_page.should_receive(:a_method).with('blah')
    @navigator.navigate_to(AnotherPage).class.should == AnotherPage
  end

  it "should fail when it does not find a proper route" do
    TestNavigator.routes = {:default => ['a'], :another => ['b']}
    expect { @navigator.navigate_to(AnotherPage, :using => :no_route) }.to raise_error
  end

  it "should fail when no default method specified" do
    TestNavigator.routes = {
      :default => [[FactoryTestPage, :a_method], [AnotherPage, :b_method]]
    }
    fake_page = double('a_page')
    FactoryTestPage.should_receive(:new).and_return(fake_page)
    fake_page.should_receive(:respond_to?).with(:a_method).and_return(false)
    expect { @navigator.navigate_to(AnotherPage) }.to raise_error
  end

  it "should know how to continue routng from a location" do
    TestNavigator.routes = {
      :default => [[FactoryTestPage, :a_method],
                   [AnotherPage, :b_method],
                   [YetAnotherPage, :c_method]]
    }
    fake_page = double('a_page')
    AnotherPage.should_receive(:new).and_return(fake_page)
    fake_page.should_receive(:respond_to?).with(:b_method).and_return(true)
    fake_page.should_receive(:b_method)
    @navigator.current_page = FactoryTestPage.new
    FactoryTestPage.should_not_receive(:new)
    @navigator.continue_navigation_to(YetAnotherPage).class.should == YetAnotherPage
  end
end
