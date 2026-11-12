extends SceneTree
# Magia negra (V12, fase E: magia_negra.gd, combate_afinidades.gd y sus ganchos en combate.gd, artes.gd e
# investigacion.gd). Sin ventana y con datos aislados (ejecutar_pruebas.ps1). Acaba con quit(1) si algo falla.
#   U. Sin escena: lo protegido sigue igual (las 12, Lya, Garon; nadie sabe magia negra sin el interruptor), datos
#      completos (descripción, sonido que existe, formas propias de los avanzados), afinidades (débil, resiste,
#      inmune, vulnerable), daño por escuela, estados (aplicar, renovar sin sumar, durar, expirar, resistir, inmunes,
#      maldición, marca y su reparto), preparación y rotura, Rayo Encadenado (orden por cercanía), desbloqueo por
#      nivel, libros e investigación, validación del catálogo, guardado y carga, y partida antigua.
#   A. Combate de verdad, Kael (interruptor, todo) y Lya contra tres Slimes: pestañas que caben, lista de escuelas,
#      página de una escuela, Rayo Encadenado (tres golpes que bajan, un sonido), Lluvia de Brasas (prepara: estado
#      «conjuro», barra, sin menú hasta soltarla; área, quemadura, Armonía al soltar, un sonido), Sol de Ceniza roto
#      por un golpe (PM perdidos, sonido de rotura una vez, sin daño) y Prisión de Hielo (el Slime pierde su turno y
#      la prisión acaba).
#   B. Kael contra el Coloso de la Falla: Peso del Abismo (Gravedad: inmune, ni daño ni lentitud), Prisión (inmune
#      al estado y resiste el Hielo), Chispa (débil al Rayo) y el panel de objetivos con «Inmune» y «Débil».
#   C. Kael contra Gorthor: la lentitud resistida dura menos y la prisión no entra; Manto del Eclipse baja su golpe.
#   D. Sin interruptor: el menú de Kael no tiene la pestaña de magia negra.
#   E. Los 24 hechizos, uno tras otro con el combate parado: efecto completo, golpe, estado y un solo sonido.
# Ganar o perder así no prueba la estrategia de un jugador: solo que el código funciona.

const ARCHIVO := "user://prueba_magia_negra.save"
const MAX_FOTOGRAMAS := 6000

var P
var G
var MN
var AF
var A
var I
var c = null
var frames := 0
var f_inicio := 0
var escenario := ""
var pendientes := ["A", "B", "C", "D", "E"]
var fallos: Array = []
var hechos: Array = []
var paso := 0
var sonidos: Array = []
var registros: Array = []
var datos := {}
var turnos_kael := 0


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	MN = load("res://magia_negra.gd")
	AF = load("res://combate_afinidades.gd")
	A = load("res://artes.gd")
	I = load("res://investigacion.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_unidad()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append("%s: %s" % [escenario, texto])


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa",
			"magia_negra_v12", "magia_negra_v12_todo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


# ================================================================= U: sin escena

func _unidad() -> void:
	escenario = "U"
	_limpiar()
	G.datos()
	var C = load("res://combate.gd")
	# 1. lo protegido
	var esperadas := {"Fuego": [[8, 50], [18, 70], [34, 140]], "Agua": [[6, 35], [15, 55], [30, 115]],
		"Rayo": [[7, 45], [17, 65], [32, 130]], "Cura": [[6, 45], [16, 45], [30, 100]]}
	for k in esperadas:
		for i in 3:
			var d: Dictionary = C.NIVELES_MAGIA[k][i]
			_ok(int(d["coste"]) == esperadas[k][i][0] and int(d["dano"]) == esperadas[k][i][1], "%s %d ha cambiado" % [k, i + 1])
	_ok(C.MAGIAS.size() == 4, "MAGIAS ha cambiado")
	for h in ["Kael", "Lya", "Garon", "Nyx", "Naira"]:
		_ok(MN.familias_de(h).is_empty(), "%s tiene magia negra sin el interruptor" % h)
		_ok(MN.hechizos(h).is_empty() if G.datos().has(h) else true, "%s sabe magia negra" % h)
	_ok(G.HEROES["Lya"]["magias"] == ["Cura", "Agua", "Fuego", "Rayo"], "las magias de Lya han cambiado")
	_ok(A.familias_de("Lya") == ["Lumbre"] and A.familias_de("Garon").is_empty(), "las artes han cambiado")
	_ok(MN.DE_HEROE.is_empty(), "DE_HEROE ya no está vacío")
	# 2. datos completos
	var formas_avanzadas := {}
	var n_hechizos := 0
	for fam in MN.ESCUELAS:
		_ok(MN.COLOR.has(fam) and MN.NOMBRE_ESCUELA.has(fam) and MN.DESC_ESCUELA.has(fam) and MN.SONIDO.has(fam),
			"%s sin color, nombre, descripción o sonido" % fam)
		_ok(not C.MAGIAS.has(fam) and not A.es_arte(fam), "%s choca con una magia o arte" % fam)
		var ultimo: Dictionary = MN.HECHIZOS[fam][-1]
		_ok(ultimo.has("investigacion"), "el avanzado de %s no pide investigación" % fam)
		_ok(not formas_avanzadas.has(ultimo["forma"]), "dos avanzados con la misma forma: %s" % ultimo["forma"])
		formas_avanzadas[ultimo["forma"]] = true
		for d in MN.HECHIZOS[fam]:
			n_hechizos += 1
			for campo in ["nombre", "coste", "dano", "a", "prep", "forma", "umbral"]:
				_ok(d.has(campo), "%s sin «%s»" % [d.get("nombre", "?"), campo])
			_ok(MN.DESCRIPCION.has(d["nombre"]), "%s sin descripción" % d["nombre"])
			_ok(not str(MN.DESCRIPCION.get(d["nombre"], "")).to_lower().contains("borra"), "%s dice «borra»" % d["nombre"])
			_ok(float(d["prep"]) >= 0.0 and float(d["prep"]) <= MN.PREP_MAX, "%s: preparación fuera de rango" % d["nombre"])
			if float(d["prep"]) >= 0.6:
				_ok(int(d["coste"]) >= 36, "%s: un hechizo largo y barato" % d["nombre"])
			var par: Array = MN.SONIDO_FORMA.get(d["forma"], MN.SONIDO[fam])
			_ok(Sonido.EFECTOS.has(par[1]), "%s: el sonido de respaldo «%s» no existe" % [d["nombre"], par[1]])
	for par in [MN.SONIDO_PREPARAR, MN.SONIDO_ROTO]:
		_ok(Sonido.EFECTOS.has(par[1]), "el sonido de respaldo «%s» no existe" % par[1])
	_ok(n_hechizos == 24, "hay %d hechizos y se esperaban 24" % n_hechizos)
	# 3. afinidades
	for clave in C.ENEMIGOS:
		_ok(AF.TABLA.has(clave), "«%s» no está en la tabla de afinidades" % clave)
	var e_slime := {"clave": "slime", "hp": 55, "hp_max": 55}
	var e_golem := {"clave": "golem_ambar", "hp": 200, "hp_max": 200}
	var e_coloso := {"clave": "coloso_falla", "hp": 520, "hp_max": 520, "personalidad": "coloso", "fases": true}
	var e_brama := {"clave": "bramavidrio", "hp": 1150, "hp_max": 1150, "personalidad": "bramavidrio", "titulo": true}
	var e_gorthor := {"clave": "gorthor", "hp": 460, "hp_max": 460, "personalidad": "jefe", "fases": true}
	_ok(AF.clase(e_slime, "Hielo") == "debil" and AF.clase(e_slime, "Gravedad") == "resiste" and AF.clase(e_slime, "Fuego") == "",
		"Slime: afinidades")
	_ok(AF.clase(e_golem, "Rayo") == "inmune", "Gólem: el Rayo no es inmune")
	_ok(AF.clase(e_coloso, "Gravedad") == "inmune" and AF.clase(e_coloso, "Rayo") == "debil", "Coloso: afinidades")
	_ok(AF.clase(e_brama, "Hielo") == "debil" and AF.clase(e_brama, "Fuego") == "resiste", "Bramavidrio: afinidades")
	for e in [e_coloso, e_brama, e_gorthor, {"clave": "guardian"}, {"clave": "guardian_bosque"}]:
		_ok(AF.clase_estado(e, "prision") == "inmune", "%s no es inmune a la prisión" % e["clave"])
	_ok(AF.clase_estado({"clave": "jefe_nuevo", "personalidad": "jefe"}, "prision") == "inmune", "un jefe nuevo no es inmune a la prisión")
	_ok(AF.clase({"clave": "x", "hero": true}, "Fuego") == "", "un héroe tiene afinidades")
	var vul := {"clave": "slime", "hp": 55, "hp_max": 55, "mn": {"vulnerable": 2}}
	_ok(AF.clase(vul, "Gravedad") == "" and AF.clase(vul, "Fuego") == "debil" and AF.clase(vul, "Hielo") == "debil",
		"vulnerable: no cambia bien las afinidades")
	_ok(AF.clase({"clave": "golem_ambar", "mn": {"vulnerable": 2}}, "Rayo") == "inmune", "vulnerable rompe una inmunidad")
	# 4. daño por escuela
	_ok(int(MN.con_afinidad(100, "negra_hielo", e_slime)["dano"]) == 150, "débil no hace ×1,5")
	_ok(int(MN.con_afinidad(100, "negra_gravedad", e_slime)["dano"]) == 50, "resiste no hace ×0,5")
	_ok(int(MN.con_afinidad(100, "negra_rayo", e_golem)["dano"]) == 0, "inmune hace daño")
	_ok(int(MN.con_afinidad(100, "negra_fuego", e_slime)["dano"]) == 100, "normal no hace ×1")
	_ok(int(MN.con_afinidad(100, "negra_fuego", {"clave": "slime", "mn": {"res_baja": 1}})["dano"]) == 125, "Res ↓ no hace ×1,25")
	_ok(int(MN.con_afinidad(100, "negra_debilitamiento", e_slime)["dano"]) == 100, "Debilitamiento tiene elemento")
	var colapso: Dictionary = MN.datos("negra_gravedad", 3)
	_ok(MN.dano_base(colapso, 0, {"clave": "slime", "hp": 400, "hp_max": 400}) == 100, "Colapso: no es el 25 % de la vida actual")
	_ok(MN.dano_base(colapso, 0, {"clave": "slime", "hp": 40, "hp_max": 400}) == 40, "Colapso: sin mínimo")
	_ok(MN.dano_base(colapso, 0, {"clave": "coloso_falla", "personalidad": "coloso", "hp": 520, "hp_max": 520}) == 52,
		"Colapso: sin tope en los jefes")
	_ok(MN.dano_base(MN.datos("negra_gravedad", 2), 50, {"clave": "slime", "hp": 1, "hp_max": 1}, 3) == 70, "Pozo: no suma por enemigo")
	# 5. estados
	var f := {"clave": "slime", "hp": 100, "hp_max": 100}
	_ok(MN.aplicar_estado(f, "lento", 2) == "" and MN.turnos(f, "lento") == 2, "lento no entra")
	MN.aplicar_estado(f, "lento", 3)
	_ok(MN.turnos(f, "lento") == 3, "lento no se renueva al mayor")
	MN.aplicar_estado(f, "lento", 1)
	_ok(MN.turnos(f, "lento") == 3, "lento se acorta o se suma mal")
	_ok(is_equal_approx(MN.mult_vel(f), 0.6), "lento no frena la barra")
	for i in 2:
		MN.al_empezar_turno(f)
	_ok(MN.turnos(f, "lento") == 1, "lento no baja un turno por turno")
	var r: Dictionary = MN.al_empezar_turno(f)
	_ok(MN.turnos(f, "lento") == 0 and "lento" in r["acaban"] and is_equal_approx(MN.mult_vel(f), 1.0), "lento no acaba")
	var g := e_gorthor.duplicate()
	_ok(MN.aplicar_estado(g, "lento", 3) == "resiste" and MN.turnos(g, "lento") == 2, "Gorthor no resiste la lentitud")
	_ok(MN.aplicar_estado(g, "prision", 1) == "inmune" and MN.turnos(g, "prision") == 0, "Gorthor entra en prisión")
	var pr := {"clave": "slime", "hp": 50, "hp_max": 50}
	MN.aplicar_estado(pr, "prision", 1)
	r = MN.al_empezar_turno(pr)
	_ok(r["prision"] and MN.turnos(pr, "prision") == 0, "la prisión no quita un turno o no acaba")
	_ok(not MN.al_empezar_turno(pr)["prision"], "la prisión dura dos turnos")
	var ml := {"clave": "slime", "hp": 100, "hp_max": 100}
	MN.aplicar_estado(ml, "maldicion", 3)
	_ok(int(MN.al_empezar_turno(ml)["maldicion"]) == 6, "la maldición no quita el 6 %")
	var mk := {"clave": "slime", "hp": 100, "hp_max": 100}
	MN.aplicar_estado(mk, "marca", 2)
	MN.al_recibir(mk, 50)
	MN.al_recibir(mk, 10)
	_ok(int(mk["mn"]["marca_guardado"]) == 18, "la marca no guarda el 30 %%: %s" % [mk["mn"]])
	MN.al_empezar_turno(mk)
	r = MN.al_empezar_turno(mk)
	_ok(int(r["marca"]) == 18 and MN.turnos(mk, "marca") == 0, "la marca no pesa al acabar: %s" % [r])
	var mk2 := {"clave": "slime", "hp": 0, "hp_max": 100}
	MN.aplicar_estado(mk2, "marca", 3)
	MN.al_recibir(mk2, 100)
	var otros := [mk2, {"clave": "slime", "hp": 10, "hp_max": 50}, {"clave": "slime", "hp": 10, "hp_max": 50}, {"clave": "slime", "hp": 0, "hp_max": 50}]
	var rep: Array = MN.reparto_marca(mk2, otros)
	_ok(rep.size() == 2 and int(rep[0][1]) == 15, "la marca no se reparte a los vivos: %s" % [rep.map(func(x): return x[1])])
	_ok(MN.reparto_marca(mk2, otros).is_empty(), "la marca se reparte dos veces")
	_ok(MN.textos_estado({"mn": {"lento": 2, "def_baja": 1}}) == ["Lento 2", "Def ↓ 1"], "textos de estado")
	# 6. preparación
	var h := {"nombre": "Kael", "hero": true, "hp": 100, "hp_max": 100}
	_ok(is_equal_approx(MN.preparar(h, "negra_fuego", 3, [], 100.0), 65.0), "la preparación no deja la barra en 65")
	_ok("conjuro" in A.estados_de(h), "el estado «conjuro» no sale en el HUD")
	_ok(not MN.golpe_en_conjuro(h, 20) and h.has("conjuro"), "un golpe flojo rompe el conjuro")
	_ok(MN.golpe_en_conjuro(h, 5) and not h.has("conjuro"), "dos golpes que suman el 25 % no lo rompen")
	_ok(not MN.golpe_en_conjuro(h, 999), "sin conjuro, un golpe lo «rompe»")
	# 7. Rayo Encadenado
	var e1 := {"nombre": "a", "hp": 10, "pos": Vector2(0, 0)}
	var e2 := {"nombre": "b", "hp": 10, "pos": Vector2(300, 0)}
	var e3 := {"nombre": "c", "hp": 10, "pos": Vector2(100, 0)}
	var e4 := {"nombre": "d", "hp": 0, "pos": Vector2(50, 0)}
	var cad: Array = MN.cadena(e1, [e1, e2, e3, e4], [0.7, 0.5])
	_ok(cad.map(func(x): return x[0]["nombre"]) == ["a", "c", "b"] and cad.map(func(x): return x[1]) == [1.0, 0.7, 0.5],
		"la cadena no salta al más cercano: %s" % [cad.map(func(x): return x[0]["nombre"])])
	_ok(MN.cadena(e1, [e1], [0.7, 0.5]).size() == 1, "la cadena salta sin nadie más")
	# 8. desbloqueo: nivel, libros e investigación
	Engine.set_meta("magia_negra_v12", "Kael")
	_ok(MN.familias_de("Kael").size() == 6 and MN.familias_de("Lya").is_empty(), "el interruptor no da las escuelas solo a Kael")
	var d := {"nivel": 1}
	_ok(MN.nivel_de("Kael", "negra_fuego", d) == 1 and MN.nivel_de("Kael", "negra_sombras", d) == 0, "nivel 1")
	d["nivel"] = 20
	_ok(MN.nivel_de("Kael", "negra_fuego", d) == 3, "a nivel 20 sin investigar: no se queda en 3 (%d)" % MN.nivel_de("Kael", "negra_fuego", d))
	_ok(MN.nuevas_al_subir("Kael", {"nivel": 6}, 5, 6) == [["negra_fuego", 2], ["negra_rayo", 2]],
		"aviso al subir: %s" % [MN.nuevas_al_subir("Kael", {"nivel": 6}, 5, 6)])
	_ok(I.estado("arcano_sol_ceniza") == "bloqueada", "la investigación no empieza bloqueada (sin el material)")
	_ok(I.magias_de("arcano_sol_ceniza") == ["magia:negra_fuego:4"], "la investigación no desbloquea Sol de Ceniza")
	for fam in MN.ESCUELAS:
		var ult: Dictionary = MN.HECHIZOS[fam][-1]
		var clave := "magia:%s:%d" % [fam, MN.cuantos(fam)]
		_ok(I.magias_de(ult["investigacion"]) == [clave], "%s no desbloquea %s" % [ult["investigacion"], clave])
		_ok(load("res://datos/catalogo.gd").uno("investigaciones", ult["investigacion"]).borrador,
			"%s sale ya en algún taller" % ult["investigacion"])
	I._partida()["arcano_sol_ceniza"] = {"progreso": 0, "completada": false}
	_ok(not I.avanzar_en_curso().has("arcano_sol_ceniza") and MN.nivel_de("Kael", "negra_fuego", d) == 3, "avanza de más")
	I.avanzar_en_curso()
	_ok(I.avanzar_en_curso() == ["arcano_sol_ceniza"], "no se completa con los combates ganados")
	_ok(MN.nivel_de("Kael", "negra_fuego", d) == 4 and I.magia_desbloqueada("negra_fuego", 4), "completada, no enseña Sol de Ceniza")
	_ok(I.recetas_de("alquimia").size() == I.recetas_de("alquimia").size(), "recetas_de")
	d["nivel"] = 1
	_ok(MN.aprender_en("Kael", "negra_hielo", 2, d) and MN.nivel_de("Kael", "negra_hielo", d) == 2, "el libro no enseña Escarcha Profunda")
	_ok(not d["libros"].has("Fuego") and d["libros"].has("negra_hielo"), "los libros pisan los de siempre")
	_ok(not MN.aprender_en("Lya", "negra_hielo", 2, {"nivel": 1}), "Lya aprende magia negra con un libro")
	var cat_err: Array = load("res://datos/catalogo.gd").validar()
	_ok(cat_err.is_empty(), "el catálogo da errores: %s" % [cat_err])
	_ok(MN.desbloqueo_valido("magia:negra_rayo:4") and not MN.desbloqueo_valido("magia:negra_rayo:5")
		and not MN.desbloqueo_valido("magia:Fuego:1") and not MN.desbloqueo_valido("receta"), "desbloqueos válidos")
	# 9. guardado y partida antigua
	G.datos()["Kael"]["nivel"] = 20
	G.datos()["Kael"]["libros"] = {"negra_sombras": 4}
	var antes := {}
	for fam in MN.ESCUELAS:
		antes[fam] = MN.nivel("Kael", fam)
	_ok(antes["negra_fuego"] == 4 and antes["negra_sombras"] == 3, "antes de guardar: %s" % [antes])
	Engine.set_meta("partida_lista", true)
	_ok(P.escribir(P.volcar(""), ARCHIVO), "no se guardó")
	Engine.remove_meta("grupo")
	Engine.remove_meta("investigaciones")
	_ok(MN.nivel("Kael", "negra_fuego") == 1, "sin partida, sigue sabiendo")
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary, "no se pudo leer")
	if leida is Dictionary:
		P.restaurar(leida)
		for fam in MN.ESCUELAS:
			_ok(MN.nivel("Kael", fam) == antes[fam], "%s: %d al cargar y %d al guardar" % [fam, MN.nivel("Kael", fam), antes[fam]])
	var antigua := {"grupo": {"Kael": {"nivel": 7, "exp": 0, "puntos": 18, "atributos": G.HEROES["Kael"]["atributos"].duplicate(),
		"pv": -1, "pm": -1}}}
	P.restaurar(antigua)
	_ok(MN.nivel("Kael", "negra_fuego") == 2 and MN.nivel("Kael", "negra_sombras") == 2, "partida antigua: %d, %d" %
		[MN.nivel("Kael", "negra_fuego"), MN.nivel("Kael", "negra_sombras")])
	_ok(I.completadas().is_empty(), "partida antigua con investigaciones")
	Engine.remove_meta("magia_negra_v12")
	_ok(MN.hechizos("Kael").is_empty(), "sin interruptor, Kael sigue sabiendo")
	if fallos.is_empty():
		hechos.append("U: lo protegido igual, 24 hechizos completos, afinidades, daño, estados, preparación, cadena, desbloqueo, catálogo, guardado y partida antigua")


