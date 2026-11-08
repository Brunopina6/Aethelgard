@tool
extends DialogicPortrait
# Retrato «vivo» para Dialogic (T-081): la misma ilustración de siempre, con vida.
# - Respira: una escala vertical muy pequeña desde los pies (no se despegan del suelo), con su propio ritmo.
# - Foco: quien habla se ilumina y se adelanta un poco; quien escucha se atenúa y se queda un paso atrás
#   (_highlight y _unhighlight, que Dialogic llama al cambiar de interlocutor).
# - Gestos breves, pedidos desde la línea de tiempo con [extra_data="…"]: ligero, firme, duda, sorpresa, decidido,
#   inquieta y preocupada. Cada uno dura menos de dos segundos y vuelve al reposo: nadie se mueve todo el rato.
# Se usa con el retrato «vivo» de los personajes (kael.dch y lya.dch); el retrato «normal» sigue siendo el de siempre.

@export_group('Main')
@export_file var image := ""

const ATENUADO := Color(0.7, 0.72, 0.8)            # quien escucha: un paso atrás, sin parecer un fantasma
const RESPIRO := 0.006                             # cuánto sube el pecho: apenas un 0,6 %

var _t := 0.0
var _fase := 0.0
var _periodo := 3.4
var _gesto: Tween
var _foco: Tween


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_fase = randf() * TAU
	_periodo = randf_range(3.1, 3.8)
	set("modulate", ATENUADO)


func _update_portrait(passed_character: DialogicCharacter, passed_portrait: String) -> void:
	apply_character_and_portrait(passed_character, passed_portrait)
	apply_texture($Foco/Gesto/Respira/Portrait, image)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var s := sin(_t * TAU / _periodo + _fase)
	$Foco/Gesto/Respira.scale = Vector2(1.0 - RESPIRO * 0.3 * s, 1.0 + RESPIRO * s)


func _highlight() -> void:
	_cambiar_foco(true)


func _unhighlight() -> void:
	_cambiar_foco(false)


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
		"decidido":                                # un paso hacia el otro
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
		_:
			t.kill()
	set_meta("ultimo_gesto", data)                  # lo miran las pruebas


func _get_covered_rect() -> Rect2:
	var p: Sprite2D = $Foco/Gesto/Respira/Portrait
	if p.texture == null:
		return Rect2()
	return Rect2(p.position, p.get_rect().size)


func _set_mirror(mirror: bool) -> void:
	$Foco/Gesto/Respira/Portrait.flip_h = mirror
