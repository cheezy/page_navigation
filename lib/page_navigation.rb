require "page_navigation/version"
require "page_navigation/routes"
require 'data_magic'

#
# Implements basic navigation capabilities for a collection of classes
# that implement a PageObject like pattern.
#
# In order to use these two methods you must define routes.  A route
# is simply an array of Class/Method calls and can contain parameters
# that can be passed to the methods.  Here is an example:
#
# @example Example routes defined in env.rb
#   MyNavigator.routes = {
#     :default => [[PageOne,:method1], [PageTwoA,:method2], [PageThree,:method3]],
#     :another_route => [[PageOne,:method1, "arg1"], [PageTwoB,:method2b], [PageThree,:method3]]
#   }
#
# Notice the first entry of :another_route is passing an argument
# to the method.
#
# The user must also maintain an instance variable named @current_page
# which points to the current object in the array.
# 
module PageNavigation

  def self.included(cls)
    cls.extend PageNavigation::Routes
    @cls = cls
  end

  def self.cls
    @cls
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
  # @param [PageObject] page_cls a class that implements the PageObject pattern.
  # @param [Hash] how a hash that contains two elements. One with the key
  # :using.  This will be used to lookup the route.  It has a
  # default value of :default. The other is with the key :visit. This specifies
  # whether to explicitly visit the first page. It has a default value of false.
  # @param [block] block an optional block to be called
  # @return [PageObject] the page you are navigating to
  #
  def navigate_to(page_cls, how = {:using => :default, :visit => false}, &block)
    how[:using] = :default unless how[:using]
    how[:visit] = false unless how[:visit]
    path = path_for how
    to_index = find_index_for(path, page_cls)-1
    if to_index == -1
      return on(page_cls, &block)
    else
      start = how[:from] ? path.find_index { |entry| entry[0] == how[:from] } : 0
      navigate_through_pages(path[start..to_index], how[:visit])
    end
    on(page_cls, &block)
  end

  #
  # Same as navigate_to except it will start at the @current_page
  # instead the beginning of the path.
  #
  # @param [PageObject] page_cls a class that implements the PageObject pattern.
  # @param [Hash] how a hash that contains an element with the key
  # :using.  This will be used to lookup the route.  It has a
  # default value of :default.
  # @param [block] block an optional block to be called
  # @return [PageObject] the page you are navigating to
  #
  def continue_navigation_to(page_cls, how = {:using => :default}, &block)
    path = path_for how
    from_index = find_index_for(path, @current_page.class)
    to_index = find_index_for(path, page_cls)-1
    if from_index == to_index
      navigate_through_pages([path[from_index]], false)
    else
      navigate_through_pages(path[from_index..to_index], false)
    end
    on(page_cls, &block)
  end

  #
  # Navigate through a complete route.
  #
  # This method will navigate an entire route executing all of the
  # methods.  Since it completes the route it does not return any
  # pages and it does not accept a block.
  #
  # @example
  #   page.navigate_all  # will use the default path
  #   page.navigate_all(:using => :another_route)
  #
  # @param [Hash] how a hash that contains two elements. One with the key
  # :using.  This will be used to lookup the route.  It has a
  # default value of :default. The other is with the key :visit. This specifies
  # whether to explicitly visit the first page. It has a default value of false.
  #
  def navigate_all(how = {:using => :default, :visit => false})
    path = path_for how
    navigate_through_pages(path[0..-1], how[:visit])
  end
  
  private

  def path_for(how)
    path = PageNavigation.cls.routes[how[:using]]
    fail("PageFactory route :#{how[:using].to_s} not found") unless path
    if PageNavigation.cls.route_data
      file_to_load = PageNavigation.cls.route_data[how[:using]]
      DataMagic.load "#{file_to_load.to_s}.yml" if file_to_load
    end
    path
  end
  
  def navigate_through_pages(pages, visit)
    pages.each do |cls, method, *args|
      page = visit ? visit(cls) : on(cls)
      visit = false # visit once, for just the first page
      fail("Navigation method '#{method}' not defined on #{cls}.") unless page.respond_to? method
      page.send method unless args
      page.send method, *args if args
    end
  end

  def find_index_for(path, item)
    path.find_index { |each| each[0] == item}
  end

end
