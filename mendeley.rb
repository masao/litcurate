class Mendeley
  BASE_URL = "https://api.mendeley.com"
  def initialize(access_token)
    @access_token = access_token
  end
  def get(path, params = {})
    conn = Faraday.new(url: BASE_URL)
    conn.authorization :Bearer, @access_token
    response = conn.get(path, params)
    JSON.load(response.body)
  end
end
