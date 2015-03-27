require "sketchup"
require 'fileutils'
require "rexml/document"

require "su_animgen/tools"
require "su_animgen/settings"
require "su_animgen/surfconfig"
require "su_animgen/camconfig"

module AnimationGenerator
  # Class Start: ModelConfig
  class ModelConfig
    # public attributions
    attr :name, :code, :camera, :surflist
    
    # constructor: from xml branch
    def initialize(node)
      # ------- fundamental info -------
      # read name
      @name = node.attributes["name"]
      # read code
      @code = node.attributes["code"].upcase
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
          # search for texture file
          tfile = File.exist?(t.text) ? t.text : File.expand_path(t.text)
          tfile = File.join(PATH["texture"], t.text) unless File.exist?(tfile)
          # assigne texture file to it
          mt.texture = tfile
          # show information
          puts "Loaded Texture : #{tname}"
        end
      end 
      # ------- load surface -------
      # initialize surface list
      @surflist = Array.new
      # read surface one by one
      node.elements.each("surface") {|s| @surflist << SurfConfig.new(s)}
      # ------- load camera -------
      @camera = CamConfig.new(node.elements["camera"])
      # ------- show information -------
      puts "Loaded Model   : #{@name}"
    end
    
    # draw surface in SketchUp space
    def draw
      @surflist.each {|surf| surf.draw}
    end
    
    # generate animation
    def animate
      # draw the model at first if necessary
      unless @surflist.map{|surf| !surf.suobj.nil? && surf.suobj.valid?}.all?
        Sketchup.active_model.entities.clear!
        draw
      end
      # generate output folder name
      outfd = File.join(PATH["output"], Time.now.strftime("%Y%m%d"), @code)
      # start animation
      @camera.animate(outfd)
    end
    
    # define class method as the file system interface
    class << self
      # load function to load model configurations from xml file
      def load(fname)
        # search for configuration file
        unless File.exist?(fname)
          fname = File.exist?(File.expand_path(fname)) ?
                  File.expand_path(fname) :
                  File.join(PATH["config"], fname)
        end
        
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