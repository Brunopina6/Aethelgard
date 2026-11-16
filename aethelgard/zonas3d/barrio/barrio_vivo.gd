extends Node3D
# DUEÑO: agente C. BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11): la VIDA. PROPUESTA [P], solo en el banco de Auditoría.
# Plan: docs/v12/BARRIO_OAKHAVEN_PLAN.md §4 (rutinas) y §11 (contrato); lo hecho: docs/v12/BARRIO_OAKHAVEN.md, sección C.
#
# TRES RUTINAS con OBJETOS SUJETOS que cambian de sitio de forma coherente, y tres vecinos en su puesto:
#   - Maela, la panadera: amasa y hornea dentro del horno, saca la BANDEJA, la deja en el mostrador de la calle, llena la
#     CESTA y abastece el puesto del pan de la plaza; vuelve, recoge y mete la bandeja. Con el carro parado (misión
#     empezada) espera junto al carro mirando la rueda; con él arreglado, la bandeja va al carro (reparto).
#   - Tobías, el porteador: del carro de las caravanas lleva una CAJA a la pila del patio de talleres y un SACO de harina a
#     la pila junto a la puerta del horno (fuera de su eje). Con el carro parado, sentado junto a él; con él arreglado,
#     carga cajas en el carro del horno.
#   - Brena, la encargada del establo: coge el CEPILLO del gancho, cepilla a Avena, lo cuelga, coge el CUBO, lo llena en
#     el pozo, lo vierte en el abrevadero (Avena bebe), deja el cubo, echa heno (Avena come) y devuelve el cubo.
#   - Avena, la yegua: atada ante el establo, NO anda (solo clips sin desplazamiento); se examina, no habla.
#   - Damián (carretero), Odila (costurera) y Nela (su hija): en su puesto con su tarea. Dentro de su interior si B lo
#     ha construido (Interiores.ORIGEN: Damián junto al potro, Odila en su silla y Nela en su alfombra, en las anclas de
#     B y de cara a la cámara); mientras no, junto a su puerta, fuera de umbrales y caminos.
#   - Dentro de un interior se anda en RECTAS que no cruzan muebles (lo andable de B, con su margen): la recta si se
#     puede; si no, una rejilla de 0,2 m y el camino más corto, estirado en tramos rectos (_ruta_dentro).
#   - La GALGA tiene una sola ubicación (Barrio.donde_galga): en la repisa de la vivienda (la copia de B), con Kael (no
#     se ve) o, cuando Damián corta el pasador, otra vez en su clavo del taller, dentro de su silueta pintada.
#   - Tocar lo PRIVADO o pedir lo OFRECIDO (Barrio.accion) hace que su dueño, si está en la sala, se pare, se gire hacia
#     Kael y conteste (Barrio.reaccion; el texto lo enseña la región). Barrio.presentes dice quién está en la sala.
#
# CÓMO (barato en el móvil, O(1) por vecino):
#   - Cada rutina es un PROGRAMA (lista de pasos: ir, tarea, coger, dejar, entrar/salir de un interior) que se compila
#     una vez en tramos con su instante: el paso que toca es (reloj − retraso) mod ciclo. No hay navegación ni física:
#     la posición, el clip y DÓNDE ESTÁ CADA OBJETO salen del instante. Fuera de la vista o lejos, el vecino ni se dibuja
#     ni se anima ni tiene choques; al volver a verlo está donde le toca (el «salto» coincide con lo simulado).
#   - Cada objeto tiene UNA ubicación lógica («sitio:<nombre>» o «mano»): una copia por sitio y otra en la mano
#     (BoneAttachment3D en «pecho» o «mano.R» del chibi; en la cápsula de reserva, un punto fijo); se enseña la que toca.
#     El cambio va con el temporizador del paso (a mitad de coger o dejar), nunca con la pose del clip. Nada se coge
#     donde no está ni se deja si no se lleva (la prueba lo recorre entero).
#   - Los caminos: el GRAFO del trazado (tramos rectos) o una recta andable; nadie se para en un umbral (PASOS) ni en el
#     eje de una puerta, ni pisa a Avena.
#   - Hablar INTERRUMPE: si está cruzando un umbral, primero lo cruza; si está cogiendo o dejando, termina; con algo en
#     las manos usa «llevar_quieto» (no «hablar», que movería los brazos y el objeto quedaría en el aire). Se gira hacia
#     Kael; al acabar (reanudar_todos) sigue donde estaba sin perder objetos: su retraso crece lo que duró la pausa.
#     Si Kael se le pone delante, espera (nunca en un umbral) y Kael nunca queda atrapado (ocupa()).
#   - La misión cambia el PROGRAMA (Barrio.programa), no la hora: el cambio se hace al empezar el ciclo siguiente, o al
#     momento si no se le ve.
#   - El reloj y los retrasos viven en la meta de SESIÓN «barrio_reloj» (CAL y «Guardar y recargar» no los reinician).
#
# Contrato con la región (barrio.gd): montar(region), piezas(), hablar(id), reanudar_todos(), ocupa(p), al_interior(id),
# la señal vio(hecho) y soltar_caches().

signal vio(hecho: String)

const T := preload("res://zonas3d/barrio/trazado.gd")
const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const NpcBarrio := preload("res://zonas3d/barrio/npc_barrio.gd")
const NpcChibi := preload("res://personajes/npc_v12/npc_chibi.gd")
const U := preload("res://zonas3d/barrio/utensilios.gd")

const META_RELOJ := "barrio_reloj"
const CERCA := 12.0              # m: animación cada fotograma
const LEJOS := 28.0              # m: más allá, quieta (y se puede cambiar de programa: no se le ve)
const OCULTO := 34.0             # m: más allá, ni se dibuja
const ANIM_MEDIA := 15.0         # Hz de animación entre CERCA y LEJOS
const LOGICA_LEJOS := 4.0        # Hz de la posición de los que se dibujan lejos
const RADIO_HABLAR := 1.9
const RADIO_OCUPA := 0.42        # Kael no entra en este círculo (salvo si ya está dentro: así nunca queda atrapado)
const DIST_PARAR := 0.95         # quien anda espera si Kael está más cerca que esto delante
const CEDER_TRAS := 0.6          # s esperando a Kael: entonces se aparta a un lado y sigue
const APARTARSE := 0.9           # m a un lado
const PAUSA_FRASE := 3.2         # s de pausa con una frase suelta (sin diálogo)
const ESPERA_MAX := 4.0          # s esperando a que acabe de cruzar o de coger para hablar; si no, se cancela
const VEL := 0.78                # m/s andando
const VEL_LLEVAR := 0.62         # m/s cargando
const DUR_COGER := 0.8           # s de coger o dejar (el objeto cambia a la mitad)
const DUR_DENTRO := 3.0          # s de cada tramo dentro de un interior que aún no existe (B)
const PASO_RUTA := 0.1           # m entre muestras al comprobar una recta (0,25 dejaba pasar esquinas finas)
const RADIO_AVENA := 0.5         # m alrededor del eje del cuerpo de Avena (nadie la pisa)
const LARGO_AVENA := 2.2
const RUMBO_AVENA := -0.52       # rotation.y: mira al abrevadero (sur-suroeste)
const ALTO_AGUA := 0.62
const UMBRALES_PUERTA := ["paso_horno", "paso_taller", "paso_vivienda"]

