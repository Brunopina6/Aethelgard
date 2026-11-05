extends Node3D
# Impacto de rayo (Godot 4.x) — escena LightningImpactVFX.tscn.
# El rayo cae justo encima del enemigo con la base en el suelo: aparece al instante (0,05 s),
# tiembla, se estrecha en X/Z y desaparece en 0,25 s. Una OmniLight3D en la base da una luz
# intensa que parpadea dos veces. Saltan chispas (GPUParticles3D). Al terminar emite "terminado"
# y se borra sola con queue_free(). El origen de la escena son los pies del enemigo (el suelo).

signal terminado

@export var aparecer := 0.05           # segundos en aparecer
@export var desaparecer := 0.25        # segundos en estrecharse y desaparecer
@export var temblor := 0.08            # metros que tiembla
@export var energia_luz := 9.0

@onready var rayo: MeshInstance3D = $Rayo
@onready var chispas: GPUParticles3D = $Chispas
@onready var luz: OmniLight3D = $Luz

var _mat: ShaderMaterial
var _temblando := true
var _pos0: Vector3


func _ready() -> void:
	_mat = rayo.material_override
	_pos0 = rayo.position
	var final: Vector3 = rayo.get_meta("escala_final", Vector3.ONE)
	rayo.scale = Vector3(final.x, 0.0, final.z)
	_mat.set_shader_parameter("alfa", 1.0)
	chispas.restart()

	# aparece de golpe (cae del cielo), luego se estrecha en X/Z y se desvanece
	var t := create_tween()
	t.tween_property(rayo, "scale", final, aparecer)
	t.tween_interval(0.06)
	t.tween_property(rayo, "scale", Vector3(final.x * 0.08, final.y, final.z * 0.08), desaparecer).set_ease(Tween.EASE_IN)
	t.parallel().tween_method(func(a: float): _mat.set_shader_parameter("alfa", a), 1.0, 0.0, desaparecer)
	t.tween_callback(func(): _temblando = false)

	# luz intensa en la base que parpadea dos veces
	luz.light_energy = 0.0
	var tl := create_tween()
	for i in 2:
		tl.tween_property(luz, "light_energy", energia_luz, 0.03)
		tl.tween_property(luz, "light_energy", energia_luz * 0.15, 0.06)
	tl.tween_property(luz, "light_energy", 0.0, 0.12)

	await get_tree().create_timer(maxf(aparecer + desaparecer + 0.1, chispas.lifetime + 0.1)).timeout
	terminado.emit()
	queue_free()


func _process(_delta: float) -> void:
	if _temblando:                              # tiembla un poco mientras está visible
		rayo.position = _pos0 + Vector3(randf_range(-temblor, temblor), 0.0, randf_range(-temblor, temblor))
