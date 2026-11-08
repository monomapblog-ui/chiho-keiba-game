## コース定義。実在の地方競馬場をモデルにする場合は TrackPresets 経由で作る。
class_name TrackData
extends Resource

@export var track_name: String = ""
@export var distance_m: float = 1400.0
@export var lane_count: int = 4

## 1周の距離。周回のない直線コースなら distance_m と同じ値にする。
@export var lap_distance_m: float = 1400.0

## 1周の中でのコーナー区間のリスト。各要素は Dictionary
## {"start": 開始m(周内), "end": 終了m(周内), "severity": 外を回った時のスタミナ消費倍率}
@export var corner_zones: Array = []

## インコース(1レーン寄り)を通り続けることへのペナルティ倍率。0なら無し。
## (例: 砂が深く外を回る傾向がある、等の特定コースの特徴を表す)
@export var inner_lane_penalty: float = 0.0

## レース上の絶対位置を「1周の中での位置」に変換する。
## distance_m が lap_distance_m の整数倍でない場合、スタート地点は1周の途中になる。
func pos_in_lap(position_m: float) -> float:
	if lap_distance_m <= 0.0:
		return position_m
	var start_offset := fmod(lap_distance_m - fmod(distance_m, lap_distance_m), lap_distance_m)
	return fmod(start_offset + position_m, lap_distance_m)
