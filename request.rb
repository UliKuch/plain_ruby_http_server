class Request
  attr_reader :request_line, :method, :full_path, :protocol, :path, :query, :headers, :body

  def initialize(client)
    @client = client

    @request_line = read_request_line
    @method, @full_path, @protocol = request_line.split
    @path, @query = full_path.split("?")

    @headers = read_headers
    @body = read_body
  end

  private

  def read_request_line
    @client.gets.chomp("\r\n")
  end

  def read_headers
    headers = {}
    while (line = @client.gets)
      break if line == "\r\n" # newline separates headers from body
      header, content = line.split(": ", 2)
      headers[header] = content.chomp("\r\n")
    end
    headers
  end

  def read_body
    body_length = @headers["Content-Length"].to_i
    @client.read(body_length)
  end
end
