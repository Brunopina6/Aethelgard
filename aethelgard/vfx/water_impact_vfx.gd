extends Node3D
# Impacto de agua mágica (Godot 4.x) — escena WaterImpactVFX.tscn.
# Al aparecer: el géiser sale del suelo hacia arriba girando despacio, el agua fluye por él,
# saltan salpicaduras y gotas (GPUParticles3D) y hay un destello azul (OmniLight3D).
# Luego el géiser se desvanece y la escena se borra sola con queue_free(). Emite "terminado"
# justo antes de borrarse. El origen de la escena son los pies del enemigo (el suelo).

signal terminado

@export var duracion := 1.7            # tiempo total del efecto en segundos
@export var giro := 140.0              # grados por segundo que gira el géiser
@export var energia_luz := 4.0

@onready var geiser: MeshInstance3D = $Geiser
@onready var salpicadura: GPUParticles3D = $Salpicadura
@onready var gotas: GPUParticles3D = $Gotas
@onready var luz: OmniLight3D = $Luz

var _mat: ShaderMaterial


func _ready() -> void:
	_mat = geiser.material_override
	var escala_final: Vector3 = geiser.get_meta("escala_final", Vector3.ONE)
	geiser.scale = Vector3(escala_final.x * 0.6, 0.0, escala_final.z * 0.6)     # brota del suelo
	_mat.set_shader_parameter("alfa", 1.0)
	salpicadura.restart()
	gotas.restart()

	var t := create_tween()
	t.tween_property(geiser, "scale", escala_final, duracion * 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(duracion * 0.4)
	t.tween_method(func(a: float): _mat.set_shader_parameter("alfa", a), 1.0, 0.0, duracion * 0.4)

	luz.light_energy = 0.0
	var tl := create_tween()
	tl.tween_property(luz, "light_energy", energia_luz, 0.08)
	tl.tween_property(luz, "light_energy", 0.0, 0.6).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(maxf(duracion, gotas.lifetime + 0.2)).timeout
	terminado.emit()
	queue_free()


func _process(delta: float) -> void:
	geiser.rotate_y(deg_to_rad(giro) * delta)
