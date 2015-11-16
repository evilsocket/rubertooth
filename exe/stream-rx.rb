#!/bin/env ruby
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'rubertooth'

uber = RUbertooth::Ubertooth.new

puts "Found device: '#{uber.device.inspect}'"

# set sweep mode
uber.channel = 9999

puts "Waiting for data ...\n\n"

uber.stream do |rx,pkt,signal,noise,snr|
    printf "systime=%u ch=%2d LAP=%06x err=%u clk100ns=%u clk1=%u s=%d n=%d snr=%d\n",
           Time.now.to_i,
           pkt.channel,
           pkt.lap,
           pkt.ac_errors,
           rx.clk100ns,
           pkt.clkn,
           signal,
           noise,
           snr
end
