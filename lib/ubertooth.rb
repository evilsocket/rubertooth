require 'libusb'

module RUbertooth

module USB
    LIBUSB_ENDPOINT_IN = 0x80
    LIBUSB_ENDPOINT_OUT = 0x00
    LIBUSB_REQUEST_TYPE_VENDOR = (0x02 << 5)
end

class Ubertooth

    USB_IDS = [
        [ 0x1D50, 0x6002, "Ubertooth ONE" ],
        [ 0x1D50, 0x6000, "Ubertooth ZERO" ],
        [ 0xFFFF, 0x0004, "TC13BADGE / Ubertooth with older firmware" ]
    ]

    COMMANDS = {
        :UBERTOOTH_PING            => 0,
        :UBERTOOTH_RX_SYMBOLS      => 1,
        :UBERTOOTH_TX_SYMBOLS      => 2,
        :UBERTOOTH_GET_USRLED      => 3,
        :UBERTOOTH_SET_USRLED      => 4,
        :UBERTOOTH_GET_RXLED       => 5,
        :UBERTOOTH_SET_RXLED       => 6,
        :UBERTOOTH_GET_TXLED       => 7,
        :UBERTOOTH_SET_TXLED       => 8,
        :UBERTOOTH_GET_1V8         => 9,
        :UBERTOOTH_SET_1V8         => 10,
        :UBERTOOTH_GET_CHANNEL     => 11,
        :UBERTOOTH_SET_CHANNEL     => 12,
        :UBERTOOTH_RESET           => 13,
        :UBERTOOTH_GET_SERIAL      => 14,
        :UBERTOOTH_GET_PARTNUM     => 15,
        :UBERTOOTH_GET_PAEN        => 16,
        :UBERTOOTH_SET_PAEN        => 17,
        :UBERTOOTH_GET_HGM         => 18,
        :UBERTOOTH_SET_HGM         => 19,
        :UBERTOOTH_TX_TEST         => 20,
        :UBERTOOTH_STOP            => 21,
        :UBERTOOTH_GET_MOD         => 22,
        :UBERTOOTH_SET_MOD         => 23,
        :UBERTOOTH_SET_ISP         => 24,
        :UBERTOOTH_FLASH           => 25,
        :BOOTLOADER_FLASH          => 26,
        :UBERTOOTH_SPECAN          => 27,
        :UBERTOOTH_GET_PALEVEL     => 28,
        :UBERTOOTH_SET_PALEVEL     => 29,
        :UBERTOOTH_REPEATER        => 30,
        :UBERTOOTH_RANGE_TEST      => 31,
        :UBERTOOTH_RANGE_CHECK     => 32,
        :UBERTOOTH_GET_REV_NUM     => 33,
        :UBERTOOTH_LED_SPECAN      => 34,
        :UBERTOOTH_GET_BOARD_ID    => 35,
        :UBERTOOTH_SET_SQUELCH     => 36,
        :UBERTOOTH_GET_SQUELCH     => 37,
        :UBERTOOTH_SET_BDADDR      => 38,
        :UBERTOOTH_START_HOPPING   => 39,
        :UBERTOOTH_SET_CLOCK       => 40,
        :UBERTOOTH_GET_CLOCK       => 41,
        :UBERTOOTH_BTLE_SNIFFING   => 42,
        :UBERTOOTH_GET_ACCESS_ADDRESS => 43,
        :UBERTOOTH_SET_ACCESS_ADDRESS => 44,
        :UBERTOOTH_DO_SOMETHING    => 45,
        :UBERTOOTH_DO_SOMETHING_REPLY => 46,
        :UBERTOOTH_GET_CRC_VERIFY  => 47,
        :UBERTOOTH_SET_CRC_VERIFY  => 48,
        :UBERTOOTH_POLL            => 49,
        :UBERTOOTH_BTLE_PROMISC    => 50,
        :UBERTOOTH_SET_AFHMAP      => 51,
        :UBERTOOTH_CLEAR_AFHMAP    => 52,
        :UBERTOOTH_READ_REGISTER   => 53,
        :UBERTOOTH_BTLE_SLAVE      => 54,
        :UBERTOOTH_GET_COMPILE_INFO => 55,
        :UBERTOOTH_BTLE_SET_TARGET => 56
    }

    MODULATIONS = {
        :MOD_BT_BASIC_RATE => 0,
        :MOD_BT_LOW_ENERGY => 1,
        :MOD_80211_FHSS    => 2
    }

    OPERATING_MODES = {
        :MODE_IDLE          => 0,
        :MODE_RX_SYMBOLS    => 1,
        :MODE_TX_SYMBOLS    => 2,
        :MODE_TX_TEST       => 3,
        :MODE_SPECAN        => 4,
        :MODE_RANGE_TEST    => 5,
        :MODE_REPEATER      => 6,
        :MODE_LED_SPECAN    => 7,
        :MODE_BT_FOLLOW     => 8,
        :MODE_BT_FOLLOW_LE  => 9,
        :MODE_BT_PROMISC_LE => 10,
        :MODE_RESET         => 11,
        :MODE_BT_SLAVE_LE   => 12
    }

    DATA_IN  = 0x82 | USB::LIBUSB_ENDPOINT_IN
    DATA_OUT = 0x05 | USB::LIBUSB_ENDPOINT_OUT
    CTRL_IN  = USB::LIBUSB_REQUEST_TYPE_VENDOR | USB::LIBUSB_ENDPOINT_IN
    CTRL_OUT = USB::LIBUSB_REQUEST_TYPE_VENDOR | USB::LIBUSB_ENDPOINT_OUT
    DMA_SIZE = 50

    def initialize
        @device = nil
        @handle = nil
        @iface = nil
        @usb = LIBUSB::Context.new

        USB_IDS.each do |uid|
            @device = @usb.devices(:idVendor => uid[0], :idProduct => uid[1]).first
            break unless @device.nil?
        end

        raise "Device not found" unless @device

        @handle = @device.open
        @iface = @handle.claim_interface(0)
    end

    def do_something data
        sent = @iface.control_transfer({
            :bmRequestType => CTRL_OUT,
            :bRequest => COMMANDS[:UBERTOOTH_DO_SOMETHING],
            :wValue => 0,
            :wIndex => 0,
            :dataOut => data,
            :timeout => 1000
        })
        raise "Failed to send data: #{sent}" unless sent == data.size

        reply = @iface.control_transfer({
            :bmRequestType => CTRL_IN,
            :bRequest => COMMANDS[:UBERTOOTH_DO_SOMETHING_REPLY],
            :wValue => 0,
            :wIndex => 0,
            :dataIn => 4,
            :timeout => 3000
        })

        yield reply
    end

    def set_modulation modulation
        r = @iface.control_transfer({
            :bmRequestType => CTRL_OUT,
            :bRequest => COMMANDS[:UBERTOOTH_SET_MOD],
            :wValue => modulation,
            :wIndex => 0,
            :timeout => 1000
        })

        raise "Command failed: #{r}" unless r == 0
    end

    def set_channel channel
        r = @iface.control_transfer({
            :bmRequestType => CTRL_OUT,
            :bRequest => COMMANDS[:UBERTOOTH_SET_CHANNEL],
            :wValue => channel,
            :wIndex => 0,
            :timeout => 1000
        })

        raise "Command failed: #{r}" unless r == 0
    end

    def btle_sniffing num
        r = @iface.control_transfer({
            :bmRequestType => CTRL_OUT,
            :bRequest => COMMANDS[:UBERTOOTH_BTLE_SNIFFING],
            :wValue => num,
            :wIndex => 0,
            :timeout => 1000
        })

        raise "Command failed: #{r}" unless r == 0
    end

    def btle_promisc
        r = @iface.control_transfer({
            :bmRequestType => CTRL_OUT,
            :bRequest => COMMANDS[:UBERTOOTH_BTLE_PROMISC],
            :wValue => 0,
            :wIndex => 0,
            :timeout => 1000
        })

        raise "Command failed: #{r}" unless r == 0
    end

    def btle_slave mac_address
        sent = @iface.control_transfer({
            :bmRequestType => CTRL_OUT,
            :bRequest => COMMANDS[:UBERTOOTH_BTLE_SLAVE],
            :wValue => 0,
            :wIndex => 0,
            :dataOut => mac_address,
            :timeout => 1000
        })
        raise "Failed to send data: #{sent}" unless sent == mac_address.size
    end

    def btle_set_target mac_address
        sent = @iface.control_transfer({
            :bmRequestType => CTRL_OUT,
            :bRequest => COMMANDS[:UBERTOOTH_BTLE_SET_TARGET],
            :wValue => 0,
            :wIndex => 0,
            :dataOut => mac_address,
            :timeout => 1000
        })
        raise "Failed to send data: #{sent}" unless sent == mac_address.size
    end

    def poll
        data = @iface.control_transfer({
            :bmRequestType => CTRL_IN,
            :bRequest => COMMANDS[:UBERTOOTH_POLL],
            :wValue => 0,
            :wIndex => 0,
            :dataIn => UsbPktRx::SIZE,
            :timeout => 1000
        })

        pkt = nil
        if data.size == UsbPktRx::SIZE
            pkt = UsbPktRx.read data
        end

        yield pkt
    end

end

end
