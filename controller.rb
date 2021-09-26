require "cgi"

class Controller
  def initialize(request)
    @request = request
  end
end

class ErrorController < Controller
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
end
