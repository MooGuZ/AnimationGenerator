# This file define a class of surface configuration, which essentially contains
# construction-related information of a surface, including shape, symmetric type,
# position, orientation, texture information, and also maintains a handle of 
# corresponding sketchup objects.
#
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load system lib
require "rexml/document"
# load sketchup lib
require "sketchup"
# load plug-in lib
require "tools"
require "curvdraw"
require "curv2surf"
require "uvmap"
# load settings
require "settings"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    # attributions
    attr :type, :sym, :texture, :position,
         :normal, :orient, :params, :suobj
         
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
      @position = Geom::Point3d.new(elist["position"].text.to_a)
      @normal   = Geom::Vector3d.new(elist["normal"].text.to_a).normalize
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
      # initialize orient as nil
      @orient = nil
      # initialize sketchup obj to nil
      @suobj = nil
      # create a buffer for calculatine issues
      @buffer = nil
    end
    
    # surface drawing
    def draw()
      # construct corresponding sketchup objects
      pos  = Geom::Point3d.new(@position)
      norm = Geom::Vector3d.new(@normal).normalize
      
      # calculate closed curve points in canonical space
      curvPts, offset, flat = curvdraw()
      
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
      orgpt = pos - norm.transform(Geom::Transformation.scaling(offset))
      # form transformation transform canonial space to sketchup space
      trans = Geom::Transformation.new(xaxis, yaxis, zaxis, orgpt)
      
      # setup orient
      @orient = yaxis
      
      # extend curve points in x-axis for plane-symmetric surface
      curvPts = xmirror(curvPts) if !flat && @sym == "plane"
      # transform curve points to sketchup space (Don't use 'transform!', it sometime fail)
      curvPts = curvPts.map {|p| p.transform(trans)}
      
      # create a group for this surface
      @suobj = Sketchup.active_model.entities.add_group
      
      # draw face/surface in sketchup space
      if flat
        # draw the face directly
        @suobj.entities.add_face(@suobj.entities.add_curve(curvPts))
      else
        # generate surface from curve and symmetric rule
        curv2surf(curvPts)
      end     
      
      # soft and smooth edges in the group
      @suobj.entities.each do |e|
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
            # calculate uvpoints of this face
            uvpoint = uvmap(e)
            # assign texture position of this face
            e.position_material(mt, uvpoint, true)
            e.position_material(mt, uvpoint, false)
          end
        end
      end
      
      # clear buffer
      @buffer = nil
    end
    
    private
    # xmirror: create x-axis mirror of points to complete points set
    def xmirror(points)
      # define mirror transformation
      trans  = Geom::Transformation.rotation([0,0,0],[0,0,1],Math::PI)
      # make mirror points
      mirror = points.map{|pt| pt.transform(trans)}.reverse
      # check distance of last element of reversed-mirror and first element of original
      if DETACHEDSURF.member?(@type)
        # combine complete original and mirror points
        return mirror + points
      else
        # combine original and mirror points without last point in mirror
        return mirror[0..(mirror.size-2)] + points
      end
    end
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator