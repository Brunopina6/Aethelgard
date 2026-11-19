extends Node
# Animación de combate V12 (12/11/2026, especialista de animación de combate): combates 3D más vivos para los héroes v2
# (Kael, Lya y Garon). APAGADO por defecto: con el interruptor apagado combate.gd hace exactamente lo de siempre (cada
# enganche pregunta antes «activo()» y, si no, sigue por su camino de siempre).
#
# Se enciende (y solo vale con los héroes v2 cargados, personajes/heroes_v2/heroes_v2.gd) con cualquiera de estas:
#   - Engine.set_meta("combate_anim_v12", true)
#   - el argumento de usuario «combate_anim_v12»   (godot ... -- heroes_v2 combate_anim_v12)
#   - Ajustes → «Combate: animación v12 (prueba)» (user://ajustes.cfg, [combate] anim_v12)
#   - ACTIVO_POR_DEFECTO = true (cuando el usuario lo apruebe)
# Las cámaras de los grandes momentos se apagan aparte: Engine.set_meta("camaras_combate", false), el argumento
# «sin_camaras» o Ajustes ([combate] camaras).
#
# Qué cambia (encargo del 12/11: «nada de ataques en los que el personaje solo se desliza hacia el enemigo»):
#   - Ataque normal: anticipación (c12_arranque), carrera con los pies sin patinar (el personaje solo avanza en pantalla
#     lo que avanza el clip de correr: velocidad del clip × velocidad de reproducción × píxeles por metro, y si se acelera
#     o frena, el clip con él), frenada (c12_frenada) o salto, golpe con su impacto de siempre, pausa de impacto
#     (hit-stop: el atacante y el golpeado se congelan un instante), reacción del enemigo (retroceso), y vuelta con
#     recuperación: Kael a brincos hacia atrás sin dar la espalda (c12_salto_atras), Lya y Garon se giran, corren y
#     frenan. Mientras los pies tocan el suelo el personaje no se mueve en pantalla.
#   - Magia de Kael y Lya: preparación visible (Kael concentra con el sable vertical, c12_magia_carga; Lya, su
#     magia_concentrar) con el círculo y la luz reuniéndose en el arma; lanzamiento, impacto con onda y destello.
#   - Técnicas: Juicio y Giro de Garon con su preparación (c12_tecnica_carga: cruza las espadas y las abre), Embuir
#     (c12_embuir), Filo Arcano y Quiebra (Kael carga el sable sobre la cabeza antes de lanzarse); cámara corta.
#   - Reacciones: golpe ligero (recibir_golpe), fuerte (c12_recibir_fuerte, con un paso atrás), bloqueo con la defensa
#     puesta (c12_bloqueo y la postura c12_defensa mientras dura), victoria escalonada.
#   - Cámara: un acercamiento corto (≤ 10 %, sin giros) hacia la acción en las técnicas, los dúos y la victoria. Nunca en
#     los combates de jefe (su encuadre está medido: Bramavidrio, Humbaba, el Coloso, el Guardián).
# Instantes que NO cambian: impacto de Kael a 0,64 s del salto (con _impacto_fuerte, el temblor de siempre), Lya golpea
# 0,28 s después de preparar y el impacto llega 0,1 s más tarde, Juicio 1,10 s y Giro 0,90/1,50 s del clip, la magia
# de Kael a 0,85 s y la de Lya a 0,5 s de lanzar. El daño y el sonido van en esas mismas llamadas a «impacto».
# Nada de aquí usa randf()/randi() globales ni crea CPUParticles2D (cada una toma su semilla del azar global): las
# chispas son sprites propios con su generador. Con «ATB al ritmo de siempre» (pausa_atb, por defecto), el azar y el
# orden de los turnos del combate son los de la animación de siempre.

const ACTIVO_POR_DEFECTO := false
const BIBLIOTECA := "res://personajes/heroes_v2/%s/%s_v2_combate_v12.glb"   # importado como AnimationLibrary
const BUCLES := ["c12_defensa", "c12_magia_carga", "c12_carrera"]
const PARADA := 0.085               # s de pausa de impacto (hit-stop) en un golpe normal
const PARADA_FUERTE := 0.12         # en un golpe de técnica
const RETROCESO := 22.0             # px que retrocede el golpeado (los grandes y los jefes no se mueven)
const ZOOM_MAX := 1.1               # acercamiento máximo de la cámara
const RETRASO_VICTORIA := {"Kael": 0.0, "Lya": 0.22, "Garon": 0.45}

var _impacto := Callable()          # el «impacto» de combate.gd de camino al nodo (ver ataque_kael() y _tomar_impacto())



# ---------------------------------------------------------------- interruptores
static func activado() -> bool:
	if Engine.has_meta("combate_anim_v12"):
		return bool(Engine.get_meta("combate_anim_v12"))
	if "combate_anim_v12" in OS.get_cmdline_user_args():
		return true
	return _ajuste("anim_v12", ACTIVO_POR_DEFECTO)


static func camaras() -> bool:
	if Engine.has_meta("camaras_combate"):
		return bool(Engine.get_meta("camaras_combate"))
	if "sin_camaras" in OS.get_cmdline_user_args():
		return false
	return _ajuste("camaras", true)


# 13/11: el ATB al ritmo de siempre. Mientras un héroe ejecuta su acción v12 (de la anticipación a la recuperación), las
# barras se llenan solo durante lo que duraba esa misma acción antes (DURACION_ANTES, medido en el combate de verdad con
# la animación de siempre) y se quedan quietas el resto; si la acción v12 es más corta, el héroe espera en guardia lo
# que falte. Así el orden de los turnos y lo que cargan los enemigos mientras actúa un héroe son los de siempre aunque
# la animación dure otra cosa (una pausa total regalaría ese tiempo a los héroes: cambiaría el equilibrio).
# Encendido por defecto con la v12; se apaga con Engine.set_meta("pausa_atb_v12", false), «sin_pausa_atb» o Ajustes
# ([combate] pausa_atb): entonces las barras corren durante toda la acción, como en la primera entrega.
static func pausa_atb() -> bool:
	if Engine.has_meta("pausa_atb_v12"):
		return bool(Engine.get_meta("pausa_atb_v12"))
	if "sin_pausa_atb" in OS.get_cmdline_user_args():
		return false
	return _ajuste("pausa_atb", true)


# combate.gd, _process: true si el ATB debe quedarse quieto este fotograma (hay una acción v12 de héroe en curso).
static func atb_en_pausa(c: Node) -> bool:
	if int(c.get_meta("c12_accion", 0)) <= 0 or not pausa_atb():
		return false
	var resto: float = float(c.get_meta("c12_atb_resto", 0.0))
	if resto > 0.0:                                 # aún dentro de lo que duraba la acción de siempre: corre
		c.set_meta("c12_atb_resto", resto - c.get_process_delta_time())
		return false
	return true


