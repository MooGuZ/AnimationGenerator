require "sketchup"
require "rexml/document"

require "su_animgen/tools"
require "su_animgen/settings"
require "su_animgen/surfdraw"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    # attributions
    attr :type, :sym, :texture, :position,
         :normal, :params, :suobj
         
    # constructor: from xml branch
    def initialize(node)
      # get surface type
      @type = node.attributes["type"].downcase
      # check availability of surface type
      unless SURFTYPE.include?(@type)
        raise ArgumentError, "Unknown surface type : #{@type}!"
      end
      # get symmtric setting
      @sym  = node.attributes["sym"] ?
              node.attributes["sym"].downcase :
              DEFAULT["surface"]["sym"]
      # check availability of symmetric setting
      unless SYMTYPE.include?(@sym)
        raise ArgumentError, "Unkonwn symmetric setting : #{@sym}"
      end
      # get elements list
      elist = node.elements
      # must-have parameters of a surface
      @texture  = elist["texture"].text.downcase
      @position = elist["position"].text.to_a
      @normal   = elist["normal"].text.to_a
      # load other parameters
      @params = Hash.new
      # parameters for surface
      SURFPARAM[@type].each do |key|
        @params[key] = elist[key].text.array? ?
                       elist[key].text.to_a :
                       elist[key].text.to_f
      end
      # paramters for symmetric
      SYMPARAM[@sym].each do |key|
        @params[key] = elist[key].text.array? ?
                       elist[key].text.to_a :
                       elist[key].text.to_f
      end
      # initialize sketchup obj to nil
      @suobj = nil
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
      curvPts, range, flat = cfunc.call(@params, thickness, accuracy)
      
      # calculate coordinates in sketchup space
      zaxis = norm
      yaxis = @params.keys.include?("orient") ?
              planeproj(MAIN_ORIENT,norm,AUXL_ORIENT).transform(
                Geom::Transformation.rotation(
                  [0,0,0],
                  norm,
                  Math::PI * @params["orient"] / 180)).normalize :
              planeproj(MAIN_ORIENT,norm,AUXL_ORIENT).normalize
      xaxis = yaxis.cross(zaxis)
      # calculate origin point in sketchup space
      orgpt = pos
      unless flat
        orgpt -= norm.transform(Geom::Transformation.scaling(curvPts[0].z))
        if @sym == "plane"
          orgpt -= yaxis.transform(Geom::Transformation.scaling(@params["symrange"]/2))
        end
      end
      # form transformation transform canonial space to sketchup space
      trans = Geom::Transformation.new(xaxis, yaxis, zaxis, orgpt)
      
      # [TODROP] complete the other half for plane-symmetric beform transformation
      curvPts = xcomplete(curvPts[0..(curvPts.size-2)]) if !flat && @sym == "plane"
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
      
      # special process for surfaces (comparing to planes)
      unless flat
        # generate surface construct following edges
        case @sym
        when "axis"
          # generate circle for axis-symmetric
          fedges = ents.add_circle(
            Geom::Point3d.new([0,0,0]).transform(trans),
            norm,
            range * 1.1)
        when "plane"
          # get other vertex of following edge (one is at pos)
          other = orgpt + yaxis.transform(Geom::Transformation.scaling(@params["symrange"]))
          # generate following edge for plane-symetric
          fedges = ents.add_curve(orgpt, other)
        else
          raise ArgumentError, "unknown symmetric type : #{@sym}"
        end
        # use followme to generate curvature shape
        cface.followme(fedges)
        # remove following edges from model
        fedges.each {|e| ents.erase_entities(e) if e.valid?}
        
        # [ABD] for hardness, just add texture to front-back both side
        # # find a sample face to determin the face direction
        # sface = ents.find do |e|
        #   e.is_a?(Sketchup::Face) && 
        #   e.vertices.map{|v| v.position}.include?(pos) &&
        #   !e.normal.perpendicular?(norm)
        # end
        # # reverse faces if in opposite direction
        # if sface.normal.dot(norm) < 0
        #   ents.each {|e| e.reverse! if e.is_a?(Sketchup::Face)}
        # end
      end
      
      # soft and smooth edges in the group
      ents.each do |e|
        if e.is_a?(Sketchup::Edge)
          e.soft   = true unless e.soft?
          e.smooth = true unless e.smooth?
        end
      end
      
      # add texture if necessary
      unless @texture == "none"
        # get material handle of SketchUp
        mts = Sketchup.active_model.materials
        # check existance of material with required texture
        raise ArgumentError, "texture #{@texture} not found!" unless mt = mts[@texture]
        # set each face in object with specific material
        @suobj.entities.each do |e| 
          if e.is_a?(Sketchup::Face)
            # # set material on face
            # e.material = mt
            # e.back_material = mt
            # calculate uvpoints of this face
            uvpoint = uvmap(e, @sym, pos, norm, yaxis, range)
            # assign texture position of this face
            e.position_material(mt, uvpoint, true)
            e.position_material(mt, uvpoint, false)
          end
        end
      end
    end 
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator