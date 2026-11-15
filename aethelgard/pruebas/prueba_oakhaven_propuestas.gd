extends SceneTree
# V12 (14/11, fase 7): la PROPUESTA «Las tres marcas del cantero» y la losa del cantero (ciudades/oakhaven_propuestas.gd;
# interruptor «oakhaven_propuestas_v12», APAGADO), con datos aislados y su propia partida.
# Sin «3d» (lista: prueba_oakhaven_propuestas):
#   1. Apagada no cambia nada: las mismas piezas, sin losa, las señales no hacen nada, el arcón no da la nota y la misión
#      no sale en el Diario aunque el arcón esté abierto.
#   2. Encendida, los datos: cuatro piezas en sitios pisables y a 2,5 casillas o más de todo lo que se examina; textos
#      sin nada reservado (D-033, D-073); la losa siempre tiene solución y su combinación es la que se deduce de las
#      marcas (ordenadas por sus muescas: Rayo, Agua, Luna), que no sale escrita en ningún texto.
#   3. Encendida, la misión entera (14/11, con el aprendiz del cantero): el aprendiz la encarga (paso «arcón») o la empieza
#      el arcón; el diálogo que toca en cada momento; cada marca, una vez, al Diario (pista) y con las tres el paso
#      siguiente; la losa da su premio UNA vez (y el cincel y la carta); volver con el aprendiz da el Polvo de cantera UNA
#      vez y la misión acaba; guardar y cargar antes de empezar, a mitad, con la cerradura vista y al final; partida
#      antigua. El camino al revés (el arcón antes que el aprendiz) y la losa antes que las marcas.
#   3b. El taller de Lya: la investigación del polvo no sale hasta tenerlo; se estudia, la receta da Éter y el polvo se
#      acaba (no hay fabricación infinita).
#   4. En la ciudad 2D (encendida): «Examinar la marca» apunta la marca; «Girar los anillos» en la losa abre su cerradura
#      (la de la losa, no la del arcón) y resolverla la abre.
# Con «3d» (lista: prueba_oakhaven_propuestas_3d):
#   5. Oakhaven 3D apagada: nada nuevo. Encendida: las cuatro piezas con su botón y alcanzables, la losa en el suelo, una
#      marca se apunta y la losa se abre con su cerradura.
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_oakhaven_propuestas.save"
const T := 64.0
const INTERRUPTOR := "oakhaven_propuestas_v12"
const LOSA := "oak_losa_cantero"
const MARCAS := ["oak_marca_torre", "oak_marca_fuente", "oak_marca_raiz"]
const PROHIBIDO := ["erebo", "corazon", "olvido", "rocio", "cripta", "trampilla", "conclave", "hermano", "recuerd"]
var Oak
var Prop
var P
var Inv
var E
var C
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	Oak = load("res://ciudades/oakhaven.gd")
	Prop = load("res://ciudades/oakhaven_propuestas.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	E = load("res://encargos.gd")
	C = load("res://cerradura_runica.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "oak_franja", "oak_franja_t", "pos_3d", "pos_zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("pos_zona_ok", false)


func _probar() -> void:
	await _esperar(3)
	_limpiar()
	if "3d" in OS.get_cmdline_user_args():
		await _en_3d()
	else:
		_apagada()
		_datos()
		_mision()
		await _ciudad()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _plano(t: String) -> String:
	var p := t.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"]]:
		p = p.replace(par[0], par[1])
	return p


# 1. Apagada.
func _apagada() -> void:
	Engine.set_meta(INTERRUPTOR, false)
	_ok(Oak.piezas_activas() == Oak.PIEZAS and Oak.pieza(LOSA).is_empty() and Oak.config_cerradura(LOSA).is_empty(),
		"1: apagada, hay piezas o cerradura nuevas")
	_ok(Oak.npcs_activos() == Oak.NPCS and Oak.npc("cantero").is_empty() and Oak.dialogo_de("cantero") == "",
		"1: apagada, sale el aprendiz del cantero")
	_ok(Oak.aplicar_senal("oak:cantero_pedido") == "" and not P.estado(Oak.NOMBRE, "cantero_pedido"),
		"1: apagada, el encargo del aprendiz empieza algo")
	_ok(not load("res://investigacion.gd").visible("lya_cantera"), "1: apagada, el taller enseña la investigación del polvo")
	_ok(Oak.aplicar_senal("oak:cantero_marca_1") == "" and not P.estado(Oak.NOMBRE, "cantero_marca_1"),
		"1: apagada, una marca se apunta")
	var t: String = Oak.abrir_cerradura()
	_ok(t.begins_with("Dentro del arcón") and not t.contains("cantero"), "1: apagada, el arcón da la nota («%s»)" % t)
	_ok(E.estado(E.de("prop_cantero")) == "oculto", "1: apagada, la misión sale en el Diario")
	_ok(Oak.abrir_cerradura(LOSA) == "", "1: apagada, la losa se abre")
	_ok(Oak.aplicar_senal("oak:cantero_fin") == "" and Inv.cantidad("Polvo de cantera") == 0, "1: apagada, el final da algo")
	_limpiar()


# 2. Los datos.
func _datos() -> void:
	Engine.set_meta(INTERRUPTOR, true)
	var nuevas: Array = Prop.PIEZAS
	_ok(nuevas.size() == 4 and Oak.piezas_activas().size() == Oak.PIEZAS.size() + 4, "2: encendida, no salen las cuatro piezas")
	var puntos: Array = []
	for lista in [Oak.NPCS, Oak.COFRES, Oak.PIEZAS, Oak.NOTAS]:
		for d in lista:
			if d.has("casilla"):
				puntos.append([d["id"], d["casilla"]])
	for id in Oak.SITIOS_DETALLE:
		puntos.append([id, Oak.SITIOS_DETALLE[id]])
	for p in nuevas:
		var c: Vector2 = p["casilla"]
		var pisable := false
		var choca := false
		for l in Oak.LUGARES:
			if (l["rect"] as Rect2).has_point(c):
				pisable = pisable or l["pisable"]
				choca = choca or not l["pisable"]
		_ok(pisable and not choca, "2: %s en %s no está en un sitio pisable" % [p["id"], c])
		for q in puntos:
			_ok(c.distance_to(q[1]) >= 2.5, "2: %s a %.1f de %s" % [p["id"], c.distance_to(q[1]), q[0]])
		puntos.append([p["id"], c])
		_ok(Oak.error_condicion(p["si"]) == "", "2: condición mal en %s" % p["id"])
		for k in ["texto", "texto_sin"]:
			for x in PROHIBIDO:
				_ok(not _plano(str(p[k])).contains(x), "2: «%s» en %s de %s" % [x, k, p["id"]])
	for n in Prop.NPCS:                                           # el aprendiz: sitio pisable, apartado y fuera del paso
		var c: Vector2 = n["casilla"]
		var pisable := false
		for l in Oak.LUGARES:
			pisable = pisable or ((l["rect"] as Rect2).has_point(c) and l["pisable"])
		_ok(pisable, "2: el vecino %s no está en un sitio pisable" % n["id"])
		for q in puntos:
			_ok(c.distance_to(q[1]) >= 2.5, "2: el vecino %s a %.1f de %s" % [n["id"], c.distance_to(q[1]), q[0]])
		for d in n["dialogos"]:
			_ok(Oak.error_condicion(d.get("si", "")) == "", "2: condición mal en %s/%s" % [n["id"], d["dialogo"]])
			_ok(ResourceLoader.exists(Oak.ruta_dialogo(d["dialogo"])), "2: falta el diálogo %s" % d["dialogo"])
			var dtl := FileAccess.get_file_as_string(Oak.ruta_dialogo(d["dialogo"]))
			for x in PROHIBIDO:
				_ok(not _plano(dtl).contains(x), "2: «%s» en %s" % [x, d["dialogo"]])
			_ok(not dtl.contains("Rayo, Agua") and not dtl.contains("Rayo y Agua"), "2: %s da la combinación" % d["dialogo"])
	var textos: String = Prop.NOTA + " " + Prop.CERRADURA["inscripcion"]
	for m in Prop.MISIONES:
		textos += " " + m["resumen"] + " " + m["pago"]
		for x in m["pistas"]:
			textos += " " + x["texto"]
	for x in PROHIBIDO:
		_ok(not _plano(textos).contains(x), "2: «%s» en los textos de la propuesta" % x)
	# la deducción: las marcas, ordenadas por sus muescas, dan la combinación; ningún texto la da hecha
	var orden := {"una sola muesca": 1, "dos muescas": 2, "tres muescas": 3}
	var por_muescas := []
	for id in MARCAS:
		var t: String = Oak.pieza(id)["texto"]
		for k in orden:
			if t.to_lower().contains(k):
				for s in ["Rayo", "Agua", "Luna", "Fuego", "Cura", "Runa"]:
					if t.contains("runa de " + s):
						por_muescas.append([orden[k], s])
	por_muescas.sort_custom(func(a, b): return a[0] < b[0])
	_ok(por_muescas.map(func(x): return x[1]) == Prop.CERRADURA["objetivo"],
		"2: las marcas no dan la combinación de la losa (%s frente a %s)" % [por_muescas, Prop.CERRADURA["objetivo"]])
	_ok(not textos.contains("Rayo, Agua") and not textos.contains("Rayo, agua"), "2: un texto da la combinación hecha")
	var cfg: Dictionary = Prop.CERRADURA
	_ok(not C.resuelta_en(cfg, cfg["inicio"]), "2: la losa empieza resuelta")
	for a in 6:
		for b in 6:
			for c in 6:
				var x: Array = [a, b, c]
				for paso in C.solucion(cfg, x):
					x = C.girar_en(cfg, x, paso[0], paso[1])
				_ok(C.resuelta_en(cfg, x), "2: la losa no tiene solución desde %s" % [[a, b, c]])


# 3. La misión entera.
func _guardar_y_cargar(donde: String) -> void:
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(P.escribir(d, ARCHIVO), "3: no se pudo escribir la partida (%s)" % donde)
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary, "3: no se pudo leer la partida (%s)" % donde)
	if leida is Dictionary:
		P.restaurar(leida)


func _toca(dialogo: String, donde: String) -> void:
	var r: String = Oak.dialogo_de("cantero", 0)
	_ok(r.get_file().get_basename() == dialogo, "3: %s, el aprendiz dice «%s» y no «%s»" % [donde, r.get_file(), dialogo])


func _mision() -> void:
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	var mis: Dictionary = E.de("prop_cantero")
	_ok(E.estado(mis) == "oculto", "3: la misión sale antes de hablar con el aprendiz o abrir el arcón")
	_toca("prop_cantero_pedido", "al principio")
	_guardar_y_cargar("antes de empezar")
	_ok(E.estado(mis) == "oculto", "3: tras cargar sin empezar, la misión sale")
	_ok(Oak.aplicar_senal("oak:cantero_fin") == "" and Inv.cantidad("Polvo de cantera") == 0, "3: el final, antes de tiempo, da algo")
	var t: String = Oak.aplicar_senal("oak:cantero_pedido")
	_ok(t == "Misión: Las tres marcas del cantero.", "3: el aprendiz no empieza la misión («%s»)" % t)
	_ok(Oak.aplicar_senal("oak:cantero_pedido") == "", "3: el encargo se repite")
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "arcon", "3: el encargo no lleva al arcón")
	_ok(E.pistas_conocidas(mis).size() == 1 and E.pistas_conocidas(mis)[0].contains("agua"), "3: el Diario no apunta lo del aprendiz")
	_ok(E.pasos_conocidos(mis).size() == 1, "3: el Diario adelanta pasos")
	_toca("prop_cantero_pendiente", "con el encargo")
	t = Oak.abrir_cerradura()
	_ok(t.contains(Prop.NOTA), "3: el arcón no da la nota del cantero («%s»)" % t)
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "marcas", "3: la nota no lleva a las marcas")
	var pistas0: int = E.pistas_conocidas(mis).size()
	for i in MARCAS.size():
		var p: Dictionary = Oak.pieza(MARCAS[i])
		var aviso: String = Oak.aplicar_senal(p["senal"])
		_ok(aviso.contains("(%d de 3)" % (i + 1)), "3: la marca %s no se apunta («%s»)" % [MARCAS[i], aviso])
		_ok(Oak.aplicar_senal(p["senal"]) == "", "3: la marca %s se apunta dos veces" % MARCAS[i])
		_ok(E.pistas_conocidas(mis).size() == pistas0 + i + 1, "3: el Diario no apunta la marca %s" % MARCAS[i])
		if i == 0:
			_guardar_y_cargar("a mitad, con una marca")
			_ok(P.estado(Oak.NOMBRE, "cantero_marca_1") and not P.estado(Oak.NOMBRE, "cantero_marca_2")
				and E.paso_actual(mis).get("id", "") == "marcas", "3: tras cargar a mitad, se pierden o sobran marcas")
	_ok(E.paso_actual(mis).get("id", "") == "losa", "3: con las tres marcas no se pasa a la losa")
	# dentro del puzle: la cerradura vista y la partida guardada con ella sin abrir
	Oak.ver_cerradura(LOSA)
	_guardar_y_cargar("dentro del puzle")
	_ok(not Oak.cerradura_abierta(LOSA) and P.estado(Oak.NOMBRE, "cerradura_cantero_vista"),
		"3: tras cargar con la losa a medias, la losa está abierta o se olvida que se vio")
	var oro0: int = Inv.oro()
	var incienso0: int = Inv.cantidad("Incienso de Ceniza")
	t = Oak.abrir_cerradura(LOSA)
	_ok(t.begins_with("Bajo la losa") and t.contains("cincel") and Inv.oro() == oro0 + 80
		and Inv.cantidad("Incienso de Ceniza") == incienso0 + 1, "3: la losa no da su premio («%s»)" % t)
	_ok(Oak.abrir_cerradura(LOSA) == "" and Inv.oro() == oro0 + 80, "3: la losa da el premio dos veces")
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "volver", "3: abierta la losa, no toca volver con el aprendiz")
	_toca("prop_cantero_fin", "con la losa abierta")
	_guardar_y_cargar("con la losa abierta, sin volver")
	_ok(Oak.cerradura_abierta(LOSA) and Inv.oro() == oro0 + 80 and E.paso_actual(mis).get("id", "") == "volver",
		"3: tras cargar con la losa abierta, cambia algo")
	t = Oak.aplicar_senal("oak:cantero_fin")
	_ok(t.contains("Polvo de cantera") and Inv.cantidad("Polvo de cantera") == 3, "3: el aprendiz no da el polvo («%s»)" % t)
	_ok(Oak.aplicar_senal("oak:cantero_fin") == "" and Inv.cantidad("Polvo de cantera") == 3, "3: el aprendiz da el polvo dos veces")
	_ok(E.estado(mis) == "hecho", "3: la misión no acaba")
	_toca("prop_cantero_despues", "después")
	_guardar_y_cargar("después")
	_ok(E.estado(mis) == "hecho" and Oak.abrir_cerradura(LOSA) == "" and Oak.aplicar_senal("oak:cantero_fin") == ""
		and Inv.cantidad("Polvo de cantera") == 3, "3: tras cargar al final, algo se repite o se pierde")
	_toca("prop_cantero_despues", "después de cargar")
	_taller()
	# partida antigua (sin «mazmorras»): todo por descubrir
	var vieja: Dictionary = P.volcar("res://mapa.tscn").duplicate(true)
	vieja.erase("mazmorras")
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	P.restaurar(vieja)
	_ok(E.estado(mis) == "oculto" and not Oak.cerradura_abierta(LOSA), "3: una partida antigua no empieza de cero")
	_toca("prop_cantero_pedido", "en una partida antigua")
	# al revés: el arcón antes que el aprendiz, y la losa antes que las marcas
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	Oak.abrir_cerradura()
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "marcas", "3: el arcón, primero, no empieza la misión")
	_toca("prop_cantero_nota", "con el arcón abierto antes")
	t = Oak.aplicar_senal("oak:cantero_pedido")
	_ok(t.begins_with("Diario") and P.estado(Oak.NOMBRE, "cantero_pedido"), "3: con el arcón abierto, el aprendiz anuncia otra misión («%s»)" % t)
	Oak.aplicar_senal("oak:cantero_marca_3")
	Oak.abrir_cerradura(LOSA)
	_ok(E.paso_actual(mis).get("id", "") == "volver", "3: la losa abierta sin las marcas deja el Diario en las marcas")
	# (revisión del 14/11) el aprendiz primero y la losa SIN abrir el arcón: el Diario no manda al arcón, sino a volver
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	Oak.aplicar_senal("oak:cantero_pedido")
	_ok(E.paso_actual(mis).get("id", "") == "arcon", "3: tras el encargo, el primer paso no es el arcón")
	Oak.abrir_cerradura(LOSA)
	_ok(E.paso_actual(mis).get("id", "") == "volver" and not Oak.cerradura_abierta(),
		"3: con la losa abierta sin el arcón, el Diario no dice volver (o el arcón se abre solo)")
	_ok(E.pasos_conocidos(mis).any(func(p): return p["id"] == "volver"), "3: el paso de volver no se enseña")
	_limpiar()
	_losa_primero()
	_marcas_primero()


