# This file provide a interface to mapping 3D points in sketchup space to 
# 2D point in texture image (the coordinate of texture are standarized to
# [0,0] to [1,1]). This interface only need the face handle in sketchup
# and return an array of points can directly used by sketchup function
# 'position_material' of Sketchup::Face objects. The interface would choose
# concrete calculation process automatically according to the current surface
# configuration.
# 
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load sketchup lib
require "sketchup"
# load plug-in lib
require "curvdist"
# load settings

module AnimationGenerator
  # class start: SurfConfig
  class SurfConfig
    private
    
    # uvmap interface method
    def uvmap(face)
      # initialize uvpoint array
      uvpoint = Array.new()
      # calculate uvposition of each vertices on face
      face.vertices.each do |v|
        # check number of uvpoints in array
        break if uvpoint.size >= 8
        # add position of current vertex to uvpoint array
        uvpoint << v.position
        # call specific method according to symmetric type
        uvpoint << method(("uv"+@sym).to_sym).call(v.position)
      end
      # return uvpoint array
      return uvpoint    
    end
    
    # uvmap for axis-symmetric
    def uvaxis(point)
      # regularize input arguments
      point  = Geom::Point3d.new(point)
      
      # vector of position
      op = point - @position
      # normalized projection of position vector to top plane
      q = planeproj(op, @normal)
      
      # calculate curve distance
      d =  curvdist(q.length, op.dot(@normal))
      
      # calculate sin and cos
      if q.length == 0
        cos = 0.0
        sin = 0.0
      else
        q.normalize!
        cos = q.dot(@orient.cross(@normal))
        sin = q.dot(@orient)
      end
      
      # return uvpoint
      return Geom::Point3d.new([
        d * cos / TEXTURE_SIZE['x'], 
        d * sin / TEXTURE_SIZE['y'],
        1])
    end
    
    # uvmap for plane-symmetric
    def uvplane(point)
      # regularize input arguments
      point  = Geom::Point3d.new(point)
      
      # vector op : from origin to point
      op = point - @position
      # projection of vector op to x-z plane
      q = planeproj(op, @normal)
      # projection to x axis
      x = q.dot(@orient.cross(@normal))
      # get sign of q to xaxis
      sign = x >= 0 ? 1.0 : -1.0
      
      # calculate curf distance
      d = curvdist(x.abs, op.dot(@normal))
      
      # calculate coordinate of uvpoint
      return Geom::Point3d.new([
        sign * d / TEXTURE_SIZE['x'], 
        op.dot(@orient) / TEXTURE_SIZE['y'], 
        1])
    end
  end
  # class end: SurfConfig
end
# module end: AnimationGenerator