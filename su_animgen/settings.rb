# this file contains all the settings utilized in AnimationGenerator
module AnimationGenerator
  
  # file system information
  # -----------------------
  AGPATH = Hash.new unless defined? AGPATH
  # path of this setting file
  AGPATH["setting"]  = File.expand_path(__FILE__)
  # path of SketchUp plugin folder
  AGPATH["suplugin"] = File.absolute_path("..",File.dirname(AGPATH["setting"]))
  # path of configuration files
  AGPATH["config"]   = File.absolute_path("su_animgen/config",AGPATH["suplugin"])
  # path of texture file folder
  AGPATH["texture"]  = File.absolute_path("su_animgen/texture",AGPATH["suplugin"])
  
  
  # surface related information
  # ---------------------------
  # accuracy of curve in drawing
  ACCURACY    = 0.1
  # thickness of drawing surface
  THICKNESS   = 0.01
  # method of drawing : shape or surface
  DRAWMETHOD  = :surface
  # maximum segment number of a drawing element
  MAX_SEG_NUM = 30 unless defined? MAX_SEG_NUM
  # parameter list os different type of surface
  SURFPARAM = Hash.new unless defined? SURFPARAM
  SURFPARAM["gaussian"] = ["curvature","height","radius"]
  SURFPARAM["sphere"]   = ["curvature","angle"]
  
end
  