extends SceneTree
# V12 (16/11): RECORRIDO de la CIUDAD COMPLETA de Oakhaven (maqueta EXPERIMENTAL, zonas3d/ciudad/, solo desde el banco de
# pruebas de Auditoría) con Kael y el grupo y los CONTROLES NORMALES (docs/v12/ciudad_sectores/RECORRIDO.md):
#   - se entra como una persona: el banco de pruebas y su botón «Ciudad de Oakhaven (maqueta, en pruebas)»;
#   - andar: CLICS de ratón en el suelo (InputEventMouseButton en coordenadas de la VENTANA: la posición del viewport
#     1280×720 pasa por root.get_final_transform(), con las franjas negras de 16:9 a 1600×720), nunca «destino» a mano.
#     Adónde tocar sale de una ruta A* por lo andable del plano (rejilla de 0,25 m, la de prueba_ciudad_plano) recortada en
#     tramos rectos libres (lo andable, sin escalón de más de 0,3 m y sin caja sólida a la altura de las rodillas) y del
#     propio toque de la escena (_punto_suelo y _ajustar_destino: se toca donde el toque cae de verdad en ese punto);
#   - un tramo con las TECLAS de dirección (la Calle Mayor hacia el norte, a un lado, al otro y atrás);
#   - los botones con clics: la acción de las puertas («en obras») y de la Puerta del Sur, «Guardar y recargar» y
#     «Volver al banco».
# Cubre: los 8 sectores; las 12 conexiones en los dos sentidos; cada SUELO en pendiente (escaleras, escalinatas y rampas)
# de los ocho trazados, ida y vuelta; cada «cubierta» con suelo debajo (soportales, corredores, pasos bajo casa, arcos,
# toldos y tejadillos); los callejones sin salida y los atajos de A.md-D.md; todas las puertas previstas; «Guardar y
# recargar» en cada sector; «Volver al banco» dos veces y la vuelta a la Puerta del Sur.
# En cada parada: que Kael llega (distancia), que no pisa lo que no es andable ni atraviesa cajas sólidas (cada
# fotograma), que no se atasca (tiempo), que el grupo le sigue (distancia, sobre lo andable) y que Kael se VE: cabeza y
# pies dentro del cuadro y ningún bloque sin aclarar entre la cámara y su cabeza (los ocultables de los sectores montados
# han de estar aclarados; lo no ocultable o la maqueta lejana de un sector sin montar, FALLO) ni nada ocultable sin
# aclarar delante de su cintura y sus pies, ni (ya parados) de la cabeza y la cintura del grupo a menos de 8 m.
# Imprime una línea por tramo, «RECORRIDO: n tramos, m fallos» y «FALLOS: m».
# Uso (con ventana; sin ventana también corre, sin capturas):
#   Godot --path aethelgard --script res://pruebas/recorrido_ciudad.gd --fixed-fps 30 --resolution 1600x720 --
#     salida=<carpeta fuera del proyecto> [perfil=bajo|medio|alto] [video=0] [solo=plaza_tapiz,oficios] [rapido]
# «solo»: visita solo esos sectores (las conexiones se andan igual); «rapido»: sin puertas ni cubiertas (depurar).
# NO mide rendimiento: quita el tope de FPS de la escena (perfil_fps) para ir más deprisa; el tiempo del juego lo fija
# --fixed-fps 30.

const BANCO := "res://banco_pruebas.tscn"
const ESCENA := "res://zonas3d/ciudad/ciudad.tscn"
const P := preload("res://zonas3d/ciudad/plano.gd")
const Comun := preload("res://zonas3d/ciudad/trazado_comun.gd")
const Blockout := preload("res://zonas3d/ciudad/blockout.gd")
const FPS := 30.0
const C := 0.25                               # celda de la rejilla (la de prueba_ciudad_plano)
const X0 := -100.0
const Z0 := -92.0
const W := 840
const H := 748
const MAX_RECTA := 9.0                        # lo más lejos que se toca (en cuadro y sin rodeos)
const LLEGA := 0.5
const GRUPO_LEJOS := 6.0
const MAX_FOTOS_FALLO := 40
const CADA_VIDEO := 15                        # un fotograma de vídeo cada 15 del juego (2 por segundo)

# Callejones sin salida por sector (A.md-D.md): [nombre, ancla del fondo, ancla desde la que se entra y a la que se vuelve].
const SIN_SALIDA := {
	"puerta_sur": [["Patio de la Rayuela (por el zaguán)", "n_pozo", "n_terraza"], ["Muelle de carga (fondo de los portes)", "n_muelle", "n_caravanas"]],
	"plaza_tapiz": [["Mirador del pretil (rincón de la plaza alta)", "mirador_pretil", "n_alta"]],
	"oficios": [["Callejón del Carbón", "n_carbon", "n_bajada"]],
	"ribera": [["Callejón de los Fardos", "reserva_rastreadores_almacen", "n_patio"]],
	"pasajes": [["Callejón de Pip, la grieta y el Patio de las Velas", "n_patio_velas", "n_alto_pip"],
		["Huerto de la Muralla", "n_huerto", "n_baja"], ["Rincón Fresco", "n_fresco", "n_vecinos_o"],
		["Corral del Rincón", "n_corral", "n_macetas_o"]],
	"cuervo": [["Corral de la Posada", "n_cuadra", "n_terraza"]],
	"terrazas": [["Patio de la Pieza", "n_patio", "n_t3"]],
	"barrio_alto": [["Mirador del Concejo", "n_mirador", "n_paseo_e"], ["Mirador de las Raíces", "mirador_raices", "n_arbol"]],
}
# Atajos y bucles documentados (A.md-D.md): [nombre, anclas en orden].
const ATAJOS := {
	"puerta_sur": [["Callejón de los Arrieros (Arco → Calle Mayor)", ["n_arco", "n_terraza", "n_callejon", "n_callejon_e", "n_mayor"]]],
	"plaza_tapiz": [["Plazuela de la Botica (Calle Mayor → callejón → Paso Cubierto)", ["n_mayor", "n_plazuela", "n_callejon_m", "n_callejon_s", "n_paso"]]],
	"oficios": [["Escalerilla de la Colina (Calle del Mercado → Paseo de la Colina)", ["n_mercado_e", "n_escalerilla_pie", "n_escalerilla_alta", "n_colina"]]],
	"ribera": [["Escalera del Molino y bucle de la acequia", ["n_escalera_pie", "n_puente", "n_rincon", "n_pasarela", "n_senda", "n_lavadero"]]],
	"pasajes": [["Escalerilla de la Botica (Paso Cubierto → Arco)", ["n_botica", "n_corredor", "n_esc_s", "n_arco"]]],
	"cuervo": [["Bucle del Callejón del Corro", ["n_boca", "n_corro_lane", "n_corro_e", "n_corro", "n_escalinata", "n_patio"]]],
	"terrazas": [["Atajo de la Hornacina", ["n_t1_o", "n_atajo", "n_t2_o"]],
		["Subida directa (Escaleras de los Tendederos y del Lavadero)", ["n_t1_esc", "n_escalera_t1", "n_t2_e", "n_escalera_e", "n_t3_e", "n_escalera_lav", "n_t4_esc", "n_t4_e"]]],
	"barrio_alto": [["Vuelta al Árbol (bajo la raíz en arco)", ["n_arbol", "n_arbol_o", "n_arbol_no", "n_tras_arbol", "n_arbol_ne", "n_arbol_e", "n_arbol"]]],
}

var v                                          # la escena (ciudad.gd)
var salida := ""
var perfil := "bajo"
var video := true
var rapido := false
var solo: Array = []
var con_fotos := true
var fallos := 0
var tramos := 0
var n_foto := 0
var fotos_fallo := 0
var n_video := 0
var registro: PackedStringArray = []
var cuenta := {}                               # lo cubierto: tipo → n
var sentidos := {}                             # "conexion:a>b" → true
var astar: AStarGrid2D
var anda := PackedByteArray()                  # 1 = andable (rejilla C)
var rodillas := {}                             # cubo de 4 m → [Rect2] de las cajas sólidas más altas que las rodillas
var _t := {}                                   # el tramo en curso: lo que se vigila cada fotograma
var _previas := {}
var _vis_marcha := 0
var _vis_marcha_txt := ""
var _diag_toque := ""
var repetidos := 0                             # pulsaciones de botón repetidas (el primer clic no entró)


func _initialize() -> void:
	var tam := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		elif a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("tam="):
			tam = a.trim_prefix("tam=")
		elif a == "video=0":
			video = false
		elif a == "rapido":
			rapido = true
		elif a.begins_with("solo="):
			solo = Array(a.trim_prefix("solo=").split(","))
	if salida == "":
		salida = OS.get_user_data_dir().path_join("recorrido_ciudad")
	DirAccess.make_dir_recursive_absolute(salida)
	con_fotos = DisplayServer.get_name() != "headless"
	video = video and con_fotos
	if video:
		DirAccess.make_dir_recursive_absolute(salida.path_join("video"))
	if tam.contains("x"):
		root.size = Vector2i(int(tam.get_slice("x", 0)), int(tam.get_slice("x", 1)))
	process_frame.connect(_cada_cuadro)
	_jugar.call_deferred()


# ================================================================= utilidades

func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await _frames(maxi(1, int(s * FPS)))


func _nota(t: String) -> void:
	print(t)
	registro.append(t)


func _contar(k: String, n := 1) -> void:
	cuenta[k] = int(cuenta.get(k, 0)) + n


func _kael() -> Vector3:
	return v.kael.global_position


func _plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _suelo(p: Vector3) -> Vector3:
	return Vector3(p.x, P.altura(p.x, p.z), p.z)


func _vivo() -> bool:
	return v != null and is_instance_valid(v) and v.is_inside_tree() and v.get("kael") != null


func _limpio(t: String) -> String:
	var r := ""
	for ch in t.to_lower():
		r += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	return r.substr(0, 40)


func _foto(nombre: String) -> String:
	if not con_fotos:
		return ""
	await _frames(2)
	n_foto += 1
	var ruta := salida.path_join("%03d_%s.jpg" % [n_foto, _limpio(nombre)])
	root.get_texture().get_image().save_jpg(ruta, 0.9)
	return ruta.get_file()


# Cada fotograma: Kael y el grupo sobre lo andable (no atraviesan cajas sólidas: lo sólido no es andable), saltos del
# grupo (reaparecer detrás de Kael = se quedó atrás) y, cada CADA_VIDEO, un fotograma para el vídeo.
func _cada_cuadro() -> void:
	if video and Engine.get_process_frames() % CADA_VIDEO == 0:
		var img := root.get_texture().get_image()
		if img != null and not img.is_empty():
			img.resize(int(img.get_width() / 2) & ~1, int(img.get_height() / 2) & ~1, Image.INTERPOLATE_BILINEAR)
			img.save_jpg(salida.path_join("video/%06d.jpg" % n_video), 0.8)
			n_video += 1
	if _t.is_empty() or not _vivo():
		_previas.clear()
		return
	var k: Vector3 = v.kael.global_position
	var ant: Vector3 = _previas.get("kael", k)
	for i in 4:                                       # (el paso del fotograma entero, no solo su final)
		var q := ant.lerp(k, (i + 1) / 4.0)
		if not P.andable(q.x, q.z):
			_t["kael_fuera"] = int(_t.get("kael_fuera", 0)) + 1
			if not _t.has("kael_donde"):
				_t["kael_donde"] = "(%.2f, %.2f) %s" % [q.x, q.z, _que_hay(q)]
			break
	_t["max_dy"] = maxf(float(_t.get("max_dy", 0.0)), absf(k.y - P.altura(k.x, k.z)))
	_previas["kael"] = k
	if v.grupo != null:
		for n in v.grupo.nodos():
			var g: Vector3 = (n as Node3D).global_position
			var ga: Vector3 = _previas.get(n, g)
			if _plana(g, ga) > 2.5:
				_t["saltos"] = int(_t.get("saltos", 0)) + 1
			elif not _andable_grupo(g):
				_t["grupo_fuera"] = int(_t.get("grupo_fuera", 0)) + 1
				if not _t.has("grupo_donde"):
					_t["grupo_donde"] = "%s en (%.2f, %.2f) %s" % [n.name, g.x, g.z, _que_hay(g)]
			_previas[n] = g


# Qué hay en un punto que no es andable (para el informe).
func _que_hay(q: Vector3) -> String:
	var s := P.sector_en_caja(q.x, q.z)
	if s == "":
		return "fuera de la ciudad"
	var b: String = P.trazado(s).bloque_en(q.x, q.z)
	return "%s: %s" % [s, "bloque " + b if b != "" else "sin suelo"]


# ================================================================= controles

func _clic(pos: Vector2) -> void:
	var w: Vector2 = root.get_final_transform() * pos
	var m := InputEventMouseMotion.new()           # (el puntero llega antes al sitio, como un dedo o un ratón de verdad)
	m.position = w
	m.global_position = w
	Input.parse_input_event(m)
	await _frames(1)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = w
	e.global_position = w
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var s := InputEventMouseButton.new()
	s.button_index = MOUSE_BUTTON_LEFT
	s.position = w
	s.global_position = w
	s.pressed = false
	Input.parse_input_event(s)
	await _frames(2)


func _clic_boton(b: Control) -> void:
	await _clic(b.get_global_rect().get_center())


# Pulsar un botón hasta que haga lo esperado («hecho»), como quien vuelve a tocar si el toque no entra: hasta 3 veces,
# esperando «seg» segundos REALES cada vez. (A 1600×720, 2 de unos 200 clics en un botón no entraron en una pasada; lo
# más probable, el puntero de verdad sobre la ventana entre la pulsación y la suelta.) Cuenta las repeticiones.
func _pulsar(b: Control, hecho: Callable, seg: float) -> bool:
	for intento in 3:
		if intento > 0:
			repetidos += 1
		if b == null or not is_instance_valid(b) or not b.is_visible_in_tree():
			return hecho.call()
		await _clic_boton(b)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < seg * 1000.0:
			if hecho.call():
				return true
			await process_frame
	return hecho.call()


func _tecla(codigo: Key, pulsada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = codigo
	e.physical_keycode = codigo
	e.pressed = pulsada
	Input.parse_input_event(e)


func _boton_banco() -> Button:
	var r = root.get_node_or_null("Recursos")
	return r.boton_banco if r != null else null


# ¿Se puede tocar ahí? En el cuadro y sin los botones de la interfaz.
func _se_puede_tocar(pp: Vector2) -> bool:
	if not Rect2(20, 100, 1240, 610).has_point(pp):
		return false
	for b in [v.boton_accion, v.boton_recargar, _boton_banco()]:
		if b != null and b.is_visible_in_tree() and (b as Control).get_global_rect().grow(10).has_point(pp):
			return false
	return true


# ================================================================= la rejilla y la ruta

func _rango(r: Rect2) -> Array:
	var i0 := clampi(int(ceil((r.position.x - X0) / C - 0.5)), 0, W)
	var i1 := clampi(int(ceil((r.end.x - X0) / C - 0.5)) - 1, -1, W - 1)
	var j0 := clampi(int(ceil((r.position.y - Z0) / C - 0.5)), 0, H)
	var j1 := clampi(int(ceil((r.end.y - Z0) / C - 0.5)) - 1, -1, H - 1)
	return [i0, i1, j0, j1]


func _centro(i: int, j: int) -> Vector2:
	return Vector2(X0 + (i + 0.5) * C, Z0 + (j + 0.5) * C)


func _celda(x: float, z: float) -> Vector2i:
	return Vector2i(clampi(int(floor((x - X0) / C)), 0, W - 1), clampi(int(floor((z - Z0) / C)), 0, H - 1))


# Lo andable por sector (sus suelos dentro de su caja, menos sus bloques sólidos: P.andable, en rectángulos) y las cajas
# sólidas más altas que las rodillas (vista3d: el rayo a SUBE_MAX + 0,1 = 0,6 m). Pesos: lejos de las paredes.
func _preparar_rejilla() -> void:
	var t0 := Time.get_ticks_msec()
	anda.resize(W * H)
	anda.fill(0)
	for s in P.ORDEN:
		var caja: Rect2 = P.SECTORES[s]["caja"]
		var t = P.trazado(s)
		for su in t.SUELOS:
			var g: Array = _rango(su[1])
			for j in range(g[2], g[3] + 1):
				for i in range(g[0], g[1] + 1):
					if caja.has_point(_centro(i, j)):
						anda[j * W + i] = 1
		for b in t.BLOQUES:
			if not b[6]:
				continue
			var g: Array = _rango(b[2])
			for j in range(g[2], g[3] + 1):
				for i in range(g[0], g[1] + 1):
					if caja.has_point(_centro(i, j)):
						anda[j * W + i] = 0
	for s2 in P.ORDEN:                               # (exactas, no en la rejilla: el rayo roza las esquinas)
		for b in P.trazado(s2).BLOQUES:
			if b[6] and float(b[4]) > 0.6:
				var r: Rect2 = (b[2] as Rect2).grow(0.05)
				for cz in range(int(floor(r.position.y / 4.0)), int(floor(r.end.y / 4.0)) + 1):
					for cx in range(int(floor(r.position.x / 4.0)), int(floor(r.end.x / 4.0)) + 1):
						var clave := Vector2i(cx, cz)
						if not rodillas.has(clave):
							rodillas[clave] = []
						rodillas[clave].append(r)
	var cerca1 := PackedByteArray()
	cerca1.resize(W * H)
	var cerca2 := PackedByteArray()
	cerca2.resize(W * H)
	for j in H:
		for i in W:
			var k := j * W + i
			if anda[k] == 0:
				continue
			if (i == 0 or anda[k - 1] == 0) or (i == W - 1 or anda[k + 1] == 0) or (j == 0 or anda[k - W] == 0) or (j == H - 1 or anda[k + W] == 0):
				cerca1[k] = 1
	for j in range(1, H - 1):
		for i in range(1, W - 1):
			var k := j * W + i
			if anda[k] == 1 and cerca1[k] == 0 and (cerca1[k - 1] == 1 or cerca1[k + 1] == 1 or cerca1[k - W] == 1 or cerca1[k + W] == 1):
				cerca2[k] = 1
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, W, H)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	astar.update()
	var n := 0
	for j in H:
		for i in W:
			var k := j * W + i
			if anda[k] == 0:
				astar.set_point_solid(Vector2i(i, j), true)
			else:
				n += 1
				if cerca1[k] == 1:
					astar.set_point_weight_scale(Vector2i(i, j), 4.0)
				elif cerca2[k] == 1:
					astar.set_point_weight_scale(Vector2i(i, j), 2.0)
	_nota("rejilla: %d casillas andables (%.0f m²) en %.1f s" % [n, n * C * C, (Time.get_ticks_msec() - t0) / 1000.0])


func _anda_rejilla(x: float, z: float) -> bool:
	var c := _celda(x, z)
	return anda[c.y * W + c.x] == 1


func _rodilla(x: float, z: float) -> bool:
	var q := Vector2(x, z)
	for r in rodillas.get(Vector2i(int(floor(x / 4.0)), int(floor(z / 4.0))), []):
		if (r as Rect2).has_point(q):
			return true
	return false


# La casilla andable más cercana a p (hasta 2 m).
func _celda_libre(p: Vector3) -> Vector2i:
	var c := _celda(p.x, p.z)
	if anda[c.y * W + c.x] == 1:
		return c
	var mejor := c
	var dmin := INF
	for r in range(1, 9):
		for j in range(c.y - r, c.y + r + 1):
			for i in range(c.x - r, c.x + r + 1):
				if i < 0 or j < 0 or i >= W or j >= H or anda[j * W + i] == 0:
					continue
				var d := _centro(i, j).distance_to(Vector2(p.x, p.z))
				if d < dmin:
					dmin = d
					mejor = Vector2i(i, j)
		if dmin < INF:
			return mejor
	return c


# La ruta (puntos en planta) de a a b por lo andable; el último punto es b.
func _ruta(a: Vector3, b: Vector3) -> PackedVector2Array:
	var ids := astar.get_id_path(_celda_libre(a), _celda_libre(b))
	var r := PackedVector2Array()
	r.append(Vector2(a.x, a.z))
	for i in range(1, ids.size()):
		r.append(_centro(ids[i].x, ids[i].y))
	if ids.size() > 0:
		r[r.size() - 1] = Vector2(b.x, b.z)
	return r


func _largo(r: PackedVector2Array) -> float:
	var l := 0.0
	for i in range(1, r.size()):
		l += r[i].distance_to(r[i - 1])
	return l


# Un tramo recto que Kael anda de un tirón: lo andable cada 0,1 m, sin escalones de más de 0,3 m y sin una caja sólida a
# la altura de las rodillas 0,35 m por delante (vista3d._altura_suelo: el rayo llega 0,3 m más allá de cada paso de 0,15).
# «exacta»: con el plano (P.andable y P.altura); si no, con la rejilla (para elegir deprisa).
func _recta_libre(a: Vector3, b: Vector3, exacta := true, rodillas_tambien := true) -> bool:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var l := d.length()
	if l < 0.05:
		return true
	var dir := d / l
	var n := int(ceil(l / 0.1))
	var y_ant := P.altura(a.x, a.z) if exacta else 0.0
	for i in range(1, n + 1):
		var q := Vector2(a.x, a.z) + d * (float(i) / n)
		if exacta:
			if not P.andable(q.x, q.y):
				return false
			var y := P.altura(q.x, q.y)
			if absf(y - y_ant) > 0.3:
				return false
			y_ant = y
		elif not _anda_rejilla(q.x, q.y):
			return false
		if rodillas_tambien and l * float(i) / n < l - 0.15:
			for adelante in [0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45]:   # (todo el rayo: en una esquina lo corta de lado)
				var r: Vector2 = q + dir * adelante
				if _rodilla(r.x, r.y):
					return false
	return true


# El siguiente toque hacia «meta»: el punto más lejano de la ruta que se anda en línea recta, en cuadro, que se puede tocar
# y donde el toque cae de verdad (la escena: _punto_suelo y _ajustar_destino). [destino previsto, posición en pantalla].
func _siguiente_toque(meta: Vector3) -> Variant:
	var k := _kael()
	var ruta := _ruta(k, meta)
	if ruta.size() < 2:
		ruta = PackedVector2Array([Vector2(k.x, k.z), Vector2(meta.x, meta.z)])
	var cand: Array = []
	var acum := 0.0
	for j in range(1, ruta.size()):
		acum += ruta[j].distance_to(ruta[j - 1])
		if acum > MAX_RECTA * 1.4:
			break
		cand.append(j)
	cand.reverse()
	var diag := {"cand": cand.size(), "lejos": 0, "rejilla": 0, "detras": 0, "no_tocable": 0, "cae_null": 0, "cae_lejos": 0, "recta": 0}
	# primero, los puntos de la ruta; si ninguno vale (un pretil a menos de 1 m delante recoge el toque, p. ej.), a un lado
	# y a otro de la ruta, como tocaría quien juega (más al centro de la calle)
	for lado in [[0.0], [0.7, -0.7, 1.4, -1.4]]:
		for j in cand:
			var w0 := _suelo(Vector3(ruta[j].x, 0.0, ruta[j].y))
			var n := Vector3(-(w0.z - k.z), 0.0, w0.x - k.x).normalized()
			for off in lado:
				var w := _suelo(w0 + n * off)
				if _plana(k, w) > MAX_RECTA or _plana(k, w) < 0.2:
					diag["lejos"] += 1
					continue
				if not _recta_libre(k, w, false):
					diag["rejilla"] += 1
					continue
				var r: Variant = _probar_toque(k, w, diag)
				if r != null:
					return r
	_diag_toque = "ruta %d puntos (%.1f m); %s" % [ruta.size(), _largo(ruta), str(diag)]
	return null


# Tocar donde se ve «w»: [destino previsto, posición en pantalla] si el toque cae ahí (a menos de 0,5 m) y se anda recto.
func _probar_toque(k: Vector3, w: Vector3, diag: Dictionary) -> Variant:
	var cam: Camera3D = v.cam
	for alto in [0.0, 0.3]:                        # (en una rampa, tocar un poco por encima también cae ahí)
		var q := w + Vector3(0.0, alto, 0.0)
		if cam.is_position_behind(q):
			diag["detras"] += 1
			continue
		var pp := cam.unproject_position(q)
		if not _se_puede_tocar(pp):
			diag["no_tocable"] += 1
			continue
		var d = v._ajustar_destino(v._punto_suelo(pp))
		if d == null:
			diag["cae_null"] += 1
			continue
		if _plana(d, w) > 0.5:
			diag["cae_lejos"] += 1
			if not diag.has("ej"):
				diag["ej"] = "toca %s, cae en %s (%s)" % [_txt(w), _txt(d), _golpe(pp)]
			continue
		if not _recta_libre(k, d):
			diag["recta"] += 1
			continue
		return [d, pp]
	return null


# Qué frena a Kael en k yendo hacia «hacia» (lo mismo que mira ciudad._altura_suelo: lo andable, el escalón y el rayo a
# las rodillas), para el informe.
func _freno(k: Vector3, hacia: Vector3) -> String:
	var dir := Vector3(hacia.x - k.x, 0.0, hacia.z - k.z).normalized()
	var sig := k + dir * 0.15
	if not P.andable(sig.x, sig.z):
		return "no andable delante (%s)" % _que_hay(sig)
	if absf(P.altura(sig.x, sig.z) - k.y) > 0.5:
		return "escalón de %.2f m" % (P.altura(sig.x, sig.z) - k.y)
	var desde := Vector3(k.x, k.y + 0.6, k.z)
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(desde, desde + dir * 0.45))
	if not r.is_empty():
		var p: Vector3 = r["position"]
		return "el rayo de las rodillas da en %s en %s" % [(r["collider"] as Node).name, _txt(p)]
	return "nada a la vista (¿atasco de 1 s de vista3d?)"


# Lo primero que encuentra el rayo del toque (para el informe).
func _golpe(pp: Vector2) -> String:
	var cam: Camera3D = v.cam
	var desde := cam.project_ray_origin(pp)
	var r: Dictionary = v.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(desde, desde + cam.project_ray_normal(pp) * 500.0))
	if r.is_empty():
		return "nada"
	var p: Vector3 = r["position"]
	return "%s en %s, suelo del plano %.2f" % [(r["collider"] as Node).name, _txt(p), P.altura(p.x, p.z)]


# Andar hasta «meta» con clics: toca el siguiente punto y, al acercarse a él, el siguiente (como quien juega). Devuelve
# {llega, falta, clics, motivo, segundos}.
func _andar_a(meta: Vector3, cerca := LLEGA, foto_en = null, foto_nombre := "") -> Dictionary:
	var f0 := Engine.get_process_frames()
	var largo := _largo(_ruta(_kael(), meta))
	var limite := int(((largo / 4.2) * 1.6 + 6.0) * FPS)
	var clics := 0
	var paradas := 0
	var objetivo = null
	var ultimo_toque := -100
	var motivo := ""
	var foto_hecha := foto_en == null
	var freno := ""
	var f := 0
	while f < limite:
		if not _vivo():
			motivo = "la escena no está"
			break
		var k := _kael()
		if _plana(k, meta) < cerca:
			break
		if not foto_hecha and _plana(k, foto_en) < 1.2:
			foto_hecha = true
			_vis_en_marcha()
			await _foto(foto_nombre)
		var parado: bool = v.destino == null
		var cerca_obj: bool = objetivo != null and _plana(k, objetivo) < 1.2 and _plana(objetivo, meta) > 0.1
		if parado or (cerca_obj and f - ultimo_toque > 6):
			if parado and objetivo != null and _plana(k, objetivo) > 0.4:
				paradas += 1                           # se paró antes del punto tocado (algo lo frenó)
				freno = _freno(k, objetivo)
			if paradas > 6:
				motivo = "se para antes de donde se toca (%d veces; la última en %s hacia %s: %s)" % [paradas, _txt(k), _txt(objetivo), freno]
				break
			var s: Variant = _siguiente_toque(meta)
			if s == null:
				if parado:
					motivo = "no hay sitio que tocar hacia %s desde %s: %s" % [_txt(meta), _txt(k), _diag_toque]
					break
			elif not parado and _plana(s[0], meta) > _plana(objetivo, meta) - 0.5:
				ultimo_toque = f                       # (no hay un sitio más adelante que el ya tocado: sigue andando)
			else:
				objetivo = s[0]
				await _clic(s[1])
				clics += 1
				ultimo_toque = f
				f += 4
				if f % 15 < 4:
					_vis_en_marcha()
				continue
		await _frames(2)
		f += 2
		if f % 16 < 2:
			_vis_en_marcha()
	if f >= limite and motivo == "":
		motivo = "tiempo agotado (%.0f s)" % (limite / FPS)
	var falta := _plana(_kael(), meta) if _vivo() else INF
	return {"llega": falta < cerca + 0.15, "falta": falta, "clics": clics, "motivo": motivo,
		"segundos": (Engine.get_process_frames() - f0) / FPS, "esperado": largo / 4.2}


func _txt(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


# ================================================================= comprobaciones en cada parada

# "" si Kael se ve; si no, por qué. Cabeza y pies en el cuadro; entre la cámara y la cabeza, nada sin aclarar (lo que la
# escena aclara: los ocultables de los sectores MONTADOS; la maqueta lejana de los no montados no se aclara).
func _visibilidad() -> String:
	var cam: Camera3D = v.cam
	var k := _kael()
	var cabeza := k + Vector3(0.0, Comun.ALTO_CABEZA, 0.0)
	var vista := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for q in [cabeza, k + Vector3(0.0, 0.05, 0.0)]:
		if cam.is_position_behind(q) or not vista.has_point(cam.unproject_position(q)):
			return "fuera del cuadro (%s en %s)" % [_txt(q), str(cam.unproject_position(q))]
	var desde := cam.global_position
	var mal: Array = []
	var claro: Material = Blockout.material(true)
	for s in P.ORDEN:
		var t = P.trazado(s)
		var montado = v.cargador.montados.get(s)
		for x in Comun.tapan(t.BLOQUES, t.OCULTABLES, desde, cabeza):
			var id: String = x[0]
			if montado != null:
				if x[1]:
					var mi = montado.get_node_or_null("Ocultable_" + id)
					if mi == null or mi.material_override != claro:
						mal.append("%s/%s sin aclarar" % [s, id])
				else:
					mal.append("%s/%s (no ocultable)" % [s, id])
			else:
				for b in t.BLOQUES:
					if b[0] == id and float(b[4]) >= v.cargador.ALTO_LEJANA and String(b[5]) != "puerta":
						mal.append("%s/%s en la maqueta lejana (sector sin montar)" % [s, id])
	for su in P.suelos_que_tapan(k):
		mal.append("suelo " + su)
	# (16/11, arreglos) la cintura y los pies: lo ocultable que los tapa ha de estar aclarado (antes la escena solo miraba
	# la cabeza y una hoja de puerta o una lona dejaban a Kael asomando la cabeza)
	for h in [0.8, 0.25]:
		for x in _sin_aclarar(desde, k + Vector3(0.0, h, 0.0)):
			mal.append("%s sin aclarar a %.2f m" % [x, h])
	return ", ".join(mal)


# Lo ocultable de los sectores montados que corta el rayo desde → p sin estar aclarado.
func _sin_aclarar(desde: Vector3, p: Vector3) -> Array:
	var r: Array = []
	var claro: Material = Blockout.material(true)
	for s in v.cargador.montados:
		var t = P.trazado(s)
		for x in Comun.tapan(t.BLOQUES, t.OCULTABLES, desde, p):
			if x[1]:
				var mi = v.cargador.montados[s].get_node_or_null("Ocultable_" + String(x[0]))
				if mi == null or mi.material_override != claro:
					r.append("%s/%s" % [s, x[0]])
	return r


# (16/11, arreglos) El grupo, ya parado: a su cabeza y su cintura, nada ocultable sin aclarar (si está a < 8 m de Kael).
func _grupo_visible() -> String:
	if v.grupo == null:
		return ""
	var mal: Array = []
	var desde: Vector3 = v.cam.global_position
	for n in v.grupo.nodos():
		var g: Vector3 = (n as Node3D).global_position
		if _plana(g, _kael()) >= 8.0:
			continue
		for h in [1.4, 0.8]:
			for x in _sin_aclarar(desde, g + Vector3(0.0, h, 0.0)):
				mal.append("%s: %s sin aclarar a %.1f m" % [n.name, x, h])
	return ", ".join(mal)


func _vis_en_marcha() -> void:
	if not _vivo():
		return
	var r := _visibilidad()
	if r != "":
		_vis_marcha += 1
		if _vis_marcha_txt == "":
			_vis_marcha_txt = "en %s: %s" % [_txt(_kael()), r]


# El grupo, tras pararse Kael: cada uno sobre lo andable y a menos de GRUPO_LEJOS (espera hasta 2,5 s).
func _grupo() -> Dictionary:
	if v.grupo == null or v.grupo.nodos().is_empty():
		return {"ok": true, "txt": "sin grupo", "lejos": 0.0}
	var peor := 0.0
	var malo := ""
	for intento in 5:
		await _segundos(0.5)
		peor = 0.0
		malo = ""
		for n in v.grupo.nodos():
			var g: Vector3 = (n as Node3D).global_position
			var d := _plana(g, _kael())
			peor = maxf(peor, d)
			if not _andable_grupo(g):
				malo = "%s fuera de lo andable en %s (%s)" % [n.name, _txt(g), _que_hay(g)]
			elif d > GRUPO_LEJOS:
				malo = "%s a %.1f m" % [n.name, d]
		if malo == "":
			break
	return {"ok": malo == "", "txt": malo, "lejos": peor}


# ================================================================= tramos

func _empezar_tramo() -> void:
	_t = {"activo": true}
	_previas.clear()
	_vis_marcha = 0
	_vis_marcha_txt = ""
	if _vivo():
		v.perfil_fps = 0                           # (sin tope de FPS: no se mide; el tiempo lo fija --fixed-fps)


# Cierra un tramo: comprueba y escribe su línea. «r»: lo que devolvió _andar_a (o el equivalente).
func _cerrar_tramo(sector: String, tipo: String, nombre: String, r: Dictionary, foto := false, extra_mal := "") -> bool:
	tramos += 1
	var n := tramos
	var mal: Array = []
	if extra_mal != "":
		mal.append(extra_mal)
	if not _vivo():
		if tipo != "banco":
			mal.append("la escena no está")
	else:
		await _frames(10)
		if not bool(r.get("llega", true)):
			mal.append("no llega (a %.2f m; %s)" % [float(r.get("falta", 0.0)), r.get("motivo", "")])
		if float(r.get("segundos", 0.0)) > float(r.get("esperado", 0.0)) * 1.6 + 6.0 and r.has("esperado"):
			mal.append("lento: %.1f s (≈ %.1f)" % [r["segundos"], r["esperado"]])
		if int(_t.get("kael_fuera", 0)) > 0:
			mal.append("Kael pisa lo no andable %d veces (%s)" % [_t["kael_fuera"], _t.get("kael_donde", "")])
		if float(_t.get("max_dy", 0.0)) > 0.15:
			mal.append("Kael fuera del suelo del plano (%.2f m)" % _t["max_dy"])
		var vis := _visibilidad()
		if vis != "":
			mal.append("Kael no se ve: " + vis)
		var g: Dictionary = await _grupo()
		if not g["ok"]:
			mal.append("grupo: " + g["txt"])
		var gv := _grupo_visible() if _vivo() else ""
		if gv != "":
			mal.append("grupo tapado: " + gv)
		if int(_t.get("grupo_fuera", 0)) > 15:
			mal.append("grupo fuera de lo andable %d fotogramas (%s)" % [_t["grupo_fuera"], _t.get("grupo_donde", "")])
		r["grupo"] = g["lejos"]
	var avisos := ""
	if _vis_marcha > 0:
		avisos += " · aviso: no se ve %d veces en marcha (%s)" % [_vis_marcha, _vis_marcha_txt]
	if int(_t.get("saltos", 0)) > 0:
		avisos += " · aviso: el grupo reaparece %d veces" % _t["saltos"]
	if int(_t.get("grupo_fuera", 0)) > 0 and int(_t.get("grupo_fuera", 0)) <= 15:
		avisos += " · aviso: grupo fuera de lo andable %d fotogramas (%s)" % [_t["grupo_fuera"], _t.get("grupo_donde", "")]
	var archivo := ""
	if _vivo() and (foto or (not mal.is_empty() and fotos_fallo < MAX_FOTOS_FALLO)):
		if not mal.is_empty() and not foto:
			fotos_fallo += 1
		archivo = await _foto("%s_%s_%s%s" % [sector, tipo, nombre, "_FALLO" if not mal.is_empty() else ""])
	var linea := "TRAMO %03d [%s] %s «%s»: %s en %.1f s, %d clic(s), falta %.2f m, grupo a %.1f m, %d aclarados%s%s" % [
		n, sector, tipo, nombre, "llega" if bool(r.get("llega", true)) else "NO LLEGA", float(r.get("segundos", 0.0)),
		int(r.get("clics", 0)), float(r.get("falta", 0.0)), float(r.get("grupo", 0.0)),
		int(v.aclarados) if _vivo() else 0, (" · foto " + archivo) if archivo != "" else "", avisos]
	_t = {}
	if mal.is_empty():
		_nota(linea + " — OK")
		return true
	fallos += 1
	_nota("FALLO: " + linea + " — " + "; ".join(mal))
	return false


# Un tramo andando con clics hasta «meta».
func _tramo(sector: String, tipo: String, nombre: String, meta: Vector3, foto := false, cerca := LLEGA, foto_en = null) -> bool:
	_empezar_tramo()
	var r: Dictionary = await _andar_a(_suelo(meta), cerca, foto_en, "%s_%s_%s_medio" % [sector, tipo, nombre])
	return await _cerrar_tramo(sector, tipo, nombre, r, foto)


func _ancla(sector: String, id: String) -> Vector3:
	return P.trazado(sector).ancla(id)


# ================================================================= lo que se recorre

# Las teclas de dirección: la Calle Mayor hacia el norte, a la izquierda, a la derecha y atrás.
func _tramo_teclas() -> void:
	for paso in [[KEY_UP, 4.0, Vector2(0, -1)], [KEY_LEFT, 0.6, Vector2(-1, 0)], [KEY_RIGHT, 1.2, Vector2(1, 0)], [KEY_DOWN, 1.0, Vector2(0, 1)]]:
		_empezar_tramo()
		var k0 := _kael()
		var f0 := Engine.get_process_frames()
		_tecla(paso[0], true)
		await _segundos(paso[1])
		_tecla(paso[0], false)
		await _frames(6)
		var d := Vector2(_kael().x - k0.x, _kael().z - k0.z)
		var esperado: float = 4.2 * float(paso[1])
		var hacia: float = d.dot(paso[2])
		var nombre := "tecla %s %.1f s" % [OS.get_keycode_string(paso[0]), paso[1]]
		var r := {"llega": hacia > esperado * 0.75 and absf(d.cross(paso[2])) < 0.5, "falta": maxf(0.0, esperado - hacia),
			"clics": 0, "segundos": (Engine.get_process_frames() - f0) / FPS,
			"motivo": "avanza %.2f m hacia donde se pulsa (≈ %.1f) y %.2f de lado" % [hacia, esperado, d.cross(paso[2])]}
		await _cerrar_tramo(P.sector_de(_kael().x, _kael().z), "teclas", nombre, r, paso[0] == KEY_UP)
	_contar("teclas")


# Una conexión de lado «de» al otro, a 4 m del borde (y «veces» seguidas: ida, vuelta, ida…).
func _conexion(id: String, de: String, veces := 3) -> void:
	var con := P.conexion(id)
	var lados := [de, "b" if de == "a" else "a"]
	var inicio := P.punto_conexion(con, lados[0], 4.0)
	await _tramo(String(con[lados[0]]), "ir", "a la %s" % con["nombre"], inicio)
	for i in veces:
		var a: String = lados[i % 2]
		var b: String = lados[(i + 1) % 2]
		var ok := await _tramo(String(con[b]), "conexion", "%s: %s → %s" % [con["nombre"], con[a], con[b]],
			P.punto_conexion(con, b, 4.0), i == 0, LLEGA, P.centro_conexion(con) if i == 0 else null)
		if ok:
			sentidos["%s:%s>%s" % [id, con[a], con[b]]] = true


# Las paradas de un sector: escaleras/rampas (ida y vuelta), cubiertas, puertas, sin salida y atajos.
func _paradas(s: String) -> Array:
	var t = P.trazado(s)
	var r: Array = []
	for i in t.SUELOS.size():
		var su: Array = t.SUELOS[i]
		if String(su[2]) == "":
			continue
		var e: Variant = _extremos_rampa(su)
		if e == null:
			_nota("AVISO [%s] la rampa %d %s no tiene una recta andable de punta a punta: no se recorre" % [s, i, str(su[1])])
			continue
		r.append({"tipo": "escalera", "nombre": "suelo %d %s %.1f→%.1f" % [i, su[2], su[3], su[4]], "p": e[0], "b": e[1], "medio": e[2]})
	if not rapido:
		for b in t.BLOQUES:
			if String(b[5]) != "cubierta":
				continue
			var p: Variant = _bajo_cubierta(s, b)
			if p == null:
				_nota("AVISO [%s] la cubierta %s no tiene suelo andable debajo: no se recorre" % [s, b[0]])
				_contar("cubierta_sin_suelo")
				continue
			r.append({"tipo": "cubierta", "nombre": "%s (%s)" % [b[0], _clase_cubierta(String(b[0]))], "p": p})
		for pid in t.PUERTAS:
			r.append({"tipo": "puerta", "nombre": pid, "p": t.PUERTAS[pid]["fuera"], "pid": pid})
	for x in SIN_SALIDA.get(s, []):
		r.append({"tipo": "sin_salida", "nombre": x[0], "p": _ancla(s, x[2]), "fondo": _ancla(s, x[1])})
	for x in ATAJOS.get(s, []):
		var pts: Array = []
		for a in x[1]:
			pts.append(_ancla(s, a))
		r.append({"tipo": "atajo", "nombre": x[0], "p": pts[0], "pts": pts})
	return r


func _clase_cubierta(id: String) -> String:
	for par in [["soportal", "soportal"], ["corredor", "corredor cubierto"], ["paso", "paso bajo edificio"], ["pasaje", "paso bajo edificio"],
			["puente", "paso bajo edificio"], ["arco", "arco"], ["dintel", "arco"], ["portico", "arco"], ["toldo", "toldo"],
			["lona", "toldo"], ["tendedero", "tendedero"], ["pergola", "pérgola"], ["tejadillo", "alero"], ["porche", "alero"],
			["lonja", "alero"], ["techo", "paso cubierto"], ["cubierta", "paso cubierto"]]:
		if par[0] in id:
			return par[1]
	return "cubierta"


# Los extremos de una rampa: un poco fuera de cada punta (en el suelo de al lado) si se pisa, si no dentro; la recta de
# punta a punta, libre. [a, b, medio] o null.
func _extremos_rampa(su: Array) -> Variant:
	var r: Rect2 = su[1]
	var eje: String = su[2]
	var largo := r.size.y if eje == "z" else r.size.x
	var ancho := r.size.x if eje == "z" else r.size.y
	var c := r.get_center()
	var offs: Array = [0.0]
	var o := 0.5
	while o < ancho * 0.5 - 0.3:
		offs.append(o)
		offs.append(-o)
		o += 0.5
	for off in offs:
		var a = null
		var b = null
		for fuera in [1.0, 0.6, 0.3, -0.3, -0.6]:
			var pa := Vector3(c.x + off, 0, r.position.y - fuera) if eje == "z" else Vector3(r.position.x - fuera, 0, c.y + off)
			if a == null and P.andable(pa.x, pa.z) and (fuera > 0.0 or largo > 1.4):
				a = _suelo(pa)
			var pb := Vector3(c.x + off, 0, r.end.y + fuera) if eje == "z" else Vector3(r.end.x + fuera, 0, c.y + off)
			if b == null and P.andable(pb.x, pb.z) and (fuera > 0.0 or largo > 1.4):
				b = _suelo(pb)
		if a == null or b == null:
			continue
		var m := Vector3(c.x + off, 0, c.y) if eje == "z" else Vector3(c.x, 0, c.y + off)
		m = _suelo(m)
		# (solo lo andable y sin escalones: el tramo se anda por la ruta, no hace falta que sea una sola recta de un toque)
		if _recta_libre(a, m, true, false) and _recta_libre(m, b, true, false):
			return [a, b, m]
	return null


# Un punto andable bajo una cubierta (lo más cerca de su centro), con la cubierta por encima de la cabeza.
func _bajo_cubierta(s: String, b: Array) -> Variant:
	var r: Rect2 = b[2]
	# (dentro, a 0,3 m del borde; una cuerda de tendedero de 0,1 m, en una franja de 0,6 m bajo ella)
	var mx := -0.3 if r.size.x > 1.0 else maxf(0.0, (0.6 - r.size.x) * 0.5)
	var mz := -0.3 if r.size.y > 1.0 else maxf(0.0, (0.6 - r.size.y) * 0.5)
	r = r.grow_individual(mx, mz, mx, mz)
	var mejor = null
	var dmin := INF
	var c := r.get_center()
	var x := r.position.x + 0.125
	while x < r.end.x:
		var z := r.position.y + 0.125
		while z < r.end.y:
			if P.andable(x, z) and P.sector_en_caja(x, z) == s and float(b[3]) > P.altura(x, z) + 1.6:
				# lo más lejos posible de lo que no se pisa (hasta 0,75 m: Kael se para 0,3 m antes de una caja) y, a
				# igual holgura, lo más cerca del centro
				var d := Vector2(x, z).distance_to(c) - _holgura(x, z) * 100.0
				if d < dmin:
					dmin = d
					mejor = Vector3(x, 0, z)
			z += 0.25
		x += 0.25
	if mejor == null:
		return null
	return _suelo(mejor)


# Cuánto sitio andable hay alrededor de (x, z): 0, 0,25, 0,5 o 0,75 m (ocho direcciones).
func _holgura(x: float, z: float) -> float:
	var h := 0.0
	for r in [0.25, 0.5, 0.75]:
		for i in 8:
			var a := TAU * i / 8.0
			if not P.andable(x + cos(a) * r, z + sin(a) * r):
				return h
		h = r
	return h


# ¿Está alguien del grupo sobre lo andable? (con 0,12 m de tolerancia: el rastro que sigue son puntos de Kael cada
# 0,2 m y la cuerda entre dos de ellos, al doblar una esquina, la roza)
func _andable_grupo(g: Vector3) -> bool:
	if P.andable(g.x, g.z):
		return true
	for i in 8:
		var a := TAU * i / 8.0
		if P.andable(g.x + cos(a) * 0.12, g.z + sin(a) * 0.12):
			return true
	return false


func _visitar(s: String) -> void:
	if not solo.is_empty() and not s in solo:
		return
	_nota("== SECTOR %s (%s)" % [s, P.SECTORES[s]["nombre"]])
	_contar("sectores")
	var lista := _paradas(s)
	var hecho := 0
	var recargado := false
	while not lista.is_empty():
		var k := _kael()
		var mejor := 0
		var dmin := INF
		for i in lista.size():
			var d := _plana(k, lista[i]["p"])
			if d < dmin:
				dmin = d
				mejor = i
		var x: Dictionary = lista.pop_at(mejor)
		await _parada(s, x)
		hecho += 1
		if not recargado and hecho * 2 >= lista.size() + hecho:   # a mitad del sector: «Guardar y recargar»
			recargado = true
			await _recargar(s)
	if not recargado:
		await _recargar(s)


func _parada(s: String, x: Dictionary) -> void:
	match String(x["tipo"]):
		"escalera":
			await _tramo(s, "ir", "al pie de " + x["nombre"], x["p"])
			if await _tramo(s, "escalera", x["nombre"] + " ida", x["b"], false, LLEGA, x["medio"]):
				_contar("escaleras_ida")
			if await _tramo(s, "escalera", x["nombre"] + " vuelta", x["p"]):
				_contar("escaleras_vuelta")
		"cubierta":
			if await _tramo(s, "cubierta", x["nombre"], x["p"], true, 0.4):
				_contar("cubiertas")
		"puerta":
			await _puerta(s, x["pid"])
		"sin_salida":
			await _tramo(s, "ir", "a la entrada de " + x["nombre"], x["p"])
			var ok := await _tramo(s, "sin_salida", x["nombre"] + " (entrar)", x["fondo"], true)
			ok = await _tramo(s, "sin_salida", x["nombre"] + " (volver)", x["p"]) and ok
			if ok:
				_contar("sin_salida")
		"atajo":
			await _tramo(s, "ir", "al principio de " + x["nombre"], x["p"])
			var ok := true
			var pts: Array = x["pts"]
			for i in range(1, pts.size()):
				ok = await _tramo(s, "atajo", "%s (%d/%d)" % [x["nombre"], i, pts.size() - 1], pts[i], i == pts.size() / 2) and ok
			if ok:
				_contar("atajos")


# Una puerta prevista: acercarse, que el botón ofrezca su texto, pulsarlo (clic) y que diga «en obras».
func _puerta(s: String, pid: String) -> void:
	var d: Dictionary = P.trazado(s).PUERTAS[pid]
	_empezar_tramo()
	var r: Dictionary = await _andar_a(_suelo(d["fuera"]), 0.35)
	var esperado := "entrar_%s/%s" % [s, pid]
	var f := 0
	while f < 45 and not (v.boton_accion.visible and v.cerca == esperado):
		await _frames(3)
		f += 3
	var mal := ""
	if not (v.boton_accion.visible and v.cerca == esperado and v.boton_accion.text == d["texto"]):
		mal = "el botón no ofrece «%s» (cerca «%s», botón «%s», visible %s)" % [d["texto"], v.cerca, v.boton_accion.text, v.boton_accion.visible]
	else:
		v.ultimo_aviso = ""
		await _pulsar(v.boton_accion, func(): return v.ultimo_aviso == v.TEXTO_OBRAS, 1.5)
		if v.ultimo_aviso != v.TEXTO_OBRAS:
			mal = "al pulsar «%s» el aviso es «%s»" % [d["texto"], v.ultimo_aviso]
	var primera := int(cuenta.get("puertas_" + s, 0)) == 0
	if await _cerrar_tramo(s, "puerta", "%s: %s" % [pid, d["texto"]], r, primera, mal):
		_contar("puertas")
		_contar("puertas_" + s)


# «Guardar y recargar» (clic en su botón): Kael reaparece donde estaba, en el mismo sector, con el grupo.
func _recargar(s: String) -> void:
	_empezar_tramo()
	var k := _kael()
	var viejo = v
	var f0 := Engine.get_process_frames()
	var R0 = root.get_node_or_null("Recursos")
	await _pulsar(v.boton_recargar, func(): return R0.cambiando or current_scene != viejo, 3.0)
	var t0 := Time.get_ticks_msec()                # (esperas en tiempo REAL: sin tope de FPS, 300 fotogramas son 2 s)
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if current_scene != viejo and current_scene != null and current_scene.scene_file_path == ESCENA:
			break
	await _cargar_ciudad()
	var mal := ""
	if not _vivo() or v == viejo:
		mal = "«Guardar y recargar» no vuelve a cargar la ciudad"
	elif _plana(_kael(), k) > 1.0 or P.sector_de(_kael().x, _kael().z) != s:
		mal = "Kael no reaparece donde estaba (%s → %s)" % [_txt(k), _txt(_kael())]
	var r := {"llega": mal == "", "falta": _plana(_kael(), k) if _vivo() else INF, "segundos": (Engine.get_process_frames() - f0) / FPS}
	if await _cerrar_tramo(s, "recarga", "Guardar y recargar en %s" % _txt(k), r, true, mal):
		_contar("recargas")


# «Volver al banco» (clic) y, en el banco, el caso de la ciudad (clic): Kael entra por el patio de caravanas.
func _volver_al_banco(y_entrar: bool) -> void:
	_empezar_tramo()
	var f0 := Engine.get_process_frames()
	var b := _boton_banco()
	var mal := ""
	if b == null or not b.is_visible_in_tree():
		mal = "no se ve «Volver al banco»"
	else:
		var R0 = root.get_node_or_null("Recursos")
		await _pulsar(b, func(): return R0.cambiando or (current_scene != null and current_scene.scene_file_path == BANCO), 3.0)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 30000:
			await process_frame
			if current_scene != null and current_scene.scene_file_path == BANCO:
				break
		await _segundos(1.0)
		if current_scene == null or current_scene.scene_file_path != BANCO:
			var R = root.get_node_or_null("Recursos")
			mal = "«Volver al banco» no lleva al banco (escena «%s», cambiando %s)" % [
				current_scene.scene_file_path if current_scene != null else "", R.cambiando if R != null else "?"]
	var r := {"llega": mal == "", "segundos": (Engine.get_process_frames() - f0) / FPS}
	v = null
	if mal == "":
		_contar("volver_al_banco")
		if y_entrar:
			mal = await _entrar_desde_el_banco()
	await _cerrar_tramo("banco", "banco", "Volver al banco" + (" y entrar otra vez" if y_entrar else ""), r, true, mal)


func _entrar_desde_el_banco() -> String:
	var BP = load("res://banco_pruebas.gd")
	var titulo: String = BP.EXPLORAR["ciudad"]["titulo"]
	var b: Button = null
	for x in current_scene.find_children("*", "Button", true, false):
		if (x as Button).text == titulo:
			b = x
	if b == null:
		return "el banco no tiene el caso «%s»" % titulo
	current_scene.marco.ensure_control_visible(b)
	await _frames(6)
	var R0 = root.get_node_or_null("Recursos")
	await _pulsar(b, func(): return R0.cambiando or (current_scene != null and current_scene.scene_file_path == ESCENA), 3.0)
	if not await _cargar_ciudad():
		return "el caso de la ciudad no la abre"
	if _plana(_kael(), P.ancla("inicio")) > 0.5:
		return "Kael no entra por el patio de caravanas (%s)" % _txt(_kael())
	return ""


func _cargar_ciudad() -> bool:
	v = null
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		await process_frame
		var c = current_scene
		if c != null and c.scene_file_path == ESCENA and c.get("kael") != null and c.get("cargador") != null:
			v = c
			break
	if v == null:
		return false
	await _segundos(1.0)
	v.perfil_fps = 0
	return true


# La Puerta del Sur: andar hasta ella (junto a la muralla sur), su botón dice que en la maqueta no se sale.
func _puerta_del_sur() -> void:
	_empezar_tramo()
	var r: Dictionary = await _andar_a(P.ancla("puerta_sur"), 0.4)
	var mal := ""
	var f := 0
	while f < 45 and not (v.boton_accion.visible and v.cerca == "puerta_sur"):
		await _frames(3)
		f += 3
	if not (v.boton_accion.visible and v.cerca == "puerta_sur"):
		mal = "el botón de la Puerta del Sur no sale (cerca «%s»)" % v.cerca
	else:
		v.ultimo_aviso = ""
		await _pulsar(v.boton_accion, func(): return v.ultimo_aviso == v.TEXTO_SALIDA, 1.5)
		if v.ultimo_aviso != v.TEXTO_SALIDA or current_scene != v:
			mal = "la Puerta del Sur: «%s»" % v.ultimo_aviso
	if await _cerrar_tramo("puerta_sur", "puerta_sur", "Puerta del Sur (junto a la muralla)", r, true, mal):
		_contar("puerta_del_sur")


# ================================================================= el recorrido

func _jugar() -> void:
	await _frames(3)
	_nota("ventana %s, viewport %s, transformación ventana←viewport %s, perfil %s" % [root.size, root.get_visible_rect().size,
		root.get_final_transform(), perfil])
	_preparar_rejilla()
	Engine.set_meta("calidad_proto", perfil)
	change_scene_to_file(BANCO)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == BANCO and current_scene.get("marco") != null:
			break
	await _segundos(1.0)
	var mal := await _entrar_desde_el_banco()
	if mal != "" or not _vivo():
		_nota("FALLO: no se entra en la ciudad: " + mal)
		fallos += 1
		_terminar()
		return
	await _foto("00_entrada")
	_nota("== ENTRADA: Kael en %s, %d de 8 sectores montados, grupo %d" % [_txt(_kael()), v.cargador.montados.size(),
		v.grupo.nodos().size() if v.grupo != null else 0])
	await _tramo_teclas()
	await _visitar("puerta_sur")
	await _puerta_del_sur()
	await _conexion("calle_mayor", "a")
	await _visitar("plaza_tapiz")
	await _conexion("calle_mercado", "a")
	await _visitar("oficios")
	await _conexion("escalera_molino", "a")
	await _visitar("ribera")
	await _conexion("rampa_carros", "b")
	await _volver_al_banco(true)
	await _conexion("arco_pasajes", "b")
	await _visitar("pasajes")
	await _conexion("paso_botica", "a", 2)
	await _conexion("pasaje_velas", "b")
	await _visitar("cuervo")
	await _conexion("calle_cuervo", "b", 2)
	await _conexion("escaleras_terrazas", "a")
	await _visitar("terrazas")
	await _conexion("terrazas_altas", "a")
	await _visitar("barrio_alto")
	await _conexion("subida_colina", "b", 2)
	await _conexion("calle_arbol", "b")
	await _tramo("plaza_tapiz", "ir", "a la Calle Mayor", P.punto_conexion(P.conexion("calle_mayor"), "b", 4.0))
	await _conexion("calle_mayor", "b", 1)
	await _puerta_del_sur()
	await _volver_al_banco(false)
	_terminar()


func _terminar() -> void:
	var faltan: Array = []
	for con in P.CONEXIONES:
		for par in [[con["a"], con["b"]], [con["b"], con["a"]]]:
			if not sentidos.has("%s:%s>%s" % [con["id"], par[0], par[1]]):
				faltan.append("%s %s→%s" % [con["id"], par[0], par[1]])
	_nota("CUBIERTO: sectores %d/8, conexiones %d/24 sentidos%s, escaleras y rampas %d ida + %d vuelta, cubiertas %d (sin suelo debajo %d), puertas %d, sin salida %d, atajos %d, recargas %d, «Volver al banco» %d, Puerta del Sur %d, teclas %d" % [
		int(cuenta.get("sectores", 0)), sentidos.size(), (" (faltan " + ", ".join(faltan) + ")") if not faltan.is_empty() else "",
		int(cuenta.get("escaleras_ida", 0)), int(cuenta.get("escaleras_vuelta", 0)), int(cuenta.get("cubiertas", 0)),
		int(cuenta.get("cubierta_sin_suelo", 0)), int(cuenta.get("puertas", 0)), int(cuenta.get("sin_salida", 0)),
		int(cuenta.get("atajos", 0)), int(cuenta.get("recargas", 0)), int(cuenta.get("volver_al_banco", 0)),
		int(cuenta.get("puerta_del_sur", 0)), int(cuenta.get("teclas", 0))])
	_nota("botones pulsados otra vez porque el primer clic no entró: %d" % repetidos)
	_nota("RECORRIDO: %d tramos, %d fallos" % [tramos, fallos])
	if video:
		_nota("vídeo: %d fotogramas en %s" % [n_video, salida.path_join("video")])
	var f := FileAccess.open(salida.path_join("recorrido.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(registro) + "\nFALLOS: %d\n" % fallos)
		f.close()
	Blockout.soltar()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)
