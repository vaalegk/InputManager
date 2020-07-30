# 
# GameInputMotion manager
# 
# Input event proxy for motion events, compatible with Godot event  
# no need to use it directly, instance managed by GameInput Manager
#

extends Resource

class_name GameInputMotion

#Input device 
var device=0
#Motion angle
var angle=0

#Motion speed
var speed=Vector2(0,0)

#for mouse events
var position=Vector2(0,0)

#event type [left_stick,right_stick,mouse]
var type=""

#for joysticks 
var dead_zone=0

func _init(env:InputEvent,dz):
	device=env.device
	dead_zone=dz
	#is joystic motion?
	if env.is_class("InputEventJoypadMotion"):
		#get all motions
		if  [JOY_AXIS_0,JOY_AXIS_1].has(env.axis):
			type="left_stick"
		elif [JOY_AXIS_2,JOY_AXIS_3].has(env.axis):
			type="right_stick"
	#or Mouse motion	
	elif env.is_class("InputEventMouseMotion"):
		type="mouse"
		speed=env.speed

#update state of event
func update(evt):
	match type:
		"left_stick":
			speed=clamp_joy_values(
				Vector2(
					Input.get_joy_axis(device,JOY_AXIS_0),
					Input.get_joy_axis(device,JOY_AXIS_1)
				))
		"right_stick":
			speed=clamp_joy_values(
				Vector2(
					Input.get_joy_axis(device,JOY_AXIS_2),
					Input.get_joy_axis(device,JOY_AXIS_3)
				))
		"mouse":
			speed=evt.speed
			position=evt.position

#movement speed
func get_speed(invert=false):
	if invert:
		return speed*Vector2(-1,-1)
	return speed

#movement angle
func get_angle(invert=false):
	return get_speed(invert).angle()

#for compatibility with standard Godot normal event
func is_action(ac):
	return ac=="InputMotion"

#for compatibility with standard Godot normal event
func is_action_type():
	return false

#for compatibility with standard Godot normal event
func as_text():
	return "motion"

#helper function for joypad motions
func clamp_joy_values(values:Vector2):
	var res=Vector2(0,0)
	if values.x>0:
		res.x=clamp(values.x-dead_zone,0,1)
	if values.x<0:
		res.x=clamp(values.x+dead_zone,-1,0)
	if values.y>0:
		res.y=clamp(values.y-dead_zone,0,1)
	if values.y<0:
		res.y=clamp(values.y+dead_zone,-1,0)
	return res
