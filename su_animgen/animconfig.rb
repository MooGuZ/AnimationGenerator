require "sketchup"
require "rexml/document"

require "su_animgen/tools"
require "su_animgen/settings"

module AnimationGenerator
	# class start: AnimConfig
  class AnimConfig
    # attributions
    attr :trajectory, :eye, :target, :up
    attr_accessor :params, :outfd
    
    # constructor: from xml node
    def initialize(node)
      # get trajectory type
      @trajectory = node.attributes["trajectory"].downcase
      # check availability of trajectory type
      unless TRAJTYPE.include?(@trajectory)
        raise ArgumentError, 'Unknown trajectory type!' 
      end
      # get element list
      elist = node.elements
      # load information of start position
      @eye    = elist["eye"].text.to_a
      @target = elist["target"].text.to_a
      @up     = elist["up"].text.to_a
      # load trajectory specific parameters
      @params = Hash.new
      TRAJPARAM[@trajectory].each do |key|
        @params[key] = elist[key].text.include?(',') ?
                       elist[key].text.to_a :
                       elist[key].text.to_f
      end
      # initialize other fields
      @outfd = nil
    end
    
    # code: return the code of current object
    def code
      # create an Array to collect all fields
      fields = [@trajectory, @eye, @target, @up, @params].map {|f| f.to_s}
      # create code by trajectory and azcode of fields
      return "#{@trajectory.upcase}-#{azcode(fields)}"
    end
    
    # path: return the output folder path
    def path() File.join(@outfd,code) end
      
    # decompose multiple animation configuration
    def each
      # create Hash table to pack up settings
      pack = Hash.new
      @params.each do |key,value|
        pack[key] = packed?(key,value) ? value : [value]
      end
      # create full permutation of each setting
      confs = permute(pack)
      # create clone of current animconfig
      anim = self.clone
      # apply block attach to each to each config
      confs.each do |conf|
        anim.params = conf
        yield anim
      end
    end
    
  end
  # class end: AnimConfig
end
# module end: AnimationGeneratore