module SwfmillUtil

  # Movieclip Resource in SWF
  class DefineSprite

    attr_accessor :images, :texts, :movieclips
    attr_reader :xmldoc
    private_class_method :new

    # initialize by XML (gotten by swf2xml)
    # Param:: xml: xml gotten by swf2xml
    # Param:: template_mode: true if skipping to read swf structure
    def self.parseXml(xml, template_mode = false)
      new(nil, xml, template_mode)
    end

    # private class method to initialize
    # Param:: swf: swf(binary string)
    # Param:: xml: gotten by swf2xml
    # Param:: template_mode: true if skipping to read swf structure
    def initialize(swf, xml, template_mode)
      @swf = swf
      @xml = xml
      @xmldoc = LibXML::XML::Document.string(@xml)
      @images = ReplacableResources.new
      @texts = ReplacableResources.new
      @movieclips = ReplacableResources.new
      read_swf_structure unless template_mode
      def @images.[]=(k,v); super; self.replaced_ids << k; end
      def @texts.[]=(k,v); super; self.replaced_ids << k; end
      def @movieclips.[]=(k,v); super; self.replaced_ids << k; end
    end

    # get internal movieclip id by instance name on stage
    # Param:: name: instance_name on stage (String)
    # Return:: movieclip_ids: Array of movieclip_ids (String)
    def movieclip_ids_named(name)
      es = @xmldoc.find(".//PlaceObject2[@name='#{name}']")
      es.collect { |e| e.attributes['objectID'] }
    end

    # make partial movieclip xml from self(Sprite)
    # Param:: adjustment: true if you wish to adjust object_id
    # Param:: root_define_sprite_id_to: target object_id on replacing
    # Param:: available_id_from: minimum object_id to use in adjustment
    # Param:: skip_root_node: skip to output xml instruction node and root node if true
    # Return:: template xml
    def partialize(adjustment = false, root_define_sprite_id_to = 0, available_id_from = 0, skip_root_node = false)
      xmldoc = LibXML::XML::Document.string(@xmldoc.to_s(:indent => false))
      if adjustment then
        root_define_sprite_id_from = xmldoc.root.attributes['baseObjectID']
        # reset id_map for adjustment each movieclip
        object_id_map = {}
        # adjust object_id refering in movieclip
        xmldoc.root.children.each do |e|
          xpath_axes = "//"
          # making object_id_map
          if e.name == "DefineSprite" && e.attributes['objectID'] == root_define_sprite_id_from.to_s then
            # inherit original object_id 
            #object_id_map[e.attributes['objectID']] = root_define_sprite_id_to.to_s
            e.attributes['objectID'] = root_define_sprite_id_to.to_s
            xpath_axes = ".//"
          else
            object_id_map[e.attributes['objectID']] = available_id_from.to_s unless object_id_map[e.attributes['objectID']]
            e.attributes['objectID'] = object_id_map[e.attributes['objectID']]
            available_id_from += 1
          end
          # adjustment!
          object_id_map.each do |from,to|
            e.find("#{xpath_axes}*[@objectID='#{from}']").each do |ae|
              ae.attributes['objectID'] = to
            end
          end
        end
      end
      if skip_root_node then
        xmldoc.root.children.inject("") { |result,node| result << node.to_s }.gsub(Regexp.new('<?xml version="1.0" encoding="UTF-8"?>'), '')
      else
        xmldoc.to_s
      end
    end

    # make template xml from self(Sprite)
    # Param:: templatized_ids: object_ids of DefineSprite on replacing with target_id and replaced_chars
    # Param:: removed_referred: removing referred elements from self(sprite) if true
    # Return:: templatized text
    def templatize(templatized_ids = {}, remove_referred = false)
      xmldoc = LibXML::XML::Document.string(@xmldoc.to_s(:indent => false))
      templatized_ids.each do |tid,hash|
        xmldoc.find("//DefineSprite[@objectID='#{tid}']").each do |ds|
          ds.prev = LibXML::XML::Node.new_text("#{hash[:replace_name]}")
          ds.remove!
        end
        if remove_referred then
          self.movieclips["#{tid}"].xmldoc.root.children.each do |e|
            xmldoc.find("//#{e.name}[@objectID='#{e.attributes['objectID']}']").each do |rf|
              rf.remove!
            end
          end
        end
        xmldoc.find("//PlaceObject2[@objectID='#{tid}']").each do |pl|
          pl.attributes['objectID'] = hash[:replace_id].to_s
        end
      end
      xmldoc.to_s
    end

    # make template to be able to templatize.
    # use to templatize a partialized template repeatedly.
    def templatizable
      @xmldoc.root.name = 'TemplatizedSprite' if @xmldoc.root.name = 'ClippedSprite'
      read_swf_structure
    end

    protected

    # protected method
    # reading swf structure and set each ReplacableResources
    #  to instance variables
    def read_swf_structure
      @xmldoc.find('.//DefineBitsLossless2').each { |n| @images[n.attributes['objectID']] = DefineBitsLossless2.xml2image(n) }
      @xmldoc.find('.//DefineBitsJPEG2').each { |n| @images[n.attributes['objectID']] = DefineBitsJPEG2.xml2image(n) }
      @xmldoc.find('.//DefineEditText').each { |n| @texts[n.attributes['objectID']] = n.attributes['initialText'] }

      @referred_place_object = Hash.new do |hash,object_id|
        xml = ""
        # pickup referred DefineShape
        @xmldoc.find(".//*[self::DefineShape[@objectID='#{object_id}'] or self::DefineShape2[@objectID='#{object_id}'] or self::DefineShape3[@objectID='#{object_id}']]").each do |e1|
          # pickup referred ClippedBitmap 
          e1.find('.//ClippedBitmap[@objectID]').each do |e2|
            # pickup referred DefineBitsLossless2 and DefineBitsJPEG2
            @xmldoc.find(".//*[self::DefineBitsLossless2[@objectID='#{e2.attributes['objectID']}'] or self::DefineBitsJPEG2[@objectID='#{e2.attributes['objectID']}']]").each do |e3|
              xml << e3.to_s
            end
          end
          xml << e1.to_s
        end
        # pickup referred DefineEditText
        @xmldoc.find(".//DefineEditText[@objectID='#{object_id}']").each do |e|
          xml << e.to_s
        end
        # pickup referred PlaceSprite(Recursive)
        inserted = {}
        @xmldoc.find(".//DefineSprite[@objectID='#{object_id}']").each do |e|
          e.find('.//PlaceObject2[@objectID]').each do |re|
            unless inserted[re.attributes['objectID']] then
              xml << @referred_place_object[re.attributes['objectID']]
              inserted[re.attributes['objectID']] = true
            end
          end
          xml << e.to_s
        end
        hash[object_id] = xml
      end

      @xmldoc.find('.//DefineSprite').each do |e|
        next if e.parent.name == 'ClippedSprite'
        # pickup referred PlaceObject
        inserted = {}
        sprite_xml = ""
        e.find('.//PlaceObject2[@objectID]').each do |re|
          #sprite_xml << referred_place_object(re.attributes['objectID'])
          unless inserted[re.attributes['objectID']] then
            sprite_xml << @referred_place_object[re.attributes['objectID']]
            inserted[re.attributes['objectID']] = true
          end
        end
        sprite_xml << e.to_s
        @movieclips[e.attributes['objectID']] = DefineSprite.parseXml("<ClippedSprite baseObjectID='#{e.attributes['objectID']}'>#{sprite_xml}</ClippedSprite>")
      end
    end
  end

  # JPEG Image Resource in SWF
  class DefineBitsJPEG2
    # class method
    # make Magick::Image instance from xml
    # Param:: LibXML::XML::Node of DefineBitsJPEG2
    # Return:: Magick::Image
    def self.xml2image(node)
      data = Base64.decode64(node.find_first('data/data').content)
      Magick::Image.from_blob(data[4..-1]).first
    end

    # class method
    # make xml from Magick::Image instance
    # Param:: object_id: new object_id
    # Param:: image: Magick::Image (JPEG compression)
    # Return:: LibXML::XML::Node
    def self.image2xml(object_id, image)
      node = LibXML::XML::Node.new("DefineBitsJPEG2")
      node.attributes['objectID'] = object_id.to_s
      data1 = LibXML::XML::Node.new('data')
      data2 = LibXML::XML::Node.new('data', Base64.encode64([0xff, 0xd9, 0xff, 0xd8].pack("C*") + image.to_blob).gsub("\n",""))
      data1 << data2
      node << data1
      node
    end
  end

  # Lossless Bitmap Image Resource in SWF
  class DefineBitsLossless2
    ShiftDepth = Magick::QuantumDepth - 8
    MaxRGB = 2 ** Magick::QuantumDepth - 1

    # class method
    # make xml from Magick::Image instance
    # Param:: object_id: new object_id
    # Param:: image: Magick::Image (PNG or GIF compression)
    # Return:: LibXML::XML::Node
    def self.image2xml(object_id, image)
      node = LibXML::XML::Node.new("DefineBitsLossless2")
      node.attributes['objectID'] = object_id.to_s

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

      node.attributes['format'] = '3'
      node.attributes['width'] = image.columns.to_s
      node.attributes['height'] = image.rows.to_s
      node.attributes['n_colormap'] = (colormap.length-1).to_s
      data1 = LibXML::XML::Node.new('data')
      data2 = LibXML::XML::Node.new('data', Base64.encode64(Zlib::Deflate.deflate(data)).gsub("\n",""))
      data1 << data2
      node << data1
      node
    end

    # class method
    # make Magick::Image instance from xml
    # Param:: LibXML::XML::Node of DefineBitsLossless2
    # Return:: Magick::Image
    def self.xml2image(node)
      raise if node.attributes['format'] != "3"
      head = 0
      width = node.attributes['width'].to_i
      height = node.attributes['height'].to_i
      data = Zlib::Inflate.inflate(Base64.decode64(node.find_first('data/data').content))
      # ready to make colormap
      colormap = []
      (node.attributes['n_colormap'].to_i + 1).times do |i|
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

  # SWF
  class Swf < DefineSprite

    # initialize by swf binary string
    def self.parseSwf(swf)
      new(swf, Swfmill.swf2xml(swf), false)
    end

    # regenerate swf using SwfmillUtil::Swfmill.xml2swf
    # Param:: adjustment: adjusting object_id in Swf if true
    # Return:: Swf binary string
    def regenerate(adjustment)
      xmldoc = LibXML::XML::Document.string(@xmldoc.to_s(:indent => false))
      # replace image element
      @images.each do |object_id, image|
        if @images.replaced_ids.include? object_id then
          image_node = xmldoc.find_first(".//*[self::DefineBitsLossless2[@objectID='#{object_id}'] or self::DefineBitsJPEG2[@objectID='#{object_id}']]")
          if image_node then
            if image.format == 'JPEG' then
              image_node.prev = DefineBitsJPEG2.image2xml(object_id, image)
              image_node.remove!
            else
              image_node.prev = DefineBitsLossless2.image2xml(object_id, image)
              image_node.remove!
            end
          else
            raise ReplaceTargetNotFoundError
          end
        end
      end
      # replace text
      @texts.each do |object_id, text|
        if @texts.replaced_ids.include? object_id then
          text_node = xmldoc.find_first(".//DefineEditText[@objectID='#{object_id}']")
          if text_node then
            text_node.attributes['initialText'] = text
          else
            raise ReplaceTargetNotFoundError
          end
        end
      end
      # replace movieclip
      ## get available object_id (greadter than maximum now)
      available_id_from = adjustment ? (xmldoc.to_s.scan /objectID=['"](\d+)['"]/).collect { |i| i[0].to_i }.delete_if { |i| i == 65535 }.max + 1 : 0 if adjustment
      @movieclips.each do |object_id, define_sprite|
        if @movieclips.replaced_ids.include? object_id then
          movieclip_node = xmldoc.find_first(".//DefineSprite[@objectID='#{object_id}']")
          if movieclip_node then
            # reset id_map for adjustment each movieclip
            object_id_map = {}
            # adjust object_id refering in movieclip
            define_sprite.xmldoc.root.children.each do |e|
              if adjustment then
                xpath_axes = "//"
                # making object_id_map
                if e.name == "DefineSprite" and e.attributes['objectID'] == define_sprite.xmldoc.root.attributes['baseObjectID'] then
                  # inherit original object_id 
                  e.attributes['objectID'] = object_id
                  xpath_axes = ".//"
                else
                  # need to adjust?
                  if xmldoc.find_first(".//*[@objectID='#{e.attributes['objectID']}']") then
                    # object_id dupplicated .. need to adjust
                    object_id_map[e.attributes['objectID']] = available_id_from.to_s unless object_id_map[e.attributes['objectID']]
                    e.attributes['objectID'] = object_id_map[e.attributes['objectID']]
                    available_id_from += 1
                  end
                end
                # adjustment!
                object_id_map.each do |from,to|
                  e.find("#{xpath_axes}*[@objectID='#{from}']").each do |ae|
                    ae.attributes['objectID'] = to
                  end
                end
              end
              # inserting new elements
              movieclip_node.prev = e
            end
            # deleting original movieclip
            movieclip_node.remove!
          else
            raise ReplaceTargetNotFoundError
          end
        end
      end
      Swfmill.xml2swf(xmldoc.to_s)
    end

    # regenerate and write swf file
    # Param:: filename
    # Param:: adjustment: adjusting object_ids if true
    def write(filename, adjustment = true)
      File.open(filename, 'w') do |f|
        f.write regenerate(adjustment)
      end
    end
  end

  # ReplacableResouces in Swf
  class ReplacableResources < Hash
    attr_accessor :replaced_ids
    def initialize
      super
      @replaced_ids = []
    end
  end

  class ReplaceTargetNotFoundError < StandardError; end

end
