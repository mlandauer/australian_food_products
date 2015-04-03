#!/usr/bin/env ruby
# Australian food product information with barcodes

require "base64"
require "dotenv"
require "rest_client"
require "yaml"

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
    s.bytes.map{|d| d+offset}.pack("c*")
  end

  def offset(salt)
    7 * salt
  end
end

class ProductApi
  attr_reader :encoder

  BASE = "https://goscan.gs1au.org"

  def initialize
    @encoder = Encoder.new
  end

  def categories
    JSON.parse(RestClient.get "#{BASE}/assets/categories.json", "Api-Key" => api_key)
  end

  # It looks like there's a max of 20 requests per page
  def products_in_category_paged(id, page)
    JSON.parse(RestClient.get "#{BASE}/api/products", params: {category: id, page: page}, "Api-Key" => api_key)["Items"]
  end

  def products_in_category(id)
    page = 0
    products = []
    begin
      page += 1
      a = products_in_category_paged(id, page)
      products += a
    end while a.count == 20
    products
  end

  def product_info(id)
    JSON.parse(RestClient.get "#{BASE}/api/products/#{id}", params: {userAction: "Browse"}, "Api-Key" => api_key, "Security-Key" => encoder.encode(id))["Items"]
  end

  private

  def api_key
    ENV["MORPH_API_KEY"]
  end
end

Dotenv.load

e = Encoder.new

# Just some quick tests for the "encoder"
raise unless e.decode("MTlANzc3Nz08QDo7OkA3") == "09343956000092"
raise unless e.decode(e.encode("09343956000092")) == "09343956000092"

api = ProductApi.new
#p api.products_in_category("10000613")
#p api.product_info("09343956000092")

def leaf_category_ids(categories)
  ids = []
  categories.each do |category|
    #p category
    if category["Children"].empty?
      ids << category["Code"]
    else
      ids += leaf_category_ids(category["Children"])
    end
  end
  ids.sort
end

leaf_category_ids(api.categories["Children"]).each do |category_id|
  puts "Getting products for category id: #{category_id}..."
  api.products_in_category(category_id).each do |product|
    api.product_info(product["Gtin"]).each do |info|
      record = {
        "barcode" => info["Gtin"],
        "description" => info["Description"],
        "info" => info.to_json
      }
      p record
      exit
    end
  end
end
