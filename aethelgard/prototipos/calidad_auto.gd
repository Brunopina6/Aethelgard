extends RefCounted
# Calidad adaptable (encargo del usuario del 09/11: «30 FPS estables en calidad baja y media en los dispositivos
# objetivo»). Elige el perfil inicial de cada aparato, lo guarda y dice qué recortes lleva el ajuste dinámico.
# Los VALORES de cada perfil siguen en calidad_proto.gd (PERFILES); aquí solo hay reglas y datos de la elección.
#
#   1. Detección (detectar): con lo que Godot sabe del aparato (GPU, núcleos, memoria, pantalla, móvil o no) da un
#      perfil inicial PRUDENTE: en el móvil, «bajo» salvo GPU fuerte con memoria y núcleos de sobra («medio»); nunca
#      «alto» en un móvil. En el PC, «alto» con GPU dedicada (o desconocida, como hasta ahora), «medio» con gráfica
#      integrada y «bajo» con dibujo por software. 60 FPS solo se proponen con «alto», y como candidato A MEDIR: la
#      calibración (regulador_calidad.gd) los confirma o los baja a 30. En «bajo» y «medio» siempre son 30.
#   2. Persistencia: user://ajustes.cfg, sección [calidad] (el mismo archivo que el volumen y las regiones; no se
#      toca lo demás). Claves:
#        auto        true = «Automática» (por defecto); false = el jugador fijó el perfil
#        perfil      el perfil en uso: el que eligió el jugador, o (en automática) el que eligió el sistema
#        perfil_auto el que eligió el sistema (detección y calibración); se conserva aunque el jugador elija otro
#        fps         límite elegido por el jugador (30 o 60); sin la clave, lo decide el sistema
#        fps_auto    límite que decidió el sistema (60 solo con «alto» y medido)
#        calibrado   true cuando la calibración del perfil del sistema ya se hizo (con éxito o hasta «bajo»)
#        nivel, nivel_de  escalón del ajuste dinámico y el perfil al que pertenece (otro perfil: escalón 0)
#        aviso       perfil elegido A MANO que no llega a su presupuesto en este aparato (se avisa en Ajustes)
#        no_llega    el aparato no llega a 30 ni en «bajo» con todos los recortes (y su medida, en calidad.log)
#      Un ajustes.cfg antiguo sin [calidad] funciona igual que antes: «bajo» en el móvil y «alto» en el PC hasta que
#      la detección escribe la sección (solo en el juego de verdad: sin ventana, en las pruebas, no se escribe nada).
#   3. Recortes del ajuste dinámico (recortes): escalones en el orden que pidió el usuario: resolución 3D, sombras,
#      hierba y partículas, distancias. Cada escalón es un dato (ESCALONES). Los que no cambian nada en un perfil
#      (las sombras del «bajo», que no tiene) se saltan. El perfil «alto» no tiene escalones: no se rebaja nunca
#      (norma del usuario); si no llega, la calibración o el regulador proponen «medio» para la próxima carga.

const AJUSTES := "user://ajustes.cfg"
const SECCION := "calidad"
const REGISTRO := "user://calidad.log"          # sucesos de la calidad (detección, calibración, avisos)
const REGISTRO_MAX := 64 * 1024                 # bytes: más allá, se empieza de nuevo
const ORDEN := ["bajo", "medio", "alto"]
const FPS_VALIDOS := [30, 60]

# --- detección (datos; en minúsculas, se buscan dentro del nombre de la GPU) ---
# Móvil: GPU que pueden con «medio» (de la medida del Redmi: Mali-G57 no puede con el medio de hoy, GPU-limitado).
const GPU_MOVIL_FUERTE := ["adreno (tm) 65", "adreno (tm) 66", "adreno (tm) 69", "adreno (tm) 7", "adreno (tm) 8",
	"adreno 7", "adreno 8", "mali-g78", "mali-g710", "mali-g715", "mali-g720", "mali-g725", "mali-g925", "immortalis",
	"xclipse", "apple"]