# Donde se pone cada vecino (fuera): [punto, adonde mira]. La «y» la da el suelo (T.altura).
const PUNTOS := {
	"carro_caravana": [Vector3(-45.5, 0, 0.2), Vector3(-45.5, 0, 1.6)],
	"pila_patio": [Vector3(2.0, 0, -23.2), Vector3(3.4, 0, -23.2)],
	"pila_horno": [Vector3(-24.0, 0, 0.3), Vector3(-24.0, 0, -0.8)],
	"mostrador": [Vector3(-19.5, 0, 0.2), Vector3(-19.5, 0, -0.8)],
	"puesto_plaza": [Vector3(-2.8, 0, 2.9), Vector3(-2.8, 0, 4.0)],
	"carro_horno": [Vector3(-12.6, 0, 3.0), Vector3(-13.2, 0, 4.2)],      # (a un lado del ancla: Kael examina el carro)
	"carro_horno_espera": [Vector3(-15.6, 0, 2.7), Vector3(-14.4, 0, 3.9)],
	"carro_horno_carga": [Vector3(-11.4, 0, 3.9), Vector3(-12.6, 0, 4.3)],
	"gancho": [Vector3(-45.6, 0, -7.4), Vector3(-45.6, 0, -8.4)],
	"cubo_establo": [Vector3(-44.6, 0, -7.3), Vector3(-44.6, 0, -8.4)],
	"cepillar": [Vector3(-47.2, 0, -6.3), Vector3(-48.0, 0, -6.8)],
	"pozo": [Vector3(-37.4, 0, 3.4), Vector3(-37.4, 0, 4.8)],
	"abrevadero": [Vector3(-48.6, 0, -4.0), Vector3(-49.8, 0, -4.0)],
	"heno": [Vector3(-47.7, 0, -4.9), Vector3(-48.55, 0, -5.84)],
}
# La puerta de cada interior: delante (fuera del umbral) y el umbral mismo (donde desaparece o aparece).
const PUERTAS_NPC := {
	"horno": [Vector3(-22.0, 0, 0.7), Vector3(-22.0, 0, -0.95)],
	"taller": [Vector3(-3.4, 0, -19.5), Vector3(-4.9, 0, -19.5)],
	"vivienda": [Vector3(-22.0, 0, -28.4), Vector3(-22.0, 0, -29.95)],
}
# Dónde descansa cada objeto. Fuera: «pos» con su altura SOBRE el suelo. Dentro: «ancla» de B y su altura.
const SITIOS := {
	"carro_caravana": {"lugar": "", "pos": Vector3(-45.5, 0.9, 1.15)},
	"carro_caravana_saco": {"lugar": "", "pos": Vector3(-46.4, 0.9, 1.15)},
	"pila_patio": {"lugar": "", "pos": Vector3(3.4, 1.2, -23.2)},
	"pila_horno": {"lugar": "", "pos": Vector3(-24.0, 0.0, -0.6)},
	"mostrador": {"lugar": "", "pos": Vector3(-19.9, 1.0, -0.7)},
	"mostrador_cesta": {"lugar": "", "pos": Vector3(-19.0, 1.0, -0.7)},
	"puesto_plaza": {"lugar": "", "pos": Vector3(-2.8, 0.9, 3.95)},
	"carro_horno": {"lugar": "", "pos": Vector3(-13.6, 0.9, 4.2)},
	"carro_horno_caja": {"lugar": "", "pos": Vector3(-12.7, 0.9, 4.3)},
	"gancho": {"lugar": "", "pos": Vector3(-45.6, 1.35, -7.92)},
	"cubo_establo": {"lugar": "", "pos": Vector3(-44.6, 0.0, -7.8)},
	"abrevadero": {"lugar": "", "pos": Vector3(-48.9, 0.0, -2.6)},
	# la bandeja, sobre la solera de piedra de la boca del horno (crear_interiores.py: y 0,88-0,97, z 1,8-2,08)
	"boca": {"lugar": "horno", "ancla": "int_horno_boca", "desp": Vector3(0.0, 0.97, -0.5)},
}
# Hacia dónde mira cada vecino en un ancla de dentro (por defecto, al norte: al fondo de la sala, donde está el mueble).
# Maela amasa al norte de la artesa, de cara a ella y a la cámara.
const MIRA_DENTRO := {"int_horno_maela": Vector3(0, 0, 1)}
const REJILLA_DENTRO := 0.2      # m: la rejilla del camino más corto dentro de un interior
const PASO_DENTRO := 0.05        # m entre muestras al comprobar una recta dentro
const HOLGURA_KAEL := 0.15       # m de holgura con los muebles para quien anda a toques (recta_libre_dentro)
# La galga colgada otra vez en su clavo (taller, local): el pivote en el agujero, junto al clavo de crear_interiores.py
# (silueta en x 6,6-6,96, y 1,62-1,71, sobre la pared norte), a lo largo de +x y de canto contra la pared.
const GALGA_CLAVO := Vector3(6.63, 1.665, 0.03)

# Los programas. Pasos: ["ir", punto] · ["tarea", clip, s] · ["coger", obj, sitio] · ["dejar", obj, sitio] ·
# ["entrar", interior] · ["salir", interior] · ["evento", nombre]. Los puntos «i:<ancla>» son de dentro (B).
const PROGRAMAS := {
	"maela": {"oficio": "panadera", "base": "i:int_horno_maela", "lugar": "horno", "desfase": 40.0,
		"inicial": {"bandeja": "boca", "cesta_pan": "mostrador_cesta"},
		"normal": [["tarea", "amasar", 16.0], ["ir", "i:int_horno_boca"], ["tarea", "hornear", 10.0],
			["coger", "bandeja", "boca"], ["salir", "horno"], ["ir", "mostrador"], ["dejar", "bandeja", "mostrador"],
			["tarea", "tarea", 4.0], ["coger", "cesta_pan", "mostrador_cesta"], ["ir", "puesto_plaza"],
			["dejar", "cesta_pan", "puesto_plaza"], ["tarea", "tarea", 9.0], ["evento", "pan_en_puesto"],
			["coger", "cesta_pan", "puesto_plaza"], ["ir", "mostrador"], ["dejar", "cesta_pan", "mostrador_cesta"],
			["coger", "bandeja", "mostrador"], ["entrar", "horno"], ["ir", "i:int_horno_boca"],
			["dejar", "bandeja", "boca"], ["ir", "i:int_horno_maela"]],
		"carro_parado": [["tarea", "amasar", 16.0], ["ir", "i:int_horno_boca"], ["tarea", "hornear", 10.0],
			["coger", "bandeja", "boca"], ["salir", "horno"], ["ir", "mostrador"], ["dejar", "bandeja", "mostrador"],
			["ir", "carro_horno"], ["tarea", "reposo", 16.0], ["evento", "mira_la_rueda"], ["ir", "mostrador"],
			["coger", "bandeja", "mostrador"], ["entrar", "horno"], ["ir", "i:int_horno_boca"],
			["dejar", "bandeja", "boca"], ["ir", "i:int_horno_maela"]],
		"reparto": [["tarea", "amasar", 16.0], ["ir", "i:int_horno_boca"], ["tarea", "hornear", 10.0],
			["coger", "bandeja", "boca"], ["salir", "horno"], ["ir", "carro_horno"], ["dejar", "bandeja", "carro_horno"],
			["tarea", "tarea", 4.0], ["evento", "pan_al_carro"], ["ir", "mostrador"],
			["coger", "cesta_pan", "mostrador_cesta"], ["ir", "puesto_plaza"], ["dejar", "cesta_pan", "puesto_plaza"],
			["tarea", "tarea", 8.0], ["coger", "cesta_pan", "puesto_plaza"], ["ir", "mostrador"],
			["dejar", "cesta_pan", "mostrador_cesta"], ["ir", "carro_horno"], ["coger", "bandeja", "carro_horno"],
			["entrar", "horno"], ["ir", "i:int_horno_boca"], ["dejar", "bandeja", "boca"], ["ir", "i:int_horno_maela"]]},
	"tobias": {"oficio": "porteador", "base": "carro_caravana", "lugar": "", "desfase": 0.0,
		"inicial": {"caja": "carro_caravana", "saco_harina": "carro_caravana_saco"},
		"normal": [["tarea", "tarea", 3.0], ["coger", "caja", "carro_caravana"], ["ir", "pila_patio"],
			["dejar", "caja", "pila_patio"], ["tarea", "tarea", 3.0], ["ir", "carro_caravana"],
			["coger", "saco_harina", "carro_caravana_saco"], ["ir", "pila_horno"], ["dejar", "saco_harina", "pila_horno"],
			["tarea", "reposo", 3.0], ["ir", "carro_caravana"]],
		"carro_parado": [["tarea", "tarea", 3.0], ["ir", "carro_horno_espera"], ["tarea", "reposo", 40.0],
			["ir", "carro_caravana"]],
		"reparto": [["tarea", "tarea", 3.0], ["coger", "caja", "carro_caravana"], ["ir", "carro_horno_carga"],
			["dejar", "caja", "carro_horno_caja"], ["tarea", "tarea", 3.0], ["evento", "carga_el_carro"],
			["ir", "carro_caravana"], ["coger", "saco_harina", "carro_caravana_saco"], ["ir", "pila_horno"],
			["dejar", "saco_harina", "pila_horno"], ["tarea", "reposo", 3.0], ["ir", "carro_caravana"]]},
	"brena": {"oficio": "encargada_establo", "base": "gancho", "lugar": "", "desfase": 10.0,
		"inicial": {"cepillo": "gancho", "cubo": "cubo_establo"},
		"normal": [["coger", "cepillo", "gancho"], ["ir", "cepillar"], ["evento", "cepilla"], ["tarea", "cepillar", 25.0],
			["evento", "cepillada"], ["ir", "gancho"], ["dejar", "cepillo", "gancho"], ["ir", "cubo_establo"],
			["coger", "cubo", "cubo_establo"], ["ir", "pozo"], ["tarea", "coger", 4.0], ["ir", "abrevadero"],
			["tarea", "verter", 3.0], ["evento", "agua"], ["dejar", "cubo", "abrevadero"], ["ir", "heno"],
			["tarea", "tarea", 6.0], ["evento", "heno"], ["ir", "abrevadero"], ["coger", "cubo", "abrevadero"],
			["ir", "cubo_establo"], ["dejar", "cubo", "cubo_establo"], ["ir", "gancho"], ["tarea", "reposo", 5.0]]},
}
const AVENA_BEBE := 14.0         # s bebiendo tras el agua
const AVENA_COME := 20.0         # s comiendo tras el heno