# ================================================================= combates de verdad

func _empezar(e: String) -> void:
	escenario = e
	paso = 0
	turnos_kael = 0
	datos.clear()
	sonidos.clear()
	registros.clear()
	_limpiar()
	G.datos()
	var niveles: Dictionary = {"A": {"Kael": 12, "Lya": 10}, "B": {"Kael": 20}, "C": {"Kael": 20}, "D": {"Kael": 20},
		"E": {"Kael": 12, "Lya": 10}}[e]
	Engine.set_meta("grupo_activo", niveles.keys())
	for n in niveles:
		G.datos()[n]["nivel"] = niveles[n]
		G.datos()[n]["exp"] = 0
		G.datos()[n]["libros"] = {}
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	if e != "D":
		Engine.set_meta("magia_negra_v12", "Kael")
		Engine.set_meta("magia_negra_v12_todo", true)
	Engine.set_meta("zona", "desierto")                 # sin «zona limpia»: nadie huye solo
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", {"A": 1, "B": 12, "C": 5, "D": 8, "E": 1}[e])
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	c.MODO_PRUEBAS = false
	c.sonido_pedido.connect(func(n): sonidos.append(n))
	seed(20261112)
	for en in c.enemigos:
		en["atb"] = 0.0
		if e in ["A", "E"]:                                # aguantan todo el guion sin caer
			en["hp_max"] = 400
			en["hp"] = 400
	f_inicio = frames


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _vivos() -> Array:
	return c.enemigos.filter(func(x): return x["hp"] > 0)


