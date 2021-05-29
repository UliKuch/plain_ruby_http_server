require "socket"
require "yaml/store"
require "cgi"

def main
  server = TCPServer.new(3456)

  loop do
    client = server.accept
    request_line = client.gets.chomp("\r\n")
    method, full_path, protocol = request_line.split
    path, query = full_path.split("?")
    headers = {}

    # get headers
    while line = client.gets
      break if line == "\r\n" # newline separates headers from body
      header, content = line.split(": ", 2)
      headers[header] = content.chomp("\r\n")
    end

    # get body
    body_length = headers["Content-Length"].to_i
    body = client.read(body_length)

    # server console output
    puts "Request received: #{request_line}"
    puts "Request method is #{method}, full path is #{full_path} (path: #{path}, query: #{query}) and protocol is #{protocol}."
    puts "Headers: #{headers}"
    
    # routes
    case [method, path.chomp("/")]
    when ["GET", ""]
      response_headers = {"Content-Type" => "text/html"}

      yaml = YAML.load(File.open("store.yml"))
      message_history = format_message_history(yaml)

      response_body = <<~HTML
        <small>Your request was: #{request_line}</small>
        <h2>This is root</h2>
        <h3>Here are some messages:</h3>
        #{message_history}
        <h3>Here is a form for you:</h3>
        <form method="POST" enctype="application/x-www-form-urlencoded">
          <label for="message">Some message:</label><br>
          <input type="text" id="message" name="message"><br><br>
          <label for="author">Author:</label><br>
          <input type="text" id="author" name="author"><br><br>
          <input type="submit" value="Submit"">
        </form>
      HTML

      client.puts response(status: 200, headers: response_headers, body: response_body)
    when ["GET", "/time"]
      response_headers = {"Content-Type" => "text/html"}
      response_body = "Time is #{Time.now}"

      client.puts response(status: 200, headers: response_headers, body: response_body)
    when ["POST", ""]
      if headers["Content-Type"] == "application/x-www-form-urlencoded"
        puts "Body: #{body}"

        params = parse_body(body)

        puts "Parameters: #{params}"
        puts "Message: #{params["message"]}"
        puts "Author: #{params["author"]}"

        store = YAML::Store.new "store.yml"
        store.transaction do
          store[Time.now] = {"author" => params["author"], "message" => params["message"]}
        end

        response_headers = {"Location" => "/"}

        client.puts response(status: 303, headers: response_headers)
      else
        response_headers = {"Content-Type" => "text/html"}
        response_body = <<~HTML
          <p>Your request was: #{request_line}</p>
          <p>Headers: #{headers}</p>
          <p>Wrong/missing 'Content-Type' header: #{headers["Content-Type"]}</p>
        HTML

        client.puts response(status: 404, headers: response_headers, body: response_body)
      end
    else
      response_headers = {"Content-Type" => "text/html"}
      response_body = <<~HTML
        <p>Your request was: #{request_line}</p>
        <p>This endpoint does not seem to exist :/</p>
      HTML

      client.puts response(status: 404, headers: response_headers, body: response_body)
    end

    puts "" # newlines between requests in server console
    client.close
  end
end

def response(status:, headers:, body: nil)
  response_string = "HTTP/1.1 #{status}\r\n"
  headers.each do |k, v|
    response_string << "#{k}: #{v}\r\n"
  end
  response_string << "\r\n"
  response_string << body unless body.nil?

  response_string
end

def parse_body(body)
  # easier: Hash[URI.decode_www_form(body)]
  body.split("&").each_with_object({}) do |string, hash|
    k, v = string.split("=")
    hash[k] = CGI.unescape(v)
  end
end

def format_message_history(yaml)
  yaml.map do |timestamp, content|
    <<~TEXT
    <h4>#{timestamp}:</h4>
    <p>#{content["author"]} wrote:
    <br/>
    #{content["message"]}</p>
    TEXT
  end.join("")
end

main
