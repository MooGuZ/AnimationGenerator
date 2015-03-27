require "sketchup"
require "rexml/document"

require "su_animgen/settings"

module AnimationGenerator
	# class start: AGAnimation
  class AGAnimation
    # attributions
    attr_accessor :trajectory, :code, :eye, 
                  :target, :up, :params,
                  :outfd, :ifrm
    
    # constructor: from xml node
    def initialize(node)
      # get trajectory type
      @trajectory = node.attributes["trajectory"].downcase
      # check availability of trajectory type
      unless TRAJTYPE.include?(@trajectory)
        raise ArgumentError, 'Unknown trajectory type!' 
      end
      # get animation code
      @code = node.attributes["code"].upcase
      # get element list
      elist = node.elements
      # load information of start position
      @eye    = elist["eye"].text.split(",").map{|s| s.to_f}
      @target = elist["target"].text.split(",").map{|s| s.to_f}
      @up     = elist["up"].text.split(",").map{|s| s.to_f}
      # load trajectory specific parameters
      @params = Hash.new
      TRAJPARAM[@trajectory].each do |key|
        @params[key] = elist[key].text.include?(',') ?
                       elist[key].text.split(',').map{|s| s.to_f} :
                       elist[key].text.to_f
      end
      # initialize other fields
      @ifrm  = nil
      @outfd = nil
    end
    
    # nextFrame: calculate next position for camera
    def nextFrame(view)
      # calculate camera position
      new_eye, new_target, new_up = 
        method(@trajectory.to_sym).call(@eye,@target,@up,@params,@ifrm)
      # check intersection
      return false if intersected?(view.camera.eye, new_eye)
      # set new camera position
      view.camera.set(new_eye, new_target, new_up)
      # show frame
      view.show_frame
      # write image
      view.write_image(
        File.join(@outfd, "%03d.jpg" % @ifrm),
        IMRESX, IMRESY, ANTIALIAS, IMQUALITY)
      # update frame count
      @ifrm += 1
      # if reach maximum frame quantity, stop
      return @ifrm < MAXFRAME ? true : false
    end
    
    # decompose one animation into many
    def decompose
      if decomposable?
        # ------- generate parameter combination -------
        # create an array for params
        plist = Array.new
        # fill in params array
        TRAJPARAM[@trajectory].each do |key|
          # get value of key
          value = @params[key]
          # pack values if necessary
          if value.nil?
            plist << [value]
          else
            case key
            when "direction"
              plist << (value[0].is_a?(Array) ? value : [value])
            when "velocity"
              plist << (value.is_a?(Array) ? value : [value])
            end
          end
        end
        # initialize combination array
        pcomb = nil
        # create combination
        plist.each {|p| pcomb = combination(pcomb,p)}
        # ------- apply every paramter combination -------
        # create a clone to manipulate
        anim = self.clone
        # create a new Hash table of params
        anim.params = Hash.new
        # traverse every paramter combination
        pcomb.each do |p|
          # initialize code as original one
          anim.code = @code
          # assign code and parameters
          TRAJPARAM[@trajectory].each_with_index do |key,ind|
            # compose code
            if !p[ind].nil? && p[ind].is_a?(Array)
              anim.code += "-#{p[ind]}"
            else
              anim.code += "-[#{p[ind]}]"
            end
            # assign parameters
            anim.params[key] = p[ind]
          end
          # refine code by removing space
          anim.code.gsub!(' ','')
          # make animation
          yield anim
        end
      else
        yield self
      end
    end
    
    # check whether or not animation is decomposable
    def decomposable?
      # initialize return flag to false
      flag = false
      # check each parameters in animation
      @params.each do |key,value|
        unless value.nil?
          case key
          when "direction"
            flag |= value[0].is_a?(Array) && value.size > 1
          when "velocity"
            flag |= value.is_a?(Array) && value.size > 1
          end
        end
      end
      # return flag
      return flag
    end
    
    # check intersection of movement
    def intersected?(from, to)
      return false
    end
    
    # combination : create all combination
    def combination(arrA,arrB)
      if arrA.nil?
        return arrB
      elsif arrB.nil?
        return arrA
      else
        # create new array for combination
        comb = Array.new
        # traverse all combination of A and B
        arrA.each do |a|
          arrB.each do |b|
            comb << [a,b]
          end
        end
        # return combination
        return comb
      end
    end
    
    private :decomposable?, :combination, :intersected?
    
  end
  # class end: AGAnimation
end
# module end: AnimationGeneratore