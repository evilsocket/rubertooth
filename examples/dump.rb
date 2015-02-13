$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'ubertooth'
require 'usbpktrx'
require 'lepacket'

uber = RUbertooth::Ubertooth.new

puts "Found device: '#{uber.device.inspect}'"

uber.set_modulation RUbertooth::Ubertooth::MODULATIONS[:MOD_BT_BASIC_RATE]

uber.stream do |pkt|
    printf "[freq=%d addr=%08x] ", pkt.frequency, pkt.access_address
    (4..pkt.data_length - 1).each do |i|
        printf "%02x", pkt.data[i]
    end
    puts
end
