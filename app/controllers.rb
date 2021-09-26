require "yaml/store"

# TODO: find better way to structure controllers (not request methods)
class GetController < Controller
  def root
    headers = {"Content-Type" => "text/html"}

    yaml = begin
      YAML.load_file("store.yml")
    rescue
      nil
    end
    @message_history = format_message_history(yaml) unless yaml.nil?

    Response.new(status: 200, headers: headers, body: response_body_from_view)
  end

  def time
    headers = {"Content-Type" => "text/plain"}

    Response.new(status: 200, headers: headers, body: response_body_from_view)
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
      params = @request.params

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
      body = response_body_from_view(filename: "missing_header")

      Response.new(status: 404, headers: headers, body: body)
    end
  end
end
