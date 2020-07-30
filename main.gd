extends Node2D
#lazy example for local multiplayer input manager
#uses the input map... the only thing is that joypad have to be mapped as All Devices
#check game settings

var player_scene=preload("res://entities/player.tscn")

#utility just to assign color, to differentiate players i guess
export(PoolColorArray) var PlayerColors

var INPUT=null
var current_players={}
var MAX_PLAYERS=4
var player_labels=[]

func _ready():
	#create input manager instance
	INPUT=GameInput.new()
	#setup max players
	INPUT.MAX_LOCAL_PLAYERS=MAX_PLAYERS
	#add input manager
	add_child(INPUT)
	
	#react to joypad connections
	INPUT.connect("JOYSTICK_CONNECTION",self,"joy_connection")
	
	#initialize some labels and stuff
	for i in range(0,MAX_PLAYERS):
		var lbl=Label.new()
		if i>0:
			lbl.set_text(str("Player ",i+1,"=NO INPUT"))
		else:#keyboard guy
			lbl.set_text(str("Player ",i+1,"=ACTIVE"))
		add_child(lbl)
		lbl.rect_position=Vector2(10,25*(i+1))
		player_labels.append(lbl)
	
	#initialize labels text
	print(Input.get_connected_joypads())
	for joy in Input.get_connected_joypads():
		player_labels[joy+1].set_text(str("Player ",joy+2,"=PRESS START TO JOIN"))

	#respond to all joystics for join functionality, youn  can map many listeners to each device
	INPUT.connect_player(0,self)
	
	#########################################
	# In Godot Keyborad+Mouse are device 0, also the first Joystic is Device 0 
	# the input manager provides a way to split device 0 between keyborad+mouse and joystic separedly
	# joy_0 is the alias if using this mode, can be turner off in GameInputManager parameters
	#########################################
	
	INPUT.connect_player("joy_0",self)
	
	#blind connect, it they are present use them nothing happens if not
	INPUT.connect_player(1,self)
	INPUT.connect_player(2,self)
	
	#add player 1 0=default keyborad + mouse
	add_player(0)

#react to joypad connection/disconnections
func joy_connection(true_device,device,connected,joy_name):
	$msg.set_text(str(true_device," ",joy_name," connected=",connected))
	if connected:
		if current_players.has(true_device):
			player_labels[device+1].set_text(str("Player ",device+2,"=ACTIVE"))
		else:
			player_labels[device+1].set_text(str("Player ",device+2,"=PRESS START TO JOIN"))
	else:
		player_labels[device+1].set_text(str("Player ",device+2,"=DISCONNECTED"))

#add a player to the "GAME" i mean demo
func add_player(device):
	if current_players.size()<MAX_PLAYERS:
		var player_obj=player_scene.instance()
		add_child(player_obj)
		
		player_obj.set_position(Vector2(rand_range(100, 500),rand_range(100, 500)))
		player_obj.set_player_color(PlayerColors[current_players.size()])
		
		var res=INPUT.connect_player(device,player_obj)
		
		if res!=OK:
			print("ERROR connecting player ",current_players.size()+1)
		
		current_players[device]=player_obj
				
		player_labels[current_players.size()-1].set_text(str("Player ",current_players.size(),"=ACTIVE"))
	
	else:
		print("NO MoAr PlAyErs")

#listen for general joypad connection
func game_input(event): #react to joypad events
	if event.get_meta("is_joypad_input")==true && event.is_action_type():#joystick connection
		if INPUT.get_num_players(event.get_meta("true_device"))==1 && event.is_action("game_join") && event.is_pressed():
			add_player(event.get_meta("true_device"))
