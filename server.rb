require "socket"
require_relative "response"
require_relative "controller"
require_relative "app/controllers"
require_relative "request"
require_relative "router"
require_relative "config/routes"

class HttpServer
  DEFAULT_PORT = 3456

  def self.start
    config = YAML.load_file("config/config.yml")
    port = config["port"]
    server = TCPServer.new(port || DEFAULT_PORT)
    puts "Server running on http://localhost:#{port}", ""

    loop do
      Thread.new(server.accept) do |client|
        request = Request.new(client).read

        case Router.route(request)
          in {controller:, action:}
        end

        response = controller.new(request).send(action)
        client.puts response.to_s

        puts "Responded with status code: #{response.status}"
        puts "Response headers: #{response.headers}"
        puts "" # newlines between requests in server console

        client.close
      end
    end
  end
end
