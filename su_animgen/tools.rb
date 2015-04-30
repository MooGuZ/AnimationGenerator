# this file contains all tools that designed to help other components
# of AnimationGenerator to finish their job.
#
# MooGu Z. <hzhu@case.edu>
# Mar 27, 2015

# load system lib
require "digest"
# load sketchup lib
require "sketchup"

module AnimationGenerator 
  
  class ::String
    # convert string to array
    def to_a
      if self.include?("],[") 
        # this is an array of arrays
        return self.scan(/\[[0-9, ]*\]/)
                   .map(&:to_a)
      else
        return self.gsub(/[\[\]]/,'')
                   .split(',')
                   .map {|s| s.to_f}
      end
    end
    
    # array?: decide a string represent an array or not
    def array?
      return self.include?(',')
    end
    
    # number?: decide a string represent a number
    def number?
      return /\A[-+]?\d*[\.]?\d+\z/ === self
    end
  end
  
  # packed?: check multiple values for a key
  def packed?(key, value)
    # special case
    return nil if key.nil? || value.nil?
    # according to key's type
    case key
    when "direction"
      return value[0].is_a?(Array)
    when "velocity"
      return value.is_a?(Array)
    else
      raise ArgumentError, "unknow key : #{key}!"
    end
  end
  
  # intersection detector
  def intersected?(model, from, to)
    # regularize points in sketchup space
    from = Geom::Point3d.new(from)
    to   = Geom::Point3d.new(to)
    # calculate direction vector
    dirt = (to - from).normalize
    # do ray test get intersection point
    intersect = model.raytest([from,dirt])
    # if intersection exisit in the direction
    # - compare it to point "TO"
    unless intersect.nil?
      return from.distance(intersect[0]) < from.distance(to)
    end
    # if no intersection return false
    return false     
  end
  
  # vector's project on a plane
  def planeproj(vec, norm, assist = [0,0,0])
    # ensure paramters are Geom::Vector3d 
    vec    = Geom::Vector3d.new(vec)
    norm   = Geom::Vector3d.new(norm).normalize
    assist = Geom::Vector3d.new(assist)
    
    # deal with zero vector
    return vec if vec.length == 0
    
    # if vector parallel to normal of face
    vec = assist if vec.parallel?(norm)
    
    # get the projection
    return vec - norm.transform(Geom::Transformation.scaling(vec % norm))
  end
  
  # generate permutation of hash table
  def permute(org)
    # initialize output array
    perm = Array.new
    # get all the keys of hash table
    keys = org.keys
    # create permutation key by key
    keys.each do |key|
      if perm.empty?
        org[key].each{|value| perm << {key => value}}
      else
        buffer = Array.new
        perm.each do |h|
          org[key].each{|value| buffer << h.merge({key => value})}
        end
        perm = buffer
      end
    end
    # return permutation
    return perm
  end
  
  # pick curtain digitals from Fixnum
  def pickdgt(num,from,len)
    # return nil for other classes
    return nil unless num.is_a?(Integer)
    # pick out specified digitals
    return num / 10**(from-1) % 10**len
  end
  
  # convert anything into 8 letter codes
  def azcode(anything)
    # define letters
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    # get MD5 of input object
    hnum = Digest::MD5.hexdigest(anything.to_s).to_i(16)
    # construct and return code
    return letters[pickdgt(hnum,37,5) % 26] +
           letters[pickdgt(hnum,32,5) % 26] +
           letters[pickdgt(hnum,27,5) % 26] +
           letters[pickdgt(hnum,22,5) % 26] +
           letters[pickdgt(hnum,17,5) % 26] +
           letters[pickdgt(hnum,11,5) % 26] +
           letters[pickdgt(hnum, 6,5) % 26] +
           letters[pickdgt(hnum, 1,5) % 26]
  end
end
      