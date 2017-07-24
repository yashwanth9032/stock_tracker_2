# require_relative 'stock_quote'
require_relative 'historical_stock_quote'

# def stock_price_selector(*symbol_array)
#   symbol_array.each do |symbol| 
#     stock_price = StockQuote.price_by_symbol(symbol)
#     stock_written = StockQuote.write_price_by_symbol(symbol, stock_price)
#   end
# end

# stock_price_selector('AAPL', 'GOOG', 'MSFT')
  
price_array = HistoricalStockQuote.historical_price('AAPL')
HistoricalStockQuote.write_price_by_symbol('AAPL', price_array)