extends Node
# Bramavidrio en el combate (V12, encargo del usuario del 11/11: «tres ataques completamente diferenciados»). El gusano
# colosal del Mar de Cristal: combate fijo «mc_bramavidrio» (grupo 13 de combate.gd), obligatorio. Modelo 3D de
# animaciones (enemigos/bramavidrio/bramavidrio_3d.gd); si falta, su foto 2D («bramavidrio2d») y los mismos ataques.
#
# Es un nodo hijo del combate (combate.gd lo crea al empezar, si hay un Bramavidrio): así sus esperas y sus efectos
# mueren con la escena. Lleva su IA, sus tres ataques, sus avisos en pantalla y sus efectos; combate.gd solo lo llama
# desde unos ganchos comentados («V12, Bramavidrio»). Con cualquier otro enemigo nada cambia.
#
# LOS TRES ATAQUES (el daño parte de su ataque, «atk», y de la furia de siempre por debajo del 30 %):
#   1. EMBESTIDA DEL ABISMO (básico, a uno; ×MULT_EMBESTIDA). Sin turno de aviso: la anticipación va en el clip. Se
#      retrae y fija sus ocelos en un héroe (marca roja sobre él y el cartel lo nombra), se estira y muerde abajo; arena
#      que salta a sus pies, golpe contundente y el alcanzado retrocede. Defender lo deja a la mitad; la Guardia de
#      Garon la para por el aliado.
#   2. FRACTURA DEL MAR DE CRISTAL (sísmico, a todos; ×MULT_FRACTURA). Un turno de aviso: se alza erguido y ruge (cartel
#      grande arriba, «⚠ Fractura» sobre su vida y el suelo que se resquebraja bajo los héroes). El turno siguiente cae a
#      lo largo junto a ellos: sacudida, ondas, grietas que brillan, placas de piedra que se alzan, polvo y esquirlas de
#      vidrio. Respuesta: DEFENDER (la mitad y no se tambalea) o la Barrera Rúnica. Quien no se defiende se TAMBALEA:
#      pierde TAMBALEO puntos de su barra de tiempo (nunca por debajo de 0; quien ya espera turno, no). No se puede
#      cortar: está fuera del alcance de las armas.
#   3. ALIENTO DEL DESIERTO ETERNO (gran ataque al grupo; ×MULT_ALIENTO). Un turno entero de preparación, y largo: abre la
#      boca y aspira arena (remolinos que van a su boca), la garganta se enciende, el cartel lo anuncia con lo que falta
#      para cortarlo y su barra de tiempo va al RITMO_ASPIRANDO. El turno siguiente expulsa un chorro de arena comprimida
#      contra los tres: nube de arena y empujón (las posiciones no cambian). Respuestas: DEFENDER (la mitad), Barrera
#      Rúnica, o CORTARLO: si el grupo le quita mientras aspira UMBRAL_CORTE de su vida máxima (un 20 % con tres héroes;
#      o con Quiebra, siempre) se atraganta, no lo suelta y pierde su turno siguiente (la interrupción de la V11).
#      Después de soltarlo jadea un turno.
#
# EQUILIBRIO (medido con pruebas/prueba_bramavidrio_combate.gd «medir», 11/11; informe combate_v12_bramavidrio.md):
#   1150 PV, ataque 34 y velocidad 11 en ENEMIGOS (nivel 10 del desierto; jefe: sube como mucho 2 niveles). Con uno o dos
#   héroes en el grupo, VIDA_POR_GRUPO de esa vida: es obligatorio y no se puede huir.
#
# IA (determinista, sin azar: se lee y se aprende):
#   Mientras le quede más de la mitad: dos embestidas y la Fractura (aviso y caída): E, E, ⚠F, F, E, E, ⚠F, F…
#   Con la mitad o menos («la arena se enfurece»): alterna el Aliento y la Fractura con una embestida entre medias:
#     E, ⚠A, A, (jadea), E, ⚠F, F, E, ⚠A, A…
#   Nunca encadena: tras soltar un especial, su turno siguiente es una embestida (o jadea); cada especial se avisa un
#   turno entero antes y no se suelta si desde el aviso no ha actuado ningún héroe (combate.gd, turnos_heroe): entonces
#   sigue preparándolo.
#
# Premio de la primera victoria (combate fijo «mc_bramavidrio» en «combates_ganados»; combate.gd _fin_combate):
# PREMIO_CANTIDAD Reliquias de vidrio (las placas que suelta de su lomo; sirven para el buscador de nivel 3). Propuesta.

const CLAVE := "bramavidrio"
const COMBATE := "mc_bramavidrio"
const GRUPO := 13
const MULT_EMBESTIDA := 1.35
const MULT_FRACTURA := 1.2
const MULT_ALIENTO := 1.9
const TAMBALEO := 25.0                  # puntos de la barra de tiempo (de 100) que pierde quien no se defiende
const RITMO_ASPIRANDO := 0.7             # mientras aspira el Aliento su barra de tiempo va al 70 %: más tiempo para responder
const VIDA_POR_GRUPO := {1: 0.5, 2: 0.7}  # su vida con uno o dos héroes en el grupo (con tres, la de ENEMIGOS)
# Parte de su vida máxima que corta el Aliento mientras aspira, según cuántos héroes en pie había al avisar (la V11 usa
# 0,25 con cualquier grupo; aquí la vida es mucho mayor). El número exacto se lee en el cartel y sobre su vida.
const UMBRAL_CORTE := {1: 0.1, 2: 0.15, 3: 0.2}
const UMBRAL_FURIA_ARENA := 0.5         # con esta parte de vida o menos, prepara también el Aliento
const NOMBRES := {"embestida": "Embestida del Abismo", "sismico": "Fractura del Mar de Cristal",
	"aliento": "Aliento del Desierto Eterno"}
const PREMIO := "Reliquia de vidrio"
const PREMIO_CANTIDAD := 2
# Colores (arena del Mar de Cristal, vidrio y la luz mineral de la garganta)
const C_ARENA := Color(0.93, 0.8, 0.58)
const C_ARENA_OSCURA := Color(0.62, 0.5, 0.36)
const C_VIDRIO := Color(0.72, 0.95, 1.0)
const C_GARGANTA := Color(1.0, 0.72, 0.32)
const C_AVISO := Color(1.0, 0.8, 0.2)
const C_PELIGRO := Color(1.0, 0.42, 0.3)

var c                                   # el combate (combate.gd)
var f: Dictionary = {}                  # el diccionario de Bramavidrio en el combate
var cartel: Control                     # el aviso grande arriba (Fractura y Aliento), mientras prepara
var cartel_titulo: Label
var cartel_ayuda: Label
var zona: Node2D                        # el suelo que se resquebraja bajo los héroes (aviso de la Fractura)
var succion: CPUParticles2D             # la arena que va a su boca (aviso del Aliento)
var brillo_garganta: Sprite2D
var marca: Node2D                       # la marca sobre el héroe que fija (Embestida)
var contador := {}                      # pruebas: ataques, avisos, impactos, cortes (prueba_bramavidrio_combate.gd)
var particulas_max := 0                 # pruebas y rendimiento: partículas vivas a la vez como mucho (CPU)


static func es(e) -> bool:
	return e is Dictionary and str(e.get("clave", "")) == CLAVE


func preparar(combate, e: Dictionary) -> void:
	c = combate
	f = e
	name = "Bramavidrio"
	# Con menos de tres héroes (alguno fuera del grupo activo), menos vida: es obligatorio y no se puede huir.
	var n: int = clampi(c.heroes.size(), 1, 3)
	if n < 3:
		f["hp_max"] = int(round(f["hp_max"] * VIDA_POR_GRUPO[n]))
		f["hp"] = mini(f["hp"], f["hp_max"])


# Al empezar (combate.gd _ready, junto a la entrada de las bestias): su emersión con la arena que revienta, el temblor y
# el rugido, y los sonidos de su derrota.
func al_entrar(p) -> void:
	if p == null:
		return
	if p.has_signal("rompe_arena"):
		p.rompe_arena.connect(func():
			c._sonar("gusano_temblor")
			_estallido_arena(_agujero(), 1.0)
			c._temblor(6.0), CONNECT_ONE_SHOT)
	if p.has_signal("caida"):
		p.caida.connect(func():
			c._sonar("gusano_temblor")
			_estallido_arena(_agujero() + Vector2(260, 40), 0.8)
			c._temblor(8.0), CONNECT_ONE_SHOT)
	get_tree().create_timer(0.9).timeout.connect(func(): if f["hp"] > 0: c._sonar("gusano_rugido"))


# ================================================================= su turno

func turno(vivos: Array, mult: float) -> void:
	if f.get("recupera", false):
		f["recupera"] = false
		var aturdido: bool = f.get("aturdido", false)
		f.erase("aturdido")
		c.registro.text = ("%s, aturdido, escupe la arena que tragó" if aturdido else "%s jadea: la garganta se le apaga") % f["nombre"]
		c._numero_flotante(f, "Aturdido" if aturdido else "Jadea", Color(0.8, 0.85, 0.75), 30)
		_contar("recupera")
		c._actualizar()
		await get_tree().create_timer(0.9).timeout
		return
	if f.get("cargando", false):
		if int(c.turnos_heroe) - int(f.get("aviso_turnos", 0)) < 1:   # nadie ha podido responder: sigue preparando
			c.registro.text = "%s sigue preparando su %s" % [f["nombre"], NOMBRES[f["especial"]]]
			_contar("sigue")
			await get_tree().create_timer(0.8).timeout
			return
		if f["especial"] == "sismico":
			await _fractura(vivos, mult)
		else:
			await _aliento(vivos, mult)
		return
	var que := decidir()
	if que == "embestida":
		await _embestida(vivos, mult)
	else:
		await _avisar(que, vivos)


# Qué hace en un turno sin nada preparado (ver la cabecera). No tira dados.
func decidir() -> String:
	if not f.get("arena_furiosa", false) and f["hp"] <= f["hp_max"] * UMBRAL_FURIA_ARENA:
		f["arena_furiosa"] = true
		c._numero_flotante(f, "¡La arena se enfurece!", C_PELIGRO, 32, Vector2(0, 60))
	if f.get("ultimo", "") != "":                     # acaba de soltar un especial: nunca dos seguidos
		f["ultimo"] = ""
		return "embestida"
	var normales: int = int(f.get("normales", 0))
	if f.get("arena_furiosa", false):
		if normales >= 1:
			return "sismico" if f.get("ultimo_especial", "") == "aliento" else "aliento"
	elif normales >= 2:
		return "sismico"
	return "embestida"


# ---------------------------------------------------------------- 1. Embestida del Abismo

func _embestida(vivos: Array, mult: float) -> void:
	var obj: Dictionary = c._elegir_objetivo("agresivo", vivos)
	c.registro.text = "%s se retrae y clava sus ocelos en %s" % [f["nombre"], obj["nombre"]]
	_marcar_objetivo(obj)
	obj = c._cubre(obj)                               # Garon puede ponerse delante
	f["ataque_brama"] = "embestida"
	_contar("embestida")
	await c._animar_golpe(f, obj, int(f["atk"] * MULT_EMBESTIDA * mult) + randi_range(-2, 3), "")
	f.erase("ataque_brama")
	_quitar_marca()
	f["normales"] = int(f.get("normales", 0)) + 1


