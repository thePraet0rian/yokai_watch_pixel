class_name Battle extends CanvasLayer


const BATTLE_YOKAI_SCENE: PackedScene = preload("res://scn/battle/battle_yokai.tscn")


enum GAME_STATES {
	SELECTING = 1, 
	ACTION = 2, 
	WIN = 3,
}

enum SUB_GAME_STATES {
	PURIFY = 0, 
	SOULIMATE = 1, 
	TARGET = 2, 
	ITEM = 3, 
	NONE = 4,
}

enum {
	LEFT = 0, 
	RIGHT = 1,
}


@onready var AnimPlayer: AnimationPlayer = $anim_player

@onready var Purify: Node2D = $ui/sub_ui/purify
@onready var Soulimate: Node2D = $ui/sub_ui/soulimate
@onready var SoulimateButton: Sprite2D = $buttons/soulimate
@onready var Target: Node2D = $ui/sub_ui/target
@onready var Items: Node2D = $ui/sub_ui/items

@onready var ButtonA: Node2D = $buttons
@onready var Buttons: Array[Sprite2D] = [
	$buttons/purify,
	$buttons/soulimate,
	$buttons/target,
	$buttons/item,
]

@onready var Players: Node2D = $yokai/players
@onready var Enemies: Node2D = $yokai/enemies

@onready var WinScreen: Node2D = $win_screen
@onready var WinScreenAnimPlayer: AnimationPlayer = $win_screen/anim_player


var current_game_state: GAME_STATES = GAME_STATES.SELECTING
var current_sub_game_state: SUB_GAME_STATES = SUB_GAME_STATES.TARGET

var player_yokai_arr: Array[Yokai]
var enemy_yokai_arr: Array[Yokai]

var player_team_inst: Array[BattleYokai]
var enemy_team_inst: Array[BattleYokai]

var buttons_index: int = 0

var input_direction: Vector2 = Vector2.ZERO
var target_vec: Vector2 = Vector2.ZERO
var is_targeting : bool = false
var targeting_int: int = 0

var direction_move: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT]
var is_moving: bool = false

var can_soulimate: bool = true
var can_item: bool = true
var can_purfy: bool = true
var can_target: bool = true

var selected_yokai: int


# START # -----------------------------------------------------------------------------------------


func _ready() -> void:	
	
	global.on_yokai_action.connect(_on_yokai_action)
	
	_setup_players()
	_setup_enemys()
	
	_start()
	

func _setup_players() -> void:
	
	for i in range(3):
		
		var BattleYokaiInst: BattleYokai = BATTLE_YOKAI_SCENE.instantiate()
		player_team_inst.append(BattleYokaiInst)
		
		BattleYokaiInst.position = Vector2(48, 91) + Vector2(72, 0) * i
		BattleYokaiInst.YokaiInst = player_yokai_arr[i]
		BattleYokaiInst.update("player")
		Players.add_child(player_team_inst[i])


func _setup_enemys() -> void:
	
	for i in range(3):
		
		var BattleYokaiInst: Sprite2D = BATTLE_YOKAI_SCENE.instantiate()
		enemy_team_inst.append(BattleYokaiInst)

		BattleYokaiInst.position = Vector2(48, 40) + Vector2(72, 0) * i
		BattleYokaiInst.YokaiInst = enemy_yokai_arr[i]
		BattleYokaiInst.update("enemy")
		Enemies.add_child(enemy_team_inst[i])


func _start() -> void:
	
	AnimPlayer.play("start")


# INPUT # -----------------------------------------------------------------------------------------


func _input(event: InputEvent) -> void:
	
	match current_game_state:
		GAME_STATES.SELECTING:
			_selecting_input(event)
		GAME_STATES.ACTION:
			_action_input(event)
		GAME_STATES.WIN:
			_win_input(event)
	
	_update_ui()


