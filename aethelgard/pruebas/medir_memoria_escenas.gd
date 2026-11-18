extends SceneTree
# MEDIDA (17/11, agente de memoria), NO prueba (no va en lista_pruebas.txt): la memoria del BANCO DE PRUEBAS al volver de
# cada caso de EXPLORAR. En el Redmi (docs/v12/REDMI_16_11.md) el PSS del banco SUBÍA de un caso al siguiente
# (888 → 913 → 916 → 935 → 951 MB tras ciudad ×4, barrio, muestra, Arboleda y Sunken con la Quilla) y repetir la misma
# escena no crecía. Aquí se repite ese orden en el PC CON VENTANA (como una persona: la pantalla de carga con su
# precalentado, el botón «Banco de pruebas», clic en cada caso y clic en «Volver al banco») y, tras cada vuelta, se anota:
#   - Performance: MEMORY_STATIC, RENDER_VIDEO_MEM_USED, RENDER_TEXTURE_MEM_USED, RENDER_BUFFER_MEM_USED, OBJECT_COUNT,
#     OBJECT_RESOURCE_COUNT, OBJECT_NODE_COUNT y OBJECT_ORPHAN_NODE_COUNT;
#   - los archivos de res:// que siguen en la caché de ResourceLoader (has_cached), por carpeta, y lo que entra o sale
#     respecto a la vuelta anterior;
#   - los grupos de Recursos («comun» y «zona») y el tamaño de las cachés estáticas de cada región (muestra_calle, barrio,
#     interiores, utensilios, npc_chibi, kit_ciudad, blockout...).
# El ciclo completo se repite «ciclos» veces: si la 2.ª vuelta no crece es una caché que se llena una vez; si crece en
# cada vuelta, una fuga. Resultado de PC: NO certifica Android (el PSS del Redmi lleva además la memoria del controlador).
# Uso (APPDATA y LOCALAPPDATA en una carpeta aislada; la partida es la del banco, en user://):
#   Godot --path aethelgard --resolution 1600x720 --script res://pruebas/medir_memoria_escenas.gd -- salida=<carpeta fuera
#     del proyecto> [perfil=bajo] [ciclos=3] [casos=ciudad,barrio,muestra_calle,arboleda,sunken] [seg=5] [sin_carga]
#     [salir_banco] [experimento]
#   «salir_banco»: al final, «Salir del banco» y la memoria en la pantalla de carga (la portada vuelve a precalentar).
#   «experimento»: ya en el banco tras los ciclos, suelta una a una las cachés estáticas y los búferes 3D de la ventana y
#   anota cuánto baja cada vez (para atribuir lo que se queda; el juego no lo hace).
# Salida: memoria_escenas_<perfil>.txt (todo) y .csv (una fila por medida) en «salida».
# Documento: docs/v12/MEMORIA_ESCENAS_17_11.md.

const BANCO := "res://banco_pruebas.tscn"
const CARGA := "res://carga.tscn"
const MB := 1048576.0
# Cachés estáticas que se miran (script → variables). Solo si el script ya está en la caché (no se carga para mirar).
const ESTATICAS := {
	"res://zonas3d/muestra_calle/muestra_calle.gd": ["_precalentado", "_luz_cache", "_mats_entre_entradas",
		"_mats_sombra_entre_entradas"],
	"res://zonas3d/barrio/barrio.gd": ["_luz_cache", "_mats_cache", "_sondas_cache"],
	"res://zonas3d/barrio/interiores.gd": ["_datos", "_mats"],
	"res://zonas3d/barrio/utensilios.gd": ["_escena", "_cajas_glb", "_material_glb", "_del_modelo", "_materiales", "_cajas"],
	"res://personajes/npc_v12/npc_chibi.gd": ["_escenas", "_materiales"],
	"res://zonas3d/ciudad/kit/kit_ciudad.gd": ["_mats"],
	"res://zonas3d/ciudad/blockout.gd": ["_mat_opaco", "_mat_claro"],
	"res://zonas3d/ciudad/ciudad.gd": ["_puertas"],
	"res://zonas3d/ciudad/plano.gd": ["_zonas"],
	"res://zonas3d/oakhaven/cantero3d.gd": ["_texturas"],
	"res://prototipos/arbol_estilizado.gd": ["_cache"],
}

