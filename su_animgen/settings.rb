# this file contains all the settings utilized in AnimationGenerator
module AnimationGenerator
  # file system information
  # -----------------------
  PATH = Hash.new
  # path of this setting file
  PATH["setting"]  = File.expand_path(__FILE__)
  # path of SketchUp plugin folder
  PATH["suplugin"] = File.absolute_path("..",File.dirname(PATH["setting"]))
  # path of configuration files
  PATH["config"]   = File.join(PATH["suplugin"], "su_animgen/config")
  # path of texture file folder
  PATH["texture"]  = File.join(PATH["suplugin"], "su_animgen/texture")
  # path of output files
  PATH["output"]   = File.expand_path("~/Documents/SketchUp/AnimationGenerator")
  
  # initialize default values hash table
  DEFAULT = Hash.new
  
  # surface related information
  # ---------------------------
  # accuracy of curve in drawing
  ACCURACY    = 0.1
  # thickness of drawing surface
  THICKNESS   = 0.01
  # method of drawing : shape or surface
  DRAWMETHOD  = :surface
  # maximum segment number of a drawing element
  MAX_SEG_NUM = 30
  # base-orientations
  MAIN_ORIENT = [0,0,1]
  AUXL_ORIENT = [1,0,0]
  # ...........................................
  # parameter list of different type of surface
  SURFPARAM = Hash.new
  SURFPARAM["gaussian"]  = ["curvature","height","radius"]
  SURFPARAM["sphere"]    = ["curvature","angle"]
  SURFPARAM["circle"]    = ["radius"]
  SURFPARAM["rectangle"] = ["width","height","orient"]
  # list of available surface type
  SURFTYPE = SURFPARAM.keys
  # ............................................
  # parameter list of different symmetric policy
  SYMPARAM = Hash.new
  SYMPARAM["axis"]  = []
  SYMPARAM["plane"] = ["orient", "symrange"]
  # list of available symmetric type
  SYMTYPE = SYMPARAM.keys
  # ........................
  # default values : surface
  DEFAULT["surface"] = Hash.new
  DEFAULT["surface"]["sym"] = "axis"
  
  # camera related settings
  # -----------------------
  # default value : camera
  DEFAULT["camera"] = Hash.new
  DEFAULT["camera"]["aspratio"] = 1.0
  DEFAULT["camera"]["fov"]      = 30.0
  DEFAULT["camera"]["imwidth"]  = 35.0
  
  # animation related information
  # -----------------------------
  # animation settings
  IMRESX    = 128
  IMRESY    = 128
  ANTIALIAS = true
  IMQUALITY = 1.0
  MAXFRAME  = 24
  FRAMERATE = 24.0
  # ......................................
  # parameter list of different trajectory
  TRAJPARAM = Hash.new
  TRAJPARAM["shift"]    = ["direction","velocity"]
  TRAJPARAM["approach"] = ["velocity"]
  TRAJPARAM["rotate"]   = ["velocity"]
  TRAJPARAM["line"]     = ["direction","velocity"]
  # list of trajectory types
  TRAJTYPE = TRAJPARAM.keys
  # ......................................
  # animation information table parameters
  ANIMINFO = Hash.new
  ANIMINFO["filename"] = "anim-info.csv"
  ANIMINFO["header"]   = [
    "code", "time", "trajectory", "eye", 
    "target", "up", "direction", "velocity"]
  
  # other settings
  # --------------
  
end
  