var region = null
var t := 0.0                     # el reloj del barrio (s)
var vecinos := {}                # id → Dictionary (ver _nuevo_vecino)
var avena: Node3D = null
var avena_anim: AnimationPlayer = null
var avena_clip := ""
var agua: MeshInstance3D = null
var objetos := {}                # obj → {"npc", "sitios": {sitio → Node3D}, "mano": Node3D}
var zona := ""                   # "" fuera; si no, el interior de Kael
var us_proceso := 0.0            # µs medios de _process (la prueba los mide)
var errores: Array = []          # lo que la compilación de los programas encuentra mal (la prueba exige vacío)
var _rutas := {}                 # caché de rutas de fuera: "a|b" → Array[Vector3]
var _t_logica := 0.0
var _montado := false
var galga_clavo: Node3D = null   # la galga otra vez en su clavo del taller (Barrio.donde_galga() == "clavo")


# ================================================================= montar

func montar(r) -> void:
	region = r
	zona = str(r.interior) if r != null and r.get("interior") != null else ""
	var reloj: Dictionary = Engine.get_meta(META_RELOJ, {}) if Engine.get_meta(META_RELOJ, {}) is Dictionary else {}
	t = float(reloj.get("t", 0.0))
	var guardados: Dictionary = reloj.get("npc", {})
	var cont := Node3D.new()
	cont.name = "Objetos"
	add_child(cont)
	for id in PROGRAMAS:
		var g: Dictionary = guardados.get(id, {})
		var prog := str(g.get("programa", Barrio.programa(id)))
		if not PROGRAMAS[id].has(prog):
			prog = "normal"
		var v := _nuevo_vecino(id, prog)
		v["retraso"] = float(g.get("retraso", t - float(PROGRAMAS[id]["desfase"])))
		v["vuelta"] = floori((t - v["retraso"]) / v["ciclo"])
		v["veces"] = int(g.get("veces", 0))
		for prog_n in PROGRAMAS[id]:
			if PROGRAMAS[id][prog_n] is Array:
				for p in PROGRAMAS[id][prog_n]:
					if p[0] in ["coger", "dejar"]:
						_objeto(p[1], id, p[2], cont)
		for o in PROGRAMAS[id]["inicial"]:
			_objeto(o, id, PROGRAMAS[id]["inicial"][o], cont)
	for id in Barrio.PUESTOS:
		var v := _nuevo_vecino(id, "puesto")
		v["veces"] = int(guardados.get(id, {}).get("veces", 0))
	_crear_avena()
	_crear_galga_clavo()
	Barrio.reaccion = ""
	_montado = true
	_actualizar(0.0, true)


func _exit_tree() -> void:
	guardar_reloj()
	Barrio.presentes = {}
	Barrio.reaccion = ""


# El reloj y los retrasos, a la meta de SESIÓN (los quita banco_pruebas.salir()).
func guardar_reloj() -> void:
	if not _montado:
		return
	var npc := {}
	for id in vecinos:
		var v: Dictionary = vecinos[id]
		npc[id] = {"retraso": v["retraso"] + (t - v["pausa_desde"] if v["charla"] == "hablando" else 0.0),
			"programa": v["programa"], "veces": v["veces"]}
	Engine.set_meta(META_RELOJ, {"t": t, "npc": npc})


func _nuevo_vecino(id: String, prog: String) -> Dictionary:
	var d: Dictionary = Barrio.NPCS[id]
	var n := Node3D.new()
	n.name = "Vecino_" + id
	add_child(n)
	var chibi: Node3D = null
	var oficio: String = d["chibi"][0]
	if NpcBarrio.hay(oficio, d["chibi"][1]):
		chibi = NpcBarrio.crear_barrio(oficio, d["chibi"][1])
		if not chibi.listo:
			chibi.free()
			chibi = null
	var agarres := {}
	if chibi != null:
		n.add_child(chibi)
		chibi.sombra(region != null and region.get("perfil") is Dictionary and region.perfil.get("sombras", false))
		for h in NpcBarrio.HUESOS:
			agarres[h] = chibi.agarre(h)
	else:
		n.add_child(_capsula(d["tinte"], d["chibi"][0] == "nina"))
	for h in NpcBarrio.HUESOS:                          # (sin hueso: un punto fijo delante del pecho o en la mano)
		if agarres.get(h) == null:
			var a := Node3D.new()
			a.name = "Agarre_" + h.replace(".", "_")
			a.position = Vector3(0, 0.82, 0.30) if h == "pecho" else Vector3(-0.26, 0.62, 0.12)
			n.add_child(a)
			agarres[h] = a
	var v := {"id": id, "nodo": n, "chibi": chibi, "agarres": agarres, "programa": prog, "segs": [], "ciclo": 1.0,
		"retraso": 0.0, "vuelta": 0, "veces": 0, "charla": "", "pausa_desde": 0.0, "fin_charla": -1.0, "espera": 0.0,
		"con_dialogo": false, "mira_kael": false, "pos": Vector3.ZERO, "lugar": "", "clip": "", "rumbo": 0.0,
		"ubic": {}, "seg": {}, "visible": false, "t_anim": 0.0, "parado": false, "tau": 0.0, "t_parado": 0.0,
		"desvio": Vector3.ZERO, "desvio_obj": Vector3.ZERO}
	if prog == "puesto":
		var q: Dictionary = Barrio.PUESTOS[id]
		var dentro := Barrio.interior_hecho(q["interior"]) and region != null
		var p: Vector3 = _ancla(q["ancla"]) if dentro else _suelo(q["fuera"])
		var m: Vector3 = p + Vector3(0, 0, 1) if dentro else _suelo(q["mira"])
		v["segs"] = [{"t0": 0.0, "dur": 1.0, "tipo": "tarea", "clip": q["tarea"], "pts": [p], "lugar": q["interior"] if dentro else "",
			"mira": m, "ubic": {}, "ubic_fin": {}}]
	else:
		var c := compilar(id, prog)
		v["segs"] = c["segs"]
		v["ciclo"] = c["ciclo"]
	vecinos[id] = v
	return v


func _capsula(tinte: Color, pequena: bool) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Capsula"
	var k := 0.72 if pequena else 1.0
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.26 * k
	c.height = 1.45 * k
	mi.mesh = c
	mi.position.y = 0.725 * k
	var m := StandardMaterial3D.new()
	m.albedo_color = tinte
	m.roughness = 0.9
	mi.material_override = m
	raiz.add_child(mi)
	var nariz := MeshInstance3D.new()                  # (hacia dónde mira)
	var b := BoxMesh.new()
	b.size = Vector3(0.10, 0.08, 0.12)
	nariz.mesh = b
	nariz.position = Vector3(0, 1.22 * k, 0.26 * k)
	nariz.material_override = m
	raiz.add_child(nariz)
	return raiz


# Una copia del objeto por cada sitio donde puede estar y otra en la mano de su vecino.
func _objeto(obj: String, npc: String, sitio: String, cont: Node3D) -> void:
	if not objetos.has(obj):
		var mano := U.crear(obj)
		var v: Dictionary = vecinos[npc]
		var ag: Node3D = v["agarres"][U.agarre(obj)]
		ag.add_child(mano)
		mano.visible = false
		# El punto de agarre (delante del pecho, en el borde que toca el cuerpo, o la palma de la mano derecha) en la pose
		# de reposo, derecho (sin heredar el giro del hueso); el pivote del utensilio va ahí (U.en_mano).
		var em: Array = U.en_mano(obj)
		if v["chibi"] != null:
			var hueso_n := "pecho" if U.agarre(obj) == "pecho" else "mano.R"
			var hueso: Transform3D = v["chibi"].reposo_hueso(hueso_n)
			var punto: Vector3 = hueso.origin + (Vector3(0, -0.10, 0.12) if hueso_n == "pecho" else Vector3(0, -0.05, 0.02))
			mano.transform = hueso.affine_inverse() * Transform3D(em[0], punto + em[1])
		else:
			mano.transform = Transform3D(em[0], em[1])
		objetos[obj] = {"npc": npc, "sitios": {}, "mano": mano}
	var o: Dictionary = objetos[obj]
	if o["sitios"].has(sitio):
		return
	var n := U.crear(obj)
	n.name = "%s_en_%s" % [obj, sitio]
	cont.add_child(n)
	n.visible = false
	var s: Dictionary = SITIOS.get(sitio, {})
	if s.is_empty():
		errores.append("sitio desconocido «%s» (%s)" % [sitio, obj])
	elif str(s["lugar"]) == "":
		var p: Vector3 = s["pos"]
		n.position = Vector3(p.x, T.altura(p.x, p.z) + p.y, p.z) + U.sobre_base(obj)
	else:
		n.position = _ancla(s["ancla"]) + s.get("desp", Vector3(0, 1.0, 0)) + U.sobre_base(obj)
	o["sitios"][sitio] = n


func _crear_avena() -> void:
	avena = Node3D.new()
	avena.name = "Avena"
	add_child(avena)
	avena.position = T.ancla("establo_caballo")
	avena.rotation.y = RUMBO_AVENA
	var ruta := "res://personajes/npc_v12/caballo/caballo.glb"
	if ResourceLoader.exists(ruta):
		var m: Node3D = (load(ruta) as PackedScene).instantiate()
		m.name = "Modelo"
		avena.add_child(m)
		avena_anim = m.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if avena_anim != null:
			for c in avena_anim.get_animation_list():
				avena_anim.get_animation(c).loop_mode = Animation.LOOP_LINEAR
			avena_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	else:
		avena.add_child(_avena_reserva())
	agua = MeshInstance3D.new()                         # el agua del abrevadero: opaca (nada transparente en bajo)
	agua.name = "Agua"
	var b := BoxMesh.new()
	b.size = Vector3(0.6, 0.04, 1.8)
	agua.mesh = b
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.30, 0.46, 0.58)
	m.roughness = 0.2
	agua.material_override = m
	agua.position = Vector3(-49.6, ALTO_AGUA, -4.0)
	agua.visible = false
	add_child(agua)


# Sin el prototipo de Blender: un caballo de cajas (cuerpo, cuello, cabeza, patas y cola), presentado como reserva.
func _avena_reserva() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Reserva"
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.56, 0.40, 0.26)
	m.roughness = 0.9
	var crin := StandardMaterial3D.new()
	crin.albedo_color = Color(0.86, 0.80, 0.62)
	var partes := [["Cuerpo", Vector3(0.5, 0.55, 1.4), Vector3(0, 1.05, 0), m],
		["Cola", Vector3(0.12, 0.6, 0.12), Vector3(0, 0.95, -0.78), crin]]
	for x in [-0.17, 0.17]:
		for z in [-0.52, 0.52]:
			partes.append(["Pata", Vector3(0.14, 0.82, 0.14), Vector3(x, 0.41, z), m])
	for p in partes:
		var mi := MeshInstance3D.new()
		mi.name = p[0]
		var b := BoxMesh.new()
		b.size = p[1]
		mi.mesh = b
		mi.position = p[2]
		mi.material_override = p[3]
		raiz.add_child(mi)
	var cuello := Node3D.new()                          # el cuello gira para beber y comer
	cuello.name = "Cuello"
	cuello.position = Vector3(0, 1.25, 0.62)
	raiz.add_child(cuello)
	for p in [["Cuello", Vector3(0.24, 0.62, 0.26), Vector3(0, 0.22, 0.12), m], ["Cabeza", Vector3(0.22, 0.24, 0.5), Vector3(0, 0.5, 0.38), m],
			["Crin", Vector3(0.06, 0.5, 0.14), Vector3(0, 0.3, -0.02), crin]]:
		var mi := MeshInstance3D.new()
		mi.name = p[0]
		var b := BoxMesh.new()
		b.size = p[1]
		mi.mesh = b
		mi.position = p[2]
		mi.material_override = p[3]
		cuello.add_child(mi)
	return raiz


# ================================================================= compilar los programas

func _suelo(p: Vector3) -> Vector3:
	return Vector3(p.x, T.altura(p.x, p.z), p.z)


func _ancla(a: String) -> Vector3:
	if region != null and region.has_method("ancla"):
		return region.ancla(a)
	return Vector3.ZERO


func _interior_de_ancla(a: String) -> String:
	for id in ["horno", "taller", "vivienda"]:
		if a.begins_with("int_%s_" % id):
			return id
	return ""


# Posición, lugar y adónde mira un punto con nombre.
func _punto(nombre: String) -> Array:
	if nombre.begins_with("i:"):
		var a := nombre.trim_prefix("i:")
		var p := _ancla(a)
		return [p, _interior_de_ancla(a), p + MIRA_DENTRO.get(a, Vector3(0, 0, -1))]
	if PUNTOS.has(nombre):
		return [_suelo(PUNTOS[nombre][0]), "", _suelo(PUNTOS[nombre][1])]
	errores.append("punto desconocido «%s»" % nombre)
	return [T.INICIO, "", T.INICIO + Vector3.FORWARD]


func compilar(id: String, prog: String) -> Dictionary:
	var P: Dictionary = PROGRAMAS[id]
	var segs: Array = []
	var t0 := 0.0
	var base := _punto(P["base"])
	var pos: Vector3 = base[0]
	var lugar: String = P["lugar"]
	var mira: Vector3 = base[2]
	var ubic: Dictionary = {}
	for o in P["inicial"]:
		ubic[o] = "sitio:" + str(P["inicial"][o])
	for paso in P[prog]:
		var lleva := ubic.values().has("mano")
		var vel := VEL_LLEVAR if lleva else VEL
		match str(paso[0]):
			"tarea":
				segs.append({"t0": t0, "dur": float(paso[2]), "tipo": "tarea", "clip": paso[1], "pts": [pos], "lugar": lugar,
					"mira": mira, "ubic": ubic.duplicate(), "ubic_fin": ubic.duplicate()})
				t0 += float(paso[2])
			"evento":
				segs.append({"t0": t0, "dur": 0.001, "tipo": "evento", "evento": paso[1], "clip": "reposo", "pts": [pos],
					"lugar": lugar, "mira": mira, "ubic": ubic.duplicate(), "ubic_fin": ubic.duplicate()})
				t0 += 0.001
			"ir":
				var dest := _punto(paso[1])
				if dest[1] != lugar:
					errores.append("%s/%s: «ir» a %s sin entrar o salir (%s → %s)" % [id, prog, paso[1], lugar, dest[1]])
				var pts: Array = _ruta(pos, dest[0], lugar, "%s/%s" % [id, prog])
				var dur := _duracion(pts, lugar, vel)
				segs.append({"t0": t0, "dur": dur, "tipo": "ir", "clip": "caminar_llevar" if lleva else "caminar", "pts": pts,
					"lugar": lugar, "mira": dest[2], "vel": vel, "ubic": ubic.duplicate(), "ubic_fin": ubic.duplicate()})
				t0 += dur
				pos = dest[0]
				mira = dest[2]
			"coger", "dejar":
				var obj: String = paso[1]
				var sitio: String = paso[2]
				var antes := ubic.duplicate()
				if paso[0] == "coger":
					if str(ubic.get(obj, "")) != "sitio:" + sitio:
						errores.append("%s/%s: coge %s en %s, pero está en %s" % [id, prog, obj, sitio, ubic.get(obj, "?")])
					ubic[obj] = "mano"
				else:
					if str(ubic.get(obj, "")) != "mano":
						errores.append("%s/%s: deja %s sin llevarlo (%s)" % [id, prog, obj, ubic.get(obj, "?")])
					ubic[obj] = "sitio:" + sitio
				if str(SITIOS.get(sitio, {}).get("lugar", "?")) != lugar:
					errores.append("%s/%s: %s %s en %s desde otro lugar (%s)" % [id, prog, paso[0], obj, sitio, lugar])
				segs.append({"t0": t0, "dur": DUR_COGER, "tipo": paso[0], "clip": paso[0], "obj": obj, "sitio": sitio,
					"pts": [pos], "lugar": lugar, "mira": mira, "ubic": antes, "ubic_fin": ubic.duplicate()})
				t0 += DUR_COGER
			"entrar":
				var pu: Array = PUERTAS_NPC[paso[1]]
				var frente := _suelo(pu[0])
				var umbral := _suelo(pu[1])
				var pts: Array = _ruta(pos, frente, "", "%s/%s" % [id, prog]) + [umbral]
				var dur := _duracion(pts, "", vel)
				segs.append({"t0": t0, "dur": dur, "tipo": "ir", "clip": "caminar_llevar" if lleva else "caminar", "pts": pts,
					"lugar": "", "lugar_fin": paso[1], "mira": umbral + (umbral - frente), "vel": vel,
					"ubic": ubic.duplicate(), "ubic_fin": ubic.duplicate()})
				t0 += dur
				lugar = paso[1]
				pos = _ancla("int_%s_salida" % paso[1])
				mira = pos + Vector3(0, 0, -1)
			"salir":
				var pu: Array = PUERTAS_NPC[paso[1]]
				var dentro := _ancla("int_%s_salida" % paso[1])
				var pts_d: Array = _ruta(pos, dentro, lugar, "%s/%s" % [id, prog])
				var d1 := _duracion(pts_d, lugar, vel)
				segs.append({"t0": t0, "dur": d1, "tipo": "ir", "clip": "caminar_llevar" if lleva else "caminar", "pts": pts_d,
					"lugar": lugar, "mira": dentro + Vector3(0, 0, 1), "vel": vel, "ubic": ubic.duplicate(), "ubic_fin": ubic.duplicate()})
				t0 += d1
				lugar = ""
				var umbral := _suelo(pu[1])
				var frente := _suelo(pu[0])
				var d2 := _duracion([umbral, frente], "", vel)
				segs.append({"t0": t0, "dur": d2, "tipo": "ir", "clip": "caminar_llevar" if lleva else "caminar", "pts": [umbral, frente],
					"lugar": "", "mira": frente + (frente - umbral), "vel": vel, "ubic": ubic.duplicate(), "ubic_fin": ubic.duplicate()})
				t0 += d2
				pos = frente
				mira = frente + (frente - umbral)
			_:
				errores.append("%s/%s: paso desconocido %s" % [id, prog, paso])
	if pos.distance_to(base[0]) > 0.05 or lugar != P["lugar"]:
		errores.append("%s/%s: el programa no acaba donde empieza (%s, %s)" % [id, prog, pos, lugar])
	return {"segs": segs, "ciclo": maxf(t0, 1.0), "final": ubic}


func _duracion(pts: Array, lugar: String, vel: float) -> float:
	if lugar != "" and not Barrio.interior_hecho(lugar):
		return DUR_DENTRO
	var l := 0.0
	for i in range(1, pts.size()):
		l += Vector2(pts[i].x - pts[i - 1].x, pts[i].z - pts[i - 1].z).length()
	return maxf(l / vel, 0.2)


# Una recta que se puede andar entera (fuera de lo sólido y de los umbrales, sin pisar a Avena).
func recta_libre(a: Vector3, b: Vector3) -> bool:
	var n := maxi(1, ceili(Vector2(b.x - a.x, b.z - a.z).length() / PASO_RUTA))
	for i in range(0, n + 1):
		var p := a.lerp(b, float(i) / n)
		if not T.andable(p.x, p.z) or _dist_avena(p) < RADIO_AVENA + 0.25:
			return false
		if i > 0 and i < n and T.en_paso(p.x, p.z) in UMBRALES_PUERTA:
			return false                                 # (por una puerta solo se cruza al entrar o salir; el arco del atajo, sí)
	return true


# Fuera: la recta si se puede; si no, por el GRAFO del trazado (BFS). Dentro: _ruta_dentro (lo andable es de B).
func _ruta(a: Vector3, b: Vector3, lugar: String, quien: String) -> Array:
	if lugar != "":
		return _ruta_dentro(a, b, lugar, quien)
	var clave := "%s|%s" % [a, b]
	if _rutas.has(clave):
		return _rutas[clave]
	var r: Array = []
	if recta_libre(a, b):
		r = [a, b]
	else:
		var na := _nodo_cercano(a)
		var nb := _nodo_cercano(b)
		if na == "" or nb == "":
			errores.append("%s: sin nodo del grafo cerca de %s o de %s" % [quien, a, b])
			r = [a, b]
		else:
			r = [a]
			for n in _bfs(na, nb):
				r.append(T.ancla(n))
			r.append(b)
	_rutas[clave] = r
	return r


# Los interiores de B (la región los tiene; sin región, las pruebas de datos: nada).
func _interiores():
	return region.get("interiores") if region != null else null


# ¿Se pisa p con holgura? (lo andable de B en p y a «m» metros en cruz: los bloqueos de B ya llevan el margen del
# cuerpo, pero quien anda se para a unos centímetros de cada punto y la recta siguiente no debe rozar una esquina)
func _libre_dentro(it, p: Vector3, m: float) -> bool:
	if not it.andable(p):
		return false
	if m <= 0.0:
		return true
	for d in [Vector3(m, 0, 0), Vector3(-m, 0, 0), Vector3(0, 0, m), Vector3(0, 0, -m)]:
		if not it.andable(p + d):
			return false
	return true


# Una recta que se anda entera DENTRO (cada 5 cm). Los vecinos van por la recta exacta (sin holgura: su posición sale
# del reloj); quien anda a toques (Kael, el recorrido jugado) se para a unos centímetros de cada punto y anda a pasos de
# 15 cm, y pide holgura «m», salvo en los primeros y últimos 20 cm (los puntos de trabajo están pegados a su mueble).
func recta_libre_dentro(a: Vector3, b: Vector3, m := 0.0) -> bool:
	var it = _interiores()
	if it == null:
		return true
	var largo := Vector2(b.x - a.x, b.z - a.z).length()
	var n := maxi(1, ceili(largo / PASO_DENTRO))
	for i in range(0, n + 1):
		var d := largo * float(i) / n
		var holgura := m if (d > 0.2 and largo - d > 0.2) else 0.0
		if not _libre_dentro(it, a.lerp(b, float(i) / n), holgura):
			return false
	return true


# Dentro de un interior: la recta si no cruza ningún mueble; si no, el camino más corto por una rejilla de 0,2 m (BFS
# en 8 direcciones sobre lo andable) estirado en tramos rectos que tampoco cruzan nada. Cada punto con la altura del
# suelo de B (la alcoba está más alta). Con holgura «m» (quien anda a toques), [] si no hay camino con ella.
func _ruta_dentro(a: Vector3, b: Vector3, lugar: String, quien: String, m := 0.0) -> Array:
	var it = _interiores()
	if it == null or not Barrio.interior_hecho(lugar):
		return [a, b]
	var clave := "%s|%s|%s|%s" % [lugar, a, b, m]
	if _rutas.has(clave):
		return _rutas[clave]
	var r: Array = [a, b]
	if not recta_libre_dentro(a, b, m):
		var o: Vector3 = it.ORIGEN[lugar]
		var tam: Vector2 = it.TAM[lugar]
		var nx := int(tam.x / REJILLA_DENTRO) + 1
		var nz := int(tam.y / REJILLA_DENTRO) + 1
		var celda := func(i: int, j: int) -> Vector3:
			var q := o + Vector3(i * REJILLA_DENTRO, 0, j * REJILLA_DENTRO)
			return Vector3(q.x, it.altura(q), q.z)
		var libre := func(i: int, j: int) -> bool:
			return i >= 0 and j >= 0 and i < nx and j < nz and _libre_dentro(it, celda.call(i, j), m)
		var cerca := func(p: Vector3) -> Vector2i:              # la celda libre más cercana a la que se llega en recta
			var mejor := Vector2i(-1, -1)
			var dmin := INF
			var ci := int(round((p.x - o.x) / REJILLA_DENTRO))
			var cj := int(round((p.z - o.z) / REJILLA_DENTRO))
			for di in range(-4, 5):
				for dj in range(-4, 5):
					var i := ci + di
					var j := cj + dj
					if libre.call(i, j):
						var q: Vector3 = celda.call(i, j)
						var d := Vector2(q.x - p.x, q.z - p.z).length()
						if d < dmin and recta_libre_dentro(p, q, m):
							dmin = d
							mejor = Vector2i(i, j)
			return mejor
		var ca: Vector2i = cerca.call(a)
		var cb: Vector2i = cerca.call(b)
		var camino: Array = []
		if ca.x >= 0 and cb.x >= 0:
			var prev := {ca: ca}
			var cola: Array = [ca]
			while not cola.is_empty():
				var c: Vector2i = cola.pop_front()
				if c == cb:
					break
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1),
						Vector2i(-1, 1), Vector2i(-1, -1)]:
					var s: Vector2i = c + d
					if not prev.has(s) and libre.call(s.x, s.y) and (d.x == 0 or d.y == 0 or (libre.call(c.x + d.x, c.y) and libre.call(c.x, c.y + d.y))):
						prev[s] = c
						cola.append(s)
			if prev.has(cb):
				var x: Vector2i = cb
				while x != ca:
					camino.push_front(celda.call(x.x, x.y))
					x = prev[x]
				camino.push_front(celda.call(ca.x, ca.y))
		if camino.is_empty() and m > 0.0:
			return []
		if camino.is_empty():
			errores.append("%s: sin camino dentro de %s de %s a %s" % [quien, lugar, a, b])
		else:
			var todos: Array = [a] + camino + [b]
			r = [a]                                              # estirar: de cada punto, al más lejano que se ve en recta
			var i := 0
			while i < todos.size() - 1:
				var j := todos.size() - 1
				while j > i + 1 and not recta_libre_dentro(todos[i], todos[j], m):
					j -= 1
				r.append(todos[j])
				i = j
	_rutas[clave] = r
	return r


