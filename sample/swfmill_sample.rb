require '../lib/swfmill_util'

#################################################################################
# test to use SwfmillUtil::Swfmill

xml = File.open('sample.xml').read
xml.gsub!(Regexp.new('####BACKGROUND_IMAGE####'),
            Base64.encode64([0xff, 0xd9, 0xff, 0xd8].pack("C*") +
            File.open('bg.jpg').read).gsub("\n",""))

File.open('foo.swf', 'w') do |f|
  f.write SwfmillUtil::Swfmill.xml2swf(xml)
end
