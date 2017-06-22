class Stock < ActiveRecord::Base

  has_many :user_stocks
  has_many :users, through: :user_stocks

  def self.find_by_ticker(ticker_symbol)
    where(ticker: ticker_symbol).first
  end

  def self.new_from_lookup(ticker_symbol)
    looked_up_stock = Stock.api_lookup(ticker_symbol)
    return nil unless looked_up_stock.present?

    new_stock = new(ticker: looked_up_stock.symbol, name: looked_up_stock.name)
    new_stock.last_price = new_stock.price
    new_stock
  end

  def price
    stock_data = Stock.api_lookup(ticker)
    return 'Unavailable' unless stock_data.present?
    
    closing_price = stock_data.close
    return "#{closing_price} (Closing)" if closing_price

    opening_price = stock_data.open
    return "#{opening_price} (Opening)" if opening_price
    'Unavailable'
  end
  
  private
  
  def self.api_lookup(ticker_symbol)
    # Use net/http to access the API
    require 'net/http'
    require 'json'
    require 'ostruct'
    
    api_url = 'https://www.alphavantage.co/query'
    query = {
      function: 'TIME_SERIES_DAILY',
      symbol: ticker_symbol,
      apikey: ENV['ALPHA_ADVANTAGE_API_KEY']
    }.to_query
    
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
      # The actual data hash is in the second item.
      recent_data = recent_data.second 
      
      # Extract desired information into a struct to avoid hash notation.
      OpenStruct.new({
        open: recent_data['1. open'].try(:to_f),
        close: recent_data['4. close'].try(:to_f),
        symbol: data['Meta Data']["2. Symbol"],
      })
    # Rescue any network related errors
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
       # Add any network error handling logic here
       puts "#{e.class} #{e.message}"
       nil # Lookup failed, return nothing
    # Rescue JSON Parse error, likely caused by an internal issue or slow response.
    rescue JSON::ParserError => e
      nil
    end
  end
end