func _process(_d: float) -> bool:
	frames += 1
	if frames < 10:
		return false
	if c == null:
		if pendientes.is_empty():
			_terminar()
			return true
		_empezar(pendientes.pop_front())
		return false
	if registros.is_empty() or registros[-1] != c.registro.text:
		registros.append(c.registro.text)
	if datos.has("preso"):                                 # A: la prisión, vista mientras dura
		var preso: Dictionary = datos["preso"]
		if MN.turnos(preso, "prision") > 0:
			datos["vio_prision"] = true
			if preso.has("mn_prision_nodo"):
				datos["vio_nodo"] = true
	if datos.has("apagar"):                                # se deja que acaben sus efectos y temporizadores
		if frames - int(datos["apagar"]) > 150:
			c.queue_free()
			c = null
			_limpiar()
		return false
	var kael := _heroe("Kael")
	if escenario == "E":
		_paso_e(kael)
	elif c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		if c.actor["nombre"] != "Kael":
			c._defender()
		else:
			turnos_kael += 1
			kael["mp_max"] = maxi(int(kael["mp_max"]), 200)
			kael["mp"] = kael["mp_max"]                  # PM de sobra: aquí se prueba el camino, no el gasto
			match escenario:
				"A":
					_turno_a(kael)
				"B":
					_turno_b(kael)
				"C":
					_turno_c(kael)
				"D":
					_turno_d(kael)
	if c.estado == "fin" and not datos.has("fin"):
		datos["fin"] = frames
	if datos.has("cerrar") or frames - f_inicio > MAX_FOTOGRAMAS or (datos.has("fin") and frames - int(datos["fin"]) > 90):
		_ok(paso >= 99, "no llegó al final (paso %d, estado %s)" % [paso, c.estado])
		c.set_process(false)                               # sin turnos nuevos
		datos["apagar"] = frames
	return false


