## 架空のコース定義。地方競馬らしい短めのダート・小回りをイメージした数値。
class_name TrackData
extends Resource

@export var track_name: String = ""
@export var distance_m: float = 1400.0
@export var lane_count: int = 4

## コーナー区間のリスト。各要素は Vector2(開始m, 終了m)
@export var corner_zones: Array = []
