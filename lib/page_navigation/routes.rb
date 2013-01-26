module PageNavigation
  module Routes
    attr_accessor :routes
    
    def routes=(routes)
      raise("You must provide a :default route") unless routes[:default]
      @routes = routes
    end
  end
end