func _nodo_cercano(p: Vector3) -> String:
	var mejor := ""
	var dmin := INF
	for n in T.GRAFO:
		var q := T.ancla(n)
		var d := Vector2(q.x - p.x, q.z - p.z).length()
		if d < dmin and recta_libre(p, q):
			dmin = d
			mejor = n
	if mejor == "":
		# (p junto a un umbral, como la puerta del taller por fuera: ninguna recta lo libra del todo; el nodo más cercano
		# con la recta andable sin mirar los umbrales, mejor que una recta que atraviesa casas)
		for n in T.GRAFO:
			var q := T.ancla(n)
			var d := Vector2(q.x - p.x, q.z - p.z).length()
			if d < dmin and _recta_andable(p, q):
				dmin = d
				mejor = n
	return mejor


func _recta_andable(a: Vector3, b: Vector3) -> bool:
	var n := maxi(1, ceili(Vector2(b.x - a.x, b.z - a.z).length() / 0.1))
	for i in range(0, n + 1):
		var p := a.lerp(b, float(i) / n)
		if not T.andable(p.x, p.z):
			return false
	return true


func _bfs(a: String, b: String) -> Array:
	var prev := {a: ""}
	var cola := [a]
	while not cola.is_empty():
		var n: String = cola.pop_front()
		if n == b:
			break
		for m in T.GRAFO[n]:
			if not prev.has(m):
				prev[m] = n
				cola.append(m)
	var r: Array = []
	var x := b
	while x != "":
		r.push_front(x)
		x = prev.get(x, "")
	return r


# El eje del cuerpo de Avena (de la cola a la cabeza).
func eje_avena() -> Array:
	var c := T.ancla("establo_caballo")
	var d := Vector3(sin(RUMBO_AVENA), 0, cos(RUMBO_AVENA))
	return [c - d * LARGO_AVENA * 0.5, c + d * LARGO_AVENA * 0.5]


func _dist_avena(p: Vector3) -> float:
	var e := eje_avena()
	var a := Vector2(e[0].x, e[0].z)
	var b := Vector2(e[1].x, e[1].z)
	var q := Vector2(p.x, p.z)
	var ab := b - a
	var k := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return q.distance_to(a + ab * k)


# ================================================================= el instante

# Lo que hace un vecino en el instante «tau» de su ciclo: {pos, lugar, clip, mira, ubic, seg, frac}.
func estado_en(v: Dictionary, tau: float) -> Dictionary:
	var segs: Array = v["segs"]
	var s: Dictionary = segs[segs.size() - 1]
	for x in segs:
		if tau < float(x["t0"]) + float(x["dur"]):
			s = x
			break
	var frac := clampf((tau - float(s["t0"])) / maxf(float(s["dur"]), 0.001), 0.0, 1.0)
	var pts: Array = s["pts"]
	var pos: Vector3 = pts[0]
	var lugar: String = s["lugar"]
	if s["tipo"] == "ir" and pts.size() > 1:
		pos = _por_la_ruta(pts, frac)
		if s.has("lugar_fin") and frac >= 1.0:
			lugar = s["lugar_fin"]
	var ubic: Dictionary = s["ubic_fin"] if (s["tipo"] in ["coger", "dejar"] and frac >= 0.5) else s["ubic"]
	return {"pos": pos, "lugar": lugar, "clip": s["clip"], "mira": s["mira"], "ubic": ubic, "seg": s, "frac": frac}


func _por_la_ruta(pts: Array, frac: float) -> Vector3:
	var largos: Array = [0.0]
	for i in range(1, pts.size()):
		largos.append(largos[i - 1] + (pts[i] as Vector3).distance_to(pts[i - 1]))
	var obj: float = largos[largos.size() - 1] * frac
	for i in range(1, pts.size()):
		if obj <= largos[i] or i == pts.size() - 1:
			var tramo: float = largos[i] - largos[i - 1]
			var k := 0.0 if tramo <= 0.0 else clampf((obj - largos[i - 1]) / tramo, 0.0, 1.0)
			return (pts[i - 1] as Vector3).lerp(pts[i], k)
	return pts[pts.size() - 1]


func tau_de(v: Dictionary) -> float:
	var r: float = v["retraso"]
	if v["charla"] == "hablando":
		r += t - float(v["pausa_desde"])
	return fposmod(t - r, float(v["ciclo"]))


# El estado de un vecino ahora (para las pruebas y la región).
func estado_de(id: String) -> Dictionary:
	var v: Dictionary = vecinos.get(id, {})
	if v.is_empty():
		return {}
	var e := estado_en(v, tau_de(v))
	e["programa"] = v["programa"]
	e["tau"] = tau_de(v)
	e["charla"] = v["charla"]
	return e


# Avanza el reloj de golpe (las pruebas: lo que pasa sin mirar).
func avanzar_reloj(s: float) -> void:
	t += s
	_actualizar(0.0, true)


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	if not _montado:
		return
	var t0 := Time.get_ticks_usec()
	t += delta
	_actualizar(delta, false)
	us_proceso = lerpf(us_proceso, float(Time.get_ticks_usec() - t0), 0.05)


func _kael() -> Vector3:
	if region != null and region.get("kael") != null:
		return region.kael.global_position
	return Vector3(INF, 0, INF)


func _actualizar(delta: float, forzar: bool) -> void:
	var k := _kael()
	var cam: Camera3D = region.cam if region != null and region.get("cam") != null else null
	_t_logica -= delta
	var logica := forzar or _t_logica <= 0.0
	if logica:
		_t_logica = 1.0 / LOGICA_LEJOS
	for id in vecinos:
		var v: Dictionary = vecinos[id]
		var vuelta := floori((t - v["retraso"]) / float(v["ciclo"])) if v["charla"] != "hablando" else int(v["vuelta"])
		if vuelta != int(v["vuelta"]):
			v["vuelta"] = vuelta
			if v["charla"] == "":
				_cambiar_programa(v, true)
		elif logica and v["charla"] == "" and v["programa"] != "puesto" and Barrio.programa(id) != v["programa"] 				and not _se_ve(v, k, cam):
			_cambiar_programa(v, false)
		_charla(v, k)
		var e := estado_en(v, tau_de(v))
		var dist := Vector2(e["pos"].x - k.x, e["pos"].z - k.z).length()
		var en_zona: bool = e["lugar"] == zona
		var dibuja: bool = en_zona and dist < OCULTO and not (e["lugar"] != "" and not Barrio.interior_hecho(e["lugar"]))
		# Kael delante: quien anda espera (nunca dentro de un umbral); si Kael no se aparta en CEDER_TRAS, el vecino se
		# hace a un lado (un desvío solo de lo que se ve, que vuelve a cero cuando Kael se aleja) y sigue: nadie se queda
		# esperando al otro para siempre. El reloj y lo que lleva no cambian.
		var parado := false
		if dibuja and v["charla"] == "" and e["seg"]["tipo"] == "ir" and dist < 2.0 and v["desvio_obj"] == Vector3.ZERO:
			var adelante: Vector3 = (e["seg"]["pts"][e["seg"]["pts"].size() - 1] - e["pos"])
			adelante.y = 0
			var hacia := Vector3(k.x - e["pos"].x, 0, k.z - e["pos"].z)
			if dist < DIST_PARAR and adelante.length() > 0.05 and adelante.normalized().dot(hacia.normalized()) > 0.35 \
					and T.en_paso(e["pos"].x, e["pos"].z) == "":
				parado = true
				v["t_parado"] = float(v["t_parado"]) + delta
				v["retraso"] = float(v["retraso"]) + delta
				if float(v["t_parado"]) > CEDER_TRAS:
					v["desvio_obj"] = _lado_libre(e["pos"], adelante, hacia)
					parado = v["desvio_obj"] == Vector3.ZERO
		if not parado:
			v["t_parado"] = 0.0
		if v["desvio_obj"] != Vector3.ZERO and (dist > 2.2 or e["seg"]["tipo"] != "ir"):
			v["desvio_obj"] = Vector3.ZERO
		v["desvio"] = (v["desvio"] as Vector3).move_toward(v["desvio_obj"], 1.6 * delta if not forzar else 10.0)
		e["pos"] = e["pos"] + v["desvio"]
		v["parado"] = parado
		_aplicar_objetos(e["lugar"], e["ubic"])
		_aplicar_eventos(v, e)
		v["pos"] = e["pos"]
		v["lugar"] = e["lugar"]
		v["ubic"] = e["ubic"]
		v["seg"] = e["seg"]
		v["tau"] = tau_de(v)
		var n: Node3D = v["nodo"]
		if not dibuja:
			if n.visible:
				n.visible = false
			v["visible"] = false
			continue
		n.visible = true
		v["visible"] = true
		if dist > LEJOS and not logica:
			continue                                     # (lejos: la posición a LOGICA_LEJOS Hz)
		n.global_position = e["pos"]
		var objetivo: Vector3 = e["mira"]
		if v["charla"] == "hablando":
			objetivo = k
		elif e["seg"]["tipo"] == "ir" and not parado:
			var pts: Array = e["seg"]["pts"]
			objetivo = e["pos"] + (_por_la_ruta(pts, minf(1.0, e["frac"] + 0.02)) - e["pos"]) * 50.0
		var dir := Vector3(objetivo.x - e["pos"].x, 0, objetivo.z - e["pos"].z)
		if dir.length() > 0.05:
			var quiere := atan2(dir.x, dir.z)
			n.rotation.y = quiere if forzar else lerp_angle(n.rotation.y, quiere, 1.0 - exp(-10.0 * delta))
		_animar(v, e, dist, delta, parado, cam)
	_actualizar_avena(k, delta)
	if logica:
		_presentes()
		_galga()
	_reaccion_pendiente(k)


