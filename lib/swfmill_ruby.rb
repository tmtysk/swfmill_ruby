require 'zlib'
require 'base64'
require 'libxml'
require 'rubygems'
require 'RMagick'

Dir[File.join(File.dirname(__FILE__), '*.rb')].sort.each { |f| require f }
