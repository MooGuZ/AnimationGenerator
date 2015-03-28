# this file contains all tools that designed for AnimationGenerator
#
# MooGu Z. <hzhu@case.edu>
# Mar 27, 2015

require "digest"

module AnimationGenerator 
  # convert string to array
  class ::String
    def to_a
      return self.gsub(/[\[\(\< \>\)\]]/,'')
                 .split(',')
                 .map {|s| s.to_f}
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
      raise ArgumentError, "unknow type of key!"
    end
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
      