# 3c (15/11, auditoría externa). La losa PRIMERO, sin hablar con el aprendiz ni abrir el arcón: la misión sale en el
# Diario con «volver» (antes se quedaba oculta), el arcón sigue cerrado, no se regalan pistas de marcas no vistas, y el
# final da el polvo una sola vez, también tras guardar y cargar.
func _losa_primero() -> void:
	var mis: Dictionary = E.de("prop_cantero")
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	_ok(E.estado(mis) == "oculto", "3c: la misión sale sin hacer nada")
	var t: String = Oak.abrir_cerradura(LOSA)
	_ok(t.contains("Misión: Las tres marcas del cantero"), "3c: al abrir la losa primero no se anuncia la misión («%s»)" % t)
	_ok(E.estado(mis) == "activo", "3c: con la losa abierta primero, la misión sigue oculta en el Diario")
	_ok(E.paso_actual(mis).get("id", "") == "volver", "3c: con la losa abierta primero, el paso no es volver")
	_ok(not Oak.cerradura_abierta(), "3c: abrir la losa abre también el arcón")
	var pistas: Array = E.pistas_conocidas(mis)
	_ok(not pistas.any(func(x): return "muesca" in x or "nota" in x.to_lower() or "aprendiz:" in x.to_lower()),
		"3c: con la losa primero se regalan pistas no examinadas (%s)" % str(pistas))
	for i in [1, 2, 3]:
		_ok(not P.estado(Oak.NOMBRE, "cantero_marca_%d" % i), "3c: abrir la losa marca como vista la marca %d" % i)
	_guardar_y_cargar("con la losa abierta primero")
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "volver", "3c: tras cargar, el Diario cambia")
	_toca("prop_cantero_fin", "con la losa abierta primero")
	var antes: int = Inv.cantidad("Polvo de cantera")
	t = Oak.aplicar_senal("oak:cantero_fin")
	_ok(t.contains("Polvo de cantera") and Inv.cantidad("Polvo de cantera") == antes + 3, "3c: el final no da el polvo («%s»)" % t)
	_ok(Oak.aplicar_senal("oak:cantero_fin") == "" and Inv.cantidad("Polvo de cantera") == antes + 3, "3c: el polvo se da dos veces")
	_guardar_y_cargar("al final, con la losa primero")
	_ok(E.estado(mis) == "hecho" and Oak.aplicar_senal("oak:cantero_fin") == "" and Inv.cantidad("Polvo de cantera") == antes + 3,
		"3c: tras cargar al final, algo se repite o se pierde")
	_ok(Oak.abrir_cerradura(LOSA) == "", "3c: la losa se vuelve a abrir (premio repetido)")
	_toca("prop_cantero_despues", "después, con la losa primero")
	_limpiar()


