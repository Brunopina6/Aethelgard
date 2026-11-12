extends RefCounted
# V12, encuentro del desierto (12/11/2026): Vidracrán, el escorpión de vidrio del Mar de Cristal, en el combate ATB.
# DEMOSTRACIÓN REVERSIBLE: no sale en ningún encuentro salvo con el interruptor «encuentro_desierto_v12» (APAGADO) o en
# sus combates de prueba (GRUPOS[14], [15] y [16] de combate.gd: «-- grupo=14»). Nombre de narrativa sin aprobar
# (docs/v12/NARRATIVA_DESIERTO.md §4). Modelo y clips: enemigos/vidracran/ (prototipo de animaciones, Blender por guion).
# Informe: docs/memory/agents/combate_v12_encuentro_desierto.md.
#
# Mecánica («caparazón y ventana»), toda con reglas que ya existían:
#   - Caparazón de vidrio: los golpes físicos le hacen la mitad (como la piel de piedra del Coloso, MULT_PIEL); la magia,
#     entera. Se lee sobre su vida («Caparazón») y en el panel de objetivos.
#   - Ciclo fijo, sin azar (legible): Pinzas (a uno, ×1) → se entierra → Aguijón → Pinzas…
#     · Enterrarse (el aviso): escarba, se hunde y su montón de arena se desliza hasta el héroe elegido (la curandera si
#       ha curado; si no, el que menos vida tiene, como el aviso de Zarzalín); el bulbo de la cola late dos veces, sale
#       «⚠ ¡Aguijón!» sobre ese héroe y un triángulo verde se queda encima de él. BAJO LA ARENA NO SE LE PUEDE APUNTAR
#       (combate.gd _alcanzables): ni golpes ni magia ni área. Es la única regla nueva y dura un turno suyo. Con dos,
#       un aguijón a la vez: si el otro ya está bajo la arena, este usa las pinzas y se entierra después.
#     · Aguijón (su turno siguiente): emerge bajo ese héroe y le pica (×1,8, como la embestida de Zarzalín). Se
#       contrarresta como siempre: DEFENDER lo deja a la mitad y la GUARDIA de Garon se lo lleva él (a la mitad).
#     · La ventana: tras picar vuelve a su sitio con el caparazón abierto: EXPUESTO hasta su turno siguiente (los golpes
#       físicos ×1,5, como el Coloso expuesto; los puntos débiles brillan con _marcar_puntos del Coloso). Al empezar su
#       turno se recompone y vuelve a las pinzas.
#   - Ningún estado nuevo de los que se guardan: todo vive en el diccionario del luchador y acaba con el combate.
# Sonido (sonido.gd, EFECTOS_VIDRACRAN, OGG de enemigos/vidracran/sonido/; procedencia en el informe): cada uno una vez,
# en su instante real (las pinzas y el aguijón, en el impacto del clip; el aviso, en el primer latido del bulbo).

const CLAVE := "vidracran"
const INTERRUPTOR := "encuentro_desierto_v12"
const ACTIVO_POR_DEFECTO := false
# combate.gd GRUPOS: los combates de prueba (también salen con el interruptor en el Mar de Cristal)
const GRUPO_UNO := 14
const GRUPO_DOS := 15
const GRUPO_MIXTO := 16
const GRUPOS_POR_TAMANO := {1: [GRUPO_UNO], 2: [GRUPO_UNO, GRUPO_DOS, GRUPO_MIXTO], 3: [GRUPO_DOS, GRUPO_MIXTO]}
const PROB_EN_MAR_CRISTAL := 0.5          # con el interruptor, la mitad de los encuentros del Mar de Cristal son suyos
const CICLO := ["pinzas", "enterrarse", "aguijon"]
const MULT_PINZAS := 1.0
const MULT_AGUIJON := 1.8
const MULT_CAPARAZON := 0.5               # golpes físicos con el caparazón cerrado (Coloso.MULT_PIEL)
const MULT_EXPUESTO := 1.5                # golpes físicos en la ventana (Coloso.MULT_VENTANA)
const COLOR_BULBO := Color(0.45, 1.0, 0.55)
const COLOR_EXPUESTO := Color(1.0, 0.42, 0.22)   # el de la ventana del Coloso (combate.gd COLOR_VENTANA)
const PREMIO := "Esquirla de vidracrán"   # datos/materiales/esquirla_vidracran.tres: una por cada uno vencido
const SIN_OBJETIVO := "Está bajo la arena: no hay a quién apuntar. Defiéndete o cúrate."
const DESLIZ_S := 0.6                     # lo que tarda el montón de arena en llegar bajo el héroe
const AVANCE_AGUIJON := 0.4               # m por delante de su origen donde pica el aguijón (para plantarlo)
const SONIDOS := {"enterrarse": "vidracran_enterrarse", "brota": "vidracran_brota", "expuesto": "vidracran_expuesto"}