const MOVIL_MEDIO_MEMORIA_MB := 6000            # y además al menos estos MB de memoria…
const MOVIL_MEDIO_NUCLEOS := 8                  # …y estos núcleos
const MOVIL_PIXELES_GRANDE := 3500000           # pantalla QHD o más: más píxeles que pintar…
const MOVIL_GRANDE_MEMORIA_MB := 8000           # …solo «medio» con esta memoria (los punteros la traen)
# PC: dibujo por software (sin GPU de verdad) y gráficas integradas.
const GPU_SOFTWARE := ["llvmpipe", "softpipe", "swiftshader", "microsoft basic render"]
const GPU_INTEGRADA := ["intel(r) uhd", "intel(r) hd", "intel hd", "intel uhd", "intel(r) iris", "iris(r) xe",
	"intel(r) graphics", "radeon(tm) graphics", "radeon graphics", "radeon(tm) vega", "radeon vega", "adreno", "mali"]
const PC_NUCLEOS_ALTO := 4                      # con menos núcleos, como mucho «medio»

# --- recortes del ajuste dinámico (en orden; acumulativos) ---
# «escala_3d»: se resta (con suelo ESCALA_MIN; medio 0,8 → 0,75 → 0,7, lo que pidió el coordinador el 09/11 para las vistas
# lejanas, donde el medio nuevo da 27,7 FPS a 34 m). «*_f»: se multiplica. «sombra_tramos»: tope.
const ESCALONES := [
	{"nombre": "resolución 3D −0,05", "escala_3d": -0.05},
	{"nombre": "resolución 3D −0,05", "escala_3d": -0.05},
	{"nombre": "sombras más simples", "sombra_tramos": 1, "dist_sombras_f": 0.7},
	{"nombre": "menos hierba y partículas", "hierba_f": 0.7, "flores_f": 0.7, "espuma_f": 0.7},
	{"nombre": "distancias más cortas", "dist_hierba_f": 0.75, "dist_sombras_f": 0.8},
]
const ESCALA_MIN := 0.6


# ================================================================= detección

# Lo que Godot sabe del aparato. Todo con funciones de Godot fiables; lo que no se sepa, -1 o "".
static func datos_del_aparato() -> Dictionary:
	var mem := OS.get_memory_info()
	var fisica: int = int(mem.get("physical", -1))
	var tam := DisplayServer.screen_get_size()
	return {"movil": OS.has_feature("mobile"), "gpu": RenderingServer.get_video_adapter_name(),
		"fabricante": RenderingServer.get_video_adapter_vendor(), "nucleos": OS.get_processor_count(),
		"memoria_mb": int(fisica / 1048576) if fisica > 0 else -1, "pantalla": Vector2i(tam)}


# Perfil inicial prudente y su límite de FPS a partir de unos datos (los de datos_del_aparato o simulados).
# Devuelve {"perfil", "fps", "motivo"}. Nunca «alto» en un móvil; nunca 60 con «bajo» o «medio».
static func detectar(d: Dictionary) -> Dictionary:
	var gpu := (String(d.get("gpu", "")) + " " + String(d.get("fabricante", ""))).to_lower()
	var nucleos: int = int(d.get("nucleos", -1))
	var memoria: int = int(d.get("memoria_mb", -1))
	var pantalla: Vector2i = d.get("pantalla", Vector2i.ZERO)
	var pixeles: int = pantalla.x * pantalla.y
	var perfil := "bajo"
	var motivo := ""
	if bool(d.get("movil", false)):
		var fuerte := _contiene(gpu, GPU_MOVIL_FUERTE)
		if fuerte and memoria >= MOVIL_MEDIO_MEMORIA_MB and nucleos >= MOVIL_MEDIO_NUCLEOS:
			perfil = "medio"
			motivo = "móvil con GPU fuerte, %d MB y %d núcleos" % [memoria, nucleos]
			if pixeles > MOVIL_PIXELES_GRANDE and memoria < MOVIL_GRANDE_MEMORIA_MB:
				perfil = "bajo"
				motivo += "; pantalla de %d píxeles: bajo" % pixeles
		else:
			motivo = "móvil (GPU %s, %d MB, %d núcleos): bajo, el prudente" % [
				"fuerte" if fuerte else "modesta o desconocida", memoria, nucleos]
	elif _contiene(gpu, GPU_SOFTWARE):
		motivo = "PC sin GPU (dibujo por software)"
	elif _contiene(gpu, GPU_INTEGRADA):
		perfil = "medio"
		motivo = "PC con gráfica integrada"
	else:
		perfil = "alto"
		motivo = "PC con GPU dedicada o desconocida (como hasta ahora)"
		if nucleos > 0 and nucleos < PC_NUCLEOS_ALTO:
			perfil = "medio"
			motivo += ", pero %d núcleos: medio" % nucleos
	# 60 FPS solo como candidato de «alto»: la calibración los mide antes de quedárselos.
	return {"perfil": perfil, "fps": 60 if perfil == "alto" else 30, "motivo": motivo}