# Fotogramas (a 30 por segundo) que duraba cada acción con la animación de siempre (prueba_combate_anim_v12.gd,
# «DURACION apagado», combate de tres con los héroes v2): de que empieza a animar a que acaba.
const DURACION_ANTES := {"ataque_Kael": 71, "ataque_Lya": 56, "atacar_juicio": 102, "atacar_giro": 91,
	"magia_Kael": 93, "magia_Lya": 83}


static func _accion(c: Node, d: int, tipo := "") -> void:
	if is_instance_valid(c):
		var n: int = maxi(0, int(c.get_meta("c12_accion", 0)) + d)
		c.set_meta("c12_accion", n)
		if d > 0:
			c.set_meta("c12_atb_resto", float(DURACION_ANTES.get(tipo, 60)) / 30.0)


# Al acabar la acción v12: si duró menos que la de siempre, espera en guardia lo que falte (con el ATB corriendo).
static func _fin_accion(c: Node) -> void:
	if is_instance_valid(c) and pausa_atb():
		var resto: float = float(c.get_meta("c12_atb_resto", 0.0))
		if resto > 0.0:
			await c.get_tree().create_timer(resto).timeout
	_accion(c, -1)


static func _ajuste(clave: String, defecto: bool) -> bool:
	var cf := ConfigFile.new()
	if cf.load("user://ajustes.cfg") != OK:
		return defecto
	return bool(cf.get_value("combate", clave, defecto))


# Ajustes (menus.gd): lo guarda en user://ajustes.cfg y lo pone ya en Engine.
static func elegir_en_ajustes(clave: String, si: bool) -> Error:
	Engine.set_meta({"anim_v12": "combate_anim_v12", "camaras": "camaras_combate", "pausa_atb": "pausa_atb_v12"}.get(clave, clave), si)
	var cf := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := cf.load("user://ajustes.cfg")
		if err != OK:
			return err
	cf.set_value("combate", clave, si)
	return cf.save("user://ajustes.cfg")


# ¿Este luchador usa la animación v12? Héroe v2 con su biblioteca de clips de combate cargada.
static func activo(f: Dictionary) -> bool:
	if not f.get("hero", false) or not activado():
		return false
	var p = f.get("p3d", null)
	if p == null or not is_instance_valid(p) or p.get("es_v2") != true or p.get("anim") == null:
		return false
	return _preparar(p, str(f.get("nombre", "")))


# Añade los clips c12_* a la biblioteca del AnimationPlayer del héroe (una vez). Los clips v2 de siempre no se tocan.
static func _preparar(p, nombre: String) -> bool:
	if p.has_meta("c12"):
		return bool(p.get_meta("c12"))
	var ruta := BIBLIOTECA % [nombre.to_lower(), nombre.to_lower()]
	var ok := false
	if ResourceLoader.exists(ruta):
		var extra = load(ruta)
		var anim: AnimationPlayer = p.anim
		if extra is AnimationLibrary and anim.has_animation_library(""):
			var lib: AnimationLibrary = anim.get_animation_library("")
			for n in extra.get_animation_list():
				var a: Animation = extra.get_animation(n)
				a.loop_mode = Animation.LOOP_LINEAR if String(n) in BUCLES else Animation.LOOP_NONE
				if not lib.has_animation(n):
					lib.add_animation(n, a)
			ok = lib.has_animation("c12_arranque")
	if ok and p.skel != null:                        # altura del tobillo en reposo (para saber si va en el aire)
		var sk: Skeleton3D = p.skel
		var y := INF
		for n in ["mixamorig_LeftFoot", "mixamorig_RightFoot"]:
			var i := sk.find_bone(n)
			if i >= 0:
				y = minf(y, p.to_local(sk.global_transform * sk.get_bone_global_rest(i).origin).y)
		if y < INF:
			p.set_meta("c12_tobillo", y)
	p.set_meta("c12", ok)
	return ok


static func _clip(p, nombre: String, fundido := 0.12, vel := 1.0) -> float:
	if p.v2 == null:
		return 0.0
	return p.v2.reproducir(nombre, fundido, vel)


func _esperar(c: Node, s: float) -> void:
	if s > 0.0:
		await c.get_tree().create_timer(s).timeout


# Píxeles de la escena por metro del modelo (ventana 3D ortográfica: alto en píxeles / alto en metros, por su escala)
static func px_metro(c: Node, f: Dictionary) -> float:
	var m: Dictionary = c.MODELOS[f["modelo"]]
	return float(m["vp"].y) / float(m["alto_vista"]) * float(m.get("esc", c.ESC))


static func es_jefe_combate(c: Node) -> bool:
	if c.brama != null:
		return true
	for e in c.enemigos:
		if e.get("personalidad", "") in ["jefe", "bosque", "coloso"] or c.Humbaba.es(e):
			return true
	return false


# ---------------------------------------------------------------- desplazamiento sin patinar
const CARRERA_MIN := 150.0        # px: más cerca no corre (Kael salta desde su sitio; Lya y Garon dan un saltito)
const FUNDIDO_CARRERA := 0.2        # s: lo que tarda en entrar el clip de correr (play() de maga_3d.gd); el avance crece con él

