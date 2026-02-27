require 'ipaddr'

module Core::Validators::IpAddress
  module_function

  def call(value)
    ip = IPAddr.new(value.to_s)
    ip.to_s
  rescue IPAddr::InvalidAddressError
    raise ArgumentError, "invalid IP address: #{value.inspect}"
  end
end
