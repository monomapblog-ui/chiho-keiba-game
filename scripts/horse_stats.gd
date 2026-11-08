## 馬1頭分の能力値を表すデータ。実在の競走馬・騎手とは一切関係のない架空の値。
class_name HorseStats
extends Resource

@export var display_name: String = ""
@export var jockey_name: String = ""

## 1-100。トップスピードの高さ
@export_range(1, 100) var speed: int = 50
## 1-100。スタミナの多さ(バテにくさ)
@export_range(1, 100) var stamina: int = 50
## 1-100。加速力・瞬発力
@export_range(1, 100) var power: int = 50
## 1-100。終盤でどれだけ踏ん張れるか
@export_range(1, 100) var guts: int = 50

## 脚質: NIGE(逃げ) / SENKO(先行) / SASHI(差し) / OIKOMI(追込)
@export var running_style: String = "SENKO"