# Corre hasta «hacia» (posición del rig): cada fotograma avanza vel_correr × speed_scale × px/m × dt (por el peso del
# clip de correr mientras entra), con el clip de correr a esa misma speed_scale: sube de 0,75 a «ss» al arrancar y, con
# «frenar» > 0, baja a 0,55 en los últimos «frenar» px. Así el pie apoyado no se mueve en pantalla.
# Como cada px recorrido es un tramo fijo del clip, en qué punto del paso se llega depende solo de la distancia: el clip
# empieza en el instante justo para que la llegada caiga en la FASE DE VUELO de la carrera (los dos pies en el aire),
# y la frenada o el salto que siguen empiezan en el aire (su primer apoyo es la llegada, sin pies que se recoloquen
# sobre el suelo). Devuelve la velocidad en pantalla (px/s) al llegar.
func _correr(c: Node, o: Dictionary, hacia: Vector2, ss := 1.15, frenar := 0.0) -> float:
	var p = o["p3d"]
	var rig: Node2D = o["rig"]
	var pxm := px_metro(c, o)
	var carrera := _carrera(p)
	var real: String = carrera[0]
	var v: float = carrera[1]
	var dt := c.get_process_delta_time()
	if dt <= 0.0:
		dt = 1.0 / 30.0
	var vuelo: Dictionary = _fases_vuelo(p, real)
	if real == "c12_carrera":                      # Garon: su carrera hecha por IK (la de captura arrastra los pies)
		p.gestos.quitar_todos(0.15)
		_clip(p, real, FUNDIDO_CARRERA)
		if p.has_method("_viento"):
			p._viento(1.2)
	else:
		p.correr()
	if real == "c12_carrera":                      # la de Garon empieza con el pie de delante apoyado (como acaba el arranque)
		var ciclo: float = p.anim.get_animation(real).length   # y acaba en su vuelo (0,45 del ciclo, o 0,95): el paso se
		var T := _simular(absf(hacia.x - rig.position.x), v, pxm, ss, frenar, dt)   # estira o encoge ≤ 15 % para que quepa
		var m := maxi(0, roundi((T - 0.45 * ciclo) / (ciclo * 0.5)))
		v *= clampf(T / (0.45 * ciclo + m * ciclo * 0.5), 0.85, 1.15)
		p.anim.seek(0.0, true)
	elif not vuelo.is_empty():                     # arranca el clip donde haga falta para llegar en el aire
		var T := _simular(absf(hacia.x - rig.position.x), v, pxm, ss, frenar, dt)
		p.anim.seek(fposmod(float(vuelo["centro"]) - T, float(vuelo["ciclo"])), true)
	var t := 0.0
	var tope := 6.0
	var vpx := 0.0
	var paso_dt := 0.0
	var pies_ant := _pies(p)
	var modo: int = p.anim.callback_mode_process        # el clip avanza aquí, antes de mover el cuerpo (sin un fotograma de retraso)
	p.anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	var v_pie := 0.0                               # última velocidad del pie apoyado (px/s), para las fases de vuelo
	var base_y: float = p.get_meta("c12_tobillo", 0.08)
	# En horizontal, el cuerpo avanza en pantalla lo que retrocede el pie apoyado en el clip (el pie queda clavado aunque
	# el clip de correr esté entrando o cambie de ritmo); en el aire, a la última velocidad. El desplazamiento vertical
	# en pantalla (la profundidad del escenario 2D, que los pies del clip no hacen) va a la par: una diagonal suave, sin
	# saltos (en una diagonal el pie apoyado se mueve algo en vertical; medido aparte en la prueba).
	while is_instance_valid(rig) and tope > 0.0:
		var resto := hacia - rig.position
		var dx := absf(resto.x)
		var k := _k_carrera(t, dx, ss, frenar)
		p.anim.speed_scale = k
		vpx = v * k * pxm * clampf(t / FUNDIDO_CARRERA, 0.0, 1.0)
		var paso := vpx * paso_dt
		if paso_dt > 0.0:
			p.anim.advance(paso_dt)
		var pies := _pies(p)                       # la pose de este fotograma
		if paso_dt > 0.0:
			var lado := 0 if pies[0].y <= pies[1].y else 1
			# apoyado: el más bajo de los dos, claramente, y casi sin moverse en vertical (Lya corre de puntillas: el
			# tobillo no baja a su altura de reposo)
			if pies[lado].y < pies[1 - lado].y - 0.02 and absf(pies[lado].y - pies_ant[lado].y) < 0.012:
				v_pie = absf(pies[lado].x - pies_ant[lado].x) * pxm / paso_dt
			if t > FUNDIDO_CARRERA or v_pie > 0.0:
				paso = clampf(v_pie * paso_dt, paso * 0.6, paso * 1.4)   # (con un margen: nunca se para ni se dispara)
		pies_ant = pies
		var nuevo := rig.position
		nuevo.x += signf(resto.x) * minf(paso, dx)
		if absf(resto.y) > 0.01 and dx > 0.0:          # en vertical, a la par que en horizontal (una diagonal suave)
			nuevo.y += resto.y * minf(paso, dx) / dx
		rig.position = nuevo
		if dx <= paso:                               # (lo que quede en vertical lo hace el salto o la frenada, en el aire)
			break
		await c.get_tree().process_frame
		paso_dt = c.get_process_delta_time()
		t += paso_dt
		tope -= paso_dt
	if is_instance_valid(p):
		p.anim.callback_mode_process = modo
	return vpx


static func _k_carrera(t: float, dist: float, ss: float, frenar: float) -> float:
	var k := lerpf(0.75, ss, clampf(t / 0.15, 0.0, 1.0))
	if frenar > 0.0:
		k = minf(k, lerpf(0.55, ss, clampf(dist / frenar, 0.0, 1.0)))
	return k


# Tiempo de clip (s) que pasa en una carrera de «d» px con el mismo perfil que _correr.
static func _simular(d: float, v: float, pxm: float, ss: float, frenar: float, dt: float) -> float:
	var t := 0.0
	var hecho := 0.0
	var clip := 0.0
	var paso_dt := 0.0
	while t < 6.0:
		var k := _k_carrera(t, d - hecho, ss, frenar)
		var paso := v * k * pxm * clampf(t / FUNDIDO_CARRERA, 0.0, 1.0) * paso_dt
		clip += k * paso_dt
		if paso >= d - hecho:
			break
		hecho += paso
		paso_dt = dt
		t += dt
	return clip


# Fases de vuelo del clip de correr de este héroe (una vez; se guarda en el nodo): {ciclo, centro} = la duración del
# clip y el centro de su fase de vuelo más larga. Se mide poniendo el esqueleto en 32 instantes del clip y volviendo a
# dejarlo como estaba en el mismo fotograma (no se llega a dibujar).
static func _fases_vuelo(p, real: String) -> Dictionary:
	if p.has_meta("c12_vuelo_" + real):
		return p.get_meta("c12_vuelo_" + real)
	var r := {}
	var anim: AnimationPlayer = p.anim
	if anim.has_animation(real) and p.skel != null:
		var largo := anim.get_animation(real).length
		var antes := String(anim.assigned_animation)
		var pos := anim.current_animation_position
		var vel := anim.speed_scale
		var n := 32
		var aire := []
		var vels := []                             # velocidad del pie más bajo (m/s) entre muestras con el mismo pie
		var ant := []
		for i in n:
			anim.play(real, 0.0)
			anim.seek(largo * i / n, true)
			aire.append(_en_vuelo(p))
			var pies := _pies(p)
			var lado := 0 if pies[0].y <= pies[1].y else 1
			if not ant.is_empty() and ant[0] == lado:
				var dd: Vector3 = pies[lado] - ant[1]
				dd.y = 0.0
				vels.append(dd.length() / (largo / n))
			ant = [lado, pies[lado]]
		if antes != "":
			anim.play(antes, 0.0)
			anim.seek(pos, true)
		anim.speed_scale = vel
		# el tramo en el aire más largo (dando la vuelta al final del ciclo)
		var mejor := [-1, 0]
		for i in n:
			if aire[i] and not aire[(i - 1 + n) % n]:
				var j := 0
				while j < n and aire[(i + j) % n]:
					j += 1
				if j > mejor[1]:
					mejor = [i, j]
		if mejor[0] >= 0:
			r = {"ciclo": largo, "centro": largo * (mejor[0] + (mejor[1] - 1) * 0.5) / n, "muestras": mejor[1]}
		if not vels.is_empty():
			vels.sort()
			r["vel"] = vels[vels.size() / 2]
	p.set_meta("c12_vuelo_" + real, r)
	return r


# Cuánto está en el aire (0 = un pie en el suelo, 1 = los dos tobillos 5 cm o más por encima de su reposo).
static func _aire(p) -> float:
	var sk: Skeleton3D = p.skel
	var base: float = p.get_meta("c12_tobillo", 0.08)
	var bajo := INF
	for n in ["mixamorig_LeftFoot", "mixamorig_RightFoot"]:
		var i := sk.find_bone(n)
		if i >= 0:
			bajo = minf(bajo, p.to_local(sk.global_transform * sk.get_bone_global_pose(i).origin).y)
	return clampf((bajo - base - 0.01) / 0.04, 0.0, 1.0) if bajo < INF else 0.0


# Los dos pies en el aire (en la carrera): tobillos más de 3,5 cm por encima de su altura en reposo.
static func _en_vuelo(p) -> bool:
	var sk: Skeleton3D = p.skel
	var base: float = p.get_meta("c12_tobillo", 0.08)
	for n in ["mixamorig_LeftFoot", "mixamorig_RightFoot"]:
		var i := sk.find_bone(n)
		if i < 0:
			return false
		if p.to_local(sk.global_transform * sk.get_bone_global_pose(i).origin).y < base + 0.035:
			return false
	return true


# Frena: c12_frenada empieza en el aire; el cuerpo sigue a la velocidad que traía hasta su «parado» (el primer apoyo)
# y ahí se queda. Devuelve la duración del clip.
static func _frenada(c: Node, o: Dictionary, destino: Vector2) -> float:
	var p = o["p3d"]
	var d := _clip(p, "c12_frenada", 0.06)
	p.anim.speed_scale = 1.0
	var parado := d * 0.17
	var rig: Node2D = o["rig"]
	var tw := c.create_tween()
	tw.tween_property(rig, "position", destino, parado).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	return d


# Se da la vuelta con pasos en el sitio (clip «girar» de los héroes v2) mientras el modelo gira.
func _girar(c: Node, o: Dictionary, dir: Vector3, dur := 0.26) -> void:
	var p = o["p3d"]
	if p.anim.has_animation("girar"):
		_clip(p, "girar", 0.08, p.anim.get_animation("girar").length / maxf(dur * 1.6, 0.1))
	p.mirar(dir, dur)
	await _esperar(c, dur)


static func _vel_px(c: Node, o: Dictionary, ss: float) -> float:
	return float(_carrera(o["p3d"])[1]) * ss * px_metro(c, o)


# El clip de correr de este héroe y su velocidad sin patinar (m/s a velocidad 1): c12_carrera (Garon) medida en el clip;
# si no, su «correr» con vel_correr (medida por prueba_anim_pies.gd).
static func _carrera(p) -> Array:
	if p.anim.has_animation("c12_carrera"):
		var m := _fases_vuelo(p, "c12_carrera")
		if m.has("vel"):
			return ["c12_carrera", float(m["vel"])]
	var v: float = float(p.get("vel_correr")) if p.get("vel_correr") != null else 3.8
	return [String(p.nombres.get("Running", "correr")), v]


# Brincos hacia atrás de cara al enemigo (Kael): el cuerpo solo se mueve en el aire (de «despegue» a «aterrizaje»).
func _brincos(c: Node, o: Dictionary, hasta: Vector2, n: int, vel := 1.2) -> void:
	var p = o["p3d"]
	var rig: Node2D = o["rig"]
	var desde := rig.position
	var despegue := 0.19 / vel
	var aterrizaje := 0.44 / vel
	var dur := 0.62 / vel
	for i in n:
		var a := desde.lerp(hasta, float(i) / n)
		var b := desde.lerp(hasta, float(i + 1) / n)
		_clip(p, "c12_salto_atras", 0.1 if i == 0 else 0.06, vel)
		await _esperar(c, despegue)
		var tw := c.create_tween()
		tw.tween_method(func(k: float):
			if not is_instance_valid(rig):
				return
			var q := a.lerp(b, k)
			o["suelo_salto"] = q.y
			rig.position = q + Vector2(0, -26.0 * 4.0 * k * (1.0 - k)), 0.0, 1.0, aterrizaje - despegue)
		await tw.finished
		o.erase("suelo_salto")
		await _esperar(c, (dur - aterrizaje) * (0.55 if i < n - 1 else 1.0))


# ---------------------------------------------------------------- pausa de impacto y reacción del golpeado
func _parada(c: Node, quienes: Array, dur: float) -> void:
	var guardados := []
	for f in quienes:
		var p = f.get("p3d", null) if f is Dictionary else null
		if p == null or not is_instance_valid(p):
			continue
		var a = p.get("anim")
		if a is AnimationPlayer and a.speed_scale != 0.0:
			guardados.append([a, a.speed_scale])
			a.speed_scale = 0.0
	if guardados.is_empty():
		return
	await c.get_tree().create_timer(dur).timeout
	for g in guardados:
		if is_instance_valid(g[0]) and g[0].speed_scale == 0.0:
			g[0].speed_scale = g[1]


static func _retroceso(c: Node, o: Dictionary, obj: Dictionary, fuerza := 1.0) -> void:
	if obj.get("hp", 0) <= 0 or obj.get("hero", false) or obj.get("animando", false) or es_jefe_combate(c):
		return
	var m: Dictionary = c.MODELOS.get(obj["modelo"], {})
	if m.has("pies_como") or m.has("pos_golpe") or not obj.has("rig_base"):
		return
	var rig: Node2D = obj["rig"]
	var base: Vector2 = obj["rig_base"]
	var lado := signf(obj["pos"].x - o["pos"].x)
	if lado == 0.0:
		lado = -1.0
	var tw := c.create_tween()
	tw.tween_interval(PARADA * 0.5)
	tw.tween_property(rig, "position", base + Vector2(lado * RETROCESO * fuerza, 0), 0.07).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(rig, "position", base, 0.32).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# Efecto del golpe: un arco de luz del color del arma y unas chispas (CPUParticles2D: su azar es suyo, no el del