# 3d (15/11). Las marcas PRIMERO: examinar una marca suelta no empieza la misión (es una runa gastada sin contexto);
# cuando empieza, su pista ya está y las no vistas no.
func _marcas_primero() -> void:
	var mis: Dictionary = E.de("prop_cantero")
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	Oak.aplicar_senal("oak:cantero_marca_2")
	_ok(E.estado(mis) == "oculto", "3d: una marca suelta empieza la misión")
	_guardar_y_cargar("con una marca vista antes de empezar")
	Oak.aplicar_senal("oak:cantero_pedido")
	_ok(E.estado(mis) == "activo" and E.paso_actual(mis).get("id", "") == "arcon", "3d: tras el encargo, el paso no es el arcón")
	var pistas: Array = E.pistas_conocidas(mis)
	_ok(pistas.any(func(x): return x.begins_with("Fuente")), "3d: la marca vista antes no sale en las pistas")
	_ok(not pistas.any(func(x): return x.begins_with("Puerta") or x.begins_with("Raíz")), "3d: salen marcas no vistas")
	Oak.aplicar_senal("oak:cantero_marca_1")
	Oak.aplicar_senal("oak:cantero_marca_3")
	_ok(P.estado(Oak.NOMBRE, "cantero_marcas"), "3d: con las tres marcas no queda apuntado")
	_ok(E.paso_actual(mis).get("id", "") == "arcon" and not Oak.cerradura_abierta(), "3d: las marcas abren el arcón o se lo saltan")
	_limpiar()


