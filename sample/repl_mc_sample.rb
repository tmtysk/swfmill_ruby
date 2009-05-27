require '../lib/swfmill_util'
require 'pp'

################################################################################
# test to replace movieclip

# initialize
swf = SwfmillUtil::Swf.parseSwf(File.open("data/sample_original.swf").read)
swf2 = SwfmillUtil::Swf.parseSwf(File.open("data/sample_original2.swf").read)

# check included movieclips (object_id => SwfmillUtil::Swf::DefineSprite)
pp swf.movieclips.keys #=> ["8", "5"]
pp swf2.movieclips.keys #=> ["6", "3"]

# check included movieclip_ids by instance_name
pp swf.movieclip_ids_named("animation") #=> ["5"]
pp swf2.movieclip_ids_named("animation") #=> ["6"]

# replace movieclip
swf.movieclips["5"] = swf2.movieclips["6"]

# write swf replaced movieclip
swf.write("data/replaced_mc.swf")
