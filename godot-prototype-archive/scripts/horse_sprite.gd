## 馬の見た目。OpenGameArt の CC0 スプライト("pixel-horse" by alizard,
## https://opengameart.org/content/pixel-horse)を使った走りアニメーション。
## 素材自体に色の違いはないため、識別用に上に小さい色付きの旗を立てている。
class_name HorseSprite
extends Node2D

const SHEET_PATH := "res://assets/sprites/horse_run_cycle.png"
const FRAME_SIZE := Vector2i(82, 66)
const FRAME_COUNT := 5

## 脚の動く速さの基準。馬の実際の速度(m/s)に応じて外側から設定する。
var gait_speed: float = 0.0

var _anim: AnimatedSprite2D
var _flag: Polygon2D
var _pending_color := Color.WHITE

static var _shared_frames: SpriteFrames = null

func _ready() -> void:
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = _get_shared_frames()
	_anim.animation = "run"
	_anim.play()
	_anim.flip_h = true  # 素材は左向きのため、右(ゴール方向)向きに反転
	add_child(_anim)

	_flag = Polygon2D.new()
	_flag.polygon = PackedVector2Array([
		Vector2(-10, -46), Vector2(10, -46), Vector2(10, -38), Vector2(-10, -38),
	])
	_flag.color = _pending_color
	add_child(_flag)

func set_color(c: Color) -> void:
	_pending_color = c
	if _flag:
		_flag.color = c

func _process(_delta: float) -> void:
	if _anim:
		_anim.speed_scale = clamp(gait_speed, 0.2, 3.0)

static func _get_shared_frames() -> SpriteFrames:
	if _shared_frames != null:
		return _shared_frames

	var sheet: Texture2D = load(SHEET_PATH)
	var frames := SpriteFrames.new()
	frames.add_animation("run")
	frames.set_animation_speed("run", 10.0)
	frames.set_animation_loop("run", true)

	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(Vector2(i * FRAME_SIZE.x, 0), Vector2(FRAME_SIZE))
		frames.add_frame("run", atlas)

	_shared_frames = frames
	return frames