func _cerrar() -> void:
	datos["cerrar"] = true


# E: los 24 hechizos, uno tras otro, con el combate parado (sin turnos): cada efecto llega a su fin, cada objetivo
# recibe su golpe una vez (los de daño) y suena una sola vez. Así se ejecutan también las formas que A, B y C no usan.
func _paso_e(kael: Dictionary) -> void:
	if not datos.has("lista"):
		if frames - f_inicio < 60:
			return
		c.set_process(false)
		var l: Array = []
		for fam in MN.ESCUELAS:
			for nv in range(1, MN.cuantos(fam) + 1):
				l.append([fam, nv])
		datos["lista"] = l
		datos["i"] = 0
		return
	if kael.get("animando", false):
		return
	var lista: Array = datos["lista"]
	if datos.has("actual"):                                # el anterior ha terminado: comprobarlo
		var fam: String = datos["actual"][0]
		var d: Dictionary = MN.datos(fam, int(datos["actual"][1]))
		var nuevos: Array = sonidos.slice(int(datos["son"]))
		var par: Array = MN.SONIDO_FORMA.get(d["forma"], MN.SONIDO[fam])
		_ok(nuevos.count(par[0]) + nuevos.count(par[1]) == 1, "%s suena %s" % [d["nombre"], nuevos])
		var objs: Array = datos["objs"]
		for j in objs.size():
			var bajo: int = int(datos["pv"][j]) - int(objs[j]["hp"])
			if int(d["dano"]) > 0 or d.has("pct"):
				_ok(bajo > 0, "%s no hace daño a %s" % [d["nombre"], objs[j]["nombre"]])
			else:
				_ok(bajo == 0, "%s hace daño sin tenerlo" % d["nombre"])
		if d.has("estado"):
			_ok(objs.all(func(o): return MN.turnos(o, d["estado"]["tipo"]) > 0), "%s no pone su estado" % d["nombre"])
		for e in c.enemigos:
			e["hp"] = e["hp_max"]
			e["quemadura"] = 0
			e.erase("mn")
			c._quitar_nodo_negra(e, "mn_marca_nodo")
			c._quitar_nodo_negra(e, "mn_prision_nodo")
			e["defendiendo"] = false
		datos.erase("actual")
		datos["espera"] = frames + 45
		return
	if frames < int(datos.get("espera", 0)):
		return
	if int(datos["i"]) >= lista.size():
		paso = 99
		_cerrar()
		return
	var x: Array = lista[int(datos["i"])]
	datos["i"] = int(datos["i"]) + 1
	var d: Dictionary = MN.datos(x[0], x[1])
	var objs: Array = c.enemigos.duplicate() if d["a"] == "enemigos" else [c.enemigos[1]]
	if d.has("saltos"):
		objs = c.enemigos.duplicate()                       # la cadena empieza en el primero y salta a los demás
	datos["actual"] = x
	datos["objs"] = objs
	datos["pv"] = objs.map(func(o): return o["hp"])
	datos["son"] = sonidos.size()
	c.actor = kael
	c._resolver_negra(kael, x[0], x[1], objs)
	_ok(kael.get("animando", false), "%s no empieza" % d["nombre"])


