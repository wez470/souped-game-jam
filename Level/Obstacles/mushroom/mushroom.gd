extends StaticBody3D

var _dip: bool = false
var _dip_timer: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Time.get_ticks_msec() - _dip_timer > 2500:
		_dip = false
		position.y = -20
	if _dip:
		var dist_away: float = 1.0 - (float(abs(1250 - (Time.get_ticks_msec() - _dip_timer))) / 1250.0)
		position.y = -50.0 * dist_away - 20


func _on_area_3d_body_entered(body: Node3D) -> void:
	if "boing" in body:
		if body._souped:
			return
		body.boing()
		_dip = true
		_dip_timer = Time.get_ticks_msec()
