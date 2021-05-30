require "socket"
require "yaml/store"
require "cgi"
require_relative "responses.rb"

class Server
  def start
    server = TCPServer.new(3456)

    loop do
      client = server.accept

      # TODO: instead: request = Request.new(request_line)

      request = {}
      request["request_line"] = client.gets.chomp("\r\n")
      request["method"], request["full_path"], request["protocol"] = request["request_line"].split
      request["path"], request["query"] = request["full_path"].split("?")
      request["headers"] = {}

      # get headers
      while line = client.gets
        break if line == "\r\n" # newline separates headers from body
        header, content = line.split(": ", 2)
        request["headers"][header] = content.chomp("\r\n")
      end

      # get body
      body_length = request["headers"]["Content-Length"].to_i
      request["body"] = client.read(body_length)

      # server console output
      puts "Request received: #{request["request_line"]}"
      puts "Request method is #{request["method"]}, full path is #{request["full_path"]} (path: #{request["path"]}, query: #{request["query"]}) and protocol is #{request["protocol"]}."
      puts "Headers: #{request["headers"]}"
      
      # routes
      response_class_matching = {
        "GET" => GetResponse,
        "POST" => PostResponse
      }
      response_class = response_class_matching[request["method"]]

      case request["path"].chomp("/")
      when "" # TODO specify GET and POST only
        # TODO: change signature to ...root.respond or ...respond(:root) ot sth like that
        # or: define private method like respond(:root) + instance variable to remove repetitive clutter
        response_class.new(client, request).root
      when "/time" # TODO: specify GET method only
        response_class.new(client, request).time
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