# combate.gd _animar_golpe: el golpe físico de Bramavidrio (la embestida). «impacto» resuelve el daño (una vez); aquí,
# lo que pasa a la vez: la arena a los pies, el temblor, el empujón y su golpe sordo.
func animar_golpe(objetivo: Dictionary, impacto: Callable) -> void:
	var p = c._p3d(f)
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		_contar("impacto_embestida")
		impacto.call()
		c._sonar("gusano_temblor")                  # el peso del golpe en la arena (con el golpe de siempre)
		var pie: Vector2 = c._suelo_de(objetivo)
		_estallido_arena(pie, 0.85)
		_polvo(pie + Vector2(0, -30), 30)
		c._onda(pie, Color(C_ARENA, 0.8), 20.0, 200.0, 0.45, 8.0)
		_empujar(objetivo, 46.0, 0.42)
		c._temblor(8.0)
	if p == null:                                    # el respaldo 2D: el empujón de su foto
		await c._anim_fisico_imagen(f, objetivo, golpe)
	else:
		f["animando"] = true
		await p.atacar("embestida", golpe)
		f["animando"] = false
	golpe.call()                                      # sin clip (o cortado): el golpe igualmente, una vez


# ---------------------------------------------------------------- avisos (Fractura y Aliento)

func _avisar(que: String, _vivos: Array) -> void:
	var p = c._p3d(f)
	f["cargando"] = true
	f["especial"] = que
	f["carga_recibido"] = 0
	f["aviso_turnos"] = int(c.turnos_heroe)
	var en_pie: int = clampi(c.heroes.filter(func(h): return h["hp"] > 0).size(), 1, 3)
	f["umbral_corte"] = ceili(f["hp_max"] * UMBRAL_CORTE[en_pie])
	if que == "aliento" and not f.has("vel_normal"):  # aspira largo: su barra de tiempo va más lenta hasta soltarlo
		f["vel_normal"] = f["vel"]
		f["vel"] = f["vel"] * RITMO_ASPIRANDO
	_contar("aviso_" + que)
	c._marcar_aviso(f, true)
	Sonido.efecto("carga_jefe")
	if que == "sismico":
		c.registro.text = "%s se alza sobre la arena: ¡va a caer sobre todos!" % f["nombre"]
		_mostrar_cartel("⚠ " + NOMBRES["sismico"], "Defendeos: a la mitad y sin tambalearos")
		_zona_impacto(true)
		_tenir_fondo(Color(0.86, 0.74, 0.62))
		if p != null and p.has_signal("rugido_pico"):
			p.rugido_pico.connect(func():
				c._sonar("gusano_rugido")
				c._temblor(5.0), CONNECT_ONE_SHOT)
		else:
			c._sonar("gusano_rugido")
	else:
		c.registro.text = "%s abre las fauces y aspira el desierto: ¡va a soplar contra todos!" % f["nombre"]
		_mostrar_cartel("⚠ " + NOMBRES["aliento"], "")
		_tenir_fondo(Color(0.95, 0.82, 0.62))
		if p != null and p.has_signal("succion"):
			p.succion.connect(func():
				c._sonar("gusano_temblor")
				_empezar_succion(), CONNECT_ONE_SHOT)
		else:
			c._sonar("gusano_temblor")
			_empezar_succion()
	c._numero_flotante(f, "⚠ ¡Fractura!" if que == "sismico" else "⚠ ¡Aliento!", C_AVISO, 34)
	c._actualizar()
	if p != null and p.has_method("avisar"):
		await p.avisar(que)
		await get_tree().create_timer(0.35).timeout
	else:
		await get_tree().create_timer(1.1).timeout


# ---------------------------------------------------------------- 2. Fractura del Mar de Cristal

func _fractura(vivos: Array, mult: float) -> void:
	var p = c._p3d(f)
	_terminar_aviso()
	c.registro.text = "¡%s se desploma sobre el Mar de Cristal!" % f["nombre"]
	_contar("fractura")
	var centro := _centro_grupo(vivos) + Vector2(-60, 10)
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		_contar("impacto_fractura")
		_a_todos(vivos, int(f["atk"] * MULT_FRACTURA * mult), true)
		Sonido.golpe(true)                           # la caída: un golpe para todos, una vez
		c._sonar("gusano_temblor")
		_efecto_fractura(_donde_cae(centro))
		c._temblor(12.0)
	f["animando"] = true
	if p != null:
		await p.atacar("sismico", golpe)
	else:
		await get_tree().create_timer(0.5).timeout
	golpe.call()
	f["animando"] = false
	f["normales"] = 0
	f["ultimo"] = "sismico"
	f["ultimo_especial"] = "sismico"
	await get_tree().create_timer(0.5).timeout


# ---------------------------------------------------------------- 3. Aliento del Desierto Eterno

func _aliento(vivos: Array, mult: float) -> void:
	var p = c._p3d(f)
	_terminar_aviso(false)                           # la succión sigue hasta que sale el chorro
	c.registro.text = "¡%s expulsa el %s!" % [f["nombre"], NOMBRES["aliento"]]
	_contar("aliento")
	var hecho := [false]
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		_contar("impacto_aliento")
		_parar_succion()
		c._sonar("gusano_rugido")                   # el bramido del chorro
		_chorro(_boca(), _centro_grupo(vivos) + Vector2(0, -150))   # a la altura del pecho
		_a_todos(vivos, int(f["atk"] * MULT_ALIENTO * mult), false)
		Sonido.golpe(true)                           # el chorro alcanza a todos: un golpe, una vez
		c._fogonazo(C_ARENA, 0.28, 0.9)
		c._temblor(9.0)
	f["animando"] = true
	if p != null:
		await p.atacar("aliento", golpe)
	else:
		await get_tree().create_timer(0.6).timeout
	golpe.call()
	f["animando"] = false
	f["recupera"] = true                             # jadea un turno
	f["normales"] = 0
	f["ultimo"] = "aliento"
	f["ultimo_especial"] = "aliento"
	await get_tree().create_timer(0.4).timeout


# combate.gd _vigilar_carga: un golpe que recibe mientras prepara. Solo el Aliento se corta (la Fractura no).
func vigilar(d: int) -> void:
	if not f.get("cargando", false) or f.get("especial", "") != "aliento" or f["hp"] <= 0:
		return
	if c.golpe_ruptura:                               # Quiebra (Kael + Garon): corta siempre
		cortar("¡Quiebra!", "¡Kael y Garon le cierran las fauces: el Aliento se corta!")
		return
	f["carga_recibido"] = int(f.get("carga_recibido", 0)) + d
	if f["carga_recibido"] >= umbral_corte():
		cortar("¡Interrumpido!", "¡%s se atraganta con su propia arena: el Aliento se corta!" % f["nombre"])
	else:
		_poner_ayuda()


func umbral_corte() -> int:
	return umbral_de(f)


# PV que cortan el Aliento: los que se fijaron al avisar (según los héroes en pie entonces) o, si no, los de tres.
static func umbral_de(e: Dictionary) -> int:
	return int(e.get("umbral_corte", ceili(e["hp_max"] * UMBRAL_CORTE[3])))


func cortar(texto_cartel: String, texto: String) -> void:
	f["cargando"] = false
	f["recupera"] = true
	f["aturdido"] = true
	f.erase("carga_recibido")
	f["normales"] = 0
	f["ultimo"] = ""
	f["ultimo_especial"] = "aliento"
	_contar("cortado")
	_terminar_aviso()
	var p = c._p3d(f)
	if p != null:
		p.reposo()                                    # cierra las fauces (deja el aviso)
		p.recibir_golpe()
	_estallido_arena(_boca(), 0.6)
	c._sonar(c.Artes.SONIDO_ESTADO["rota"])
	c._numero_flotante(f, texto_cartel, Color(1.0, 0.92, 0.45), 38, Vector2(0, -60))
	c.registro.text = texto
	c._temblor(4.0)
	c._actualizar()


# ---------------------------------------------------------------- daño a todos

# Cada héroe en pie recibe «dano» (con su defensa, Defender a la mitad, la Guardia de Garon y las corazas, como los demás
# golpes a todos). «tambalea»: quien no se defendía pierde TAMBALEO de su barra de tiempo.
func _a_todos(vivos: Array, dano: int, tambalea: bool) -> void:
	var primero := true
	for h0 in vivos:
		if h0["hp"] <= 0:
			continue
		var h: Dictionary = c._cubre(h0, false)
		if h["hp"] <= 0:
			continue
		var d: int = maxi(1, dano + randi_range(-2, 3) - int(h.get("def", 0) / 2.0))
		var defiende: bool = h.get("defendiendo", false)
		if defiende:
			d = maxi(1, int(d * 0.5))
		var real: int = c._quitar_pv(h, d)
		c._golpe_visual(h, real, "")
		if primero or h["hp"] <= 0:                   # una voz de dolor (y la de quien cae), no un coro
			Sonido.recibe(h)
		primero = false
		_empujar(h, 30.0 if tambalea else 58.0, 0.5)
		if tambalea and not defiende and h["hp"] > 0 and not c.cola.has(h) and h["atb"] < c.ATB_MAX:
			h["atb"] = maxf(0.0, h["atb"] - TAMBALEO)
			c._numero_flotante(h, "Tambalea", Color(0.95, 0.75, 0.5), 26, Vector2(-20, 40))
			_contar("tambaleo")
		if not tambalea:
			_polvo(c._centro(h) + Vector2(0, 30), 34)
			_estallido_arena(c._suelo_de(h), 0.45)
	c._actualizar()


# ================================================================= lo que se lee

# Lo que se lee sobre su vida (combate.gd _actualizar).
static func estados(e: Dictionary) -> PackedStringArray:
	var r := PackedStringArray()
	if e.get("cargando", false):
		if e.get("especial", "") == "aliento":
			r.append("⚠ Aliento: córtalo %d/%d" % [int(e.get("carga_recibido", 0)), umbral_de(e)])
		else:
			r.append("⚠ Fractura: defendeos")
	elif e.get("aturdido", false):
		r.append("Aturdido")
	return r


# Lo que dice la lista de objetivos (combate.gd _info_objetivo).
static func info(e: Dictionary) -> Array:
	if not e.get("cargando", false):
		return []
	if e.get("especial", "") == "aliento":
		return ["⚠ Aliento: quítale %d PV y lo cortas" % maxi(0, umbral_de(e) - int(e.get("carga_recibido", 0)))]
	return ["⚠ Fractura: no se corta, defendeos"]


# Premio de la primera victoria (combate.gd _fin_combate). Devuelve el aviso.
static func dar_premio() -> String:
	if not ResourceLoader.exists("res://inventario.gd"):
		return ""
	load("res://inventario.gd").agregar_objeto(PREMIO, PREMIO_CANTIDAD)
	return "Bramavidrio suelta placas de su lomo: +%d %s" % [PREMIO_CANTIDAD, PREMIO]


