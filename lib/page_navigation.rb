require "page_navigation/version"
require "page_navigation/routes"

#
# Implements basic navigation capabilities for a collection of classes
# that implement a PageObject like pattern.
#
# In order to use these two methods you must define routes.  A route
# is cimply an array of Class/Method calls and can contain parameters
# that can be passed to the methods.  Here is an example:
#
# @example Example routes defined in env.rb
#   MyNavigator.routes = {
#     :default => [[PageOne,:method1], [PageTwoA,:method2], [PageThree,:method3]],
#     :another_route => [[PageOne,:method1, "arg1"], [PageTwoB,:method2b], [PageThree,:method3]]
#   }
#
# Notice the first entry of :anouther_route is passing an argument
# to the method.
#
# The user must also maintain an instance variable named @current_page
# which points to the current object in the array.
# 
module PageNavigation

  def self.included(cls)
    cls.extend PageNavigation::Routes
  end


  #
  # Navigate to a specific page following a predefined path.
  #
  # This method requires a lot of setup.  See the documentation for
  # this module.  Once the setup is complete you can navigate to a
  # page traversing through all other pages along the way.  It will
  # call the method you specified in the routes for each
  # page as it navigates.  Using the example setup defined in the
  # documentation above you can call the method two ways:
  #
  # @example
  #   page.navigate_to(PageThree)  # will use the default path
  #   page.navigate_to(PageThree, :using => :another_route)
  #
  # @param [PageObject]  a class that implements the PageObject pattern.
  # @param [Hash] a hash that contains an element with the key
  # :using.  This will be used to lookup the route.  It has a
  # default value of :default.
  # @param [block]  an optional block to be called
  # @return [PageObject] the page you are navigating to
  #
  def navigate_to(page_cls, how = {:using => :default}, &block)
    path = path_for how
    to_index = find_index_for(path, page_cls)-1
    navigate_through_pages(path[0..to_index])
    on(page_cls, &block)
  end

  #
  # Same as navigate_to except it will start at the @current_page
  # instead the beginning of the path.
  #
  # @param [PageObject]  a class that implements the PageObject pattern.
  # @param [Hash] a hash that contains an element with the key
  # :using.  This will be used to lookup the route.  It has a
  # default value of :default.
  # @param [block]  an optional block to be called
  # @return [PageObject] the page you are navigating to
  #
  def continue_navigation_to(page_cls, how = {:using => :default}, &block)
    path = path_for how
    from_index = find_index_for(path, @current_page.class)+1
    to_index = find_index_for(path, page_cls)-1
    navigate_through_pages(path[from_index..to_index])
    on(page_cls, &block)
  end

  
  private

  def path_for(how)
    path = self.class.routes[how[:using]]
    fail("PageFactory route :#{how[:using].to_s} not found") unless path
    path
  end
  
  def navigate_through_pages(pages)
    pages.each do |cls, method, *args|
      page = on(cls)
      fail("Navigation method not specified on #{cls}.") unless page.respond_to? method
      page.send method unless args
      page.send method, *args if args
    end
  end

  def find_index_for(path, item)
    path.find_index { |each| each[0] == item}
  end

  def self.included(cls)
    cls.extend PageNavigation::Routes
  end
end
