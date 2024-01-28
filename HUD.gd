extends Control

@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _splat_player: AudioStreamPlayer = $SplatPlayer

func souped() -> void:
	_anim_player.play("souped")
	_splat_player.play()

func reset() -> void:
	_anim_player.play("RESET")
	_splat_player.stop()


func escaped() -> void:
	_anim_player.play("escaped")
