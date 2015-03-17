require "sketchup"
require "forwardable"
require "rexml/document"

require "su_animgen/settings"
require "su_animgen/surfdraw"

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
    
    # constructor from file
    def initialize(name,surflist,code)
      @name     = name
      @surflist = surflist
      @code     = code
    end
    
    # draw surface in SketchUp space
    def draw
      @surflist.each do |surf|
        # generate specific type of surface in SkechUp
        case surf.type.downcase
        when "gaussian"
          surf.suobj = surfdraw(method(:gaussian), surf.position, surf.normal, surf.params)
        when "sphere"
          surf.suobj = surfdraw(method(:sphere), surf.position, surf.normal, surf.params)
        else
          raise ArgumentError, 'Unknow surface type!'
        end
        # add texture to the surface
        add_texture(surf.suobj,surf.texture) if surf.suobj
      end
    end
    
    # define class method as the file system interface
    class << self
      # load function to load model configurations from xml file
      def load(fname)
        # search for configuration file
        fname = File.absolute_path(fname, AGPATH["config"]) unless File.exist?(fname)
        
        # parsing document by REXML lib
        doc = REXML::Document.new File.new(fname)
        
        # get configuration node
        config = doc.root
        
        # initialize array of instances of ModelConfig
        marr = Array.new
        # generate ModelConfig instance for each model node
        config.elements.size.times do |i|
          # get model handel
          m = config.elements[i+1]
          
          # initilize surface list
          slist = Array.new
          # construct each surface configuration according to xml file
          m.elements.each("surface") do |s|
            # get type of current surface
            type = s.attributes["type"].downcase
            # load surface configuration according to type
            slist << surfload(s,SURFPARAM[type])
          end
          # construct ModelConfig instance
          marr << ModelConfig.new(m.attributes["name"], slist, m.attributes["code"])
          # output information
          puts "Loaded Model : #{marr.last.name}"
          
          # get material handle of SketchUp
          mts = Sketchup.active_model.materials
          # load materials with specific texture
          m.elements.each("texture") do |t|
            tname = t.attributes["name"]
            # add new material if not exist
            unless mts[tname]
              # add a new material
              mt = mts.add(tname)
              # assigne texture file to it
              mt.texture = File.exist?(t.text) \
                           ? t.text 
                           : File.absolute_path(t.text, AGPATH["texture"])
              # show information
              puts "Loaded Texture : #{tname}"
            end
          end                
        end
        
        # return the array of model configuration
        return marr
      end
      
      # save function export current model list to a xml file
      def save(modelarr,fname)
        # deal with single model case
        unless modelarr.is_a?(Array)
          modelarr = [modelarr]
        end
        # this function is unnecessary at this time
      end
      
      # surface load function create SurfConfig from REXML node
      private
      def surfload(node, sparams)
        type  = node.attributes["type"]
        # get elements list
        elist = node.elements
        # must-have parameters of a surface
        texture  = elist["texture"].text
        position = elist["position"].text.split(",").map{|s| s.to_f}
        normal   = elist["normal"].text.split(",").map{|s| s.to_f}
        # other parameters
        params = Hash.new
        sparams.each {|key| params[key] = elist[key].text.to_f}
        # generate SurfConfig
        return SurfConfig.new(type,texture,position,normal,params,nil)
      end
      
    end
    
    # add texture to the group of faces in SketchUp
    private
    def add_texture(suobj,tname)
      # materials handle of SketchUp
      mts = Sketchup.active_model.materials
      # check existance of material with required texture
      raise ArgumentError, "texture #{tname} not found!" unless mt = mts[tname]
      # set each face in object with specific material
      suobj.entities.each {|e| e.material = mt if e.is_a?(Sketchup::Face)}
    end
    
  end
  # Class End: ModelConfig
end