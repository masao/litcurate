class Mendeley
  BASE_URL = "https://api.mendeley.com"
  def initialize(access_token)
    @access_token = access_token
    @connection = Faraday.new(url: BASE_URL)
    @connection.authorization :Bearer, @access_token
  end
  def run_request(method, path, body = nil, headers = {})
    response = @connection.run_request(method, path, body, headers)
    if response.status != 200
      STDERR.puts response.inspect
      raise Error.new( response.body )
    end
    JSON.load(response.body)
  end
  def get(path)
    run_request(:get, path)
  end
  def patch(path, body)
    STDERR.puts [path, body].inspect
    headers = {
      "Content-Type": "application/vnd.mendeley-document.1+json",
    }
    run_request(:patch, path, body, headers)
  end
  class Error < Exception; end
end
