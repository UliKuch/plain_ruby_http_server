require "socket"
require "yaml/store"
require "cgi"
require_relative "controller.rb"
require_relative "request.rb"

class Server
  def start
    server = TCPServer.new(3456)

    loop do
      client = server.accept
      request = Request.new(client)

      # server console output
      puts "Request received: #{request.request_line}"
      puts "Request method is #{request.method}, full path is #{request.full_path} (path: #{request.path}, query: #{request.query}) and protocol is #{request.protocol}."
      puts "Headers: #{request.headers}"

      # routes
      case [request.method, request.path.chomp("/")]
      when ["GET", ""]
        GetController.new(client, request).root
      when ["POST", ""]
        PostController.new(client, request).root
      when ["GET", "/time"]
        GetController.new(client, request).time
      else
        GetController.new(client, request).missing_endpoint
      end

      puts "" # newlines between requests in server console
      client.close
    end
  end
end

Server.new.start

# TODO: rack app? see e.g.:
# https://blog.appsignal.com/2016/11/23/ruby-magic-building-a-30-line-http-server-in-ruby.html