func _pestanas() -> Array:
	return c.menu._pestanas


func _filas() -> Array:
	return c.menu.filas.map(func(f): return f["item"])


func _lanzar(fam: String, nv: int, objetivo = null) -> void:
	c._menu_magia(c.PESTANA_NEGRA)
	c._menu_escuela(fam)
	c._elegir_negra(fam, nv)
	if objetivo != null:
		_ok(c.estado == "objetivo", "%s %d no pide objetivo" % [fam, nv])
		c._confirmar_objetivo(objetivo)


func _turno_a(kael: Dictionary) -> void:
	var slimes: Array = c.enemigos
	match paso:
		0:
			c._menu_magia(0)
			var tabs := _pestanas()
			var iconos: Array = tabs.map(func(p): return p.get("icono", p["texto"]))
			_ok("Negra" in iconos and "DÚO" in iconos and "I" in iconos, "pestañas: %s" % [iconos])
			var ancho := 4.0 * (tabs.size() - 1)
			for t in tabs:
				ancho += float(t["ancho"])
			_ok(ancho <= c.ANCHO_PESTANAS and tabs.all(func(t): return float(t["ancho"]) >= 56.0), "las pestañas no caben: %d px" % ancho)
			c._menu_magia(c.PESTANA_NEGRA)
			var vistas: Array = _filas().filter(func(i): return i.has("escuela")).map(func(i): return i["escuela"])
			_ok(_filas().size() == 4 and _filas()[3].get("pagina", false), "la lista de escuelas no va en páginas de 4")
			c._pagina_escuelas(1)
			vistas.append_array(_filas().filter(func(i): return i.has("escuela")).map(func(i): return i["escuela"]))
			_ok(vistas == MN.ESCUELAS, "lista de escuelas: %s" % [vistas])
			c._pagina_escuelas(0)
			c._menu_escuela("negra_rayo")
			_ok(c.estado == "magia_negra" and _filas().size() == 4 and _pestanas().size() == 6, "página de Rayo")
			_ok(_filas()[2]["derecha"].begins_with("◷") and not _filas()[0]["derecha"].begins_with("◷"), "el ◷ de la preparación")
			c._menu_escuela("negra_debilitamiento")
			_ok(_filas().size() == 4 and _filas()[3].get("pagina", false), "Debilitamiento (5) no va en dos páginas")
			c._menu_escuela("negra_debilitamiento", 1)
			_ok(_filas().map(func(i): return i["texto"]) == ["Maldición Menguante", "Herida Elemental", "‹ Antes"],
				"segunda página de Debilitamiento: %s" % [_filas().map(func(i): return i["texto"])])
			c._atras()
			_ok(c.estado == "magia" and _filas().size() == 4, "‹ no vuelve a la lista de escuelas")
			c._menu_escuela("negra_rayo")
			datos["pv"] = slimes.map(func(e): return e["hp"])
			datos["pm"] = kael["mp"]
			datos["son"] = sonidos.size()
			# todos a la vista: el segundo cerca del primero (salta antes a él)
			_lanzar("negra_rayo", 2, slimes[0])
			_ok(kael["mp"] == datos["pm"] - 13, "Rayo Encadenado no gasta 13 PM")
			paso = 1
		1:
			var bajan: Array = []
			for i in slimes.size():
				bajan.append(int(datos["pv"][i]) - int(slimes[i]["hp"]))
			_ok(bajan.all(func(x): return x > 0), "Rayo Encadenado no toca a los tres: %s" % [bajan])
			var nuevos: Array = sonidos.slice(int(datos["son"]))
			_ok(nuevos.count("golpe_critico") + nuevos.count("negra_rayo") == 1, "Rayo Encadenado suena %s" % [nuevos])
			for s in slimes:
				s["hp"] = s["hp_max"]
				s["defendiendo"] = false
			datos["pv"] = slimes.map(func(e): return e["hp"])
			datos["son"] = sonidos.size()
			datos["armonia"] = c.armonia
			datos["turnos"] = turnos_kael
			_lanzar("negra_fuego", 3)                      # Lluvia de Brasas: a todos, prepara
			_ok(kael.has("conjuro") and "conjuro" in A.estados_de(kael), "Lluvia de Brasas no prepara")
			datos["preparando"] = true
			paso = 2
		2:
			_ok(turnos_kael == int(datos["turnos"]) + 1, "abre el menú mientras prepara")
			_ok(not kael.has("conjuro"), "sigue preparando en su turno siguiente")
			var bajan: Array = []
			for i in slimes.size():
				bajan.append(int(datos["pv"][i]) - int(slimes[i]["hp"]))
			_ok(bajan.all(func(x): return x > 0), "Lluvia de Brasas no alcanza a todos: %s" % [bajan])
			_ok(slimes.all(func(s): return s["hp"] <= 0 or int(s.get("quemadura", 0)) > 0), "Lluvia de Brasas no quema")
			var nuevos: Array = sonidos.slice(int(datos["son"]))
			_ok(nuevos.count("embuir") + nuevos.count("negra_preparar") == 1, "preparar suena %s" % [nuevos])
			_ok(nuevos.count("brasa") + nuevos.count("negra_fuego") == 1, "Lluvia de Brasas suena %s" % [nuevos])
			_ok(c.armonia >= float(datos["armonia"]) + 0.149, "la Armonía no sube al soltarla")
			_ok(registros.any(func(t): return str(t).contains("suelta Lluvia de Brasas")), "no se ve que la suelta")
			for s in slimes:
				s["hp"] = s["hp_max"]
				s["quemadura"] = 0
			datos["pv"] = slimes.map(func(e): return e["hp"])
			datos["son"] = sonidos.size()
			var pm: int = kael["mp"]
			_lanzar("negra_fuego", 4)                      # Sol de Ceniza, y se lo rompen
			_ok(kael.has("conjuro") and kael["mp"] == pm - 38, "Sol de Ceniza no prepara o no gasta")
			c._quitar_pv(kael, ceili(kael["hp_max"] * 0.25))
			_ok(not kael.has("conjuro") and not "conjuro" in A.estados_de(kael), "un golpe fuerte no rompe el conjuro")
			var nuevos2: Array = sonidos.slice(int(datos["son"]))
			_ok(nuevos2.count("barrera_rota") + nuevos2.count("negra_conjuro_roto") == 1, "la rotura suena %s" % [nuevos2])
			kael["hp"] = kael["hp_max"]
			paso = 3
		3:
			var bajan: Array = []
			for i in slimes.size():
				bajan.append(int(datos["pv"][i]) - int(slimes[i]["hp"]))
			_ok(bajan.all(func(x): return x <= 6), "el Sol de Ceniza roto hizo daño: %s" % [bajan])   # (quemadura: 5)
			for s in slimes:
				s["hp"] = s["hp_max"]
				s["quemadura"] = 0
			datos["preso"] = slimes[1]
			datos["registros"] = registros.size()
			datos["turno_preso"] = turnos_kael
			_lanzar("negra_hielo", 3, slimes[1])           # Prisión de Hielo: prepara
			paso = 4
		4:
			var preso: Dictionary = datos["preso"]
			var visto: bool = registros.slice(int(datos["registros"])).any(func(t): return str(t).contains("prisión de hielo"))
			if visto and MN.turnos(preso, "prision") == 0 or turnos_kael > int(datos["turno_preso"]) + 8:
				_ok(datos.get("vio_prision", false) and datos.get("vio_nodo", false), "Prisión de Hielo no encierra o no se ve")
				_ok(visto, "el Slime en prisión no pierde su turno")
				_ok(MN.turnos(preso, "prision") == 0 and not preso.has("mn_prision_nodo"), "la prisión no acaba")
				paso = 6
			c._defender()
		_:
			for s in slimes:                               # acabar: un golpe a cada uno
				if s["hp"] > 1:
					s["hp"] = 1
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(_vivos()[0])
			paso = 99


