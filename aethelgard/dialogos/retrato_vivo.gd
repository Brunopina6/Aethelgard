@tool
extends DialogicPortrait
# Retrato «vivo» para Dialogic (T-081, T-084): las ilustraciones del personaje, con vida.
# - Respira: una escala vertical muy pequeña desde los pies (no se despegan del suelo), con su propio ritmo.
# - Foco: quien habla se ilumina y se adelanta un poco; quien escucha se atenúa y se queda un paso atrás
#   (_highlight y _unhighlight, que Dialogic llama al cambiar de interlocutor).
# - Gestos breves, pedidos desde la línea de tiempo con [extra_data="…"]: ligero, firme, duda, sorpresa, decidido (o
#   decidida), inquieta y preocupada. Cada uno dura menos de dos segundos y vuelve al reposo: nadie se mueve todo el rato.
# - Poses (T-084): si el personaje tiene una ilustración para ese gesto («poses» en su .dch: gesto → imagen), pasa a
#   ella con un fundido corto mientras dice su frase, y vuelve a la de reposo («image») al dejar de hablar o pasados
#   unos segundos. Quien escucha está siempre en reposo, y cada frase lleva su gesto sin repetirse.
#   El fundido no deja ver el fondo a través del cuerpo: la pose nueva aparece ENCIMA de la anterior y solo después se
#   retira la de debajo (que ya solo se ve donde la nueva no tapa: el brazo que cambia de sitio).
# Se usa con el retrato «vivo» de los personajes (kael.dch y lya.dch) en el prólogo y con «vivo_pv» en los diálogos de
# Pastos Verdes (el mismo, del tamaño y en el sitio del retrato «normal»; T-084, tanda 2).

@export_group('Main')
@export_file var image := ""
@export var poses := {}                            # gesto → ilustración, p. ej. {"decidido": "res://…/kael_puno.png"}

const ATENUADO := Color(0.7, 0.72, 0.8)            # quien escucha: un paso atrás, sin parecer un fantasma
const RESPIRO := 0.006                             # cuánto sube el pecho: apenas un 0,6 %
const ENTRA := 0.18                                # segundos: la pose nueva aparece encima…
const SALE := 0.14                                 # …y después se retira la anterior
const MANTENER := 3.2                              # segundos con la pose del gesto si sigue hablando
const MANTENER_GESTO := {"sorpresa": 1.8}          # las reacciones más breves

var _t := 0.0
var _fase := 0.0
var _periodo := 3.4
var _gesto: Tween
var _foco: Tween
var _fundido: Tween
var _espera: Tween
var _reposo: Texture2D
var _texturas := {}                                # gesto → textura (cargadas al unirse el personaje)
var _pose := "reposo"
var _pose_t := -10.0                               # cuándo se pidió la pose del último gesto (en segundos de _t)
var _hablo_tras_pose := false                      # si ha empezado a hablar después de pedirla


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_fase = randf() * TAU
	_periodo = randf_range(3.1, 3.8)
	set("modulate", ATENUADO)


func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	for tw in [_fundido, _espera]:                  # (Dialogic crea un nodo nuevo en cada cambio de retrato; por si acaso)
		if tw != null and tw.is_valid():
			tw.kill()
	$Foco/Gesto/Respira/Siguiente.visible = false
	$Foco/Gesto/Respira/Portrait.modulate.a = 1.0
	apply_character_and_portrait(passed_character, passed_portrait)
	apply_texture($Foco/Gesto/Respira/Portrait, image)
	_reposo = $Foco/Gesto/Respira/Portrait.texture
	_texturas.clear()
	_pose = "reposo"
	set_meta("pose", _pose)                         # lo miran las pruebas
	if Engine.is_editor_hint():
		return
	for g in poses:                                 # ya están en memoria: la pantalla de carga lee dialogos/retratos/
		var ruta := String(poses[g])
		if ResourceLoader.exists(ruta):
			_texturas[g] = load(ruta)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var s := sin(_t * TAU / _periodo + _fase)
	$Foco/Gesto/Respira.scale = Vector2(1.0 - RESPIRO * 0.3 * s, 1.0 + RESPIRO * s)


func _highlight() -> void:
	_cambiar_foco(true)
	_hablo_tras_pose = true


func _unhighlight() -> void:
	_cambiar_foco(false)
	# Quien escucha, en reposo. Salvo si la pose se acaba de pedir sin que haya hablado después: entonces es una
	# reacción a lo que va a decir el otro (la etiqueta va justo antes de su frase) y vuelve sola, con su tiempo.
	if _hablo_tras_pose or _t - _pose_t > 0.25:
		_volver_al_reposo()


func _cambiar_foco(habla: bool) -> void:
	if _foco != null and _foco.is_valid():
		_foco.kill()
	_foco = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_foco.tween_property(self, "modulate", Color.WHITE if habla else ATENUADO, 0.3)
	_foco.tween_property($Foco, "position:y", -8.0 if habla else 4.0, 0.35)
	_foco.tween_property($Foco, "scale", Vector2.ONE * (1.0 if habla else 0.975), 0.35)


# Hacia dónde está el otro: los de la izquierda miran a la derecha y al revés.
func _hacia_el_otro() -> float:
	var p = get("global_position")
	return 1.0 if p == null or p.x < 640.0 else -1.0


