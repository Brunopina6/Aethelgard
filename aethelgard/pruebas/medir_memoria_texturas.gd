extends SceneTree
# Memoria gráfica (14/11, rendimiento): qué texturas y mallas cargadas pesan más, en Oakhaven y en un combate (y en la
# invocación de Érebo), con cifras deterministas (bytes, formatos, tamaños; nada de tiempos). Con ventana (GPU real).
#   Godot --path aethelgard --script res://pruebas/medir_memoria_texturas.gd --fixed-fps 30 -- salida=<carpeta>
#         escena=oakhaven|combate [perfil=bajo] [etiqueta=x] 3d sin_prologo
# Usa RenderingServer.texture_debug_usage() (la lista de texturas en vídeo que da el depurador de Godot: ruta, formato,
# tamaño y bytes) y recorre el árbol para atribuir mallas y texturas a sus nodos. Señala:
#   - texturas SIN COMPRIMIR (RGBA8/RGB8/...) grandes y si su .import pide compresión de vídeo o no;
#   - texturas con mipmaps que solo se usan en 2D (interfaz), y las 3D sin ellos;
#   - duplicados: la misma imagen cargada con dos rutas (mismo tamaño, formato y contenido).
# Escribe <salida>/memoria_<escena>_<perfil><etiqueta>.json y .txt.

var salida := ""
var id := "oakhaven"
var perfil := "bajo"
var etiqueta := ""
var R


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
		elif a.begins_with("escena="):
			id = a.substr(7)
		elif a.begins_with("perfil="):
			perfil = a.substr(7)
		elif a.begins_with("etiqueta="):
			etiqueta = "_" + a.substr(9)
	R = root.get_node("Recursos")
	Engine.set_meta("calidad_proto", perfil)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	Engine.set_meta("archivo_partida_prueba", "user://medir_memoria_texturas.save")
	DirAccess.make_dir_recursive_absolute(salida)
	_medir.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _memoria() -> Dictionary:
	return {"video_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"texturas_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"buffers_mb": snappedf(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, 0.1),
		"estatica_mb": snappedf(OS.get_static_memory_usage() / 1048576.0, 0.1)}


