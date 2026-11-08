## プレイ可能な画面。ノードはすべてコードで組み立てる(手書き.tscnの事故を避けるため)。
## 見た目はまだ仮(色付き四角)。操作感の検証が目的のプロトタイプ。
extends Node2D

const TRACK_PIXELS_PER_METER := 0.6
const LANE_PIXELS := 28.0
const TRACK_TOP := 80.0

var world: RaceWorld
var rng := RandomNumberGenerator.new()

var player_effort := 0.65
var player_lane := 2.0

var horse_nodes: Array = []
var hud_labels: Dictionary = {}
var race_finished := false

func _ready() -> void:
	rng.randomize()
	_build_world()
	_build_visuals()
	_build_hud()

func _build_world() -> void:
	var track := TrackPresets.kochi()

	var roster: Array[HorseStats] = []
	roster.append(_make_horse("カゼノハヤテ", "小峰 隼人", 72, 60, 68, 55, "NIGE"))
	roster.append(_make_horse("ゴールドブリーズ", "芦田 蓮", 65, 70, 60, 65, "SENKO"))
	roster.append(_make_horse("クロシオキング", "最上 龍馬", 60, 75, 58, 72, "SASHI"))
	roster.append(_make_horse("トサノツバサ", "日向 景虎", 58, 68, 70, 60, "OIKOMI"))

	world = RaceWorld.new(track, roster)

func _make_horse(p_name: String, jockey: String, spd: int, sta: int, pw: int, gut: int, style: String) -> HorseStats:
	var s := HorseStats.new()
	s.display_name = p_name
	s.jockey_name = jockey
	s.speed = spd
	s.stamina = sta
	s.power = pw
	s.guts = gut
	s.running_style = style
	return s

func _build_visuals() -> void:
	for i in world.horses.size():
		var box := ColorRect.new()
		box.size = Vector2(20, 14)
		box.color = Color(0.9, 0.2, 0.2) if i == 0 else Color(0.3, 0.3, 0.8)
		add_child(box)
		horse_nodes.append(box)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var y := 10.0
	for i in world.horses.size():
		var lbl := Label.new()
		lbl.position = Vector2(10, y)
		layer.add_child(lbl)
		hud_labels[i] = lbl
		y += 20.0

	var info := Label.new()
	info.position = Vector2(10, y + 10.0)
	info.text = "↑/W: 押す(効果アップ/スタミナ消費大)  ↓/S: 抑える(スタミナ回復)  ←→ or A/D: レーン変更"
	layer.add_child(info)

	var result := Label.new()
	result.position = Vector2(450, 10)
	layer.add_child(result)
	hud_labels["result"] = result

func _process(delta: float) -> void:
	if world == null:
		return
	if race_finished:
		return

	_handle_input(delta)

	var efforts: Array = []
	var lanes: Array = []
	var progress := world.race_progress()
	for i in world.horses.size():
		if i == 0:
			efforts.append(player_effort)
			lanes.append(player_lane)
		else:
			var d := AIController.decide(world.horses[i], world.track, progress, rng)
			efforts.append(d["effort"])
			lanes.append(d["lane"])

	world.step_all(delta, efforts, lanes)
	_update_visuals()

	if world.all_finished() and not race_finished:
		race_finished = true
		_show_results()

func _handle_input(delta: float) -> void:
	var push := Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W)
	var hold_back := Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S)
	var go_left := Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A)
	var go_right := Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D)

	if push:
		player_effort = min(player_effort + delta * 1.5, 1.0)
	elif hold_back:
		player_effort = max(player_effort - delta * 1.5, 0.3)
	else:
		player_effort = lerp(player_effort, 0.65, delta)

	if go_left:
		player_lane = max(player_lane - delta * 2.0, 1.0)
	elif go_right:
		player_lane = min(player_lane + delta * 2.0, float(world.track.lane_count))

func _update_visuals() -> void:
	for i in world.horses.size():
		var h: HorseRuntime = world.horses[i]
		var node: ColorRect = horse_nodes[i]
		node.position = Vector2(h.position_m * TRACK_PIXELS_PER_METER, TRACK_TOP + h.lane_cur * LANE_PIXELS)

		var lbl: Label = hud_labels[i]
		var tag := " (あなた)" if i == 0 else ""
		lbl.text = "%s%s  速度:%.1fm/s  スタミナ:%.0f/%.0f  距離:%.0f/%.0fm" % [
			h.stats.display_name, tag, h.speed_mps,
			h.stamina_cur, h.stamina_max, h.position_m, world.track.distance_m
		]

func _show_results() -> void:
	var text := "【結果】\n"
	for i in world.finish_order.size():
		var idx: int = world.finish_order[i]
		var h: HorseRuntime = world.horses[idx]
		var tag := " (あなた)" if idx == 0 else ""
		text += "%d着: %s%s (%.2f秒)\n" % [i + 1, h.stats.display_name, tag, h.finish_time]
	var result_lbl: Label = hud_labels["result"]
	result_lbl.text = text
