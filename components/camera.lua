return component("camera", function(e, show, offset, orientation, thirdPerson)
	e.show = show -- do or don't draw camera entity
	e.offset = offset or vec3()
	e.orientation = orientation or quat()
	e.thirdPerson = thirdPerson -- (TODO: rename? Properly defined camera tracking types?) do or don't rotate offset along with camera entity and rotate with camera entity orientation (fixed offset would be on to make a (typical in terms of camera) platformer, or off to see from the eyes of a creature whose position component is elsewhere on its body)
end)
