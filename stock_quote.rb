class StockQuote
  # Use net/http to access the API
  require 'net/http'
  require 'json'
  # Use ostruct to store the API data in a way that is more easily accessible
  require 'ostruct'

  def self.price_by_symbol(ticker_symbol)
    looked_up_stock = StockQuote.api_lookup(ticker_symbol)
    
    # Use ternary operator instead of if-else, https://en.wikipedia.org/wiki/%3F:#Ruby
    looked_up_stock ? looked_up_stock.open : 'N/A'
  end

  def self.write_price_by_symbol(symbol, price)
    filename = "#{symbol}.csv"
    todays_date = Time.now.strftime('%Y-%m-%d') 
    File.open(filename, "a") do |file|
      file << "#{todays_date}, #{price}\n"
    end
  end
  
  private
  
  def self.api_lookup(ticker_symbol)
    
    # The API base URL
    api_url = 'https://www.alphavantage.co/query'
    
    # API parameters
    function = "function=TIME_SERIES_DAILY"
    symbol = "symbol=#{ticker_symbol}"
    apikey = "apikey=#{ENV['ALPHA_ADVANTAGE_API_KEY']}"
    
    # Create the api query string from the API parameters
    query = [function, symbol, apikey].join('&')
    
    # Combine the API URL and the query to get the full URL
    url = "#{api_url}?#{query}"
    
    begin # Use error handling
      # Send API request and parse JSON response.
      uri = URI(url)
      response = Net::HTTP.get(uri)
      data = JSON.parse(response)
      
      # Get the actual historical data
      historical_data = data['Time Series (Daily)']
      
      # Get the most recent data
      recent_data = historical_data.first
      return nil unless recent_data # Stop early if no recent data
      puts recent_data[0]
      
      # The actual data hash is in the second item.
      recent_data = recent_data[1]
      return nil unless recent_data # Stop early if no recent data
      
      # Extract desired information into a struct to avoid hash notation.
      OpenStruct.new({
        open: recent_data['1. open'].to_f,
        close: recent_data['4. close'].to_f,
        symbol: data['Meta Data']["2. Symbol"],
      })
    # Rescue any network related errors
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
       # Add any network error handling logic here
       nil # Lookup failed, return nothing
    # Rescue JSON Parse error, likely caused by an internal issue or slow response.
    rescue JSON::ParserError => e
      nil # Lookup failed, return nothing
    end
  end
end

stock_price = StockQuote.price_by_symbol('AAPL')
stock_written = StockQuote.write_price_by_symbol('AAPL', stock_price)
