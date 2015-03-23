require "sketchup"
require "forwardable"
require "rexml/document"

require "su_animgen/settings"
require "su_animgen/surfconfig"

module AnimationGenerator
  # define structure SurfConfig
  SurfConfig = Struct.new(
    :type, :texture, :position,  
    :normal, :params, :suobj
  ) unless defined? SurfConfig
    
  # Class Start: ModelConfig
  class ModelConfig
    extend Forwardable
    
    # public attributions
    attr :name, :surflist, :code
    
    # define delegators
    def_delegators :@surflist, :each, :map, :<<    
    
    # constructor: from xml branch
    def initialize(node)
      # ------- fundamental info -------
      # read name
      @name = node.attributes["name"]
      # read code
      @code = node.attributes["code"]
      # ------- load texture -------
      # get material handle of SketchUp
      mts = Sketchup.active_model.materials
      # load materials with specific texture
      node.elements.each("texture") do |t|
        tname = t.attributes["name"]
        # add new material if not exist
        unless mts[tname]
          # add a new material
          mt = mts.add(tname)
          # assigne texture file to it
          mt.texture = File.exist?(t.text) \
                       ? t.text 
                       : File.absolute_path(t.text, PATH["texture"])
          # show information
          puts "Loaded Texture : #{tname}"
        end
      end 
      # ------- load surface -------
      # initialize surface list
      @surflist = Array.new
      # read surface one by one
      node.elements.each("surface") {|s| @surflist << SurfConfig.new(s)}
    end
    
    # draw surface in SketchUp space
    def draw
      @surflist.each {|surf| surf.draw}
    end
    
    # define class method as the file system interface
    class << self
      # load function to load model configurations from xml file
      def load(fname)
        # search for configuration file
        fname = File.absolute_path(fname, PATH["config"]) unless File.exist?(fname)
        
        # parsing document by REXML lib
        doc = REXML::Document.new File.new(fname)
        
        # get configuration node
        config = doc.root
        
        # initialize array of instances of ModelConfig
        marr = Array.new
        # generate ModelConfig instance for each model node
        config.elements.each("model") {|m| marr << ModelConfig.new(m)}
        
        # return the array of model configuration
        return marr
      end
      
    end
    
  end
  # Class End: ModelConfig
end