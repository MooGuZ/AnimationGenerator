# this file contains all the settings utilized in AnimationGenerator
module AnimationGenerator
  # file system information
  # -----------------------
  PATH = Hash.new unless defined? PATH
  # path of this setting file
  PATH["setting"]  = File.expand_path(__FILE__)
  # path of SketchUp plugin folder
  PATH["suplugin"] = File.absolute_path("..",File.dirname(PATH["setting"]))
  # path of configuration files
  PATH["config"]   = File.absolute_path("su_animgen/config",PATH["suplugin"])
  # path of texture file folder
  PATH["texture"]  = File.absolute_path("su_animgen/texture",PATH["suplugin"])
  
  # initialize default values hash table
  DEFAULT = Hash.new unless defined? DEFAULT
  
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
  # list of available surface type
  SURFTYPE = ['gaussian','sphere']
  # parameter list os different type of surface
  SURFPARAM = Hash.new unless defined? SURFPARAM
  SURFPARAM["gaussian"] = ["curvature","height","radius"]
  SURFPARAM["sphere"]   = ["curvature","angle"]
  
end
  