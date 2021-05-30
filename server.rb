require "socket"
require "yaml/store"
require "cgi"
require_relative "responses.rb"
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
        # TODO: change signature to ...root.respond or ...respond(:root) ot sth like that
        # or: define private method like respond(:root) + instance variable to remove repetitive clutter
        GetResponse.new(client, request).root
      when ["POST", ""]
        PostResponse.new(client, request).root
      when ["GET", "/time"]
        GetResponse.new(client, request).time
      else
        GetResponse.new(client, request).missing_endpoint
      end

      puts "" # newlines between requests in server console
      client.close
    end
  end
end

Server.new.start

# TODO: rack app? see e.g.:
# https://blog.appsignal.com/2016/11/23/ruby-magic-building-a-30-line-http-server-in-ruby.html