# 3b. El taller de Lya con el polvo (la receta da Éter; el polvo se acaba).
func _taller() -> void:
	var I = load("res://investigacion.gd")
	var Ta = load("res://talleres.gd")
	_ok(I.visible("lya_cantera") and I.estado("lya_cantera") == "disponible", "3b: con el polvo, la investigación no sale o no se puede")
	_ok(Ta.reservado("Polvo de cantera"), "3b: antes de estudiar, el polvo se puede vender (y la investigación quedaría bloqueada)")
	_ok(I.empezar("lya_cantera") == "" and I.avanzar("lya_cantera", 1) and I.estado("lya_cantera") == "completada",
		"3b: la investigación del polvo no se completa")
	_ok(Inv.cantidad("Polvo de cantera") == 3, "3b: estudiar gasta el polvo")
	_ok(not Ta.reservado("Polvo de cantera"), "3b: estudiada, el polvo sigue reservado")
	Inv.agregar_objeto("Hierba lunar", 5)
	var eter0: int = Inv.cantidad("Éter")
	var hechas := 0
	for i in 5:
		if Ta.fabricar("eter_cantera"):
			hechas += 1
	_ok(hechas == 3 and Inv.cantidad("Éter") == eter0 + 3 and Inv.cantidad("Polvo de cantera") == 0
		and Inv.cantidad("Hierba lunar") == 2, "3b: la receta no da Éter o no se acaba el polvo (%d hechas)" % hechas)
	_ok(Ta.puede("eter_cantera").contains("Polvo de cantera"), "3b: sin polvo, el motivo no lo dice («%s»)" % Ta.puede("eter_cantera"))
	_ok(I.visible("lya_cantera"), "3b: completada, la investigación deja de salir")


func _dar_con(z, id: String) -> Array:
	for e in z.piezas:
		if e[1]["id"] == id:
			return e
	return []


# 4. En la ciudad 2D, encendida.
func _ciudad() -> void:
	_limpiar()
	Engine.set_meta(INTERRUPTOR, true)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	var marca: Vector2 = Oak.pieza("oak_marca_fuente")["casilla"]
	Engine.set_meta("pos_zona", (marca + Vector2(0, 0.6)) * T)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file("res://ciudad_oakhaven.tscn")
	await _esperar(40)
	var z = current_scene
	if z == null or not z.has_method("_abrir_cerradura"):
		_ok(false, "4: no se cargó la ciudad 2D")
		return
	_ok(_dar_con(z, LOSA).size() == 3 and _dar_con(z, "oak_marca_raiz").size() == 3, "4: la ciudad no pone las piezas nuevas")
	_ok(z.npcs.any(func(n): return n[1].get("id", "") == "cantero"), "4: la ciudad 2D no pone al aprendiz")
	_ok(z.boton_examinar.text == "Examinar la marca", "4: junto a la fuente no se ofrece la marca («%s»)" % z.boton_examinar.text)
	z._accion()
	await _esperar(2)
	_ok(P.estado(Oak.NOMBRE, "cantero_marca_2"), "4: examinar la marca no la apunta")
	var losa: Array = _dar_con(z, LOSA)
	z.jugador.position = losa[2] + Vector2(0, 0.6 * T)
	await _esperar(4)
	_ok(z.boton_examinar.text == "Girar los anillos", "4: junto a la losa no se ofrece girar («%s»)" % z.boton_examinar.text)
	z._accion()
	await _esperar(3)
	var m = z.cerradura_abierta
	_ok(m != null and m.config.get("id", "") == LOSA, "4: la losa no abre su propia cerradura")
	if m == null:
		return
	for p in C.solucion(m.config, m.giros):
		m.girar(p[0], p[1])
	m.cerrar_menu()
	await _esperar(4)
	_ok(Oak.cerradura_abierta(LOSA) and not Oak.cerradura_abierta(), "4: resolver la losa no la abre (o abre el arcón)")


