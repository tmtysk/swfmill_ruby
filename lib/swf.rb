module SwfmillUtil

  class Swf

    attr_accessor :images, :texts

    def initialize(swf)
      @swf = swf
      @xml = Swfmill.swf2xml(swf)
      @rexml = REXML::Document.new(@xml)
      @images = {}
      @rexml.root.each_element('//DefineBitsLossless2') { |e| @images[e.attributes['objectID']] = DefineBitsLossless2.xml2image(e) }
      @rexml.root.each_element('//DefineBitsJPEG2') { |e| @images[e.attributes['objectID']] = DefineBitsJPEG2.xml2image(e) }
      @texts = {}
      @rexml.root.each_element('//DefineEditText') { |e| @texts[e.attributes['objectID']] = e.attributes['initialText'] }
    end

    def regenerate
      # replace image element
      @images.each do |object_id,image|
        image_node = REXML::XPath.first(@rexml.root, "//DefineBitsLossless2[@objectID='#{object_id}']") || REXML::XPath.first(@rexml.root, "//DefineBitsJPEG2[@objectID='#{object_id}']")
        if image_node then
          if image.format == 'JPEG' then
            image_node.parent.replace_child(image_node, DefineBitsJPEG2.image2xml(object_id, image))
          else
            image_node.parent.replace_child(image_node, DefineBitsLossless2.image2xml(object_id, image))
          end
        else
          raise ReplaceTargetNotFoundError
        end
      end
      # replace text
      @texts.each do |object_id,text|
        text_node = REXML::XPath.first(@rexml.root, "//DefineEditText[@objectID='#{object_id}']") 
        if text_node then
          text_node.attributes['initialText'] = text
        else
          raise ReplaceTargetNotFoundError
        end
      end
      Swfmill.xml2swf(@rexml.to_s)
    end

    def write(filename)
      File.open(filename, 'w') do |f|
        f.write regenerate
      end
    end

    class DefineBitsJPEG2
      def self.xml2image(element)
        data = Base64.decode64(element.get_elements('data/data').first.text)
        Magick::Image.from_blob(data[4..-1]).first
      end

      def self.image2xml(object_id, image)
        element = REXML::Element.new("DefineBitsJPEG2")
        element.add_attribute('objectID', object_id.to_s)
        data1 = element.add_element('data')
        data2 = data1.add_element('data')
        data2.text = Base64.encode64([0xff, 0xd9, 0xff, 0xd8].pack("C*") + image.to_blob).gsub("\n","")
        element
      end
    end

    class DefineBitsLossless2

      ShiftDepth = Magick::QuantumDepth - 8
      MaxRGB = 2 ** Magick::QuantumDepth - 1

      def self.image2xml(object_id, image)
        element = REXML::Element.new("DefineBitsLossless2")
        element.add_attribute('objectID', object_id.to_s)
        data1 = element.add_element('data')
        data2 = data1.add_element('data')

        colormap = []
        data = ""
        image.get_pixels(0, 0, image.columns, image.rows).each_with_index do |pixel,i|
          idx = colormap.index(pixel)
          if idx then
            data << [idx].pack("C")
          else
            colormap << pixel
            data << [colormap.length-1].pack("C")
          end
          if (i+1) % image.rows == 0 then
            # padding
            data += [0].pack("C") * (4-(image.rows%4))
          end
        end
        data = colormap.inject("") { |r,c|
          opacity = (MaxRGB-c.opacity) >> ShiftDepth
          if opacity == 0 then
            r += 
              [0].pack("C") +
              [0].pack("C") +
              [0].pack("C") +
              [opacity].pack("C")
          else
            r += 
              [c.red >> ShiftDepth].pack("C") +
              [c.green >> ShiftDepth].pack("C") +
              [c.blue >> ShiftDepth].pack("C") +
              [opacity].pack("C")
          end
        } + data

        element.add_attribute('format', '3')
        element.add_attribute('width', image.columns.to_s)
        element.add_attribute('height', image.rows.to_s)
        element.add_attribute('n_colormap', (colormap.length-1).to_s)
        data2.text = Base64.encode64(Zlib::Deflate.deflate(data)).gsub("\n","")
        element
      end

      def self.xml2image(element)
        raise if element.attributes['format'] != "3"
        head = 0
        width = element.attributes['width'].to_i
        height = element.attributes['height'].to_i
        data = Zlib::Inflate.inflate(Base64.decode64(element.get_elements('data/data').first.text))
        # ready to make colormap
        colormap = []
        (element.attributes['n_colormap'].to_i + 1).times do |i|
          colormap[i] = {
          'r' => data[head,1].unpack("C").first << ShiftDepth,
          'g' => data[head+1,1].unpack("C").first << ShiftDepth,
          'b' => data[head+2,1].unpack("C").first << ShiftDepth,
          'a' => MaxRGB - (data[head+3,1].unpack("C").first << ShiftDepth)
          }
          head += 4
        end
        # making pixels
        pixels = []
        height.times do |h|
          width.times do |w|
            mapidx = data[head,1].unpack("C*").first
            pixels << Magick::Pixel.new(
              colormap[mapidx]['r'],
              colormap[mapidx]['g'],
              colormap[mapidx]['b'],
              colormap[mapidx]['a']
            )
            head += 1
          end
          head += (4-(width%4))
        end
        # making image
        image = Magick::Image.new(width, height) {
          self.colorspace = Magick::RGBColorspace
          self.compression = Magick::NoCompression
          self.background_color = "transparent"
        }
        image.store_pixels(0, 0, width, height, pixels)
      end
    end

    class ReplaceTargetNotFoundError < StandardError; end

  end
end
