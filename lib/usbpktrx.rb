require 'bindata'

module RUbertooth

# USB packet for Bluetooth RX (64 total bytes)
class UsbPktRx < BinData::Record
    endian :little

    uint8  :pkt_type
    uint8  :status
    uint8  :channel
    uint8  :clkn_high
    uint32 :clk100ns
    int8   :rssi_max   # Max RSSI seen while collecting symbols in this packet
    int8   :rssi_min   # Min ...
    int8   :rssi_avg   # Average ...
    uint8  :rssi_count # Number of ... (0 means RSSI stats are invalid)
    array  :reserved, :type => :uint8, :initial_length => 2
    array  :data,     :type => :uint8, :initial_length => 50

    SIZE = 64

    PACKET_TYPES = {
        :BR_PACKET  => 0,
        :LE_PACKET  => 1,
        :MESSAGE    => 2,
        :KEEP_ALIVE => 3
    }

    attr_accessor :frequency, :access_address, :data_length

    def self.from_s data
        pkt = self.read data
        pkt.set_fields!

        pkt
    end

    def set_fields!
        @frequency = channel + 2402
        @access_address = 0
        4.times do |i|
            @access_address |= data[i] << (i * 8)
        end
        @data_length = ( data[5] & 0x3f ) + 9
        @data_length = 50 unless @data_length <= 50
    end
end

end
