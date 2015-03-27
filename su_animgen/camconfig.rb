require "sketchup"
require 'fileutils'
require "rexml/document"

require "su_animgen/csvtable"

require "su_animgen/settings"
require "su_animgen/aganimation"

module AnimationGenerator
  # class start: CamConfig
  class CamConfig
    # attributions
    attr :aspratio, :fov, :imwidth, :animlist
    
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
      # initialize animation list
      @animlist = Array.new 
      # load animations if not empty
      unless node.elements.empty?
        node.elements.each("animation") do |e|
          @animlist << AGAnimation.new(e)
        end
      end
    end
    
    # make animation
    def animate(outfd)
      # get active view's handle
      view = Sketchup.active_model.active_view
      
      # save current camera setting
      camrecord = view.camera.clone
      
      # set camera parameters in active view
      view.camera.perspective  = true
      view.camera.aspect_ratio = @aspratio
      view.camera.fov          = @fov
      view.camera.image_width  = @imwidth
      
      # create anim-info.csv file
      infotable = CSVTable.read(File.join(outfd,ANIMINFO["filename"]))
      infotable = CSVTable.new(ANIMINFO["header"]) unless infotable
      # make animation one by one
      @animlist.each do |aconf|
        # decompose animation configuration if possible
        aconf.decompose do |anim|
          # ------- create animation -------
          # set frame count
          anim.ifrm = 0
          # set output folder
          anim.outfd = File.join(outfd, anim.code)
          # create animation folder
          FileUtils.mkdir_p(anim.outfd)
          # start animation
          # view.animation = anim
          # run animation
          nil while anim.nextFrame(view)
          # ------- save animation information -------
          # find or create record of current animation
          rcd = infotable.row {|r| r[:code] == anim.code}
          # fill animation information
          ANIMINFO["header"].each do |field|
            if anim.respond_to?(field)
              rcd[field] = anim.send(field)
            elsif anim.params.has_key?(field.to_s)
              rcd[field] = anim.params[field.to_s]
            end
          end
        end
      end
      # write anim-info.csv file
      infotable.write(File.join(outfd,ANIMINFO["filename"]))
      # reset camera according to record
      view.camera = camrecord
    end
  end
  # class end: CamConfig
end
# module end: AnimationGenerator