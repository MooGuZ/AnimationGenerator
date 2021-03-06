# this file defines a class to generate animations according to
# animation configuration.
#
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015

# load system lib
require "fileutils"
# load sketchup lib
require "sketchup"
# load plug-in lib
require "tools"
require "csvtable"
require "trajcalc"
# load settings
require "settings"

module AnimationGenerator
  # class start: AnimGen
  class AnimGen
    # attributes
    attr :ifrm, :anim
    
    # animation generationg
    def initialize(aconf,infotable)
      # get active view's handle
      view = Sketchup.active_model.active_view
      # decompose animation configuration, if necessary
      aconf.each do |anim|
        @ifrm = 0           # reset frame counter
        @anim = anim        # current animation configuration
        FileUtils.mkdir_p(anim.path)   # create output folder
        nil while nextFrame(view)      # create animation
        # find or create record of current animation
        record = infotable.row {|r| r["code"] == anim.code}
        # fill animation information
        ANIMINFO["header"].each do |key|
          if anim.respond_to?(key)
            record[key] = anim.send(key)
          elsif anim.params.has_key?(key)
            record[key] = anim.params[key]
          end
        end
        # add time stamp
        record["time"] = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      end
    end
    
    # nextFrame: generate next frame of animation
    def nextFrame(view)
      # calculate camera position of current frame
      # eye, target, up = method(@anim.trajectory.to_sym).call(
      #   @anim.eye, @anim.target, @anim.up, @anim.params, @ifrm)
      if @ifrm != 0
        # calculate trajectory
        eye, target, up = trajcalc(@anim, @ifrm)
        # check intersection
        return false if intersected?(view.model, view.camera.eye, eye)
        # set new position of camera
        view.camera.set(eye, target, up)
      else
        # initialize camera
        view.camera.set(@anim.eye, @anim.target, @anim.up)
      end
      # write image
      view.write_image(
        File.join(@anim.path, "%03d.jpg" % @ifrm),
        IMRESX, IMRESY, ANTIALIAS, IMQUALITY)
      # update frame counter
      @ifrm += 1
      # if reach maximum frame quantity, stop
      return @ifrm < MAXFRAME 
    end
    
    private :nextFrame

  end
  # class end: AnimGen
end