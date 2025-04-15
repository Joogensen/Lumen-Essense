extends CanvasLayer


func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	pass

func start_animation():
	show()
	$ColorRect.modulate.a = 0.0 
	$AnimationPlayer.play("death")
