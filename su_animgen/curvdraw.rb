# This file provide a interface to draw specific type of curves according to the
# surface configuration.
# 
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load sketchup lib
require "sketchup"
# load settings
require "settings"

# this file contains all the specific surface drawing method of AnimationGenerator
module AnimationGenerator
  # Class Start: SurfConfig
  class SurfConfig    
    private
    
    # curvdraw : interface
    def curvdraw()
      method(@type.to_sym).call()
    end
    
    # surface : gaussian
    def gaussian()
      # get parameters from Hash
      curvature = @params["curvature"]
      height    = @params["height"]
      radius    = @params["radius"]
      
      # check availability of input arguments : HEIGHT
      raise ArgumentError, "CURVATURE cannot be 0 for Gaussian surface" if curvature == 0
      raise ArgumentError, 'HEIGHT cannot be 0 for Gaussian surface' if height == 0
      
      # calculate number of segments according to variance (height / curvature)
      # nseg = (radius / ACCURACY).ceil
      nseg = (GAUSSIAN_SEG_PER_SIG * radius / Math.sqrt((height / curvature).abs)).ceil
      # generate curve points
      curvPts = (0..nseg).map do |i|
        x = i * radius / nseg
        z = (curvature > 0) ? height * Math.exp((-x**2 * curvature) / (2 * height))
                            : height * (1 - Math.exp((x**2 * curvature) / (2 * height)))
        Geom::Point3d.new([x, 0, z])
      end

      # return curve points and radius of surface
      return curvPts, ((curvature > 0) ? height : 0), false
    end
    
    # surface : sphere
    def sphere()
      # get parameters from Hash
      curvature = @params["curvature"]
      angle     = @params["angle"] * Math::PI / 360

      # input arugment check
      raise ArgumentError, "CURVATURE cannot be 0 for Sphere surface" if curvature == 0
      
      # regulize angle
      angle = Math::PI if (angle <= 0 || angle >= Math::PI)
      
      # calculate radius
      radius = 1 / curvature.abs
      # calculate delta angle for each face
      dangle = Math::PI / (2 * (Math::PI * radius / ACCURACY / 2.0).ceil)
      # calculate number of segments
      nseg = (angle * radius / ACCURACY).ceil
      # apply segment restriction
      nseg = [[nseg, CIRCLE_SEG_NUM_MAX].min, CIRCLE_SEG_NUM_MIN].max
      # calculate delta angle and calibrate it to make integer faces in pi/2
      dangle = angle / nseg
      dangle = (Math::PI / 2) / (Math::PI / 2 / dangle).ceil
      # recalculate number of segment (may slightly bigger than maximum)
      nseg = (angle / dangle).ceil
      # generate curve points
      curvPts = (0..nseg).map do |i|
        theta = Math::PI / 2 - i * dangle
        # deal with the overflow
        theta = (Math::PI / 2 - angle) if theta < (Math::PI / 2 - angle)
        # calculate coordinates
        x = Math.cos(theta) * radius
        z = (curvature > 0) ? Math.sin(theta) * radius 
                            : (1 - Math.sin(theta)) * radius
        Geom::Point3d.new([x, 0, z])
      end
      # return curve points
      return curvPts, ((curvature > 0) ? radius : 0), false 
    end
    
    # face : circle
    def circle()
      # get paramter from hash
      radius = Float(@params["radius"])
      
      # calculate number of segments
      nseg = (2 * Math::PI * radius / ACCURACY).ceil
      # apply segment restriction
      nseg = [[nseg, CIRCLE_SEG_NUM_MAX].min, CIRCLE_SEG_NUM_MIN].max
      # generate points
      pts = (0..nseg).map do |i|
        theta = 2 * Math::PI * i / nseg
        Geom::Point3d.new([
          radius * Math.cos(theta), 
          radius * Math.sin(theta), 
          0])
      end
      
      return pts, 0, true
    end
    
    # face : rectangle
    def rectangle()
      # get paramter from hash
      width  = @params["width"] / 2
      height = @params["height"] / 2
      
      # generate points
      pts = [
        Geom::Point3d.new([ width,  height, 0]),
        Geom::Point3d.new([-width,  height, 0]),
        Geom::Point3d.new([-width, -height, 0]),
        Geom::Point3d.new([ width, -height, 0]),
        Geom::Point3d.new([ width,  height, 0])
      ]
      
      return pts, 0, true
    end
    
    # surface : Donut
    def donut()
      # get parameters from hash
      offset = @params["offset"]
      radius = @params["radius"]
      
      # check the parameters
      if offset <= radius
        raise ArgumentError, "radius of donut should be smaller than its offset"
      end
      
      # calculate number of segment for drawing circle
      nseg = 2 * (Math::PI * radius / ACCURACY).ceil
      # apply segment restriction
      nseg = [[nseg, CIRCLE_SEG_NUM_MAX].min, CIRCLE_SEG_NUM_MIN].max
      # generate points
      pts = (0..nseg).map do |i|
        theta = 2 * Math::PI * i / nseg
        Geom::Point3d.new([
          offset + radius * Math.cos(theta),
          0,
          radius * Math.sin(theta)
        ])
      end
      
      return pts, 0, false
    end    
  end
  # Class End: SurfConfig
end