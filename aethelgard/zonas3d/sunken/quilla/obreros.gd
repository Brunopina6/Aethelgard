extends Node3D
# «La cuadrilla de la Quilla» (V12, 16/11; PROPUESTA [P], sin aprobar): trabajan para la proa en obras («Proa en
# obras. Orden de la capitana», ciudades/sunken.gd). Solo existen con la Quilla horneada (quilla.gd, EXPERIMENTAL).
#   - el CALAFATE (oficio herrero, persona «calafate»): coge estopa y brea de la olla, la lleva a una costura de su casa
#     y la mete a golpe de mazo; vuelve a por más;
#   - la CARPINTERA DE RIBERA (oficio campesino, persona «carpintera»: la azada se lee como su azuela): coge un tablón
#     del montón, lo lleva al banco, lo labra y deja la pieza hecha junto a la Quilla (para el empalme de la costilla 32);
#   - dos MARINEROS (oficio viajero, «marinero_1» y «marinero_2»: el bastón se lee como su bichero): uno hala el cabo
#     del torno y la cabria sube un fardo de tablas de la barca; el otro lo recoge, lo lleva por la repisa y lo apila
#     junto a la rampa.
# Reglas: NINGUNO pisa lo andable (trazado.gd) ni pasa a menos de 1,2 m de las rutas de prueba_sunken3d (x 40 y la de la
# tabla); van en su lista propia (no en «vecinos»: no entran en sunken_3d._prohibido); la animación solo avanza si se
# ven; hablar con ellos los PARA (miran a Kael, una frase por aviso) y después siguen donde lo dejaron. Las frases que
# rozan el secreto de la costilla que no alumbra solo salen después de encontrar la paga (Sunk.paga_encontrada()).

const NpcChibi := preload("res://personajes/npc_v12/npc_chibi.gd")
const Sunk := preload("res://ciudades/sunken.gd")
const Y := 0.3                                   # el piso de las plataformas de las casas
const PAUSA_HABLAR := 3.8
const RADIO := {"calafate": 2.0, "carpintera": 1.8, "marineros": 1.9}
const BOTON := {"calafate": "Hablar con el calafate", "carpintera": "Hablar con la carpintera",
	"marineros": "Hablar con el marinero"}
const CORTO := {"calafate": "Calafate", "carpintera": "Carpintera", "marineros": "Marinero"}
const FRASES := {
	"calafate": ["Estopa, brea y mazo. Si una costura llora, la Quilla entera se entera.",
		"La laguna no quiere hundirnos. Solo entra por donde la dejamos entrar."],
	"carpintera": ["Esta costilla perdió un trozo. Le pongo un empalme: madera vieja, abrazaderas nuevas.",
		"Aquí no se tira nada. Las casas son tablas que antes fueron cubierta.",
		"La capitana quiere la proa lista. Primero, que la Quilla aguante."],
	"marineros": ["¡Arriba ese fardo! Tablas para la proa, por orden de la capitana.",
		"Subimos madera de la laguna todo el día. Las gaviotas miran y no ayudan."],
}
const FRASES_TRAS_PAGA := {
	"calafate": "¿Una tabla suelta bajo la costilla del medio? Ya decía yo que crujía distinto.",
	"marineros": "¿La costilla sin farol? Nadie cuelga uno ahí. Ahora ya sabes por qué.",
}

var q                                            # quilla.gd
var mat                                          # zonas3d/garganta/materiales.gd (los de la escena de siempre)
var lista: Array = []                            # los obreros: {"id", "nodo", "chibi", "pasos", "i", "t", ...}
var grupos := {}                                 # id de conversación → [obreros]
var veces := {}
var _mats := {}
# lo que se ve moverse
var fardo: MeshInstance3D
var cabo_cabria: MeshInstance3D
var montones := {}                               # nombre → {"piezas": [MeshInstance3D], "n": int}
var _punta := Vector3(48.3, 3.62, 30.2)
var _t_golpe := 0.0


func preparar(q_, anclas: Dictionary, mat_) -> void:
	q = q_
	mat = mat_
	var a := func(n: String, def: Vector3) -> Vector3: return anclas.get(n, def)
	var olla: Vector3 = a.call("olla_brea", Vector3(42.85, Y, 42.75))
	var costura: Vector3 = a.call("costura", Vector3(43.0, Y, 40.2))
	var banco: Vector3 = a.call("banco_carpintera", Vector3(36.65, Y, 32.15))
	var tablones: Vector3 = a.call("tablones", Vector3(35.5, Y, 32.2))
	var entrega: Vector3 = a.call("entrega_carpintera", Vector3(37.85, Y, 32.2))
	var fardos: Vector3 = a.call("fardos", Vector3(42.85, Y, 31.98))
	_punta = a.call("cabria_punta", Vector3(48.3, 3.62, 30.2))
	# el calafate: de la olla a dos costuras de su casa (en el porche, x ≈ 42,9; la fachada está en x 43,45)
	_obrero("calafate", "herrero", "calafate", Vector3(42.8, Y, olla.z - 0.45), [
		["coger", "estopa", 1.2, Vector3(0, 0, 1)],
		["ir", Vector3(43.0, Y, costura.z + 0.1)],
		["tarea", 6.5, Vector3(1, 0, 0), true],
		["ir", Vector3(43.0, Y, costura.z + 1.05)],
		["tarea", 4.5, Vector3(1, 0, 0), true],
		["dejar", "estopa", 0.6, Vector3(1, 0, 0)],
		["ir", Vector3(42.8, Y, olla.z - 0.45)],
		["esperar", 1.5, Vector3(0, 0, 1)],
	])
	# la carpintera: del montón de tablones al banco, la labra y deja la pieza junto a la Quilla
	_obrero("carpintera", "campesino", "carpintera", tablones + Vector3(0.3, 0, 0.3), [
		["coger", "tablon", 1.0, Vector3(-1, 0, 0)],
		["ir", banco + Vector3(0.0, 0, 0.42)],
		["dejar", "tablon_banco", 0.5, Vector3(0, 0, -1)],
		["tarea", 7.0, Vector3(0, 0, -1), true],
		["coger", "pieza", 0.8, Vector3(0, 0, -1)],
		["ir", entrega + Vector3(-0.1, 0, 0.3)],
		["dejar", "pieza_hecha", 0.7, Vector3(1, 0, 0)],
		["ir", tablones + Vector3(0.3, 0, 0.3)],
	])
	# los marineros: uno al torno (hala mientras sube el fardo); el otro lo recoge y lo apila por la repisa del sur
	var m1 := _obrero("marineros", "viajero", "marinero_1", Vector3(46.75, Y, 30.0), [
		["izar", 4.2, Vector3(-1, 0, 0)],
		["esperar_fardo"],
		["bajar", 3.0, Vector3(-1, 0, 0)],
	])
	m1["principal"] = false
	_obrero("marineros", "viajero", "marinero_2", Vector3(47.25, Y, 30.9), [
		["esperar_arriba", Vector3(1, 0, 0)],
		["coger", "fardo", 0.9, Vector3(1, 0, 0)],
		["ir", Vector3(47.0, Y, 31.95)],
		["ir", fardos + Vector3(0.45, 0, 0)],
		["dejar", "fardo_apilado", 0.8, Vector3(-1, 0, 0)],
		["ir", Vector3(47.0, Y, 31.95)],
		["ir", Vector3(47.25, Y, 30.9)],
	])
	_crear_atrezo(olla, tablones, banco, entrega, fardos)


# Al irse (salir de Sunken o del banco), los atlas de las cuatro personas de la cuadrilla, que solo se usan aquí, salen
# de la caché de npc_chibi.gd: sin esto seguían en memoria el resto de la sesión. Los modelos de sus oficios (herrero,
# campesino, viajero) los comparten otros vecinos y se quedan.
func _exit_tree() -> void:
	var personas: Array = []
	for o in lista:
		personas.append(o["persona"])
	NpcChibi.soltar(personas)


func _obrero(grupo: String, oficio: String, persona: String, sitio: Vector3, pasos: Array) -> Dictionary:
	var n := Node3D.new()
	n.name = "Obrero_" + persona
	add_child(n)
	n.global_position = sitio
	var chibi: Node3D = null
	if NpcChibi.existe(oficio):
		chibi = NpcChibi.crear(oficio, persona)
		if not chibi.listo:
			chibi.free()
			chibi = null
	if chibi != null:
		n.add_child(chibi)
		chibi.sombra(false)
	var o := {"id": grupo, "persona": persona, "nodo": n, "chibi": chibi, "pasos": pasos, "i": 0, "t": 0.0,
		"pausa": 0.0, "lleva": null, "principal": true, "parado": false}
	lista.append(o)
	if not grupos.has(grupo):
		grupos[grupo] = []
	grupos[grupo].append(o)
	_empezar_paso(o)
	return o


# ================================================================= el atrezo que se mueve (con los materiales de siempre)

func _caja(tam: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	var clave := color.to_html()
	if not _mats.has(clave):
		_mats[clave] = mat.liso(color, 0.95)          # (el de las cápsulas de los vecinos: sin programas nuevos)
	mi.material_override = _mats[clave]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _crear_atrezo(olla: Vector3, tablones: Vector3, banco: Vector3, entrega: Vector3, fardos: Vector3) -> void:
	fardo = _caja(Vector3(0.62, 0.34, 0.42), Color(0.62, 0.47, 0.30))
	fardo.name = "Fardo"
	add_child(fardo)
	fardo.global_position = Vector3(_punta.x, -0.45, _punta.z)
	cabo_cabria = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.02
	cm.height = 1.0
	cm.radial_segments = 4
	cm.rings = 1
	cabo_cabria.mesh = cm
	cabo_cabria.material_override = mat.liso(Color(0.45, 0.38, 0.27), 0.95)
	cabo_cabria.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cabo_cabria)
	_poner_cabo()
	montones["pieza_hecha"] = _monton(entrega, Vector3(0.24, 0.05, 1.0), Color(0.74, 0.62, 0.46), 4, 0.06)
	montones["fardo_apilado"] = _monton(fardos, Vector3(0.6, 0.32, 0.42), Color(0.60, 0.46, 0.30), 3, 0.33)
	montones["tablon_banco"] = _monton(banco + Vector3(0, 0.82, 0), Vector3(1.2, 0.06, 0.26), Color(0.58, 0.45, 0.31), 1, 0.0)


# Un montón es UNA malla (una llamada de dibujo) con una versión por cada número de piezas.
func _monton(base: Vector3, tam: Vector3, color: Color, n: int, alto: float) -> Dictionary:
	var mallas: Array = []
	var caja := BoxMesh.new()
	caja.size = tam
	for cuantas in range(1, n + 1):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for k in cuantas:
			st.append_from(caja, 0, Transform3D(Basis(), Vector3(0.02 * (k % 2), tam.y * 0.5 + alto * k, 0)))
		mallas.append(st.commit())
	var mi := _caja(tam, color)
	mi.mesh = mallas[0]
	add_child(mi)
	mi.global_position = base
	mi.visible = false
	return {"nodo": mi, "mallas": mallas, "n": 0, "max": n}


func _poner_monton(nombre: String, n: int) -> void:
	var d: Dictionary = montones[nombre]
	d["n"] = n
	var mi: MeshInstance3D = d["nodo"]
	mi.visible = n > 0
	if n > 0:
		mi.mesh = d["mallas"][n - 1]


func _poner_cabo() -> void:
	var arriba := _punta
	var abajo := fardo.global_position + Vector3(0, 0.17, 0)
	if absf(fardo.global_position.x - _punta.x) > 0.05:          # (el fardo ya está en el descansillo: el gancho, arriba)
		abajo = Vector3(_punta.x, 1.05, _punta.z)
	var largo := maxf(0.05, arriba.y - abajo.y)
	cabo_cabria.global_position = Vector3(arriba.x, (arriba.y + abajo.y) * 0.5, arriba.z)
	cabo_cabria.scale = Vector3(1, largo, 1)


# ================================================================= los trabajos

func _empezar_paso(o: Dictionary) -> void:
	o["t"] = 0.0
	_clip_paso(o)


# El clip del paso en curso, sin tocar su tiempo (al seguir tras hablar o tras un diálogo, sigue donde lo dejó).
func _clip_paso(o: Dictionary) -> void:
	var p: Array = o["pasos"][o["i"]]
	var c = o["chibi"]
	match String(p[0]):
		"ir":
			if c != null:
				c.andar(c.velocidad_natural())
		"tarea", "izar", "bajar":
			if c != null:
				c.clip("tarea")
		_:
			if c != null:
				c.clip("reposo")


func _siguiente(o: Dictionary) -> void:
	o["i"] = (int(o["i"]) + 1) % (o["pasos"] as Array).size()
	_empezar_paso(o)


func _mirar(o: Dictionary, dir: Vector3) -> void:
	if dir.length() > 0.01:
		(o["nodo"] as Node3D).rotation.y = atan2(dir.x, dir.z)


func _llevar(o: Dictionary, que) -> void:
	if o["lleva"] != null and is_instance_valid(o["lleva"]):
		(o["lleva"] as Node).queue_free()
	o["lleva"] = null
	if que == null:
		return
	var tam := {"estopa": Vector3(0.22, 0.14, 0.18), "tablon": Vector3(0.12, 0.06, 1.3), "pieza": Vector3(0.12, 0.06, 1.0),
		"fardo": Vector3(0.6, 0.32, 0.4)}
	var col := {"estopa": Color(0.30, 0.25, 0.18), "tablon": Color(0.56, 0.43, 0.29), "pieza": Color(0.74, 0.62, 0.46),
		"fardo": Color(0.62, 0.47, 0.30)}
	var p := _caja(tam[que], col[que])
	(o["nodo"] as Node3D).add_child(p)
	p.position = Vector3(0.0, 0.62 if que == "fardo" else 0.78, 0.28 if que != "tablon" and que != "pieza" else 0.12)
	if que in ["tablon", "pieza"]:
		p.position = Vector3(0.18, 1.02, 0.0)
		p.rotation.y = PI * 0.5
	o["lleva"] = p


func _paso(o: Dictionary, delta: float, escena: Node) -> void:
	var p: Array = o["pasos"][o["i"]]
	var n: Node3D = o["nodo"]
	o["t"] = float(o["t"]) + delta
	match String(p[0]):
		"ir":
			var meta: Vector3 = p[1]
			var d := meta - n.global_position
			d.y = 0.0
			var v: float = o["chibi"].velocidad_natural() if o["chibi"] != null else 0.8
			if d.length() <= v * delta:
				n.global_position = meta
				_siguiente(o)
			else:
				_mirar(o, d)
				n.global_position += d.normalized() * v * delta
		"tarea":
			_mirar(o, p[2])
			if p[3]:
				_golpes(o, delta, escena)
			if o["t"] >= p[1]:
				_siguiente(o)
		"coger":
			_mirar(o, p[3])
			if o["t"] >= p[2]:
				if p[1] == "fardo":
					fardo.visible = false
				_llevar(o, p[1])
				if p[1] == "pieza":
					_poner_monton("tablon_banco", 0)
				_siguiente(o)
		"dejar":
			_mirar(o, p[3])
			if o["t"] >= p[2]:
				_llevar(o, null)
				if montones.has(p[1]):
					var m: Dictionary = montones[p[1]]
					var cuantos: int = int(m["n"]) + 1
					if cuantos > int(m["max"]):
						cuantos = 1                    # (se los llevan: el montón vuelve a empezar)
					_poner_monton(p[1], cuantos)
				_siguiente(o)
		"esperar":
			_mirar(o, p[2])
			if o["t"] >= p[1]:
				_siguiente(o)
		"izar":                                    # el fardo sube de la barca a la punta de la cabria
			_mirar(o, p[2])
			fardo.visible = true
			var k := clampf(float(o["t"]) / float(p[1]), 0.0, 1.0)
			var y0 := -0.45
			var y1 := 0.9
			fardo.global_position = Vector3(_punta.x, lerpf(y0, y1, k * k * (3.0 - 2.0 * k)), _punta.z)
			if o["t"] >= p[1]:
				fardo.global_position = Vector3(_punta.x - 0.95, 0.62, _punta.z)   # (lo arriman al descansillo)
				_sonar("puente_cruje", fardo.global_position, escena)
				_siguiente(o)
		"esperar_fardo":                           # hasta que el otro lo coge
			if not fardo.visible:
				_siguiente(o)
		"bajar":                                   # el gancho vacío baja a la barca
			_mirar(o, p[2])
			var k := clampf(float(o["t"]) / float(p[1]), 0.0, 1.0)
			fardo.visible = false
			fardo.global_position = Vector3(_punta.x, lerpf(0.9, -0.45, k), _punta.z)
			if o["t"] >= p[1]:
				_siguiente(o)
		"esperar_arriba":                          # hasta que el fardo está en el descansillo
			_mirar(o, p[1])
			if fardo.visible and absf(fardo.global_position.x - (_punta.x - 0.95)) < 0.01:
				_siguiente(o)
	_poner_cabo()


# Los golpes del mazo o de la azuela (los de la madera de los pasos), solo si se ve y Kael está cerca.
func _golpes(o: Dictionary, delta: float, escena: Node) -> void:
	_t_golpe -= delta
	if _t_golpe > 0.0:
		return
	_t_golpe = 0.82
	_sonar("paso_madera", (o["nodo"] as Node3D).global_position, escena, 6.0)


func _sonar(nombre: String, p: Vector3, escena: Node, db := 0.0) -> void:
	var kael: Node3D = escena.get("kael")
	if kael == null or kael.global_position.distance_to(p) > 9.0:
		return
	var son = escena.get_node_or_null("/root/Sonido")
	if son != null:
		son.efecto(nombre, {"pos": p, "db": db})


func avanzar(delta: float, escena: Node) -> void:
	var cam: Camera3D = escena.get("cam")
	var ocupado: bool = escena.has_method("ocupado") and escena.ocupado()
	for o in lista:
		var n: Node3D = o["nodo"]
		if float(o["pausa"]) > 0.0:
			o["pausa"] = float(o["pausa"]) - delta
			if float(o["pausa"]) <= 0.0:
				o["parado"] = false
				_clip_paso(o)
		elif ocupado:                              # (un diálogo o la tienda: el que iba andando se queda quieto)
			if not o["parado"]:
				o["parado"] = true
				if o["chibi"] != null and String(o["pasos"][o["i"]][0]) == "ir":
					o["chibi"].clip("reposo")
		else:
			if o["parado"]:
				o["parado"] = false
				_clip_paso(o)
			_paso(o, delta, escena)
		var c = o["chibi"]
		if c != null and (cam == null or cam.is_position_in_frustum(n.global_position + Vector3(0, 0.8, 0))):
			c.avanzar(delta)                       # (la animación, solo si se ve)


# ================================================================= hablar (sunken_3d.gd, piezas_al_alcance y _accion)

func piezas() -> Array:
	var r: Array = []
	for g in grupos:
		var o: Dictionary = _quien_habla(g)
		r.append([g, (o["nodo"] as Node3D).global_position, RADIO[g], BOTON[g]])
	return r


func _quien_habla(g: String) -> Dictionary:
	var os: Array = grupos[g]
	for o in os:                                    # (de los marineros, el que apila: el que está más cerca)
		if o["persona"] == "marinero_2":
			return o
	return os[0]


func es_obrero(id: String) -> bool:
	return grupos.has(id)


func frase(id: String, n: int) -> String:
	var l: Array = (FRASES[id] as Array).duplicate()
	if FRASES_TRAS_PAGA.has(id) and Sunk.paga_encontrada():
		l.append(FRASES_TRAS_PAGA[id])
	return l[(n - 1) % l.size()]


func hablar(id: String, desde: Vector3) -> String:
	if not grupos.has(id):
		return ""
	veces[id] = int(veces.get(id, 0)) + 1
	for o in grupos[id]:
		o["pausa"] = PAUSA_HABLAR                   # se paran (y siguen después donde lo dejaron)
		var n: Node3D = o["nodo"]
		_mirar(o, desde - n.global_position)
		if o["chibi"] != null:
			o["chibi"].clip("hablar" if o == _quien_habla(id) else "reposo", "reposo")
	return "%s: «%s»" % [CORTO[id], frase(id, int(veces[id]))]
