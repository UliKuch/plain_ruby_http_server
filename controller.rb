require "cgi"

class Controller
  def initialize(request)
    @request = request
  end

  private

  def response_body_from_view(path: nil, filename: nil)
    # TODO: use proper snake_case instead of downcase
    relative_path = if path.nil?
      "views/" + self.class.to_s.chomp("Controller").downcase
    else
      path
    end

    # read calling method's name if filename not specified
    name = filename.nil? ? caller_locations.first.base_label : filename

    eval(File.open("app/#{relative_path}/#{name}.rb").read)
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