var salida := ""
var perfil := "bajo"
var ciclos := 3
var casos: Array = ["ciudad", "barrio", "muestra_calle", "arboleda", "sunken"]
var seg_dentro := 5.0
var con_carga := true
var salir_banco := false
var experimento := false
var lineas: Array = []
var filas: Array = []                       # CSV: una por medida
var archivos: PackedStringArray = []        # todos los archivos de res:// (sin .godot ni .import)
var cache_previa := {}                      # ruta → true (la vuelta anterior al banco)


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.trim_prefix("salida=")
		elif a.begins_with("perfil="):
			perfil = a.trim_prefix("perfil=")
		elif a.begins_with("ciclos="):
			ciclos = int(a.trim_prefix("ciclos="))
		elif a.begins_with("casos="):
			casos = Array(a.trim_prefix("casos=").split(","))
		elif a.begins_with("seg="):
			seg_dentro = float(a.trim_prefix("seg="))
		elif a == "sin_carga":
			con_carga = false
		elif a == "salir_banco":
			salir_banco = true
		elif a == "experimento":
			experimento = true
	if perfil != "":
		Engine.set_meta("calidad_proto", perfil)   # perfil FIJO (el regulador no cambia nada a mitad de la medida)
	_medir.call_deferred()


# ================================================================= utilidades