# ¿Está encendida la demostración? «-- encuentro_desierto_v12» o Engine.set_meta("encuentro_desierto_v12", true).
static func activo() -> bool:
	if INTERRUPTOR in OS.get_cmdline_user_args():
		return true
	return bool(Engine.get_meta(INTERRUPTOR, ACTIVO_POR_DEFECTO))


# Para zonas3d/mar_cristal_3d.gd: el grupo de combate de un encuentro al azar del Mar de Cristal, o -1 (el de siempre).
# Apagado devuelve -1 sin tirar ningún dado: los encuentros y el azar quedan exactamente como estaban.
static func grupo_mar_cristal() -> int:
	if not activo():
		return -1
	if randf() >= PROB_EN_MAR_CRISTAL:
		return -1
	var n := 3
	if ResourceLoader.exists("res://grupo.gd"):
		n = clampi(load("res://grupo.gd").activos().size(), 1, 3)
	var opciones: Array = GRUPOS_POR_TAMANO[n]
	return opciones[randi() % opciones.size()]


static func es(f) -> bool:
	return f is Dictionary and str(f.get("clave", "")) == CLAVE


static func enterrado(f: Dictionary) -> bool:
	return es(f) and f.get("vc_enterrado", false)


# Se le puede apuntar (los demás enemigos, siempre; Vidracrán, salvo bajo la arena).
static func apuntable(f: Dictionary) -> bool:
	return not enterrado(f)


# Lo que le hace un golpe (combate.gd lo pide junto a Coloso.dano_recibido). Bajo la arena no le llega nada (por si un
# conjuro preparado o un rebote lo busca). Físico: caparazón ×0,5 o expuesto ×1,5. Magia: entera.
static func dano_recibido(dano: int, magia: String, _origen: Dictionary, objetivo: Dictionary) -> int:
	if not es(objetivo):
		return dano
	if enterrado(objetivo):
		return 0
	if magia != "":
		return dano
	var m := MULT_EXPUESTO if objetivo.get("vc_expuesto", false) else MULT_CAPARAZON
	return maxi(1, int(round(dano * m)))


# Lo que se lee sobre su vida.
static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if e.get("vc_enterrado", false):
		r.append("Bajo la arena")
		var o = e.get("vc_objetivo", null)
		if o is Dictionary and int(o.get("hp", 0)) > 0:
			r.append("⚠ Aguijón: %s" % o["nombre"])
	elif e.get("vc_expuesto", false):
		r.append("¡Expuesto!")
	else:
		r.append("Caparazón")
	return r


# Lo que dice el panel de objetivos (combate.gd _info_objetivo).
static func info(e: Dictionary) -> Array:
	if e.get("vc_enterrado", false):
		return ["Bajo la arena: no se le alcanza"]
	if e.get("vc_expuesto", false):
		return ["¡Expuesto! Golpes ×1,5"]
	return ["Caparazón: golpes a la mitad, la magia entera"]


