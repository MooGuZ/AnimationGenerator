require "sketchup"

module AnimationGenerator
  # class start: AnimGen
  class AnimGen
    private
    
    # trajectory : line
    def line(eye, target, up, params, ind)
      # regularize input parameters
      eye = Geom::Point3d.new(eye)
      ind = ind.to_f
      # get direction, velocity, and current time
      d = Geom::Vector3d.new(params["direction"]).normalize
      v = params["velocity"]
      t = ind / FRAMERATE
      # calculate current eye position
      new_eye = eye + d.transform(Geom::Transformation.scaling(v * t))
      # return new positions
      return new_eye, target, up
    end
    
  end
  # class end: AnimGen
end