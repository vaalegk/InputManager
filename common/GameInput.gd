# 
# GameInput manager
# 
# Simple game input manager for local multiplayer
#
extends Node

class_name GameInput

#maximun local players
var MAX_LOCAL_PLAYERS=4

#signal for joystic connection, proxy for default Godot Input one
signal JOYSTICK_CONNECTION

#currentt device mappings, each device can have many listener or active targets
#addes using connect_player, depends on presence of node_input_function bellow
var device_map={}

#function to check to pass input events, and connectinng players/listeners, 
#could have implemented it with signals, but this decided on to go this way
var node_input_function="game_input"

#Current motion proxies, created at runtime when needed
var motions={}

#Input modes to pass events, GAME_INPUT_RAW, passes the events as is, 
#no motion proxy just device mapping separation
enum {GAME_INPUT_MANAGED,GAME_INPUT_RAW}

#Current input event modes
var mode=GAME_INPUT_MANAGED

#Joypad deadzone 
var dead_zone=0.3

#Split Device 0  keyboard + mouse & joypad_0 
#if true an alias joy_0 is created for joypad device 0
var split_device_zero=true

func _ready():
	pause_mode=Node.PAUSE_MODE_STOP
# warning-ignore:return_value_discarded
	Input.connect("joy_connection_changed",self,"joystic_change")

#Joystick connection/disconnection signal, adds more info and is aware of device alias for device 0
#if enabled
func joystic_change(dev,connected):
	var true_device=dev
	#allow for device 0 separation (keyboard+mouse and joypad 0)
	if dev==0 && split_device_zero:
		true_device=str("joy_",dev)
	
	emit_signal("JOYSTICK_CONNECTION",true_device,dev,connected,Input.get_joy_name(dev))

#Removes a mapping from the device input map
func disconnect_player(player):
	var player_key=str(player)
	if player.has_meta("game_input_device"):
		if device_map.has(player.get_meta("game_input_device")):
			if device_map[player.get_meta("game_input_device")].has(player_key):
				device_map[player.get_meta("game_input_device")].erase(player_key)

#Adds node to the target device map
func connect_player(device,player):
	if device_map.size()<=MAX_LOCAL_PLAYERS:
		#check if target node has receiver funcion
		if player.has_method(node_input_function):
			if !device_map.has(device):
				#if not initialized initialize device mapping
				device_map[device]={}
			device_map[device][str(player)]=player
			player.set_meta("game_input_device",device)
			#connect to signal to disconnect player if removed from tree
			if !player.is_connected("tree_exiting",self,"disconnect_player"):
				player.connect("tree_exiting",self,"disconnect_player",[player])
			return OK
		else:
			return ERR_CONNECTION_ERROR
	else:
		return ERR_BUSY

#Utility function to get number of nodes connected to a device
func get_num_players(device):	
	if device_map.has(device):
		return device_map[device].size()
	else:
		return 0

#Utility function to check if an event is a "Motion" event
#@TODO: Add joypad trigger maybe?
func check_valid_motions(event):
	if event.get_class().ends_with("Motion"):
		if event.is_class("InputEventMouseMotion"):
			return true
		elif [JOY_AXIS_0,JOY_AXIS_1,JOY_AXIS_2,JOY_AXIS_3].has(event.axis):
			return true
	return false

#Utility funcion to get friendly names for joypad axis
func get_axis(event):
	if event.is_class("InputEventJoypadMotion"):
		if  [JOY_AXIS_0,JOY_AXIS_1].has(event.axis):
			return "left_stick"
		elif [JOY_AXIS_2,JOY_AXIS_3].has(event.axis):
			return "right_stick"
	else:
		return ""

#Actually process input events
func _input(event):
	var true_device=event.device
	#allow for device 0 separation (keyboard+mouse and joypad 0)
	if event.device==0 && split_device_zero:
		if event.get_class().count("Joypad")>0:
			true_device=str("joy_",event.device)
	
	#if mapped, keep processing, if not do nothing	
	if device_map.has(true_device): 
		var targets=device_map[true_device]
		var true_event=event
		if mode!=GAME_INPUT_RAW:
			#check for motion events, Mouse, Left or Right Stick. 
			#TODO add Joypad trigger button motions configurable
			if check_valid_motions(event):
				var device_key=str(event.get_class().replace("InputEvent",get_axis(event)),event.device)
				if !motions.has(device_key):
					#create proxy event handler if not already created 
					var mev=GameInputMotion.new(event,dead_zone)
					motions[device_key]=mev
					get_tree().set_input_as_handled()
					
				motions[device_key].update(event)
				true_event=motions[device_key]
		
		#add usefull metadata to event 
		true_event.set_meta("is_joypad_input",event.get_class().count("Joypad")>0)
		true_event.set_meta("true_device",true_device)
		
		#call target functions on each mapped receiving node
		for target in targets:
			if is_instance_valid(targets[target]):
				targets[target].call(node_input_function,true_event)
			else: #remove mapped object if no longer valid
				device_map[true_device].erase(target)