static func _contiene(texto: String, lista: Array) -> bool:
	for x in lista:
		if texto.contains(String(x)):
			return true
	return false


# ================================================================= ajustes guardados

static func _cargar(ruta: String) -> ConfigFile:
	var c := ConfigFile.new()
	if FileAccess.file_exists(ruta):
		c.load(ruta)
	return c


# Lo guardado en [calidad], con valores por defecto y saneado. «existe»: hay sección [calidad].
static func estado(ruta := AJUSTES) -> Dictionary:
	return estado_de(_cargar(ruta))


static func estado_de(c: ConfigFile) -> Dictionary:
	var e := {"existe": c.has_section(SECCION)}
	e["auto"] = _si_o(c.get_value(SECCION, "auto", true), true)
	e["perfil"] = _perfil_o(c.get_value(SECCION, "perfil", ""))
	e["perfil_auto"] = _perfil_o(c.get_value(SECCION, "perfil_auto", ""))
	e["fps"] = _fps_o(c.get_value(SECCION, "fps", 0))
	e["fps_auto"] = _fps_o(c.get_value(SECCION, "fps_auto", 0))
	e["calibrado"] = _si_o(c.get_value(SECCION, "calibrado", false), false)
	e["nivel"] = maxi(0, _entero_o(c.get_value(SECCION, "nivel", 0)))
	e["nivel_de"] = _perfil_o(c.get_value(SECCION, "nivel_de", ""))
	e["aviso"] = _perfil_o(c.get_value(SECCION, "aviso", ""))
	e["no_llega"] = _si_o(c.get_value(SECCION, "no_llega", false), false)
	return e


static func _perfil_o(v) -> String:
	var s := String(v) if v is String or v is StringName else ""
	return s if s in ORDEN else ""


static func _fps_o(v) -> int:
	var n := _entero_o(v)
	return n if n in FPS_VALIDOS else 0


static func _entero_o(v) -> int:
	return int(v) if (v is int or v is float) else 0


static func _si_o(v, defecto: bool) -> bool:
	return v if v is bool else defecto


# Escribe esas claves de [calidad] sin tocar el resto del archivo (volumen, mapa, regiones, Érebo).
static func guardar(claves: Dictionary, ruta := AJUSTES) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists(ruta):
		var err := c.load(ruta)
		if err != OK:
			return err
	for k in claves:
		if claves[k] == null:
			if c.has_section_key(SECCION, k):
				c.erase_section_key(SECCION, k)
		else:
			c.set_value(SECCION, k, claves[k])
	return c.save(ruta)


# ================================================================= qué perfil y qué FPS

# Perfil según lo guardado: el del jugador si lo fijó; si no, el del sistema; "" si aún no hay ninguno.
static func perfil_de(e: Dictionary) -> String:
	if not e["auto"] and e["perfil"] != "":
		return e["perfil"]
	return e["perfil_auto"]


# El perfil en uso fuera de las pruebas A/B (calidad_proto.actual() mira antes Engine y «-- movil»). Sin nada
# guardado: en el juego de verdad, detecta y lo guarda; sin ventana (pruebas), el de antes («legado»), sin escribir.
# («aparato»: datos simulados para las pruebas, que así comprueban también lo que se guarda en el juego de verdad.)
static func perfil_en_uso(legado: String, ruta := AJUSTES, aparato := {}) -> String:
	var e := estado(ruta)
	var p := perfil_de(e)
	if p != "":
		return p
	if DisplayServer.get_name() == "headless" and aparato.is_empty():
		return legado
	var d := detectar(aparato if not aparato.is_empty() else datos_del_aparato())
	guardar({"auto": e["auto"], "perfil": d["perfil"] if e["auto"] else e["perfil"], "perfil_auto": d["perfil"],
		"fps_auto": d["fps"], "calibrado": false}, ruta)
	registrar("detección: %s a %d FPS (%s; %s)" % [d["perfil"], d["fps"], d["motivo"], resumen_aparato()])
	return d["perfil"]


