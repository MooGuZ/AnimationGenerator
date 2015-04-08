require "matrix"
require "sketchup"

require "su_animgen/settings"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    # uvmap interface method
    def uvmap(face, symtype, origin, norm, orient, range)
      # initialize uvpoint array
      uvpoint = Array.new()
      # calculate uvposition of each vertices on face
      face.vertices.each do |v|
        # check number of uvpoints in array
        break if uvpoint.size >= 8
        # add position of current vertex to uvpoint array
        uvpoint << v.position
        # call specific method according to symmetric type
        uvpoint << method(("uv"+symtype).to_sym).call(
                     v.position, origin, norm, orient, range)
      end
      # return uvpoint array
      return uvpoint    
    end
    
    # uvmap for axis-symmetric
    def uvaxis(point, origin, norm, orient, range)
      # regularize input arguments
      point  = Geom::Point3d.new(point)
      origin = Geom::Point3d.new(origin)
      norm   = Geom::Vector3d.new(norm).normalize
      orient = Geom::Vector3d.new(orient).normalize
      range  = Float(range)
      
      # vector of position
      op = point - origin
      # estimate radius by euclidien distance
      r = op.length / [2 * range, TEXTURE_SIZE.values.min].max
      # normalized projection of position vector to top plane
      q = planeproj(op, norm)
      # calculate sin and cos
      if q.length == 0
        cos = 0.0
        sin = 0.0
      else
        q.normalize!
        cos = q.dot(orient.cross(norm))
        sin = q.dot(orient)
      end
      
      # return uvpoint
      return Geom::Point3d.new([0.5 + r * cos, 0.5 + r * sin, 1])
    end
    
    # uvmap for plane-symmetric
    def uvplane(point, origin, norm, orient, range)
      # regularize input arguments
      point  = Geom::Point3d.new(point)
      origin = Geom::Point3d.new(origin)
      norm   = Geom::Vector3d.new(norm).normalize
      orient = Geom::Vector3d.new(orient).normalize
      range  = Float(range)
      
      # get range of x and y
      rangex = [2 * range, TEXTURE_SIZE['x']].max
      rangey = [2 * @params["symrange"], TEXTURE_SIZE['y']].max
      
      # vector op : from origin to point
      op = point - origin
      # projection of vector op to x-z plane
      q = planeproj(op, orient)
      # get sign of q to xaxis
      sign = q.dot(orient.cross(norm)) >= 0 ? 1.0 : -1.0
      
      # calculate coordinate of uvpoint
      return Geom::Point3d.new([sign * q.length / rangex, op.dot(orient) / rangey, 1])
    end
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator