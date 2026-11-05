extends "res://invocacion_base.gd"
# Érebo — Ladrón de Corazones. Coreografía completa (cámara, sombra, sonido, reglas).
#
# ctx = {
#   "invocador": Node3D,        # quien invoca (Lya)
#   "objetivo": Node3D,         # un solo enemigo
#   "es_jefe": bool,
#   "camara": Camera3D,         # opcional (la activa si falta)
#   "al_resultado": Callable,   # f(resultado) -> aplica daño/muerte UNA vez, justo al estallar el orbe
#   "forzar": "exito"/"fallo",  # opcional, para pruebas
# }
# resultado = {"exito": bool, "muerte": bool, "dano_pct_actual": float}
#   Enemigo normal: 20 % de muerte instantánea. Si falla, secuencia corta sin orbe.
#   Jefe: siempre arranca el orbe; quita el 20 % de la vida ACTUAL (nunca mata de golpe).

const PROB_MUERTE := 0.2
const DANO_JEFE := 0.2
const SND := "res://sonidos/erebo_%s.wav"

var erebo: Node3D
var sombra: Node3D
var _invocador: Node3D
var _objetivo: Node3D
var _sombras_apagadas: Array = []
var _lado := Vector3.FORWARD
var _hacia := Vector3.RIGHT


func _secuencia(ctx: Dictionary) -> void:
	_invocador = ctx.invocador
	_objetivo = ctx.objetivo
	var es_jefe: bool = ctx.get("es_jefe", false)
	var exito: bool = es_jefe or randf() < PROB_MUERTE
	if ctx.has("forzar"):
		exito = es_jefe or ctx.forzar == "exito"
	resultado = {"exito": exito, "muerte": exito and not es_jefe, "dano_pct_actual": DANO_JEFE if es_jefe else (1.0 if exito else 0.0)}

	await _preparar(ctx)
	var pies: Vector3 = _invocador.global_position
	var hacia_inv: Vector3 = (pies - _objetivo.global_position)
	hacia_inv.y = 0.0
	hacia_inv = hacia_inv.normalized()
	var lugar: Vector3 = _objetivo.global_position + hacia_inv * 0.95
	erebo.global_position = lugar
	erebo.mirar(-hacia_inv, 0.0)
	var lado := hacia_inv.cross(Vector3.UP).normalized()   # perpendicular a la línea invocador-objetivo
	if camara != null and lado.dot(camara.global_position - lugar) < 0.0:
		lado = -lado                                        # siempre del lado donde ya está la cámara
	_lado = lado
	_hacia = hacia_inv

	# 1. La sombra se desprende y corre por el suelo (cámara baja que la sigue)
	if _invocador.has_method("lanzar_magia"):
		_invocador.lanzar_magia()
	sonar(SND % "susurros", -6.0)
	await esperar(0.7)
	if saltada(): return
	_apagar_sombra(_invocador)
	sonar(SND % "sombra", -3.0)
	var medio := (pies + lugar) * 0.5
	plano(pies + lado * 3.2 + Vector3(0, 1.15, 0) - hacia_inv * 0.6, pies.lerp(lugar, 0.35), 0.6, 44.0)
	get_tree().create_timer(0.6).timeout.connect(func():
		if not saltada(): plano(lugar + lado * 3.0 + Vector3(0, 1.0, 0) + hacia_inv * 0.9, medio.lerp(lugar, 0.75), 1.1, 42.0))
	await sombra.viajar(pies, lugar, 1.6)
	if saltada(): return
	sombra.ocultar(0.4)

	# 2. Érebo surge del suelo (plano bajo, contrapicado)
	plano(lugar + lado * 2.6 + hacia_inv * 1.2 + Vector3(0, 0.45, 0), lugar + Vector3(0, 1.0, 0), 0.8, 42.0)
	evento.emit("invocacion")
	await erebo.emerger()
	if saltada(): return

	# 3. Mete la mano en el pecho (primer plano lateral)
	var pecho: Vector3 = _objetivo.global_position + Vector3(0, _altura(_objetivo) * 0.55, 0)
	plano((pecho + lugar) * 0.5 + lado * 1.5 + Vector3(0, 0.15, 0), (pecho + lugar) * 0.5 + Vector3(0, 0.05, 0), 0.5, 38.0)
	await erebo.penetrar()
	if saltada(): return
	_onda_pecho(pecho)
	sacudir(0.03, 0.18)
	await congelar(0.12, 0.14)
	if saltada(): return

	# 4. Extrae la esencia
	sonar(SND % "extraccion", -2.0)
	await erebo.extraer(exito)
	if saltada(): return
	if not exito:
		# fallo: la mano sale vacía, secuencia corta
		evento.emit("fallo")
		_aplicar_resultado()
		if _objetivo.has_method("herida"):
			_objetivo.herida()
		await _salida(pies, lugar)
		return

	# 5. Lo sostiene delante de la máscara: primer plano frontal
	var cara: Vector3 = lugar + Vector3(0, _altura(erebo) * 0.55, 0)
	# se gira hacia la cámara para «presentar» el orbe (el enemigo no tapa el plano)
	var presenta := (-hacia_inv + lado * 1.4).normalized()
	erebo.mirar(presenta, 0.45)
	plano(cara + presenta * 1.5 + lado * 0.15 + Vector3(0, 0.1, 0), cara + Vector3(0, 0.02, 0), 0.9, 36.0)
	await erebo.aplastar(_al_estallar)
	if saltada(): return
	await esperar(0.6)
	if saltada(): return
	await _salida(pies, lugar)


