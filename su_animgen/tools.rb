# this file contains all tools that designed for AnimationGenerator
#
# MooGu Z. <hzhu@case.edu>
# Mar 27, 2015

module AnimationGenerator 
  # convert string to array
  class ::String
    def to_a
      return self.gsub(/[\[\(\< \>\)\]]/,'')
                 .split(',')
                 .map {|s| s.to_f}
    end
  end
  
  # generate full combination of two array
  def combination(arr_a, arr_b)
    # special cases
    return arr_b if arr_a.nil? || (arr_a.is_a?(Array) && arr_a.empty?)
    return arr_a if arr_b.nil? || (arr_b.is_a?(Array) && arr_b.empty?)
    return nil unless arr_a.is_a?(Array) && arr_b.is_a?(Array) 
    # initialize combinatory array
    comb = Array.new
    # traverse every combination
    arr_a.each {|a| arr_b.each {|b| comb << [a,b]}}
    # return combinatory array
    return comb
  end
end
      