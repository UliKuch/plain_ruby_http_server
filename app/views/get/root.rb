<<~HTML
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
  #{@message_history}
HTML