func _medir() -> void:
	var informe := {"escena": id, "perfil": perfil, "gpu": RenderingServer.get_video_adapter_name()}
	informe["arranque"] = _memoria()
	if "con_carga" in OS.get_cmdline_user_args():     # como el juego: la pantalla de carga y su precarga común primero
		change_scene_to_file("res://carga.tscn")
		var t := 0
		for i in 6000:
			await process_frame
			t += 1
			var e := current_scene.scene_file_path if current_scene != null else ""
			if e != "" and e != "res://carga.tscn" and not R.cambiando and t > 5 and current_scene.get("listo") != false:
				break
		await _esperar(30)
		informe["tras_la_carga"] = _memoria()
		informe["precarga"] = {"comun": R.grupos["comun"].size(), "zona": R.grupos["zona"].size()}
	var c = null
	if id == "oakhaven":
		change_scene_to_file("res://zonas3d/oakhaven_3d.tscn")
		for i in 900:
			await process_frame
			if current_scene != null and current_scene.scene_file_path.ends_with("oakhaven_3d.tscn") and not R.cambiando:
				break
		await _esperar(150)                            # que se asiente (hierba por trozos, cachés)
	else:
		var P = load("res://progreso.gd")
		var G = load("res://grupo.gd")
		for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
			if Engine.has_meta(k):
				Engine.remove_meta(k)
		G.datos()
		for n in ["Kael", "Lya"]:
			G.datos()[n]["nivel"] = 5
			G.datos()[n]["pv"] = -1
		Engine.set_meta("zona", "ceniza")
		Engine.set_meta("tipo_combate", "normal")
		Engine.set_meta("grupo_combate", 9)
		c = load("res://combate.tscn").instantiate()
		root.add_child(c)
		await _esperar(150)
	informe["escena_puesta"] = _memoria()
	informe["texturas"] = _inventario()
	informe["mallas"] = _mallas(root)
	if c != null:                                    # y con la invocación de Érebo en pantalla (su teatro y sus texturas)
		for i in 3000:
			if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
				if c.actor["nombre"] == "Lya":
					break
				c._defender()
			for e in c.enemigos:
				e["atb"] = 0.0
			await process_frame
		c.armonia = 1.0
		c._invocar_sobre(c.enemigos[0])
		for i in 600:
			await process_frame
			if c.inv_erebo != null and c.inv_erebo.erebo != null and c.inv_erebo.erebo.visible:
				break
		await _esperar(60)
		informe["invocacion"] = _memoria()
		informe["texturas_invocacion"] = _inventario()
	var nombre := "memoria_%s_%s%s" % [id, perfil, etiqueta]
	var f := FileAccess.open(salida.path_join(nombre + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(informe, " "))
	f.close()
	var txt := _texto(informe)
	f = FileAccess.open(salida.path_join(nombre + ".txt"), FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	print(txt)
	for k in ["calidad_proto", "pos_3d_ok", "grupo_activo", "archivo_partida_prueba", "zona", "tipo_combate", "grupo_combate"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	quit(0)


const SIN_COMPRIMIR := ["L8", "LA8", "R8", "RG8", "RGB8", "RGBA8", "RGBA4444", "RGB565", "RF", "RGF", "RGBF", "RGBAF", "RH",
	"RGH", "RGBH", "RGBAH"]


# Las texturas vivas: las que cuelgan del árbol (nodos, materiales, mallas, parámetros de sombreador) y las que guarda
# Recursos (la precarga). De las importadas, formato, tamaño y mipmaps salen de la cabecera de su .ctex (lo que sube a
# vídeo); de las generadas (degradados, ventanas, imágenes hechas en código), de su imagen o su tamaño. Los bytes son
# una estimación (bits por píxel × píxeles, × 4/3 con mipmaps); el total real es el del monitor de Godot.
func _inventario() -> Dictionary:
	var texturas := {}
	var vistos := {}
	for n in root.find_children("*", "", true, false):
		if n != R:
			_recorrer(n, texturas, vistos, 0)
	var en_escena := texturas.keys()
	_recorrer(R.grupos, texturas, vistos, 0)          # y lo que guarda la precarga (Recursos.grupos)
	var total := 0.0
	var por_formato := {}
	var filas := []
	var por_md5 := {}
	var solo_precarga := {"numero": 0, "kb": 0.0}
	var por_carpeta := {}
	for id_t in texturas:
		var tex: Texture2D = texturas[id_t]
		var fila := _datos_textura(tex)
		fila["en_escena"] = id_t in en_escena
		if not fila.en_escena:
			solo_precarga.numero += 1
			solo_precarga.kb += fila.kb
		var carpeta: String = fila.ruta.get_base_dir() if fila.ruta.begins_with("res://") else "(generadas)"
		por_carpeta[carpeta] = por_carpeta.get(carpeta, 0.0) + fila.kb
		total += fila.kb
		por_formato[fila.formato] = por_formato.get(fila.formato, 0.0) + fila.kb
		filas.append(fila)
		if fila.has("md5_origen") and fila.md5_origen != "":
			por_md5.get_or_add(fila.md5_origen, []).append(fila.ruta)
	filas.sort_custom(func(a, b): return a.kb > b.kb)
	var dup := []
	for k in por_md5:
		if por_md5[k].size() > 1:
			dup.append(por_md5[k])
	var sin_comp := filas.filter(func(x): return x.formato.get_slice("(", 0) in SIN_COMPRIMIR and x.kb >= 512.0)
	var generadas := filas.filter(func(x): return not x.ruta.begins_with("res://") or x.ruta.contains("::"))
	var kb_gen := 0.0
	for x in generadas:
		kb_gen += x.kb
	var pf := {}
	for k in por_formato:
		pf[k] = snappedf(por_formato[k] / 1024.0, 0.01)
	var pc := []
	for k in por_carpeta:
		pc.append([k, snappedf(por_carpeta[k] / 1024.0, 0.1)])
	pc.sort_custom(func(a, b): return a[1] > b[1])
	return {"total_mb_estimado": snappedf(total / 1024.0, 0.1), "numero": filas.size(), "por_formato_mb": pf,
		"solo_en_la_precarga": {"numero": solo_precarga.numero, "mb": snappedf(solo_precarga.kb / 1024.0, 0.1)},
		"por_carpeta_mb": pc.slice(0, 15),
		"mayores": filas.slice(0, 40), "sin_comprimir_512kb": sin_comp, "duplicadas_mismo_origen": dup,
		"generadas": {"numero": generadas.size(), "mb": snappedf(kb_gen / 1024.0, 0.1), "mayores": generadas.slice(0, 12)}}


func _recorrer(o, texturas: Dictionary, vistos: Dictionary, prof: int) -> void:
	if o == null or prof > 6:
		return
	if o is Array:
		for x in o:
			if (typeof(x) == TYPE_OBJECT and is_instance_valid(x)) or x is Array or x is Dictionary:
				_recorrer(x, texturas, vistos, prof + 1)
		return
	if o is Dictionary:
		for x in o.values():
			if (typeof(x) == TYPE_OBJECT and is_instance_valid(x)) or x is Array or x is Dictionary:
				_recorrer(x, texturas, vistos, prof + 1)
		return
	if typeof(o) != TYPE_OBJECT or not is_instance_valid(o):
		return
	if o is Resource:
		var id: int = o.get_instance_id()
		if vistos.has(id):
			return
		vistos[id] = true
		if o is Texture2D:
			texturas[id] = o
	if o is ShaderMaterial and o.shader != null:
		for u in o.shader.get_shader_uniform_list():
			var v = o.get_shader_parameter(u.name)
			if v is Object:
				_recorrer(v, texturas, vistos, prof + 1)
	if o is Mesh:
		for s in o.get_surface_count():
			_recorrer(o.surface_get_material(s), texturas, vistos, prof + 1)
	for p in o.get_property_list():
		var uso: int = p.usage
		if p.type != TYPE_OBJECT and p.type != TYPE_ARRAY and p.type != TYPE_DICTIONARY:
			continue
		if not (uso & PROPERTY_USAGE_STORAGE or uso & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if p.name in ["script", "owner"] or (o is Node and p.type == TYPE_OBJECT and is_instance_valid(o.get(p.name)) and o.get(p.name) is Node):
			continue                                  # (los nodos se recorren desde el árbol)
		var v = o.get(p.name)
		if (typeof(v) == TYPE_OBJECT and is_instance_valid(v)) or v is Array or v is Dictionary:
			_recorrer(v, texturas, vistos, prof + 1)


# Formato, tamaño, mipmaps y KB de una textura; de las importadas, también su .import y el md5 de la imagen de origen.
func _datos_textura(tex: Texture2D) -> Dictionary:
	var ruta := tex.resource_path
	var fila := {"ruta": ruta if ruta != "" else "(%s)" % tex.get_class(), "clase": tex.get_class(), "w": tex.get_width(),
		"h": tex.get_height(), "formato": "?", "mipmaps": false}
	var ctex := ""
	if ruta.begins_with("res://") and not ruta.contains("::") and FileAccess.file_exists(ruta + ".import"):
		var cfg := ConfigFile.new()
		if cfg.load(ruta + ".import") == OK:
			fila["import_modo"] = ["sin pérdida", "con pérdida", "vídeo comprimida", "vídeo sin comprimir", "basis"][clampi(int(cfg.get_value("params", "compress/mode", 0)), 0, 4)]
			fila["import_mipmaps"] = bool(cfg.get_value("params", "mipmaps/generate", false))
			for clave in ["path.s3tc", "path.bptc", "path"]:
				var c = cfg.get_value("remap", clave, "")
				if c != "" and FileAccess.file_exists(c):
					ctex = c
					break
			fila["md5_origen"] = FileAccess.get_md5(ruta)
	if ctex != "":
		var f := FileAccess.open(ctex, FileAccess.READ)
		if f != null and f.get_buffer(4).get_string_from_ascii() == "GST2":
			f.get_32()                                # versión
			f.get_32()
			f.get_32()
			var banderas := f.get_32()
			f.get_32()
			f.get_32()
			f.get_32()
			f.get_32()
			var tipo := f.get_32()                    # 0 imagen, 1 png, 2 webp, 3 basis
			var w := f.get_16()
			var h := f.get_16()
			var mips := f.get_32()
			var fmt := f.get_32()
			fila["w"] = w
			fila["h"] = h
			fila["formato"] = _formato(fmt) + ("" if tipo == 0 else ["", "(png)", "(webp)", "(basis)"][clampi(tipo, 0, 3)])
			fila["mipmaps"] = mips > 0 or (banderas & 1) != 0
	elif tex is ImageTexture or tex is GradientTexture2D or tex is NoiseTexture2D or tex is ViewportTexture:
		fila["formato"] = "RGBA8"                      # (las generadas suben sin comprimir)
		if tex is ImageTexture:
			var img := tex.get_image()
			if img != null:
				fila["formato"] = _formato(img.get_format())
				fila["mipmaps"] = img.has_mipmaps()
	var bpp := _bpp(fila.formato.get_slice("(", 0))
	if fila.formato.ends_with("(png)") or fila.formato.ends_with("(webp)"):
		bpp = 32.0                                     # sin pérdida o con pérdida: en vídeo, sin comprimir
	fila["kb"] = snappedf(fila.w * fila.h * bpp / 8.0 * (4.0 / 3.0 if fila.mipmaps else 1.0) / 1024.0, 0.1)
	return fila


func _formato(f: int) -> String:
	var nombres := ["L8", "LA8", "R8", "RG8", "RGB8", "RGBA8", "RGBA4444", "RGB565", "RF", "RGF", "RGBF", "RGBAF", "RH",
		"RGH", "RGBH", "RGBAH", "RGBE9995", "DXT1", "DXT3", "DXT5", "RGTC_R", "RGTC_RG", "BPTC_RGBA", "BPTC_RGBF",
		"BPTC_RGBFU", "ETC", "ETC2_R11", "ETC2_R11S", "ETC2_RG11", "ETC2_RG11S", "ETC2_RGB8", "ETC2_RGBA8",
		"ETC2_RGB8A1", "ETC2_RA_AS_RG", "DXT5_RA_AS_RG", "ASTC_4x4", "ASTC_4x4_HDR", "ASTC_8x8", "ASTC_8x8_HDR"]
	return nombres[f] if f >= 0 and f < nombres.size() else "?%d" % f


func _bpp(fmt: String) -> float:
	return {"L8": 8, "LA8": 16, "R8": 8, "RG8": 16, "RGB8": 24, "RGBA8": 32, "RGBA4444": 16, "RGB565": 16, "RGBAH": 64,
		"RGBAF": 128, "DXT1": 4, "DXT3": 8, "DXT5": 8, "BPTC_RGBA": 8, "ETC2_RGB8": 4, "ETC2_RGBA8": 8, "ASTC_4x4": 8,
		"ASTC_8x8": 2, "RGTC_R": 4, "RGTC_RG": 8}.get(fmt, 0)


# Mallas del árbol: vértices e índices por recurso (una vez cada una), con cuántas instancias la usan.
func _mallas(raiz: Node) -> Dictionary:
	var vistas := {}
	for n in raiz.find_children("*", "", true, false):
		var m: Mesh = null
		var veces := 1
		if n is MeshInstance3D:
			m = n.mesh
		elif n is MultiMeshInstance3D and n.multimesh != null:
			m = n.multimesh.mesh
			veces = n.multimesh.instance_count
		if m == null or not (m is ArrayMesh or m is PrimitiveMesh):
			continue
		var k := m.resource_path if m.resource_path != "" else str(m.get_instance_id())
		if not vistas.has(k):
			var v := 0
			var i := 0
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				v += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() if arr[Mesh.ARRAY_VERTEX] != null else 0
				i += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() if arr[Mesh.ARRAY_INDEX] != null else 0
			vistas[k] = {"malla": k, "nodo": str(n.name), "vertices": v, "indices": i, "instancias": 0}
		vistas[k]["instancias"] += veces
	var filas: Array = vistas.values()
	filas.sort_custom(func(a, b): return a.vertices > b.vertices)
	var tv := 0
	for x in filas:
		tv += x.vertices
	return {"distintas": filas.size(), "vertices_total": tv, "mayores": filas.slice(0, 20)}


func _texto(inf: Dictionary) -> String:
	var t := "Memoria gráfica: %s, perfil %s (%s)\n" % [inf.escena, inf.perfil, inf.gpu]
	if inf.has("precarga"):
		t += "  precarga: %s\n" % JSON.stringify(inf.precarga)
	for k in ["arranque", "tras_la_carga", "escena_puesta", "invocacion"]:
		if inf.has(k):
			t += "  %-14s %s\n" % [k, JSON.stringify(inf[k])]
	for k in ["texturas", "texturas_invocacion"]:
		if not inf.has(k):
			continue
		var x: Dictionary = inf[k]
		t += "\n%s: %d texturas vivas, %.1f MB estimados; por formato (MB): %s\n" % [k, x.numero, x.total_mb_estimado, JSON.stringify(x.por_formato_mb)]
		t += "  generadas en código o ventanas: %d, %.1f MB\n" % [x.generadas.numero, x.generadas.mb]
		t += "  solo en la precarga (no las usa esta escena): %d, %.1f MB\n" % [x.solo_en_la_precarga.numero, x.solo_en_la_precarga.mb]
		t += "  por carpeta (MB): %s\n" % JSON.stringify(x.por_carpeta_mb)
		t += "  mayores:\n"
		for f in x.mayores.slice(0, 30):
			t += "    %8.1f KB %-14s %5dx%-5d mip=%-5s import=%-17s %s %s\n" % [f.kb, f.formato, f.w, f.h, str(f.mipmaps), str(f.get("import_modo", "-")), "escena" if f.en_escena else "precarga", f.ruta]
		t += "  sin comprimir (>= 512 KB): %d\n" % x.sin_comprimir_512kb.size()
		for f in x.sin_comprimir_512kb:
			t += "    %8.1f KB %-14s %5dx%-5d mip=%-5s import=%s %s\n" % [f.kb, f.formato, f.w, f.h, str(f.mipmaps), str(f.get("import_modo", "-")), f.ruta]
		t += "  la misma imagen de origen con dos rutas: %s\n" % JSON.stringify(x.duplicadas_mismo_origen)
	if inf.has("mallas"):
		t += "\nmallas: %d distintas, %d vértices; mayores: %s\n" % [inf.mallas.distintas, inf.mallas.vertices_total,
			JSON.stringify(inf.mallas.mayores.slice(0, 10))]
	return t
