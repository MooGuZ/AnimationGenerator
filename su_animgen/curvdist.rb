require "sketchup"

require "su_animgen/settings"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    # curvdist : interface to calculate distance on current curve
    def curvdist(x, z)
      return method(("dist"+@type).to_sym).call(x, z)
    end
    
    # distgaussian : distance estimation on gaussian curve
    def distgaussian(x, z)
      # gaussian function would be very hard to accurately calculate
      # the length of the curve, however, the euclidian distance is
      # quite a good approximation. Here, I just adopt it.
      return Math.sqrt(x**2 + z**2)
    end
    
    # distsphere : distance calculation on sphere curve
    def distsphere(x, z)
      # get radius of sphere
      radius = 1 / Float(@params["curvature"]).abs
      # [!!!] calibrate radius if necessary
      radius = radius + THICKNESS if @params["curvature"] < 0
      # calculate length of vector
      l = Math.sqrt(x**2 + z**2)
      # deal abnormal case
      raise ArgumentError, "something wrong in DISTSPHERE" if l > 2 * radius
      # get central angle
      angle = 2 * Math.asin(l / (2 * radius))
      # return curve distance
      return radius * [angle, Math::PI - angle].min
    end
    
    def distcircle(x, z)
      return x
    end
    
    def distrectangle(x, z)
      return x
    end
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator