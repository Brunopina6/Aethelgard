extends RefCounted
# V12 (19/11/2026): Velaria, la polilla de alas como postigos de farol (T-097, bestiario 01; D-075: modelo de Meshy del
# usuario, licencia SIN CONFIRMAR → solo APK de prueba privadas). Modelo y clips rescatados de la copia de animaciones
# (enemigos/velaria/, velaria_3d.gd); ficha: REBELUM_Bestiario/Fichas_e_integracion.txt (destello_de_velo 0,70 s y
# corte_de_ala 0,50 s). Documento: docs/v12/VELARIA_V12.md.
#
# APAGADA: solo con su interruptor «velaria_v12» (Engine.set_meta("velaria_v12", true) o «-- velaria_v12»), que enciende
# el banco de pruebas de Auditoría en su caso («velaria», banco_pruebas.gd). Nunca sale al azar: solo en su combate de
# prueba GRUPOS[30], que hay que pedir a mano («-- grupo=30 velaria_v12»). Apagada, preparar() no cambia nada (queda la
# personalidad «agresivo» de ENEMIGOS: un golpe normal, que su modelo hace con el corte de ala) y no hay tiradas nuevas.
#
# Encendida (personalidad «velaria», turno()), como el Zarzalín (combate.gd _turno_zarzalin):
#   · destello_de_velo: proyectil ANUNCIADO. Un turno avisa: repliega las alas (avisar() del modelo; su señal «aviso»
#     suena UNA vez, «velaria_aviso_destello», por combate.gd _sonidos_bestia), «⚠ Cargando» sobre su vida, ningún daño.
#     El turno siguiente lo suelta a quien eligió (Garon puede cubrirle): al abrir las alas (señal «impacto», sonido
#     «velaria_destello», UNA vez) sale la luz; el daño se resuelve UNA vez al llegar (×MULT_DESTELLO; Defender, a la
#     mitad, como cualquier golpe). Luego «deja el centro visible»: el turno siguiente se recompone, sin atacar.
#   · corte_de_ala: vuela hasta el héroe, se eleva y pasa en diagonal; «velaria_aviso_corte» al empezar el clip y el
#     impacto (daño y «velaria_corte») UNA vez, en el ancla del clip (0,50 s). Vuelve volando a su sitio.
# Separación: IA = turno(); daño = combate.gd _animar_golpe (su impacto, una vez); presentación = velaria_3d.gd.
# Cifras PROPUESTAS, sin equilibrar: PROB_AVISO, MULT_DESTELLO y su fila de combate.gd ENEMIGOS.

const CLAVE := "velaria"
const PERSONALIDAD := "velaria"
const INTERRUPTOR := "velaria_v12"
const ACTIVO_POR_DEFECTO := false
const GRUPOS_PRUEBA := [30]
const DESTELLO := "destello_de_velo"
const CORTE := "corte_de_ala"
const AVISO_CORTE := "velaria_aviso_corte"      # sonido.gd (tanda 4): al empezar el clip del corte
const PROB_AVISO := 0.4                         # PROPUESTA (la del Zarzalín)
const MULT_DESTELLO := 1.5                      # PROPUESTA: «daño moderado» (el Zarzalín embiste a ×1,8)
const T_VIAJE := 0.3                            # segundos de vuelo de la luz hasta el héroe
const COLOR_LUZ := Color(1.0, 0.88, 0.58)
const FRENTE_RESPALDO := 0.3                    # m de la cabeza por delante de su sitio si no se puede medir


static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


# combate.gd _elegir_enemigos: con el interruptor, su personalidad (si no, nada).
static func preparar(e: Dictionary) -> void:
	if str(e.get("clave", "")) == CLAVE and activo():
		e["personalidad"] = PERSONALIDAD


# Velaria con su personalidad (la IA de turno()).
static func es(f) -> bool:
	return f is Dictionary and str(f.get("personalidad", "")) == PERSONALIDAD


# Velaria con su modelo 3D (encendida o no): sus ataques los anima animar_golpe().
static func de_ella(c, f) -> bool:
	return f is Dictionary and str(f.get("clave", "")) == CLAVE and c._p3d(f) != null \
		and c._p3d(f).has_method("avisar")


# ================================================================= IA (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var p = c._p3d(f)
	if f.get("recupera", false):                    # tras el destello: el centro visible, sin atacar
		f["recupera"] = false
		c.registro.text = "%s recompone las alas" % f["nombre"]
		c._numero_flotante(f, "Recompone", Color(0.8, 0.85, 0.75), 28)
		await c.get_tree().create_timer(0.8).timeout
		return
	if f.get("cargando", false):                    # avisó el turno anterior: suelta el destello
		f["cargando"] = false
		c._marcar_aviso(f, false)
		f["recupera"] = true
		var objetivo = f.get("objetivo_carga", null)
		if objetivo == null or objetivo["hp"] <= 0:
			objetivo = c._elegir_objetivo("agresivo", vivos)
		objetivo = c._cubre(objetivo)               # Garon puede cubrir al que avisó
		f.erase("objetivo_carga")
		c.registro.text = "¡%s suelta el destello sobre %s!" % [f["nombre"], objetivo["nombre"]]
		f["ataque_3d"] = DESTELLO
		await c._animar_golpe(f, objetivo, int(f["atk"] * MULT_DESTELLO * mult) + randi_range(-2, 3), "")
		f.erase("ataque_3d")
		return
	if randf() < PROB_AVISO:                        # avisa: repliega las alas y concentra la luz
		var objetivo: Dictionary = c._elegir_objetivo("agresivo", vivos)
		f["cargando"] = true
		c._marcar_aviso(f, true)
		f["objetivo_carga"] = objetivo
		c.registro.text = "%s repliega las alas y concentra la luz: ¡va a por %s!" % [f["nombre"], objetivo["nombre"]]
		c._numero_flotante(f, "⚠ ¡Destello!", Color(1.0, 0.8, 0.2), 32)
		c._actualizar()
		if p != null and p.has_method("avisar"):
			await p.avisar(DESTELLO)
		else:
			await c.get_tree().create_timer(1.0).timeout
		return
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))
	c.registro.text = "%s ataca a %s" % [f["nombre"], obj["nombre"]]
	f["ataque_3d"] = CORTE
	await c._animar_golpe(f, obj, int(f["atk"] * mult) + randi_range(-2, 3), "")
	f.erase("ataque_3d")


