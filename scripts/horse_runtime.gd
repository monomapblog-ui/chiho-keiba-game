## レース中の1頭分の可変状態(位置・速度・スタミナ等)とステップ更新ロジック。
## ノードツリーに依存しない純粋なロジックなので、エディタなしでもテストできる。
class_name HorseRuntime
extends RefCounted

var stats: HorseStats

var position_m: float = 0.0
var speed_mps: float = 0.0
var stamina_cur: float = 0.0
var stamina_max: float = 0.0
var lane_cur: float = 2.0

var finished: bool = false
var finish_time: float = -1.0
var rank: int = -1

func _init(p_stats: HorseStats) -> void:
	stats = p_stats
	stamina_max = lerp(60.0, 100.0, stats.stamina / 100.0)
	stamina_cur = stamina_max

func base_speed_mps() -> float:
	return lerp(15.0, 19.0, stats.speed / 100.0)

func accel_mps2() -> float:
	return lerp(3.0, 6.5, stats.power / 100.0)

func in_corner(track: TrackData) -> bool:
	for zone in track.corner_zones:
		if position_m >= zone.x and position_m < zone.y:
			return true
	return false

## 1ステップ進める。
## effort: 0.3(抑える)〜1.0(全力)の継続操作値
## lane_target: 目標レーン(1=内 〜 lane_count=外)
## speed_cap: 前の馬が詰まっている場合の速度上限(負値なら無効)
## race_progress: レース全体の進行度(0.0〜1.0、終盤ボーナス判定に使用)
func step(dt: float, effort: float, lane_target: float, track: TrackData, speed_cap: float, race_progress: float) -> void:
	if finished:
		return

	effort = clamp(effort, 0.3, 1.0)

	var target_speed := base_speed_mps() * (0.55 + 0.45 * effort)

	# 終盤の踏ん張り(ガッツ)ボーナス。スタミナが残っている時だけ効く
	if race_progress >= 0.85 and stamina_cur > 5.0:
		target_speed *= 1.0 + (stats.guts / 100.0) * 0.08

	# スタミナ切れ(バテ)
	if stamina_cur <= 0.0:
		target_speed *= 0.6

	if speed_cap >= 0.0:
		target_speed = min(target_speed, speed_cap)

	var accel := accel_mps2()
	var diff := target_speed - speed_mps
	speed_mps += clamp(diff, -accel * dt, accel * dt)
	speed_mps = max(speed_mps, 0.0)

	# スタミナ消費。コーナーで外(3,4レーン)を回ると消費が増える
	var corner_penalty := 1.0
	if in_corner(track) and lane_cur >= 3.0:
		corner_penalty = 1.4
	var drain := (effort * effort) * 1.8 * corner_penalty * dt
	stamina_cur = max(stamina_cur - drain, 0.0)
	if effort <= 0.4:
		stamina_cur = min(stamina_cur + 2.0 * dt, stamina_max)

	# レーン変更。1秒あたり最大1.5レーンまで
	var lane_speed := 1.5 * dt
	lane_cur += clamp(lane_target - lane_cur, -lane_speed, lane_speed)
	lane_cur = clamp(lane_cur, 1.0, float(track.lane_count))

	position_m += speed_mps * dt

	if position_m >= track.distance_m:
		position_m = track.distance_m
		finished = true
