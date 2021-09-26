<<~HTML
  <p>Your request was: #{@request.request_line}</p>
  <p>Headers: #{@request.headers}</p>
  <p>Wrong/missing 'Content-Type' header: #{@request.headers["Content-Type"]}</p>
HTML
