require 'zlib'
require 'base64'
require 'rexml/document'
require 'rubygems'
require 'RMagick'

Dir[File.join(File.dirname(__FILE__), '*.rb')].sort.each { |f| require f }
