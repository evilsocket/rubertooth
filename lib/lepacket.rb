module RUbertooth
module BlueTooth

# BLE packet decoder
class LePacket
    attr_accessor :symbols, :access_address, :channel_index, :length,
                  :clk100ns, :adv_type, :adv_tx_add, :adv_rx_add, :llid,
                  :nesn, :sn, :md, :opcode

    MAX_LE_SYMBOLS = 64

    LLIDS = [
        "Reserved",
        "LL Data PDU / empty or L2CAP continuation",
        "LL Data PDU / L2CAP start",
        "LL Control PDU"
    ]

    OPCODES = [
        "LL_CONNECTION_UPDATE_REQ",
        "LL_CHANNEL_MAP_REQ",
        "LL_TERMINATE_IND",
        "LL_ENC_REQ",
        "LL_ENC_RSP",
        "LL_START_ENC_REQ",
        "LL_START_ENC_RSP",
        "LL_UNKNOWN_RSP",
        "LL_FEATURE_REQ",
        "LL_FEATURE_RSP",
        "LL_PAUSE_ENC_REQ",
        "LL_PAUSE_ENC_RSP",
        "LL_VERSION_IND",
        "LL_REJECT_IND",
        "LL_SLAVE_FEATURE_REQ",
        "LL_CONNECTION_PARAM_REQ",
        "LL_CONNECTION_PARAM_RSP",
        "LL_REJECT_IND_EXT",
        "LL_PING_REQ",
        "LL_PING_RSP",
        "Reserved for Future Use"
    ]

    ADV_TYPES = {
        :ADV_IND =>			0,
        :ADV_DIRECT_IND =>	1,
        :ADV_NONCONN_IND =>	2,
        :SCAN_REQ =>		3,
        :SCAN_RSP =>		4,
        :CONNECT_REQ =>		5,
        :ADV_SCAN_IND =>	6
    }

    ADV_TYPE_NAMES = [
        "ADV_IND",
        "ADV_DIRECT_IND",
        "ADV_NONCONN_IND",
        "SCAN_REQ",
        "SCAN_RSP",
        "CONNECT_REQ",
        "ADV_SCAN_IND"
    ]

    # source clock accuracy in a connect packet
    CONNECT_SCA = [
        "251 ppm to 500 ppm", "151 ppm to 250 ppm", "101 ppm to 150 ppm",
        "76 ppm to 100 ppm", "51 ppm to 75 ppm", "31 ppm to 50 ppm",
        "21 ppm to 30 ppm", "0 ppm to 20 ppm",
    ]

    def initialize
        # raw unwhitened bytes of packet, including access address
        @symbols = Array.new MAX_LE_SYMBOLS
        @access_address = 0
        @channel_index = 0
        # number of symbols
        @length = 0
        @clk100ns = 0
        # advertising packet header info
        @adv_type   = 0
        @adv_tx_add = 0
        @adv_rx_add = 0
        # data fields
        @llid = 0
        @nesn = 0
        @sn = 0
        @md = 0
        @opcode = 0
    end

    def is_data?
        @channel_index < 37
    end

    def dump
        if is_data?
            printf "Data / AA %08x / %2d bytes\n", @access_address, @length
            printf "    Channel Index: %d\n", @channel_index
            printf "    LLID: %d / %s\n", @llid, LLIDS[@llid]
            printf "    NESN: %d  SN: %d  MD: %d\n", @nesn, @sn, @md
            printf "    Opcode: %d / %s\n", @opcode, OPCODES[(@opcode<0x14)?@opcode:0x14]
        else
            printf "Advertising / AA %08x / %2d bytes\n", @access_address, @length
            printf "    Channel Index: %d\n", @channel_index
            printf "    Type:  %s\n", ADV_TYPE_NAMES[ @adv_type ]

            case @adv_type
            when ADV_TYPES[:ADV_IND]
                LePacket.dump_addr "AdvA:  ", @symbols, 6, @adv_tx_add
                if (@length - 6) > 0
                    printf "    AdvData:"
                    (0..@length - 6 - 1).each do |i|
                        printf " %02x", @symbols[12+i]
                    end
                    puts
                    LePacket.dump_scan_rsp_data @symbols[12,@symbols.size], @length - 6
                end

            when ADV_TYPES[:SCAN_REQ]
                LePacket.dump_addr "ScanA: ", @symbols, 6, @adv_tx_add
                LePacket.dump_addr "AdvA:  ", @symbols, 12, @adv_rx_add

            when ADV_TYPES[:SCAN_RSP]
                LePacket.dump_addr "AdvA:  ", @symbols, 6, @adv_tx_add
                printf "    ScanRspData:"
                (0..@length - 6 - 1).each do |i|
                    printf " %02x", @symbols[12+i]
                end
                puts
                LePacket.dump_scan_rsp_data @symbols[12,@symbols.size], @length - 6

            when ADV_TYPES[:CONNECT_REQ]
                LePacket.dump_addr "InitA: ", @symbols, 6, @adv_tx_add
                LePacket.dump_addr "AdvA:  ", @symbols, 12, @adv_rx_add
                LePacket.dump_32 "AA:    ", @symbols, 18
                LePacket.dump_24 "CRCInit: ", @symbols, 22
                LePacket.dump_8 "WinSize: ", @symbols, 25
                LePacket.dump_16 "WinOffset: ", @symbols, 26
                LePacket.dump_16 "Interval: ", @symbols, 28
                LePacket.dump_16 "Latency: ", @symbols, 30
                LePacket.dump_16 "Timeout: ", @symbols, 32

                printf "    ChM:"
                5.times do |i|
                    printf " %02x", @symbols[34+i]
                end
                puts

                printf "    Hop: %d\n", @symbols[39] & 0x1f
                printf "    SCA: %d, %s\n", @symbols[39] >> 5, CONNECT_SCA[@symbols[39] >> 5]
            end
        end

        print "\n    Data: "
        (6..6 + @length - 1).each do |i|
            printf " %02x", @symbols[i]
        end

        print "\n    CRC:  "
        3.times do |i|
            printf " %02x", @symbols[ 6 + @length + i ]
        end
        puts
    end

    def self.decode data, phys_channel, clk100ns
        pkt = self.new

        MAX_LE_SYMBOLS.times do |i|
            pkt.symbols[i] = data[i]
        end

        pkt.channel_index = self.channel_index phys_channel
        pkt.clk100ns = clk100ns

        pkt.access_address = 0
        pkt.access_address |= pkt.symbols[0]
        pkt.access_address |= pkt.symbols[1] << 8
        pkt.access_address |= pkt.symbols[2] << 16
        pkt.access_address |= pkt.symbols[3] << 24

        # data PDU
        if pkt.is_data?
            pkt.length = pkt.symbols[5] & 0x1f
            pkt.llid = pkt.symbols[4] & 0x3
            pkt.nesn = (pkt.symbols[4] >> 2) & 1
            pkt.sn = (pkt.symbols[4] >> 3) & 1
            pkt.md = (pkt.symbols[4] >> 4) & 1
            pkt.opcode = pkt.symbols[6] unless pkt.llid != 3 # LL Control PDU

        # advertising PDU
        else
            pkt.length = pkt.symbols[5] & 0x3f
    		pkt.adv_type = pkt.symbols[4] & 0xf
    		pkt.adv_tx_add = pkt.symbols[4] & 0x40 ? 1 : 0
    		pkt.adv_rx_add = pkt.symbols[4] & 0x80 ? 1 : 0
        end

        pkt
    end

    private

    def self.dump_addr name, buf, offset, random
        printf "    %s%02x", name, buf[offset+5]
        (4..0).each do |i|
            printf ":%02x", buf[offset+i]
        end
        printf " (%s)\n", !!random ? "random" : "public"
    end

    def self.dump_8 name, buf, offset
        printf "    %s%02x (%d)\n", name, buf[offset], buf[offset]
    end

    def self.dump_16 name, buf, offset
        val = buf[offset+1] << 8 | buf[offset]
        printf "    %s%04x (%d)\n", name, val, val
    end

    def self.dump_24 name, buf, offset
        val = buf[offset+2] << 16 | buf[offset+1] << 8 | buf[offset]
        printf "    %s%06x\n", name, val
    end

    def self.dump_32 name, buf, offset
        val = buf[offset+3] << 24 |
              buf[offset+2] << 16 |
              buf[offset+1] << 8 |
              buf[offset+0]
        printf "    %s%08x\n", name, val
    end

    def self.dump_uuid uuid
        4.times do |i|
            printf "%02x", uuid[i]
        end
        printf "-"
        (4..5).each do |i|
            printf "%02x", uuid[i]
        end
        printf "-"
        (6..7).each do |i|
            printf "%02x", uuid[i]
        end
        printf "-"
        (8..9).each do |i|
            printf "%02x", uuid[i]
        end
        printf "-"
        (10..15).each do |i|
            printf "%02x", uuid[i]
        end
    end

    def self.dump_scan_rsp_data buf, len
        pos = 0
        sublen = 0

        while pos < len
            sublen = buf[pos]
            pos += 1

            return unless sublen > 0 and pos + sublen <= len

            type = buf[pos]
            printf "        Type %02x", type

            case type
            when 0x01
                printf " (Flags)\n           "
                8.times do |i|
                    printf "%d", (buf[pos+1] & (1 << (7-i))) > 0 ? 1 : 0
                end
                puts

            when 0x06
            when 0x07
                printf " (128-bit Service UUIDs)\n"
                if (sublen - 1) % 16 == 0
                    uuid = Array.new 16
                    (sublen - 1).times do |i|
                        uuid[15 - (i % 16)] = buf[pos+1+i]
                        if (i & 15) == 15
                            printf "           "
                            self.dump_uuid uuid
                            printf "\n"
                        end
                    end
                else
                    printf "Wrong length (%d, must be divisible by 16)\n", sublen - 1
                end

            when 0x09
                printf " (Complete Local Name)\n           "
                (1..sublen-1).each do |i|
                    printf "%c", buf[pos+i]
                end
                puts

            when 0x0a
                printf " (Tx Power Level)\n           "
                if sublen == 2
                    printf "%d dBm\n", buf[pos+1]
                else
                    printf "Wrong length (%d, should be 1)\n", sublen-1
                end

            when 0x12
                printf " (Slave Connection Interval Range)\n           "
                if sublen == 5
                    val = (buf[pos+2] << 8) | buf[pos+1]
                    printf "(%0.2f, ", val * 1.25
                    val = (buf[pos+4] << 8) | buf[pos+3];
                    printf "%0.2f) ms\n", val * 1.25
                else
                    printf "Wrong length (%d, should be 4)\n", sublen-1
                end

            when 0x16
                printf " (Service Data)\n           "
                if sublen-1 >= 2
                    val = (buf[pos+2] << 8) | buf[pos+1];
                    printf "UUID: %02x", val
                    if sublen-1 > 2
                        printf ", Additional:"
                        (3..sublen-1).each do |i|
                            printf " %02x", buf[pos+i]
                        end
                    end
                    puts
                else
                    printf "Wrong length (%d, should be >= 2)\n", sublen-1
                end

            else
                printf "\n           "
                (1..sublen-1).each do |i|
                    printf " %02x", buf[pos+i]
                end
                puts
            end

            pos += sublen
        end
    end

    def self.channel_index phys_channel
        if phys_channel == 2402
            37
        elsif phys_channel < 2426 # 0 - 10
            (phys_channel - 2404) / 2
        elsif phys_channel == 2426
            38
        elsif phys_channel < 2480 # 11 - 36
            11 + (phys_channel - 2428) / 2
        else
            39
        end
    end
end

end
end