func _turno_b(kael: Dictionary) -> void:
	var coloso: Dictionary = c.enemigos[0]
	match paso:
		0:
			var pv: int = coloso["hp"]
			_lanzar("negra_gravedad", 1, coloso)
			datos["pv"] = pv
			paso = 1
		1:
			_ok(int(datos["pv"]) == int(coloso["hp"]) and MN.turnos(coloso, "lento") == 0, "la Gravedad le hace algo al Coloso")
			c._menu_magia(c.PESTANA_NEGRA)
			c._menu_escuela("negra_hielo")
			c._elegir_negra("negra_hielo", 3)
			var info: String = c._info_objetivo(coloso, true)
			_ok(info.contains("Resiste: Hielo") and info.contains("Inmune: Prisión"), "panel: %s" % info)
			c._confirmar_objetivo(coloso)
			datos["pv"] = coloso["hp"]
			paso = 2
		2:
			_ok(MN.turnos(coloso, "prision") == 0, "el Coloso entra en prisión")
			var hielo: int = int(datos["pv"]) - int(coloso["hp"])
			_ok(hielo >= 0 and hielo < 20, "Prisión hace demasiado a quien resiste el Hielo: %d" % hielo)
			c._menu_magia(c.PESTANA_NEGRA)
			c._menu_escuela("negra_rayo")
			c._elegir_negra("negra_rayo", 1)
			_ok(c._info_objetivo(coloso, true).contains("Débil: Rayo"), "panel sin «Débil»")
			c._confirmar_objetivo(coloso)
			datos["pv"] = coloso["hp"]
			paso = 3
		3:
			_ok(int(datos["pv"]) - int(coloso["hp"]) > 0, "la Chispa no le hace nada")
			paso = 99
			_cerrar()