# ================================================================= avisos en pantalla

# El cartel grande del aviso, arriba a la derecha, en el cielo libre (ni tapa al gusano ni el menú; legible en el móvil).
# Se queda hasta que suelta o se corta.
func _mostrar_cartel(titulo: String, ayuda: String) -> void:
	_quitar_cartel()
	cartel = Control.new()
	cartel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartel.position = Vector2(700, 72)
	cartel.size = Vector2(560, 100)
	var fondo := ColorRect.new()
	fondo.color = Color(0.08, 0.05, 0.03, 0.62)
	fondo.size = cartel.size
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartel.add_child(fondo)
	var linea := ColorRect.new()
	linea.color = C_PELIGRO
	linea.size = Vector2(cartel.size.x, 3)
	linea.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cartel.add_child(linea)
	cartel_titulo = c._etiqueta(titulo, 34, C_AVISO, c.menu.f_nombre)
	cartel_titulo.add_theme_constant_override("outline_size", 8)
	cartel_titulo.position = Vector2(0, 4)
	cartel_titulo.size = Vector2(cartel.size.x, 46)
	cartel_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cartel.add_child(cartel_titulo)
	cartel_ayuda = c._etiqueta(ayuda, 23, Color(1.0, 0.95, 0.85))
	cartel_ayuda.add_theme_constant_override("outline_size", 6)
	cartel_ayuda.position = Vector2(0, 54)
	cartel_ayuda.size = Vector2(cartel.size.x, 40)
	cartel_ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cartel.add_child(cartel_ayuda)
	c.capa.add_child(cartel)
	if ayuda == "":
		_poner_ayuda()
	cartel.modulate.a = 0.0
	var t := cartel.create_tween()
	t.tween_property(cartel, "modulate:a", 1.0, 0.2)
	var pulso := cartel_titulo.create_tween().set_loops()   # el título late mientras prepara
	pulso.tween_property(cartel_titulo, "modulate", Color(1.25, 1.1, 0.9), 0.45).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(cartel_titulo, "modulate", Color(1, 1, 1), 0.45).set_trans(Tween.TRANS_SINE)


func _poner_ayuda() -> void:
	if cartel_ayuda == null or not is_instance_valid(cartel_ayuda) or f.get("especial", "") != "aliento":
		return
	var falta: int = maxi(0, umbral_corte() - int(f.get("carga_recibido", 0)))
	cartel_ayuda.text = "Defendeos, o quitadle %d PV más para cortarlo" % falta


func _quitar_cartel() -> void:
	if cartel != null and is_instance_valid(cartel):
		var viejo := cartel
		var t := viejo.create_tween()
		t.tween_property(viejo, "modulate:a", 0.0, 0.25)
		t.tween_callback(viejo.queue_free)
	cartel = null
	cartel_titulo = null
	cartel_ayuda = null


func _terminar_aviso(parar_succion := true) -> void:
	if f.has("vel_normal"):                           # vuelve a su ritmo de siempre (Aliento soltado o cortado)
		f["vel"] = f["vel_normal"]
		f.erase("vel_normal")
	f["cargando"] = false
	c._marcar_aviso(f, false)
	_quitar_cartel()
	_zona_impacto(false)
	_tenir_fondo(Color(1, 1, 1))
	if parar_succion:
		_parar_succion()


# El fondo se apaga un poco mientras prepara (impone sin tapar nada) y vuelve después.
func _tenir_fondo(color: Color) -> void:
	if c.fondo_nodo == null or not is_instance_valid(c.fondo_nodo):
		return
	if not f.has("fondo0"):
		f["fondo0"] = c.fondo_nodo.modulate
	var meta: Color = f["fondo0"] * color
	c.fondo_nodo.create_tween().tween_property(c.fondo_nodo, "modulate", meta, 0.6)


