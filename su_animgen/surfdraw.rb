require "sketchup"

require "su_animgen/settings"

# this file contains all the specific surface drawing method of AnimationGenerator
module AnimationGenerator
  # Class Start: ModelConfig
  class ModelConfig    
    # Gaussian Surface
    private
    def gaussian(params, thickness, accuracy)
      # get parameters from Hash
      curvature = Float(params["curvature"])
      height    = Float(params["height"])
      radius    = Float(params["radius"])
      
      # check availability of input arguments : HEIGHT
      raise ArgumentError, "CURVATURE cannot be 0 for Gaussian surface" if curvature == 0
      raise ArgumentError, 'HEIGHT cannot be 0 for Gaussian surface' if height == 0
      
      # if drawing in shape, regulize RADIUS
      if DRAWMETHOD == :shape && radius > 3 * Math.sqrt(height / curvature.abs)
        radius = 3 * Math.sqrt(height / curvature.abs)
        puts 'Radius is reset for the limitation of SketchUp!'
      end
      
      # calculate number of segments
      nseg = [(radius / accuracy).ceil, MAX_SEG_NUM].min
      # generate curve points
      curvPts = (0..nseg).map do |i|
        x = i * radius / nseg
        z = (curvature > 0) ? height * Math.exp((-x**2 * curvature) / (2 * height))
                            : height * (1 - Math.exp((x**2 * curvature) / (2 * height)))
        Geom::Point3d.new([x, 0, z])
      end
      # make closed curve with assistant points
      case DRAWMETHOD
      when :surface
        # define shifting transformation
        t = Geom::Transformation.translation([0, 0, -thickness])
        # attach assistant points
        curvPts += curvPts.map{|p| p.transform(t)}.reverse
      when :shape
        # add anchor point
        curvPts << ((curvature > 0) ? Geom::Point3d.new([0,0,0]) 
                                    : Geom::Point3d.new([radius,0,0]))
      else
        raise ArgumentError, 'Undefined drawing method!'
      end
      # add first point to close the curve
      curvPts << curvPts[0]
      
      # return curve points and radius of surface
      return curvPts, radius
    end
    
    # Sphere with arbitraty angle
    private
    def sphere(params, thickness, accuracy)
      # get parameters from Hash
      curvature = Float(params["curvature"])
      angle     = params["angle"] * Math::PI / 360
      
      # input arugment check
      raise ArgumentError, "CURVATURE cannot be 0 for Sphere surface" if curvature == 0
      
      # regulize angle
      angle = Math::PI if (angle <= 0 || angle >= Math::PI)
      
      # calculate radius
      radius = 1 / curvature.abs
      # calculate number of segments
      nseg = [(angle * radius / accuracy).ceil, MAX_SEG_NUM].min
      # generate curve points
      curvPts = (0..nseg).map do |i|
        theta = Math::PI / 2 - i * angle / nseg 
        x = Math.cos(theta) * radius
        z = (curvature > 0) ? Math.sin(theta) * radius 
                            : (1 - Math.sin(theta)) * radius
        Geom::Point3d.new([x, 0, z])
      end
      # calculate the range of surface
      range = (angle <= Math::PI / 2) ? curvPts.last.x : radius
      # make closed curve with assistant points
      case DRAWMETHOD
      when :surface
        # geometry center of curve
        center = (curvature > 0) ? [0, 0, 0] : [0, 0, radius]
        # create transformation for generating closed curve
        t = (curvature > 0) ? Geom::Transformation.scaling(center, 1 - thickness / radius)
                            : Geom::Transformation.scaling(center, 1 + thickness / radius)
        # generate assistant points by transformation and attach to curve points
        curvPts += curvPts.map{|p| p.transform(t)}.reverse
      when :shape
        if curvature > 0
          curvPts << Geom::Point3d.new([0, 0, curvPts.last.z])
        elsif angle <= Math::PI / 2
          curvPts << Geom::Point3d.new([curvPts.last.x, 0, 0])
        else
          curvPts << Geom::Point3d.new([radius + thickness, 0, curvPts.last.z])
          curvPts << Geom::Point3d.new([radius + thickness, 0, 0])
        end
      else
        raise ArgumentError, 'Undefined drawing method!'
      end
      # add first point to close the curve
      curvPts << curvPts[0]
      
      # return curve points
      return curvPts, range 
    end
    
    # surface drawing function works like a drawing engine for gerneral surfaces
    private
    def surfdraw(cfunc, pos, norm, params, thickness = THICKNESS, accuracy = ACCURACY)
      # construct corresponding sketchup objects
      pos  = Geom::Point3d.new(pos)
      norm = Geom::Vector3d.new(norm).normalize
      
      # ensure every parameter for calculation is Float
      thichness = Float(thickness)
      accuracy  = Float(accuracy)
      
      # calculate closed curve points in canonical space
      curvPts, range = cfunc.call(params, thickness, accuracy)
      
      # define transformation from canonical space to sketchup space
      trans = Geom::Transformation.new(
        pos - norm.transform(Geom::Transformation.scaling(curvPts[0].z)), 
        norm)
      # transform curve points to sketchup space
      curvPts = curvPts.map {|p| p.transform(trans)}
      
      # create a group for this surface
      grp = Sketchup.active_model.entities.add_group
      # get entities handle of sketchup
      ents = grp.entities
      # generate closed curve in sketchup space
      curv = ents.add_curve(curvPts)
      # generate face based on the curve
      cface = ents.add_face(curv)
      # generate circle as following edges
      fedges = ents.add_circle(
        Geom::Point3d.new([0,0,0]).transform(trans),
        norm,
        range * 1.1)
      # use followme to generate curvature shape
      cface.followme(fedges)
      # remove follow edges from model
      ents.erase_entities(fedges)
      
      # find a sample face to determin the face direction
      sface = ents.find do |e|
        e.is_a?(Sketchup::Face) && e.vertices.map{|v| v.position}.include?(pos)
      end
      # reverse faces if in opposite direction
      if sface.normal.dot(norm) < 0
        ents.each {|e| e.reverse! if e.is_a?(Sketchup::Face)}
      end
      
      # return the surface group
      return grp
    end
    
  end
  # Class End: ModelConfig
end