require "sketchup"

require "su_animgen/settings"
require "su_animgen/curvdist"

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    # uvmap interface method
    def uvmap(face, symtype, origin, norm, orient)
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
                     v.position, origin, norm, orient)
      end
      # return uvpoint array
      return uvpoint    
    end
    
    # uvmap for axis-symmetric
    def uvaxis(point, origin, norm, orient)
      # regularize input arguments
      point  = Geom::Point3d.new(point)
      origin = Geom::Point3d.new(origin)
      norm   = Geom::Vector3d.new(norm).normalize
      orient = Geom::Vector3d.new(orient).normalize
      
      # vector of position
      op = point - origin
      # normalized projection of position vector to top plane
      q = planeproj(op, norm)
      
      # calculate curve distance
      d =  curvdist(q.length, op.dot(norm))
      
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
      return Geom::Point3d.new([
        d * cos / TEXTURE_SIZE['x'], 
        d * sin / TEXTURE_SIZE['y'],
        1])
    end
    
    # uvmap for plane-symmetric
    def uvplane(point, origin, norm, orient)
      # regularize input arguments
      point  = Geom::Point3d.new(point)
      origin = Geom::Point3d.new(origin)
      norm   = Geom::Vector3d.new(norm).normalize
      orient = Geom::Vector3d.new(orient).normalize
      
      # vector op : from origin to point
      op = point - origin
      # projection of vector op to x-z plane
      q = planeproj(op, orient)
      # projection to x axis
      x = q.dot(orient.cross(norm))
      # get sign of q to xaxis
      sign = x >= 0 ? 1.0 : -1.0
      
      # calculate curf distance
      d = curvdist(x.abs, q.dot(norm))
      
      # calculate coordinate of uvpoint
      return Geom::Point3d.new([
        sign * d / TEXTURE_SIZE['x'], 
        op.dot(orient) / TEXTURE_SIZE['y'], 
        1])
    end
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator