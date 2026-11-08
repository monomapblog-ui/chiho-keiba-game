## CPU(対戦相手)の馬の操作を脚質に応じて自動で決める、簡易な意思決定ロジック。
class_name AIController
extends RefCounted

static func decide(h: HorseRuntime, _track: TrackData, progress: float, rng: RandomNumberGenerator) -> Dictionary:
	var style: String = h.stats.running_style
	var effort := 0.65

	match style:
		"NIGE":
			effort = 0.85 if progress < 0.6 else (0.55 if progress < 0.85 else 0.9)
		"SENKO":
			effort = 0.7 if progress < 0.75 else 0.9
		"SASHI":
			effort = 0.55 if progress < 0.7 else 0.95
		"OIKOMI":
			effort = 0.45 if progress < 0.8 else 1.0
		_:
			effort = 0.7

	effort += rng.randf_range(-0.05, 0.05)
	effort = clamp(effort, 0.3, 1.0)

	var lane_target := 2.0 + rng.randf_range(-0.3, 0.3)

	return {"effort": effort, "lane": lane_target}
