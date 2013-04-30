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
    DataMagic.stub(:load)
  end

  it "should raise an error when you do not provide a default route" do
    expect { TestNavigator.routes = {:another => []} }.to raise_error
  end

  it "should store the routes" do
    routes = ['a', 'b', 'c']
    TestNavigator.routes = {:default => routes}
    TestNavigator.routes[:default].should == routes
  end

  it "should store route data" do
    TestNavigator.route_data = {:default => :blah}
    TestNavigator.route_data.should == {:default => :blah}
  end

  it "should navigate to a page calling the default methods" do
    pages = [[FactoryTestPage, :a_method], [AnotherPage, :b_method]]
    TestNavigator.routes = {:default => pages}
    fake_page = double('a_page')
    FactoryTestPage.should_receive(:new).and_return(fake_page)
    fake_page.should_receive(:a_method)
    @navigator.navigate_to(AnotherPage).class.should == AnotherPage
  end

  it "should load the DataMagic file when specified" do
    pages = [[FactoryTestPage, :a_method], [AnotherPage, :b_method]]
    TestNavigator.routes = {:default => pages}
    TestNavigator.route_data = {:default => :dm_file}
    fake_page = double('a_page')
    FactoryTestPage.should_receive(:new).and_return(fake_page)
    fake_page.should_receive(:a_method)
    DataMagic.should_receive(:load).with('dm_file.yml')
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
    @navigator.current_page = FactoryTestPage.new
    f_page = FactoryTestPage.new
    a_page = AnotherPage.new
    FactoryTestPage.should_receive(:new).and_return(f_page)
    f_page.should_receive(:respond_to?).with(:a_method).and_return(true)
    f_page.should_receive(:a_method)
    AnotherPage.should_receive(:new).and_return(a_page)
    a_page.should_receive(:respond_to?).with(:b_method).and_return(true)
    a_page.should_receive(:b_method)
    @navigator.continue_navigation_to(YetAnotherPage).class.should == YetAnotherPage
  end

  it "should know how to continue routng from a location that is one page from the end" do
    TestNavigator.routes = {
      :default => [[FactoryTestPage, :a_method],
                   [AnotherPage, :b_method],
                   [YetAnotherPage, :c_method]]
    }
    @navigator.current_page = FactoryTestPage.new
    f_page = FactoryTestPage.new
    FactoryTestPage.should_receive(:new).and_return(f_page)
    f_page.should_receive(:respond_to?).with(:a_method).and_return(true)
    f_page.should_receive(:a_method)
    a_page = AnotherPage.new
    AnotherPage.should_receive(:new).and_return(a_page)
    a_page.should_receive(:respond_to?).with(:b_method).and_return(true)
    a_page.should_receive(:b_method)
    @navigator.continue_navigation_to(YetAnotherPage).class.should == YetAnotherPage
  end

  it "should know how to navigate an entire route including the last page" do
    TestNavigator.routes = {
      :default => [[FactoryTestPage, :a_method],
                   [AnotherPage, :b_method],
                   [YetAnotherPage, :c_method]]
    }
    f_page = FactoryTestPage.new
    a_page = AnotherPage.new
    y_page = YetAnotherPage.new
    FactoryTestPage.should_receive(:new).and_return(f_page)
    f_page.should_receive(:respond_to?).with(:a_method).and_return(true)
    f_page.should_receive(:a_method)
    AnotherPage.should_receive(:new).and_return(a_page)
    a_page.should_receive(:respond_to?).with(:b_method).and_return(true)
    a_page.should_receive(:b_method)
    YetAnotherPage.should_receive(:new).and_return(y_page)
    y_page.should_receive(:respond_to?).with(:c_method).and_return(true)
    y_page.should_receive(:c_method)
    @navigator.navigate_all
  end

  it "should be able to start in the middle of a route and proceed" do
    TestNavigator.routes = {
      :default => [[FactoryTestPage, :a_method],
                   [AnotherPage, :b_method],
                   [YetAnotherPage, :c_method]]
    }
    a_page = AnotherPage.new
    y_page = YetAnotherPage.new
    AnotherPage.should_receive(:new).and_return(a_page)
    a_page.should_receive(:respond_to?).with(:b_method).and_return(true)
    a_page.should_receive(:b_method)
    YetAnotherPage.should_receive(:new).and_return(y_page)
    @navigator.navigate_to(YetAnotherPage, :from => AnotherPage)
  end
end
