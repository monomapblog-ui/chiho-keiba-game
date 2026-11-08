## `godot4 --headless --script res://test/race_sim_test.gd` で実行する自動テスト。
## 画面なしでレースロジック一式(スタミナ消費・終盤ボーナス・ブロッキング)を
## 最後まで走らせ、異常値(NaN・完走しない馬など)がないかを確認する。
extends SceneTree

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var track := TrackData.new()
	track.track_name = "白鷺競馬場(テスト)"
	track.distance_m = 1400.0
	track.lane_count = 4
	track.corner_zones = [Vector2(300, 500), Vector2(950, 1150)]

	var roster: Array[HorseStats] = []
	roster.append(_make_horse("カゼノハヤテ", 72, 60, 68, 55, "NIGE"))
	roster.append(_make_horse("ゴールドブリーズ", 65, 70, 60, 65, "SENKO"))
	roster.append(_make_horse("クロシオキング", 60, 75, 58, 72, "SASHI"))
	roster.append(_make_horse("トサノツバサ", 58, 68, 70, 60, "OIKOMI"))

	var world := RaceWorld.new(track, roster)

	var dt := 1.0 / 30.0
	var t := 0.0
	var max_t := 180.0
	var ok := true

	while not world.all_finished() and t < max_t:
		var progress := world.race_progress()
		var efforts: Array = []
		var lanes: Array = []
		for h in world.horses:
			var d := AIController.decide(h, track, progress, rng)
			efforts.append(d["effort"])
			lanes.append(d["lane"])
		world.step_all(dt, efforts, lanes)
		t += dt

		for h in world.horses:
			if is_nan(h.position_m) or is_nan(h.speed_mps):
				ok = false
				push_error("NaNを検出: %s" % h.stats.display_name)

	print("=== レースシミュレーション結果(白鷺競馬場 1400m) ===")
	if t >= max_t:
		print("警告: 制限時間(%.0f秒)内に全馬が完走しませんでした" % max_t)
		ok = false

	for i in world.finish_order.size():
		var idx: int = world.finish_order[i]
		var h: HorseRuntime = world.horses[idx]
		print("%d着 %s  完走タイム:%.2f秒  最終スタミナ:%.1f/%.1f" % [
			i + 1, h.stats.display_name, h.finish_time, h.stamina_cur, h.stamina_max
		])

	if world.finish_order.size() != world.horses.size():
		ok = false
		print("エラー: 完走していない馬がいます")

	print("")
	if ok:
		print("OK: シミュレーションは正常に完了しました")
	else:
		print("NG: 異常を検出しました")

	quit()

func _make_horse(name: String, spd: int, sta: int, pw: int, gut: int, style: String) -> HorseStats:
	var s := HorseStats.new()
	s.display_name = name
	s.speed = spd
	s.stamina = sta
	s.power = pw
	s.guts = gut
	s.running_style = style
	return s
