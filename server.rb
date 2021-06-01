require "socket"
require_relative "controller"
require_relative "request"
require_relative "router"

class HttpServer
  def self.start
    server = TCPServer.new(3456)
    # TODO: store routes somewhere else
    # TODO: add some more (nested) routes
    router = Router.new do
      get "", controller: GetController, action: :root
      post "", controller: PostController, action: :root
      get "/time", controller: GetController # TODO: remove /
    end

    loop do
      Thread.new(server.accept) do |client|
        request = Request.new(client).read

        case router.route(request)
          in {controller:, action:}
        end

        response = controller.new(request).send(action)
        client.puts response.to_s

        puts "" # newlines between requests in server console
        client.close
      end
    end
  end
end

HttpServer.start

# TODO: rack app? see e.g.:
# https://blog.appsignal.com/2016/11/23/ruby-magic-building-a-30-line-http-server-in-ruby.html
