# This file define a class of model configuration, which essentially contains
# a list of surfaces, and a camera setting. Besides, it also load texture from
# image files, and provide class method to read and write model information in 
# XML file.
#
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load system lib
require 'fileutils'
require "rexml/document"
# load sketchup lib
require "sketchup"
# load plug-in lib
require "tools"
require "surfconfig"
require "camconfig"
# load settings
require "settings"

module AnimationGenerator
  # Class Start: ModelConfig
  class ModelConfig
    # public attributions
    attr :name, :camera, :surflist
    
    # constructor: from xml branch
    def initialize(node)
      # ------- fundamental info -------
      @name = node.attributes["name"]
      # ------- load surface -------
      # initialize surface list
      @surflist = Array.new
      # read surface one by one
      node.elements.each("surface") do |s|
        if s.attributes["name"]
          # get surface name
          sname = s.attributes["name"].downcase
          # check existence of attribution "name"
          raise ArgumentError, "surface #{sname} do not found!" \
            unless @@surflib[sname]
          # copy surface from surface lib
          @surflist << @@surflib[sname].clone
        else
          # load surface by configuration
          @surflist << SurfConfig.new(s)
        end
      end
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
      # output folder name
      outfd = File.join(PATH["output"], Time.now.strftime("%Y%m%d"), @name.upcase)
      # generate output folder
      FileUtils.mkdir_p(outfd)
      # start animation
      @camera.animate(outfd)
    end
    
    # define class method as the file system interface
    class << self
      # static array of surface libarary
      @@surflib = Hash.new()
      
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

        # load texture library
        # --------------------
        # get material handle of SketchUp
        mts = Sketchup.active_model.materials
        # load materials with specific texture
        config.elements.each("texture") do |t|
          tname = t.attributes["name"].downcase
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
        
        # load surface library
        # --------------------
        config.elements.each("surflib") do |sl|
          slname = sl.attributes["name"].downcase
          # add new surface to surface library if not exist before
          unless @@surflib[slname]
            # add new surface
            @@surflib[slname] = SurfConfig.new(sl)
            # print information
            puts "Loaded Surface : #{slname} [Surface Library]"
          end
        end

        # generate ModelConfig instance for each model node
        config.elements.each("model") {|m| marr << ModelConfig.new(m)}
        
        # return the array of model configuration
        return marr
      end
      
    end
    
  end
  # Class End: ModelConfig
end
