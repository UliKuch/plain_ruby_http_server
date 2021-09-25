require "socket"
require_relative "controller"
require_relative "request"
require_relative "router"
require_relative "config/routes"

class HttpServer
  def self.start
    config = YAML.load_file("config/config.yml")
    server = TCPServer.new(config["port"])

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
