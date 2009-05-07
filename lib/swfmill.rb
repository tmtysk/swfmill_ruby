module SwfmillUtil

  SWFMILL = "/Users/tmtysk/bin/swfmill"

  class Swfmill

    def self.xml2swf(xml, option = "-e cp932")
      IO.popen("#{SWFMILL} #{option} xml2swf stdin", "r+") do |io|
        io.write xml
        io.close_write
        io.read
      end
    end

    def self.swf2xml(swf, option = "-e cp932")
      IO.popen("#{SWFMILL} #{option} swf2xml stdin", "r+") do |io|
        io.write swf
        io.close_write
        io.read
      end
    end

  end

end
