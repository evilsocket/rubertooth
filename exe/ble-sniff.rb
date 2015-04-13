#!/bin/env ruby
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'rubertooth'

MODES = { :follow => 0, :promisc => 1 }

mode = MODES[:promisc]
uber = RUbertooth::Ubertooth.new

puts "Found device: '#{uber.device.inspect}'"

uber.modulation = RUbertooth::Ubertooth::MODULATIONS[:MOD_BT_LOW_ENERGY]

if mode == MODES[:follow]
    uber.channel = 2402
    uber.btle_sniffing 2
else
    uber.btle_promisc
end

prev_ts = 0

puts "Starting polling loop ..."

uber.keep_polling 0.5 do |pkt|
    ts_diff = pkt.clk100ns - prev_ts
    prev_ts = pkt.clk100ns

    printf "\nfreq=%d addr=%08x delta_t=%.03f ms\n", pkt.frequency, pkt.access_address, ts_diff / 10000.0

    (4..pkt.data_length - 1).each do |i|
        printf " %02x", pkt.data[i]
    end
    puts

    lepkt = RUbertooth::BlueTooth::LePacket.decode pkt.data, pkt.frequency, pkt.clk100ns

    lepkt.dump
end
