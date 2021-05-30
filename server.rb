require "socket"
require_relative "controller"
require_relative "request"

class HttpServer
  def self.start
    server = TCPServer.new(3456)

    loop do
      client = server.accept
      request = Request.new(client)

      # server console output
      puts "Request received: #{request.request_line}"
      puts "Request method is #{request.method}, full path is #{request.full_path} (path: #{request.path}, query: #{request.query}) and protocol is #{request.protocol}."
      puts "Headers: #{request.headers}"
      puts "Body: #{request.body}"

      # routes
      response = case [request.method, request.path.chomp("/")]
      when ["GET", ""]
        GetController.new(request).root
      when ["POST", ""]
        PostController.new(request).root
      when ["GET", "/time"]
        GetController.new(request).time
      else
        GetController.new(request).missing_endpoint
      end

      client.puts response

      puts "" # newlines between requests in server console
      client.close
    end
  end
end

HttpServer.start

# TODO: rack app? see e.g.:
# https://blog.appsignal.com/2016/11/23/ruby-magic-building-a-30-line-http-server-in-ruby.html
