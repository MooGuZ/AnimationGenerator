# This file provide a method to convert curve to a surface according to the specific
# symmetric type. This method aims at replace 'followme' in sketchup, which require
# a face to start surface construction process, and in this way, the result always
# is actually a shape not surface. Further more, this restriction cause a lot of
# trouble in implementing several functions. The verion I implemented here can only
# work in side the surface configuration class because it directly uses a lot class
# variables.
#
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load sketchup lib
require "sketchup"
# load settings
require "settings"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    private
    
    # curv2surf : construct surface from curve points
    def curv2surf(curvPts)
      method(("c2s"+@sym).to_sym).call(curvPts)
    end
    
    # c2saxis : axis-symmetric version of curv2surf
    def c2saxis(curvPts)
      # get required parameters
      pos  = Geom::Point3d.new(@position)
      norm = Geom::Vector3d.new(@normal).normalize

      # radius of curve
      radius = curvPts.map{|p| (p - @position).dot(@orient.cross(@normal)).abs}.max
      # calculate how many faces woud generated in a circle
      nface = (2 * Math::PI * radius / ACCURACY).ceil
      # apply segment restriction
      nface = [[nface, CIRCLE_SEG_NUM_MAX].min, CIRCLE_SEG_NUM_MIN].max
      # ensure there are even number of faces
      nface += 1 if nface.odd?
      # calculate rotation angle for each time
      angle = 2 * Math::PI / nface
      # construct rotation transformation
      rotating = Geom::Transformation.rotation(pos, norm, angle)
      
      # create faces by rotation
      nface.times do |i|
        # rotate points a step
        nextPts = curvPts.map{|p| p.transform(rotating)}
        # create face one by one
        (curvPts.size - 1).times do |i|
          # generate vertices for current face
          points = [
            curvPts[i],
            curvPts[i+1],
            nextPts[i+1],
            nextPts[i]
          ]
          begin
            # generate face use sketchup api
            @suobj.entities.add_face(points)
          rescue ArgumentError
            # remove duplicate points
            points = rmdup(points)
            # extreme case which should not happen
            next if points.size < 3
            # add face again
            @suobj.entities.add_face(points)
          end
        end
        # update curve points
        curvPts = nextPts
      end
    end
    
    # c2splane : plane-symmetric version of curv2surf
    def c2splane(curvPts)
      # get required paramters
      range = @params["symrange"]
      
      # abnormal cases
      raise ArgumentError, "symmertic range cannot be zero" if range == 0
      
      # calculate translation vector
      shifting = @orient.transform(Geom::Transformation.scaling(range / 2))
      
      # create faces by translation
      (curvPts.size - 1).times do |i|
        # if curvPts contains even number of points means the curve is detached
        # - from y-z plane, then, no face should created between two part of the 
        # - surface.
        next if DETACHEDSURF.member?(@type) && (i == (curvPts.size / 2) - 1)
        # points of face
        points = [
          curvPts[i] - shifting,
          curvPts[i] + shifting,
          curvPts[i+1] + shifting,
          curvPts[i+1] - shifting
        ]
        # add face to sketchup space, the exception of duplicate points should 
        # - never happen here, because function 'xmirror' and 'curvdraw' should
        # - eliminate them for plane symmetric condition already
        @suobj.entities.add_face(points)
      end
    end
    
    # rmdup : helper function to remove duplicate points
    def rmdup(points)
      # initialize array to contain unique points
      uniPts = Array.new
      # check distance from one points to others
      points.size.times do |i|
        havedup = false
        (i+1).upto(points.size - 1) do |j|
          havedup = true if points[i].distance(points[j]) <= ZEROTOLERANCE
        end
        uniPts << points[i] unless havedup
      end
      # return unique points array
      return uniPts
    end
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator