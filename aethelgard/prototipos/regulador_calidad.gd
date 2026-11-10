extends RefCounted
# Calibración al entrar y ajuste dinámico de la calidad (encargo del 09/11: 30 FPS estables). Solo DECIDE: recibe el
# tiempo real de cada fotograma (muestra) y devuelve qué hacer; quien lo usa (vista3d.gd) lo aplica y lo guarda
# (calidad_auto.gd). Así se prueba con tiempos simulados (pruebas/prueba_calidad_auto.gd).
#
# Presupuesto: 1000 / FPS objetivo ms (33,3 ms a 30 FPS). Una medida es MALA si su p95 pasa de 1,2 veces el
# presupuesto (40 ms) o su mediana de 1,05 veces (35 ms). Medidas del Redmi (tope 30): bajo v293, mediana 33,4 y p95
# 34,0: bien; medio nuevo (v336, cand B) a 20 m, 33,3 y 34,3: bien; a 34 m, 36,0 y 39,0: mal; medio antiguo, 37,0 y 42,2: mal.
#
#   espera      los primeros ESPERA s de la escena no cuentan (entrada, sombreados, sonidos).
#   calibrando  primera vez de este perfil en automática: se miden CALIBRA_MIDE s. Bien: «calibrado». Mal: con
#               «alto» a 60, se queda en 30 y se vuelve a medir; si no, se pide el perfil de debajo para la próxima
#               carga (bajar uno; detrás del fundido de la próxima entrada, sin cambios bruscos) y se sigue vigilando.
#   vigilando   ventanas de VENTANA s. MALAS_PARA_BAJAR ventanas malas SEGUIDAS (unos 6 s) bajan UN escalón
#               (calidad_auto.ESCALONES: resolución, sombras, hierba y partículas, distancias). Tras un cambio, ASENTAR
#               s sin evaluar. Sin escalones: el perfil de debajo para la próxima carga; en «bajo», se registra que el
#               aparato no llega (una vez).
#   histéresis  bajar pide unos 6 s seguidos por encima; subir un escalón pide CALMA_PARA_SUBIR s seguidos con el p95
#               dentro del presupuesto, y a cada escalón solo se vuelve a subir UNA vez por sesión: si vuelve a fallar,
#               se queda abajo. Así no oscila. Los FPS NUNCA suben solos (de 30 a 60, jamás).
#   a mano      con el perfil fijado por el jugador no se cambia nada: solo se avisa (una vez) si no llega.

const ESPERA := 3.0
const CALIBRA_MIDE := 6.0
const VENTANA := 2.0
const MALAS_PARA_BAJAR := 3
const CALMA_PARA_SUBIR := 90.0
const ASENTAR := 4.0
const MS_PAUSA := 250.0         # un fotograma más largo es una pausa o una carga, no falta de GPU: no cuenta
const TOL_P95 := 1.2           # 40 ms a 30 FPS
const TOL_MEDIANA := 1.05      # 35 ms a 30 FPS: el medio nuevo a 34 m (mediana 36,0, 27,7 FPS) ya es «malo»
const TOL_CALMA := 1.05

var perfil: String
var fps: int                    # límite en uso
var objetivo: int               # FPS que se defienden: 30; 60 solo con «alto» a 60 decidido por el sistema
var auto: bool
var calibrar: bool
var nivel: int
var max_nivel: int
var estado := "espera"
var ultima_medida := {}
var cambios := 0                # acciones que cambian la calidad o los FPS (las pruebas cuentan oscilaciones)

var _t := 0.0
var _tras_asentar := ""
var _muestras := PackedFloat32Array()
var _t_muestras := 0.0
var _malas := 0
var _calma := 0.0
var _subidas := {}              # nivel → ya se subió a él en esta sesión
var _avisado := false
var _no_llega := false
var _perfil_pedido := false


func _init(p_perfil: String, p_fps: int, p_objetivo: int, p_auto: bool, p_calibrar: bool, p_nivel: int,
		p_max_nivel: int) -> void:
	perfil = p_perfil
	fps = p_fps
	objetivo = p_objetivo
	auto = p_auto
	calibrar = p_calibrar and p_auto
	max_nivel = p_max_nivel if p_auto else 0
	nivel = clampi(p_nivel, 0, max_nivel)


func presupuesto_ms() -> float:
	return 1000.0 / float(objetivo)


# Un fotograma de «ms» milisegundos (reloj real). Devuelve {} o {"accion": …, "medida": {p95, mediana, n}}.
func muestra(ms: float) -> Dictionary:
	if ms <= 0.0 or ms > MS_PAUSA:
		return {}
	match estado:
		"espera":
			_t += ms / 1000.0
			if _t >= ESPERA:
				_ir("calibrando" if calibrar else "vigilando")
		"asentar":
			_t += ms / 1000.0
			if _t >= ASENTAR:
				_ir(_tras_asentar)
		"calibrando":
			_acumular(ms)
			if _t_muestras >= CALIBRA_MIDE:
				return _fin_calibracion()
		"vigilando":
			_acumular(ms)
			if _t_muestras >= VENTANA:
				return _fin_ventana()
	return {}


func _ir(e: String) -> void:
	estado = e
	_t = 0.0
	_muestras.clear()
	_t_muestras = 0.0


func _asentar(despues: String) -> void:
	_tras_asentar = despues
	_ir("asentar")


func _acumular(ms: float) -> void:
	_muestras.append(ms)
	_t_muestras += ms / 1000.0


func _medida() -> Dictionary:
	var orden := _muestras.duplicate()
	orden.sort()
	var n := orden.size()
	var m := {"n": n, "p95": orden[mini(n - 1, int(n * 0.95))] if n > 0 else 0.0,
		"mediana": orden[n / 2] if n > 0 else 0.0, "segundos": _t_muestras}
	_muestras.clear()
	_t_muestras = 0.0
	ultima_medida = m
	return m


func mala(m: Dictionary) -> bool:
	return float(m["p95"]) > presupuesto_ms() * TOL_P95 or float(m["mediana"]) > presupuesto_ms() * TOL_MEDIANA


func _tranquila(m: Dictionary) -> bool:
	return float(m["p95"]) <= presupuesto_ms() * TOL_CALMA


func _fin_calibracion() -> Dictionary:
	var m := _medida()
	if not mala(m):
		calibrar = false
		_ir("vigilando")
		return {"accion": "calibrado", "perfil": perfil, "fps": fps, "medida": m}
	if fps == 60 and objetivo == 60:                 # «alto» no llega a 60: 30 y se vuelve a medir
		fps = 30
		objetivo = 30
		cambios += 1
		_asentar("calibrando")
		return {"accion": "fps", "fps": 30, "medida": m}
	calibrar = false
	_ir("vigilando")
	if perfil != "bajo":
		_perfil_pedido = true
		cambios += 1
		return {"accion": "perfil", "perfil": _bajar(perfil), "medida": m}
	return {"accion": "calibrado", "perfil": perfil, "fps": fps, "medida": m, "justo": true}


func _fin_ventana() -> Dictionary:
	var m := _medida()
	if mala(m):
		_calma = 0.0
		_malas += 1
		if _malas < MALAS_PARA_BAJAR:
			return {}
		_malas = 0
		if not auto:
			if _avisado:
				return {}
			_avisado = true
			return {"accion": "aviso", "perfil": perfil, "medida": m}
		if fps == 60 and objetivo == 60:             # «alto» a 60 que ya no aguanta: a 30 (nunca al revés)
			fps = 30
			objetivo = 30
			cambios += 1
			_asentar("vigilando")
			return {"accion": "fps", "fps": 30, "medida": m}
		if nivel < max_nivel:
			nivel += 1
			cambios += 1
			_asentar("vigilando")
			return {"accion": "nivel", "nivel": nivel, "medida": m}
		if perfil != "bajo":
			if _perfil_pedido:
				return {}
			_perfil_pedido = true
			cambios += 1
			return {"accion": "perfil", "perfil": _bajar(perfil), "medida": m}
		if _no_llega:
			return {}
		_no_llega = true
		return {"accion": "no_llega", "perfil": perfil, "medida": m}
	_malas = 0                                       # «sostenido»: seguidas
	_calma = _calma + float(m["segundos"]) if _tranquila(m) else 0.0
	if auto and nivel > 0 and _calma >= CALMA_PARA_SUBIR and not _subidas.has(nivel - 1):
		nivel -= 1
		_subidas[nivel] = true
		_calma = 0.0
		cambios += 1
		_asentar("vigilando")
		return {"accion": "nivel", "nivel": nivel, "subir": true, "medida": m}
	return {}


static func _bajar(p: String) -> String:
	return "medio" if p == "alto" else "bajo"