# Quién está ahora en la sala de Kael (o fuera, cerca): lo mira Barrio.accion para lo privado y lo ofrecido.
func _presentes() -> void:
	var p := {}
	for id in vecinos:
		var v: Dictionary = vecinos[id]
		if v["visible"] and v["lugar"] == zona and zona != "":
			p[id] = true
	Barrio.presentes = p


# La galga, en un solo sitio: la copia de la repisa (de B) se oculta en cuanto Kael la coge; vuelve a su clavo del
# taller cuando Damián corta el pasador.
func _galga() -> void:
	var donde := Barrio.donde_galga()
	var it = _interiores()
	if it != null and it.has_method("poner_sitio"):
		it.poner_sitio("galga", donde == "repisa")
	if galga_clavo != null:
		galga_clavo.visible = donde == "clavo" and zona == "taller"


func _crear_galga_clavo() -> void:
	var it = _interiores()
	if it == null or not Barrio.interior_hecho("taller"):
		return
	galga_clavo = U.crear("galga")
	galga_clavo.name = "Galga_en_el_clavo"
	add_child(galga_clavo)
	galga_clavo.transform = Transform3D(Basis(Vector3.UP, -PI / 2.0), it.ORIGEN["taller"] + GALGA_CLAVO)
	galga_clavo.visible = false
	var sh := "res://zonas3d/muestra_calle/calle_vertice.gdshader"         # (como la de la repisa, de B: luz fija)
	if U.del_modelo_cache("galga") and ResourceLoader.exists(sh):
		var m := ShaderMaterial.new()
		m.shader = load(sh)
		m.set_shader_parameter("textura", load(U.RUTA_ATLAS) if ResourceLoader.exists(U.RUTA_ATLAS) else null)
		m.set_shader_parameter("luz_escala", 0.85)
		m.set_shader_parameter("sombra_fuerza", 0.0)
		m.set_shader_parameter("contacto_fuerza", 0.0)
		for mi in ([galga_clavo] + galga_clavo.find_children("*", "MeshInstance3D", true, false)):
			if mi is MeshInstance3D:
				(mi as MeshInstance3D).material_override = m


# Lo privado tocado o lo ofrecido pedido (Barrio.accion pone Barrio.reaccion): su dueño, si está en la sala, se para,
# se gira hacia Kael y contesta (el texto ya lo enseña la región); luego sigue con lo suyo, como tras una frase.
func _reaccion_pendiente(k: Vector3) -> void:
	if Barrio.reaccion == "":
		return
	var id := Barrio.reaccion
	Barrio.reaccion = ""
	var v: Dictionary = vecinos.get(id, {})
	if v.is_empty() or v["charla"] != "" or not v["visible"] or v["lugar"] != zona or not _puede_parar(v):
		return
	v["charla"] = "hablando"
	v["pausa_desde"] = t
	v["fin_charla"] = t + PAUSA_FRASE
	v["con_dialogo"] = false
	var n: Node3D = v["nodo"]
	if k.x != INF:
		n.rotation.y = atan2(k.x - n.global_position.x, k.z - n.global_position.z)


# Hacia qué lado se aparta quien anda para dejar pasar a Kael (el contrario a Kael; si no se puede pisar, el otro).
func _lado_libre(p: Vector3, adelante: Vector3, hacia: Vector3) -> Vector3:
	var d := adelante.normalized()
	var lado := Vector3(-d.z, 0, d.x)
	if lado.dot(hacia) > 0.0:
		lado = -lado
	for l in [lado, -lado]:
		var q: Vector3 = p + l * APARTARSE
		if T.andable(q.x, q.z) and T.en_paso(q.x, q.z) == "" and _dist_avena(q) > RADIO_AVENA:
			return l * APARTARSE
	return Vector3.ZERO


# ¿Lo ve Kael? (en su zona, cerca y en cuadro). Si no, se le puede cambiar de programa sin que se note.
func _se_ve(v: Dictionary, k: Vector3, cam: Camera3D) -> bool:
	if v["lugar"] != zona:
		return false
	if Vector2(v["pos"].x - k.x, v["pos"].z - k.z).length() > LEJOS:
		return false
	return cam == null or cam.is_position_in_frustum(v["pos"] + Vector3(0, 0.8, 0))


func _cambiar_programa(v: Dictionary, en_la_vuelta: bool) -> void:
	if v["programa"] == "puesto":
		return
	var quiere := Barrio.programa(v["id"])
	if quiere == v["programa"] or not PROGRAMAS[v["id"]].has(quiere):
		return
	var tau_viejo := fposmod(t - float(v["retraso"]), float(v["ciclo"]))
	var c := compilar(v["id"], quiere)
	v["programa"] = quiere
	v["segs"] = c["segs"]
	v["ciclo"] = c["ciclo"]
	# en la vuelta, el ciclo nuevo sigue desde su principio (los programas de un vecino empiezan en el mismo sitio y con
	# los objetos en el mismo sitio); si no se le ve, empieza ahora desde su sitio
	v["retraso"] = t - (minf(tau_viejo, 1.0) if en_la_vuelta else 0.0)
	v["vuelta"] = floori((t - v["retraso"]) / float(v["ciclo"]))


func _aplicar_objetos(lugar: String, ubic: Dictionary) -> void:
	for obj in ubic:
		var o: Dictionary = objetos.get(obj, {})
		if o.is_empty():
			continue
		var u: String = ubic[obj]
		var mano: Node3D = o["mano"]
		var en_mano := u == "mano" and lugar == zona
		if mano.visible != en_mano:
			mano.visible = en_mano
		for s in o["sitios"]:
			var n: Node3D = o["sitios"][s]
			var ve: bool = u == "sitio:" + s and str(SITIOS[s]["lugar"]) == zona \
				and (zona == "" or Barrio.interior_hecho(zona))
			if n.visible != ve:
				n.visible = ve


func _aplicar_eventos(v: Dictionary, e: Dictionary) -> void:
	var s: Dictionary = e["seg"]
	if s.get("tipo", "") != "evento":
		return
	var marca := [int(v["vuelta"]), float(s["t0"])]
	if v.get("ultimo_evento", []) != marca:
		v["ultimo_evento"] = marca
		if v["visible"]:
			vio.emit("%s:%s" % [v["id"], s["evento"]])


