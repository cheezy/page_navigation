require 'spec_helper'

class FirstPage
end

class MiddlePage
end

class LastPage
end

class TestNavigator
  include PageNavigation
  attr_accessor :current_page

  def on(cls) #placeholder for PageFactory's on_page (alias 'on')
    cls.new
  end

  def visit(cls) #placeholder for PageFactory's visit_page (alias 'visit')
    page_instance = cls.new
    page_instance.visit
    page_instance
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
    allow(DataMagic).to receive(:load)
  end

  it 'should raise an error when you do not provide a default route' do
    expect { TestNavigator.routes = {:another => []} }.to raise_error 'You must provide a :default route'
  end

  it 'should store the routes' do
    routes = %w(a b c)
    TestNavigator.routes = {:default => routes}
    expect(TestNavigator.routes[:default]).to be routes
  end

  it 'should store route data' do
    TestNavigator.route_data = {:default => :blah}
    expect(TestNavigator.route_data).to eq ({:default => :blah})
  end

  it 'should navigate to a page calling the default methods' do
    pages = [[FirstPage, :a_method], [MiddlePage, :b_method]]
    TestNavigator.routes = {:default => pages}
    fake_page = double('middle_page')
    expect(FirstPage).to receive(:new).and_return(fake_page)
    expect(fake_page).to receive(:a_method)
    expect(@navigator.navigate_to(MiddlePage).class).to be MiddlePage
  end

  it 'should load the DataMagic file when specified' do
    pages = [[FirstPage, :a_method], [MiddlePage, :b_method]]
    TestNavigator.routes = {:default => pages}
    TestNavigator.route_data = {:default => :dm_file}
    fake_page = double('middle_page')
    expect(FirstPage).to receive(:new).and_return(fake_page)
    expect(fake_page).to receive(:a_method)
    expect(DataMagic).to receive(:load).with('dm_file.yml')
    expect(@navigator.navigate_to(MiddlePage).class).to be MiddlePage
  end

  it 'should pass parameters to methods when navigating' do
    pages = [[FirstPage, :a_method, 'blah'], [MiddlePage, :b_method]]
    TestNavigator.routes = {:default => pages}
    fake_page = double('middle_page')
    expect(FirstPage).to receive(:new).and_return(fake_page)
    expect(fake_page).to receive(:a_method).with('blah')
    expect(@navigator.navigate_to(MiddlePage).class).to be MiddlePage
  end

  it 'should fail when it does not find a proper route' do
    TestNavigator.routes = {:default => ['a'], :another => ['b']}
    expect { @navigator.navigate_to(MiddlePage, :using => :no_route) }.to raise_error
  end

  it 'should fail when no default method specified' do
    TestNavigator.routes = {
      :default => [[FirstPage, :a_method], [MiddlePage, :b_method]]
    }
    fake_page = double('middle_page')
    expect(FirstPage).to receive(:new).and_return(fake_page)
    expect(fake_page).to receive(:respond_to?).with(:a_method).and_return(false)
    expect { @navigator.navigate_to(MiddlePage) }.to raise_error
  end

  it 'should know how to continue routing from a location' do
    first_page, middle_page, last_page = mock_common_method_calls

    @navigator.current_page = FirstPage.new
    
    expect(first_page).to receive(:a_method)
    expect(middle_page).to receive(:b_method)

    expect(@navigator.continue_navigation_to(LastPage).class).to be LastPage
  end

  it 'should know how to continue routing from a location that is one page from the end' do
    first_page, middle_page, last_page = mock_common_method_calls

    @navigator.current_page = MiddlePage.new

    expect(first_page).not_to receive(:a_method)
    expect(middle_page).to receive(:b_method)

    expect(@navigator.continue_navigation_to(LastPage).class).to be LastPage
  end

  it 'should know how to navigate an entire route including the last page' do
    first_page, middle_page, last_page = mock_common_method_calls

    expect(first_page).to receive(:a_method)
    expect(middle_page).to receive(:b_method)
    expect(last_page).to receive(:c_method)

    @navigator.navigate_all
  end

  it 'should be able to start in the middle of a route and proceed' do
    first_page, middle_page, last_page = mock_common_method_calls

    expect(first_page).not_to receive(:a_method)
    expect(middle_page).to receive(:b_method)

    @navigator.navigate_to(LastPage, :from => MiddlePage)
  end

  it 'should visit page at start of route given visit param set to true' do
    first_page, middle_page, last_page = mock_common_method_calls

    expect(first_page).to receive(:visit)
    expect(first_page).to receive(:a_method)
    expect(middle_page).to receive(:b_method)
    expect(middle_page).not_to receive(:visit)

    @navigator.navigate_to(LastPage, visit: true)
  end

  it 'should not visit page at start of route given visit param set to false (explicit)' do
    first_page, middle_page, last_page = mock_common_method_calls

    expect(first_page).not_to receive(:visit)
    expect(first_page).to receive(:a_method)
    expect(middle_page).to receive(:b_method)

    @navigator.navigate_to(LastPage, visit: false)
  end

  it 'should not visit page at start of route given visit param set to false (default)' do
    first_page, middle_page, last_page = mock_common_method_calls

    expect(first_page).not_to receive(:visit)
    expect(first_page).to receive(:a_method)
    expect(middle_page).to receive(:b_method)

    @navigator.navigate_to(LastPage)
  end

  it 'should handle specification of both using and visit params' do
    first_page, middle_page, last_page = mock_common_method_calls

    expect(first_page).to receive(:respond_to?).with(:x_method).at_least(:once).and_return(true)
    expect(first_page).to receive(:visit)
    expect(first_page).to receive(:x_method)
    expect(middle_page).to receive(:respond_to?).with(:y_method).at_least(:once).and_return(true)
    expect(middle_page).to receive(:y_method)
    expect(middle_page).not_to receive(:visit)

    @navigator.navigate_to(LastPage, visit: true, using: :alt)
  end
end

def mock_common_method_calls
  TestNavigator.routes = {
      :default => [[FirstPage, :a_method],
                   [MiddlePage, :b_method],
                   [LastPage, :c_method]],
      :alt => [[FirstPage, :x_method],
               [MiddlePage, :y_method],
               [LastPage, :z_method]]
  }

  first_page = FirstPage.new
  allow(FirstPage).to receive(:new).and_return(first_page)
  allow(first_page).to receive(:respond_to?).with(:visit).and_return(true)
  allow(first_page).to receive(:respond_to?).with(:a_method).and_return(true)

  middle_page = MiddlePage.new
  allow(MiddlePage).to receive(:new).and_return(middle_page)
  allow(middle_page).to receive(:respond_to?).with(:visit).and_return(true)
  allow(middle_page).to receive(:respond_to?).with(:b_method).and_return(true)

  last_page = LastPage.new
  allow(LastPage).to receive(:new).and_return(last_page)
  allow(last_page).to receive(:respond_to?).with(:visit).and_return(true)
  allow(last_page).to receive(:respond_to?).with(:c_method).and_return(true)

  return first_page, middle_page, last_page
end