func _nota(t: String) -> void:
	print(t)
	lineas.append(t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _esperar(seg: float) -> void:
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < int(seg * 1000000.0):
		await process_frame


func _clic(pos: Vector2) -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		await _frames(10)
	var w: Vector2 = root.get_final_transform() * pos
	var m := InputEventMouseMotion.new()
	m.position = w
	m.global_position = w
	Input.parse_input_event(m)
	await _frames(1)
	for pulsado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = w
		e.global_position = w
		e.pressed = pulsado
		Input.parse_input_event(e)
		await _frames(2)


func _pulsar(b: Control, hecho: Callable, seg: float) -> bool:
	for intento in 3:
		if b == null or not is_instance_valid(b) or not b.is_visible_in_tree():
			return hecho.call()
		await _clic(b.get_global_rect().get_center())
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < seg * 1000.0:
			if hecho.call():
				return true
			await process_frame
	return hecho.call()


func _recursos() -> Node:
	return root.get_node_or_null("Recursos")


func _quieto() -> bool:
	var R = _recursos()
	return R == null or not R.cambiando


func _en(ruta: String) -> bool:
	return current_scene != null and current_scene.scene_file_path == ruta and _quieto()


func _esperar_escena(ruta: String, max_seg := 90.0) -> bool:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < max_seg * 1000.0:
		await process_frame
		if _en(ruta):
			return true
	return false


# ================================================================= qué hay en memoria

func _listar(carpeta: String) -> void:
	for nombre in ResourceLoader.list_directory(carpeta):
		var ruta := carpeta.path_join(nombre)
		if ruta.begins_with("res://.godot") or ruta.begins_with("res://addons/godot-git") :
			continue
		if nombre.ends_with("/"):
			_listar(ruta)
		else:
			archivos.append(ruta)


func _cacheados() -> Dictionary:
	var r := {}
	for a in archivos:
		if ResourceLoader.has_cached(a):
			r[a] = true
	return r


func _carpeta(ruta: String) -> String:
	var partes := ruta.trim_prefix("res://").split("/")
	if partes.size() <= 1:
		return "(raíz)"
	return "/".join(partes.slice(0, mini(3, partes.size() - 1)))


func _por_carpeta(rutas: Array) -> String:
	var c := {}
	for r in rutas:
		var k := _carpeta(r)
		c[k] = int(c.get(k, 0)) + 1
	var ks := c.keys()
	ks.sort_custom(func(a, b): return c[a] > c[b])
	var t: Array = []
	for k in ks.slice(0, 14):
		t.append("%s %d" % [k, c[k]])
	if ks.size() > 14:
		t.append("(+%d carpetas)" % (ks.size() - 14))
	return ", ".join(t)


func _tam(v) -> String:
	if v == null:
		return "null"
	if v is Dictionary or v is Array:
		return str(v.size())
	if v is PackedByteArray or v is PackedFloat32Array:
		return str(v.size())
	if v is Object:
		return "1"
	return str(v)


func _estaticas() -> String:
	var t: Array = []
	for s in ESTATICAS:
		if not ResourceLoader.has_cached(s):
			continue
		var S = load(s)
		var p: Array = []
		for var_ in ESTATICAS[s]:
			var v = S.get(var_)
			p.append("%s=%s" % [var_, _tam(v)])
		t.append("%s{%s}" % [s.get_file().get_basename(), " ".join(p)])
	return " · ".join(t)


func _grupos() -> String:
	var R = _recursos()
	if R == null:
		return "-"
	return "comun %d · zona %d" % [R.grupos.get("comun", {}).size(), R.grupos.get("zona", {}).size()]


func _mon() -> Dictionary:
	return {
		"estatica": Performance.get_monitor(Performance.MEMORY_STATIC) / MB,
		"video": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB,
		"texturas": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MB,
		"bufferes": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / MB,
		"objetos": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"recursos": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodos": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"huerfanos": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
	}


func _txt_mon(m: Dictionary) -> String:
	return "estática %.1f MB · vídeo %.1f MB (texturas %.1f, búferes %.1f) · objetos %d · recursos %d · nodos %d · huérfanos %d" % [
		m["estatica"], m["video"], m["texturas"], m["bufferes"], m["objetos"], m["recursos"], m["nodos"], m["huerfanos"]]


func _anotar(ciclo: int, momento: String, caso: String, detalle := false) -> void:
	await _frames(4)
	var m := _mon()
	var cache := _cacheados()
	_nota("[c%d] %-22s %-14s %s · caché res:// %d archivos · Recursos %s" % [ciclo, momento, caso, _txt_mon(m), cache.size(), _grupos()])
	filas.append("%d;%s;%s;%.2f;%.2f;%.2f;%.2f;%d;%d;%d;%d;%d" % [ciclo, momento, caso, m["estatica"], m["video"],
		m["texturas"], m["bufferes"], m["objetos"], m["recursos"], m["nodos"], m["huerfanos"], cache.size()])
	if detalle:
		_nota("        cachés estáticas: %s" % _estaticas())
		if not cache_previa.is_empty():
			var entran: Array = []
			var salen: Array = []
			for k in cache:
				if not cache_previa.has(k):
					entran.append(k)
			for k in cache_previa:
				if not cache.has(k):
					salen.append(k)
			_nota("        caché res:// respecto a la vuelta anterior: +%d (%s) · −%d (%s)" % [entran.size(),
				_por_carpeta(entran), salen.size(), _por_carpeta(salen)])
			if entran.size() > 0 and entran.size() <= 60:
				entran.sort()
				_nota("          entran: %s" % ", ".join(entran))
		cache_previa = cache
		_nota("        texturas que retienen las cachés estáticas (aprox. sin comprimir, con mipmaps): %s" % _tex_estaticas())


# Texturas e imágenes a las que llegan las cachés estáticas (materiales, diccionarios, imágenes; no entra en escenas
# empaquetadas): por script, cuántas y cuánto pesarían sin comprimir (ancho × alto × 4 × 4/3). En la GPU, comprimidas
# (S3TC en el PC, ETC2/ASTC en el móvil), pesan de 4 a 8 veces menos; sirve para comparar, no como cifra de memoria.
func _tex_estaticas() -> String:
	var t: Array = []
	for s in ESTATICAS:
		if not ResourceLoader.has_cached(s):
			continue
		var S = load(s)
		var vistos := {}
		for var_ in ESTATICAS[s]:
			_recoger(S.get(var_), vistos, 0)
		if vistos.is_empty():
			continue
		var bytes := 0.0
		for k in vistos:
			bytes += vistos[k]
		t.append("%s %d (%.1f MB)" % [s.get_file().get_basename(), vistos.size(), bytes / MB])
	return ", ".join(t) if t.size() > 0 else "ninguna"


func _recoger(v, vistos: Dictionary, prof: int) -> void:
	if v == null or prof > 4:
		return
	if v is Dictionary:
		for k in v:
			_recoger(v[k], vistos, prof + 1)
	elif v is Array:
		for x in v:
			_recoger(x, vistos, prof + 1)
	elif v is Texture2D:
		vistos[(v as Object).get_instance_id()] = (v as Texture2D).get_width() * (v as Texture2D).get_height() * 4.0 * 4.0 / 3.0
	elif v is Image:
		vistos[(v as Object).get_instance_id()] = float((v as Image).get_data_size())
	elif v is ShaderMaterial:
		var sm := v as ShaderMaterial
		if sm.shader != null:
			for u in sm.shader.get_shader_uniform_list():
				_recoger(sm.get_shader_parameter(u["name"]), vistos, prof + 1)
	elif v is BaseMaterial3D:
		for tp in [BaseMaterial3D.TEXTURE_ALBEDO, BaseMaterial3D.TEXTURE_EMISSION, BaseMaterial3D.TEXTURE_NORMAL]:
			_recoger((v as BaseMaterial3D).get_texture(tp), vistos, prof + 1)


# ================================================================= recorrido

func _boton_caso(clave: String) -> Button:
	var BP = load("res://banco_pruebas.gd")
	var titulo: String = BP.EXPLORAR[clave]["titulo"]
	for x in current_scene.find_children("*", "Button", true, false):
		if (x as Button).text == titulo:
			return x
	return null


func _entrar(clave: String) -> bool:
	var BP = load("res://banco_pruebas.gd")
	var escena: String = str(BP.EXPLORAR[clave].get("escena", ""))
	if clave == "sunken":
		Engine.set_meta("sunken_quilla_v12", true)   # (como el selector «Sunken: Quilla horneada» = Sí del banco)
	var b := _boton_caso(clave)
	if b == null:
		_nota("FALLO: el banco no tiene el caso «%s»" % clave)
		return false
	current_scene.marco.ensure_control_visible(b)
	await _frames(6)
	var R = _recursos()
	await _pulsar(b, func(): return R.cambiando or (current_scene != null and current_scene.scene_file_path == escena), 3.0)
	if not await _esperar_escena(escena):
		_nota("FALLO: el caso «%s» no abre %s" % [clave, escena])
		return false
	await _esperar(seg_dentro)
	return true


func _volver() -> bool:
	var R = _recursos()
	var b: Button = R.boton_banco if R != null else null
	if b == null or not b.is_visible_in_tree():
		_nota("FALLO: no se ve «Volver al banco»")
		return false
	await _pulsar(b, func(): return R.cambiando or (current_scene != null and current_scene.scene_file_path == BANCO), 3.0)
	if not await _esperar_escena(BANCO):
		_nota("FALLO: «Volver al banco» no vuelve")
		return false
	await _esperar(2.0)
	return true


func _medir() -> void:
	_listar("res://")
	_nota("PC: %s · %s · %s · ventana %s · renderizador %s · perfil %s FIJO · %d ciclos de %s · %.0f s dentro · fecha %s" % [
		RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version(), OS.get_processor_name(),
		str(DisplayServer.window_get_size()), ProjectSettings.get_setting("rendering/renderer/rendering_method"), perfil,
		ciclos, ",".join(casos), seg_dentro, Time.get_datetime_string_from_system()])
	_nota("res:// tiene %d archivos que se miran en la caché" % archivos.size())
	if con_carga:
		change_scene_to_file(CARGA)
		var t0 := Time.get_ticks_msec()
		var c = null
		while Time.get_ticks_msec() - t0 < 300000:
			await process_frame
			c = current_scene
			# (carga.tscn puede ser la portada alternativa, portada/inicio_alternativo.gd: las dos tienen «boton_banco»)
			if c != null and c.get("boton_banco") != null and c.boton_banco.visible and _quieto():
				break
			# la portada alternativa enseña sus botones con el menú (lo abre el primer toque: aquí, su misma función)
			if c != null and c.get("listo") == true and c.get("estado") != null and c.estado != "menu" and c.has_method("_abrir_menu"):
				c._abrir_menu()
				await _esperar(1.5)
		if c == null or c.get("boton_banco") == null or not c.boton_banco.visible:
			_nota("FALLO: la carga no enseña «Banco de pruebas»")
			_terminar()
			return
		await _esperar(1.0)
		await _anotar(0, "carga terminada", "-", true)
		await _pulsar(c.boton_banco, func(): return _recursos().cambiando or _en(BANCO), 3.0)
	else:
		change_scene_to_file(BANCO)
	if not await _esperar_escena(BANCO):
		_nota("FALLO: no se llega al banco")
		_terminar()
		return
	await _esperar(2.0)
	await _anotar(0, "banco (inicio)", "-", true)
	for ciclo in range(1, ciclos + 1):
		for clave in casos:
			if not await _entrar(clave):
				_terminar()
				return
			await _anotar(ciclo, "dentro", clave)
			if not await _volver():
				_terminar()
				return
			await _anotar(ciclo, "banco tras", clave, true)
	if experimento:
		await _experimento()
	if salir_banco:
		var bs: Button = null
		for x in current_scene.find_children("*", "Button", true, false):
			if (x as Button).text == "Salir del banco":
				bs = x
		if bs != null:
			await _pulsar(bs, func(): return _recursos().cambiando or (current_scene != null and current_scene.scene_file_path != BANCO), 3.0)
			var t1 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t1 < 60000 and (not _quieto() or current_scene == null or current_scene.scene_file_path == BANCO):
				await process_frame
			if current_scene != null and current_scene.scene_file_path != BANCO:
				await _esperar(3.0)
				await _anotar(ciclos, "tras «Salir del banco»", "-", true)
	_terminar()


# «experimento»: ya en el banco tras los ciclos, se sueltan una a una las cachés estáticas de las regiones y se anota
# cuánto baja cada vez (qué retiene cada una). Solo para atribuir: el juego no lo hace así.
func _experimento() -> void:
	var pasos := [
		["barrio (barrio, interiores, utensilios)", func():
			for r in ["res://zonas3d/barrio/barrio.gd", "res://zonas3d/barrio/interiores.gd", "res://zonas3d/barrio/barrio_vivo.gd"]:
				if ResourceLoader.has_cached(r):
					load(r).soltar_caches()],
		["muestra_calle", func():
			if ResourceLoader.has_cached("res://zonas3d/muestra_calle/muestra_calle.gd"):
				load("res://zonas3d/muestra_calle/muestra_calle.gd").soltar_caches()],
		["npc_chibi (_escenas y _materiales)", func():
			if ResourceLoader.has_cached("res://personajes/npc_v12/npc_chibi.gd"):
				var S = load("res://personajes/npc_v12/npc_chibi.gd")
				S.soltar(S._materiales.keys(), S._escenas.keys())],
		["ciudad (blockout, kit_ciudad, _puertas, _zonas)", func():
			if ResourceLoader.has_cached("res://zonas3d/ciudad/kit/kit_ciudad.gd"):
				load("res://zonas3d/ciudad/kit/kit_ciudad.gd").soltar_caches()
			if ResourceLoader.has_cached("res://zonas3d/ciudad/blockout.gd"):
				var B = load("res://zonas3d/ciudad/blockout.gd")
				B._mat_opaco = null
				B._mat_claro = null],
		# los búferes 3D de la ventana (color, profundidad, brillo, copia de pantalla...) son de la VENTANA, no de la
		# escena: siguen tras volver al banco (2D). Cambiar un momento la escala 3D los rehace (libera los efectos).
		["búferes 3D de la ventana (escala 3D ± 0,01)", func():
			var s := root.scaling_3d_scale
			root.scaling_3d_scale = s + 0.01 if s < 1.0 else s - 0.01
			await _frames(3)
			root.scaling_3d_scale = s],
	]   # (17/11: se probaron también root.disable_3d = true y cambiar 8 px el tamaño de la ventana: no baja nada más)
	for p in pasos:
		await (p[1] as Callable).call()
		await _frames(10)
		await _anotar(ciclos, "EXP soltar", str(p[0]).left(14), true)
		_nota("        (experimento: soltado «%s»)" % p[0])


func _terminar() -> void:
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		var f := FileAccess.open(salida.path_join("memoria_escenas_%s.txt" % perfil), FileAccess.WRITE)
		f.store_string("\n".join(lineas) + "\n")
		f.close()
		var g := FileAccess.open(salida.path_join("memoria_escenas_%s.csv" % perfil), FileAccess.WRITE)
		g.store_string("ciclo;momento;caso;estatica_mb;video_mb;texturas_mb;bufferes_mb;objetos;recursos;nodos;huerfanos;cache_archivos\n"
			+ "\n".join(filas) + "\n")
		g.close()
	quit(0)
