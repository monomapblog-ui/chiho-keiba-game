## CPU(対戦相手)の馬の操作を脚質に応じて自動で決める、簡易な意思決定ロジック。
class_name AIController
extends RefCounted

static func decide(h: HorseRuntime, track: TrackData, progress: float, rng: RandomNumberGenerator) -> Dictionary:
	var style: String = h.stats.running_style
	var effort := 0.65
	var base_lane := 2.0

	match style:
		"NIGE":
			effort = 0.85 if progress < 0.6 else (0.55 if progress < 0.85 else 0.9)
			base_lane = 1.3  # 逃げ: 内側のインコースを突く
		"SENKO":
			effort = 0.7 if progress < 0.75 else 0.9
			base_lane = 1.8  # 先行: ややインコース寄り
		"SASHI":
			effort = 0.55 if progress < 0.7 else 0.95
			base_lane = 2.6  # 差し: やや外側から勝負
		"OIKOMI":
			effort = 0.45 if progress < 0.8 else 1.0
			base_lane = 3.2  # 追込: 外側から大外一気を狙う
		_:
			effort = 0.7

	effort += rng.randf_range(-0.05, 0.05)
	effort = clamp(effort, 0.3, 1.0)

	# 終盤、インコースの消耗ペナルティが大きいコースでは外に膨らむ判断をする
	if track.inner_lane_penalty > 0.0 and progress > 0.3:
		base_lane = max(base_lane, 1.8)

	var lane_target: float = clamp(base_lane + rng.randf_range(-0.25, 0.25), 1.0, float(track.lane_count))

	return {"effort": effort, "lane": lane_target}