func _animar(v: Dictionary, e: Dictionary, dist: float, delta: float, parado: bool, cam: Camera3D) -> void:
	var ch = v["chibi"]
	if ch == null:
		return
	var lleva: bool = e["ubic"].values().has("mano")
	var c: String = e["clip"]
	var vel := 1.0
	if v["charla"] == "hablando":
		c = "llevar_quieto" if lleva else "hablar"
	elif parado:
		c = "llevar_quieto" if lleva else "reposo"
	elif e["seg"]["tipo"] == "ir":
		vel = float(e["seg"].get("vel", VEL)) / ch.velocidad_natural()
	elif c == "reposo" and lleva:
		c = "llevar_quieto"
	if c != v["clip"] or vel != v.get("vel_clip", 1.0):
		v["clip"] = c
		v["vel_clip"] = vel
		ch.poner(c, vel)
	# la animación: cada fotograma de cerca, a ANIM_MEDIA Hz más lejos, nada lejos o fuera de cuadro
	if dist > LEJOS or (cam != null and not cam.is_position_in_frustum(e["pos"] + Vector3(0, 0.8, 0))):
		return
	if dist <= CERCA:
		ch.avanzar(delta)
		return
	v["t_anim"] = float(v["t_anim"]) + delta
	if float(v["t_anim"]) >= 1.0 / ANIM_MEDIA:
		ch.avanzar(v["t_anim"])
		v["t_anim"] = 0.0


# Avena según la rutina de Brena (bebe tras el agua, come tras el heno), y el agua del abrevadero.
func estado_avena() -> Dictionary:
	var v: Dictionary = vecinos.get("brena", {})
	if v.is_empty():
		return {"clip": "reposo", "agua": false}
	var tau := tau_de(v)
	var t_agua := -1.0
	var t_heno := -1.0
	for s in v["segs"]:
		if s["tipo"] == "evento" and s["evento"] == "agua":
			t_agua = s["t0"]
		if s["tipo"] == "evento" and s["evento"] == "heno":
			t_heno = s["t0"]
	var clip := "reposo"
	if t_agua >= 0.0 and tau >= t_agua and tau < t_agua + AVENA_BEBE:
		clip = "beber"
	elif t_heno >= 0.0 and tau >= t_heno and tau < t_heno + AVENA_COME:
		clip = "comer"
	elif fposmod(tau, 23.0) < 1.6:
		clip = "sacudir"
	return {"clip": clip, "agua": t_agua >= 0.0 and tau >= t_agua}


func _actualizar_avena(k: Vector3, delta: float) -> void:
	if avena == null:
		return
	var fuera := zona == ""
	var dist := Vector2(avena.position.x - k.x, avena.position.z - k.z).length()
	avena.visible = fuera and dist < OCULTO
	agua.visible = false
	if not avena.visible:
		return
	var e := estado_avena()
	agua.visible = e["agua"]
	if e["clip"] != avena_clip:
		avena_clip = e["clip"]
		if avena_anim != null:
			var c: String = avena_clip if avena_anim.has_animation(avena_clip) else "reposo"
			if avena_anim.has_animation(c):
				avena_anim.play(c, 0.3)
	if dist > CERCA:
		return
	if avena_anim != null:
		avena_anim.advance(delta)
	else:
		var cuello := avena.get_node_or_null("Reserva/Cuello") as Node3D
		if cuello != null:
			var baja := {"beber": 1.1, "comer": 0.9, "sacudir": -0.25}.get(avena_clip, 0.0) as float
			var oscila := sin(t * (6.0 if avena_clip == "sacudir" else 1.6)) * (0.18 if avena_clip == "sacudir" else 0.04)
			cuello.rotation.x = lerpf(cuello.rotation.x, baja + oscila, 1.0 - exp(-4.0 * delta))


# ================================================================= hablar

# ¿Puede pararse a hablar ya? No a mitad de coger o dejar, ni dentro de un umbral.
func _puede_parar(v: Dictionary) -> bool:
	var e := estado_en(v, tau_de(v))
	if e["seg"]["tipo"] in ["coger", "dejar"]:
		return false
	return T.en_paso(e["pos"].x, e["pos"].z) == ""


func _charla(v: Dictionary, k: Vector3) -> void:
	match str(v["charla"]):
		"pendiente":
			v["espera"] = float(v["espera"]) + get_process_delta_time()
			var e := estado_en(v, tau_de(v))
			if e["lugar"] != zona:
				v["charla"] = ""
				if region != null and region.has_method("avisar"):
					region.avisar("%s ha entrado. Ya saldrá." % Barrio.NPCS[v["id"]]["corto"], "", 2.4)
			elif _puede_parar(v):
				_empezar_charla(v)
			elif float(v["espera"]) > ESPERA_MAX:
				v["charla"] = ""
		"hablando":
			if not v["con_dialogo"] and float(v["fin_charla"]) >= 0.0 and t >= float(v["fin_charla"]):
				_reanudar(v)


func hablar(id: String) -> void:
	var v: Dictionary = vecinos.get(id, {})
	if not v.is_empty() and v["charla"] == "hablando" and not v["con_dialogo"]:
		_reanudar(v)                                     # (diciendo una frase o contestando a lo tocado: se habla ya)
	if v.is_empty() or v["charla"] != "":
		return
	v["espera"] = 0.0
	if _puede_parar(v):
		_empezar_charla(v)
	else:
		v["charla"] = "pendiente"                        # (primero cruza el umbral o acaba de coger o dejar)


func _empezar_charla(v: Dictionary) -> void:
	var id: String = v["id"]
	v["charla"] = "hablando"
	v["pausa_desde"] = t
	v["fin_charla"] = -1.0
	var ruta := Barrio.dialogo_de(id, int(v["veces"]))
	var frase := Barrio.frase(id, int(v["veces"]))
	v["veces"] = int(v["veces"]) + 1
	v["con_dialogo"] = ruta != "" and region != null and region.has_method("iniciar_dialogo") and region.iniciar_dialogo(ruta)
	if not v["con_dialogo"]:
		v["fin_charla"] = t + PAUSA_FRASE
		if region != null and region.has_method("avisar"):
			region.avisar("%s: «%s»" % [Barrio.NPCS[id]["corto"], frase], "", PAUSA_FRASE)
	var k := _kael()                                     # (se gira hacia Kael en el acto)
	var n: Node3D = v["nodo"]
	if k.x != INF:
		n.rotation.y = atan2(k.x - n.global_position.x, k.z - n.global_position.z)


func _reanudar(v: Dictionary) -> void:
	if v["charla"] != "hablando":
		v["charla"] = ""
		return
	v["retraso"] = float(v["retraso"]) + (t - float(v["pausa_desde"]))   # sigue donde estaba: su reloj se retrasa
	v["charla"] = ""
	v["con_dialogo"] = false
	v["vuelta"] = floori((t - v["retraso"]) / float(v["ciclo"]))


# La región lo llama al acabar cada diálogo: todos siguen con lo suyo (sin perder lo que llevaban).
func reanudar_todos() -> void:
	for id in vecinos:
		if vecinos[id]["charla"] == "hablando":
			_reanudar(vecinos[id])
		elif vecinos[id]["charla"] == "pendiente":
			vecinos[id]["charla"] = ""


# ================================================================= contrato con la región

# [[id, posición, radio, texto del botón]] de los vecinos que se ven en la zona de Kael.
func piezas() -> Array:
	var r: Array = []
	for id in vecinos:
		var v: Dictionary = vecinos[id]
		if v["visible"] and v["lugar"] == zona:
			r.append([id, v["pos"], RADIO_HABLAR, str(Barrio.NPCS[id]["boton"])])
	return r


# ¿Pisa p a un vecino o a Avena? (Kael no entra; si ya está dentro de uno, puede salir: nunca queda atrapado)
func ocupa(p: Vector3) -> bool:
	var k := _kael()
	for id in vecinos:
		var v: Dictionary = vecinos[id]
		if not v["visible"] or v["lugar"] != zona:
			continue
		var q: Vector3 = v["pos"]
		if Vector2(p.x - q.x, p.z - q.z).length() < RADIO_OCUPA and Vector2(k.x - q.x, k.z - q.z).length() >= RADIO_OCUPA:
			return true
	if zona == "" and avena != null:
		if _dist_avena(p) < RADIO_AVENA and _dist_avena(k) >= RADIO_AVENA:
			return true
	return false


func al_interior(id: String) -> void:
	zona = id
	_actualizar(0.0, true)


# Cachés estáticas: las de los utensilios y las de los modelos del barrio en npc_chibi (solo sus oficios y personas: lo
# de Oakhaven no se toca). Las suelta banco_pruebas.salir() y la región al salir del árbol.
static func soltar_caches() -> void:
	U.soltar_caches()
	var Chibi = load("res://personajes/npc_v12/npc_chibi.gd")
	for o in ["panadera", "porteador", "encargada_establo"]:
		Chibi._escenas.erase(o)
	for p in Barrio.NPCS:
		Chibi._materiales.erase(str(Barrio.NPCS[p]["chibi"][1]))
