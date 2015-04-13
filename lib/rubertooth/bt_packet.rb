require 'bindata'

module RUbertooth
  # BlueTooth packet
  class BtPacket < BinData::Record
    endian :little

    # maximum number of symbols
    MAX_SYMBOLS = 3125
    # maximum number of payload bits
    MAX_PAYLOAD_LENGTH = 2744

    LAP_ANY = 0xffffffff

    FLAGS = {
      WHITENED: 0,
      NAP_VALID: 1,
      UAP_VALID: 2,
      LAP_VALID: 3,
      CLK6_VALID: 4,
      CLK27_VALID: 5,
      CRC_CORRECT: 6,
      HAS_PAYLOAD: 7,
      IS_EDR: 8,
      HOP_REVERSAL_INIT: 9,
      GOT_FIRST_PACKET: 10,
      IS_AFH: 11,
      LOOKS_LIKE_AFH: 12,
      IS_ALIASED: 13,
      FOLLOWING: 14
    }

    uint32 :refcount
    uint32 :flags
    uint8 :channel # Bluetooth channel (0-79)
    uint8 :uap     # upper address part
    uint16 :nap    # non-significant address part
    uint32 :lap    # lower address part found in access code

    uint8 :packet_type
    uint8 :packet_lt_addr # LLID field of payload header (2 bits)
    uint8 :packet_flags # Flags - FLOW/ARQN/SQEN */
    uint8 :packet_hec # Flags - FLOW/ARQN/SQEN */

    # packet header, one bit per char
    array :packet_header, type: :uint8, initial_length: 18

    # number of payload header bytes: 0, 1, 2, or -1 for
    # unknown. payload is one bit per char.
    int32 :payload_header_length
    array :payload_header, type: :uint8, initial_length: 16
    uint8 :payload_llid # LLID field of payload header (2 bits)
    uint8 :payload_flow # flow field of payload header (1 bit)

    # payload length: the total length of the asynchronous data
    # in bytes.  This does not include the length of synchronous
    # data, such as the voice field of a DV packet.  If there is a
    # payload header, this payload length is payload body length
    # (the length indicated in the payload header's length field)
    # plus payload_header_length plus 2 bytes CRC (if present).
    int32 :payload_length

    # The actual payload data in host format
    # Ready for passing to wireshark
    # 2744 is the maximum length, but most packets are shorter.
    # Dynamic allocation would probably be better in the long run but is
    # problematic in the short run.
    array :payload, type: :uint8, initial_length: MAX_PAYLOAD_LENGTH

    uint16 :crc
    uint32 :clock # CLK1-27 of master
    uint32 :clkn # native (local) clock, CLK0-27
    uint8 :ac_errors # Number of bit errors in the AC

    # the raw symbol stream (less the preamble), one bit per char
    uint16 :sym_length # number of symbols
    array :symbols, type: :uint8, initial_length: MAX_SYMBOLS

    def self.build(lap, ac_errors, channel, clkn, syms, size)
      pkt = BtPacket.new
      pkt.refcount = 1
      pkt.lap = lap
      pkt.ac_errors = ac_errors
      pkt.flags = 0
      pkt.set_flag BtPacket::FLAGS[:WHITENED], 1
      pkt.channel = channel
      pkt.clkn = clkn >> 1 # really CLK1
      pkt.sym_length = size

      if pkt.sym_length > BtPacket::MAX_SYMBOLS
        pkt.sym_length = BtPacket::MAX_SYMBOLS
      end

      pkt.sym_length.times do |i|
        pkt.symbols[i] = syms[i]
      end

      pkt
    end

    def set_flag(flag, val)
      mask = 1 << flag
      @flags &= ~mask
      @flags |= mask if val > 0
    end
  end
end
