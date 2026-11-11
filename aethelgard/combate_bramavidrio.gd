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
#
# V12, Bramavidrio v2 (11/11, encargo del usuario: más espectáculo en los tres ataques; informe
# docs/memory/agents/combate_v12_bramavidrio2_efectos.md). Solo efectos 2D temporales sobre la capa del combate y el
# orden de dibujo: ni daños, ni fórmulas, ni IA, ni turnos cambian. Sirven con las dos versiones del modelo (la v2 da
# además las señales placas_suelo y fin_succion; con la v1, los mismos instantes del clip).
#   Embestida: al recogerse (anticipacion, 0,2 s) la arena le resbala del cuerpo y el suelo retumba; al fijar (0,55) un
#     destello en su cabeza; al lanzarse (0,8) una estela hacia el objetivo y se dibuja delante de los héroes que quedan
#     detrás de su cabeza; en el impacto, golpe de arena (abanico, terrones, polvo y onda) y una sacudida con peso.
#   Fractura: al caer (caida, 2,1) su sombra crece donde va a dar; en el impacto (placas_suelo, 2,5333) sacudida pesada
#     con réplica, grietas, placas que se alzan, nube de arena a ras de suelo bajo los héroes, esquirlas y arena que les
#     cae encima; con placas_asientan (3,1) las placas se hunden y el polvo se posa; con placas_fin (3,65) se acaba.
#   Aliento: mientras aspira, arena que sube del suelo (bajo los héroes) a su boca y polvo que se levanta; los héroes se
#     inclinan hacia él; para con fin_succion (1,7). Al soltar (1,85) un chorro de arena opaco que BARRE a los tres hasta
#     fin_descarga (2,6): a cada uno lo arrastra al pasar y le cae arena encima.
#   Derrota: se retuerce hacia atrás (DIR_DERROTA) y cae detrás de los héroes, no encima.
#   Móvil (combate.gd «movil», calidad 0,4): menos partículas y pocas nubes grandes (el Redmi va justo de relleno).

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
# V12, Bramavidrio v2: efectos de los ataques (ver la cabecera)
const DIR_DERROTA := Vector3(0.85, 0.0, -0.53)   # hacia dónde mira al morir: se desploma detrás de los héroes
const C_ARENA_CHORRO := Color(0.86, 0.66, 0.4)   # el chorro: ocre más oscuro que el suelo, para que se lea sobre él
const PLACAS_ASIENTAN := 3.1             # instantes del clip «ataque_sismico» (bramavidrio2_clips.json; la v1, igual)
const PLACAS_FIN := 3.65
const FIN_SUCCION := 1.7                 # «ataque_aliento»
const ALCANCE_EXTRA := 160.0             # Embestida: cuánto puede avanzar su dibujo hacia un objetivo lejano (escena)
var _ofs_mordisco := 673.0              # Embestida: de su agujero a su hocico en el impacto (escena; se mide en cada una)
# V12, sonido propio de Bramavidrio (12/11, encargo del usuario; informe docs/memory/agents/sonido_v12_bramavidrio.md):
# qué suena en cada instante, [identidad propia (sonido.gd, EFECTOS_BRAMAVIDRIO), lo de antes] ("" = nada). Con la
# identidad apagada (sonido.gd BRAMAVIDRIO_IDENTIDAD = false, o «-- bramavidrio_sonido=anterior») suena exactamente lo de
# antes. Solo se piden sonidos (con la señal sonido_pedido de combate.gd, como _sonar): ni efectos, ni daños, ni IA, ni
# turnos cambian. Su voz (herido y caída) la pide combate.gd con Sonido.recibe (familia «brama» en sonido.gd).
const SONIDOS := {
	"emerge": ["brama_emerge", "gusano_temblor"],           # al entrar: rompe la arena (rompe_arena)
	"rugido_entrada": ["brama_rugido", "gusano_rugido"],    # al entrar, 0,9 s después
	"recoge": ["brama_recoge", ""],                         # Embestida: se recoge (0,2 s del clip)
	"fija": ["brama_fija", ""],                             # Embestida: fija al objetivo (0,55)
	"latigazo": ["brama_latigazo", ""],                     # Embestida: se lanza (0,8)
	"surco": ["brama_surco", ""],                           # Embestida: avanza sobre la arena (_deslizar)
	"embestida": ["brama_embestida", "gusano_temblor"],     # Embestida: impacto (1,0)
	"rugido": ["brama_rugido", "gusano_rugido"],            # aviso de la Fractura (rugido_pico)
	"caida_aire": ["brama_caida_aire", ""],                 # Fractura: cae (2,1)
	"fractura": ["brama_fractura", "gusano_temblor"],       # Fractura: impacto (2,5333)
	"placas": ["brama_placas", ""],                         # Fractura: placas_suelo (v1: con el impacto)
	"placas_asientan": ["brama_placas_asientan", ""],       # Fractura: placas_asientan (3,1)
	"succion": ["brama_succion", "gusano_temblor"],         # aviso del Aliento: empieza a aspirar (succion, 0,45)
	"chorro": ["brama_chorro", "gusano_rugido"],            # Aliento: el chorro (1,85)
	"alcanza": ["brama_arena_alcanza", ""],                 # Aliento: el chorro alcanza a un héroe
	"atraganta": ["brama_atraganta", ""],                   # le cortan el Aliento
	"jadeo": ["brama_jadeo", ""],                           # el turno que jadea (o escupe la arena tras el corte)
	"derrumbe": ["brama_derrumbe", "gusano_temblor"],       # derrota: se desploma (caida, 1,6)
}
const BUCLE_SUCCION := "brama_succion_bucle"            # mientras aspira, hasta fin_succion, el golpe o el corte
const SonidoGD := preload("res://sonido.gd")
var creados := {}                       # pruebas: efectos creados de cada clase
var chorro: Node2D                      # el chorro del Aliento mientras barre (pruebas)
var polvo_succion: CPUParticles2D       # el polvo que levanta al aspirar
var _citas: Array = []                  # [clip, segundos, Callable, límite]: salen cuando su clip llega a ese instante
var _reloj := 0.0                       # segundos de juego (límite de las citas si el clip no llega)
var _frente := false                    # se dibuja delante de los héroes que quedan detrás de su cabeza
var _indice0 := -1                      # su sitio de siempre entre los luchadores (detrás de todos)
var _girado := false                    # ya se ha vuelto para morir
var _tirando := false                   # los héroes se inclinan hacia él mientras aspira
var _tw_cuerpo := {}                    # héroe → el tween de su dibujo (empujones y tirones; uno a la vez)
var _barrido := {}                      # el chorro: tiempo, recorrido y a quién ha alcanzado
var _fx := {}                           # la Fractura: sus placas y su nube (para asentarlas y acabarlas)
var _rng := RandomNumberGenerator.new() # azar propio de los efectos: no toca el del combate
var _tex_raya: Texture2D                # una mota alargada: arena en movimiento (se alinea con su velocidad)
var _tex_borde: Texture2D               # bordes suaves de las bandas (chorro y estela)
var _tex_grano: Array = []              # el grano del chorro (dos texturas que se alternan: la arena hierve)


static func es(e) -> bool:
	return e is Dictionary and str(e.get("clave", "")) == CLAVE


# V12, sonido: el nombre del sonido de un instante (SONIDOS) según la identidad elegida ("" si no suena nada).
static func sonido(evento: String) -> String:
	var par: Array = SONIDOS.get(evento, ["", ""])
	return par[0] if SonidoGD.identidad_bramavidrio() else par[1]


