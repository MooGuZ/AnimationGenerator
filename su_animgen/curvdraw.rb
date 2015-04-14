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
      
      # calculate number of segments
      nseg = [(radius / ACCURACY).ceil, MAX_SEG_NUM].min
      # generate curve points
      curvPts = (0..nseg).map do |i|
        x = i * radius / nseg
        z = (curvature > 0) ? height * Math.exp((-x**2 * curvature) / (2 * height))
                            : height * (1 - Math.exp((x**2 * curvature) / (2 * height)))
        Geom::Point3d.new([x, 0, z])
      end

      # return curve points and radius of surface
      return curvPts, radius, false
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
      # calculate number of segments
      nseg = [(angle * radius / ACCURACY).ceil, MAX_SEG_NUM].min
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

      # return curve points
      return curvPts, range, false 
    end
    
    # face : circle
    def circle()
      # get paramter from hash
      radius = Float(@params["radius"])
      
      # calculate number of segments
      nseg = (Math::PI * radius / ACCURACY).ceil
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
      
      return pts, Math.sqrt(width**2 + height**2), true
    end
    
  end
  # Class End: SurfConfig
end