# El aviso del turno de un héroe mientras alguno está bajo la arena ("" si ninguno).
static func aviso_turno(enemigos: Array) -> String:
	for e in enemigos:
		if enterrado(e) and int(e["hp"]) > 0:
			var o = e.get("vc_objetivo", null)
			if o is Dictionary and int(o.get("hp", 0)) > 0:
				return "%s está bajo la arena: va a por %s. ¡Defiéndete!" % [e["nombre"], o["nombre"]]
			return "%s está bajo la arena" % e["nombre"]
	return ""


# El botín: un material por cada Vidracrán vencido (no los que huyen).
static func botin_de(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		if es(e) and not e.get("huido", false) and int(e.get("hp", 0)) <= 0:
			r.append(PREMIO)
	return r


static func _contar(f: Dictionary, k: String) -> void:
	if not f.has("vc_contador"):
		f["vc_contador"] = {}
	f["vc_contador"][k] = int(f["vc_contador"].get(k, 0)) + 1


# ================================================================= su turno (combate.gd _turno_enemigo)

static func turno(c, f: Dictionary, vivos: Array, mult: float) -> void:
	if not f.has("vc_fase"):                               # el segundo de un grupo empieza en otro punto del ciclo
		f["vc_fase"] = 0 if c.enemigos.filter(func(e): return es(e)).find(f) % 2 == 0 else 1
	if f.get("vc_expuesto", false):                        # la ventana se cierra al empezar su turno
		f["vc_expuesto"] = false
		c._marcar_puntos(f, false)
		_contar(f, "recompone")
		c._numero_flotante(f, "Cierra el caparazón", Color(0.95, 0.85, 0.6), 26)
		c._actualizar()
	if f.get("vc_enterrado", false):
		await _aguijon(c, f, vivos, mult)
		return
	var limpia: bool = load("res://progreso.gd").zona_limpia(Engine.get_meta("zona", "llanura"))
	if limpia and randf() < 0.7:                           # como los demás enemigos normales en una «zona limpia»
		await c._huir(f)
		return
	var otro_bajo: bool = c.enemigos.any(func(e): return not is_same(e, f) and enterrado(e) and int(e["hp"]) > 0)
	if CICLO[int(f["vc_fase"]) % CICLO.size()] == "enterrarse" and not otro_bajo:   # (un aguijón a la vez: si otro ya
		await _enterrarse(c, f, vivos)                                                 # está bajo la arena, pinzas)
	else:
		await _pinzas(c, f, vivos, mult)


static func _pinzas(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._cubre(c._elegir_objetivo("agresivo", vivos))
	c.registro.text = "%s lanza las pinzas contra %s" % [f["nombre"], obj["nombre"]]
	f["vc_ataque"] = "pinzas"
	_contar(f, "pinzas")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_PINZAS * mult) + randi_range(-2, 3), "")
	f.erase("vc_ataque")
	f["vc_fase"] = 1


static func _enterrarse(c, f: Dictionary, vivos: Array) -> void:
	var obj: Dictionary = c._elegir_objetivo("agresivo", vivos)
	f["vc_objetivo"] = obj
	_contar(f, "enterrarse")
	c.registro.text = "%s se entierra... ¡el bulbo de su cola brilla junto a %s!" % [f["nombre"], obj["nombre"]]
	c._sonar(SONIDOS["enterrarse"])
	var p = c._p3d(f)
	f["animando"] = true
	if p != null and p.has_method("enterrarse"):
		await p.enterrarse()
	else:
		await c.get_tree().create_timer(0.8).timeout
	if f["hp"] <= 0:
		f["animando"] = false
		return
	f["vc_enterrado"] = true
	if f.has("sombra"):
		f["sombra"].visible = false
	f["rig"].z_index = 5                                    # el montón y la cola, delante de los héroes
	await _deslizar(c, f, obj)
	_marcar(c, f, obj)
	c._numero_flotante(obj, "⚠ ¡Aguijón!", COLOR_BULBO, 32)
	c._actualizar()
	if p != null and p.has_method("avisar"):
		await p.avisar("emerger_aguijon")                  # su señal «aviso» suena (combate.gd _sonidos_bestia)
	else:
		c._sonar("vidracran_aviso_emerger")
		await c.get_tree().create_timer(0.8).timeout
	f["animando"] = false
	f["vc_fase"] = 2


