class Response
  attr_reader :status, :headers, :body

  def initialize(status:, headers:, body: nil)
    @status = status
    @headers = headers
    @body = body
  end

  def to_s
    result = "HTTP/1.1 #{status}\r\n"
    headers.each do |k, v|
      result << "#{k}: #{v}\r\n"
    end
    result << "\r\n"
    result << body unless body.nil?
    result
  end
end
