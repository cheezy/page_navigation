module PageNavigation
  module Routes
    
    def routes
      @routes
    end
    
    def routes=(routes)
      raise('You must provide a :default route') unless routes[:default]
      @routes = routes
    end

    def route_data
      @route_data 
    end

    def route_data=(data)
      @route_data = data
    end
  end
end
