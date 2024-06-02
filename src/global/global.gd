class_name Global extends Node



signal _on_battle_start()

signal _on_battle_end()

signal _on_room_transition()

signal _on_warp()

signal _on_save

signal _on_load()

signal _on_dialogue()

signal _on_dialogue_end

signal _on_menue_close

signal _on_yokai_action()


var current_time: int = 0
var current_money: int = 1240
var player_inventory: Array[Array] = [[],[],[],[],[]]


@onready var player_yokai: Array[Yokai] = [
	Yokai.new("Jibanyan", preload("res://res/yokai/jibanyan/jibanyan_two.png")), 
	Yokai.new("Zerberker", preload("res://res/yokai/zerberker/zerberker_back.png")), 
	Yokai.new("Dragon Lord", preload("res://res/yokai/dargon_lord/dargon_lord_back.png")), 
	Yokai.new("Cadin", preload("res://res/yokai/cadin/cadin.png")), 
	Yokai.new("Peckpocket", preload("res://res/yokai/peckpocket/peckpocket.png")),
	Yokai.new("Jibanyan", preload("res://res/yokai/jibanyan/jibanyan_back.png"))
]

const rooms: Array[PackedScene] = [
	preload("res://scn/rooms/room_01.tscn"),
	preload("res://scn/rooms/room_02.scn"),
]