# La marca roja sobre el héroe que fija (la Embestida): un anillo que se cierra y «⚠» encima.
func _marcar_objetivo(h: Dictionary) -> void:
	_quitar_marca()
	marca = Node2D.new()
	marca.position = c._suelo_de(h)
	marca.z_index = -1
	var est := {"t": 0.0}
	marca.draw.connect(func():
		var r := lerpf(150.0, 70.0, est["t"])
		marca.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.34))
		marca.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(C_PELIGRO, 0.85), 6.0)
		marca.draw_arc(Vector2.ZERO, r * 0.6, 0, TAU, 40, Color(C_PELIGRO, 0.5), 3.0))
	c.escena.add_child(marca)
	var t := marca.create_tween()
	t.tween_method(func(v: float):
		est["t"] = v
		marca.queue_redraw(), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	c._numero_flotante(h, "⚠", C_PELIGRO, 44, Vector2(10, -40))


func _quitar_marca() -> void:
	if marca != null and is_instance_valid(marca):
		marca.queue_free()
	marca = null


# El suelo bajo los héroes se resquebraja mientras está erguido (aviso de la Fractura): grietas finas que laten.
func _zona_impacto(si: bool) -> void:
	if zona != null and is_instance_valid(zona):
		zona.queue_free()
	zona = null
	if not si:
		return
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	if vivos.is_empty():
		return
	zona = Node2D.new()
	zona.position = _centro_grupo(vivos) + Vector2(-60, 10)
	zona.z_index = -1
	var rng := RandomNumberGenerator.new()
	rng.seed = 13                                      # siempre las mismas (no toca el azar del combate)
	var lineas: Array = []
	for i in 9:
		lineas.append(_grieta(rng, Vector2.ZERO, TAU * i / 9.0 + rng.randf_range(-0.2, 0.2), rng.randf_range(160, 300)))
	zona.draw.connect(func():
		for l in lineas:
			zona.draw_polyline(l, Color(0.2, 0.12, 0.06, 0.8), 5.0)
			zona.draw_polyline(l, Color(C_PELIGRO, 0.95), 2.4))
	c.escena.add_child(zona)
	var t := zona.create_tween().set_loops()
	t.tween_property(zona, "modulate:a", 0.45, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(zona, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)


# ================================================================= efectos

# Partículas de arena (no aditivas: la arena no brilla), cuántas según la calidad del combate (móvil: 0,4).
func _arena(pos: Vector2, color: Color, cantidad: int, vida: float, vel: Vector2, dir: Vector2, apertura: float,
		gravedad: Vector2, escala: float, radio := 30.0, continuo := 0.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = c.glow_tex
	p.position = pos
	p.amount = maxi(4, int(cantidad * c.calidad))
	p.lifetime = vida
	p.one_shot = continuo <= 0.0                       # «continuo»: segundos que emite sin parar (el chorro)
	p.explosiveness = 0.85 if continuo <= 0.0 else 0.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radio
	p.direction = dir
	p.spread = apertura
	p.gravity = gravedad
	p.initial_velocity_min = vel.x
	p.initial_velocity_max = vel.y
	p.scale_amount_min = escala * 0.5
	p.scale_amount_max = escala
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	g.colors = PackedColorArray([Color(color, 0.0), Color(color, 0.95), Color(color, 0.0)])
	p.color_ramp = g
	c.escena.add_child(p)
	p.emitting = true
	_contar_particulas(p.amount)
	if continuo > 0.0:
		get_tree().create_timer(continuo).timeout.connect(func():
			if is_instance_valid(p):
				p.emitting = false)
	get_tree().create_timer(continuo + vida + 0.5).timeout.connect(p.queue_free)
	return p


# La arena que salta (golpe, emersión, caída): un abanico hacia arriba y un poco de polvo.
func _estallido_arena(pos: Vector2, fuerza: float) -> void:
	_arena(pos, C_ARENA_OSCURA, int(50 * fuerza), 0.9, Vector2(220, 560) * fuerza, Vector2(0, -1), 60.0, Vector2(0, 1000),
		0.13, 40.0 * fuerza)
	_arena(pos, Color(1.0, 0.92, 0.75), int(30 * fuerza), 0.8, Vector2(160, 420) * fuerza, Vector2(0, -1), 75.0,
		Vector2(0, 900), 0.08, 30.0 * fuerza)
	_arena(pos + Vector2(0, -20), C_ARENA, int(18 * fuerza), 1.3, Vector2(40, 160) * fuerza, Vector2(0, -1), 100.0,
		Vector2(0, 60), 0.32, 70.0 * fuerza)


# La Fractura: grietas que brillan y se apagan, placas de piedra que se alzan y se hunden, polvo, esquirlas de vidrio y
# dos ondas. Geometría 2D temporal (nada del terreno cambia). En el móvil, menos placas y partículas.
func _efecto_fractura(centro: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1302                                    # no toca el azar del combate
	var grietas := Node2D.new()
	grietas.position = centro
	grietas.z_index = 0                                # tras el cuerpo caído en el árbol (encima) y bajo el menú
	var lineas: Array = []
	for i in 11:
		lineas.append(_grieta(rng, Vector2.ZERO, TAU * i / 11.0 + rng.randf_range(-0.15, 0.15), rng.randf_range(220, 420)))
	var est := {"k": 0.0}
	grietas.draw.connect(func():
		for l in lineas:
			var n: int = maxi(2, int(ceil(l.size() * est["k"])))
			var parte: PackedVector2Array = l.slice(0, n)
			grietas.draw_polyline(parte, Color(0.14, 0.09, 0.05, 0.9), 7.0)
			grietas.draw_polyline(parte, Color(1.0, 0.86, 0.55, 0.95), 2.5))
	c.escena.add_child(grietas)
	var t := grietas.create_tween()
	t.tween_method(func(v: float):
		est["k"] = v
		grietas.queue_redraw(), 0.0, 1.0, 0.16)
	t.tween_interval(0.9)
	t.tween_property(grietas, "modulate:a", 0.0, 0.8)
	t.tween_callback(grietas.queue_free)
	var placas: int = 4 if c.movil else 7
	for i in placas:
		var ang := TAU * i / placas + rng.randf_range(-0.3, 0.3)
		var r := rng.randf_range(150, 330)
		_placa(centro + Vector2(cos(ang) * r, sin(ang) * r * 0.34), rng.randf_range(38, 70), rng.randf_range(60, 120),
			rng.randf_range(-14, 14), 0.04 * i)
	c._onda(centro, Color(1.0, 0.88, 0.62, 0.9), 30.0, 480.0, 0.7, 12.0)
	get_tree().create_timer(0.14).timeout.connect(func(): c._onda(centro, Color(C_ARENA, 0.7), 20.0, 330.0, 0.6, 8.0))
	_arena(centro, C_ARENA, 60, 1.2, Vector2(200, 560), Vector2(0, -1), 80.0, Vector2(0, 950), 0.1, 160.0)
	_polvo(centro + Vector2(0, -20), 50)
	c._particulas(centro + Vector2(0, -30), Color(C_VIDRIO, 1.0), Color(0.5, 0.85, 1.0, 0.0), 30, 1.0, Vector2(260, 620),
		120.0, Vector2(0, -1), 60.0, Vector2(0, 1100), 0.05)
	_contar_particulas(0)                              # el humo y las esquirlas son del combate: se cuentan vivos


# Una placa de piedra que se alza del suelo (pivote en su base), se inclina y se vuelve a hundir.
func _placa(pos: Vector2, ancho: float, alto: float, inclina: float, retraso: float) -> void:
	var n := Node2D.new()
	n.position = pos
	n.z_index = 0                                      # (sobre el cuerpo caído y bajo el menú, que va después)
	n.scale = Vector2(1.0, 0.0)
	var cara := Polygon2D.new()
	cara.polygon = PackedVector2Array([Vector2(-ancho * 0.5, 0), Vector2(-ancho * 0.42, -alto * 0.92),
		Vector2(ancho * 0.05, -alto), Vector2(ancho * 0.5, -alto * 0.8), Vector2(ancho * 0.48, 0)])
	cara.color = Color(0.66, 0.58, 0.47)
	n.add_child(cara)
	var lado := Polygon2D.new()                       # el canto en sombra, para que se lea el volumen
	lado.polygon = PackedVector2Array([Vector2(ancho * 0.48, 0), Vector2(ancho * 0.5, -alto * 0.8),
		Vector2(ancho * 0.62, -alto * 0.7), Vector2(ancho * 0.6, 4)])
	lado.color = Color(0.4, 0.34, 0.27)
	n.add_child(lado)
	var filo := Line2D.new()                          # un filo de vidrio en lo alto
	filo.points = PackedVector2Array([Vector2(-ancho * 0.42, -alto * 0.92), Vector2(ancho * 0.05, -alto),
		Vector2(ancho * 0.5, -alto * 0.8)])
	filo.width = 3.0
	filo.default_color = Color(C_VIDRIO, 0.9)
	n.add_child(filo)
	c.escena.add_child(n)
	var t := n.create_tween()
	t.tween_interval(retraso)
	t.tween_property(n, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(n, "rotation_degrees", inclina, 0.16)
	t.tween_interval(0.75)
	t.tween_property(n, "scale", Vector2(1.0, 0.0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(n, "modulate:a", 0.0, 0.5)
	t.tween_callback(n.queue_free)


# Una grieta quebrada desde «desde» hacia «ang», aplastada como el suelo (y × 0,34).
func _grieta(rng: RandomNumberGenerator, desde: Vector2, ang: float, largo: float) -> PackedVector2Array:
	var pts := PackedVector2Array([desde])
	var paso := largo / 6.0
	var p := desde
	for i in 6:
		var a := ang + rng.randf_range(-0.45, 0.45)
		p += Vector2(cos(a), sin(a) * 0.34) * paso
		pts.append(p)
	return pts


# El Aliento, mientras aspira: arena que gira y entra en su boca, y la garganta que se enciende.
func _empezar_succion() -> void:
	_parar_succion()
	if f["hp"] <= 0 or not f.get("cargando", false):
		return
	var boca := _boca()
	succion = CPUParticles2D.new()
	succion.texture = c.glow_tex
	succion.position = boca
	succion.amount = maxi(10, int(90 * c.calidad))
	succion.lifetime = 0.9
	succion.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	succion.emission_sphere_radius = 300.0
	succion.direction = Vector2(-1, 0)
	succion.spread = 180.0
	succion.initial_velocity_min = 0.0
	succion.initial_velocity_max = 40.0
	succion.gravity = Vector2.ZERO
	succion.radial_accel_min = -820.0
	succion.radial_accel_max = -620.0
	succion.tangential_accel_min = 140.0
	succion.tangential_accel_max = 260.0
	succion.scale_amount_min = 0.05
	succion.scale_amount_max = 0.12
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.8, 1.0])
	g.colors = PackedColorArray([Color(C_ARENA, 0.0), Color(C_ARENA, 0.9), Color(C_GARGANTA, 0.7), Color(C_GARGANTA, 0.0)])
	succion.color_ramp = g
	c.escena.add_child(succion)
	succion.emitting = true
	_contar_particulas(succion.amount)
	brillo_garganta = c._brillo(C_GARGANTA)
	brillo_garganta.position = boca
	brillo_garganta.scale = Vector2.ONE * 0.3
	c.escena.add_child(brillo_garganta)
	var t := brillo_garganta.create_tween().set_loops()
	t.tween_property(brillo_garganta, "scale", Vector2.ONE * 0.75, 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(brillo_garganta, "scale", Vector2.ONE * 0.5, 0.4).set_trans(Tween.TRANS_SINE)


func _parar_succion() -> void:
	if succion != null and is_instance_valid(succion):
		succion.emitting = false
		get_tree().create_timer(1.0).timeout.connect(succion.queue_free)
	succion = null
	if brillo_garganta != null and is_instance_valid(brillo_garganta):
		var b := brillo_garganta
		var t := b.create_tween()
		t.tween_property(b, "modulate:a", 0.0, 0.3)
		t.tween_callback(b.queue_free)
	brillo_garganta = null


# El chorro de arena comprimida: de la boca, a la altura del pecho de los héroes, y sigue más allá (los envuelve). Una
# banda de arena con los bordes difuminados que se abre, su núcleo claro y la arena que vuela dentro.
func _chorro(desde: Vector2, hasta: Vector2) -> void:
	var dir := (hasta - desde).normalized()
	var fin := hasta + dir * 320.0
	var borde := GradientTexture2D.new()                 # bordes suaves: transparente, arena, transparente (a lo ancho)
	var gb := Gradient.new()
	gb.offsets = PackedFloat32Array([0.0, 0.3, 0.5, 0.7, 1.0])
	gb.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
	borde.gradient = gb
	borde.fill_from = Vector2(0, 0)
	borde.fill_to = Vector2(0, 1)
	borde.width = 4
	borde.height = 64
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, 0.25))
	curva.add_point(Vector2(0.55, 0.85))
	curva.add_point(Vector2(1.0, 1.0))
	var banda := Line2D.new()
	banda.width = 340.0
	banda.width_curve = curva
	banda.texture = borde
	banda.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.76, 0.42, 0.95), Color(0.8, 0.6, 0.38, 0.92), Color(0.62, 0.47, 0.3, 0.0)])
	banda.gradient = g
	banda.z_index = 0                                  # (z 0: el menú y la vida, que van después, quedan encima)
	var nucleo := Line2D.new()
	nucleo.width = 96.0
	nucleo.width_curve = curva
	nucleo.texture = borde
	nucleo.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	var gn := Gradient.new()
	gn.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	gn.colors = PackedColorArray([Color(1.0, 0.95, 0.8, 0.9), Color(1.0, 0.9, 0.7, 0.55), Color(1.0, 0.9, 0.7, 0.0)])
	nucleo.gradient = gn
	nucleo.material = c.mat_aditivo
	nucleo.z_index = 0
	for l in [banda, nucleo]:
		l.points = PackedVector2Array([desde, desde, desde])
		c.escena.add_child(l)
	var t := banda.create_tween()
	t.tween_method(func(v: float):
		var punta := desde.lerp(fin, v)
		var pts := PackedVector2Array([desde, desde.lerp(punta, 0.5), punta])
		banda.points = pts
		nucleo.points = pts, 0.0, 1.0, 0.14)
	t.tween_interval(0.55)
	t.tween_property(banda, "modulate:a", 0.0, 0.4)
	t.parallel().tween_property(nucleo, "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		banda.queue_free()
		nucleo.queue_free())
	_arena(desde, C_ARENA, 80, 0.6, Vector2(1100, 1600), dir, 9.0, Vector2.ZERO, 0.12, 24.0, 0.7)
	_arena(desde, C_ARENA_OSCURA, 30, 0.7, Vector2(700, 1100), dir, 16.0, Vector2(0, 120), 0.2, 30.0, 0.6)


# Empuja visualmente a un héroe (solo su dibujo: su sitio y sus controles no cambian) y lo devuelve.
func _empujar(h: Dictionary, dist: float, dur: float) -> void:
	if not h.has("cuerpo") or h["hp"] <= 0:
		return
	var cuerpo: Node2D = h["cuerpo"]
	if not h.has("cuerpo_pos0"):
		h["cuerpo_pos0"] = cuerpo.position
	var p0: Vector2 = h["cuerpo_pos0"]
	var t := cuerpo.create_tween()
	t.tween_property(cuerpo, "position", p0 + Vector2(dist, 0), dur * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(cuerpo, "position", p0, dur * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ================================================================= puntos de la escena

func _boca() -> Vector2:
	var p = c._p3d(f)
	if p == null or not f.has("cam3d") or not p.has_method("boca"):
		return c._centro(f) + Vector2(80, -40)
	var spr: Sprite2D = f["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(f["cam3d"].unproject_position(p.boca())))


func _agujero() -> Vector2:
	var p = c._p3d(f)
	if p == null or not f.has("cam3d"):
		return c._suelo_de(f)
	var spr: Sprite2D = f["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(f["cam3d"].unproject_position(p.global_position)))


# Dónde cae la cabeza en la Fractura (el hocico, en el instante del impacto): entre ese punto y los héroes rompe el suelo.
# Sin modelo, «si_no».
func _donde_cae(si_no: Vector2) -> Vector2:
	var p = c._p3d(f)
	if p == null or not f.has("cam3d") or not p.has_method("cabeza"):
		return si_no
	return _en_escena(p.cabeza()).lerp(si_no, 0.75)


# Un punto del mundo 3D del gusano, en la escena del combate (su ventana 3D se dibuja como un sprite).
func _en_escena(punto: Vector3) -> Vector2:
	var spr: Sprite2D = f["partes"]["sprite"]
	return c.escena.to_local(spr.to_global(f["cam3d"].unproject_position(punto)))


func _centro_grupo(vivos: Array) -> Vector2:
	var s := Vector2.ZERO
	var n := 0
	for h in vivos:
		if h["hp"] > 0:
			s += c._suelo_de(h)
			n += 1
	return s / n if n > 0 else c._suelo_de(f) + Vector2(400, 0)


# ================================================================= limpieza y cuentas

func _process(_delta: float) -> void:
	if c == null or f.is_empty():
		return
	if (f["hp"] <= 0 or c.estado == "fin") and (cartel != null or zona != null or succion != null or marca != null):
		_terminar_aviso()                              # cae (o acaba el combate) a medias: fuera avisos y succión
		_quitar_marca()


func _contar(que: String) -> void:
	contador[que] = int(contador.get(que, 0)) + 1


func _contar_particulas(n: int) -> void:
	var vivas := 0
	for p in c.escena.get_children():
		if p is CPUParticles2D and p.emitting:
			vivas += p.amount
	particulas_max = maxi(particulas_max, vivas + n)


# Una nube de polvo de arena (el humo del combate, sin brillo), con menos partículas en el móvil (calidad 0,4).
func _polvo(pos: Vector2, cantidad: int) -> void:
	c._humo(pos, C_ARENA, maxi(8, int(cantidad * c.calidad)))
