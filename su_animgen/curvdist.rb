# This file calculate distance between two points on a specific type of surface.
# It provide a interface as DIST = CURVDIST(), and this method would automatically
# choose the concrete calculating method according to the surface type of current
# surface configuration.
#
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load system lib
require "matrix"
# load settings
require "settings"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    private
    
    # curvdist : interface to calculate distance on current curve
    def curvdist(x, z)
      return method(("dist"+@type).to_sym).call(x, z)
    end
    
    # ===============================================================
    def distgaussian(x, z)
      # gaussian function would be very hard to accurately calculate
      # the length of the curve, however, the euclidian distance is
      # quite a good approximation. Here, I just adopt it.
      # return Vector[x,z].norm
      
      # alternative solution : use segments simulate the distances
      # ----------------------------------------------------------
      nseg = 13
      # get curve parameters
      curvature = @params["curvature"]
      height    = @params["height"]
      # initialize distance and point record
      dist = 0
      prcd = Vector[0,height]
      # generate curve points
      (1..nseg).map do |i|
        r = i * x / nseg
        h = height * Math.exp((-r**2 * curvature.abs) / (2 * height))
        # update distance
        dist += (Vector[r,h] - prcd).norm
        # update point record
        prcd = Vector[r,h]
      end
      
      # return distance
      return dist
    end
    
    # ===============================================================
    def distsphere(x, z)
      # get radius of sphere
      radius = 1 / Float(@params["curvature"]).abs
      # calculate length of vector
      l = Math.sqrt(x**2 + z**2)
      # deal abnormal case
      # raise ArgumentError, "something wrong in DISTSPHERE" if l > 2 * radius
      l = 2 * radius if l > 2 * radius
      # get central angle
      angle = 2 * Math.asin(l / (2 * radius))
      # return curve distance
      return radius * [angle, Math::PI - angle].min
    end
    
    # ===============================================================
    def distcircle(x, z)
      return x
    end
    
    # ===============================================================
    def distrectangle(x, z)
      return x
    end
  
    # ===============================================================
    def distdonut(x, z)
      # get parameter of donut curve
      offset = @params["offset"]
      radius = @params["radius"]
      # use ATAN2 method to get the angle of this point
      angle = Math.atan2(z, x - offset)
      # [special case] indistinguishable point
      if (angle.abs - Math::PI).abs <= ZEROTOLERANCE
        # check the center of surface in buffer and 
        # - decide the sign of anlge
        angle = (@buffer - @position).dot(@normal) > 0 ? Math::PI : -Math::PI
      end
      # estimate the number of texture cycles
      nCycle = ((2 * Math::PI * radius) / TEXTURE_SIZE['y']).ceil
      # return the distance that make the cross section of donut continuous
      return angle / (2 * Math::PI) * TEXTURE_SIZE['y'] * nCycle
    end
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator
