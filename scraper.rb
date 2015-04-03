# Australian product information

require "base64"

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


id = "09343956000092"
e = Encoder.new
p id
p e.encode(id)
p e.decode(e.encode(id))
