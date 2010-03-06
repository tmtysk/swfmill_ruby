require '../lib/swfmill_ruby'
require 'pp'

################################################################################
# test to templatize Swf

# initialize
swf = SwfmillUtil::Swf.parseSwf(File.open("data/sample_original.swf").read)

# check included movieclips (object_id => SwfmillUtil::Swf::DefineSprite)
pp swf.movieclips.keys #=> ["8", "5"]

# check included movieclip_ids by instance_name
pp swf.movieclip_ids_named("animation") #=> ["5"]

# templatize Swf - replace specified movieclip element will be replaced to 
#  special text pattern (for using String#gsub).
File.open("data/animation_template_gsub.xml", "w") do |f|
  f.puts swf.templatize({ "5" => { :replace_name => '####PARTIAL_MOVIECLIP_5####', :replace_id => 5 } })
end
