$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'ubertooth'
require 'usbpktrx'
require 'lepacket'

MODES = { :follow => 0, :promisc => 1 }

mode = MODES[:follow]
uber = RUbertooth::Ubertooth.new

uber.set_modulation RUbertooth::Ubertooth::MODULATIONS[:MOD_BT_LOW_ENERGY]

if mode == MODES[:follow]
    uber.set_channel 2402
    uber.btle_sniffing 2
else
    uber.btle_promisc
end

prev_ts = 0

loop do
    uber.poll do |pkt|
        next unless not pkt.nil?

        access_address = 0
        4.times do |i|
            access_address |= pkt.data[i] << (i * 8)
        end

        ts_diff = pkt.clk100ns - prev_ts
        prev_ts = pkt.clk100ns

        printf "\nfreq=%d addr=%08x delta_t=%.03f ms\n", pkt.channel + 2402, access_address, ts_diff / 10000.0

        len = (pkt.data[5] & 0x3f) + 6 + 3
        len = 50 unless len <= 50

        print "  "
        (4..len - 1).each do |i|
            printf "%02x ", pkt.data[i]
        end
        puts

        lepkt = RUbertooth::BlueTooth::LePacket.decode pkt.data, pkt.channel + 2402, pkt.clk100ns

        lepkt.dump
    end

    sleep 0.5
end
