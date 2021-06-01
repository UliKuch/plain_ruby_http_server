class Request
  attr_reader :request_line, :method, :full_path, :protocol, :path, :query, :headers, :body

  def initialize(client)
    @client = client
  end

  def read
    @request_line = read_request_line
    puts "Request received: #{request_line}"

    @method, @full_path, @protocol = request_line.split
    @path, @query = full_path.split("?")
    puts "Request method is #{method}, full path is #{full_path} (path: #{path}, query: #{query}) and protocol is #{protocol}."

    @headers = read_headers
    puts "Headers: #{headers}"

    @body = read_body
    puts "Body: #{body}"

    self
  rescue => error
    puts "Error reading request: #{error}"
    puts "Error's backtrace is:"
    puts error.backtrace.join("\n")

    self
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
