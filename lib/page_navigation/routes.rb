module PageNavigation
  module Routes
    
    def routes
      @routes
    end
    
    def routes=(routes)
      raise("You must provide a :default route") unless routes[:default]
      @routes = routes
    end
  end
end