static func _aguijon(c, f: Dictionary, vivos: Array, mult: float) -> void:
	var obj = f.get("vc_objetivo", null)
	if not (obj is Dictionary) or int(obj["hp"]) <= 0:
		obj = c._elegir_objetivo("agresivo", vivos)
	obj = c._cubre(obj)                                     # la Guardia de Garon: el aguijón va a él
	_marcar(c, f, null)
	f.erase("vc_objetivo")
	_contar(f, "aguijon")
	c.registro.text = "¡%s emerge bajo %s y clava el aguijón!" % [f["nombre"], obj["nombre"]]
	f["vc_ataque"] = "aguijon"
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_AGUIJON * mult) + randi_range(-2, 3), "")
	f.erase("vc_ataque")
	f["vc_fase"] = 0
	if f["hp"] > 0:                                         # la ventana: expuesto hasta su turno siguiente
		f["vc_expuesto"] = true
		_contar(f, "expuesto")
		c._marcar_puntos(f, true)
		c._sonar(SONIDOS["expuesto"])
		c._numero_flotante(f, "¡Expuesto!", COLOR_EXPUESTO, 34)
		c.registro.text = "¡%s queda expuesto: su caparazón está abierto!" % f["nombre"]
		c._actualizar()
		await c.get_tree().create_timer(0.6).timeout


# ================================================================= animación (combate.gd _animar_golpe)