func _selecting_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("move_left"):
		if buttons_index != 0:
			buttons_index -= 1
		else:
			buttons_index = 3
	elif event.is_action_pressed("move_right"):
		if buttons_index != 3:
			buttons_index += 1
		else:
			buttons_index = 0

	for i in range(len(Buttons)):
		if i == buttons_index:
			Buttons[i].frame = 1
		else:
			Buttons[i].frame = 0
	
	match buttons_index:
		1:
			if _can_soulimate(): 
				Buttons[1].frame = 1
			else:
				print("yes")
				Buttons[1].frame = 3

	if event.is_action_pressed("space"):
		_change_sub_game_state(buttons_index)


func _change_sub_game_state(sub_buttons_index: int) -> void:
	
	_disable_yokai()
	
	match sub_buttons_index:
		SUB_GAME_STATES.PURIFY:
			for i in range(len(player_team_inst)):
				if player_team_inst[i].dirty:
					Purify.visible = true
					current_game_state = GAME_STATES.ACTION
			
		SUB_GAME_STATES.SOULIMATE:
			for i in range(len(player_team_inst)):
				if player_team_inst[i].YokaiInst.yokai_soul >= 1.0:
					Soulimate.visible = true
					current_sub_game_state = SUB_GAME_STATES.SOULIMATE
					current_game_state = GAME_STATES.ACTION
			
		SUB_GAME_STATES.TARGET:
			Target.process_mode = Node.PROCESS_MODE_ALWAYS
			process_mode = Node.PROCESS_MODE_ALWAYS
			Target.visible = true
			current_sub_game_state = SUB_GAME_STATES.TARGET
			current_game_state = GAME_STATES.ACTION
			
		SUB_GAME_STATES.ITEM:
			_hide_ui()
			Items.visible = true
			Items.process_mode = Node.PROCESS_MODE_INHERIT
			current_sub_game_state = SUB_GAME_STATES.ITEM
			current_game_state = GAME_STATES.ACTION


func _update_ui() -> void:
	
	#SoulimateButton.frame = 2
	#for i in range(len(player_team_inst)):
		#if player_team_inst[i].YokaiInst.yokai_soul >= 1.0:
			#Soulimate.frame = 0
	pass


func _can_soulimate() -> bool:
	
	for i in range(len(player_team_inst)):
		if player_team_inst[i].YokaiInst.yokai_soul >= 1.0:
			print("soulimate")
			return true
	return false
			


func _action_input(event: InputEvent) -> void:
	
	match current_sub_game_state:
		SUB_GAME_STATES.PURIFY:
			_purify_input(event)
		SUB_GAME_STATES.SOULIMATE:
			_soulimate_input(event)
		SUB_GAME_STATES.TARGET:
			_target_input(event)
		SUB_GAME_STATES.ITEM:
			_item_input(event)


func _purify_input(event: InputEvent) ->  void:

	if event.is_action_pressed("shift"):
		current_game_state = GAME_STATES.SELECTING
		Purify.visible = false
		_enable_yokai()
		_show_ui()


func _soulimate_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("shift"):
		current_game_state = GAME_STATES.SELECTING
		Soulimate.visible = false
		_enable_yokai()


func _target_input(_event: InputEvent) -> void:

	#if event.is_action_pressed("shift"):
		#_enable_yokai()		
		#current_game_state = GAME_STATES.SELECTING
		#target.visible = false
	
	pass
		
		
func _item_input(event: InputEvent) -> void:

	if event.is_action_pressed("shift"):
		current_game_state = GAME_STATES.SELECTING
		Items.visible = false
		_enable_yokai()
		_show_ui()
		Items.process_mode = Node.PROCESS_MODE_DISABLED


# MOVE # ------------------------------------------------------------------------------------------


func player_input() -> void:

	input_direction.x = Input.get_axis("move_wheel_left", "move_wheel_right")

	if input_direction != Vector2.ZERO:
		is_moving = true
		if input_direction == Vector2.LEFT:
			move_yokai(LEFT)
		elif input_direction == Vector2.RIGHT:
			move_yokai(RIGHT)
	else:
		is_moving = false


func move_yokai(direction) -> void:

	if direction == LEFT:
		move_left()
		player_team_inst[2].disable_tick()
	elif direction == RIGHT:
		move_right()
		player_team_inst[0].disable_tick()

	for i in range(4):
		player_team_inst[i].move_direction(direction_move[direction])

	if direction == LEFT:
		remove_yokai(0)
	elif direction == RIGHT:
		remove_yokai(3)


