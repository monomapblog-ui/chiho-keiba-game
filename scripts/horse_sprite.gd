## 簡易的に「馬らしい」見た目にするための、図形だけで組んだシルエット。
## 画像素材はまだ無いので、ポリゴンを組み合わせて側面から見た馬の形を作り、
## 脚を振る簡単なアニメーションを付けている。本格的な絵への差し替えは別途。
class_name HorseSprite
extends Node2D

## 脚を振る速さ。馬の実際の速度(m/s)に応じて外側から設定する。
var gait_speed: float = 0.0

var _gait_phase: float = 0.0
var _leg_front: Polygon2D
var _leg_back: Polygon2D
var _parts: Array[Polygon2D] = []

func _ready() -> void:
	# 脚(後ろ脚を先に描いて、前脚・胴体・首の後ろに隠れるようにする)
	_leg_back = _make_poly(_leg_shape())
	_leg_back.position = Vector2(-13, 0)
	add_child(_leg_back)

	_leg_front = _make_poly(_leg_shape())
	_leg_front.position = Vector2(13, 0)
	add_child(_leg_front)

	var body := _make_poly(_ellipse_points(22.0, 12.0, Vector2.ZERO, 16))
	add_child(body)

	var neck := _make_poly(PackedVector2Array([
		Vector2(12, -4), Vector2(24, -20), Vector2(32, -25), Vector2(40, -19),
		Vector2(38, -10), Vector2(28, -3), Vector2(16, 2),
	]))
	add_child(neck)

	var ear := _make_poly(PackedVector2Array([
		Vector2(31, -24), Vector2(33, -31), Vector2(36, -23),
	]))
	add_child(ear)

	var tail := _make_poly(PackedVector2Array([
		Vector2(-21, -5), Vector2(-30, -13), Vector2(-27, 3), Vector2(-18, 3),
	]))
	add_child(tail)

	_parts = [_leg_back, _leg_front, body, neck, ear, tail]

func set_color(c: Color) -> void:
	for p in _parts:
		p.color = c

func _make_poly(points: PackedVector2Array) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = points
	return poly

func _ellipse_points(rx: float, ry: float, center: Vector2, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := (TAU / float(segments)) * i
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _leg_shape() -> PackedVector2Array:
	# 付け根(y=0、胴体側)から足先(y=18)に伸びる細い脚。回転の軸は付け根側。
	return PackedVector2Array([
		Vector2(-2, 0), Vector2(2, 0), Vector2(2, 18), Vector2(-2, 18),
	])

func _process(delta: float) -> void:
	_gait_phase += delta * gait_speed
	var swing := sin(_gait_phase) * 20.0
	_leg_front.rotation = deg_to_rad(swing)
	_leg_back.rotation = deg_to_rad(-swing)