static func animar_golpe(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var p = c._p3d(o)
	if str(o.get("vc_ataque", "pinzas")) == "aguijon":
		await _anim_aguijon(c, o, obj, impacto)
	elif p != null:
		await c._anim_zarzalin(o, obj, impacto, "pinzas")   # corre, planta la pinza y vuelve (el impacto, una vez)
	elif c._es_sprite(o):
		await c._anim_fisico_sprite(o, obj, impacto)
	else:
		impacto.call()
		await c.get_tree().create_timer(0.5).timeout


# Dónde deja su rig para que el aguijón caiga en «obj» (escena). Se mide desde donde está ahora (puede estar ya bajo
# otro héroe) y un poco por delante de sus pies, para que el montón y la cola se vean.
static func _sitio(c, o: Dictionary, obj: Dictionary) -> Vector2:
	var m: Dictionary = c.MODELOS[o["modelo"]]
	if not m.has("vp"):
		return o["rig_base"]
	var px_m: float = m["vp"].y / m["alto_vista"] * m["esc"]
	var pies_x: float = c._centro(obj).x - 20.0 - AVANCE_AGUIJON * px_m
	var rig: Node2D = o["rig"]
	return rig.position + Vector2(pies_x - c._suelo_de(o).x, c._suelo_de(obj).y - c._suelo_de(o).y + 18.0)


# Bajo la arena: el montón se desliza hasta el héroe (deja un reguero de arena).
static func _deslizar(c, o: Dictionary, obj: Dictionary) -> void:
	var rig: Node2D = o["rig"]
	var destino := _sitio(c, o, obj)
	if rig.position.distance_to(destino) < 4.0:
		return
	var desde: Vector2 = c._suelo_de(o)
	c._particulas(desde, Color(0.88, 0.76, 0.52, 0.9), Color(0.8, 0.68, 0.45, 0.0), 14, 0.7, Vector2(30, 90), 40.0,
		Vector2(0, -1), 40.0, Vector2(0, 260), 0.12)
	var t: Tween = c.create_tween()
	t.tween_property(rig, "position", destino, DESLIZ_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	c._particulas(c._suelo_de(o), Color(0.88, 0.76, 0.52, 0.9), Color(0.8, 0.68, 0.45, 0.0), 14, 0.7, Vector2(30, 90),
		40.0, Vector2(0, -1), 40.0, Vector2(0, 260), 0.12)


static func _anim_aguijon(c, o: Dictionary, obj: Dictionary, impacto: Callable) -> void:
	var p = c._p3d(o)
	var rig: Node2D = o["rig"]
	var ida := Vector3(1, 0, 0.1)
	o["animando"] = true
	rig.z_index = 5
	await _deslizar(c, o, obj)                              # (si cambió de héroe: Garon cubre o el elegido cayó)
	o["vc_enterrado"] = false
	if o.has("sombra"):
		o["sombra"].visible = true
	c._sonar(SONIDOS["brota"])
	c._particulas(c._suelo_de(o), Color(0.9, 0.78, 0.55, 0.95), Color(0.85, 0.72, 0.5, 0.0), 26, 0.9,
		Vector2(60, 200), 50.0, Vector2(0, -1), 50.0, Vector2(0, 420), 0.14)
	var golpes := [0]
	var al_golpear := func():
		golpes[0] += 1
		if golpes[0] == 1:
			impacto.call()
			c._temblor(6.0)
	if p != null and p.has_method("atacar"):
		p.mirar(ida, 0.1)
		await p.atacar("emerger_aguijon", al_golpear)
	else:
		await c.get_tree().create_timer(0.5).timeout
	if golpes[0] == 0:                                      # sin el clip (o cortado): el golpe igualmente, una vez
		al_golpear.call()
	if o["hp"] > 0:                                         # vuelve corriendo a su sitio
		var base: Vector2 = o["rig_base"]
		if p != null:
			p.mirar(-ida, 0.2)
			p.correr()
		var t: Tween = c.create_tween()
		t.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await t.finished
		if p != null:
			p.mirar_frente(0.25)
			p.reposo()
	rig.z_index = 0
	o["animando"] = false


# ================================================================= la marca sobre el héroe elegido

# Un triángulo verde (el color del bulbo) encima del héroe al que va el aguijón, hasta que pica. «obj» null: fuera.
static func _marcar(c, f: Dictionary, obj) -> void:
	var antes = f.get("vc_marca", null)
	if antes != null and is_instance_valid(antes):
		antes.queue_free()
	f.erase("vc_marca")
	if obj == null:
		return
	var s = c._sena_arte("aviso", obj, {"dur": 9999.0, "color": COLOR_BULBO})
	s.position = c._centro(obj) + Vector2(0, -150)
	f["vc_marca"] = s


# combate.gd _actualizar: si cae él o el héroe marcado, la marca fuera (no queda nada colgado).
static func repasar(f: Dictionary) -> void:
	var m = f.get("vc_marca", null)
	if m == null:
		return
	var o = f.get("vc_objetivo", null)
	if int(f["hp"]) <= 0 or not (o is Dictionary) or int(o.get("hp", 0)) <= 0:
		if is_instance_valid(m):
			m.queue_free()
		f.erase("vc_marca")


# combate.gd _comprobar_fin: al acabar el combate (victoria o derrota), su marca y sus puntos débiles, fuera.
static func al_acabar(enemigos: Array) -> void:
	for e in enemigos:
		if not es(e):
			continue
		for k in ["vc_marca", "puntos_nodo"]:
			var n = e.get(k, null)
			if n != null and is_instance_valid(n):
				n.queue_free()
			e.erase(k)


# Nodos que deja en la escena (para las pruebas: al acabar no debe quedar ninguno).
static func nodos_vivos(enemigos: Array) -> Array:
	var r: Array = []
	for e in enemigos:
		for k in ["vc_marca", "puntos_nodo"]:
			var n = e.get(k, null)
			if es(e) and n != null and is_instance_valid(n) and not n.is_queued_for_deletion():
				r.append("%s:%s" % [e["nombre"], k])
	return r