# combate). Pocas partículas y aditivas pequeñas (presupuesto Android: ≤ 14 chispas y un trazo de 3 líneas).
static func _tajo(c: Node, centro: Vector2, color: Color, lado: float, grande := false) -> void:
	var r := 70.0 if not grande else 95.0
	var pts := PackedVector2Array()
	var a0 := -2.2
	var a1 := 0.5
	for i in 9:
		var a := lerpf(a0, a1, i / 8.0)
		pts.append(centro + Vector2(cos(a) * lado * -1.0, sin(a)) * r + Vector2(0, -10))
	c._trazo_luz(pts, color, 0.55 if not grande else 0.8, 0.16)
	_chispas(c, centro, color.lightened(0.5), 14 if grande else 9, 0.32, Vector2(140, 320), Vector2(-lado, -0.4), 70.0,
		Vector2(0, 500), 0.07)


static func _color_arma(nombre: String) -> Color:
	return {"Kael": Color(0.75, 0.9, 1.0), "Lya": Color(1.0, 0.92, 0.7), "Garon": Color(1.0, 0.62, 0.32)}.get(nombre, Color.WHITE)


# Envuelve el impacto de siempre: lo llama tal cual (daño, sonido, número, temblor…) y después la pausa, el retroceso y
# el efecto.
func _con_impacto(c: Node, o: Dictionary, obj: Dictionary, impacto: Callable, fuerte := false) -> Callable:
	return func():
		impacto.call()
		var lado := signf(obj["pos"].x - o["pos"].x)
		_tajo(c, c._centro(obj), _color_arma(str(o.get("nombre", ""))), lado if lado != 0.0 else -1.0, fuerte)
		_retroceso(c, o, obj, 1.4 if fuerte else 1.0)
		_parada(c, [o, obj], PARADA_FUERTE if fuerte else PARADA)


# ---------------------------------------------------------------- cámara (acercamientos cortos, sin giros)
# Acerca la escena (luchadores y fondo) hacia «foco» (punto de la escena) a «zoom», en «ida» s, lo sostiene «queda» s y
# vuelve en «vuelta» s. Nada en los combates de jefe ni con las cámaras apagadas. La interfaz no se mueve.
static func camara(c: Node, foco: Vector2, zoom := 1.07, ida := 0.25, queda := 0.4, vuelta := 0.35) -> void:
	if not camaras() or es_jefe_combate(c) or c.escena == null:
		return
	zoom = clampf(zoom, 1.0, ZOOM_MAX)
	var esc: Node2D = c.escena
	var fondo = c.fondo_nodo
	var e_pos0: Vector2 = c.PIVOTE_ESCENA * (1.0 - c.TAM_ESCENA)
	var e_esc0: float = c.TAM_ESCENA
	var en_pantalla: Vector2 = e_pos0 + foco * e_esc0
	en_pantalla = en_pantalla.lerp(Vector2(640, 380), 0.35)   # no lo centra del todo: menos movimiento
	var previo = c.get_meta("c12_camara") if c.has_meta("c12_camara") else null   # (el tween va en el combate)
	if previo is Tween and previo.is_valid():
		previo.kill()
	var aplicar := func(k: float):
		var z := lerpf(1.0, zoom, k)
		if is_instance_valid(esc):
			esc.scale = Vector2.ONE * e_esc0 * z
			esc.position = en_pantalla + (e_pos0 - en_pantalla) * z
		if fondo != null and is_instance_valid(fondo):
			fondo.scale = Vector2.ONE * z
			fondo.position = en_pantalla + (Vector2.ZERO - en_pantalla) * z
	var tw := c.create_tween()
	c.set_meta("c12_camara", tw)
	tw.tween_method(aplicar, 0.0, 1.0, ida).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_interval(queda)
	tw.tween_method(aplicar, 1.0, 0.0, vuelta).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ---------------------------------------------------------------- ataques