func inst_yokai() -> Node2D:

	var player_yokai_inst: BattleYokai = BATTLE_YOKAI_SCENE.instantiate()
	Players.add_child(player_yokai_inst)

	return player_yokai_inst


func move_left() -> void:

	var player_yokai_inst: BattleYokai = inst_yokai()
	player_yokai_inst.position = Vector2(264, 91)

	player_team_inst.append(player_yokai_inst)

	player_yokai_arr.append(player_yokai_arr[0])
	player_yokai_arr.remove_at(0)

	player_yokai_inst.YokaiInst = player_yokai_arr[2]
	player_yokai_inst.update("player")


func move_right() -> void:

	var player_yokai_inst: Node2D = inst_yokai()
	player_yokai_inst.position = Vector2(-24, 91)
	
	player_team_inst.insert(0, player_yokai_inst)

	player_yokai_arr.insert(0, player_yokai_arr[5])
	player_yokai_arr.remove_at(6)

	player_yokai_inst.YokaiInst = player_yokai_arr[0]
	player_yokai_inst.update("player")


func remove_yokai(yokai: int) -> void:

	player_team_inst[yokai].remove()
	player_team_inst.remove_at(yokai)


func _physics_process(_delta: float) -> void:

	if player_team_inst[2].progress == 0.0:
		player_input()


# ACTION # ----------------------------------------------------------------------------------------


func _on_yokai_action(team: int, yokai: int, action: String) -> void:

	match action:
		"attack":
			attack(team, yokai)


func attack(team: int, _yokai: int) -> void:

	match team:
		0:
			var random_int: int = pick_alive()
			enemy_team_inst[random_int].health_update(calculate_damage(0, 0, 0))

			update_battle()
		1:
			pass


func pick_alive() -> int:

	if is_targeting:
		if enemy_team_inst[targeting_int].YokaiInst.yokai_hp >= 0:
			return targeting_int
	
	randomize()
	var random_int: int = randi_range(0, 2)

	if enemy_team_inst[0].YokaiInst.yokai_hp <= 0:
		if enemy_team_inst[1].YokaiInst.yokai_hp <= 0:
			if enemy_team_inst[2].YokaiInst.yokai_hp <= 0:
				return -1

	if enemy_team_inst[random_int].YokaiInst.yokai_hp <= 0:
		return pick_alive()

	return random_int


func calculate_damage(_yokai_str: int, _yokai_def: int, _power: int) -> int:

	return 100
	#var crit: float = 1.0
	#var guard: float = 1.0
	#return ((yokai_str / 2 - yokai_def / 4) + (power / 2)) * crit * guard


func update_battle() -> void:
	
	if pick_alive() == -1:
		await get_tree().create_timer(1).timeout
		AnimPlayer.play_backwards("start")
		await AnimPlayer.animation_finished
		
		WinScreen.visible = true
		_disable_yokai()
		current_game_state = GAME_STATES.WIN


# MISC # ------------------------------------------------------------------------------------------


func _disable_yokai() -> void:
	
	for i in range(len(player_team_inst)):
		player_team_inst[i].disable_tick()
	
	for i in range(len(enemy_team_inst)):
		player_team_inst[i].disable_tick()


func _enable_yokai() -> void:
	
	for i in range(len(player_team_inst)):
		player_team_inst[i].enable_tick()
	
	for i in range(len(enemy_team_inst)):
		enemy_team_inst[i].enable_tick()


# END # -------------------------------------------------------------------------------------------


func _win_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("space"):
		print("yes")
		WinScreenAnimPlayer.play("fade")


func _end() -> void:
	
	get_parent().process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().physics_frame
	global.on_battle_ended.emit()
	queue_free()


func _hide_ui() -> void:
	
	var tween: Tween = create_tween()
	tween.tween_property(ButtonA, "position", Vector2(0, 14), .15)


func _show_ui() -> void:
	
	var tween: Tween = create_tween()
	tween.tween_property(ButtonA, "position", Vector2(0, 0), 0.15)


# -------------------------------------------------------------------------------------------------