# 5. Oakhaven 3D.
func _alcanzable(v, p: Vector3, radio: float) -> bool:
	for k in 24:
		var q: Vector3 = p + Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0)) * (0.5 + 0.35 * (k / 8))
		q.y = p.y
		if not v._prohibido(q) and Vector2(q.x - p.x, q.z - p.z).length() < radio:
			return true
	return false


func _en_3d() -> void:
	Engine.set_meta(INTERRUPTOR, false)
	Engine.set_meta("partida_lista", true)
	change_scene_to_file("res://zonas3d/oakhaven_3d.tscn")
	await _esperar(25)
	var v = current_scene
	if v == null or v.get("vida") == null:
		_ok(false, "5: no se cargó Oakhaven 3D")
		return
	var ids: Array = v.vida.piezas().map(func(x): return x[0])
	_ok(not ("pieza:" + LOSA) in ids and not v.vida.arcon.has("losa"), "5: apagada, la 3D pone la losa")
	_ok(not v.vida.vecinos.has("cantero") and v.vida.marcas_cantero.is_empty(), "5: apagada, la 3D pone al aprendiz o las marcas")
	Engine.set_meta(INTERRUPTOR, true)
	change_scene_to_file("res://zonas3d/oakhaven_3d.tscn")
	await _esperar(25)
	v = current_scene
	var vida = v.vida
	_ok(vida.arcon.has("losa"), "5: encendida, no está la losa en el suelo")
	_ok(vida.vecinos.has("cantero") and vida.vecinos["cantero"]["chibi"] != null, "5: encendida, no está el aprendiz (con su figura)")
	_ok(vida.marcas_cantero.size() == 3, "5: encendida, no se ven las tres marcas (%d)" % vida.marcas_cantero.size())
	_ok(vida.piezas().any(func(x): return x[0] == "cantero" and x[3] == "Hablar con el aprendiz"), "5: no se ofrece hablar con el aprendiz")
	var ruta: String = vida.hablar("cantero")
	_ok(ruta.ends_with("prop_cantero_pedido.dtl"), "5: el aprendiz no empieza por su encargo («%s»)" % ruta)
	await _esperar(2)
	var dg = root.get_node_or_null("Dialogic")
	if dg != null and dg.current_timeline != null:
		dg.end_timeline()
	await _esperar(3)
	for pz in vida.piezas():
		var id := String(pz[0]).trim_prefix("pieza:")
		if not Oak.pieza(id).is_empty() and Prop.PIEZAS.any(func(p): return p["id"] == id):
			_ok(_alcanzable(v, pz[1], pz[2]), "5: %s no se alcanza" % id)
			ids.append(id)
	for p in Prop.PIEZAS:
		_ok(vida.piezas().any(func(x): return x[0] == "pieza:" + p["id"]), "5: la 3D no ofrece %s" % p["id"])
	vida.usar_pieza("oak_marca_torre")
	await _esperar(2)
	_ok(P.estado(Oak.NOMBRE, "cantero_marca_1") and vida.ultimo_aviso.contains("Marca del cantero (1 de 3)"),
		"5: la marca de la torre no se apunta («%s»)" % vida.ultimo_aviso)
	vida.usar_pieza(LOSA)
	await _esperar(3)
	var m = vida.abierto
	_ok(m != null and m.config.get("id", "") == LOSA and v.ocupado(), "5: la losa no abre su cerradura en 3D")
	if m == null:
		return
	for p in C.solucion(m.config, m.giros):
		m.girar(p[0], p[1])
	m.cerrar_menu()
	await _esperar(3)
	_ok(Oak.cerradura_abierta(LOSA) and vida.abierto == null, "5: resolver la losa en 3D no la abre")
	var ofrece := ""
	for pz in vida.piezas():
		if pz[0] == "pieza:" + LOSA:
			ofrece = pz[3]
	_ok(ofrece == "Examinar", "5: abierta, la losa no pasa a «Examinar» («%s»)" % ofrece)
	await _esperar(40)
	var piedra: Node3D = vida.arcon.get("losa_piedra")
	_ok(piedra != null and piedra.position.x > 0.6, "5: abierta, la losa no se aparta")