# Límite de FPS en uso para un perfil. El del jugador manda. Si no, 30 en «bajo» y «medio» siempre; en «alto», el
# que decidió el sistema (60 solo si se midió o está a medir) o, sin nada guardado, el de la tabla (como antes).
static func fps_de(perfil: String, e: Dictionary, fps_tabla: int) -> int:
	if e["fps"] != 0:
		return e["fps"]
	if perfil != "alto":
		return 30
	if e["fps_auto"] != 0:
		return e["fps_auto"]
	return fps_tabla


# Escalón del ajuste dinámico que vale para este perfil (solo en automática y si es de este perfil).
static func nivel_de(perfil: String, e: Dictionary) -> int:
	if not e["auto"] or e["nivel_de"] != perfil:
		return 0
	return mini(e["nivel"], escalones_utiles(perfil).size())


static func bajar(perfil: String) -> String:
	var i := ORDEN.find(perfil)
	return ORDEN[maxi(0, i - 1)] if i >= 0 else "bajo"


# ================================================================= recortes del ajuste dinámico

# Los escalones que cambian algo en este perfil (índices de ESCALONES). «alto»: ninguno, no se rebaja.
static func escalones_utiles(perfil: String) -> Array:
	var tabla: Dictionary = load("res://prototipos/calidad_proto.gd").PERFILES
	if perfil == "alto" or not tabla.has(perfil):
		return []
	var utiles: Array = []
	var antes: Dictionary = tabla[perfil].duplicate()
	for i in ESCALONES.size():
		var despues := _aplicar_escalon(antes, ESCALONES[i])
		if despues != antes:
			utiles.append(i)
		antes = despues
	return utiles


# Valores del perfil que cambian con «nivel» escalones útiles (solo las claves que cambian).
static func recortes(perfil: String, nivel: int) -> Dictionary:
	var tabla: Dictionary = load("res://prototipos/calidad_proto.gd").PERFILES
	if nivel <= 0 or not tabla.has(perfil):
		return {}
	var base: Dictionary = tabla[perfil]
	var d: Dictionary = base.duplicate()
	var utiles := escalones_utiles(perfil)
	for k in mini(nivel, utiles.size()):
		d = _aplicar_escalon(d, ESCALONES[utiles[k]])
	var cambios := {}
	for k in d:
		if d[k] != base[k]:
			cambios[k] = d[k]
	return cambios


static func _aplicar_escalon(antes: Dictionary, esc: Dictionary) -> Dictionary:
	var d := antes.duplicate()
	if esc.has("escala_3d"):
		d["escala_3d"] = snappedf(maxf(ESCALA_MIN, float(d["escala_3d"]) + float(esc["escala_3d"])), 0.01)
	var con_sombras: bool = bool(d.get("sombras", false))
	if con_sombras and esc.has("sombra_tramos"):
		d["sombra_tramos"] = mini(int(d.get("sombra_tramos", 4)), int(esc["sombra_tramos"]))
	for k in esc:
		var clave := String(k)
		if not clave.ends_with("_f"):
			continue
		var campo := clave.trim_suffix("_f")
		if not d.has(campo) or (campo == "dist_sombras" and not con_sombras):
			continue
		var v = d[campo]
		if v is int:
			d[campo] = int(round(v * float(esc[k])))
		else:
			d[campo] = snappedf(float(v) * float(esc[k]), 0.01)
	return d


static func nombre_escalon(perfil: String, nivel: int) -> String:
	var utiles := escalones_utiles(perfil)
	if nivel <= 0 or nivel > utiles.size():
		return ""
	return ESCALONES[utiles[nivel - 1]]["nombre"]


# ================================================================= registro

# Una línea en la consola y en user://calidad.log (para diagnosticar aparatos que no llegan).
static func registrar(texto: String) -> void:
	var linea := "%s  %s" % [Time.get_datetime_string_from_system(), texto]
	print("[calidad] ", texto)
	var f: FileAccess
	if FileAccess.file_exists(REGISTRO) and FileAccess.open(REGISTRO, FileAccess.READ).get_length() < REGISTRO_MAX:
		f = FileAccess.open(REGISTRO, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(REGISTRO, FileAccess.WRITE)
	if f != null:
		f.store_line(linea)


static func resumen_aparato() -> String:
	var d := datos_del_aparato()
	return "GPU «%s» de «%s», %d núcleos, %d MB, pantalla %dx%d, %s" % [d["gpu"], d["fabricante"], d["nucleos"],
		d["memoria_mb"], d["pantalla"].x, d["pantalla"].y, "móvil" if d["movil"] else "PC"]
