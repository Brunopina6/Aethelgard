extends SceneTree
# Herramienta (V12, especialista de mundo, 13/11): ESBOZO de las Cumbres de Ciclópea 3D (lugar 3), sin escena todavía.
# Vuelca la disposición que zona.gd genera para el lugar 3 (estilo «nieve», semilla 1000 + 3 × 7919), como hizo
# volcar_bosque_2d.gd con el Gran Bosque, y propone el relieve de la 3D (docs/v12/INVENTARIO_MUNDO.md §8):
#   - el camino sube del sur (la entrada, 0 m) al altar del norte (+9 m) en rampas suaves (≤ 12 %);
#   - los muros de la 2D son paredes de roca (+5 a +14 m sobre el camino), más altas cuanto más al norte;
#   - el agua de la 2D, un lago helado a la altura de su orilla (no se pisa: como el agua de las otras regiones);
#   - los rincones (ruinas, campamento, mirada) en rellanos.
# Escribe en <carpeta>: ciclopea_2d.json (caminos, rincones, cofres con sus ids «3_x_y», objetos, máscaras), plano_2d.png
# y relieve.png (alturas propuestas en grises, 4 px por casilla; 0 = 0 m, 255 = 16 m), que lee fuente/esbozo_ciclopea.py.
# Uso (datos aislados): Godot --headless --path aethelgard -s res://pruebas/herramientas/volcar_ciclopea_2d.gd -- <carpeta>

const LUGAR := 3
const ALTO_ALTAR := 9.0
const ALTO_MAX := 16.0


func _initialize() -> void:
	var carpeta := OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	var z = load("res://zona.gd").new()
	var l: Dictionary = load("res://mapa.gd").LUGARES[LUGAR]
	var estilo: String = load("res://mapa.gd").ZONA_LUGAR[LUGAR]
	z.lugar = {"indice": LUGAR, "nombre": l["nombre"], "tipo": l["tipo"], "zona": estilo, "texto": l["texto"]}
	z.nombre_estilo = estilo
	z.estilo = z.ESTILOS[estilo]
	z.es_ciudad = false
	z.semilla = 1000 + LUGAR * 7919
	z._generar_disposicion()
	var W: int = z.ANCHO
	var H: int = z.ALTO
	var cofres: Array = []
	var objetos := {}
	for o in z.colocados:
		var c := Vector2(o["pos"].x / z.T, o["pos"].y / z.T)
		if o["tipo"] == "cofre":
			cofres.append([z._id_cofre(o["pos"]), [snappedf(c.x, 0.01), snappedf(c.y, 0.01)]])
		else:
			objetos[o["tipo"]] = int(objetos.get(o["tipo"], 0)) + 1
	var lugares: Array = []
	for li in z.lugares_interes:
		lugares.append([li["tipo"], [snappedf(li["pos"].x, 0.01), snappedf(li["pos"].y, 0.01)]])
	var caminos: Array = []
	for cm in z.caminos:
		caminos.append(Array(cm).map(func(p): return [snappedf(p.x, 0.01), snappedf(p.y, 0.01)]))
	# --- relieve propuesto (4 px por casilla)
	var k := 4
	var rel := Image.create(W * k, H * k, false, Image.FORMAT_L8)
	var plano := Image.create(W * k, H * k, false, Image.FORMAT_RGB8)
	var ruido := FastNoiseLite.new()
	ruido.seed = z.semilla
	ruido.frequency = 0.08
	var sur: float = H - 1.0
	var norte: float = z.meta.y
	for y in H * k:
		for x in W * k:
			var p := Vector2(x, y) / float(k)
			var t := clampf((sur - p.y) / maxf(sur - norte, 1.0), 0.0, 1.0)
			var base := ALTO_ALTAR * smoothstep(0.0, 1.0, t)               # la subida del camino, suave
			var muro: bool = z.muros[mini(int(p.y), H - 1) * W + mini(int(p.x), W - 1)] != 0
			var en_camino: bool = z._peso(z.camino_v, p) > 0.5
			var agua: bool = z._en_agua(p * z.T)
			var h := base
			if muro:
				h = base + 5.0 + 9.0 * t + 2.5 * ruido.get_noise_2d(p.x, p.y)  # pared de roca, más alta al norte
			elif not en_camino and not agua:
				h = base + 0.8 + 1.2 * absf(ruido.get_noise_2d(p.x * 1.7, p.y * 1.7))   # laderas nevadas
			elif agua:
				h = base - 0.4
			rel.set_pixel(x, y, Color.from_hsv(0, 0, clampf(h / ALTO_MAX, 0.0, 1.0)))
			var col := Color(0.86, 0.9, 0.96)                               # nieve
			if muro:
				col = Color(0.42, 0.44, 0.5)
			if en_camino:
				col = Color(0.62, 0.55, 0.46)
			if agua:
				col = Color(0.55, 0.75, 0.9)
			plano.set_pixel(x, y, col.darkened(0.25 * (1.0 - h / ALTO_MAX)))
	for cf in cofres:
		plano.fill_rect(Rect2i(int(cf[1][0] * k) - 3, int(cf[1][1] * k) - 3, 6, 6), Color(1, 0.8, 0.2))
	for li in lugares:
		plano.fill_rect(Rect2i(int(li[1][0] * k) - 4, int(li[1][1] * k) - 4, 8, 8), Color(0.9, 0.3, 0.3))
	plano.fill_rect(Rect2i(int(z.meta.x * k) - 5, int(z.meta.y * k) - 5, 10, 10), Color(0.5, 1, 1))
	rel.save_png(carpeta.path_join("relieve.png"))
	plano.save_png(carpeta.path_join("plano_2d.png"))
	var datos := {"lugar": LUGAR, "estilo": estilo, "semilla": z.semilla, "ancho": W, "alto": H, "t": z.T,
		"meta": [z.meta.x, z.meta.y], "salida_x": z.salida_x, "caminos": caminos, "lugares": lugares, "cofres": cofres,
		"objetos_por_tipo": objetos, "alto_altar_m": ALTO_ALTAR, "alto_max_m": ALTO_MAX, "px_por_casilla": k,
		"detalles": load("res://progreso.gd").DETALLES.get(LUGAR, []),
		"hallazgos": load("res://hallazgos.gd").HALLAZGOS.filter(func(h): return int(h["lugar"]) == LUGAR)}
	var f := FileAccess.open(carpeta.path_join("ciclopea_2d.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(datos, "\t"))
	f.close()
	print("CICLOPEA %dx%d casillas · %d cofres · %d rincones · objetos %s" % [W, H, cofres.size(), lugares.size(), objetos])
	z.free()
	quit()
