require "sketchup"

require "su_animgen/settings"

# this file contains all the specific surface drawing method of AnimationGenerator
module AnimationGenerator
  # Class Start: SurfConfig
  class SurfConfig    
    private
    # surface : gaussian
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
      return curvPts, radius, false
    end
    
    # surface : sphere
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
      return curvPts, range, false 
    end
    
    # face : circle
    def circle(params, unused, accuracy)
      # get paramter from hash
      radius = Float(params["radius"])
      
      # calculate number of segments
      nseg = (Math::PI * radius / accuracy).ceil
      # generate points
      pts = (0..nseg).map do |i|
        theta = 2 * Math::PI * i / nseg
        Geom::Point3d.new([
          radius * Math.cos(theta), 
          radius * Math.sin(theta), 
          0])
      end
      
      return pts, radius, true
    end
    
    # face : rectangle
    def rectangle(params, *unused)
      # get paramter from hash
      width  = Float(params["width"]) / 2
      height = Float(params["height"]) / 2
      
      # generate points
      pts = [
        Geom::Point3d.new([ width,  height, 0]),
        Geom::Point3d.new([-width,  height, 0]),
        Geom::Point3d.new([-width, -height, 0]),
        Geom::Point3d.new([ width, -height, 0]),
        Geom::Point3d.new([ width,  height, 0])
      ]
      
      return pts, [width, height].max, true
    end
    
  end
  # Class End: SurfConfig
end