# Pide el sonido de un instante como combate.gd _sonar: la señal sonido_pedido sale siempre (pruebas) y suena por Sonido.
func _son(evento: String) -> void:
	var n := sonido(evento)
	if n == "":
		return
	c.sonido_pedido.emit(n)
	Sonido.efecto(n)


func preparar(combate, e: Dictionary) -> void:
	c = combate
	f = e
	name = "Bramavidrio"
	_crear_texturas()
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
			_son("emerge")
			_estallido_arena(_agujero(), 1.0)
			c._temblor(6.0), CONNECT_ONE_SHOT)
	if p.has_signal("caida"):
		p.caida.connect(func():
			_son("derrumbe")
			_caida_cuerpo(), CONNECT_ONE_SHOT)
	get_tree().create_timer(0.9).timeout.connect(func(): if f["hp"] > 0: _son("rugido_entrada"))


# ================================================================= su turno

func turno(vivos: Array, mult: float) -> void:
	if f.get("recupera", false):
		f["recupera"] = false
		var aturdido: bool = f.get("aturdido", false)
		f.erase("aturdido")
		c.registro.text = ("%s, aturdido, escupe la arena que tragó" if aturdido else "%s jadea: la garganta se le apaga") % f["nombre"]
		c._numero_flotante(f, "Aturdido" if aturdido else "Jadea", Color(0.8, 0.85, 0.75), 30)
		_son("jadeo")                                 # V12, sonido: resuella (o escupe la arena)
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
		_son("embestida")                            # el peso del golpe en la arena (con el golpe de siempre)
		_golpe_embestida(objetivo)
	if p == null:                                    # el respaldo 2D: el empujón de su foto
		await c._anim_fisico_imagen(f, objetivo, golpe)
	else:
		f["animando"] = true
		_en_instante("ataque", 0.2, _anticipacion_embestida)                 # se recoge: la arena le resbala
		_en_instante("ataque", 0.55, _fija_embestida)                        # fija al objetivo
		_en_instante("ataque", 0.8, _lanza_embestida.bind(objetivo))         # se lanza: estela y delante
		await p.atacar("embestida", golpe)
		_vaciar_citas("ataque")
		_al_frente(false)
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
				_son("rugido")
				c._temblor(5.0), CONNECT_ONE_SHOT)
		else:
			_son("rugido")
	else:
		c.registro.text = "%s abre las fauces y aspira el desierto: ¡va a soplar contra todos!" % f["nombre"]
		_mostrar_cartel("⚠ " + NOMBRES["aliento"], "")
		_tenir_fondo(Color(0.95, 0.82, 0.62))
		if p != null and p.has_signal("succion"):
			p.succion.connect(func():
				_son("succion")
				_empezar_succion(), CONNECT_ONE_SHOT)
		else:
			_son("succion")
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
	var placas := [false]                            # las placas y el polvo, una vez (señal placas_suelo o el golpe)
	var placas_suelo := func():
		if placas[0]:
			return
		placas[0] = true
		_placas_suelo(_donde_cae(centro), centro)
	var golpe := func():
		if hecho[0]:
			return
		hecho[0] = true
		_contar("impacto_fractura")
		_a_todos(vivos, int(f["atk"] * MULT_FRACTURA * mult), true)
		Sonido.golpe(true)                           # la caída: un golpe para todos, una vez
		_son("fractura")
		_efecto_fractura(_donde_cae(centro))
		_sacudida(16.0, 0.75)                        # con peso: cae y rebota (y una réplica)
		get_tree().create_timer(0.3).timeout.connect(func(): _sacudida(6.0, 0.35))
		if p == null or not p.has_signal("placas_suelo"):   # la v1 (o sin modelo): las placas con el golpe
			placas_suelo.call()
	f["animando"] = true
	if p != null:
		if p.has_signal("placas_suelo"):             # v2: el instante en que se levantan las placas del suelo
			p.placas_suelo.connect(placas_suelo, CONNECT_ONE_SHOT)
		_en_instante("ataque_sismico", 2.1, _sombra_caida.bind(centro))   # cae: su sombra crece donde va a dar
		_en_instante("ataque_sismico", PLACAS_ASIENTAN, _placas_asientan)
		_en_instante("ataque_sismico", PLACAS_FIN, _placas_fin)
		await p.atacar("sismico", golpe)
	else:
		await get_tree().create_timer(0.5).timeout
	golpe.call()
	placas_suelo.call()
	if p != null and p.has_signal("placas_suelo") and p.placas_suelo.is_connected(placas_suelo):
		p.placas_suelo.disconnect(placas_suelo)
	_vaciar_citas("ataque_sismico")
	_placas_asientan()                               # (si el clip se cortó: que el polvo se pose igualmente; si no, nada)
	_placas_fin()
	_al_frente(false)
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
		_son("chorro")                               # el bramido del chorro
		_chorro_barrido(vivos)                       # barre a los tres de delante atrás hasta fin_descarga
		_a_todos(vivos, int(f["atk"] * MULT_ALIENTO * mult), false)
		Sonido.golpe(true)                           # el chorro alcanza a todos: un golpe, una vez
		c._fogonazo(C_ARENA_CHORRO, 0.16, 1.0)
		_sacudida(9.0, 0.5)
	f["animando"] = true
	if p != null:
		if p.has_signal("fin_succion"):              # v2: deja de aspirar (1,7 s); la v1, en el mismo instante del clip
			p.fin_succion.connect(_parar_succion, CONNECT_ONE_SHOT)
		else:
			_en_instante("ataque_aliento", FIN_SUCCION, _parar_succion)
		await p.atacar("aliento", golpe)
		if p.has_signal("fin_succion") and p.fin_succion.is_connected(_parar_succion):
			p.fin_succion.disconnect(_parar_succion)
		_vaciar_citas("ataque_aliento")
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
	_son("atraganta")                                 # V12, sonido: se atraganta con su arena
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
		if not tambalea and not _barrido.is_empty():   # el Aliento: el chorro empuja a cada uno cuando lo alcanza
			continue
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
	p.set_meta("brama_efecto", "arena")
	creados["arena"] = int(creados.get("arena", 0)) + 1
	c.escena.add_child(p)
	p.emitting = true
	_contar_particulas(0)
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
	grietas.z_index = -1                               # en el suelo: bajo los héroes y el cuerpo caído
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
	grietas.set_meta("brama_efecto", "grietas")
	creados["grietas"] = int(creados.get("grietas", 0)) + 1
	c._onda(centro, Color(1.0, 0.88, 0.62, 0.9), 30.0, 480.0, 0.7, 12.0)
	get_tree().create_timer(0.14).timeout.connect(func(): c._onda(centro, Color(C_ARENA, 0.7), 20.0, 330.0, 0.6, 8.0))
	_arena(centro, C_ARENA, 60, 1.2, Vector2(200, 560), Vector2(0, -1), 80.0, Vector2(0, 950), 0.1, 160.0)
	_polvo(centro + Vector2(0, -20), 50)
	c._particulas(centro + Vector2(0, -30), Color(C_VIDRIO, 1.0), Color(0.5, 0.85, 1.0, 0.0), 30, 1.0, Vector2(260, 620),
		120.0, Vector2(0, -1), 60.0, Vector2(0, 1100), 0.05)
	_contar_particulas(0)                              # el humo y las esquirlas son del combate: se cuentan vivos


