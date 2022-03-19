# This file define a class of camera configuration, which essentially contains
# camera settings in sketchup and a list of animation configuration.
#
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load system lib
require "rexml/document"
# load sketchup lib
require "sketchup"
# load plug-in lib
require "csvtable"
require "animconfig"
require "animgen"
# load settings
require "settings"

module AnimationGenerator
  # class start: CamConfig
  class CamConfig
    # attributions
    attr :aspratio, :fov, :imwidth, :animlist, :ropts
    
    # constructor : from xml node
    def initialize(node)
      # get camera settings
      @aspratio = node.attributes["aspratio"] ?
                  node.attributes["aspratio"].to_f :
                  DEFAULT["camera"]["aspratio"]
      @fov      = node.attributes["fov"] ?
                  node.attributes["fov"].to_f :
                  DEFAULT["camera"]["fov"]
      @imwidth  = node.attributes["imwidth"] ?
                  node.attributes["imwidth"].to_f :
                  DEFAULT["camera"]["imwidth"]
      # initialize render options
      @ropts = Hash.new
      # initialize animation list
      @animlist = Array.new 
      # load render options and animations if not empty
      unless node.elements.empty?
        # get available render option items
        suropts = Sketchup.active_model.rendering_options.keys
        # load render options
        node.elements.each("render") do |render|
          render.attributes.each do |option, value|
            # check whether or not current option is supported
            if suropts.include?(option)
              if value.number?
                @ropts[option] = value.to_f
              elsif value.downcase == "true"
                @ropts[option] = true
              elsif value.downcase == "false"
                @ropts[option] = false
              else
                @ropts[option] = value
              end
            else
              puts "option [#{option.name}] is not supported"
            end
          end
        end
        # load animations
        node.elements.each("animation") do |e|
          @animlist << AnimConfig.new(e)
        end
      end
    end
    
    # make animation
    def animate(outfd)
      # get active view's handle
      view = Sketchup.active_model.active_view
      # save current camera setting
      # camrecord = view.camera.clone    
      # set camera parameters in active view
      view.camera.perspective  = true
      view.camera.aspect_ratio = @aspratio
      view.camera.fov          = @fov
      view.camera.image_width  = @imwidth
      # get render option's handle
      suropts = Sketchup.active_model.rendering_options
      # activate default render options
      DEFAULT["render"].each_pair { |key, value| suropts[key] = value }
      # activate user's render options
      @ropts.each_pair { |key, value| suropts[key] = value }
      # create anim-info.csv file
      infotable = CSVTable.read(File.join(outfd,ANIMINFO["filename"]))
      infotable = CSVTable.new(ANIMINFO["header"]) unless infotable
      # make animation one by one
      @animlist.each do |aconf|
        # pass output folder info to animconfig
        aconf.outfd = outfd
        # generate animation by AnimGen
        AnimGen.new(aconf,infotable)
      end
      # write anim-info.csv file
      infotable.write(File.join(outfd,ANIMINFO["filename"]))
      # reset camera according to record
      # view.camera = camrecord
    end
  end
  # class end: CamConfig
end
# module end: AnimationGenerator