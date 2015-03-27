require "sketchup"
require "rexml/document"

require "su_animgen/tools"
require "su_animgen/settings"
require "su_animgen/surfdraw"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    # attributions
    attr :type, :texture, :position,
         :normal, :params, :suobj
         
    # constructor: from xml branch
    def initialize(node)
      # get surface type
      @type  = node.attributes["type"].downcase
      # check availability of type
      raise ArgumentError, 'Unknown surface type!' unless SURFTYPE.include?(@type)
      # get elements list
      elist = node.elements
      # must-have parameters of a surface
      @texture  = elist["texture"].text.downcase
      @position = elist["position"].text.to_a
      @normal   = elist["normal"].text.to_a
      # other parameters
      @params = Hash.new
      SURFPARAM[@type].each {|key| @params[key] = elist[key].text.to_f}
      # initialize sketchup obj to nil
      @suobj  = nil
    end
    
    # surface drawing
    def draw(thickness = THICKNESS, accuracy = ACCURACY)
      # construct corresponding sketchup objects
      pos  = Geom::Point3d.new(@position)
      norm = Geom::Vector3d.new(@normal).normalize
      
      # ensure every parameter for calculation is Float
      thichness = Float(thickness)
      accuracy  = Float(accuracy)
      
      # get curve function
      cfunc = method(@type.to_sym)
      
      # calculate closed curve points in canonical space
      curvPts, range = cfunc.call(@params, thickness, accuracy)
      
      # define transformation from canonical space to sketchup space
      trans = Geom::Transformation.new(
        pos - norm.transform(Geom::Transformation.scaling(curvPts[0].z)), 
        norm)
      # transform curve points to sketchup space
      curvPts = curvPts.map {|p| p.transform(trans)}
      
      # create a group for this surface
      @suobj = Sketchup.active_model.entities.add_group
      # get entities handle of sketchup
      ents   = @suobj.entities
      # generate closed curve in sketchup space
      curv   = ents.add_curve(curvPts)
      # generate face based on the curve
      cface  = ents.add_face(curv)
      # generate circle as following edges
      fedges = ents.add_circle(
        Geom::Point3d.new([0,0,0]).transform(trans),
        norm,
        range * 1.1)
      # use followme to generate curvature shape
      cface.followme(fedges)
      # remove following edges from model
      ents.erase_entities(fedges)
      
      # find a sample face to determin the face direction
      sface = ents.find do |e|
        e.is_a?(Sketchup::Face) && e.vertices.map{|v| v.position}.include?(pos)
      end
      # reverse faces if in opposite direction
      if sface.normal.dot(norm) < 0
        ents.each {|e| e.reverse! if e.is_a?(Sketchup::Face)}
      end
      
      # add texture if necessary
      unless @texture == "none"
        # get material handle of SketchUp
        mts = Sketchup.active_model.materials
        # check existance of material with required texture
        raise ArgumentError, "texture #{@texture} not found!" unless mt = mts[@texture]
        # set each face in object with specific material
        @suobj.entities.each {|e| e.material = mt if e.is_a?(Sketchup::Face)}
      end
    end
    
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator