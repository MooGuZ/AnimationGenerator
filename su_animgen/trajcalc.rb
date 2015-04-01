require "sketchup"

module AnimationGenerator
  # class start: AnimGen
  class AnimGen
    private
    
    # trajectory : line
    def line(eye, target, up, params, ind)
      # regularize input parameters
      eye    = Geom::Point3d.new(eye)
      target = Geom::Point3d.new(target)
      ind = ind.to_f
      # get direction, velocity, and current time
      d = Geom::Vector3d.new(params["direction"]).normalize
      v = params["velocity"]
      t = ind / FRAMERATE
      # calculate current eye position
      eye = eye + d.transform(Geom::Transformation.scaling(v * t))
      # get up vector of current camera
      cur_up  = Sketchup.active_model.active_view.camera.up
      # calculate current up vector of camera
      up  = planeproj(up, target-eye, cur_up) if (target-eye).length
      # return new positions
      return eye, target, up
    end
    
  end
  # class end: AnimGen
end