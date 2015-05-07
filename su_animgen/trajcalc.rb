# This file provide an interface to class AnimGen to calculate camera position
# of a specific animation configuration at a specific frame.
# 
# MooGu Z. <hzhu@case.edu>
# Apr 11, 2015 

# load sketchup lib
require "sketchup"
# load plug-in lib
require "animconfig"
# load settings
require "settings"

module AnimationGenerator
  # class start: AnimGen
  class AnimGen
    private
    
    # trajcalc : interface
    def trajcalc(aconf, ifrm)
      # regularize input parameters
      eye    = Geom::Point3d.new(aconf.eye)
      target = Geom::Point3d.new(aconf.target)
      up     = Geom::Vector3d.new(aconf.up)
      # call concrete trajectory calculation method
      method(aconf.trajectory.to_sym).call(eye, target, up, aconf.params, ifrm)
    end
    
    # trajectory : translate
    # - camera move linearly and keep it orientation
    def translate(eye, target, up, params, ind)
      # get direction, velocity, and current time
      d = Geom::Vector3d.new(params["direction"]).normalize
      v = params["velocity"]
      t = ind.to_f / FRAMERATE
      # calculate shifting direction in translation
      shift = d.transform(Geom::Transformation.scaling(v * t))
      # update eye and target position
      eye = eye + shift
      target = target + shift
      # return new status of camera
      return eye, target, up
    end
    
    # trajectory : shift
    # - camera move around the target in one direction as a circle
    def shift(eye, target, up, params, ind)
      # get direction, velocity, and current time
      d = Geom::Vector3d.new(params["direction"]).normalize
      v = params["velocity"] / 180.0 * Math::PI
      t = ind.to_f / FRAMERATE
      # calculate camera position by rotation
      norm = (target - eye).cross(d)
      if norm.length == 0
        raise ArgumentError, "dirction for shifting animation is unavailable"
      end
      eye = eye.transform(Geom::Transformation.rotation(target, norm.normalize, v * t))
      # calculate up direction with minimum rotation for viewer
      cur_up = Sketchup.active_model.active_view.camera.up
      up = planeproj(cur_up, target-eye) if (target-eye).length > ZEROTOLERANCE
      # return new status of camera
      return eye, target, up
    end
    
    # trajectory : approach
    # - camera move towards the target
    def approach(eye, target, up, params, ind)
      # get direction, velocity, and current time
      v = params["velocity"]
      t = ind.to_f / FRAMERATE
      # update camera position
      eye = eye + (target-eye).normalize.transform(Geom::Transformation.scaling(v * t))
      # keep camera's orientation
      up = Sketchup.active_model.active_view.camera.up
      # reture new status of camera
      return eye, target, up
    end
    
    # trajectory : rotation
    # - keep camera's position just rotate it
    def rotate(eye, target, up, params, ind)
      # get direction, velocity, and current time
      v = params["velocity"] / 180.0 * Math::PI
      t = ind.to_f / FRAMERATE
      # calculate new up direction of camera by rotation
      cur_up = Sketchup.active_model.active_view.camera.up
      up = cur_up.transform(Geom::Transformation.rotation(
            Geom::Point3d.new([0,0,0]), target-eye, v * t))
      # return new status of camera
      return eye, target, up
    end 
    
    # trajectory : line
    # - camera move linearly while keep pointing to target
    def line(eye, target, up, params, ind)
      # get direction, velocity, and current time
      d = Geom::Vector3d.new(params["direction"]).normalize
      v = params["velocity"]
      t = ind.to_f / FRAMERATE
      # calculate current eye position
      eye = eye + d.transform(Geom::Transformation.scaling(v * t))
      # get up vector of current camera
      cur_up  = Sketchup.active_model.active_view.camera.up
      # calculate current up vector of camera
      # - plan A : minimize rotating effects by project up vector 
      # -          of last frame to current plane
      up = planeproj(cur_up, target-eye) if (target-eye).length > ZEROTOLERANCE
      # - plan B : always keep up vector point to positive z-axis
      # up  = planeproj(up, target-eye, cur_up) if (target-eye).length > ZEROTOLERANCE
      # return new status of camera
      return eye, target, up
    end
  end
  # class end: AnimGen
end