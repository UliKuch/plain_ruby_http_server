require "socket"
require "yaml/store"
require "cgi"

# TODO: Controller instead of Response classes?
class Response
  def initialize(client, request)
    @client = client
    @request = request
  end

  private

  def respond(status:, headers:, body: nil)
    response_string = "HTTP/1.1 #{status}\r\n"
    headers.each do |k, v|
      response_string << "#{k}: #{v}\r\n"
    end
    response_string << "\r\n"
    response_string << body unless body.nil?

    @client.puts response_string
  end
end

class GetResponse < Response
  def root
    headers = {"Content-Type" => "text/html"}

    yaml = begin
      YAML.load_file("store.yml")
    rescue
      nil
    end
    message_history = format_message_history(yaml) unless yaml.nil?

    body = <<~HTML
      <small>Your request was: #{@request["request_line"]}</small>
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

    respond(status: 200, headers: headers, body: body)
  end

  def time
    headers = {"Content-Type" => "text/plain"}
    body = "Time is #{Time.now}"

    respond(status: 200, headers: headers, body: body)
  end

  def missing_endpoint
    headers = {"Content-Type" => "text/html"}
    body = <<~HTML
      <p>Your request was: #{@request["request_line"]}</p>
      <p>This endpoint does not seem to exist :/</p>
    HTML

    respond(status: 404, headers: headers, body: body)
  end

  private

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
end

class PostResponse < Response
  def root
    if @request["headers"]["Content-Type"] == "application/x-www-form-urlencoded"
      puts "Body: #{@request["body"]}"

      params = parse_body(@request["body"])

      puts "Parameters: #{params}"
      puts "Message: #{params["message"]}"
      puts "Author: #{params["author"]}"

      store = YAML::Store.new "store.yml"
      store.transaction do
        store[Time.now] = {"author" => params["author"], "message" => params["message"]}
      end

      headers = {"Location" => "/"}

      respond(status: 303, headers: headers)
    else
      headers = {"Content-Type" => "text/html"}
      body = <<~HTML
        <p>Your request was: #{@request["request_line"]}</p>
        <p>Headers: #{@request["headers"]}</p>
        <p>Wrong/missing 'Content-Type' header: #{@request["headers"]["Content-Type"]}</p>
      HTML

      respond(status: 404, headers: headers, body: body)
    end
  end

  private

  def parse_body(body)
    # easier: Hash[URI.decode_www_form(body)]
    body.split("&").each_with_object({}) do |string, hash|
      k, v = string.split("=")
      hash[k] = CGI.unescape(v)
    end
  end
end
