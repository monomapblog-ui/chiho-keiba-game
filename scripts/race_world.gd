## レース全体(複数頭)の進行管理。前の馬が詰まっている場合の速度頭打ち(ブロッキング)も
## ここで解決してから各馬のstep()を呼ぶ。
class_name RaceWorld
extends RefCounted

const MIN_GAP_M := 1.2
const LANE_BLOCK_THRESHOLD := 0.8

var track: TrackData
var horses: Array[HorseRuntime] = []
var elapsed: float = 0.0
var finish_order: Array[int] = []

func _init(p_track: TrackData, roster: Array[HorseStats]) -> void:
	track = p_track
	for s in roster:
		horses.append(HorseRuntime.new(s))

func all_finished() -> bool:
	for h in horses:
		if not h.finished:
			return false
	return true

func race_progress() -> float:
	var total := 0.0
	for h in horses:
		total += h.position_m / track.distance_m
	return total / horses.size()

func step_all(dt: float, efforts: Array, lane_targets: Array) -> void:
	elapsed += dt
	var progress := race_progress()

	var caps: Array = []
	caps.resize(horses.size())
	for i in horses.size():
		caps[i] = -1.0

	# 位置が前な馬から順に並べ、同レーンで詰まっていれば後ろの馬の速度をキャップする
	var order := range(horses.size())
	order.sort_custom(func(a, b): return horses[a].position_m > horses[b].position_m)

	for rank_idx in order.size():
		var i: int = order[rank_idx]
		var h: HorseRuntime = horses[i]
		if h.finished:
			continue
		for rank_idx2 in range(0, rank_idx):
			var j: int = order[rank_idx2]
			var ahead: HorseRuntime = horses[j]
			if ahead.finished:
				continue
			var gap := ahead.position_m - h.position_m
			var lane_gap: float = absf(ahead.lane_cur - h.lane_cur)
			if gap >= 0.0 and gap < MIN_GAP_M and lane_gap < LANE_BLOCK_THRESHOLD:
				caps[i] = ahead.speed_mps

	for i in horses.size():
		horses[i].step(dt, efforts[i], lane_targets[i], track, caps[i], progress)

	for i in horses.size():
		var h: HorseRuntime = horses[i]
		if h.finished and h.finish_time < 0.0:
			h.finish_time = elapsed
			finish_order.append(i)
			h.rank = finish_order.size()