# Una placa de piedra que se alza del suelo (pivote en su base) y se inclina; tiembla hasta que se asienta
# (_placas_asientan la hunde). Se borra sola a los 4 s pase lo que pase.
func _placa(pos: Vector2, ancho: float, alto: float, inclina: float, retraso: float) -> Node2D:
	var n := _efecto("placa", pos, 4.0)
	n.position = pos
	n.z_index = 0                                      # (sobre el cuerpo caído y bajo el menú, que va después)
	n.scale = Vector2(1.0, 0.0)
	var cara := Polygon2D.new()
	cara.polygon = PackedVector2Array([Vector2(-ancho * 0.5, 0), Vector2(-ancho * 0.42, -alto * 0.92),
		Vector2(ancho * 0.05, -alto), Vector2(ancho * 0.5, -alto * 0.8), Vector2(ancho * 0.48, 0)])
	cara.color = Color(0.6, 0.5, 0.37)   # costra de arena prensada
	n.add_child(cara)
	var lado := Polygon2D.new()                       # el canto en sombra, para que se lea el volumen
	lado.polygon = PackedVector2Array([Vector2(ancho * 0.48, 0), Vector2(ancho * 0.5, -alto * 0.8),
		Vector2(ancho * 0.62, -alto * 0.7), Vector2(ancho * 0.6, 4)])
	lado.color = Color(0.33, 0.26, 0.19)
	n.add_child(lado)
	var filo := Line2D.new()                          # un filo de vidrio en lo alto
	filo.points = PackedVector2Array([Vector2(-ancho * 0.42, -alto * 0.92), Vector2(ancho * 0.05, -alto),
		Vector2(ancho * 0.5, -alto * 0.8)])
	filo.width = 3.0
	filo.default_color = Color(C_VIDRIO, 0.9)
	n.add_child(filo)
	var t := n.create_tween()
	t.tween_interval(retraso)
	t.tween_property(n, "scale", Vector2(1.0, 1.12), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(n, "rotation_degrees", inclina, 0.12)
	t.tween_property(n, "scale", Vector2(1.0, 1.0), 0.1)                   # choca y rebota
	for i in 4:                                                             # tiembla mientras el suelo se mueve
		t.tween_property(n, "rotation_degrees", inclina + (2.5 if i % 2 == 0 else -2.5) * (1.0 - i * 0.2), 0.06)
	t.tween_property(n, "rotation_degrees", inclina, 0.06)
	n.set_meta("t", t)
	return n


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


# ================================================================= V12, Bramavidrio v2: efectos de los ataques

# Texturas propias (una vez): una mota alargada (arena en movimiento, alineada con su velocidad) y los bordes suaves de
# las bandas.
func _crear_texturas() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
	var r := GradientTexture2D.new()
	r.gradient = g
	r.fill = GradientTexture2D.FILL_RADIAL
	r.fill_from = Vector2(0.5, 0.5)
	r.fill_to = Vector2(1.0, 0.5)
	r.width = 24
	r.height = 96
	_tex_raya = r
	var gb := Gradient.new()
	gb.offsets = PackedFloat32Array([0.0, 0.22, 0.5, 0.78, 1.0])
	gb.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var b := GradientTexture2D.new()
	b.gradient = gb
	b.fill_from = Vector2(0, 0)
	b.fill_to = Vector2(0, 1)
	b.width = 4
	b.height = 64
	_tex_borde = b
	_tex_grano = [_grano(1305), _grano(1306)]


# Motas de arena sueltas, más densas en el centro y nada en los bordes (el grano del chorro; dos que se alternan).
func _grano(semilla: int) -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	for y in 32:
		var borde := clampf(1.0 - absf(y - 15.5) / 16.0, 0.0, 1.0)
		for x in 32:
			var a := rng.randf_range(0.45, 1.0) * borde if rng.randf() < 0.3 else 0.0
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


# Un efecto: un nodo de la escena del combate con su nombre (efectos_vivos) que se borra solo a los «vida» s (0: lo
# borra quien lo creó). «suelo»: se dibuja bajo los luchadores (sombras y grietas).
func _efecto(nombre: String, pos := Vector2.ZERO, vida := 3.0, suelo := false) -> Node2D:
	var n := Node2D.new()
	n.name = "brama_" + nombre
	n.position = pos
	n.set_meta("brama_efecto", nombre)
	if suelo:
		n.z_index = -1                               # sobre el fondo (z −100) y bajo los luchadores
	c.escena.add_child(n)
	creados[nombre] = int(creados.get(nombre, 0)) + 1
	if vida > 0.0:
		var t := n.create_tween()
		t.tween_interval(vida)
		t.tween_callback(n.queue_free)
	return n


# Los efectos de Bramavidrio que siguen en la escena (pruebas: que se crean y se borran).
func efectos_vivos() -> Array:
	var r: Array = []
	if c == null or c.escena == null or not is_instance_valid(c.escena):
		return r
	for n in c.escena.get_children():
		if n.has_meta("brama_efecto") and not n.is_queued_for_deletion():
			r.append(str(n.get_meta("brama_efecto")))
	return r


# Un emisor de partículas dentro de «padre». «d»: n (en el PC; en el móvil, «n_movil» o n × calidad), vida, pos, forma
# («esfera» con radio, «caja» con caja, «puntos» con puntos), dir, apertura, vel (mín, máx), gravedad, amortigua, radial
# (mín, máx), escala (mín, máx), curva (la escala a lo largo de la vida), colores y tiempos, aditivo, alinear (la mota
# alargada sigue su velocidad), una_vez (si no, emite sin parar; «segundos»: cuánto) y explosion.
func _emisor(padre: Node, d: Dictionary) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _tex_raya if d.get("alinear", false) else c.glow_tex
	if d.get("aditivo", false):
		p.material = c.mat_aditivo
	p.position = d.get("pos", Vector2.ZERO)
	var n: int = int(d["n"])
	p.amount = maxi(2, int(d["n_movil"]) if c.movil and d.has("n_movil") else int(round(n * c.calidad)))
	p.lifetime = d.get("vida", 1.0)
	p.one_shot = d.get("una_vez", true)
	p.explosiveness = d.get("explosion", 0.85 if p.one_shot else 0.0)
	p.randomness = 0.2
	match str(d.get("forma", "esfera")):
		"caja":
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = d.get("caja", Vector2(40, 10))
		"puntos":
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
			p.emission_points = d["puntos"]
		_:
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = d.get("radio", 20.0)
	p.direction = d.get("dir", Vector2(0, -1))
	p.spread = d.get("apertura", 30.0)
	var v: Vector2 = d.get("vel", Vector2(50, 150))
	p.initial_velocity_min = v.x
	p.initial_velocity_max = v.y
	p.gravity = d.get("gravedad", Vector2.ZERO)
	var am: float = d.get("amortigua", 0.0)
	p.damping_min = am * 0.7
	p.damping_max = am
	var ra: Vector2 = d.get("radial", Vector2.ZERO)
	p.radial_accel_min = ra.x
	p.radial_accel_max = ra.y
	var e: Vector2 = d.get("escala", Vector2(0.1, 0.2))
	p.scale_amount_min = e.x
	p.scale_amount_max = e.y
	if d.has("curva"):
		var cu := Curve.new()
		for q in d["curva"]:
			cu.add_point(q)
		p.scale_amount_curve = cu
	p.particle_flag_align_y = d.get("alinear", false)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(d.get("tiempos", [0.0, 0.15, 1.0]))
	g.colors = PackedColorArray(d["colores"])
	p.color_ramp = g
	padre.add_child(p)
	p.emitting = true
	_contar_particulas(0)
	if not p.one_shot and d.has("segundos"):
		get_tree().create_timer(float(d["segundos"])).timeout.connect(func():
			if is_instance_valid(p):
				p.emitting = false)
	return p


# Una banda de arena (Line2D con bordes suaves): «anchos» [ancho, al principio, a mitad], «colores» a lo largo.
func _banda(padre: Node, ancho: float, curva: Array, colores: Array, tiempos: Array, aditivo := false) -> Line2D:
	var l := Line2D.new()
	l.width = ancho
	var cu := Curve.new()
	for q in curva:
		cu.add_point(q)
	l.width_curve = cu
	l.texture = _tex_borde
	l.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(tiempos)
	g.colors = PackedColorArray(colores)
	l.gradient = g
	if aditivo:
		l.material = c.mat_aditivo
	padre.add_child(l)
	return l


# Sacudida con peso: la pantalla cae y rebota, sobre todo en vertical, y se apaga. Su propio azar (no el del combate).
func _sacudida(fuerza: float, dur := 0.6) -> void:
	if c.capa == null or not is_instance_valid(c.capa):
		return
	var t: Tween = c.create_tween()
	var pasos := maxi(5, int(dur / 0.045))
	for i in pasos:
		var k := fuerza * pow(1.0 - float(i) / pasos, 1.5)
		var y := k if i % 2 == 0 else -k * 0.6
		t.tween_property(c.capa, "offset", Vector2(_rng.randf_range(-0.4, 0.4) * k, y), dur / pasos)
	t.tween_property(c.capa, "offset", Vector2.ZERO, 0.05)


# ---------------------------------------------------------------- citas con el clip del modelo

# «accion» sale cuando el clip «clip» del modelo llega a «s» segundos (o, si no llega, a los «limite» s de juego).
func _en_instante(clip: String, s: float, accion: Callable, limite := 8.0) -> void:
	_citas.append([clip, s, accion, _reloj + limite])


func _vaciar_citas(clip: String) -> void:
	_citas = _citas.filter(func(x): return x[0] != clip)


func _revisar_citas() -> void:
	if _citas.is_empty():
		return
	var p = c._p3d(f)
	var clip := ""
	var pos := 0.0
	if p != null and p.anim != null:
		clip = String(p.anim.current_animation)
		pos = p.anim.current_animation_position
	for x in _citas.duplicate():
		if (x[0] == clip and pos >= x[1]) or _reloj >= x[3]:
			_citas.erase(x)
			(x[2] as Callable).call()


# ---------------------------------------------------------------- orden de dibujo

# Mientras ataca, se dibuja delante de los héroes que quedan detrás de su cabeza (su hocico sobre el suelo, en
# profundidad); si no, en su sitio de siempre, detrás de todos.
func _al_frente(si: bool) -> void:
	_frente = si
	if si:
		_ordenar(_suelo_cabeza().y)
	else:
		_ordenar(-INF)


func _ordenar(y_cabeza: float) -> void:
	var rig = f.get("rig")
	if rig == null or not is_instance_valid(rig) or rig.get_parent() != c.escena:
		return
	if _indice0 < 0:
		_indice0 = rig.get_index()
	var tras := -1                                       # el último héroe (en el árbol) que queda detrás de su cabeza
	for h in c.heroes:
		if h.has("rig") and is_instance_valid(h["rig"]) and h["rig"].get_parent() == c.escena and c._suelo_de(h).y < y_cabeza:
			tras = maxi(tras, h["rig"].get_index())
	var actual: int = rig.get_index()
	var meta := _indice0
	if tras >= 0:
		meta = tras if actual < tras else tras + 1
	if meta != actual:
		c.escena.move_child(rig, meta)


# Dónde está su hocico sobre el suelo (en profundidad, como los pies de los héroes).
func _suelo_cabeza() -> Vector2:
	var p = c._p3d(f)
	if p == null or not f.has("cam3d") or not p.has_method("cabeza"):
		return c._suelo_de(f)
	var cab: Vector3 = p.cabeza()
	return _en_escena(Vector3(cab.x, p.global_position.y, cab.z))


# ---------------------------------------------------------------- 1. Embestida

# Se recoge (anticipacion): la arena le resbala del cuello, el suelo del agujero se levanta y retumba.
func _anticipacion_embestida() -> void:
	_son("recoge")
	var p = c._p3d(f)
	if p == null:
		return
	var n := _efecto("anticipacion", Vector2.ZERO, 2.0)
	_emisor(n, {"n": 26, "n_movil": 10, "vida": 0.9, "pos": _en_escena(p.centro()), "forma": "caja", "caja": Vector2(90, 50),
		"dir": Vector2(0, 1), "apertura": 20.0, "vel": Vector2(20, 90), "gravedad": Vector2(0, 750), "explosion": 0.4,
		"escala": Vector2(0.04, 0.09), "colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.95), Color(C_ARENA_OSCURA, 0)]})
	_emisor(n, {"n": 12, "n_movil": 4, "vida": 1.0, "pos": _agujero() + Vector2(60, -10), "forma": "caja",
		"caja": Vector2(130, 12), "dir": Vector2(0, -1), "apertura": 50.0, "vel": Vector2(30, 90), "amortigua": 30.0,
		"gravedad": Vector2(0, -20), "escala": Vector2(0.35, 0.6),
		"colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.45), Color(C_ARENA, 0)]})
	_sacudida(2.5, 0.3)


# Fija al objetivo: un destello en su cabeza.
func _fija_embestida() -> void:
	_son("fija")
	var p = c._p3d(f)
	if p == null:
		return
	var n := _efecto("fija", _en_escena(p.cabeza()), 0.7)
	var b: Sprite2D = c._brillo(Color(1.0, 0.78, 0.5))
	b.scale = Vector2.ONE * 0.15
	n.add_child(b)
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2(1.2, 0.4), 0.12)
	t.tween_property(b, "modulate:a", 0.0, 0.35)


# Se lanza: se dibuja delante de quien queda detrás de su cabeza y deja una estela de arena hacia el objetivo. Si el
# objetivo queda más lejos de donde llega su hocico (Lya, detrás), se lanza también sobre la arena: su dibujo avanza lo
# que falta (como mucho ALCANCE_EXTRA), levantando arena en la base, y vuelve a su agujero.
func _lanza_embestida(obj: Dictionary) -> void:
	_al_frente(true)
	_son("latigazo")
	var p = c._p3d(f)
	if p == null:
		return
	var falta: float = c._suelo_de(obj).x - 40.0 - (_agujero().x + _ofs_mordisco)
	if falta > 12.0:
		_deslizar(minf(falta, ALCANCE_EXTRA))
	var desde := _en_escena(p.cabeza())
	var hasta: Vector2 = c._centro(obj) + Vector2(0, 40)
	var n := _efecto("estela", Vector2.ZERO, 0.9)
	var l := _banda(n, 170.0, [Vector2(0, 0.15), Vector2(1, 1)],
		[Color(0.85, 0.68, 0.45, 0.0), Color(0.85, 0.68, 0.45, 0.85)], [0.0, 1.0])
	l.points = PackedVector2Array([desde, desde])
	var t := l.create_tween()
	t.tween_method(func(v: float): l.points = PackedVector2Array([desde, desde.lerp(hasta, v)]), 0.0, 1.0, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(l, "modulate:a", 0.0, 0.3)


# El impacto (combate.gd lo resuelve una vez): golpe de arena a los pies del alcanzado (abanico, terrones, polvo bajo y
# onda), arena que salta de su hocico, el empujón y una sacudida con peso.
func _golpe_embestida(objetivo: Dictionary) -> void:
	var pie: Vector2 = c._suelo_de(objetivo)
	_estallido_arena(pie, 1.0)
	_polvo(pie + Vector2(0, -30), 34)
	c._onda(pie, Color(C_ARENA, 0.85), 20.0, 240.0, 0.45, 9.0)
	var n := _efecto("golpe_embestida", pie, 2.0)
	_emisor(n, {"n": 22, "n_movil": 9, "vida": 0.8, "radio": 30.0, "dir": Vector2(0, -1), "apertura": 75.0,
		"vel": Vector2(280, 640), "gravedad": Vector2(0, 1500), "escala": Vector2(0.06, 0.12),
		"colores": [Color(C_ARENA_OSCURA, 1), Color(C_ARENA_OSCURA, 1), Color(C_ARENA_OSCURA, 0)], "tiempos": [0.0, 0.7, 1.0]})
	_emisor(n, {"n": 10, "n_movil": 4, "vida": 1.1, "forma": "caja", "caja": Vector2(60, 8), "dir": Vector2(1, 0),
		"apertura": 180.0, "vel": Vector2(120, 280), "amortigua": 220.0, "gravedad": Vector2(0, -15),
		"escala": Vector2(0.5, 0.85), "colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.55), Color(C_ARENA, 0)]})
	var p = c._p3d(f)
	if p != null and f.has("cam3d"):
		var hocico := _en_escena(p.cabeza())
		_estallido_arena(hocico, 0.5)
		_ofs_mordisco = hocico.x - _agujero().x          # hasta dónde llega de verdad (para la próxima)
	_empujar(objetivo, 52.0, 0.45)
	_sacudida(8.0, 0.4)


# Se lanza sobre la arena: su dibujo avanza «dx» (0,2 s), aguanta el mordisco y vuelve a su sitio; la base levanta arena.
func _deslizar(dx: float) -> void:
	var rig = f.get("rig")
	if rig == null or not is_instance_valid(rig):
		return
	_contar("desliza")
	_son("surco")
	var base: Vector2 = f["rig_base"]
	var t: Tween = rig.create_tween()
	t.tween_property(rig, "position", base + Vector2(dx, 0), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_interval(0.35)
	t.tween_property(rig, "position", base, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var hoyo := _agujero()
	var n := _efecto("surco", hoyo, 2.0)
	_emisor(n, {"n": 18, "n_movil": 7, "vida": 0.9, "una_vez": false, "segundos": 0.25, "forma": "caja",
		"caja": Vector2(dx * 0.5 + 40.0, 14), "pos": Vector2(dx * 0.5, 0), "dir": Vector2(0, -1), "apertura": 55.0,
		"vel": Vector2(80, 260), "gravedad": Vector2(0, 700), "escala": Vector2(0.06, 0.12),
		"colores": [Color(C_ARENA_OSCURA, 0), Color(C_ARENA_OSCURA, 1), Color(C_ARENA, 0)], "tiempos": [0.0, 0.15, 1.0]})
	_emisor(n, {"n": 8, "n_movil": 3, "vida": 1.2, "forma": "caja", "caja": Vector2(dx * 0.5 + 40.0, 10),
		"pos": Vector2(dx * 0.5, -10), "dir": Vector2(0, -1), "apertura": 40.0, "vel": Vector2(20, 70),
		"amortigua": 30.0, "escala": Vector2(0.5, 0.8), "colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.45), Color(C_ARENA, 0)]})


# ---------------------------------------------------------------- 2. Fractura

# Cae (caida): se dibuja delante de los héroes que quedan detrás de su cabeza y su sombra crece donde va a dar.
func _sombra_caida(centro: Vector2) -> void:
	_al_frente(true)
	_son("caida_aire")
	var n := _efecto("sombra_caida", centro, 0.9, true)
	n.scale = Vector2(0.3, 0.3 * 0.34)
	n.modulate.a = 0.0
	var s := Sprite2D.new()
	s.texture = c.glow_tex
	s.modulate = Color(0.12, 0.07, 0.03, 0.75)
	s.scale = Vector2.ONE * 2.6
	n.add_child(s)
	var t := n.create_tween()
	t.tween_property(n, "scale", Vector2(1.0, 0.34), 0.43).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(n, "modulate:a", 1.0, 0.43)
	t.tween_property(n, "modulate:a", 0.0, 0.3)


# Las placas del suelo (señal placas_suelo de la v2; con la v1, en el golpe): placas que saltan y tiemblan, la nube de
# arena a ras de suelo bajo los héroes y los terrones que les caen encima.
func _placas_suelo(centro: Vector2, grupo: Vector2) -> void:
	_contar("placas_suelo")
	_son("placas")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1303                                       # siempre las mismas (no toca el azar del combate)
	var placas: Array = []
	var n_placas: int = 4 if c.movil else 7
	for i in n_placas:
		var ang := TAU * i / n_placas + rng.randf_range(-0.3, 0.3)
		var r := rng.randf_range(150, 330)
		placas.append(_placa(centro + Vector2(cos(ang) * r, sin(ang) * r * 0.34), rng.randf_range(70, 120),
			rng.randf_range(50, 95), rng.randf_range(-26, 26), 0.03 * i))
	var nube := _efecto("nube_suelo", grupo, 4.5)
	_emisor(nube, {"n": 26, "n_movil": 9, "vida": 2.2, "forma": "caja", "caja": Vector2(300, 24), "dir": Vector2(1, 0),
		"apertura": 180.0, "vel": Vector2(140, 380), "amortigua": 170.0, "gravedad": Vector2(0, -22), "explosion": 0.9,
		"escala": Vector2(0.75, 1.3), "curva": [Vector2(0, 0.5), Vector2(1, 1.2)],
		"colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.62), Color(C_ARENA_OSCURA, 0)], "tiempos": [0.0, 0.12, 1.0]})
	nube.create_tween().tween_callback(func():           # lo que saltó vuelve a caer, encima de ellos
		_emisor(nube, {"n": 40, "n_movil": 14, "vida": 1.3, "pos": Vector2(0, -380), "forma": "caja",
			"caja": Vector2(320, 40), "dir": Vector2(0, 1), "apertura": 15.0, "vel": Vector2(40, 160),
			"gravedad": Vector2(0, 950), "explosion": 0.35, "escala": Vector2(0.04, 0.1),
			"colores": [Color(C_ARENA_OSCURA, 0), Color(C_ARENA_OSCURA, 1), Color(C_ARENA, 0)], "tiempos": [0.0, 0.1, 1.0]})
		).set_delay(0.3)
	_fx = {"placas": placas, "nube": nube, "asentadas": false, "grupo": grupo}


# placas_asientan (3,1): las placas se hunden con un golpe sordo de polvo y el polvo de la nube se posa.
func _placas_asientan() -> void:
	if _fx.is_empty() or _fx["asentadas"]:
		return
	_fx["asentadas"] = true
	_contar("placas_asientan")
	_son("placas_asientan")
	var bases := PackedVector2Array()
	for n in _fx["placas"]:
		if not is_instance_valid(n):
			continue
		bases.append(n.position)
		var t0 = n.get_meta("t", null)
		if t0 is Tween and t0.is_valid():
			t0.kill()
		var t: Tween = n.create_tween()
		t.tween_property(n, "scale", Vector2(1.0, 0.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(n, "position:y", n.position.y + 10.0, 0.55)
		t.parallel().tween_property(n, "modulate:a", 0.5, 0.55)
	var g: Vector2 = _fx["grupo"]
	var posa := _efecto("polvo_posa", Vector2.ZERO, 3.0)
	if not bases.is_empty():
		_emisor(posa, {"n": 3 * bases.size(), "n_movil": 2 * bases.size(), "vida": 0.9, "forma": "puntos",
			"puntos": bases, "dir": Vector2(0, -1), "apertura": 70.0, "vel": Vector2(30, 90), "amortigua": 60.0,
			"escala": Vector2(0.3, 0.5), "colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.5), Color(C_ARENA, 0)]})
	_emisor(posa, {"n": 14, "n_movil": 5, "vida": 1.6, "pos": g + Vector2(0, -170), "forma": "caja",
		"caja": Vector2(300, 90), "dir": Vector2(0, 1), "apertura": 30.0, "vel": Vector2(10, 40),
		"gravedad": Vector2(0, 40), "explosion": 0.5, "escala": Vector2(0.6, 1.0),
		"colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.28), Color(C_ARENA, 0)], "tiempos": [0.0, 0.3, 1.0]})
	_sacudida(3.0, 0.25)


# placas_fin (3,65): ya no queda nada en pie; la nube se acaba de disipar.
func _placas_fin() -> void:
	if _fx.is_empty():
		return
	_contar("placas_fin")
	for n in _fx["placas"]:
		if is_instance_valid(n):
			var t: Tween = n.create_tween()
			t.tween_property(n, "modulate:a", 0.0, 0.2)
			t.tween_callback(n.queue_free)
	var nube = _fx["nube"]
	if is_instance_valid(nube):
		var t2: Tween = nube.create_tween()
		t2.tween_property(nube, "modulate:a", 0.0, 0.6)
		t2.tween_callback(nube.queue_free)
	_fx = {}


# ---------------------------------------------------------------- 3. Aliento

# Mientras aspira: la arena sube del suelo (bajo su cabeza y bajo los héroes) a su boca, el polvo se levanta, la
# garganta se enciende y los héroes se inclinan hacia él. Hasta fin_succion (o el golpe, o el corte).
func _empezar_succion() -> void:
	_parar_succion()
	if f["hp"] <= 0 or not f.get("cargando", false):
		return
	if sonido("succion") == "brama_succion":           # V12, sonido: sigue aspirando en bucle (lo corta _parar_succion)
		c.sonido_pedido.emit(BUCLE_SUCCION)
		Sonido.efecto(BUCLE_SUCCION, {"en": self})
	var boca := _boca()
	var n := _efecto("succion", boca, 0.0)               # lo borra _parar_succion
	var puntos := _puntos_suelo(boca)
	succion = _emisor(n, {"n": 70, "n_movil": 26, "vida": 1.0, "una_vez": false, "forma": "puntos", "puntos": puntos,
		"dir": Vector2(0, -1), "apertura": 35.0, "vel": Vector2(40, 140), "radial": Vector2(-1350, -950),
		"amortigua": 60.0, "escala": Vector2(0.35, 0.7), "alinear": true,
		"colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.95), Color(C_GARGANTA, 0.8), Color(C_GARGANTA, 0)],
		"tiempos": [0.0, 0.2, 0.8, 1.0]})
	polvo_succion = _emisor(n, {"n": 12, "n_movil": 4, "vida": 1.6, "una_vez": false, "forma": "puntos", "puntos": puntos,
		"dir": Vector2(0, -1), "apertura": 25.0, "vel": Vector2(20, 60), "radial": Vector2(-140, -70),
		"escala": Vector2(0.5, 0.9), "colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.35), Color(C_ARENA, 0)]})
	brillo_garganta = c._brillo(C_GARGANTA)
	brillo_garganta.scale = Vector2.ONE * 0.3
	n.add_child(brillo_garganta)
	var t := brillo_garganta.create_tween().set_loops()
	t.tween_property(brillo_garganta, "scale", Vector2.ONE * 0.75, 0.4).set_trans(Tween.TRANS_SINE)
	t.tween_property(brillo_garganta, "scale", Vector2.ONE * 0.5, 0.4).set_trans(Tween.TRANS_SINE)
	_tirar(true)


# Puntos del suelo de donde sube la arena (relativos a la boca): de debajo de su cabeza hasta más allá de los héroes.
func _puntos_suelo(boca: Vector2) -> PackedVector2Array:
	var vivos: Array = c.heroes.filter(func(h): return h["hp"] > 0)
	var hoyo := _agujero()
	var lejos := _centro_grupo(vivos) + Vector2(160, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1304
	var pts := PackedVector2Array()
	for i in 16:
		var k := float(i) / 15.0
		var q := Vector2(lerpf(boca.x - 60.0, lejos.x, k), lerpf(hoyo.y, lejos.y, k))
		q += Vector2(rng.randf_range(-30, 30), rng.randf_range(-1.0, 1.0) * (30.0 + 70.0 * k))
		pts.append(q - boca)
	return pts


# La boca se mueve (traga, se echa atrás): la succión la sigue y la arena sigue saliendo del mismo suelo.
func _seguir_boca() -> void:
	var n := succion.get_parent() as Node2D
	if n == null:
		return
	var b := _boca()
	if b.distance_squared_to(n.position) < 1.0:
		return
	n.position = b
	var pts := _puntos_suelo(b)
	succion.emission_points = pts
	if polvo_succion != null and is_instance_valid(polvo_succion):
		polvo_succion.emission_points = pts


func _parar_succion() -> void:
	Sonido.cortar(BUCLE_SUCCION, 0.3)                    # V12, sonido: el bucle de la succión (si suena)
	if succion != null and is_instance_valid(succion):
		succion.emitting = false
		if polvo_succion != null and is_instance_valid(polvo_succion):
			polvo_succion.emitting = false
		var n := succion.get_parent()
		var t := n.create_tween()
		t.tween_interval(1.1)
		t.tween_callback(n.queue_free)
	succion = null
	polvo_succion = null
	if brillo_garganta != null and is_instance_valid(brillo_garganta):
		var b := brillo_garganta
		var t := b.create_tween()
		t.tween_property(b, "modulate:a", 0.0, 0.3)
	brillo_garganta = null
	_tirar(false)


# Los héroes se inclinan hacia él mientras aspira (solo su dibujo, poco: su sitio y sus controles no cambian).
func _tirar(si: bool) -> void:
	if si == _tirando:
		return
	_tirando = si
	for h in c.heroes:
		if not h.has("cuerpo") or not is_instance_valid(h["cuerpo"]):
			continue
		var cuerpo: Node2D = h["cuerpo"]
		if not h.has("cuerpo_pos0"):
			h["cuerpo_pos0"] = cuerpo.position
		var p0: Vector2 = h["cuerpo_pos0"]
		_matar_tw(h)
		var t := cuerpo.create_tween()
		if si and h["hp"] > 0:
			t.set_loops()
			t.tween_property(cuerpo, "position", p0 + Vector2(-9, 0), 0.22).set_trans(Tween.TRANS_SINE)
			t.tween_property(cuerpo, "position", p0 + Vector2(-4, 0), 0.22).set_trans(Tween.TRANS_SINE)
		else:
			t.tween_property(cuerpo, "position", p0, 0.25)
		_tw_cuerpo[h["nombre"]] = t


func _matar_tw(h: Dictionary) -> void:
	var t = _tw_cuerpo.get(h["nombre"], null)
	if t is Tween and t.is_valid():
		t.kill()
	_tw_cuerpo.erase(h["nombre"])


# El chorro (en el golpe, 1,85 s): una banda de arena opaca de su boca que BARRE a los vivos de delante atrás hasta
# fin_descarga (2,6), con su sombra, rayas que corren, un núcleo claro, la nube donde rompe y la arena que vuela dentro.
# A cada uno, al pasar: lo arrastra, le salpica y le cae arena encima (_alcanzar).
func _chorro_barrido(vivos: Array) -> void:
	if chorro != null and is_instance_valid(chorro):
		chorro.queue_free()
	var objetivos: Array = vivos.filter(func(h): return h["hp"] > 0)
	objetivos.sort_custom(func(a, b): return c._suelo_de(a).y > c._suelo_de(b).y)   # de delante atrás
	var pechos := PackedVector2Array()
	for h in objetivos:
		pechos.append(c._centro(h) + Vector2(0, 10))
	if pechos.is_empty():
		pechos.append(_centro_grupo(vivos) + Vector2(0, -150))
	var camino := PackedVector2Array()
	if pechos.size() == 1:
		camino = PackedVector2Array([pechos[0] + Vector2(-20, 80), pechos[0], pechos[0] + Vector2(20, -80)])
	else:
		camino.append(pechos[0] + (pechos[0] - pechos[1]).normalized() * 70.0)
		camino.append_array(pechos)
		camino.append(pechos[-1] + (pechos[-1] - pechos[-2]).normalized() * 70.0)
	var u: Array = []                                    # dónde del barrido está cada uno (0..1)
	for i in objetivos.size():
		u.append(float(i + 1) / float(camino.size() - 1))
	chorro = _efecto("chorro", Vector2.ZERO, 3.0)
	var curva := [Vector2(0, 0.3), Vector2(0.55, 0.88), Vector2(1, 1)]
	var sombra: Line2D = null                            # (en el móvil, sin sombra ni rayas: menos relleno para la GPU)
	if not c.movil:
		sombra = _banda(chorro, 380.0, curva,                        # su sombra en el suelo: lo separa del fondo
			[Color(0.22, 0.13, 0.06, 0.0), Color(0.22, 0.13, 0.06, 0.45), Color(0.22, 0.13, 0.06, 0.0)], [0.0, 0.4, 1.0])
	var banda := _banda(chorro, 360.0, curva,                        # el cuerpo del chorro: arena ocre, casi opaca
		[Color(0.8, 0.6, 0.36, 0.98), Color(0.74, 0.55, 0.33, 0.93), Color(0.66, 0.49, 0.3, 0.0)], [0.0, 0.65, 1.0])
	var grano := _banda(chorro, 330.0, curva,                        # el grano que hierve dentro (oscuro)
		[Color(0.42, 0.29, 0.17, 0.95), Color(0.42, 0.29, 0.17, 0.85), Color(0.42, 0.29, 0.17, 0.0)], [0.0, 0.7, 1.0])
	grano.texture = _tex_grano[0]
	grano.texture_mode = Line2D.LINE_TEXTURE_TILE
	grano.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var rayas_l: Array = []
	if not c.movil:
		rayas_l.append(_banda(chorro, 80.0, [Vector2(0, 0.3), Vector2(1, 1)],
			[Color(1.0, 0.9, 0.7, 0.0), Color(1.0, 0.9, 0.72, 0.6), Color(1.0, 0.9, 0.7, 0.0)], [0.0, 0.35, 1.0]))
		rayas_l.append(_banda(chorro, 64.0, [Vector2(0, 0.3), Vector2(1, 1)],
			[Color(0.45, 0.32, 0.2, 0.0), Color(0.45, 0.32, 0.2, 0.6), Color(0.45, 0.32, 0.2, 0.0)], [0.0, 0.45, 1.0]))
	var nucleo := _banda(chorro, 100.0, [Vector2(0, 0.25), Vector2(1, 0.7)],
		[Color(1.0, 0.85, 0.6, 0.5), Color(1.0, 0.8, 0.55, 0.22), Color(1.0, 0.8, 0.55, 0.0)], [0.0, 0.5, 1.0], true)
	var frente := Sprite2D.new()                         # la nube donde rompe (sin brillo: es arena)
	frente.texture = c.glow_tex
	frente.modulate = Color(0.78, 0.6, 0.38, 0.8)
	frente.scale = Vector2.ONE * 1.8
	chorro.add_child(frente)
	var boca := _boca()
	var dir0 := (camino[0] - boca).normalized()
	var rayas := _emisor(chorro, {"n": 90, "n_movil": 32, "vida": 0.42, "una_vez": false, "segundos": 0.75,
		"pos": boca, "radio": 30.0, "dir": dir0, "apertura": 8.0, "vel": Vector2(1500, 2100), "escala": Vector2(0.7, 1.3),
		"alinear": true, "colores": [Color(1, 0.92, 0.75, 0), Color(0.95, 0.8, 0.58, 1.0), Color(0.55, 0.4, 0.25, 0)],
		"tiempos": [0.0, 0.1, 1.0]})
	var granos := _emisor(chorro, {"n": 50, "n_movil": 16, "vida": 0.6, "una_vez": false, "segundos": 0.75,
		"pos": boca, "radio": 40.0, "dir": dir0, "apertura": 14.0, "vel": Vector2(800, 1300), "gravedad": Vector2(0, 220),
		"escala": Vector2(0.09, 0.18), "colores": [Color(0.35, 0.24, 0.14, 0), Color(0.35, 0.24, 0.14, 1), Color(0.35, 0.24, 0.14, 0)],
		"tiempos": [0.0, 0.1, 1.0]})
	_barrido = {"t": 0.0, "dur": 0.75, "camino": camino, "objetivos": objetivos, "u": u, "alcanzados": {}, "fin": false,
		"sombra": sombra, "lineas": [banda, grano, nucleo], "grano": grano, "rayas_l": rayas_l, "frente": frente,
		"emisores": [rayas, granos]}
	_actualizar_chorro(0.0)


# Un punto del barrido (0..1) a lo largo del camino de pecho en pecho.
func _en_camino(camino: PackedVector2Array, u: float) -> Vector2:
	var tramos := camino.size() - 1
	var x := clampf(u, 0.0, 1.0) * tramos
	var i := mini(int(x), tramos - 1)
	return camino[i].lerp(camino[i + 1], x - i)


func _actualizar_chorro(delta: float) -> void:
	var b := _barrido
	if chorro == null or not is_instance_valid(chorro):
		_barrido = {}
		return
	b["t"] += delta
	var t: float = b["t"] / b["dur"]
	var u := clampf(t, 0.0, 1.0)
	var boca := _boca()
	var punta := _en_camino(b["camino"], u)
	var dir := (punta - boca).normalized()
	var normal := Vector2(-dir.y, dir.x)
	var fin := boca + (punta - boca) * 1.45               # sigue más allá: los envuelve
	var abrir := clampf(b["t"] / 0.12, 0.0, 1.0)         # sale de la boca en 0,12 s
	var punta_v := boca.lerp(fin, abrir)
	var medio := boca.lerp(punta_v, 0.5) + normal * sin(b["t"] * 38.0) * 10.0
	var pts := PackedVector2Array([boca, medio, punta_v])
	for l in b["lineas"]:
		l.points = pts
	b["grano"].texture = _tex_grano[int(b["t"] / 0.05) % 2]          # la arena hierve
	if b["sombra"] != null:
		b["sombra"].points = PackedVector2Array([boca + Vector2(0, 26), medio + Vector2(0, 30), punta_v + Vector2(0, 36)])
	for k in b["rayas_l"].size():                         # las rayas: corrientes que se retuercen dentro
		var lado := 1.0 if k == 0 else -1.0
		var off := normal * lado * (40.0 + 18.0 * sin(b["t"] * 25.0 + k * 2.0))
		b["rayas_l"][k].points = PackedVector2Array([boca, medio + off * 0.6, punta_v + off])
	b["frente"].position = boca.lerp(fin, abrir * 0.72)
	b["frente"].scale = Vector2.ONE * (1.4 + 0.25 * sin(b["t"] * 20.0))
	for e in b["emisores"]:
		if is_instance_valid(e):
			e.position = boca
			e.direction = dir
	for i in b["objetivos"].size():
		if not b["alcanzados"].has(i) and u >= float(b["u"][i]) - 0.05:
			b["alcanzados"][i] = true
			_alcanzar(b["objetivos"][i], dir, maxf(0.1, b["dur"] * (1.0 - u)))
	if t >= 1.0 and not b["fin"]:
		b["fin"] = true
		var tw := chorro.create_tween()
		tw.tween_property(chorro, "modulate:a", 0.0, 0.35)
		tw.tween_callback(chorro.queue_free)
		_barrido = {}


# El chorro alcanza a un héroe: salpica, lo arrastra mientras le da y le cae arena encima.
func _alcanzar(h: Dictionary, dir: Vector2, espera: float) -> void:
	_contar("chorro_alcanza")
	_son("alcanza")
	var n := _efecto("alcanza", c._centro(h), 2.2)
	_emisor(n, {"n": 30, "n_movil": 12, "vida": 0.5, "radio": 30.0, "dir": dir, "apertura": 50.0, "vel": Vector2(300, 700),
		"gravedad": Vector2(0, 500), "escala": Vector2(0.06, 0.13),
		"colores": [Color(C_ARENA, 0), Color(C_ARENA, 1), Color(C_ARENA_OSCURA, 0)]})
	_emisor(n, {"n": 24, "n_movil": 9, "vida": 0.9, "una_vez": false, "segundos": 0.9, "pos": Vector2(0, -190),
		"forma": "caja", "caja": Vector2(70, 10), "dir": Vector2(0, 1), "apertura": 10.0, "vel": Vector2(60, 160),
		"gravedad": Vector2(0, 800), "escala": Vector2(0.04, 0.09),
		"colores": [Color(C_ARENA, 0), Color(C_ARENA, 1), Color(C_ARENA_OSCURA, 0)], "tiempos": [0.0, 0.1, 1.0]})
	_polvo(c._suelo_de(h) + Vector2(0, -20), 18)
	_empujar(h, 64.0, 0.55, espera)


# Empuja visualmente a un héroe (solo su dibujo: su sitio y sus controles no cambian) y lo devuelve; «espera»: lo sigue
# arrastrando ese tiempo antes de volver.
func _empujar(h: Dictionary, dist: float, dur: float, espera := 0.0) -> void:
	if not h.has("cuerpo") or h["hp"] <= 0:
		return
	var cuerpo: Node2D = h["cuerpo"]
	if not h.has("cuerpo_pos0"):
		h["cuerpo_pos0"] = cuerpo.position
	var p0: Vector2 = h["cuerpo_pos0"]
	_matar_tw(h)
	var t := cuerpo.create_tween()
	t.tween_property(cuerpo, "position", p0 + Vector2(dist, 0), dur * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if espera > 0.0:
		t.tween_property(cuerpo, "position", p0 + Vector2(dist * 1.15, 0), espera)
	t.tween_property(cuerpo, "position", p0, dur * 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tw_cuerpo[h["nombre"]] = t


# ---------------------------------------------------------------- derrota

# Al desplomarse (señal caida): la arena salta a lo largo del cuerpo, detrás de los héroes, y retumba.
func _caida_cuerpo() -> void:
	var hoyo := _agujero()
	var cab := _suelo_cabeza()
	for k in [0.35, 0.7, 1.0]:
		_estallido_arena(hoyo.lerp(cab, k), 0.55)
	var n := _efecto("caida", hoyo.lerp(cab, 0.6), 3.0)
	_emisor(n, {"n": 16, "n_movil": 6, "vida": 1.8, "forma": "caja", "caja": Vector2(maxf(60.0, hoyo.distance_to(cab) * 0.5), 20),
		"dir": Vector2(0, -1), "apertura": 60.0, "vel": Vector2(40, 140), "amortigua": 60.0, "gravedad": Vector2(0, -15),
		"escala": Vector2(0.6, 1.0), "colores": [Color(C_ARENA, 0), Color(C_ARENA, 0.5), Color(C_ARENA, 0)]})
	_sacudida(9.0, 0.5)


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

func _process(delta: float) -> void:
	if c == null or f.is_empty():
		return
	_reloj += delta
	_revisar_citas()                                   # V12, Bramavidrio v2: los efectos que van con su clip
	if _frente:
		_ordenar(_suelo_cabeza().y)
	if succion != null and is_instance_valid(succion):
		_seguir_boca()
	if not _barrido.is_empty():
		_actualizar_chorro(delta)
	var p = c._p3d(f)
	if not _girado and p != null and p.get("_muerta") == true:   # muere: se retuerce hacia atrás, detrás de los héroes
		_girado = true
		_al_frente(false)
		if p.has_method("mirar"):
			p.mirar(DIR_DERROTA, 1.3)
	if (f["hp"] <= 0 or c.estado == "fin") and (cartel != null or zona != null or succion != null or marca != null):
		_terminar_aviso()                              # cae (o acaba el combate) a medias: fuera avisos y succión
		_quitar_marca()
	if (f["hp"] <= 0 or c.estado == "fin") and _tirando:
		_tirar(false)


func _contar(que: String) -> void:
	contador[que] = int(contador.get(que, 0)) + 1


# Partículas vivas a la vez (las del combate y las de los efectos de Bramavidrio, que van dentro de su nodo).
func _contar_particulas(n: int) -> void:
	var vivas := 0
	for p in c.escena.get_children():
		if p is CPUParticles2D and p.emitting:
			vivas += p.amount
		elif p.has_meta("brama_efecto"):
			for q in p.get_children():
				if q is CPUParticles2D and q.emitting:
					vivas += q.amount
	particulas_max = maxi(particulas_max, vivas + n)


# Una nube de polvo de arena (el humo del combate, sin brillo), con menos partículas en el móvil (calidad 0,4).
func _polvo(pos: Vector2, cantidad: int) -> void:
	c._humo(pos, C_ARENA, maxi(8, int(cantidad * c.calidad)))