func _set_extra_data(data: String) -> void:
	if Engine.is_editor_hint() or data == "":
		return
	var g: Node2D = $Foco/Gesto
	if _gesto != null and _gesto.is_valid():
		_gesto.kill()
	g.position = Vector2.ZERO
	g.rotation = 0.0
	g.scale = Vector2.ONE
	var d := _hacia_el_otro()
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gesto = t
	match data:
		"ligero":                                  # un pequeño bote, como quien quita hierro
			t.tween_property(g, "position:y", -10.0, 0.16).set_ease(Tween.EASE_OUT)
			t.tween_property(g, "position:y", 0.0, 0.24).set_ease(Tween.EASE_IN)
		"firme":                                   # un asentimiento seco
			t.tween_property(g, "position:y", 5.0, 0.12)
			t.parallel().tween_property(g, "scale", Vector2.ONE * 1.015, 0.12)
			t.tween_property(g, "position:y", 0.0, 0.3)
			t.parallel().tween_property(g, "scale", Vector2.ONE, 0.3)
		"duda":                                    # ladea la cabeza y vuelve
			t.tween_property(g, "rotation_degrees", -3.0 * d, 0.35)
			t.tween_interval(0.6)
			t.tween_property(g, "rotation_degrees", 0.0, 0.45)
		"sorpresa":                                # un respingo
			t.tween_property(g, "position:y", -12.0, 0.1).set_ease(Tween.EASE_OUT)
			t.parallel().tween_property(g, "scale", Vector2.ONE * 1.03, 0.1)
			t.tween_property(g, "position:y", 0.0, 0.3).set_ease(Tween.EASE_IN)
			t.parallel().tween_property(g, "scale", Vector2.ONE, 0.3)
		"decidido", "decidida":                    # un paso hacia el otro
			t.tween_property(g, "position:x", 18.0 * d, 0.4)
			t.parallel().tween_property(g, "scale", Vector2.ONE * 1.025, 0.4)
			t.tween_interval(1.0)
			t.tween_property(g, "position:x", 0.0, 0.6)
			t.parallel().tween_property(g, "scale", Vector2.ONE, 0.6)
		"inquieta":                                # se acerca, preocupada por lo que cuenta
			t.tween_property(g, "position:x", 14.0 * d, 0.35)
			t.tween_interval(0.8)
			t.tween_property(g, "position:x", 0.0, 0.6)
		"preocupada":                              # se encoge un poco
			t.tween_property(g, "position:y", 8.0, 0.5)
			t.parallel().tween_property(g, "scale", Vector2.ONE * 0.985, 0.5)
			t.tween_interval(0.8)
			t.tween_property(g, "position:y", 0.0, 0.6)
			t.parallel().tween_property(g, "scale", Vector2.ONE, 0.6)
		_:                                         # solo pose (p. ej. «brazalete»), o nada
			t.kill()
	set_meta("ultimo_gesto", data)                  # lo miran las pruebas
	if _texturas.has(data):                         # la ilustración del gesto, mientras dice su frase
		_cambiar_pose(data)
		_pose_t = _t
		_hablo_tras_pose = false
		if _espera != null and _espera.is_valid():
			_espera.kill()
		_espera = create_tween()
		_espera.tween_interval(MANTENER_GESTO.get(data, MANTENER))
		_espera.tween_callback(_volver_al_reposo)


func _volver_al_reposo() -> void:
	if _espera != null and _espera.is_valid():
		_espera.kill()
	if _pose != "reposo":
		_cambiar_pose("reposo")


# Pasa a otra ilustración del personaje con un fundido corto (ENTRA + SALE). Si había otro a medias, lo termina antes.
func _cambiar_pose(nombre: String) -> void:
	var tex: Texture2D = _reposo if nombre == "reposo" else _texturas.get(nombre)
	if tex == null:
		return
	_terminar_fundido()
	_pose = nombre
	set_meta("pose", nombre)
	var base: Sprite2D = $Foco/Gesto/Respira/Portrait
	var encima: Sprite2D = $Foco/Gesto/Respira/Siguiente
	if base.texture == tex:
		return
	encima.texture = tex
	encima.position = base.position
	encima.scale = base.scale
	encima.flip_h = base.flip_h
	encima.modulate.a = 0.0
	encima.visible = true
	_fundido = create_tween()
	_fundido.tween_property(encima, "modulate:a", 1.0, ENTRA).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fundido.tween_property(base, "modulate:a", 0.0, SALE)
	_fundido.tween_callback(_terminar_fundido)


func _terminar_fundido() -> void:
	if _fundido != null and _fundido.is_valid():
		_fundido.kill()
	_fundido = null
	var base: Sprite2D = $Foco/Gesto/Respira/Portrait
	var encima: Sprite2D = $Foco/Gesto/Respira/Siguiente
	if encima.visible and encima.texture != null:
		base.texture = encima.texture
	base.modulate.a = 1.0
	encima.visible = false
	encima.modulate.a = 0.0


func _get_covered_rect() -> Rect2:
	var p: Sprite2D = $Foco/Gesto/Respira/Portrait
	if p.texture == null:
		return Rect2()
	return Rect2(p.position, p.get_rect().size)


func _set_mirror(mirror: bool) -> void:
	$Foco/Gesto/Respira/Portrait.flip_h = mirror
	$Foco/Gesto/Respira/Siguiente.flip_h = mirror
