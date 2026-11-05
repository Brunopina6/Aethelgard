extends Node3D
# Efecto de curación (Godot 4.x) — escena HealingVFX.tscn.
# Se pone en los pies del personaje curado. El círculo rúnico queda plano en el suelo; la espiral
# (con las cruces y las hojas) gira despacio sobre el eje Y. Todo aparece desde abajo escalándose
# con suavidad, se mantiene 0,8 s y se desvanece con transparencia. Una OmniLight3D verde/dorada
# va subiendo de brillo. Al final emite "terminado" y se borra con queue_free().

signal terminado

@export var aparecer := 0.5            # segundos en crecer desde el suelo
@export var mantener := 0.8            # segundos a pleno
@export var desvanecer := 0.6          # segundos del fundido
@export var giro := 60.0               # grados por segundo que gira la espiral
@export var energia_luz := 2.5

@onready var circulo: MeshInstance3D = $Circulo
@onready var espiral: MeshInstance3D = $Espiral
@onready var brillos: GPUParticles3D = $Brillos
@onready var luz: OmniLight3D = $Luz


func _ready() -> void:
	var e_circulo: Vector3 = circulo.get_meta("escala_final", Vector3.ONE)
	var e_espiral: Vector3 = espiral.get_meta("escala_final", Vector3.ONE)
	circulo.scale = Vector3(0.0, e_circulo.y, 0.0)          # el círculo se abre en el suelo
	espiral.scale = Vector3(e_espiral.x * 0.7, 0.0, e_espiral.z * 0.7)   # la espiral crece hacia arriba
	_alfa(1.0)
	brillos.restart()

	var t := create_tween().set_parallel(true)
	t.tween_property(circulo, "scale", e_circulo, aparecer * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(espiral, "scale", e_espiral, aparecer).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.chain().tween_interval(mantener)
	t.chain().tween_method(_alfa, 1.0, 0.0, desvanecer)

	luz.light_energy = 0.0                                   # la luz sube poco a poco
	var tl := create_tween()
	tl.tween_property(luz, "light_energy", energia_luz, aparecer + mantener).set_trans(Tween.TRANS_SINE)
	tl.tween_property(luz, "light_energy", 0.0, desvanecer)

	await get_tree().create_timer(aparecer + mantener + desvanecer + 0.05).timeout
	terminado.emit()
	queue_free()


func _alfa(a: float) -> void:
	(circulo.material_override as ShaderMaterial).set_shader_parameter("alfa", a)
	(espiral.material_override as ShaderMaterial).set_shader_parameter("alfa", a)


func _process(delta: float) -> void:
	espiral.rotate_y(deg_to_rad(giro) * delta)          # solo gira la espiral; el círculo queda quieto