# ================================================================= animación (combate.gd _animar_golpe)

# El impacto de _animar_golpe (daño, Sonido.golpe y voz), UNA vez. Si cae a medias antes de golpear, no golpea.
static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var ataque := str(o.get("ataque_3d", CORTE))
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		impacto.call()
	if ataque == DESTELLO:
		await _destello(c, o, obj, golpe)
	else:
		await _corte(c, o, obj, golpe)
	if not hecho[0] and o["hp"] > 0:                 # sin el clip (o cortado): el golpe igualmente, una vez
		golpe.call()


# El corte de ala: vuela hasta el héroe y se planta donde su cabeza llega a él en el impacto del clip (como el Zarzalín:
# su sitio en reposo + el alcance del clip), el clip (con su avance) y vuelve volando.
static func _corte(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var m: Dictionary = c.MODELOS[o["modelo"]]
	var px_m: float = m["vp"].y / m["alto_vista"] * m["esc"]
	var adelante: float = _frente(p) + p.alcance(CORTE)
	var pies_x: float = c._centro(obj).x - 30.0 - adelante * px_m
	var destino := base + Vector2(pies_x - c._suelo_de(o).x, c._suelo_de(obj).y - c._suelo_de(o).y)
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	p.mirar(ida, 0.15)
	p.correr()                                       # su aleteo de vuelo
	var t1: Tween = c.create_tween()
	t1.tween_property(rig, "position", destino, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t1.finished
	p.mirar(ida, 0.1)
	c._sonar(AVISO_CORTE)                            # las bestias no tienen voz de «ataque»: su aviso hace ese papel
	await p.atacar(CORTE, golpe)
	if o["hp"] > 0:
		p.mirar(-ida, 0.2)
		p.correr()
	var t3: Tween = c.create_tween()
	t3.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t3.finished
	if o["hp"] > 0:
		p.mirar_frente(0.25)
		p.reposo()
	rig.z_index = 0
	o["animando"] = false


# El destello: desde su sitio. Al abrir las alas (el impacto del clip) la luz sale de su pecho y vuela hasta el héroe; el
# daño, al llegar. Desde el aviso, el clip sigue desde la luz concentrada (velaria_3d.gd atacar).
static func _destello(c, o: Dictionary, obj: Dictionary, golpe: Callable) -> void:
	var p = c._p3d(o)
	o["animando"] = true
	p.mirar(Vector3(1, 0, 0.1), 0.15)
	var llego := [false]
	var al_soltar := func():
		_volar(c, _pantalla_luz(c, o), c._centro(obj), func():
			golpe.call()
			llego[0] = true)
	await p.atacar(DESTELLO, al_soltar)
	var t0 := 0
	while not llego[0] and t0 < 60:                  # (la luz aún en el aire: espera a que llegue)
		await c.get_tree().process_frame
		t0 += 1
	if o["hp"] > 0:
		p.mirar_frente(0.25)
	o["animando"] = false


# La luz en vuelo: un brillo que crece un poco (con efectos reducidos se sigue viendo: es un solo sprite, sin partículas
# de por medio) y un estallido pequeño al llegar.
static func _volar(c, desde: Vector2, hasta: Vector2, al_llegar: Callable) -> void:
	var g: Sprite2D = c._brillo(COLOR_LUZ)
	g.z_index = 7
	g.position = desde
	g.scale = Vector2(0.45, 0.45)
	c.escena.add_child(g)
	var t: Tween = c.create_tween()
	t.tween_property(g, "position", hasta, T_VIAJE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(g, "scale", Vector2(0.8, 0.8), T_VIAJE)
	t.tween_callback(func():
		al_llegar.call()
		c._particulas(hasta, Color(COLOR_LUZ, 1.0), Color(COLOR_LUZ, 0.0), 16, 0.5, Vector2(80, 200), 30.0,
			Vector2(0, -1), 180.0, Vector2(0, 120), 0.1)
		g.queue_free())


# El pecho de Velaria (velaria_3d.gd luz()) en las medidas de la escena del combate.
static func _pantalla_luz(c, o: Dictionary) -> Vector2:
	var p = c._p3d(o)
	if p == null or not p.has_method("luz") or not o.has("cam3d") or not o.has("partes") \
			or not o["partes"].has("sprite"):
		return c._centro(o)
	var cam: Camera3D = o["cam3d"]
	var spr: Sprite2D = o["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(cam.unproject_position(p.luz())))


# Metros de la cabeza por delante de su sitio, en reposo (con su escala), medidos en las pistas del clip.
static func _frente(p) -> float:
	if p == null or not p.has_method("_cabeza_en"):
		return FRENTE_RESPALDO
	var z: float = p._cabeza_en("reposo", 0.0).z * float(p.escala)
	if z <= 0.0 or z > 1.5:
		return FRENTE_RESPALDO
	return z