func _al_estallar() -> void:
	sonar(SND % "fractura", 0.0)
	sonar(SND % "resonancia", -4.0)
	destello(Color(1.0, 0.8, 0.88, 0.4), 0.25)
	sacudir(0.09, 0.45)
	_aplicar_resultado()              # el enemigo reacciona justo al romperse el orbe
	var l: Vector3 = erebo.global_position
	plano(l + _lado * 2.7 + _hacia * 0.4 + Vector3(0, 1.0, 0), l - _hacia * 0.4 + Vector3(0, 0.75, 0), 0.6, 42.0)


func _salida(pies: Vector3, lugar: Vector3) -> void:
	await erebo.hundirse()
	if saltada(): return
	sonar(SND % "sombra", -8.0, 0.85)
	await sombra.viajar(lugar, pies, 1.1, true)
	if saltada(): return
	await sombra.ocultar(0.3)
	_reponer_sombra()
	if _invocador.has_method("fin_magia"):
		_invocador.fin_magia()


func _preparar(ctx: Dictionary) -> void:
	var raiz: Node = ctx.objetivo.get_parent()
	if erebo == null:
		erebo = load("res://erebo_3d.gd").new()
		erebo.calidad = "movil" if es_movil() else "alta"
		erebo.visible = false
		raiz.add_child(erebo)
		for i in 3:
			await get_tree().process_frame
	erebo.reducir_destellos = ajustes.reducir_destellos
	erebo.cancelado = false
	if not erebo.evento.is_connected(_reenviar):
		erebo.evento.connect(_reenviar)
	if sombra == null:
		sombra = load("res://sombra_invocacion.gd").new()
		raiz.add_child(sombra)


func _reenviar(nombre: String) -> void:
	evento.emit(nombre)
	match nombre:
		"emerge":
			sonar(SND % "susurros", -4.0, 0.8)
		"pulso":
			sonar(SND % "pulso", -2.0, 1.0 + erebo._aplasta * 0.3)
		"sostiene":
			sonar(SND % "tension", -6.0)
		"tension":
			silenciar(0.12)               # silencio justo antes del impacto
		"se_hunde":
			sonar(SND % "susurros", -10.0, 0.7)


# Onda espiritual en el pecho (sin herida): un aro que se cierra y otro que se abre.
func _onda_pecho(pos: Vector3) -> void:
	erebo.fogonazo(pos, Color(0.55, 0.2, 0.8, 0.8), 0.7 * _altura(erebo), 0.25, true, true)
	erebo.fogonazo(pos, Color(1.0, 0.2, 0.35, 0.5), 0.5 * _altura(erebo), 0.35, false, true)


func _altura(n: Node) -> float:
	var a = n.get("ALTURA")
	return a if a != null else 1.6


func _apagar_sombra(n: Node) -> void:
	_sombras_apagadas.clear()
	for mi in n.find_children("*", "GeometryInstance3D", true, false):
		if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			_sombras_apagadas.append([mi, mi.cast_shadow])
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _reponer_sombra() -> void:
	for par in _sombras_apagadas:
		if is_instance_valid(par[0]):
			par[0].cast_shadow = par[1]
	_sombras_apagadas.clear()


func _al_saltar() -> void:
	if erebo != null:
		erebo.cancelado = true
		erebo.limpiar()
	if sombra != null:
		sombra.limpiar()
	_reponer_sombra()
	if _invocador != null and _invocador.has_method("fin_magia"):
		_invocador.fin_magia()
