cwd = File.join(File.expand_path(File.dirname(__FILE__)), 'rubertooth')
$: << cwd

require File.join(cwd, 'assembler')
require File.join(cwd, 'bt_packet')
require File.join(cwd, 'le_packet')
require File.join(cwd, 'usb_pkt_rx')
require File.join(cwd, 'ubertooth')
#usb_pkt_rx', 'bt_packet', 'le_packet', 'assembler', 'ubertooth')
