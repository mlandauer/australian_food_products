#!/usr/bin/env ruby
# Australian product information

require "base64"
require "dotenv"
require "rest_client"

# The "stupidest encoder in the world"
class Encoder
  def initialize
    @r = Random.new
  end

  def decode(s)
    a = Base64.decode64(s)
    salt = a[0].to_i
    offset_string(a[1..-1], -offset(salt)).reverse
  end

  def encode(s)
    salt = @r.rand(9) + 1
    b = offset_string(s.reverse, offset(salt))
    Base64.encode64(salt.to_s + b).strip
  end

  def offset_string(s, offset)
    b = ""
    s.each_byte do |d|
      b = b + [d+offset].pack("c")
    end
    b
  end

  def offset(salt)
    7 * salt
  end
end

def product_info(id, e)
  JSON.parse(RestClient.get "https://goscan.gs1au.org/api/products/#{id}", params: {userAction: "Browse"}, "Api-Key" => ENV["MORPH_API_KEY"], "Security-Key" => e.encode(id))
end

def categories
  JSON.parse(RestClient.get "https://goscan.gs1au.org/assets/categories.json", "Api-Key" => ENV["MORPH_API_KEY"])
end

def products_in_category(id, page = 1)
  JSON.parse(RestClient.get "https://goscan.gs1au.org/api/products", params: {category: "10000613", page: 1}, "Api-Key" => ENV["MORPH_API_KEY"])
end

Dotenv.load

e = Encoder.new

# Just some quick tests for the "encoder"
raise unless e.decode("MTlANzc3Nz08QDo7OkA3") == "09343956000092"
raise unless e.decode(e.encode("09343956000092")) == "09343956000092"

#p categories
p products_in_category("10000613")
#p product_info("09343956000092", e)
