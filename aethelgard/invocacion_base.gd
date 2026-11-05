extends Node
# Base reutilizable para todas las invocaciones (Érebo y las que vengan).
# Se encarga de lo común: ajustes de calidad y accesibilidad, cámara cinematográfica,
# sonido por capas, saltar sin duplicar efectos y dejarlo todo como estaba al terminar.
#
# Cada invocación hereda y escribe solo su coreografía en _secuencia(ctx).
# Uso desde combate:
#   var inv = load("res://invocacion_erebo.gd").new()
#   add_child(inv)
#   var resultado: Dictionary = await inv.lanzar(ctx)
#   (si el jugador pulsa saltar: inv.saltar())

signal evento(nombre: String)       # para sincronizar UI, daño, vibración...
signal terminada(resultado: Dictionary)

# Ajustes (los puede rellenar el menú de opciones)
var ajustes := {
	"calidad": "alta",             # "alta" (PC) | "movil" (menos partículas, sin sombras extra)
	"reducir_destellos": false,
	"reducir_sacudidas": false,
	"volumen_db": 0.0,
}

var camara: Camera3D
var resultado := {}
var _saltada := false
var _resultado_aplicado := false
var _al_resultado := Callable()
var _cam_trans := Transform3D()
var _cam_fov := 40.0
var _cam_tw: Tween
var _sacude := 0.0
var _sacude_dur := 0.0
var _sonidos := {}
var _capa_ui: CanvasLayer
var _velo: ColorRect


func es_movil() -> bool:
	return ajustes.calidad == "movil"


# ---------------------------------------------------------------- ciclo de vida

func lanzar(ctx: Dictionary) -> Dictionary:
	_saltada = false
	_resultado_aplicado = false
	resultado = {}
	camara = ctx.get("camara", get_viewport().get_camera_3d())
	_al_resultado = ctx.get("al_resultado", Callable())
	if camara != null:
		_cam_trans = camara.global_transform
		_cam_fov = camara.fov
	_crear_velo()
	await _secuencia(ctx)
	if not _saltada:
		_aplicar_resultado()        # por si la coreografía no llegó a aplicarlo
		await _restaurar(0.6)
		terminada.emit(resultado)
	return resultado


# Salta la cinemática: aplica el resultado una sola vez y limpia al instante.
func saltar() -> void:
	if _saltada:
		return
	_saltada = true
	_al_saltar()
	_aplicar_resultado()
	_restaurar(0.0)
	terminada.emit(resultado)


func saltada() -> bool:
	return _saltada


# Las hijas lo amplían para limpiar sus personajes y efectos.
func _al_saltar() -> void:
	pass


func _secuencia(_ctx: Dictionary) -> void:
	pass


# El daño/muerte solo se aplica una vez, pase lo que pase.
func _aplicar_resultado() -> void:
	if _resultado_aplicado or resultado.is_empty():
		return
	_resultado_aplicado = true
	if _al_resultado.is_valid():
		_al_resultado.call(resultado)


func _restaurar(dur: float) -> void:
	Engine.time_scale = 1.0
	_sacude = 0.0
	for s in _sonidos.values():
		s.stop()
	if _velo != null:
		_velo.color.a = 0.0
	if camara == null:
		return
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	if dur <= 0.0:
		camara.global_transform = _cam_trans
		camara.fov = _cam_fov
		return
	_cam_tw = create_tween().set_parallel(true)
	_cam_tw.tween_property(camara, "global_transform", _cam_trans, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tw.tween_property(camara, "fov", _cam_fov, dur)
	await _cam_tw.finished


# ---------------------------------------------------------------- cámara

# Plano: la cámara viaja a «pos» mirando a «mira» en «dur» segundos (transición suave).
func plano(pos: Vector3, mira: Vector3, dur: float, fov := -1.0) -> void:
	if camara == null or _saltada:
		return
	if _cam_tw != null and _cam_tw.is_valid():
		_cam_tw.kill()
	var destino := Transform3D(Basis.looking_at(mira - pos, Vector3.UP), pos)
	if dur <= 0.0:
		camara.global_transform = destino
		if fov > 0.0:
			camara.fov = fov
		return
	_cam_tw = create_tween().set_parallel(true)
	_cam_tw.tween_property(camara, "global_transform", destino, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if fov > 0.0:
		_cam_tw.tween_property(camara, "fov", fov, dur).set_trans(Tween.TRANS_SINE)


# Sacudida controlada (se reduce mucho si el jugador lo pide).
func sacudir(fuerza: float, dur: float) -> void:
	if ajustes.reducir_sacudidas:
		fuerza *= 0.2
	_sacude = fuerza
	_sacude_dur = dur


func _process(delta: float) -> void:
	if _sacude > 0.0 and camara != null:
		var d := delta / maxf(Engine.time_scale, 0.01)
		_sacude_dur -= d
		var off := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _sacude
		camara.h_offset = off.x
		camara.v_offset = off.y
		if _sacude_dur <= 0.0:
			_sacude = 0.0
			camara.h_offset = 0.0
			camara.v_offset = 0.0
	elif camara != null and (camara.h_offset != 0.0 or camara.v_offset != 0.0):
		camara.h_offset = 0.0
		camara.v_offset = 0.0


# Congela el tiempo un instante (impacto), ignorando la escala para volver.
func congelar(escala: float, segundos: float) -> void:
	Engine.time_scale = escala
	await get_tree().create_timer(segundos, true, false, true).timeout
	Engine.time_scale = 1.0


# Destello de pantalla (muy suave si se reducen los destellos).
func destello(color: Color, dur := 0.25) -> void:
	if _velo == null:
		return
	if ajustes.reducir_destellos:
		color.a *= 0.2
	_velo.color = color
	var t := create_tween()
	t.tween_property(_velo, "color:a", 0.0, dur).set_ease(Tween.EASE_IN)


func _crear_velo() -> void:
	if _capa_ui != null:
		return
	_capa_ui = CanvasLayer.new()
	_capa_ui.layer = 50
	add_child(_capa_ui)
	_velo = ColorRect.new()
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.color = Color(0, 0, 0, 0)
	_capa_ui.add_child(_velo)


# ---------------------------------------------------------------- sonido por capas

func sonar(ruta: String, vol_db := 0.0, tono := 1.0) -> void:
	if _saltada or not ResourceLoader.exists(ruta):
		return
	var p: AudioStreamPlayer = _sonidos.get(ruta)
	if p == null:
		p = AudioStreamPlayer.new()
		p.stream = load(ruta)
		add_child(p)
		_sonidos[ruta] = p
	p.volume_db = vol_db + ajustes.volumen_db
	p.pitch_scale = tono
	p.play()


# Silencio dramático: baja todas las capas que suenan.
func silenciar(dur := 0.15) -> void:
	for p in _sonidos.values():
		if p.playing:
			var t := create_tween()
			t.tween_property(p, "volume_db", -60.0, dur)
			t.tween_callback(p.stop)


func esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout
