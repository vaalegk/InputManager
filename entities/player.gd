extends KinematicBody2D

#very simple and lazzy player controller just for the demo, 
#dont pay much attention to it just the game_input function

export(float) var speed=300
export(float) var twin_stick_mode=true
export(Color) var player_color=Color(0,1,1,1) setget set_player_color

var direction=Vector2(0,0)
var angle=0

#not needed for demo but here anyway
var states={
	"left":false,
	"right":false,
	"up":false,
	"down":false
}

func set_player_color(col:Color):
	player_color=col
	if !is_inside_tree():
		return
	$Sprite.modulate=col

func _ready():
	set_player_color(player_color)

func _process(_delta):
	direction=Vector2(0,0)
	if states["left"]==true:
		direction.x=-1
	if states["right"]==true:
		direction.x=1
	if states["up"]==true:
		direction.y=-1
	if states["down"]==true:
		direction.y=1

func _physics_process(delta):
	position+=direction*speed*delta
	if angle!=0 && twin_stick_mode:
		$gun_pivot.global_rotation=angle

#Function used from the GameInputManager to pass events, configurable there
func game_input(event):
	if event.is_action_type():
		if event.is_action("ui_left"):
			states["left"]=event.is_pressed()
		if event.is_action("ui_right"):
			states["right"]=event.is_pressed()
		if event.is_action("ui_up"):
			states["up"]=event.is_pressed()
		if event.is_action("ui_down"):
			states["down"]=event.is_pressed()
		
		if event.is_action("game_fire"):#PEW!
			$gun_pivot/laser_pointer/pew.visible=event.is_pressed()

	elif twin_stick_mode:
		if event.as_text()=="motion":
			match event.type:
				"left_stick":
					states["left"]=event.speed.x<0
					states["right"]=event.speed.x>0
					states["up"]=event.speed.y<0
					states["down"]=event.speed.y>0
				"right_stick":
					#allow joypad angle pointing
					angle=lerp_angle($gun_pivot.global_rotation,event.get_angle(),0.2)
				"mouse":
					#calculate from mouse motion
					angle=event.position.angle_to_point($gun_pivot.global_position)
					
