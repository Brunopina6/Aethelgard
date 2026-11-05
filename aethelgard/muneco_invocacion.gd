extends Node3D
# Doble en 3D de un enemigo dibujado en 2D (slime, guardián...) para la cinemática de Érebo
# (invocacion_erebo.gd). Es su dibujo puesto de pie en el escenario 3D, siempre mirando a la cámara,
# con lo que la invocación le pide: ALTURA, herida() y morir().

var ALTURA := 1.6
var _spr: Sprite3D
var _muerta := false


func preparar(tex: Texture2D, alto: float, tinte := Color.WHITE, region := Rect2()) -> void:
	ALTURA = alto
	_spr = Sprite3D.new()
	_spr.texture = tex
	if region.has_area():
		_spr.region_enabled = true
		_spr.region_rect = region
	var alto_px: float = region.size.y if region.has_area() else float(tex.get_height())
	_spr.pixel_size = alto / maxf(1.0, alto_px)
	_spr.centered = true
	_spr.offset = Vector2(0, alto_px * 0.5)          # los pies en el suelo
	_spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_spr.shaded = false
	_spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_spr.modulate = tinte
	_spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	add_child(_spr)


func herida() -> void:
	if _muerta or _spr == null:
		return
	var base := _spr.modulate
	var t := create_tween()
	t.tween_property(_spr, "modulate", Color(1.8, 0.5, 0.6), 0.08)
	t.parallel().tween_property(_spr, "position:x", 0.08, 0.05)
	t.tween_property(_spr, "position:x", -0.08, 0.08)
	t.tween_property(_spr, "position:x", 0.0, 0.08)
	t.tween_property(_spr, "modulate", base, 0.3)


func morir() -> void:
	if _muerta or _spr == null:
		return
	_muerta = true
	var t := create_tween().set_parallel(true)
	t.tween_property(_spr, "modulate", Color(0.6, 0.2, 0.5, 0.0), 1.2)
	t.tween_property(_spr, "position:y", -0.25, 1.2).set_ease(Tween.EASE_IN)
