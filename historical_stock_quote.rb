# Use net/http to access the API
require 'net/http'
require 'json'
require 'csv'
# Struct is used this time as it's more suitable with a large amount of data
Stock = Struct.new(:open, :close, :symbol, :trade_date)

class HistoricalStockQuote
  def self.historical_price(symbol)
      data = api_historical_data_lookup(symbol)
      data.map do |quote|
          [quote.trade_date, quote.open]
      end
  end
  
  def self.write_price_by_symbol(symbol, quotes)
    filename = "#{symbol}.csv"
    CSV.open(filename, "w") do |file|
      quotes.each do |quote|
        file << quote
      end
    end
  end
  
  private
  
  def self.api_historical_data_lookup(ticker_symbol)
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
        
        # Add historical data
        historical_data.map do |trade_date, stock_data|
            next unless stock_data # Stop early if no recent data
            
            # Extract desired information into a struct to avoid hash notation.
            Stock.new(stock_data['1. open'].to_f,
                                stock_data['4. close'].to_f,
                                data['Meta Data']["2. Symbol"],
                                trade_date
            )
        end
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
