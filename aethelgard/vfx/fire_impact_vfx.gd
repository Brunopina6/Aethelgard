extends Node3D
# Impacto de fuego mágico (Godot 4.x) — escena FireImpactVFX.tscn.
# Al aparecer: el vórtice gira sobre su eje Y y crece de 0 a 1, salen llamas estilizadas y chispas
# (GPUParticles3D), y un destello breve de luz (OmniLight3D). Luego el vórtice se desvanece y la
# escena se borra sola con queue_free(). Emite "terminado" justo antes de borrarse.
# El origen de la escena son los pies del enemigo (el suelo).

signal terminado

@export var duracion := 1.6            # tiempo total del efecto en segundos
@export var giro := 540.0              # grados por segundo que gira el vórtice
@export var energia_luz := 6.0

@onready var vortice: MeshInstance3D = $Vortice
@onready var llamas: GPUParticles3D = $Llamas
@onready var chispas: GPUParticles3D = $Chispas
@onready var luz: OmniLight3D = $Luz

var _mat: ShaderMaterial


func _ready() -> void:
	_mat = vortice.material_override
	vortice.scale = Vector3.ZERO
	_mat.set_shader_parameter("alfa", 1.0)
	llamas.restart()
	chispas.restart()

	var escala_final: Vector3 = vortice.get_meta("escala_final", Vector3.ONE)
	var t := create_tween()
	t.tween_property(vortice, "scale", escala_final, duracion * 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(duracion * 0.38)
	t.tween_method(func(a: float): _mat.set_shader_parameter("alfa", a), 1.0, 0.0, duracion * 0.4)

	luz.light_energy = 0.0
	var tl := create_tween()
	tl.tween_property(luz, "light_energy", energia_luz, 0.06)
	tl.tween_property(luz, "light_energy", 0.0, 0.45).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(maxf(duracion, llamas.lifetime + 0.2)).timeout
	terminado.emit()
	queue_free()


func _process(delta: float) -> void:
	vortice.rotate_y(deg_to_rad(giro) * delta)
