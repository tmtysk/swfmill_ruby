require '../lib/swfmill_ruby'
require 'pp'

################################################################################
# test to partialize movieclip

# initialize
swf = SwfmillRuby::Swf.parseSwf(File.open("data/sample_original.swf").read)
swf2 = SwfmillRuby::Swf.parseSwf(File.open("data/sample_original2.swf").read)

# check included movieclips (object_id => SwfmillRuby::Swf::DefineSprite)
pp swf.movieclips.keys #=> ["8", "5"]
pp swf2.movieclips.keys #=> ["6", "3"]

# check included movieclip_ids by instance_name
pp swf.movieclip_ids_named("animation") #=> ["5"]
pp swf2.movieclip_ids_named("animation") #=> ["6"]

# partialize movieclip specifying the mapping of object_ids
#  and available, unused object_id (if you want to adjust object_ids)
File.open("data/animation_partial.xml", "w") do |f|
  f.puts swf2.movieclips["6"].partialize(true, 5, 1000)
end

# if you wish to use String#gsub instead of LibXML on replacing,
#  specify skip_root_node = true on partialize
File.open("data/animation_partial_gsub.xml", "w") do |f|
  f.puts swf2.movieclips["6"].partialize(true, 5, 1000, true)
end
