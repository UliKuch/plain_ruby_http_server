class Router
  # TODO: Use specific ErrorController?
  NOT_FOUND = {controller: GetController, action: :missing_endpoint}
  BAD_REQUEST = {controller: GetController, action: :bad_request}

  class << self
    def config(&block)
      @@routes_hash = {}
      instance_eval(&block)
    end

    def route(request)
      method = request.method
      path = request.path&.chomp("/")

      return BAD_REQUEST if method.nil? || path.nil?

      @@routes_hash.dig(path, method) || NOT_FOUND
    end

    private

    # define methods for http methods to allow for expressive route definitions
    [:get, :post, :put, :patch, :delete].each do |method|
      define_method(method) do |route_name, controller:, action: nil|
        default_or_custom_action = action.nil? ? route_name.split("/").last : action
        # TODO: add some default controller name (and change current controller names)

        add_route(
          route_name,
          controller: controller,
          action: default_or_custom_action,
          method: method.to_s.upcase
        )
      end
    end

    # builds routes hash like thie:
    # {
    #   "" => {
    #     "GET" => {
    #       controller: GetController,
    #       action: :root
    #     },
    #     "POST" =>  {
    #       controller: PostController,
    #       action: :root
    #     }
    #   },
    #   "/endpoint" => {
    #     "GET" => {
    #       controller: GetController,
    #       action: :time
    #     }
    #   }
    # }
    def add_route(route_name, controller:, action:, method:)
      # TODO: split("/") nested routes

      @@routes_hash[route_name] ||= {}
      @@routes_hash[route_name][method] = {controller: controller, action: action}
    end
  end
end
