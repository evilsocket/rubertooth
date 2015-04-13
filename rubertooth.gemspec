require 'rake'
require './lib/rubertooth/version'

Gem::Specification.new do |s|
  s.name         = 'rubertooth'
  s.version      = RUbertooth::VERSION
  s.authors      = ['Simone Margaritelli']
  s.email        = 'evilsocket@gmail.com'
  s.summary      = 'Ubertooth library port for ruby'
  s.homepage     = 'https://github.com/evilsocket/rubertooth'
  s.description  = %q{This is an ubertooth manipulation library for Ruby. With it, users can read, parse, and write bluetooth packets.}
  s.files        = Dir['exe/**/*', 'lib/**/{*,.[a-z]*}']
  s.require_path = 'lib'
  s.bindir       = 'exe'
  s.executables  = ['ble-sniff.rb', 'stream-rx.rb']
  s.license      = 'BSD'
  s.required_ruby_version = '>= 2.2.1'

  s.add_dependency 'ffi', '~> 1.9'
  s.add_dependency 'libusb', '~> 0.5'
  s.add_dependency 'bindata', '~> 2.1'
  s.add_development_dependency 'bundler', '~> 1.8'
  s.add_development_dependency 'rake', '~> 0.8'

  s.extra_rdoc_files  = %w[README.md]
end
