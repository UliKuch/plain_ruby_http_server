require "yaml/store"
require "cgi"
require_relative "response"

class Controller
  def initialize(request)
    @request = request
  end

  private

  # TODO: Maybe add this to request object?
  def parse_body(body)
    # easier: Hash[URI.decode_www_form(body)]
    body.split("&").each_with_object({}) do |string, hash|
      k, v = string.split("=")
      hash[k] = CGI.unescape(v)
    end
  end
end

# TODO: find better way to structure controllers (not request methods)
class GetController < Controller
  def root
    headers = {"Content-Type" => "text/html"}

    yaml = begin
      YAML.load_file("store.yml")
    rescue
      nil
    end
    message_history = format_message_history(yaml) unless yaml.nil?

    body = <<~HTML
      <small>Your request was: #{@request.request_line}</small>
      <h2>This is root</h2>
      <h3>Here is a form for you:</h3>
      <form method="POST" enctype="application/x-www-form-urlencoded">
        <label for="message">Some message:</label><br>
        <input type="text" id="message" name="message"><br><br>
        <label for="author">Author:</label><br>
        <input type="text" id="author" name="author"><br><br>
        <input type="submit" value="Submit"">
      </form>
      <h3>Here are some messages:</h3>
      #{message_history}
    HTML

    Response.new(status: 200, headers: headers, body: body)
  end

  def time
    headers = {"Content-Type" => "text/plain"}
    body = "Time is #{Time.now}"

    Response.new(status: 200, headers: headers, body: body)
  end

  def missing_endpoint
    headers = {"Content-Type" => "text/html"}
    body = <<~HTML
      <p>Your request was: #{@request.request_line}</p>
      <p>This endpoint does not seem to exist :/</p>
    HTML

    Response.new(status: 404, headers: headers, body: body)
  end

  def bad_request
    headers = {"Content-Type" => "text/html"}
    body = <<~HTML
      <h1>Bad Request</h1>
    HTML

    Response.new(status: 400, headers: headers, body: body)
  end

  private

  def format_message_history(yaml)
    yaml.reverse_each.map do |timestamp, content|
      <<~HTML
        <h4>#{timestamp}:</h4>
        <p>#{content["author"]} wrote:
        <br/>
        #{content["message"]}</p>
      HTML
    end.join("")
  end
end

class PostController < Controller
  def root
    if @request.headers["Content-Type"] == "application/x-www-form-urlencoded"
      params = parse_body(@request.body)

      # server console output
      puts "Parameters: #{params}"

      store = YAML::Store.new "store.yml"
      store.transaction do
        store[Time.now] = {"author" => params["author"], "message" => params["message"]}
      end

      headers = {"Location" => "/"}

      Response.new(status: 303, headers: headers)
    else
      headers = {"Content-Type" => "text/html"}
      body = <<~HTML
        <p>Your request was: #{@request.request_line}</p>
        <p>Headers: #{@request.headers}</p>
        <p>Wrong/missing 'Content-Type' header: #{@request.headers["Content-Type"]}</p>
      HTML

      Response.new(status: 404, headers: headers, body: body)
    end
  end
end