func _turno_c(kael: Dictionary) -> void:
	var gorthor: Dictionary = c.enemigos[0]
	match paso:
		0:
			_lanzar("negra_gravedad", 1, gorthor)
			paso = 1
		1:
			_ok(MN.turnos(gorthor, "lento") in [1, 2], "la lentitud de Gorthor no se acorta: %d" % MN.turnos(gorthor, "lento"))
			_ok(is_equal_approx(MN.mult_vel(gorthor), 0.6) or MN.turnos(gorthor, "lento") == 0, "no va lento")
			_lanzar("negra_sombras", 2)                      # Manto del Eclipse (prepara)
			paso = 2
		2:
			_ok(MN.turnos(gorthor, "atk_baja") > 0 and is_equal_approx(MN.mult_ataque(gorthor), 0.75), "Manto: Gorthor no pega menos")
			c._menu_magia(c.PESTANA_NEGRA)
			c._menu_escuela("negra_hielo")
			c._elegir_negra("negra_hielo", 3)
			_ok(c._info_objetivo(gorthor, true).contains("Inmune: Prisión"), "panel de Gorthor sin «Inmune: Prisión»")
			c._confirmar_objetivo(gorthor)
			paso = 3
		3:
			_ok(MN.turnos(gorthor, "prision") == 0, "Gorthor entra en prisión")
			paso = 99
			_cerrar()


func _turno_d(kael: Dictionary) -> void:
	c._menu_magia(0)
	var iconos: Array = _pestanas().map(func(p): return p.get("icono", p["texto"]))
	_ok(not "Negra" in iconos, "sin interruptor hay pestaña de magia negra: %s" % [iconos])
	_ok(MN.hechizos("Kael").is_empty(), "sin interruptor Kael sabe magia negra")
	paso = 99
	_cerrar()


func _terminar() -> void:
	for f in fallos:
		print("FALLO: ", f)
	if fallos.is_empty():
		for h in hechos:
			print("OK ", h)
		print("OK A: pestañas que caben, escuelas, Rayo Encadenado (3 golpes, 1 sonido), Lluvia de Brasas preparada, Sol de Ceniza roto y Prisión de Hielo")
		print("OK B: el Coloso inmune a la Gravedad y a la Prisión, resiste el Hielo, débil al Rayo; panel con «Inmune» y «Débil»")
		print("OK C: Gorthor resiste la lentitud, el Manto baja su golpe, inmune a la Prisión")
		print("OK D: sin interruptor, nada de magia negra")
		print("OK E: los 24 hechizos llegan al final, golpean a los suyos, ponen su estado y suenan una vez")
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