# Kael (combate.gd, _anim_salto_3d): anticipación, carrera, el salto con corte de siempre (impacto a 0,64 s),
# pausa, y brincos hacia atrás de cara al enemigo.
func i_ataque_kael(c: Node, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var k = o["p3d"]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var dx: float = c._pos_ataque(obj).x - o["pos"].x + c.ANIM[o["modelo"]]["distancia"]
	var despegue := base + Vector2(dx + 70.0, 0.0)
	var duo: bool = o.get("filo_arcano", false) or c.golpe_ruptura   # Filo Arcano o Quiebra: técnica combinada
	o["animando"] = true
	rig.z_index = 5
	k.mirar(Vector3(-1, 0, 0.1), 0.12)
	if duo:                                          # carga el sable sobre la cabeza (con el fuego de Lya, si lo hay)
		_clip(k, "c12_tecnica_carga", 0.15)
		k.expresion("decidido")
		var col: Color = Color(1.0, 0.55, 0.2) if o.get("filo_arcano", false) else c.C_RUNA
		_chispas(c, c._centro(o) + Vector2(0, -60), col, 12, 0.6, Vector2(30, 80), Vector2(0, -1), 60.0, Vector2(0, -40), 0.06)
		camara(c, (c._centro(o) + c._centro(obj)) * 0.5, 1.08, 0.3, 1.2, 0.45)
		await _esperar(c, 0.55)
	var ss := 1.2
	var lejos := rig.position.distance_to(despegue) >= CARRERA_MIN
	if lejos:                                        # carrerilla: anticipación y carrera hasta el despegue
		_clip(k, "c12_arranque", 0.1)
		await _esperar(c, 0.22)
		var aterriza := _vel_px(c, o, ss) * 0.06 * 0.8        # lo que aún avanza en el aire al empezar el salto
		await _correr(c, o, despegue + Vector2(aterriza, 0), ss)
	# el salto de siempre (ataque_salto de kael_v2_3d.gd: impacto a 0,64 s), con la pausa del impacto
	k.mirar(Vector3(-1, 0, 0.3), 0.1)
	k.gestos.quitar_todos(0.1)
	_clip(k, "ataque", 0.1)
	k.expresion("grito", 1.0)
	var salida := rig.position                       # cerca: salta desde su sitio (el salto cubre toda la distancia)
	if lejos:
		var tw0 := c.create_tween()                  # llega en el aire: aún avanza un poco hasta apoyar
		tw0.tween_property(rig, "position", despegue, 0.06).set_ease(Tween.EASE_OUT)
		salida = despegue
	var golpe := _con_impacto(c, o, obj, Callable(c, "_impacto_fuerte").bind(impacto), duo)
	await _esperar(c, c.SALTO_T[0])
	_sonido(c).efecto("salto")
	c._voz(o, "ataque")
	var llegada := despegue + Vector2(-70, 0)
	o["suelo_salto"] = salida.y
	var despega := 0.07                              # el clip despega los pies a 0,27 s: el arco empieza ahí (antes, a 0,2 s, subía con los pies en el suelo)
	await _esperar(c, despega)
	var s1: float = c.SALTO_T[1] - despega
	var s2: float = c.SALTO_T[2]
	var t2 := c.create_tween()                       # el mismo arco de siempre (sube 130 px; 40 de 70 px al subir)
	t2.tween_method(func(s: float):
		var fx := 0.0
		var fy := 0.0
		if s <= s1:
			var e := 1.0 - (1.0 - s / s1) * (1.0 - s / s1)
			fx = 40.0 / 70.0 * e
			fy = e
		else:
			var e := (s - s1) / s2 * (s - s1) / s2
			fx = 40.0 / 70.0 + 30.0 / 70.0 * e
			fy = 1.0 - e
		if not lejos:                                # desde su sitio: el avance empieza al despegar
			fx = smoothstep(0.06, s1 + s2, s)
		if is_instance_valid(rig):
			var b := salida.lerp(llegada, fx)
			o["suelo_salto"] = b.y
			rig.position = b + Vector2(0, -130.0 * fy), 0.0, s1 + s2, s1 + s2)
	await t2.finished
	rig.position = llegada
	o.erase("suelo_salto")
	golpe.call()                                     # 0,64 s: el impacto de siempre (daño, sonido, temblor)
	await _esperar(c, (PARADA_FUERTE if duo else PARADA) + 0.4)
	# vuelve a brincos, de cara al enemigo
	k.mirar(Vector3(-1, 0, 0.1), 0.15)
	await _brincos(c, o, base, 2, 1.25)
	k.mirar_frente(0.25)
	k.reposo()
	rig.z_index = 0
	o["animando"] = false


# Lya (combate.gd, _anim_fisico_3d): anticipación, carrera, frenada, el golpe de cetro de siempre (golpea 0,28 s después
# de preparar, impacto 0,1 s después), pausa, y vuelta corriendo.
func i_ataque_lya(c: Node, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var maga = o["p3d"]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var dx: float = c._pos_ataque(obj).x - o["pos"].x + c.ANIM[o["modelo"]]["distancia"]
	var dy: float = (c._pos_ataque(obj).y - o["pos"].y) * 0.8
	var sitio = c._sitio_golpe(o, obj)
	if sitio != null:
		dx = sitio.x - base.x
		dy = sitio.y - base.y
	var destino := base + Vector2(dx, dy)
	o["animando"] = true
	rig.z_index = 5
	maga.mirar(Vector3(-1, 0, 0.1), 0.12)
	_clip(maga, "c12_arranque", 0.1)
	await _esperar(c, 0.24)
	await _ir_y_frenar(c, o, destino, 1.0)
	maga.preparar_golpe()
	c._voz(o, "ataque")
	await _esperar(c, 0.28)
	maga.golpear()
	await _esperar(c, 0.1)
	_con_impacto(c, o, obj, impacto).call()
	await _esperar(c, PARADA + 0.22)
	maga.fin_golpe()
	await _esperar(c, 0.06)
	await _volver_corriendo(c, o, base, 1.3, 0.2)   # 13/11: vuelta más corta (más deprisa y sin pausas largas)
	rig.z_index = 0
	o["animando"] = false


# Corre hasta «destino» y frena (c12_frenada) sin pasarse: la carrera acaba antes lo que avanza el cuerpo al frenar.
func _ir_y_frenar(c: Node, o: Dictionary, destino: Vector2, ss: float) -> void:
	var rig: Node2D = o["rig"]
	var dir := (destino - rig.position).normalized()
	if rig.position.distance_to(destino) < CARRERA_MIN:   # cerca: un saltito (la frenada más lenta, que empieza en el aire)
		var p = o["p3d"]
		var d := _clip(p, "c12_frenada", 0.1, 0.7)
		var aire := 0.42 * 0.17 / 0.7 + 0.05
		var desde := rig.position
		var tw := c.create_tween()
		tw.tween_method(func(k: float):
			if is_instance_valid(rig):
				o["suelo_salto"] = desde.lerp(destino, k).y
				rig.position = desde.lerp(destino, k) + Vector2(0, -18.0 * 4.0 * k * (1.0 - k)), 0.0, 1.0, aire)
		await tw.finished
		o.erase("suelo_salto")
		await _esperar(c, d * 0.62 - aire)
		return
	var parado := 0.42 * 0.17                          # c12_frenada: el primer apoyo
	var hasta := destino - dir * _vel_px(c, o, 0.55) * parado * 0.8
	await _correr(c, o, hasta, ss, 110.0)
	var d := _frenada(c, o, destino)
	await _esperar(c, d * 0.62)


# Se gira, corre a su sitio, frena y se vuelve hacia los enemigos (Lya y Garon).
func _volver_corriendo(c: Node, o: Dictionary, base: Vector2, ss := 1.05, giro := 0.24) -> void:
	var p = o["p3d"]
	var rig: Node2D = o["rig"]
	var dir := (base - rig.position)
	await _girar(c, o, Vector3(signf(dir.x) if dir.x != 0.0 else 1.0, 0, 0.1), giro)
	await _ir_y_frenar(c, o, base, ss)
	rig.position = base
	p.mirar_frente(0.3)
	await _esperar(c, 0.15 if ss < 1.2 else 0.05)
	p.reposo()


# Garon (combate.gd, _anim_ataque_3d con atacar_juicio o atacar_giro): anticipación (y la de la técnica), carrera con
# peso, frenada, Juicio o Giro de captura con su impacto de siempre, pausa fuerte, y vuelta corriendo.
func i_ataque_garon(c: Node, o: Dictionary, obj: Dictionary, impacto: Callable, metodo: String) -> void:
	var p = o["p3d"]
	var rig: Node2D = o["rig"]
	var base: Vector2 = o["rig_base"]
	var hueco: float = c.ANIM[o["modelo"]].get("distancia", 120.0) + c.ANIM[obj["modelo"]].get("distancia", 120.0) * 0.4
	var destino := base + Vector2(c._centro(obj).x + hueco - c._centro(o).x, (c._pos_ataque(obj).y - o["pos"].y) * 0.8)
	if obj.has("centro_ofs") and o.has("centro_ofs"):
		destino.y = base.y + (c._suelo_de(obj).y - c._suelo_de(o).y)
	var sitio = c._sitio_golpe(o, obj)
	if sitio != null:
		destino = sitio
	var tecnica: String = str(o.get("c12_tecnica", ""))
	o["animando"] = true
	rig.z_index = 5
	p.mirar(Vector3(-1, 0, 0.1), 0.12)
	if tecnica != "":                                # cruza las espadas y las abre: la técnica se anuncia
		_clip(p, "c12_tecnica_carga", 0.15)
		await _esperar(c, 0.6)
		var col: Color = c.menu.COLOR_HEROE.get("Garon", Color(1.0, 0.6, 0.3))
		c._destello(c._centro(o) + Vector2(0, -20), col.lightened(0.3), 1.0)
		c._onda(c._suelo_de(o), Color(col, 0.8), 20.0, 130.0, 0.5, 6.0)
		await _esperar(c, 0.2)
	else:
		_clip(p, "c12_arranque", 0.1)
		await _esperar(c, 0.26)
	await _ir_y_frenar(c, o, destino, 1.1)
	_sonido(c).voz(o, "ataque")
	if tecnica != "":
		camara(c, (c._centro(o) + c._centro(obj)) * 0.5, 1.09, 0.35, 1.4 if metodo == "atacar_giro" else 0.9, 0.45)
	var golpes := [0]
	var al_golpear := func():
		golpes[0] += 1
		if golpes[0] == 1 or metodo == "atacar_giro":
			impacto.call()
			if metodo == "golpe_fuerte" or metodo == "atacar_juicio":
				c._temblor(9.0)
		else:
			c._temblor(4.0)
			_sonido(c).golpe(false, obj.get("defendiendo", false), -6.0)
		var lado := signf(obj["pos"].x - o["pos"].x)
		_tajo(c, c._centro(obj), _color_arma("Garon"), lado if lado != 0.0 else -1.0, tecnica != "")
		_retroceso(c, o, obj, 1.4 if tecnica != "" else 1.1)
		_parada(c, [o, obj], PARADA_FUERTE if tecnica != "" else PARADA)
	match metodo:
		"atacar_giro":
			await p.atacar_giro(al_golpear)
		_:
			await p.atacar_juicio(al_golpear)
	if golpes[0] == 0:
		impacto.call()
	await _volver_corriendo(c, o, base)
	rig.z_index = 0
	o["animando"] = false


# ---------------------------------------------------------------- magia (Kael y Lya)
# combate.gd, _anim_magia_3d: con la preparación (concentrarse con el círculo y la luz que se reúne en el arma) delante;
# lo demás como siempre (lanzar_magia, halo, _lanzar, impacto, círculo fuera, fin_magia), con una onda en el impacto.
func i_magia(c: Node, o: Dictionary, obj: Dictionary, magia_n: String, impacto: Callable) -> void:
	var maga = o["p3d"]
	var color: Color = c._color_magia(magia_n)
	o["animando"] = true
	var potente: bool = int(c.nivel_sel) >= 2      # nivel II o III: su técnica (Lya, la magia poderosa; Kael, más carga)
	var circulo = c._carga_magia(o, magia_n, 1.25 if potente else 1.0)
	maga.mirar(Vector3(-1, 0, 0.15), 0.15)
	if potente:
		camara(c, (c._centro(o) + c._centro(obj)) * 0.5, 1.07, 0.4, 1.6, 0.5)
	if str(o.get("nombre", "")) == "Kael":
		_clip(maga, "c12_magia_carga", 0.2)
		maga.expresion("entrecerrados", 0.8)
	elif maga.has_method("concentrar"):
		maga.concentrar()
	var cam: Camera3D = o["cam3d"]
	var spr: Sprite2D = o["partes"]["sprite"]
	var reune: Sprite2D = c._brillo(color)
	reune.scale = Vector2(0.05, 0.05)
	reune.modulate.a = 0.0
	c.escena.add_child(reune)
	var tw := c.create_tween()
	tw.tween_method(func(k: float):
		if is_instance_valid(reune) and is_instance_valid(maga):
			reune.position = c.escena.to_local(spr.to_global(cam.unproject_position(maga.punto_magia())))
			reune.scale = Vector2.ONE * lerpf(0.05, 0.8 if potente else 0.55, k)
			reune.modulate.a = k, 0.0, 1.0, 0.9 if potente else 0.6)
	_chispas(c, c._centro(o) + Vector2(0, -40), color.lightened(0.4), 10, 0.6, Vector2(40, 90), Vector2(0, -1), 180.0,
		Vector2.ZERO, 0.05)
	await tw.finished
	reune.queue_free()
	if potente and maga.has_method("magia_poderosa"):
		await maga.magia_poderosa()                # Lya v2: concentra, alza el cetro y lo baja (sale a 1,5 s)
	else:
		await maga.lanzar_magia()
	var punto: Vector2 = c.escena.to_local(spr.to_global(cam.unproject_position(maga.punto_magia())))
	var halo: Sprite2D = c._brillo(color)
	halo.position = punto
	halo.scale = Vector2.ZERO
	c.escena.add_child(halo)
	c._particulas(punto, Color(color.r, color.g, color.b, 0.9), Color(color.r, color.g, color.b, 0.0), 40, 0.6,
		Vector2(60, 140), 70.0, Vector2(0, -1), 180.0, Vector2(0, 0), 0.08)
	var t2 := c.create_tween()
	t2.tween_property(halo, "scale", Vector2(1.1, 1.1), 0.5)
	t2.tween_property(halo, "scale", Vector2(0.6, 0.6), 0.15)
	await t2.finished
	halo.queue_free()
	await c._lanzar(punto, c._centro(obj), magia_n)
	impacto.call()
	c._onda(c._suelo_de(obj), Color(color, 0.85), 30.0, 190.0, 0.5, 7.0)
	_parada(c, [obj], PARADA)
	c._quitar_carga(circulo)
	await _esperar(c, 0.8)
	maga.fin_magia()
	await _esperar(c, 0.35)
	o["animando"] = false


# ---------------------------------------------------------------- reacciones
# combate.gd, _golpe_visual: en lugar de herida() a secas. Con la defensa puesta, bloquea; con un golpe fuerte (crítico,
# o ≥ 22 % de su vida, o un efecto potente), el golpe fuerte; si no, el ligero de siempre.
static func reaccion(c: Node, f: Dictionary, dano: int, critico: bool, potencia: float) -> void:
	var p = f["p3d"]
	if p.get("_muerta"):
		return
	if f.get("defendiendo", false):
		_clip(p, "c12_bloqueo", 0.05)
		c._destello(c._centro(f) + Vector2(-40, -10), Color(0.75, 0.88, 1.0), 0.7)
		_m(c)._volver_a(c, p, "c12_bloqueo", 0.5, "c12_defensa")
		return
	if critico or dano >= int(f.get("hp_max", 100) * 0.22) or potencia > 1.25:
		p.gestos.quitar_todos(0.1)
		var d := _clip(p, "c12_recibir_fuerte", 0.05)
		p.expresion("dolor", 0.9)
		_m(c)._volver_a(c, p, "c12_recibir_fuerte", d, "")
		return
	p.herida()


func _volver_a(c: Node, p, clip: String, d: float, luego: String) -> void:
	await _esperar(c, d)
	if not is_instance_valid(p) or p.get("_muerta") or p.anim.assigned_animation != clip:
		return
	if luego != "":
		_clip(p, luego, 0.2)
	else:
		p.reposo()


static func defender(c: Node, f: Dictionary) -> void:
	_clip(f["p3d"], "c12_defensa", 0.2)


static func fin_defensa(c: Node, f: Dictionary) -> void:
	var p = f["p3d"]
	if not p.get("_muerta") and p.anim.assigned_animation in ["c12_defensa", "c12_bloqueo"]:
		p.reposo()


static func embuir(c: Node, f: Dictionary) -> void:
	_clip(f["p3d"], "c12_embuir", 0.15)
	_m(c)._volver_a(c, f["p3d"], "c12_embuir", 1.2, "")


# Victoria: cada uno a su tiempo (no todos a la vez) y la cámara se acerca un poco al grupo.
func i_victoria(c: Node, h: Dictionary) -> void:
	var p = h["p3d"]
	var r: float = RETRASO_VICTORIA.get(str(h.get("nombre", "")), 0.3)
	if r > 0.0:
		await _esperar(c, r)
	if is_instance_valid(p):
		p.victoria()


static func camara_victoria(c: Node, heroes: Array) -> void:
	var vivos := heroes.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	var centro := Vector2.ZERO
	for h in vivos:
		centro += c._centro(h) / vivos.size()
	camara(c, centro, 1.06, 0.8, 1.6, 0.9)


# El gestor de sonido (autoload «Sonido», sonido.gd), sin nombrarlo: así este guion compila aunque lo cargue una prueba
# antes de que existan los autoloads.
static func _sonido(c: Node) -> Node:
	return c.get_node("/root/Sonido")


# Los dos tobillos en el espacio del héroe.
static func _pies(p) -> Array:
	var sk: Skeleton3D = p.skel
	var r := []
	for n in ["mixamorig_LeftFoot", "mixamorig_RightFoot"]:
		r.append(p.to_local(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(n)).origin))
	return r


# ---------------------------------------------------------------- el «motor»: un nodo hijo del combate
# Lo que espera (await) va en métodos de un nodo hijo del combate, no en funciones estáticas: si el combate se cierra
# a medias (huir, cambiar de escena, la medida de escenas que entra y sale), el nodo se libera con él y Godot ya no
# reanuda esas esperas (una función estática sí lo haría, sobre nodos ya liberados: así se cerró una vez la medida).
static func _m(c: Node) -> Node:
	var m := c.get_node_or_null("AnimCombateV12")
	if m == null:
		m = load("res://combate_anim_v12.gd").new()
		m.name = "AnimCombateV12"
		c.add_child(m)
	return m


# (19/11, HIBRIDA_SALIDA_19_11_REVISION) «impacto» (una función anónima de combate.gd) no puede quedarse en la pila de
# estas funciones ESTÁTICAS mientras esperan al nodo: si el juego se cierra a mitad del ataque, esa espera queda colgada
# hasta después de descargar los scripts y Godot 4.7.2 se cerraba con 0xC0000005 (como la híbrida de Érebo, PC-19). Ni
# siquiera como argumento de la llamada esperada (la copia temporal también queda en la pila: caso «guardada_arg» de
# pruebas/herramientas/diag_estatica_lambda.gd): va al nodo, se vacía aquí y el nodo la toma (d_*). Mismo orden y mismos
# instantes: _tomar_impacto() se hace en la misma llamada, antes de la primera espera.
static func ataque_kael(c: Node, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	_accion(c, 1, "ataque_Kael")
	var m = _m(c)
	m._impacto = impacto
	impacto = Callable()
	await m.d_ataque_kael(c, o, obj)
	await _fin_accion(c)


static func ataque_lya(c: Node, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	_accion(c, 1, "ataque_Lya")
	var m = _m(c)
	m._impacto = impacto
	impacto = Callable()
	await m.d_ataque_lya(c, o, obj)
	await _fin_accion(c)


static func ataque_garon(c: Node, o: Dictionary, obj: Dictionary, impacto: Callable, metodo: String) -> void:
	_accion(c, 1, metodo)
	var m = _m(c)
	m._impacto = impacto
	impacto = Callable()
	await m.d_ataque_garon(c, o, obj, metodo)
	await _fin_accion(c)


static func magia(c: Node, o: Dictionary, obj: Dictionary, magia_n: String, impacto: Callable) -> void:
	_accion(c, 1, "magia_" + str(o.get("nombre", "")))
	var m = _m(c)
	m._impacto = impacto
	impacto = Callable()
	await m.d_magia(c, o, obj, magia_n)
	await _fin_accion(c)


func _tomar_impacto() -> Callable:
	var i := _impacto
	_impacto = Callable()
	return i


func d_ataque_kael(c: Node, o: Dictionary, obj: Dictionary) -> void:
	await i_ataque_kael(c, o, obj, _tomar_impacto())


func d_ataque_lya(c: Node, o: Dictionary, obj: Dictionary) -> void:
	await i_ataque_lya(c, o, obj, _tomar_impacto())


func d_ataque_garon(c: Node, o: Dictionary, obj: Dictionary, metodo: String) -> void:
	await i_ataque_garon(c, o, obj, _tomar_impacto(), metodo)


func d_magia(c: Node, o: Dictionary, obj: Dictionary, magia_n: String) -> void:
	await i_magia(c, o, obj, magia_n, _tomar_impacto())


static func victoria(c: Node, h: Dictionary) -> void:
	_m(c).i_victoria(c, h)


# Chispas propias (unas pocas Sprite2D aditivas con su tween), en lugar de CPUParticles2D: cada CPUParticles2D que se
# crea toma su semilla del azar GLOBAL (una tirada), así que unas partículas de más cambiaban las tiradas del combate
# (críticos, patrones de los enemigos). Estas usan su propio generador con semilla fija: el azar del combate queda igual.
# Presupuesto: ≤ 14 sprites de 0,3-0,6 s por golpe, con la textura y el material aditivo que ya usa el combate.
static func _chispas(c: Node, pos: Vector2, col: Color, n: int, vida: float, vel: Vector2, dir: Vector2, apertura: float,
		gravedad: Vector2, escala: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12 + n
	var base := dir.normalized() if dir.length() > 0.01 else Vector2.UP
	for i in maxi(3, int(n * float(c.calidad))):
		var s := Sprite2D.new()
		s.texture = c.glow_tex
		s.material = c.mat_aditivo
		s.modulate = col
		s.position = pos
		s.scale = Vector2.ONE * escala * rng.randf_range(0.5, 1.0)
		c.escena.add_child(s)
		var v := base.rotated(deg_to_rad(rng.randf_range(-apertura, apertura))) * rng.randf_range(vel.x, vel.y)
		var fin := pos + v * vida + gravedad * vida * vida * 0.5
		var tw := c.create_tween().bind_node(s).set_parallel(true)
		tw.tween_property(s, "position", fin, vida).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 0.0, vida).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(s.queue_free)
