extends RefCounted
# V12, fase C (12/11/2026, animaciones): los cambios EXACTOS que pide el especialista de animaciones en combate.gd para
# enganchar el Guardián de piedra, el Gólem de ámbar y Gorthor (enemigos/*/…_3d.gd). No se aplican solos: el
# coordinador los copia a combate.gd (cada uno es «busca este texto, que sale una sola vez, y pon este otro»). Las
# pruebas (pruebas/fotos_enemigos_v12.gd y prueba_enemigos_v12_combate.gd) los aplican EN MEMORIA a una copia del
# guion para jugar el combate de verdad con ellos, sin tocar el archivo. Si combate.gd cambia y un texto ya no está,
# aplicar() lo dice («faltan»).
#
# Lo imprescindible son los cambios 1-3 (los modelos y su encuadre); 4-11 son los ganchos de los clips propios
# (carga, aturdido, Devorar, fase 2, rendirse, perdón y el tiempo de caída). Sin ellos los modelos funcionan igual con
# su ataque y su golpe fuerte de siempre. Los respaldos (guardian.png y el goblin de Gorthor) no se tocan.

const CAMBIOS := [
	# 1. MODELOS: las tres entradas nuevas (al final del diccionario). Encuadre medido por prueba_enemigos_v12.gd
	#    (todas las poses de todos los clips menos la derrota, la victoria y el arrastrarse caben, con 0,25 m de
	#    margen); «pos_grupo»: los pies donde estaban los del dibujo de antes; «caida»: segundos antes de fundirlo.
	["modelos",
"""	"coloso_falla2d": {"tipo": "imagen", "imagen": "res://enemigos/guardian.png", "cadera": Vector2(160, 470), "tam": 1.45,
		"barra_y": -197.0, "centro_y": 90.0, "tinte": Color(1.05, 0.86, 0.8)},
}
""",
"""	"coloso_falla2d": {"tipo": "imagen", "imagen": "res://enemigos/guardian.png", "cadera": Vector2(160, 470), "tam": 1.45,
		"barra_y": -197.0, "centro_y": 90.0, "tinte": Color(1.05, 0.86, 0.8)},
	# V12, fase C (animaciones, 12/11): modelos propios de Blender (enemigos/<nombre>/fuente/), con la interfaz de
	# goblin_3d.gd (corren hasta el objetivo: atacar_hacha / golpe_fuerte) y los ganchos de enemigo_v12_3d.gd (cargar,
	# aturdido, fase2, devorar, rendirse, retirarse). Encuadre de pruebas/prueba_enemigos_v12.gd; «respaldo»: lo de antes.
	"guardian3d": {
		"tipo": "3d", "esc": 0.6, "script": "res://enemigos/guardian_piedra/guardian_piedra_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/guardian_piedra/guardian_piedra.glb"],
		"vp": Vector2i(1280, 1300), "alto_vista": 4.7, "centro_y": 1.8, "barra_y": 216.0, "centro_3d": 1.35,
		"pos_grupo": Vector2(%GUARDIAN_POS%), "caida": 1.6, "respaldo": "guardian"},
	"golem_ambar3d": {
		"tipo": "3d", "esc": 0.6, "script": "res://enemigos/golem_ambar/golem_ambar_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/golem_ambar/golem_ambar.glb"],
		"vp": Vector2i(1000, 910), "alto_vista": 3.3, "centro_y": 1.15, "barra_y": 49.0, "centro_3d": 1.25,
		"pos_grupo": Vector2(%GOLEM_POS%), "caida": 1.4, "respaldo": "guardian"},
	"gorthor_v12": {
		"tipo": "3d", "esc": 0.6, "script": "res://enemigos/gorthor/gorthor_3d.gd",
		"gestos": "res://gestos_3d.gd", "rutas": ["res://enemigos/gorthor/gorthor.glb"],
		"vp": Vector2i(1420, 1520), "alto_vista": 5.2, "centro_y": 1.6, "barra_y": 183.0, "centro_3d": 1.6,
		"pos_grupo": Vector2(%GORTHOR_POS%), "caida": 1.4, "respaldo": "gorthor3d"},
}
"""],
	# 2. ENEMIGOS: cada uno con su modelo (vida, ataque, personalidad y premios, sin cambiar)
	["enemigo_guardian",
		"""	"guardian": {"nombre": "Guardián de piedra", "modelo": "guardian",""",
		"""	"guardian": {"nombre": "Guardián de piedra", "modelo": "guardian3d","""],
	["enemigo_gorthor",
		"""	"gorthor": {"nombre": "Gorthor el Devorador", "modelo": "gorthor3d",""",
		"""	"gorthor": {"nombre": "Gorthor el Devorador", "modelo": "gorthor_v12","""],
	["enemigo_golem",
		"""	"golem_ambar": {"nombre": "Gólem de ámbar", "modelo": "guardian",""",
		"""	"golem_ambar": {"nombre": "Gólem de ámbar", "modelo": "golem_ambar3d","""],
	# 3. ANIM: a qué distancia se planta para golpear (la punta de su arma o su puño llega al héroe en el impacto)
	["anim",
		"""	"guardian": {"distancia": 150.0},
""",
		"""	"guardian": {"distancia": 150.0},
	"guardian3d": {"distancia": %GUARDIAN_DIST%},         # V12, fase C: el mandoble llega 2 m por delante
	"golem_ambar3d": {"distancia": %GOLEM_DIST%},      # V12, fase C: el puño
	"gorthor_v12": {"distancia": %GORTHOR_DIST%},        # V12, fase C: la cuchilla
"""],
	# 4. El jefe avisa su golpe devastador: alza el arma y se queda en la carga (Guardián y Gorthor)
	["carga_jefe",
		"""		f["cargando"] = true
		_marcar_aviso(f, true)                       # la señal de aviso sobre él, hasta que golpee (se lee sin partículas)
""",
		"""		f["cargando"] = true
		_marcar_aviso(f, true)                       # la señal de aviso sobre él, hasta que golpee (se lee sin partículas)
		if _p3d(f) != null and _p3d(f).has_method("cargar"):   # V12, fase C: alza el arma y se queda en la carga
			_p3d(f).cargar()
"""],
	# 5. El bruto «levanta los puños» (el Gólem): su carga
	["carga_patron",
		"""	f["objetivo_carga"] = obj
	_marcar_aviso(f, true)
""",
		"""	f["objetivo_carga"] = obj
	_marcar_aviso(f, true)
	if _p3d(f) != null and _p3d(f).has_method("cargar"):       # V12, fase C: el Gólem levanta los puños y se queda
		_p3d(f).cargar()
"""],
	# 6. Carga interrumpida (V11): se tambalea hasta su turno siguiente, y al recuperarse vuelve al reposo
	["interrumpido",
		"""	f.erase("carga_recibido")
	_marcar_aviso(f, false)
""",
		"""	f.erase("carga_recibido")
	_marcar_aviso(f, false)
	if _p3d(f) != null and _p3d(f).has_method("aturdido"):     # V12, fase C: se tambalea (el Gólem)
		_p3d(f).aturdido()
"""],
	["recupera",
		"""	if f.get("recupera", false):
		f["recupera"] = false
		registro.text = ("%s, aturdido, recupera el aliento" if f.get("aturdido", false) else "%s recupera el aliento") % f["nombre"]
""",
		"""	if f.get("recupera", false):
		f["recupera"] = false
		registro.text = ("%s, aturdido, recupera el aliento" if f.get("aturdido", false) else "%s recupera el aliento") % f["nombre"]
		if _p3d(f) != null and _p3d(f).has_method("aturdido"):   # V12, fase C: deja de tambalearse
			_p3d(f).reposo()
"""],
	# 7. Devorar (Gorthor, fase 2): su mordisco con las fauces, no el tajo
	["devorar_metodo",
		"""		var fuerte: bool = origen.get("furia", false) or origen.get("descarga", false)
		await _anim_ataque_3d(origen, objetivo, impacto, "golpe_fuerte" if fuerte else "atacar_hacha")
""",
		"""		var fuerte: bool = origen.get("furia", false) or origen.get("descarga", false)
		var metodo_3d := "golpe_fuerte" if fuerte else "atacar_hacha"
		if origen.get("devora", false) and _p3d(origen).has_method("devorar"):   # V12, fase C: el mordisco de Gorthor
			metodo_3d = "devorar"
		await _anim_ataque_3d(origen, objetivo, impacto, metodo_3d)
"""],
	["devorar_clip",
		"""		"atacar_giro":
			await p.atacar_giro(al_golpear)
""",
		"""		"atacar_giro":
			await p.atacar_giro(al_golpear)
		"devorar":                                     # V12, fase C: Gorthor muerde (impacto al cerrar las fauces)
			await p.devorar(al_golpear)
"""],
	# 8. Fase 2 (Gorthor, «¡Furia del Abismo!»): ruge y se le encienden las vetas de brasa
	["fase2",
		"""	_numero_flotante(f, "¡FURIA DEL ABISMO!", Color("FF7A3C"), 40)
""",
		"""	_numero_flotante(f, "¡FURIA DEL ABISMO!", Color("FF7A3C"), 40)
	if _p3d(f) != null and _p3d(f).has_method("fase2"):         # V12, fase C: Gorthor ruge y se enciende
		_p3d(f).fase2()
"""],
	# 9. Último aliento: cae de rodillas con su clip (en vez de bajar el rig 24 px)
	["rendirse",
		"""	create_tween().tween_property(f["rig"], "position:y", f["rig_base"].y + 24.0, 0.5)
""",
		"""	if _p3d(f) != null and _p3d(f).has_method("rendirse"):     # V12, fase C: Gorthor cae de rodillas
		_p3d(f).rendirse()
	else:
		create_tween().tween_property(f["rig"], "position:y", f["rig_base"].y + 24.0, 0.5)
"""],
	# 10. Perdonado: se da la vuelta y se arrastra mientras el rig se desliza y se funde
	["perdon",
		"""	registro.text = "Kael baja la espada. %s se arrastra hacia el abismo." % f["nombre"].get_slice(" ", 0)
""",
		"""	registro.text = "Kael baja la espada. %s se arrastra hacia el abismo." % f["nombre"].get_slice(" ", 0)
	if _p3d(f) != null and _p3d(f).has_method("retirarse"):    # V12, fase C: a gatas, arrastrando la cuchilla
		_p3d(f).retirarse()
"""],
	# 11. Cuánto se ve la derrota antes de fundirse («caida» de MODELOS; sin ella, 0,9 s como siempre)
	["caida",
		"""				t.tween_interval(2.8 if Brama.es(f) else 0.9)   # V12, Bramavidrio: se ve desplomarse y hundirse
""",
		"""				t.tween_interval(2.8 if Brama.es(f) else float(MODELOS[f["modelo"]].get("caida", 0.9)))   # V12: Bramavidrio se ve desplomarse y hundirse; fase C: «caida»
"""],
]

# Valores medidos (pruebas/fotos_enemigos_v12.gd, «medir»): los pies en el mismo sitio que los del dibujo de antes y la
# distancia a la que su golpe llega al héroe.
const VALORES := {
	"%GUARDIAN_POS%": "-191, -186", "%GOLEM_POS%": "-79, 37", "%GORTHOR_POS%": "-60, -247",
	"%GUARDIAN_DIST%": "310.0", "%GOLEM_DIST%": "220.0", "%GORTHOR_DIST%": "220.0",
}


static func texto_de(i: int, cual: int) -> String:
	var t: String = CAMBIOS[i][cual]
	for k in VALORES:
		t = t.replace(k, VALORES[k])
	return t


# Devuelve {"ok": bool, "texto": el guion cambiado, "faltan": [nombres], "repetidos": [nombres]}.
static func aplicar(fuente: String) -> Dictionary:
	var faltan := []
	var repetidos := []
	var t := fuente.replace("\r\n", "\n")
	for i in CAMBIOS.size():
		var ancla := texto_de(i, 1)
		var n := t.count(ancla)
		if n == 0:
			faltan.append(CAMBIOS[i][0])
			continue
		if n > 1:
			repetidos.append(CAMBIOS[i][0])
			continue
		t = t.replace(ancla, texto_de(i, 2))
	return {"ok": faltan.is_empty() and repetidos.is_empty(), "texto": t, "faltan": faltan, "repetidos": repetidos}
