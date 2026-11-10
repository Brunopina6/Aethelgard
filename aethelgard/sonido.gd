extends Node
# Sonido (autoload): buses, volúmenes del jugador (T-030, D-064) y efectos del juego (T-083).
# - Los buses están en default_bus_layout.tres: Musica, Efectos, Interfaz y Ambiente, todos hacia Master. Cada
#   reproductor elige el suyo: la música del combate y las campanas de la cinemática del mirador, Musica; Érebo, los
#   golpes, los pasos y los objetos, Efectos; los tonos de los menús y el sonido al escribir de los diálogos,
#   Interfaz; los ambientes de cada lugar (musica.gd), el río, la cascada y los detalles de la naturaleza, Ambiente.
# - El volumen de cada bus (de 0 a 100 %) se guarda en user://ajustes.cfg, aparte de la partida, y solo cuando el
#   jugador lo cambia: abrir el juego no escribe nada.
# - Con todo al 100 %, todo suena igual que antes de los buses (0 dB en cada uno).
# Los ajustes se cambian en la pestaña «Ajustes» del menú del grupo (menus.gd).
#
# EFECTOS (T-083). El juego pide un efecto por su nombre desde el evento real (un golpe, un paso, un cofre…):
#   Sonido.efecto("cofre")         Sonido.golpe(critico, defendido)         Sonido.efecto("tesoro", {"retraso": 0.3})
# - EFECTOS: cada efecto con sus variantes (derivados de audio/efectos/, hechos con pruebas/prueba_efectos_preparar.gd;
#   procedencia y licencia en docs/audio/inventario_sonidos.md), su bus, su volumen, cuánto varía el tono, su
#   prioridad, cuántos a la vez y la espera mínima entre dos iguales (un mismo evento no suena dos veces seguidas).
# - Voces: VOCES reproductores por bus. Sin hueco, se quita el de menos prioridad (y más viejo) si no es más
#   importante que el nuevo; si lo es, el nuevo no suena. Una victoria, una derrota o un jefe (prioridad 4) bajan los
#   golpes, pasos e interfaz (prioridades 0-2) mientras suenan: un golpe no tapa una victoria (las monedas y el
#   nivel, que llegan con ella, no bajan).
# - Sin repeticiones mecánicas: variantes sin repetir la anterior, y tono y volumen con una variación leve.
# - Cambio de escena: lo que suena por Efectos y Ambiente se apaga con un fundido corto (salvo los efectos «cruza»:
#   la emboscada, el portal…) y lo programado para después no llega a sonar. La interfaz sigue (el «confirmar» que
#   cambia de escena se oye entero).
# - Pausa: los efectos (no la interfaz) se pausan con el árbol; al pausar la app (Android) se pausa todo.
# - Silencio: con el bus a 0 % o callado, el efecto no suena ni ocupa voz.
# - Pasos: pasos_3d sigue los pies del esqueleto (suena cuando un pie toca el suelo); pasos_2d, los fotogramas del
#   muñeco. El suelo lo dice la escena (hierba, piedra, madera…).
# - Ambiente 3D: fuente_3d (la cascada), fuente_linea (el río: el sonido se pone en el punto del cauce más cercano a
#   quien escucha) y oyente_3d (se escucha desde el personaje, mirando como la cámara).
# - Detalles de la naturaleza: según el contexto de Musica, de vez en cuando una ráfaga, un pájaro, unas hojas o una
#   gota (DETALLES), por el bus Ambiente.
# - Voces de los enemigos (tanda 2): Sonido.voz(enemigo, "ataque" | "herido" | "caida" | …) elige la familia de cada
#   enemigo (FAMILIAS: limo, goblin, gorthor, piedra, ámbar) y suena una vez por evento real: «ataque» al lanzarse,
#   «herido» o «caida» cuando un golpe físico ya le ha quitado los PV (Sonido.recibe). Una voz por enemigo (la nueva
#   corta la suya anterior) y como mucho MAX_GRUPO["voz"] a la vez entre todos. Los héroes, desde la tanda 5, la suya (FAMILIAS_HEROE). Las magias no
#   piden voces (su presentación está protegida: va en la propuesta de magias, docs/audio/inventario_sonidos.md).
# - Agua de las zonas 2D: agua_zona(zona) pone el río en el agua más cercana a quien anda; suena al acercarse, con un
#   fundido, y se calla lejos (Agua2D).
# - Aleatorio: todo lo del sonido usa su propio generador (_rng), nunca randf()/randi()/shuffle()/pick_random() globales:
#   así no cambia la secuencia del combate cuando una prueba fija su semilla.
# - Para las pruebas: contador (veces que ha sonado cada efecto), descartes y registro (lo último que sonó).
# Tanda 3 (T-083):
# - Efectos en el espacio: Sonido.efecto(nombre, {"pos": Vector3}) suena desde ese punto de una escena 3D (un reproductor
#   3D de la escena, VOCES_3D como mucho, con las mismas reglas de prioridad, máximo, espera, pausa y silencio). La
#   distancia de referencia sale de «en_3d» del catálogo (o de la petición). Sin nadie que escuche en 3D, suena normal.
# - Pasos de los compañeros (Lya, Garon): con alguien que escucha en 3D, salen de su pie (en el espacio: a un lado o
#   detrás, y más bajos cuanto más lejos) y llevan su volumen (DB_PASOS); sin él, 3 dB por debajo. Los del personaje que
#   escucha (Kael) siguen sin posición.
# - Detalles en el espacio: en una escena que lo pide (detalles_3d), las gotas de la mazmorra caen en un punto (la pared
#   de roca más cercana) y no «dentro de la cabeza».
# - Eco de un lugar (eco): una reverberación en los buses Efectos y Ambiente mientras esa escena es la actual (la Garganta
#   3D). Se quita sola al cambiar de escena.
# - Fuentes 2D (fuente_2d): un sonido del mundo en una escena 2D (la taberna de Oakhaven, el letrero del cuervo) que suena
#   más cuanto más cerca de quien anda, en bucle o de vez en cuando.
# Tanda 4 (T-097): las seis bestias del bestiario, solo en el catálogo (BESTIAS): aviso e impacto de cada ataque, herido,
#   caída y entrada; sus voces van por FAMILIAS como las de la tanda 2. Las engancha combate (docs/audio/inventario_sonidos.md).
# - Héroes quietos (tanda 4): el nodo de pasos de cada personaje 3D (Pasos3D) hace, si lleva un rato parado, un gesto muy
#   discreto suyo (QUIETO: Kael, Lya y Garon distintos), uno a la vez entre los tres, por Efectos y con prioridad 0. No hace
#   falta tocar ninguna escena: va donde ya hay pasos_3d (Pastos Verdes y la Garganta 3D).
# Tanda 5: las voces no verbales de Kael, Lya y Garon en combate (FAMILIAS_HEROE): esfuerzo, herido, jadeo con poca vida,
#   alivio y victoria; por debajo de los golpes (prioridad 1, una a la vez). Cómo pedirlas: docs/audio/inventario_sonidos.md.
# V9 (10/11): identidad sonora del Guardián del Bosque Olvidado («guardian_bosque_*» y su voz, familia «corteza») y el
#   tratamiento de su combate (TRATAMIENTOS: la música con paso bajo y un bosque antiguo por debajo); el orbe del altar
#   («orbe_vision», «orbe_cierra»). Dónde se piden: docs/audio/inventario_sonidos.md, sección V9.

const ARCHIVO := "user://ajustes.cfg"
const BUSES := ["Musica", "Efectos", "Interfaz", "Ambiente"]
const VISIBLES := ["Musica", "Efectos", "Interfaz", "Ambiente"]
const NOMBRES := {"Musica": "Música", "Efectos": "Efectos", "Interfaz": "Interfaz", "Ambiente": "Ambiente"}
const AYUDA := {"Musica": "combates y cinemáticas", "Efectos": "pasos, golpes, cofres e invocaciones",
	"Interfaz": "botones, menús y diálogos", "Ambiente": "pájaros, viento, río y lugares"}
const PASO := 10                                           # lo que sube o baja cada pulsación, en %
const HZ := 11025                                          # las muestras de los ajustes: cortas y ligeras

const EF := "res://audio/efectos/"
const VOCES := {"Efectos": 10, "Interfaz": 4, "Ambiente": 4}
const ATENUAR_DB := 8.0                                    # lo que bajan las prioridades 0-2 mientras suena una 4
const FUNDIDO_CORTE := 0.1                                 # s: al cambiar de escena o cortar
# Mezcla (tanda 7; decisión del coordinador, reversible: el usuario aún no lo ha escuchado). Medido el 09/11 con la mezcla
# por buses (prueba_efectos_senal, «mezclas=6»): en combate la música quedaba 9 dB por encima de los golpes y las voces, y
# el Master llegaba a −0,3 dBFS. Para volver atrás, poner la constante a false.
# - APARTAR_MUSICA_EN_COMBATE: en combate (contexto «combate» de Musica), la música baja sola cuando suenan efectos: un
#   compresor al final del bus Musica que escucha al bus Efectos. Conservador para que no «bombee»: ratio bajo, ataque y
#   suelta lentos. Alternativa B (documentada en el inventario): la música del combate de −6 a −10 dB en combate.gd.
# - LIMITADOR_MASTER: un limitador suave al final del Master, contra la saturación medida (solo actúa en los picos).
const APARTAR_MUSICA_EN_COMBATE := true
const APARTAR := {"umbral": -30.0, "ratio": 2.0, "ataque_ms": 30.0, "suelta_ms": 800.0}
const LIMITADOR_MASTER := true
const LIMITE := {"techo_db": -1.0, "suelta_s": 0.15}
const MAX_GRUPO := {"voz": 2, "quieto": 1, "voz_heroe": 1}               # cuántos de un mismo grupo suenan a la vez como mucho
# Los héroes quietos en la exploración 3D (tanda 4; Pasos3D): tras «primero» s parados (al azar entre los dos), un gesto
# discreto de su personaje; mientras sigan parados, otro cada «entre» s. Andar lo reinicia. Kael es el que escucha (o el
# nodo «Kael»); Lya y Garon, por el nombre de su nodo.
const QUIETO := {"primero": [7.0, 14.0], "entre": [22.0, 40.0]}
const QUIETO_DE := {"Kael": "quieto_kael", "Lya": "quieto_lya", "Garon": "quieto_garon"}
const VOCES_3D := 8                                        # reproductores 3D de una escena (efectos con «pos»)
# Un efecto en el espacio sin «en_3d» en el catálogo: a «unidad» metros suena a su volumen, la mitad cada vez que se
# dobla la distancia, y callado más allá de «max». «filtro»: dB que pierde lo agudo a lo lejos (Godot: −24).
const EN_3D := {"unidad": 3.0, "max": 40.0, "filtro": -12.0}
# Los pasos de los compañeros desde su pie: a 2,5 m de quien escucha (a la altura de su cabeza, sobre Kael) suenan a su
# volumen; detrás de Kael (2-3 m) quedan unos 1-3 dB por debajo y más bajos si se quedan atrás; lo agudo apenas cambia.
const PASO_3D := {"unidad": 2.5, "max": 25.0, "filtro": -6.0}
# Volumen de los pasos de cada compañero (por el nombre de su nodo, grupo_3d.gd): Lya pisa más ligera que Garon.
const DB_PASOS := {"Lya": -2.0, "Garon": 0.0}
const DB_COMPANERO_SIN_POSICION := -3.0                    # sin nadie que escuche en 3D: algo por debajo de Kael
# Eco de cada lugar (eco()): una reverberación por bus (cuánto se oye: «humedo» de 0 a 1; lo directo baja un poco,
# «seco», para que lo largo y fuerte no suba de pico). «sala», «amortiguar», «abrir» y «graves» son los de
# AudioEffectReverb (room_size, damping, spread, hipass); «previo_ms» y «rebote», el retardo antes del eco y cuánto se
# repite (predelay_msec, predelay_feedback): la pared de enfrente devuelve el golpe. Medido el 09/11 (con el driver real,
# un paso de roca): la cola queda unos 27 dB por debajo del golpe entre 0,1 y 0,4 s y 36 dB entre 0,4 y 1 s (con 0,16
# de «humedo» quedaba a 36 y 48 dB: no se oía). Con 0,45, la palanca sube unos 2 dB de pico.
const ECO := {
	"garganta": {"sala": 0.85, "amortiguar": 0.3, "abrir": 0.9, "graves": 0.15, "previo_ms": 60.0, "rebote": 0.3,
		"seco": 0.92, "buses": {"Efectos": 0.45, "Ambiente": 0.35}},
}

# a: archivo (sin .wav, dentro de audio/efectos/) o prefijo con n variantes (a + "1"… a + "n"); codigo: tono de los
# menús hecho por código (menu_combate.gd, sonidos_ui). db: volumen. tono: variación (± fracción). p: prioridad
# (0 pasos y detalles · 1 interfaz y movimientos · 2 golpes y objetos · 3 eventos · 4 victoria, derrota y jefes).
# max: cuántos a la vez. espera: s mínimos entre dos iguales. cruza: sigue al cambiar de escena. tres_d: emisor 3D.
# dos_d: emisor 2D por cercanía (agua de las zonas). grupo: comparte el límite MAX_GRUPO (las voces de los enemigos).
# tono_fijo: multiplica siempre el tono (el Gólem de ámbar usa el ataque de la piedra, más agudo).
# en_3d: distancia de referencia cuando suena en el espacio (efecto con «pos»; si no lo dice, EN_3D).
# trata (V9): [jefe, etapa] de TRATAMIENTOS: al pedirlo, empieza o cambia el tratamiento del combate de ese jefe.
# bucle (V9): el archivo es un bucle que no es un emisor (el bosque antiguo del tratamiento; no se pide con efecto()).
# Pasos: tres a la vez como mucho (Kael, Lya y Garon pueden pisar casi juntos; con dos se cortaban colas).
const EFECTOS := {
	# ---- pasos
	"paso_hierba": {"a": "pasos/hierba_", "n": 6, "db": -15.0, "tono": 0.06, "p": 0, "max": 3, "espera": 0.09},
	"paso_piedra": {"a": "pasos/piedra_", "n": 6, "db": -14.0, "tono": 0.06, "p": 0, "max": 3, "espera": 0.09},
	"paso_hojas": {"a": "pasos/hojas_", "n": 5, "db": -15.0, "tono": 0.06, "p": 0, "max": 3, "espera": 0.09},
	"paso_nieve": {"a": "pasos/nieve_", "n": 5, "db": -15.0, "tono": 0.06, "p": 0, "max": 3, "espera": 0.09},
	"paso_grava": {"a": "pasos/grava_", "n": 5, "db": -16.0, "tono": 0.06, "p": 0, "max": 3, "espera": 0.09},
	"paso_arena": {"a": "pasos/arena_", "n": 4, "db": -14.0, "tono": 0.06, "p": 0, "max": 3, "espera": 0.09},
	"paso_madera": {"a": "pasos/madera_", "n": 4, "db": -13.0, "tono": 0.06, "p": 0, "max": 3, "espera": 0.09},
	# ---- combate: ataques físicos, impactos y defensa (las magias no cambian: no tienen sonido aquí)
	"golpe": {"a": "combate/golpe_", "n": 4, "db": -5.0, "tono": 0.05, "p": 2, "max": 3, "espera": 0.04},
	"golpe_critico": {"a": "combate/critico_", "n": 2, "db": -5.0, "tono": 0.04, "p": 3, "max": 2, "espera": 0.04},
	"golpe_defendido": {"a": "combate/defendido_", "n": 3, "db": -7.0, "tono": 0.05, "p": 2, "max": 2, "espera": 0.04},
	"defensa": {"a": "combate/defensa", "db": -8.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.2},
	# la Guardia de Garon (tanda 5; la pide combate por su nombre): se planta tras el escudo, metálico, firme y breve
	"guardia": {"a": "combate/guardia", "db": -14.0, "tono": 0.03, "p": 2, "max": 1, "espera": 0.2},
	"salto": {"a": "combate/salto_", "n": 3, "db": -9.0, "tono": 0.05, "p": 1, "max": 2, "espera": 0.1},
	"huida": {"a": "combate/huida", "db": -8.0, "tono": 0.06, "p": 2, "max": 2, "espera": 0.1},
	"emboscada": {"a": "combate/emboscada", "db": -4.0, "p": 4, "max": 1, "espera": 1.0, "cruza": true},
	"jefe": {"a": "combate/jefe", "db": -4.0, "p": 4, "max": 1, "espera": 1.0},
	"fase2": {"a": "combate/fase2", "db": -4.0, "p": 4, "max": 1, "espera": 1.0},
	"carga_jefe": {"a": "combate/carga_jefe", "db": -8.0, "p": 3, "max": 1, "espera": 0.5},
	"embuir": {"a": "combate/embuir", "db": -8.0, "tono": 0.03, "p": 2, "max": 1, "espera": 0.3},
	"victoria": {"a": "combate/victoria", "db": -5.0, "p": 4, "max": 1, "espera": 2.0},
	"derrota": {"a": "combate/derrota", "db": -5.0, "p": 4, "max": 1, "espera": 2.0},
	"nivel": {"a": "combate/nivel", "db": -7.0, "p": 3, "max": 2, "espera": 0.3},
	"monedas": {"a": "combate/monedas_", "n": 3, "db": -9.0, "tono": 0.04, "p": 3, "max": 2, "espera": 0.15},
	"pocion": {"a": "combate/pocion", "db": -8.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.2},
	"congelar": {"a": "combate/congelar", "db": -9.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.3},
	# ---- voces de los enemigos (tanda 2; voz() y recibe()). <familia>_ataque: al lanzarse; _herido: un golpe físico que
	# no lo tumba; _caida: el que lo tumba (Gorthor: al caer de rodillas); _muerte: «Acabar»; _devorar: su mordisco.
	# «espera» corta las repeticiones (el Giro golpea a varios a la vez: una voz por familia) y «grupo» limita el total.
	"limo_ataque": {"a": "voces/limo_ataque_", "n": 2, "db": -6.0, "tono": 0.07, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"limo_herido": {"a": "voces/limo_herido_", "n": 3, "db": -6.0, "tono": 0.08, "p": 2, "max": 1, "espera": 0.3, "grupo": "voz"},
	"limo_caida": {"a": "voces/limo_caida_", "n": 2, "db": -8.0, "tono": 0.05, "p": 3, "max": 2, "espera": 0.1, "grupo": "voz"},
	"goblin_ataque": {"a": "voces/goblin_ataque_", "n": 3, "db": -13.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"goblin_herido": {"a": "voces/goblin_herido_", "n": 3, "db": -14.0, "tono": 0.06, "p": 2, "max": 1, "espera": 0.3, "grupo": "voz"},
	"goblin_caida": {"a": "voces/goblin_caida_", "n": 2, "db": -11.0, "tono": 0.04, "p": 3, "max": 2, "espera": 0.1, "grupo": "voz"},
	"gorthor_ataque": {"a": "voces/gorthor_ataque_", "n": 2, "db": -10.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.3, "grupo": "voz"},
	"gorthor_herido": {"a": "voces/gorthor_herido_", "n": 2, "db": -13.0, "tono": 0.03, "p": 2, "max": 1, "espera": 0.4, "grupo": "voz"},
	"gorthor_caida": {"a": "voces/gorthor_caida", "db": -8.0, "p": 3, "max": 1, "espera": 1.0, "grupo": "voz"},
	"gorthor_muerte": {"a": "voces/gorthor_muerte", "db": -9.0, "p": 3, "max": 1, "espera": 1.0, "grupo": "voz"},
	"gorthor_devorar": {"a": "voces/gorthor_devorar", "db": -10.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.5, "grupo": "voz"},
	"piedra_ataque": {"a": "voces/piedra_ataque_", "n": 2, "db": -11.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.3, "grupo": "voz"},
	"piedra_herido": {"a": "voces/piedra_herido_", "n": 3, "db": -8.0, "tono": 0.06, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"piedra_caida": {"a": "voces/piedra_caida_", "n": 2, "db": -5.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.5, "grupo": "voz"},
	"ambar_ataque": {"a": "voces/piedra_ataque_", "n": 2, "db": -11.0, "tono_fijo": 1.12, "tono": 0.04, "p": 2, "max": 1, "espera": 0.3, "grupo": "voz"},
	"ambar_herido": {"a": "voces/ambar_herido_", "n": 2, "db": -8.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"ambar_caida": {"a": "voces/ambar_caida", "db": -5.0, "p": 3, "max": 1, "espera": 0.5, "grupo": "voz"},
	# ---- las seis bestias del bestiario (tanda 4, T-097; solo el catálogo: las engancha combate). Por bestia:
	# <bestia>_aviso_<ataque>: la preparación, al empezar el ataque (acaba antes del impacto) · <bestia>_<ataque>: el
	# impacto, en el instante del golpe, junto al Sonido.golpe() de siempre (que dice si el héroe se defiende) ·
	# _herido y _caida: su voz, con Sonido.recibe() (FAMILIAS) · _entrada: al presentarse. Prioridades: avisos 3 (el
	# jugador tiene que oírlos), impactos 2 y voces como las de la tanda 2 (herido 2, caída 3). El Posadero (jefe
	# opcional) suena por encima: 2-3 dB más y prioridad 3 en todo. No hay «_ataque»: el aviso hace ese papel.
	# Zarzalín: el aviso de la embestida va en la señal «aviso» de zarzalin_3d.gd (el hocico ya está bajo) y una pezuña
	# en cada señal «pezuna(n)»; el derrumbe, al empezar su clip «derrota» (el cuerpo toca la tierra a 0,60 s).
	"zarzalin_aviso_embestida": {"a": "bestias/zarzalin_aviso_embestida", "db": -12.0, "tono": 0.04, "p": 3, "max": 1, "espera": 0.5},
	"zarzalin_pezuna": {"a": "bestias/zarzalin_pezuna_", "n": 2, "db": -11.0, "tono": 0.05, "p": 3, "max": 2, "espera": 0.15},
	"zarzalin_embestida": {"a": "bestias/zarzalin_embestida", "db": -10.0, "tono": 0.04, "p": 2, "max": 2, "espera": 0.1},
	"zarzalin_aviso_colmillo": {"a": "bestias/zarzalin_aviso_colmillo", "db": -3.0, "tono": 0.04, "p": 3, "max": 1, "espera": 0.4},
	"zarzalin_colmillo": {"a": "bestias/zarzalin_colmillo", "db": -11.0, "tono": 0.05, "p": 2, "max": 2, "espera": 0.1},
	"zarzalin_herido": {"a": "bestias/zarzalin_herido_", "n": 2, "db": -10.0, "tono": 0.06, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"zarzalin_caida": {"a": "bestias/zarzalin_caida", "db": -7.0, "tono": 0.03, "p": 3, "max": 2, "espera": 0.1, "grupo": "voz"},
	"zarzalin_derrumbe": {"a": "bestias/zarzalin_derrumbe", "db": -7.0, "tono": 0.03, "p": 2, "max": 2, "espera": 0.3},
	"zarzalin_entrada": {"a": "bestias/zarzalin_entrada", "db": -6.0, "p": 3, "max": 1, "espera": 1.0},
	"cencerrante_aviso_alarma": {"a": "bestias/cencerrante_aviso_alarma", "db": -6.0, "tono": 0.04, "p": 3, "max": 1, "espera": 0.5},
	"cencerrante_alarma": {"a": "bestias/cencerrante_alarma", "db": -7.0, "tono": 0.03, "p": 2, "max": 2, "espera": 0.1},
	"cencerrante_aviso_campanada": {"a": "bestias/cencerrante_aviso_campanada", "db": -10.0, "tono": 0.04, "p": 3, "max": 1, "espera": 0.4},
	"cencerrante_campanada": {"a": "bestias/cencerrante_campanada", "db": -4.0, "tono": 0.03, "p": 2, "max": 2, "espera": 0.1},
	"cencerrante_herido": {"a": "bestias/cencerrante_herido_", "n": 2, "db": -6.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"cencerrante_caida": {"a": "bestias/cencerrante_caida", "db": -4.0, "p": 3, "max": 2, "espera": 0.1, "grupo": "voz"},
	"cencerrante_entrada": {"a": "bestias/cencerrante_entrada", "db": -7.0, "p": 3, "max": 1, "espera": 1.0},
	"velaria_aviso_destello": {"a": "bestias/velaria_aviso_destello", "db": -2.5, "tono": 0.04, "p": 3, "max": 1, "espera": 0.5},
	"velaria_destello": {"a": "bestias/velaria_destello", "db": -11.0, "tono": 0.04, "p": 2, "max": 2, "espera": 0.1},
	"velaria_aviso_corte": {"a": "bestias/velaria_aviso_corte", "db": -11.0, "tono": 0.05, "p": 3, "max": 1, "espera": 0.4},
	"velaria_corte": {"a": "bestias/velaria_corte", "db": -13.0, "tono": 0.05, "p": 2, "max": 2, "espera": 0.1},
	"velaria_herido": {"a": "bestias/velaria_herido_", "n": 2, "db": -9.5, "tono": 0.06, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"velaria_caida": {"a": "bestias/velaria_caida", "db": -8.0, "p": 3, "max": 2, "espera": 0.1, "grupo": "voz"},
	"velaria_entrada": {"a": "bestias/velaria_entrada", "db": -8.0, "p": 3, "max": 1, "espera": 1.0},
	"custodio_aviso_portazo": {"a": "bestias/custodio_aviso_portazo", "db": -13.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.5},
	"custodio_portazo": {"a": "bestias/custodio_portazo", "db": -10.0, "tono": 0.04, "p": 2, "max": 2, "espera": 0.1},
	"custodio_aviso_martillo": {"a": "bestias/custodio_aviso_martillo", "db": -13.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.5},
	"custodio_martillo": {"a": "bestias/custodio_martillo", "db": -8.0, "tono": 0.03, "p": 2, "max": 2, "espera": 0.1},
	"custodio_herido": {"a": "bestias/custodio_herido_", "n": 2, "db": -9.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"custodio_caida": {"a": "bestias/custodio_caida", "db": -8.0, "p": 3, "max": 2, "espera": 0.1, "grupo": "voz"},
	"custodio_entrada": {"a": "bestias/custodio_entrada", "db": -13.0, "p": 3, "max": 1, "espera": 1.0},
	"hilandera_aviso_mordida": {"a": "bestias/hilandera_aviso_mordida", "db": -10.0, "tono": 0.05, "p": 3, "max": 1, "espera": 0.5},
	"hilandera_mordida": {"a": "bestias/hilandera_mordida", "db": -7.0, "tono": 0.04, "p": 2, "max": 2, "espera": 0.1},
	"hilandera_aviso_trama": {"a": "bestias/hilandera_aviso_trama", "db": -12.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.5},
	"hilandera_trama": {"a": "bestias/hilandera_trama", "db": -12.0, "tono": 0.02, "p": 2, "max": 1, "espera": 0.3},
	"hilandera_herido": {"a": "bestias/hilandera_herido_", "n": 2, "db": -9.0, "tono": 0.06, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"hilandera_caida": {"a": "bestias/hilandera_caida", "db": -6.0, "p": 3, "max": 2, "espera": 0.1, "grupo": "voz"},
	"hilandera_entrada": {"a": "bestias/hilandera_entrada", "db": -6.0, "p": 3, "max": 1, "espera": 1.0},
	"posadero_aviso_cierre": {"a": "bestias/posadero_aviso_cierre", "db": -1.5, "tono": 0.03, "p": 3, "max": 1, "espera": 0.5},
	"posadero_cierre": {"a": "bestias/posadero_cierre", "db": -5.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.3},
	"posadero_aviso_llave": {"a": "bestias/posadero_aviso_llave", "db": -1.5, "tono": 0.03, "p": 3, "max": 1, "espera": 0.5},
	"posadero_llave": {"a": "bestias/posadero_llave", "db": -9.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.3},
	"posadero_herido": {"a": "bestias/posadero_herido_", "n": 2, "db": -2.0, "tono": 0.05, "p": 3, "max": 1, "espera": 0.25, "grupo": "voz"},
	"posadero_caida": {"a": "bestias/posadero_caida", "db": -9.0, "p": 3, "max": 1, "espera": 1.0, "grupo": "voz"},
	"posadero_entrada": {"a": "bestias/posadero_entrada", "db": -3.0, "p": 3, "max": 1, "espera": 1.0},
	# ---- V9: el Guardián del Bosque Olvidado (combate.gd, clave «guardian_bosque»), con identidad propia en lugar de «jefe»,
	# «carga_jefe» y «fase2». Un árbol viejo: madera que cruje y gime, raíces y tierra, un corazón que late.
	# _jefe: su título (_presentar, en lugar de «jefe»); empieza el tratamiento del combate («trata»: la música con paso
	# bajo y el bosque antiguo por debajo, TRATAMIENTOS) · _entrada: despierta (su clip «entrada») · _ataque: el latigazo de
	# rama (señal «impacto» de su modelo) · _golpe: las raíces que brotan en el golpe cargado (señal «impacto») · _carga:
	# el latido grave al cargar (en lugar de «carga_jefe») · _fase2: el rugido de corteza (en lugar de «fase2»; la música se
	# abre) · _derrumbe: se desmorona al caer (no si se purifica) · _purificar: el Elixir, cálido y luminoso (el bosque
	# antiguo se calma). Su voz va por FAMILIAS («corteza»): ataque al alzar la rama, herido y caída con Sonido.recibe.
	"guardian_bosque_jefe": {"a": "guardian/jefe", "db": -5.0, "p": 4, "max": 1, "espera": 1.0, "trata": ["guardian_bosque", "inicio"]},
	"guardian_bosque_entrada": {"a": "guardian/entrada", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"guardian_bosque_ataque": {"a": "guardian/ataque_", "n": 2, "db": -8.0, "tono": 0.05, "p": 2, "max": 2, "espera": 0.1},
	"guardian_bosque_golpe": {"a": "guardian/golpe", "db": -6.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.3},
	"guardian_bosque_carga": {"a": "guardian/carga", "db": -9.0, "p": 3, "max": 1, "espera": 0.5},
	"guardian_bosque_fase2": {"a": "guardian/fase2", "db": -4.0, "p": 4, "max": 1, "espera": 1.0, "trata": ["guardian_bosque", "fase2"]},
	"guardian_bosque_derrumbe": {"a": "guardian/derrumbe", "db": -6.0, "p": 3, "max": 1, "espera": 1.0},
	"guardian_bosque_purificar": {"a": "guardian/purificar", "db": -5.0, "p": 4, "max": 1, "espera": 2.0, "trata": ["guardian_bosque", "calma"]},
	"corteza_ataque": {"a": "guardian/corteza_ataque_", "n": 2, "db": -9.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.3, "grupo": "voz"},
	"corteza_herido": {"a": "guardian/corteza_herido_", "n": 3, "db": -9.0, "tono": 0.06, "p": 2, "max": 1, "espera": 0.25, "grupo": "voz"},
	"corteza_caida": {"a": "guardian/corteza_caida", "db": -6.0, "p": 3, "max": 1, "espera": 0.5, "grupo": "voz"},
	# ---- las voces de los héroes en combate (tanda 5; no verbales). Por debajo de los golpes y de las voces de los
	# enemigos: prioridad 1 (lo primero que cede si faltan voces) y una a la vez entre los tres (grupo «voz_heroe»); la
	# de victoria, prioridad 3 (no baja con la fanfarria) y muy corta. Las piden voz() y recibe() (esfuerzo al lanzarse,
	# herido o caída al recibir un golpe físico, jadeo si queda con poca vida), voz(h, "alivio") y victoria_heroes().
	"kael_esfuerzo": {"a": "heroes/kael_esfuerzo_", "n": 3, "db": -13.5, "tono": 0.04, "p": 1, "max": 1, "espera": 0.3, "grupo": "voz_heroe"},
	"kael_herido": {"a": "heroes/kael_herido_", "n": 2, "db": -14.0, "tono": 0.05, "p": 1, "max": 1, "espera": 0.3, "grupo": "voz_heroe"},
	"kael_jadeo": {"a": "heroes/kael_jadeo_", "n": 2, "db": -10.5, "tono": 0.03, "p": 1, "max": 1, "espera": 2.0, "grupo": "voz_heroe"},
	"kael_alivio": {"a": "heroes/kael_alivio_", "n": 2, "db": -12.5, "tono": 0.03, "p": 1, "max": 1, "espera": 0.5, "grupo": "voz_heroe"},
	"kael_victoria": {"a": "heroes/kael_victoria_", "n": 2, "db": -8.5, "tono": 0.03, "p": 3, "max": 1, "espera": 1.0, "grupo": "voz_heroe"},
	"lya_esfuerzo": {"a": "heroes/lya_esfuerzo_", "n": 3, "db": -14.5, "tono": 0.04, "p": 1, "max": 1, "espera": 0.3, "grupo": "voz_heroe"},
	"lya_herido": {"a": "heroes/lya_herido_", "n": 3, "db": -17.0, "tono": 0.05, "p": 1, "max": 1, "espera": 0.3, "grupo": "voz_heroe"},
	"lya_jadeo": {"a": "heroes/lya_jadeo_", "n": 2, "db": -14.0, "tono": 0.03, "p": 1, "max": 1, "espera": 2.0, "grupo": "voz_heroe"},
	"lya_alivio": {"a": "heroes/lya_alivio_1", "db": -13.0, "tono": 0.04, "p": 1, "max": 1, "espera": 0.5, "grupo": "voz_heroe"},
	"lya_victoria": {"a": "heroes/lya_victoria_1", "db": -12.0, "tono": 0.03, "p": 3, "max": 1, "espera": 1.0, "grupo": "voz_heroe"},
	"garon_esfuerzo": {"a": "heroes/garon_esfuerzo_", "n": 3, "db": -16.0, "tono": 0.03, "p": 1, "max": 1, "espera": 0.3, "grupo": "voz_heroe"},
	"garon_herido": {"a": "heroes/garon_herido_", "n": 2, "db": -13.5, "tono": 0.04, "p": 1, "max": 1, "espera": 0.3, "grupo": "voz_heroe"},
	"garon_jadeo": {"a": "heroes/garon_jadeo_", "n": 2, "db": -15.0, "tono": 0.03, "p": 1, "max": 1, "espera": 2.0, "grupo": "voz_heroe"},
	"garon_alivio": {"a": "heroes/garon_alivio_1", "db": -12.5, "tono": 0.03, "p": 1, "max": 1, "espera": 0.5, "grupo": "voz_heroe"},
	"garon_victoria": {"a": "heroes/garon_victoria_1", "db": -9.0, "tono": 0.02, "p": 3, "max": 1, "espera": 1.0, "grupo": "voz_heroe"},
	# ---- los héroes quietos en la exploración 3D (tanda 4): un gesto muy discreto de vez en cuando (Pasos3D, QUIETO);
	# uno a la vez entre los tres (grupo «quieto»), prioridad 0 (lo primero que cede)
	"quieto_kael": {"a": "heroes/kael_quieto_", "n": 2, "db": -12.0, "tono": 0.04, "p": 0, "max": 1, "espera": 1.0, "grupo": "quieto"},
	"quieto_lya": {"a": "heroes/lya_quieto_", "n": 2, "db": -18.0, "tono": 0.04, "p": 0, "max": 1, "espera": 1.0, "grupo": "quieto"},
	"quieto_garon": {"a": "heroes/garon_quieto_", "n": 2, "db": -10.5, "tono": 0.04, "p": 0, "max": 1, "espera": 1.0, "grupo": "quieto"},
	# ---- cofres, puertas, objetos, recompensas y momentos de la misión
	"cofre": {"a": "mundo/cofre_", "n": 3, "db": -7.0, "tono": 0.05, "p": 3, "max": 1, "espera": 0.3},
	"tesoro": {"a": "mundo/tesoro", "db": -8.0, "p": 3, "max": 1, "espera": 0.3},
	"union": {"a": "mundo/union", "db": -10.0, "p": 3, "max": 1, "espera": 1.0},
	"examinar": {"a": "mundo/examinar", "db": -11.0, "tono": 0.02, "p": 1, "max": 1, "espera": 0.3},
	"pagina": {"a": "mundo/pagina", "db": -8.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.3},
	"misterio": {"a": "mundo/misterio", "db": -10.0, "p": 3, "max": 1, "espera": 2.0},
	"palanca": {"a": "mundo/palanca", "db": -6.0, "p": 3, "max": 1, "espera": 0.5},
	"atascado": {"a": "mundo/atascado", "db": -9.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.3},
	# (en la Garganta 3D suena desde el levadizo: ya viene «lejos» del archivo, así que a lo lejos no pierde más agudos)
	"puente_baja": {"a": "mundo/puente_baja", "db": -9.0, "p": 3, "max": 1, "espera": 1.0,
		"en_3d": {"unidad": 14.0, "max": 90.0, "filtro": 0.0}},
	"ascensor": {"a": "mundo/ascensor", "db": -6.0, "tono": 0.03, "p": 2, "max": 1, "espera": 0.5},
	"cerrada": {"a": "mundo/cerrada", "db": -8.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.4},
	"guardado": {"a": "mundo/guardado", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"posada": {"a": "mundo/posada", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"portal": {"a": "mundo/portal", "db": -6.0, "p": 3, "max": 1, "espera": 1.0, "cruza": true},
	"entrar": {"a": "mundo/entrar", "db": -12.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.5, "cruza": true},
	"puerta_abre": {"a": "mundo/puerta_abre", "db": -9.0, "p": 3, "max": 1, "espera": 1.0,
		"en_3d": {"unidad": 20.0, "max": 90.0, "filtro": 0.0}},
	"brazalete": {"a": "mundo/brazalete", "db": -17.0, "tono": 0.03, "p": 1, "max": 1, "espera": 1.5},
	# V9: el orbe del altar (bosque_pastos.gd, _vision): la visión se abre con una resonancia cristalina y se cierra con
	# otra copa, más grave, que se apaga (en lugar de «misterio»)
	"orbe_vision": {"a": "mundo/orbe_vision", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"orbe_cierra": {"a": "mundo/orbe_cierra", "db": -14.0, "p": 2, "max": 1, "espera": 0.5},
	# ---- Oakhaven (tanda 3; los pide narrativa: docs/audio/inventario_sonidos.md, «Cómo pedirlos»)
	"campana": {"a": "mundo/campana", "bus": "Ambiente", "db": -12.0, "p": 1, "max": 1, "espera": 6.0},
	"farol": {"a": "mundo/farol", "db": -6.0, "tono": 0.06, "p": 2, "max": 3, "espera": 0.08},
	# ---- las artes nuevas (tanda 3, T-091: Alba, Escarcha y Lumbre; NO son las 12 magias de siempre, que no suenan).
	# Una vez por lanzamiento (prioridad 3) y los estados: Aliento (cura al empezar el turno, muy bajo), la coraza que
	# absorbe (dos a la vez como mucho, cada 0,05 s) y se rompe, la Brasa que levanta al caído, y la esquiva (pluma).
	"arte_alba": {"a": "combate/arte_alba", "db": -11.0, "p": 3, "max": 1, "espera": 0.3},
	"arte_ocaso": {"a": "combate/arte_ocaso", "db": -10.0, "p": 3, "max": 1, "espera": 0.3},
	"arte_hora_dorada": {"a": "combate/arte_hora_dorada", "db": -9.0, "p": 3, "max": 1, "espera": 0.5},
	"arte_escarcha": {"a": "combate/arte_escarcha", "db": -9.0, "tono": 0.03, "p": 3, "max": 1, "espera": 0.3},
	"arte_lumbre": {"a": "combate/arte_lumbre", "db": -9.0, "p": 3, "max": 1, "espera": 0.3},
	"renacer": {"a": "combate/renacer", "db": -9.0, "p": 3, "max": 1, "espera": 0.5},
	"aliento": {"a": "combate/aliento", "db": -13.0, "tono": 0.04, "p": 1, "max": 1, "espera": 0.3},
	"barrera_absorbe": {"a": "combate/barrera_absorbe_", "n": 2, "db": -8.0, "tono": 0.05, "p": 1, "max": 2, "espera": 0.05},
	"barrera_rota": {"a": "combate/barrera_rota", "db": -9.0, "tono": 0.04, "p": 3, "max": 1, "espera": 0.2},
	"brasa": {"a": "combate/brasa", "db": -11.0, "p": 3, "max": 1, "espera": 0.5},
	"esquiva": {"a": "combate/esquiva_", "n": 2, "db": -9.0, "tono": 0.05, "p": 2, "max": 2, "espera": 0.08},
	# ---- interfaz (los tonos de siempre, hechos por código, y unos pocos de la biblioteca)
	"ui_tic": {"codigo": "tic", "bus": "Interfaz", "db": -6.0, "p": 1, "max": 2, "espera": 0.03},
	"ui_confirmar": {"codigo": "confirmar", "bus": "Interfaz", "db": -6.0, "p": 1, "max": 2, "espera": 0.05},
	"ui_clac": {"codigo": "clac", "bus": "Interfaz", "db": -6.0, "p": 1, "max": 1, "espera": 0.05},
	"ui_mejora": {"codigo": "confirmar", "bus": "Interfaz", "db": -6.0, "tono_fijo": 1.26, "p": 1, "max": 1, "espera": 0.05},
	"ui_abrir": {"a": "interfaz/abrir", "bus": "Interfaz", "db": -14.0, "p": 1, "max": 1, "espera": 0.1},
	"ui_cerrar": {"a": "interfaz/cerrar", "bus": "Interfaz", "db": -14.0, "p": 1, "max": 1, "espera": 0.1},
	"ui_atras": {"a": "interfaz/atras", "bus": "Interfaz", "db": -12.0, "p": 1, "max": 1, "espera": 0.05},
	"ui_error": {"a": "interfaz/error", "bus": "Interfaz", "db": -13.0, "p": 1, "max": 1, "espera": 0.15},
	"ui_equipar": {"a": "interfaz/equipar", "bus": "Interfaz", "db": -12.0, "tono": 0.05, "p": 1, "max": 1, "espera": 0.1},
	"ui_equipar_arma": {"a": "interfaz/equipar_arma", "bus": "Interfaz", "db": -12.0, "tono": 0.05, "p": 1, "max": 1, "espera": 0.1},
	"libro_hoja": {"a": "interfaz/libro_hoja", "bus": "Interfaz", "db": -8.0, "tono": 0.05, "p": 1, "max": 1, "espera": 0.08},
	"libro_cerrar": {"a": "interfaz/libro_cerrar", "bus": "Interfaz", "db": -11.0, "tono": 0.03, "p": 1, "max": 1, "espera": 0.2},
	# ---- ambiente: emisores 3D (bucles) y detalles sueltos
	"rio": {"a": "ambiente/rio", "bus": "Ambiente", "db": -3.0, "tres_d": {"unidad": 4.0, "max": 32.0}},
	# el río de las zonas 2D (el mismo bucle): a todo volumen a «cerca» casillas de la orilla o menos, callado a «lejos»
	"rio_2d": {"a": "ambiente/rio", "bus": "Ambiente", "db": -5.0, "dos_d": {"cerca": 1.5, "lejos": 9.0}},
	"cascada": {"a": "ambiente/cascada", "bus": "Ambiente", "db": 3.0, "tres_d": {"unidad": 8.0, "max": 45.0}},
	# la Garganta 3D (tanda 3): la cascada grande que cae al abismo (se oye en toda la garganta, de lejos solo el
	# rumor grave) y el viento del abismo a lo largo de su eje (garganta_3d.gd, _sonido_3d)
	"cascada_grande": {"a": "ambiente/cascada_grande", "bus": "Ambiente", "db": 0.0, "tres_d": {"unidad": 10.0, "max": 120.0}},
	"viento_abismo": {"a": "ambiente/viento_abismo", "bus": "Ambiente", "db": -2.5, "tres_d": {"unidad": 8.0, "max": 70.0}},
	# la entrada, la cornisa y los puentes colgantes (tanda 5; los engancha quien lleva garganta_3d.gd): las cuerdas y tablas de los
	# puentes crujen de vez en cuando y el viento silba en ellas, desde el punto de su línea más cercano a quien escucha
	# («cada»: no son bucles; fuente_linea los hace sonar de vez en cuando)
	"puente_cruje": {"a": "ambiente/puente_cruje_", "n": 5, "bus": "Ambiente", "db": -14.0, "tono": 0.07, "p": 0, "max": 2, "espera": 0.8,
		"tres_d": {"unidad": 4.0, "max": 25.0, "filtro": -8.0, "cada": [3.0, 8.0]}},
	"viento_cuerdas": {"a": "ambiente/viento_cuerdas_", "n": 2, "bus": "Ambiente", "db": -8.0, "tono": 0.05, "p": 0, "max": 1, "espera": 4.0,
		"tres_d": {"unidad": 6.0, "max": 40.0, "filtro": -6.0, "cada": [9.0, 18.0]}},
	# Oakhaven (tanda 3): el bullicio de la taberna (bucle) y el letrero del cuervo (de vez en cuando, «cada» s), por
	# cercanía en la escena 2D (fuente_2d): a todo volumen a «cerca» casillas o menos, callado a «lejos»
	# (medido el 09/11: a −6 dB, junto a la puerta apenas asomaba sobre el ambiente de la ciudad; a −2, unos 3 dB por encima)
	"taberna": {"a": "ambiente/taberna", "bus": "Ambiente", "db": -2.0, "dos_d": {"cerca": 2.0, "lejos": 11.0}},
	"cuervo": {"a": "mundo/cuervo_", "n": 3, "bus": "Ambiente", "db": -12.0, "tono": 0.06, "p": 0, "max": 1, "espera": 1.5,
		"dos_d": {"cerca": 2.0, "lejos": 12.0, "cada": [4.0, 11.0]}},
	# Oakhaven vivo (tanda 6): el murmullo de la plaza y del mercado y la fuente, en bucle y por cercanía (fuente_2d en la
	# 2D; fuente_3d en la 3D, T-103), y los detalles según la hora (DETALLES «ciudad_dia», «_tarde», «_noche»). Medido el 09/11
	# (mezcla por buses): con la plaza a −2 y la fuente a −8 los pasos quedaban 4 dB por debajo del ambiente; así, 1 dB por encima
	"plaza_murmullo": {"a": "ambiente/plaza_murmullo", "bus": "Ambiente", "db": -5.0, "dos_d": {"cerca": 4.0, "lejos": 16.0},
		"tres_d": {"unidad": 8.0, "max": 50.0}},
	"mercado_murmullo": {"a": "ambiente/mercado_murmullo", "bus": "Ambiente", "db": -1.0, "dos_d": {"cerca": 3.0, "lejos": 12.0},
		"tres_d": {"unidad": 6.0, "max": 40.0}},
	"fuente_plaza": {"a": "ambiente/fuente_plaza", "bus": "Ambiente", "db": -10.0, "dos_d": {"cerca": 1.5, "lejos": 8.0},
		"tres_d": {"unidad": 3.0, "max": 25.0}},
	"pajaro_ciudad": {"a": "ambiente/pajaro_ciudad_", "n": 2, "bus": "Ambiente", "db": -16.0, "tono": 0.06, "p": 0, "max": 1, "espera": 3.0},
	"grillo": {"a": "ambiente/grillo", "bus": "Ambiente", "db": -14.0, "tono": 0.05, "p": 0, "max": 1, "espera": 4.0},
	"mochuelo": {"a": "ambiente/mochuelo_", "n": 2, "bus": "Ambiente", "db": -20.0, "tono": 0.03, "p": 0, "max": 1, "espera": 8.0},
	# V9: el bosque antiguo bajo el combate del Guardián (TRATAMIENTOS; un bucle, no un emisor: «bucle»)
	"bosque_antiguo": {"a": "ambiente/bosque_antiguo", "bus": "Ambiente", "db": -8.0, "bucle": true},
	"rafaga_hierba": {"a": "ambiente/rafaga_hierba_", "n": 4, "bus": "Ambiente", "db": -14.0, "tono": 0.05, "p": 0, "max": 1, "espera": 3.0},
	"rafaga_arbol": {"a": "ambiente/rafaga_arbol_", "n": 4, "bus": "Ambiente", "db": -14.0, "tono": 0.05, "p": 0, "max": 1, "espera": 3.0},
	"pajaro": {"a": "ambiente/pajaro", "bus": "Ambiente", "db": -18.0, "tono": 0.08, "p": 0, "max": 1, "espera": 4.0},
	"hojas": {"a": "ambiente/hojas_", "n": 2, "bus": "Ambiente", "db": -16.0, "tono": 0.06, "p": 0, "max": 1, "espera": 3.0},
	"gota": {"a": "ambiente/gota_", "n": 3, "bus": "Ambiente", "db": -16.0, "tono": 0.1, "p": 0, "max": 2, "espera": 0.5},
	"gota_cueva": {"a": "ambiente/gota_cueva_", "n": 2, "bus": "Ambiente", "db": -14.0, "tono": 0.08, "p": 0, "max": 2, "espera": 0.5},
}

# Detalles de la naturaleza por contexto de Musica: cada cuánto (s, al azar entre los dos) y qué puede sonar.
const DETALLES := {
	"pradera": {"cada": [9.0, 20.0], "efectos": ["rafaga_hierba", "rafaga_hierba", "pajaro"]},
	"ciudad": {"cada": [14.0, 28.0], "efectos": ["pajaro", "pajaro_ciudad"]},
	# una ciudad con su hora (fijar_momento: Oakhaven, tanda 6); «campana»: cada cuánto la campana lejana marca la hora
	"ciudad_dia": {"cada": [10.0, 22.0], "efectos": ["pajaro", "pajaro_ciudad", "pajaro_ciudad", "rafaga_hierba"], "campana": [110.0, 200.0]},
	"ciudad_tarde": {"cada": [12.0, 24.0], "efectos": ["pajaro_ciudad", "grillo", "grillo", "rafaga_hierba"], "campana": [110.0, 200.0]},
	"ciudad_noche": {"cada": [10.0, 22.0], "efectos": ["grillo", "grillo", "mochuelo"], "campana": [180.0, 300.0]},
	"bosque": {"cada": [8.0, 18.0], "efectos": ["rafaga_arbol", "rafaga_arbol", "hojas"]},
	"viento": {"cada": [10.0, 22.0], "efectos": ["rafaga_hierba"]},
	"mazmorra": {"cada": [4.0, 11.0], "efectos": ["gota", "gota", "gota_cueva"]},
}

# Suelo de las zonas 2D (zona.gd, ESTILOS: «suelo» y «camino») → paso.
const SUELOS := {"hierba": "hierba", "hierba_oscura": "hojas", "tierra": "grava", "tierra_morada": "grava",
	"grava": "grava", "nieve": "nieve", "nieve_pisada": "nieve", "arena": "arena", "arena_dura": "arena",
	"ceniza": "arena", "basalto": "piedra", "empedrado": "piedra"}
# Fotogramas del muñeco 2D (muneco.gd, «correr», 10 por vuelta) en los que un pie toca el suelo.
const CUADROS_PASO := [1, 6]

# Voz de cada enemigo: por su clave en combate.gd (ENEMIGOS) o, si no se sabe, por su dibujo (MODELOS).
const FAMILIAS := {"slime": "limo", "grimfang": "goblin", "gorthor": "gorthor", "guardian": "piedra", "golem_ambar": "ambar",
	# las bestias del bestiario (tanda 4): su clave en combate.gd, con el nombre de la ficha o el corto
	"zarzalin": "zarzalin", "cencerrante": "cencerrante", "velaria": "velaria", "custodio_cal": "custodio", "custodio": "custodio",
	"hilandera_eco": "hilandera", "hilandera": "hilandera", "posadero_hueco": "posadero", "posadero": "posadero",
	# V9: el Guardián del Bosque Olvidado (su voz: madera que cruje y gime; «guardian_bosque_*» son sus efectos)
	"guardian_bosque": "corteza", "coloso_falla": "piedra"}   # coloso_falla: la voz de piedra del guardián (V9)
# V9: tratamiento del combate de un jefe (lo empieza y lo cambia un efecto con «trata»: [jefe, etapa]). Mientras dure:
# - la música (bus Musica) pasa por un paso bajo («corte», Hz) y un ajuste de volumen («musica_db»): el Guardián
#   empieza con la música apagada, como oída desde dentro del bosque, y en su fase 2 se abre;
# - un bucle propio por debajo («bucle», del catálogo, por Ambiente; «bucle_db» sobre su volumen; −60 = callado).
# «s»: segundos del cambio. Se quita solo: si se va su dueño (el combate, «en» del efecto), si cambia la escena, y el
# bucle se apaga con la victoria o la derrota. No hay música de jefe con licencia libre en el proyecto (la del combate
# tiene la licencia pendiente y la de Suno no entra): el tratamiento es para la que suene, sin añadir ninguna.
const TRATAMIENTOS := {
	"guardian_bosque": {"bucle": "bosque_antiguo", "etapas": {
		"inicio": {"corte": 2800.0, "musica_db": -2.0, "bucle_db": 0.0, "s": 2.5},
		"fase2": {"corte": 9000.0, "musica_db": 0.0, "bucle_db": -5.0, "s": 1.6},
		"calma": {"corte": 20000.0, "musica_db": -3.0, "bucle_db": 2.0, "s": 2.0},
		"fin": {"bucle_db": -60.0, "s": 1.8},
	}},
}
# Los efectos de cada bestia (tanda 4), por familia: [avisos], [impactos] y los demás (para las pruebas y el inventario).
const BESTIAS := {
	"zarzalin": [["zarzalin_aviso_embestida", "zarzalin_aviso_colmillo"], ["zarzalin_embestida", "zarzalin_colmillo"],
		["zarzalin_pezuna", "zarzalin_herido", "zarzalin_caida", "zarzalin_derrumbe", "zarzalin_entrada"]],
	"cencerrante": [["cencerrante_aviso_alarma", "cencerrante_aviso_campanada"], ["cencerrante_alarma", "cencerrante_campanada"],
		["cencerrante_herido", "cencerrante_caida", "cencerrante_entrada"]],
	"velaria": [["velaria_aviso_destello", "velaria_aviso_corte"], ["velaria_destello", "velaria_corte"],
		["velaria_herido", "velaria_caida", "velaria_entrada"]],
	"custodio": [["custodio_aviso_portazo", "custodio_aviso_martillo"], ["custodio_portazo", "custodio_martillo"],
		["custodio_herido", "custodio_caida", "custodio_entrada"]],
	"hilandera": [["hilandera_aviso_mordida", "hilandera_aviso_trama"], ["hilandera_mordida", "hilandera_trama"],
		["hilandera_herido", "hilandera_caida", "hilandera_entrada"]],
	"posadero": [["posadero_aviso_cierre", "posadero_aviso_llave"], ["posadero_cierre", "posadero_llave"],
		["posadero_herido", "posadero_caida", "posadero_entrada"]],
}
# Tanda 5: las voces de los héroes (no verbales) por su nombre en combate.gd; «ataque» es su esfuerzo. Con menos de
# JADEO_VIDA de su vida máxima, tras un golpe jadean (una vez hasta curarse).
const FAMILIAS_HEROE := {"Kael": "kael", "Lya": "lya", "Garon": "garon"}
const EVENTO_HEROE := {"ataque": "esfuerzo"}
const JADEO_VIDA := 0.3
const FAMILIA_MODELO :=  {"slime": "limo", "grimfang": "goblin", "hollin": "goblin", "hollin_a": "goblin", "hollin_b": "goblin",
	"gorthor3d": "gorthor", "gorthor": "gorthor", "guardian": "piedra"}
# Qué suena junto al líquido de una zona 2D (zona.gd, ESTILOS «agua»): de momento solo el agua de verdad (el hielo, el
# abismo, la lava y el veneno, nada).
const AGUA_2D := {"agua": "rio_2d"}

var _volumen := {}
var _muestras := {}                                        # bus → reproductor de su muestra en los ajustes
var _sonidos := {}                                         # bus → AudioStreamWAV de su muestra (se hace una vez)

var _voces := {}                                           # bus → [AudioStreamPlayer]
var _propios: Array = []                                   # reproductores con dueño (hijos de una escena: {"en": nodo})
var _emisores: Array = []                                  # AudioStreamPlayer3D de ambiente (para pausarlos)
var _ultimo := {}                                          # efecto → ms de la última vez que sonó
var _variante := {}                                        # efecto → última variante
var _streams := {}                                         # ruta → AudioStream
var _codigo := {}                                          # tonos hechos por código
var _bajar_hasta := {}                                     # bus → s: hasta entonces, lo de menos prioridad va más bajo
var _orden := 0                                            # cuál empezó antes (para quitar el más viejo)
var reloj := 0.0                                           # s de juego (los tiempos de espera van con él)
var _escena: Node = null
var _gen := 0                                              # sube en cada cambio de escena
var _oyente: Node3D = null
var _voces3d: Array = []                                   # AudioStreamPlayer3D de la escena actual (efectos con «pos»)
var _det3d_escena: Node = null                             # la escena que pide los detalles en el espacio (detalles_3d)
var _det3d_donde := Callable()
var _eco: Array = []                                       # [bus, AudioEffectReverb] puestos por eco()
var _eco_escena: Node = null
var _jadeo_de := {}                                        # héroe → ya ha jadeado con poca vida (tanda 5)
var _voz_de := {}                                          # enemigo → [su última voz, su orden] (una voz por enemigo)
var _det_ctx := ""
var _momento := ""                                         # la hora de la escena que la ha fijado (tanda 6)
var _momento_escena: Node = null
var _campana_t := -1.0                                     # s hasta la próxima campana de la hora
var _apartar: AudioEffectCompressor = null                 # tanda 7: la música que se aparta (solo en combate)
var _limitador: AudioEffectHardLimiter = null              # tanda 7: el limitador del Master
var _trata := {}                                           # V9: el tratamiento del combate de un jefe (TRATAMIENTOS)
var _det_t := 0.0
var _rng := RandomNumberGenerator.new()
var pausado := false
var contador := {}                                         # efecto → veces que ha sonado
var descartes := {}                                        # "efecto:motivo" → veces
var registro: Array = []                                   # [ms, efecto, archivo, bus] de lo último que sonó


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS                # vigila la escena y la pausa aunque el árbol esté pausado
	_rng.randomize()
	cargar()
	for bus in VOCES:
		_voces[bus] = []
		for i in VOCES[bus]:
			var p := AudioStreamPlayer.new()
			p.bus = bus
			p.name = "%s_%d" % [bus, i]
			p.process_mode = Node.PROCESS_MODE_ALWAYS if bus == "Interfaz" else Node.PROCESS_MODE_PAUSABLE
			add_child(p)
			_voces[bus].append(p)
	limitador(LIMITADOR_MASTER)


# Lee los volúmenes guardados (sin archivo, o con un valor que no es un número, 100 %) y los aplica a los buses.
func cargar() -> void:
	var c := ConfigFile.new()
	var hay := c.load(ARCHIVO) == OK
	for b in BUSES:
		var v = c.get_value("volumen", b, 100) if hay else 100
		_volumen[b] = clampi(int(v), 0, 100) if (v is int or v is float) else 100
		_aplicar(b)


func volumen(bus: String) -> int:
	return int(_volumen.get(bus, 100))


# Cambia el volumen de un bus (se queda entre 0 y 100) y lo guarda.
func fijar(bus: String, v: int) -> void:
	if not bus in BUSES:
		return
	v = clampi(v, 0, 100)
	if v == volumen(bus):
		return
	_volumen[bus] = v
	_aplicar(bus)
	_guardar()


func _aplicar(bus: String) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		push_warning("Sonido: falta el bus «%s» (default_bus_layout.tres)" % bus)
		return
	var v := volumen(bus)
	AudioServer.set_bus_mute(i, v == 0)
	AudioServer.set_bus_volume_db(i, linear_to_db(v / 100.0) if v > 0 else -80.0)


func _guardar() -> void:
	var c := ConfigFile.new()
	c.load(ARCHIVO)                                        # conserva lo demás que hubiera en el archivo
	for b in BUSES:
		c.set_value("volumen", b, volumen(b))
	var err := c.save(ARCHIVO)
	if err != OK:
		push_warning("Sonido: no se pudieron guardar los ajustes (%s)" % error_string(err))


# Una muestra corta por ese bus, para oír el volumen nuevo al cambiarlo en los ajustes: dos notas de campana
# (música), un destello de tres notas (efectos), un «tic» (interfaz) o una brisa (ambiente). Cada pulsación vuelve a
# empezar la muestra: no
# se amontonan. Son sonidos hechos por código, cortos y a 11 025 Hz, para que la primera pulsación no dé un parón
# (la campana del mirador, de 2,5 s, tardaba unos 180 ms en el PC la primera vez).
func probar(bus: String) -> void:
	if volumen(bus) == 0 or not bus in VISIBLES:
		return
	if not _sonidos.has(bus):
		_sonidos[bus] = _wav(_muestra(bus), HZ)
	var p: AudioStreamPlayer = _muestras.get(bus)
	if p == null:
		p = AudioStreamPlayer.new()
		p.bus = bus
		p.volume_db = -6.0
		add_child(p)
		_muestras[bus] = p
	p.stream = _sonidos[bus]
	p.play()


static func _muestra(bus: String) -> PackedFloat32Array:
	var m := PackedFloat32Array()
	match bus:
		"Musica":                                          # sol y do, con timbre de campana suave
			var notas := PackedFloat32Array([784.0, 1046.5])
			m.resize(int(HZ * 0.55))
			for i in m.size():
				var t := float(i) / HZ
				var s := 0.0
				for k in 2:
					var t0 := t - k * 0.16
					if t0 >= 0.0:
						s += (sin(TAU * notas[k] * t0) + 0.3 * sin(TAU * 2.0 * notas[k] * t0)) * minf(1.0, t0 * 250.0) * exp(-t0 * 6.0)
				m[i] = s * 0.22
		"Efectos":                                         # tres notas agudas y rápidas, como un destello
			var notas := PackedFloat32Array([1568.0, 2093.0, 2637.0])
			m.resize(int(HZ * 0.32))
			for i in m.size():
				var t := float(i) / HZ
				var s := 0.0
				for k in 3:
					var t0 := t - k * 0.06
					if t0 >= 0.0:
						s += sin(TAU * notas[k] * t0) * minf(1.0, t0 * 400.0) * exp(-t0 * 14.0)
				m[i] = s * 0.18
		"Interfaz":                                        # «tic» cristalino, como el de los menús
			m.resize(int(HZ * 0.06))
			for i in m.size():
				var t := float(i) / HZ
				m[i] = (sin(TAU * 2600.0 * t) + 0.5 * sin(TAU * 3900.0 * t)) * exp(-t * 85.0) * 0.22
		"Ambiente":                                        # una brisa: ruido suave que sube y baja
			var rng := RandomNumberGenerator.new()
			rng.seed = 11
			var suave := 0.0
			m.resize(int(HZ * 0.9))
			for i in m.size():
				var t := float(i) / m.size()
				suave += (rng.randf_range(-1.0, 1.0) - suave) * 0.08     # filtro paso bajo de un polo
				m[i] = suave * sin(t * PI) * 0.55
	return m


static func _wav(m: PackedFloat32Array, hz: int) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(m.size() * 2)
	for i in m.size():
		b.encode_s16(i * 2, int(clampf(m[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = hz
	w.stereo = false
	w.data = b
	return w


# ================================================================= efectos (T-083)

# Hace sonar un efecto del catálogo. Opciones: db (más o menos volumen), tono (multiplica), retraso (s; se anula si
# cambia la escena), en (nodo dueño: el reproductor es hijo suyo y muere con él), variante (índice fijo, sin
# variación de tono ni de volumen; lo usan las pruebas de señal), pos (Vector3: suena desde ese punto de la escena 3D,
# con «en_3d» del catálogo o de la petición; sin nadie que escuche en 3D, suena normal). Devuelve el reproductor, o null
# si no suena (efecto que no existe, silencio, pausa, repetido demasiado pronto o sin voz libre).
func efecto(nombre: String, op := {}) -> Node:
	var d: Dictionary = EFECTOS.get(nombre, {})
	if d.is_empty():
		push_warning("Sonido: no hay efecto «%s»" % nombre)
		return null
	var retraso: float = op.get("retraso", 0.0)
	if retraso > 0.0:
		var gen := _gen
		var resto := op.duplicate()
		resto.erase("retraso")
		get_tree().create_timer(retraso, false).timeout.connect(func():
			var dueno = resto.get("en")
			if (gen == _gen or d.get("cruza", false)) and (dueno == null or is_instance_valid(dueno)):
				efecto(nombre, resto))
		return null
	if d.has("trata"):                                     # V9: el combate de un jefe, con su tratamiento (aunque calle)
		tratamiento(String(d["trata"][0]), String(d["trata"][1]), op.get("en"))
	elif (nombre == "victoria" or nombre == "derrota") and not _trata.is_empty():
		tratamiento(String(_trata["jefe"]), "fin")         # su bucle se apaga con el final del combate
	var bus: String = d.get("bus", "Efectos")
	if pausado:
		return _descartar(nombre, "pausa")
	if calla(bus):
		return _descartar(nombre, "silencio")
	var ahora := reloj                                     # tiempo de juego: igual a 30 que a 60 FPS y en las pruebas
	var clave: String = op.get("clave", nombre)            # la espera, por efecto (o por quien lo pide: los pasos)
	if ahora - float(_ultimo.get(clave, -1000.0)) < float(d.get("espera", 0.05)):
		return _descartar(nombre, "repetido")
	var fija := op.has("variante")
	var ruta := _elegir(nombre, d, int(op.get("variante", -1)))
	var stream := _stream(ruta)
	if stream == null:
		return _descartar(nombre, "sin_archivo")
	var prioridad := int(d.get("p", 1))
	var grupo: String = d.get("grupo", "")
	if grupo != "" and not _hueco_grupo(grupo, prioridad):
		return _descartar(nombre, "grupo")
	var pos = op.get("pos")
	if not (pos is Vector3 and hay_escucha_3d()):
		pos = null
	var p = _voz(nombre, bus, prioridad, int(d.get("max", 2)), op.get("en"), pos, op.get("en_3d", d.get("en_3d", EN_3D)))
	if p == null:
		return _descartar(nombre, "sin_voz")
	_ultimo[clave] = ahora
	var tono := float(d.get("tono", 0.0))
	var vol := float(d.get("db", 0.0)) + float(op.get("db", 0.0))
	var pitch := float(d.get("tono_fijo", 1.0)) * float(op.get("tono", 1.0))
	if tono > 0.0 and not fija:
		pitch *= 1.0 + _rng.randf_range(-tono, tono)
		vol += _rng.randf_range(-0.7, 0.7)
	if prioridad < 3 and ahora < float(_bajar_hasta.get(bus, -1.0)):
		vol -= ATENUAR_DB                                  # suena una victoria o un jefe: golpes y pasos, por debajo
	_parar_fundido(p)
	_orden += 1
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = vol
	p.set_meta("efecto", nombre)
	p.set_meta("p", prioridad)
	p.set_meta("t", _orden)
	p.set_meta("cruza", d.get("cruza", false))
	p.set_meta("grupo", grupo)
	p.play()
	if prioridad >= 4:
		_bajar_hasta[bus] = ahora + stream.get_length() / maxf(pitch, 0.01)
		_atenuar(bus, prioridad, p)
	contador[nombre] = int(contador.get(nombre, 0)) + 1
	registro.append([ahora, nombre, ruta, bus, pos])
	if registro.size() > 300:
		registro.pop_front()
	return p


# Un golpe físico resuelto: normal, crítico o contra quien se defiende. db: más bajo (el segundo tajo del doble ataque,
# que solo tiembla y no hace daño, suena así: −6 dB).
func golpe(critico := false, defendido := false, db := 0.0) -> void:
	efecto("golpe_defendido" if defendido else ("golpe_critico" if critico else "golpe"), {"db": db} if db != 0.0 else {})


# La voz de un enemigo de combate (un diccionario de combate.gd): «ataque», «herido», «caida», «muerte» (si su familia no
# la tiene, la de caída) o «devorar». Los héroes (tanda 5, por su nombre): «ataque» es su esfuerzo; «alivio»,
# «victoria» y «jadeo» también; si no hay «caida», la de herido. Una voz por enemigo: la nueva corta la suya de antes.
# Con «furia» (menos del 30 % de vida, combate.gd), su ataque suena más fuerte y más grave.
func voz(quien: Dictionary, evento: String) -> Node:
	if quien.is_empty() or not quien.has("hero"):
		return null
	var fam := familia(quien)
	var heroe: bool = quien["hero"]
	if heroe:                                          # tanda 5: «ataque» de un héroe es su esfuerzo
		evento = EVENTO_HEROE.get(evento, evento)
	var nombre := fam + "_" + evento
	if fam != "" and not EFECTOS.has(nombre) and evento == "muerte":
		nombre = fam + "_caida"
	if fam != "" and not EFECTOS.has(nombre) and evento == "caida" and heroe:
		nombre = fam + "_herido"                       # un héroe que cae se queja como herido (más grave)
		evento = "herido"
	if heroe and evento == "alivio":
		_jadeo_de.erase(_clave_de(quien))              # curado: si vuelve a quedar con poca vida, vuelve a jadear
	if fam == "" or not EFECTOS.has(nombre):
		return null
	var op := {}
	if evento == "ataque" and quien.get("furia", false):
		op = {"db": 2.0, "tono": 0.94}
	var clave = _clave_de(quien)
	var antes: Array = _voz_de.get(clave, [])
	var p = efecto(nombre, op)
	if p != null:
		if antes.size() == 2 and is_instance_valid(antes[0]) and antes[0] != p and antes[0].playing \
				and int(antes[0].get_meta("t", -1)) == int(antes[1]):
			_apagar(antes[0], 0.06)                        # su voz anterior se corta (no dos voces del mismo)
		_voz_de[clave] = [p, int(p.get_meta("t", 0))]
	return p


# Un golpe físico ya le ha restado los PV a «quien»: si sigue en pie, su voz de herido; si cae, la de caída. (Un jefe
# que se queda de rodillas con 1 PV se queja como herido; su caída suena al arrodillarse, combate.gd _decidir.)
# Tanda 5: un héroe se queja igual; y si el golpe le deja con poca vida (JADEO_VIDA de su máximo), jadea un momento
# después, una vez (hasta que se cure: voz(h, "alivio")).
func recibe(quien: Dictionary) -> void:
	var hp := int(quien.get("hp", 1))
	voz(quien, "caida" if hp <= 0 else "herido")
	if quien.get("hero", false) and hp > 0:
		var clave = _clave_de(quien)
		var poca: bool = hp < float(quien.get("hp_max", hp)) * JADEO_VIDA
		var fam := familia(quien)
		if not poca:
			_jadeo_de.erase(clave)
		elif not _jadeo_de.has(clave) and EFECTOS.has(fam + "_jadeo"):
			_jadeo_de[clave] = true
			efecto(fam + "_jadeo", {"retraso": 0.7})


# Tanda 5: el gesto de victoria de uno de los héroes que siguen en pie (al azar), un momento después de la fanfarria.
func victoria_heroes(heroes: Array) -> String:
	var vivos: Array = heroes.filter(func(h): return h is Dictionary and int(h.get("hp", 0)) > 0 \
		and EFECTOS.has(familia(h) + "_victoria"))
	if vivos.is_empty():
		return ""
	var h: Dictionary = vivos[_rng.randi_range(0, vivos.size() - 1)]
	var nombre := familia(h) + "_victoria"
	efecto(nombre, {"retraso": 0.8})
	return nombre


static func familia(quien: Dictionary) -> String:
	if quien.get("hero", false):
		return FAMILIAS_HEROE.get(String(quien.get("nombre", "")), "")
	var clave := String(quien.get("clave", ""))
	if FAMILIAS.has(clave):
		return FAMILIAS[clave]
	return FAMILIA_MODELO.get(String(quien.get("modelo", "")), "")


func _clave_de(quien: Dictionary):
	var r = quien.get("rig")
	if r is Object and is_instance_valid(r):
		return r.get_instance_id()
	return String(quien.get("nombre", ""))


# Corta (con un fundido) lo que suena de un efecto, o de todos los de Efectos y Ambiente si no se dice cuál.
func cortar(nombre := "", fundido := FUNDIDO_CORTE) -> void:
	for p in _todas():
		if not p.playing:
			continue
		var n: String = p.get_meta("efecto", "")
		if (nombre == "" and String(p.bus) != "Interfaz") or n == nombre:
			_apagar(p, fundido)


# Cuántos reproductores suenan (de un bus, o de todos).
func sonando(bus := "") -> int:
	var n := 0
	for p in _todas():
		if p.playing and (bus == "" or String(p.bus) == bus):
			n += 1
	return n


# Cuántos de un grupo (MAX_GRUPO) suenan ahora (sin contar los que ya se apagan).
func grupo_sonando(grupo: String) -> int:
	var n := 0
	for p in _todas():
		if p.playing and p.get_meta("grupo", "") == grupo and not p.get_meta("apagando", false):
			n += 1
	return n


func calla(bus: String) -> bool:
	var i := AudioServer.get_bus_index(bus)
	return volumen(bus) == 0 or i < 0 or AudioServer.is_bus_mute(i) or AudioServer.is_bus_mute(0)


func reiniciar_contadores() -> void:
	contador.clear()
	descartes.clear()
	registro.clear()
	_ultimo.clear()


# Rutas de todos los archivos del catálogo, sin repetir (el río 2D y el ataque del ámbar usan archivos de otros).
static func archivos() -> PackedStringArray:
	var r := PackedStringArray()
	for nombre in EFECTOS:
		var d: Dictionary = EFECTOS[nombre]
		if d.has("codigo"):
			continue
		var rutas: Array = []
		if d.has("n"):
			for i in int(d["n"]):
				rutas.append(EF + d["a"] + str(i + 1) + ".wav")
		else:
			rutas.append(EF + d["a"] + ".wav")
		for ruta in rutas:
			if not ruta in r:
				r.append(ruta)
	return r


func _descartar(nombre: String, motivo: String) -> Node:
	var k := nombre + ":" + motivo
	descartes[k] = int(descartes.get(k, 0)) + 1
	return null


func _elegir(nombre: String, d: Dictionary, fija: int) -> String:
	if d.has("codigo"):
		return "codigo:" + String(d["codigo"])
	if not d.has("n"):
		return EF + d["a"] + ".wav"
	var n := int(d["n"])
	var i := fija
	if i < 0 or i >= n:
		i = _rng.randi_range(0, n - 1)
		if n > 1 and i == int(_variante.get(nombre, -1)):   # nunca la misma dos veces seguidas
			i = (i + 1 + _rng.randi_range(0, n - 2)) % n
	_variante[nombre] = i
	return EF + d["a"] + str(i + 1) + ".wav"


func _stream(ruta: String) -> AudioStream:
	if _streams.has(ruta):
		return _streams[ruta]
	var s: AudioStream = null
	if ruta.begins_with("codigo:"):
		if _codigo.is_empty():
			_codigo = load("res://menu_combate.gd").sonidos_ui()
		s = _codigo.get(ruta.substr(7))
	elif has_node("/root/Recursos"):
		s = get_node("/root/Recursos").obtener(ruta)       # la pantalla de carga ya los dejó cargados
	elif ResourceLoader.exists(ruta):
		s = load(ruta)
	if s != null:
		_streams[ruta] = s
	return s


# Un reproductor para el efecto: con «pos», uno 3D de la escena (_voz3d); con dueño, uno nuevo hijo suyo; si no, uno
# del bus. Respeta «max» (si ya suenan tantos, se reutiliza el más viejo de ellos) y las prioridades (si no hay hueco,
# se quita el menos importante).
func _voz(nombre: String, bus: String, prioridad: int, maximo: int, dueno, pos = null, en_3d := {}) -> Node:
	var mismos: Array = []
	for p in _todas():
		if p.playing and p.get_meta("efecto", "") == nombre:
			mismos.append(p)
	if mismos.size() >= maximo:
		mismos.sort_custom(func(a, b): return int(a.get_meta("t", 0)) < int(b.get_meta("t", 0)))
		var viejo: Node = mismos[0]
		if dueno == null and pos == null and viejo in _voces.get(bus, []):
			viejo.stop()
			return viejo
		_apagar(viejo, 0.0)
	if pos is Vector3:
		return _voz3d(bus, prioridad, pos, en_3d)
	if dueno is Node and is_instance_valid(dueno):
		var q := AudioStreamPlayer.new()
		q.bus = bus
		q.process_mode = Node.PROCESS_MODE_PAUSABLE
		dueno.add_child(q)
		q.finished.connect(q.queue_free)
		_propios.append(q)
		return q
	var lista: Array = _voces.get(bus, [])
	for p in lista:
		if not p.playing:
			return p
	var peor: AudioStreamPlayer = null
	for p in lista:
		if peor == null or int(p.get_meta("p", 0)) < int(peor.get_meta("p", 0)) or (
				int(p.get_meta("p", 0)) == int(peor.get_meta("p", 0)) and int(p.get_meta("t", 0)) < int(peor.get_meta("t", 0))):
			peor = p
	if peor != null and int(peor.get_meta("p", 0)) <= prioridad:
		peor.stop()
		return peor
	return null


# Un reproductor 3D de la escena actual en «pos» (efectos en el espacio). Se crean al pedirlos, VOCES_3D como mucho, y
# mueren con la escena. Sin hueco, se quita el menos importante (y más viejo) si no lo es más que el nuevo.
func _voz3d(bus: String, prioridad: int, pos: Vector3, t: Dictionary) -> AudioStreamPlayer3D:
	var escena := get_tree().current_scene
	if escena == null or not escena.is_inside_tree():
		return null
	_voces3d = _voces3d.filter(func(x): return is_instance_valid(x) and x.is_inside_tree())
	var q: AudioStreamPlayer3D = null
	for x in _voces3d:
		if not x.playing:
			q = x
			break
	if q == null and _voces3d.size() < VOCES_3D:
		q = AudioStreamPlayer3D.new()
		q.bus = StringName(bus)                            # nunca por Master (lo mira prueba_audio)
		q.name = "Sonido3D_%d" % _voces3d.size()
		q.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		q.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		q.process_mode = Node.PROCESS_MODE_PAUSABLE
		escena.add_child(q)
		_voces3d.append(q)
	if q == null:
		for x in _voces3d:
			if q == null or int(x.get_meta("p", 0)) < int(q.get_meta("p", 0)) or (
					int(x.get_meta("p", 0)) == int(q.get_meta("p", 0)) and int(x.get_meta("t", 0)) < int(q.get_meta("t", 0))):
				q = x
		if q == null or int(q.get_meta("p", 0)) > prioridad:
			return null
		q.stop()
	q.bus = StringName(bus)
	q.unit_size = float(t.get("unidad", EN_3D["unidad"]))
	q.max_distance = float(t.get("max", EN_3D["max"]))
	q.max_db = 0.0                                         # más cerca que «unidad» no sube por encima de su volumen
	q.attenuation_filter_db = float(t.get("filtro", EN_3D["filtro"]))
	q.global_position = pos
	return q


# Límite de un grupo (MAX_GRUPO): si ya suenan tantos, se quita el menos importante (y más viejo) si no lo es más que el
# nuevo; si todos lo son, el nuevo no suena.
func _hueco_grupo(grupo: String, prioridad: int) -> bool:
	var lista: Array = []
	for p in _todas():
		if p.playing and p.get_meta("grupo", "") == grupo and not p.get_meta("apagando", false):
			lista.append(p)
	if lista.size() < int(MAX_GRUPO.get(grupo, 99)):
		return true
	var peor: Node = null
	for p in lista:
		if peor == null or int(p.get_meta("p", 0)) < int(peor.get_meta("p", 0)) or (
				int(p.get_meta("p", 0)) == int(peor.get_meta("p", 0)) and int(p.get_meta("t", 0)) < int(peor.get_meta("t", 0))):
			peor = p
	if int(peor.get_meta("p", 0)) > prioridad:
		return false
	_apagar(peor, 0.05)
	return true


func _todas() -> Array:
	var r: Array = []
	for bus in _voces:
		r.append_array(_voces[bus])
	var vivos: Array = []
	for q in _propios:
		if is_instance_valid(q):
			vivos.append(q)
	_propios = vivos
	r.append_array(vivos)
	for q in _voces3d:
		if is_instance_valid(q):
			r.append(q)
	return r


func _atenuar(bus: String, _prioridad: int, excepto: Node) -> void:
	for p in _todas():
		if p != excepto and p.playing and String(p.bus) == bus and int(p.get_meta("p", 0)) < 3:
			var t := create_tween()
			t.tween_property(p, "volume_db", p.volume_db - ATENUAR_DB, 0.15)
			p.set_meta("tween", t)


func _apagar(p: Node, fundido: float) -> void:
	_parar_fundido(p)
	if fundido <= 0.0 or not p.playing:
		p.stop()
		return
	var t := create_tween()
	t.tween_property(p, "volume_db", -60.0, fundido)
	t.tween_callback(p.stop)
	p.set_meta("tween", t)
	p.set_meta("apagando", true)                           # ya se va: no cuenta para el límite de su grupo


func _parar_fundido(p: Node) -> void:
	p.remove_meta("apagando")
	if p.has_meta("tween"):
		var t = p.get_meta("tween")
		if t is Tween and t.is_valid():
			t.kill()
		p.remove_meta("tween")


func _process(delta: float) -> void:
	reloj += delta
	var e := get_tree().current_scene
	if e != _escena:
		_escena = e
		_al_cambiar_escena()
	if not _trata.is_empty() and not _trata_vigente():
		quitar_tratamiento()                               # V9: se ha ido el combate del jefe
	_detalles(delta)
	var m = get_node_or_null("/root/Musica")
	apartar_musica(APARTAR_MUSICA_EN_COMBATE and m != null and m.contexto == "combate")


# Tanda 7: en combate, la música se aparta cuando suenan efectos (APARTAR): un compresor al final del bus Musica que
# escucha al bus Efectos. Pedirlo dos veces no pone dos; con false se quita.
func apartar_musica(si: bool) -> void:
	var i := AudioServer.get_bus_index("Musica")
	if i < 0 or si == (_apartar != null):
		return
	if si:
		_apartar = AudioEffectCompressor.new()
		_apartar.threshold = float(APARTAR["umbral"])
		_apartar.ratio = float(APARTAR["ratio"])
		_apartar.attack_us = float(APARTAR["ataque_ms"]) * 1000.0
		_apartar.release_ms = float(APARTAR["suelta_ms"])
		_apartar.sidechain = &"Efectos"
		_apartar.resource_name = "Apartar_musica"
		AudioServer.add_bus_effect(i, _apartar)
	else:
		_quitar_efecto_bus(i, _apartar)
		_apartar = null


func musica_apartada() -> bool:
	return _apartar != null


# Tanda 7: el limitador suave del Master (LIMITE): solo toca los picos que pasarían de «techo_db».
func limitador(si: bool) -> void:
	if si == (_limitador != null):
		return
	if si:
		_limitador = AudioEffectHardLimiter.new()
		_limitador.ceiling_db = float(LIMITE["techo_db"])
		_limitador.release = float(LIMITE["suelta_s"])
		_limitador.resource_name = "Limitador_master"
		AudioServer.add_bus_effect(0, _limitador)
	else:
		_quitar_efecto_bus(0, _limitador)
		_limitador = null


# V9: el tratamiento del combate de un jefe (TRATAMIENTOS): lo empieza la primera etapa que se pide (con «dueno», el
# combate: mientras exista) y las siguientes lo cambian con un fundido. Pone un paso bajo y un volumen al principio del
# bus Musica (antes del compresor de la tanda 7) y su bucle por Ambiente, hijo del dueño (muere con él).
func tratamiento(jefe: String, etapa: String, dueno = null) -> void:
	var t: Dictionary = TRATAMIENTOS.get(jefe, {})
	var e: Dictionary = t.get("etapas", {}).get(etapa, {})
	if e.is_empty():
		return
	if not _trata.is_empty() and (_trata["jefe"] != jefe or not _trata_vigente()):
		quitar_tratamiento()
	if _trata.is_empty():
		if etapa == "fin":
			return
		if not (is_instance_valid(dueno) and dueno is Node):
			dueno = get_tree().current_scene
		if not (is_instance_valid(dueno) and dueno is Node):
			return                                         # sin combate al que atarlo, nada (no se quedaría puesto)
		_trata = {"jefe": jefe, "dueno": dueno}
		var i := AudioServer.get_bus_index("Musica")
		if i >= 0:
			var f := AudioEffectLowPassFilter.new()
			f.cutoff_hz = 20000.0
			f.resource_name = "Tratamiento_paso_bajo"
			var a := AudioEffectAmplify.new()
			a.volume_db = 0.0
			a.resource_name = "Tratamiento_volumen"
			AudioServer.add_bus_effect(i, f, 0)
			AudioServer.add_bus_effect(i, a, 1)
			_trata["filtro"] = f
			_trata["amp"] = a
		var nb: String = t.get("bucle", "")
		if EFECTOS.has(nb):
			var st := _stream(_elegir(nb, EFECTOS[nb], -1))
			if st != null:
				var p := AudioStreamPlayer.new()
				p.name = "Tratamiento_" + nb
				p.bus = StringName(EFECTOS[nb].get("bus", "Ambiente"))
				p.stream = st
				p.volume_db = -60.0
				p.process_mode = Node.PROCESS_MODE_PAUSABLE
				p.set_meta("efecto", nb)
				dueno.add_child(p)
				p.play()
				_emisores.append(p)                        # la pausa de la app (pausar) también lo para
				_trata["bucle"] = p
				_trata["bucle_db"] = float(EFECTOS[nb].get("db", 0.0))
	_trata["etapa"] = etapa
	var viejo = _trata.get("tween")
	if viejo is Tween and viejo.is_valid():
		viejo.kill()
	var s := float(e.get("s", 1.0))
	var tw := create_tween().set_parallel(true)
	tw.tween_interval(s)
	if e.has("corte") and _trata.has("filtro"):
		tw.tween_property(_trata["filtro"], "cutoff_hz", float(e["corte"]), s)
	if e.has("musica_db") and _trata.has("amp"):
		tw.tween_property(_trata["amp"], "volume_db", float(e["musica_db"]), s)
	var bucle = _trata.get("bucle")
	if e.has("bucle_db") and is_instance_valid(bucle):
		var objetivo := float(_trata["bucle_db"]) + float(e["bucle_db"])
		if float(e["bucle_db"]) <= -59.0:
			objetivo = -60.0
		tw.tween_property(bucle, "volume_db", objetivo, s)
		if objetivo <= -60.0:
			tw.chain().tween_callback(bucle.stop)
	_trata["tween"] = tw


# Quita el tratamiento: el paso bajo y el volumen del bus Musica y el bucle (con un fundido corto).
func quitar_tratamiento() -> void:
	if _trata.is_empty():
		return
	var tw = _trata.get("tween")
	if tw is Tween and tw.is_valid():
		tw.kill()
	var i := AudioServer.get_bus_index("Musica")
	if i >= 0:
		for k in ["filtro", "amp"]:
			if _trata.has(k):
				_quitar_efecto_bus(i, _trata[k])
	var p = _trata.get("bucle")
	if is_instance_valid(p):
		var t := create_tween()
		t.tween_property(p, "volume_db", -60.0, FUNDIDO_CORTE)
		t.tween_callback(p.queue_free)
	_trata = {}


# El tratamiento que suena: {"jefe", "etapa", "corte" (Hz del paso bajo), "musica_db", "bucle_db"}, o {} si no hay.
func tratamiento_actual() -> Dictionary:
	if _trata.is_empty():
		return {}
	var r := {"jefe": _trata["jefe"], "etapa": _trata.get("etapa", "")}
	if _trata.has("filtro"):
		r["corte"] = _trata["filtro"].cutoff_hz
		r["musica_db"] = _trata["amp"].volume_db
	if is_instance_valid(_trata.get("bucle")):
		r["bucle_db"] = _trata["bucle"].volume_db
		r["bucle_suena"] = _trata["bucle"].playing
	return r


func _trata_vigente() -> bool:
	var du = _trata.get("dueno")
	return is_instance_valid(du) and du is Node and du.is_inside_tree()


func _quitar_efecto_bus(i: int, efecto_bus: AudioEffect) -> void:
	for k in range(AudioServer.get_bus_effect_count(i) - 1, -1, -1):
		if AudioServer.get_bus_effect(i, k) == efecto_bus:
			AudioServer.remove_bus_effect(i, k)


# Cambio de escena: lo de Efectos y Ambiente que no «cruza» se apaga y lo programado ya no suena. El eco y los detalles
# en el espacio de la escena anterior se quitan.
func _al_cambiar_escena() -> void:
	_gen += 1
	_voz_de.clear()                                        # los enemigos de antes ya no existen
	_jadeo_de.clear()
	_voces3d = _voces3d.filter(func(x): return is_instance_valid(x) and x.is_inside_tree())
	for p in _todas():
		if p.playing and String(p.bus) != "Interfaz" and not p.get_meta("cruza", false):
			_apagar(p, FUNDIDO_CORTE)
	_emisores = _emisores.filter(func(x): return is_instance_valid(x))
	if _oyente != null and not is_instance_valid(_oyente):
		_oyente = null
	if not _eco.is_empty() and _eco_escena != _escena:
		quitar_eco()
	if not _trata.is_empty() and (not _trata_vigente() or _escena != null and _trata["dueno"] != _escena \
			and not _escena.is_ancestor_of(_trata["dueno"])):
		quitar_tratamiento()                               # V9: el tratamiento del jefe no pasa a otra escena
	if _det3d_escena != null and _det3d_escena != _escena:
		_det3d_escena = null
		_det3d_donde = Callable()


# De vez en cuando, un detalle de la naturaleza según el lugar (DETALLES). Nunca en pausa ni en combate. Si la escena
# lo pide (detalles_3d), suena en un punto del espacio.
func _detalles(delta: float) -> void:
	var m = get_node_or_null("/root/Musica")
	var ctx: String = m.contexto if m != null else ""
	if _momento != "" and is_instance_valid(_momento_escena) and _momento_escena == _escena \
			and DETALLES.has(ctx + "_" + _momento):
		ctx = ctx + "_" + _momento                         # tanda 6: la hora que ha fijado la escena
	if ctx != _det_ctx:
		_det_ctx = ctx
		_det_t = _rng.randf_range(4.0, 9.0)
		_campana_t = -1.0
	var dd: Dictionary = DETALLES.get(ctx, {})
	if dd.is_empty() or pausado or get_tree().paused:
		return
	if dd.has("campana"):                                  # la campana lejana marca la hora de vez en cuando
		if _campana_t < 0.0:
			_campana_t = _rng.randf_range(float(dd["campana"][0]) * 0.4, float(dd["campana"][1]) * 0.5)
		_campana_t -= delta
		if _campana_t <= 0.0:
			efecto("campana")
			_campana_t = _rng.randf_range(float(dd["campana"][0]), float(dd["campana"][1]))
	_det_t -= delta
	if _det_t <= 0.0:
		var lista: Array = dd["efectos"]
		var nombre: String = lista[_rng.randi_range(0, lista.size() - 1)]
		var op := {}
		if _det3d_donde.is_valid() and is_instance_valid(_det3d_escena) and _det3d_escena == _escena:
			var q = _det3d_donde.call(posicion_oyente(), _rng.randf(), _rng.randf())
			if q is Vector3:
				op["pos"] = q
		efecto(nombre, op)
		_det_t = _rng.randf_range(dd["cada"][0], dd["cada"][1])


# Los detalles de la naturaleza (DETALLES) de esta escena 3D suenan en un punto: «donde» recibe la posición de quien
# escucha y dos números al azar entre 0 y 1 (del generador del sonido) y devuelve dónde (Vector3; si no, suena normal).
# La Garganta 3D: cada gota cae en la pared de roca más cercana. Se olvida al cambiar de escena.
# Tanda 6: la hora del lugar («dia», «tarde» o «noche») mientras «escena» sea la actual: los detalles de su contexto pasan
# a ser los de «<contexto>_<momento>» si existen (Oakhaven: pájaros de día, grillo al atardecer, mochuelo de noche, y la
# campana que marca la hora). Se olvida sola al cambiar de escena. Con «» vuelve a lo de siempre.
func fijar_momento(escena: Node, momento: String) -> void:
	_momento = momento
	_momento_escena = escena


func momento_actual() -> String:
	return _momento if is_instance_valid(_momento_escena) and _momento_escena == _escena else ""


func detalles_3d(escena: Node, donde: Callable) -> void:
	_det3d_escena = escena
	_det3d_donde = donde


# Android: al pasar la app a segundo plano se pausa todo; al volver, sigue.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT and OS.has_feature("mobile"):
		pausar(true)
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN and OS.has_feature("mobile"):
		pausar(false)


func pausar(si: bool) -> void:
	pausado = si
	for p in _todas():
		p.stream_paused = si
	_emisores = _emisores.filter(func(x): return is_instance_valid(x))
	for x in _emisores:
		x.stream_paused = si


# ================================================================= pasos

# Pasos de un personaje 3D: suenan cuando un pie toca el suelo (los huesos LeftFoot / RightFoot del esqueleto), solo
# si avanza. «superficie» recibe la posición y dice el suelo («hierba», «piedra»…). Sin esqueleto, por distancia.
# Vale para varios personajes a la vez (Kael, Lya, Garon…), uno por cuerpo: pedirlo dos veces para el mismo cuerpo
# devuelve el que ya tenía (no se duplican). db: su volumen; sin decirlo, el de DB_PASOS por el nombre del nodo (Lya,
# Garon) o 0. Los de quien no es el que escucha (los compañeros) suenan desde su pie, en el espacio (PASO_3D: más bajos
# cuanto más lejos); sin oyente 3D, 3 dB más bajos (DB_COMPANERO_SIN_POSICION).
# Dos pasos del mismo cuerpo con menos de 0,09 s entre ellos suenan como uno («espera» del catálogo, por cuerpo: los
# pasos de dos personajes que pisan a la vez suenan los dos).
func pasos_3d(cuerpo: Node3D, superficie: Callable, db := NAN) -> Node:
	if cuerpo == null:
		return null
	var vol: float = db if not is_nan(db) else float(DB_PASOS.get(String(cuerpo.name), 0.0))
	for h in cuerpo.get_children():
		if h is Pasos3D:
			h.superficie = superficie
			h.db = vol
			return h
	var n := Pasos3D.new()
	n.name = "Pasos"
	n.son = self
	n.cuerpo = cuerpo
	n.superficie = superficie
	n.db = vol
	cuerpo.add_child(n)
	return n


# Pasos del muñeco 2D: al llegar a un fotograma de CUADROS_PASO de «correr». «superficie» dice el suelo.
func pasos_2d(sprite: AnimatedSprite2D, superficie: Callable) -> void:
	if sprite == null:
		return
	sprite.frame_changed.connect(func():
		if is_instance_valid(sprite) and String(sprite.animation).begins_with("correr") and sprite.frame in CUADROS_PASO:
			efecto("paso_" + String(superficie.call())))


# Los pasos de una zona 2D (zona.gd y la Garganta): el suelo sale de su estilo, de si pisa camino o un puente.
func pasos_zona(z: Node) -> void:
	if z == null or z.get("sprite") == null:
		return
	pasos_2d(z.sprite, func(): return suelo_zona(z))


static func suelo_zona(z) -> String:
	if not is_instance_valid(z) or z.get("jugador") == null:
		return "hierba"
	var p: Vector2 = z.jugador.position
	var e: Dictionary = z.estilo
	if z._en_puente(p):
		return "piedra" if e.get("agua", "") in ["lava", "veneno"] else "madera"
	var textura: String = e.get("suelo", "")
	if z._peso(z.camino_v, p / z.T) > 0.5:
		textura = e.get("camino", "")
	return SUELOS.get(textura, "hierba")


class Pasos3D extends Node:
	const ALTO_SUELO := 0.06                     # m sobre lo más bajo del pie en la vuelta: «toca el suelo»
	const VEL_MIN := 0.6                         # m/s: más despacio, no suenan pasos
	const ENTRE_PASOS := 0.16                    # s mínimos entre dos pasos (los dos pies)
	var son
	var cuerpo: Node3D
	var superficie: Callable
	var db := 0.0                                # más bajo para los compañeros
	var skel: Skeleton3D
	var pies: Array = []                         # {"i": hueso, "y": altura anterior, "min": lo más bajo, "baja": bool}
	var _ant := Vector3.ZERO
	var _vel := 0.0
	var _acum := 0.0
	var _t_ultimo := 0.0
	var _t := 0.0
	var _buscar_en := 0.0
	var pasos := 0                               # pisadas (para las pruebas)
	var sonados := 0                             # pisadas que han sonado
	var ultimo: Node = null                      # el reproductor del último paso que sonó (para las pruebas)
	var _parado := 0.0                           # s seguidos sin andar
	var _toca_gesto := -1.0                      # a los cuántos s parado toca el próximo gesto (-1: sin elegir)
	var gestos := 0                              # gestos de quieto que han sonado (para las pruebas)

	func _ready() -> void:
		_ant = cuerpo.global_position
		_buscar_pies()

	# Parado: tras un rato, un gesto discreto de su personaje (QUIETO); si ya suena el de otro, se espera un poco.
	func _quieto(delta: float) -> void:
		var nombre := _gesto()
		if nombre == "":
			return
		_parado += delta
		if _toca_gesto < 0.0:
			_toca_gesto = son._rng.randf_range(son.QUIETO["primero"][0], son.QUIETO["primero"][1])
		if _parado < _toca_gesto:
			return
		if son.grupo_sonando("quieto") > 0:
			_toca_gesto = _parado + 1.5
			return
		var op := {}
		if not son.es_oyente(cuerpo) and son.hay_oyente():
			op = {"pos": cuerpo.global_position + Vector3(0, 1.2, 0), "en_3d": son.PASO_3D}
		if son.efecto(nombre, op) != null:
			gestos += 1
		_toca_gesto = _parado + son._rng.randf_range(son.QUIETO["entre"][0], son.QUIETO["entre"][1])

	# El gesto de este personaje: el que escucha es Kael; Lya y Garon, por el nombre de su nodo; los demás, ninguno.
	func _gesto() -> String:
		if son.QUIETO_DE.has(String(cuerpo.name)):
			return son.QUIETO_DE[String(cuerpo.name)]
		return son.QUIETO_DE["Kael"] if son.es_oyente(cuerpo) else ""

	# Los huesos de los pies (si el modelo aún no estaba, se vuelve a mirar cada segundo; mientras, por distancia).
	func _buscar_pies() -> void:
		var s = cuerpo.get("skel")
		if not s is Skeleton3D:
			return
		skel = s
		pies.clear()
		for lado in ["left", "right"]:
			for b in skel.get_bone_count():
				if skel.get_bone_name(b).to_lower().ends_with(lado + "foot"):
					pies.append({"i": b, "y": 0.0, "min": 99.0, "baja": false})
					break

	func _process(delta: float) -> void:
		if delta <= 0.0 or not is_instance_valid(cuerpo):
			return
		_t += delta
		if pies.size() < 2 and _t >= _buscar_en:
			_buscar_en = _t + 1.0
			_buscar_pies()
		var p := cuerpo.global_position
		var d := Vector2(p.x - _ant.x, p.z - _ant.z).length()
		_ant = p
		if d > 2.0:                                  # recolocado (vuelve del combate, carga): no es andar
			return
		_vel = lerpf(_vel, d / delta, minf(1.0, delta * 10.0))
		if _vel < VEL_MIN:
			for f in pies:
				f["baja"] = false
			_acum = 0.0
			_quieto(delta)
			return
		_parado = 0.0
		_toca_gesto = -1.0
		if pies.size() == 2 and is_instance_valid(skel):
			for f in pies:
				var pie: Vector3 = (skel.global_transform * skel.get_bone_global_pose(f["i"])).origin
				var y: float = pie.y - p.y
				f["min"] = minf(y, float(f["min"]) + delta * 0.05)      # lo más bajo de la vuelta (se adapta despacio)
				var vy: float = (y - float(f["y"])) / delta
				f["y"] = y
				if vy < -0.2:
					f["baja"] = true
				elif f["baja"] and vy > -0.05 and y < float(f["min"]) + ALTO_SUELO:
					f["baja"] = false
					_pisar(p, pie)
		else:                                        # sin esqueleto: un paso cada zancada (más larga al correr)
			_acum += d
			var zancada := clampf(_vel * 0.33, 0.7, 2.2)
			if _acum >= zancada:
				_acum -= zancada
				_pisar(p, p)

	# Un pie toca el suelo en «pie». Los del que escucha (Kael), sin posición; los de los compañeros, desde su pie (con
	# un oyente 3D) o algo más bajos (sin él). Cada paso pide un solo efecto; la espera mínima entre dos pasos es de
	# cada cuerpo («clave»): dos personajes que pisan a la vez suenan los dos (antes se perdía casi la mitad).
	func _pisar(p: Vector3, pie: Vector3) -> void:
		if _t - _t_ultimo < ENTRE_PASOS:
			return
		_t_ultimo = _t
		pasos += 1
		var nombre := "paso_" + String(superficie.call(p))
		var op := {"db": db + (2.0 if _vel > 5.5 else 0.0), "clave": nombre + "@" + str(get_instance_id())}
		if not son.es_oyente(cuerpo):
			if son.hay_oyente():
				op["pos"] = pie
				op["en_3d"] = son.PASO_3D
			elif son.DB_PASOS.has(String(cuerpo.name)):
				op["db"] += son.DB_COMPANERO_SIN_POSICION
		var r = son.efecto(nombre, op)
		if r != null:
			ultimo = r
			sonados += 1


# ================================================================= ambiente 3D

# Emisor fijo (la cascada) con el bucle del efecto, por el bus Ambiente. Empieza en un punto al azar del bucle.
# db: más o menos que el volumen del catálogo (el mismo bucle en dos sitios).
func fuente_3d(padre: Node3D, nombre: String, pos: Vector3, db := 0.0) -> AudioStreamPlayer3D:
	var e := _emisor(padre, nombre, AudioStreamPlayer3D.new(), db)
	if e != null:
		e.position = pos
	return e


# Emisor a lo largo de un segmento (un río, la caída de una cascada, el eje de un abismo): cada fotograma se pone en el
# punto del segmento más cercano a quien escucha.
func fuente_linea(padre: Node3D, nombre: String, a: Vector3, b: Vector3, db := 0.0) -> Node3D:
	var d: Dictionary = EFECTOS.get(nombre, {})
	if d.get("tres_d", {}).has("cada"):                    # tanda 5: de vez en cuando, no un bucle (las cuerdas)
		return _fuente_cada(padre, nombre, a, b, db)
	var f := FuenteLineal.new()
	f.a = a
	f.b = b
	f.son = self
	var e := _emisor(padre, nombre, f, db)
	if e != null:
		e.position = a.lerp(b, 0.5)
	return e


# Tanda 5: una fuente 3D que suena de vez en cuando («cada» de su «tres_d»: [mín, máx] s) en el punto del segmento más
# cercano a quien escucha, si está a menos de «max» m: una de sus variantes, con efecto() (prioridad, voces, pausa,
# silencio y cambio de escena de siempre). Es hija de «padre» y muere con él.
func _fuente_cada(padre: Node3D, nombre: String, a: Vector3, b: Vector3, db := 0.0) -> Node3D:
	if padre == null:
		return null
	var f := FuenteCada.new()
	f.name = "Sonido_" + nombre
	if padre.has_node(NodePath(f.name)):
		f.name = "Sonido_%s_%d" % [nombre, padre.get_child_count()]
	f.son = self
	f.nombre = nombre
	f.a = a
	f.b = b
	f.db = db
	f.process_mode = Node.PROCESS_MODE_PAUSABLE
	padre.add_child(f)
	return f


class FuenteCada extends Node3D:
	var son
	var nombre := ""
	var a: Vector3
	var b: Vector3
	var db := 0.0
	var veces := 0                             # cuántas veces ha sonado (para las pruebas)
	var _t := 0.0

	func _ready() -> void:
		var c: Array = son.EFECTOS[nombre]["tres_d"]["cada"]
		_t = son._rng.randf_range(0.5, float(c[0]))

	func _process(delta: float) -> void:
		_t -= delta
		if _t > 0.0:
			return
		var t3: Dictionary = son.EFECTOS[nombre]["tres_d"]
		_t = son._rng.randf_range(float(t3["cada"][0]), float(t3["cada"][1]))
		var o: Vector3 = son.posicion_oyente()
		var ab := b - a
		var k := clampf((o - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var p := a + ab * k
		if p.distance_to(o) > float(t3.get("max", 40.0)):
			return
		if son.efecto(nombre, {"pos": p, "en_3d": t3, "db": db}) != null:
			veces += 1


func _emisor(padre: Node3D, nombre: String, e: AudioStreamPlayer3D, db := 0.0) -> AudioStreamPlayer3D:
	var d: Dictionary = EFECTOS.get(nombre, {})
	var s := _stream(EF + String(d.get("a", "")) + ".wav") if d.has("tres_d") else null
	if padre == null or s == null:
		e.free()
		push_warning("Sonido: no se puede crear el emisor «%s»" % nombre)
		return null
	var t: Dictionary = d["tres_d"]
	e.name = "Sonido_" + nombre
	if padre.has_node(NodePath(e.name)):                   # el mismo bucle dos veces (el viento del abismo y el de los
		e.name = "Sonido_%s_%d" % [nombre, padre.get_child_count()]   # puentes): cada uno con su nombre
	e.stream = s
	e.bus = &"Ambiente"
	e.volume_db = float(d.get("db", 0.0)) + db
	e.unit_size = float(t.get("unidad", 5.0))
	e.max_distance = float(t.get("max", 40.0))
	e.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	e.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
	e.process_mode = Node.PROCESS_MODE_PAUSABLE
	e.set_meta("efecto", nombre)
	padre.add_child(e)
	e.play(_rng.randf_range(0.0, maxf(0.0, s.get_length() - 1.0)))
	_emisores.append(e)
	contador[nombre] = int(contador.get(nombre, 0)) + 1
	return e


# Eco del lugar (ECO[nombre]) mientras «escena» sea la escena actual: una reverberación (AudioEffectReverb) al final de
# los buses que dice ECO (Efectos y Ambiente; nunca la música ni la interfaz). Se quita sola al cambiar de escena, o con
# quitar_eco(). Pedirlo otra vez lo cambia (no se suman dos).
func eco(escena: Node, nombre: String) -> void:
	quitar_eco()
	var c: Dictionary = ECO.get(nombre, {})
	if c.is_empty() or escena == null:
		return
	var buses: Dictionary = c["buses"]
	for bus in buses:
		var i := AudioServer.get_bus_index(bus)
		if i < 0:
			continue
		var r := AudioEffectReverb.new()
		r.room_size = float(c["sala"])
		r.damping = float(c["amortiguar"])
		r.spread = float(c["abrir"])
		r.hipass = float(c["graves"])
		r.predelay_msec = float(c["previo_ms"])
		r.predelay_feedback = float(c["rebote"])
		r.dry = float(c.get("seco", 1.0))
		r.wet = float(buses[bus])
		r.resource_name = "Eco_" + nombre
		AudioServer.add_bus_effect(i, r)
		_eco.append([bus, r])
	_eco_escena = escena


func quitar_eco() -> void:
	for par in _eco:
		var i := AudioServer.get_bus_index(par[0])
		if i < 0:
			continue
		for k in range(AudioServer.get_bus_effect_count(i) - 1, -1, -1):
			if AudioServer.get_bus_effect(i, k) == par[1]:
				AudioServer.remove_bus_effect(i, k)
	_eco.clear()
	_eco_escena = null


# Los buses que llevan ahora el eco de un lugar (para las pruebas).
func eco_activo() -> Array:
	return _eco.map(func(x): return x[0])


# Se escucha desde «sigue» (a la altura de la cabeza), mirando hacia donde mira la cámara: lo que está a la derecha
# en la pantalla suena a la derecha, y la distancia es la del personaje, no la de la cámara (que va a 20 m).
func oyente_3d(sigue: Node3D, camara: Camera3D) -> AudioListener3D:
	if sigue == null:
		return null
	var o := Oyente.new()
	o.name = "Oyente"
	o.sigue = sigue
	o.camara = camara
	sigue.get_parent().add_child(o)
	_oyente = o
	return o


func posicion_oyente() -> Vector3:
	if _oyente != null and is_instance_valid(_oyente):
		return _oyente.global_position
	var c := get_viewport().get_camera_3d()
	return c.global_position if c != null else Vector3.ZERO


# Hay alguien que escucha desde un personaje (oyente_3d) en la escena de ahora.
func hay_oyente() -> bool:
	return _oyente != null and is_instance_valid(_oyente) and _oyente.is_inside_tree()


# «cuerpo» es el personaje desde el que se escucha (sus pasos no van en el espacio: están en sus oídos).
func es_oyente(cuerpo: Node) -> bool:
	return hay_oyente() and _oyente.sigue == cuerpo


# Un efecto con «pos» se puede oír en el espacio: hay un oyente 3D o una cámara 3D en la pantalla.
func hay_escucha_3d() -> bool:
	return hay_oyente() or get_viewport().get_camera_3d() != null


class Oyente extends AudioListener3D:
	var sigue: Node3D
	var camara: Camera3D

	func _ready() -> void:
		_seguir()
		make_current()

	func _process(_d: float) -> void:
		_seguir()

	func _seguir() -> void:
		if not is_instance_valid(sigue):
			return
		var b := camara.global_basis if is_instance_valid(camara) else Basis()
		global_transform = Transform3D(b.orthonormalized(), sigue.global_position + Vector3(0, 1.5, 0))


class FuenteLineal extends AudioStreamPlayer3D:
	var a: Vector3
	var b: Vector3
	var son

	func _process(_d: float) -> void:
		var o: Vector3 = son.posicion_oyente()
		var ab := b - a
		var t := clampf((o - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		global_position = a + ab * t


# ================================================================= agua de las zonas 2D (tanda 2)

# El río de una zona 2D (zona.gd): un emisor 2D se pone en el punto del río más cercano a quien anda (así suena a la
# izquierda o a la derecha) y su volumen sale de la distancia a la orilla, con un fundido; lejos se calla y deja de
# sonar. Por el bus Ambiente y por debajo del ambiente del lugar. Solo el río (el agua que cruza la zona de lado a
# lado): las charcas están quietas y no suenan a corriente. Sin río de agua de verdad (AGUA_2D), no hay emisor.
func agua_zona(z: Node) -> Node:
	if z == null or not z.get("estilo") is Dictionary or not z.get("agua_v") is PackedByteArray:
		return null
	var nombre: String = AGUA_2D.get(String(z.estilo.get("agua", "")), "")
	var d: Dictionary = EFECTOS.get(nombre, {})
	var s := _stream(EF + String(d.get("a", "")) + ".wav") if d.has("dos_d") else null
	if s == null or z.get("ANCHO") == null or z.get("ALTO") == null:
		return null
	var rio := mascara_rio(z.agua_v, int(z.ANCHO) + 1, int(z.ALTO) + 1)
	if not rio.has(1):
		return null
	var e := Agua2D.new()
	e.name = "Sonido_" + nombre
	e.son = self
	e.zona = z
	e.rio = rio
	e.stream = s
	e.bus = &"Ambiente"
	e.base_db = float(d.get("db", 0.0))
	e.cerca = float(d["dos_d"].get("cerca", 1.5))
	e.lejos = float(d["dos_d"].get("lejos", 9.0))
	e.attenuation = 0.0                                    # el volumen lo pone Agua2D (la distancia es a la orilla)
	e.max_distance = 1.0e6
	e.volume_db = -80.0
	e.process_mode = Node.PROCESS_MODE_PAUSABLE
	e.set_meta("efecto", nombre)
	z.add_child(e)
	_emisores.append(e)
	contador[nombre] = int(contador.get(nombre, 0)) + 1
	return e


# Los vértices de agua (1) que forman el río: las manchas de agua que llegan a un lado de la zona (el río la cruza de
# lado a lado; las charcas nunca están a menos de 4 casillas del borde, zona.gd) o que cruzan media zona. Las charcas
# se quedan fuera.
static func mascara_rio(v: PackedByteArray, vw: int, vh: int) -> PackedByteArray:
	var r := PackedByteArray()
	r.resize(v.size())
	if v.size() != vw * vh:
		return r
	var visto := PackedByteArray()
	visto.resize(v.size())
	for i in v.size():
		if v[i] != 1 or visto[i] == 1:
			continue
		var mancha := PackedInt32Array([i])
		visto[i] = 1
		var k := 0
		var x0 := vw
		var x1 := -1
		while k < mancha.size():
			var j := mancha[k]
			k += 1
			var x := j % vw
			x0 = mini(x0, x)
			x1 = maxi(x1, x)
			for n in [j - 1 if x > 0 else -1, j + 1 if x < vw - 1 else -1, j - vw, j + vw]:
				if n >= 0 and n < v.size() and v[n] == 1 and visto[n] == 0:
					visto[n] = 1
					mancha.append(n)
		if x0 <= 3 or x1 >= vw - 4 or x1 - x0 >= vw / 2:
			for j in mancha:
				r[j] = 1
	return r


class Agua2D extends AudioStreamPlayer2D:
	const CADA := 0.12                     # s entre dos búsquedas del agua más cercana
	const FUNDIDO := 0.8                   # s de nada a todo (y de todo a nada)
	var son
	var zona: Node
	var rio := PackedByteArray()           # los vértices del río (mascara_rio)
	var base_db := 0.0
	var cerca := 1.5                       # casillas desde la orilla: más cerca, a todo volumen
	var lejos := 9.0                       # casillas: más lejos, en silencio
	var nivel := 0.0                       # volumen lineal de ahora (va hacia «objetivo» con el fundido)
	var objetivo := 0.0
	var distancia := 99.0                  # casillas hasta la orilla más cercana
	var punto := Vector2.ZERO              # el agua más cercana (px, en la zona)
	var _t := 0.0

	func _ready() -> void:
		_buscar()
		position = punto

	func _process(delta: float) -> void:
		if not is_instance_valid(zona) or zona.get("jugador") == null:
			return
		_t -= delta
		if _t <= 0.0:
			_t = CADA
			_buscar()
		var saliendo: bool = zona.get("saliendo") == true
		if saliendo:                       # la zona se va (combate, mapa): el agua se funde, el doble de rápido (su
			objetivo = 0.0                 # fundido a negro dura 0,5 s) y no vuelve
		position = position.lerp(punto, minf(1.0, delta * 5.0))
		nivel = move_toward(nivel, objetivo, delta / (FUNDIDO * (0.5 if saliendo else 1.0)))
		if nivel > 0.003:
			volume_db = base_db + linear_to_db(nivel)
			if not playing:
				play(son._rng.randf_range(0.0, maxf(0.0, stream.get_length() - 1.0)))
		elif playing:
			stop()
			volume_db = -80.0

	# El vértice del río más cercano (mascara_rio sobre zona.gd agua_v) en un cuadro alrededor de quien anda.
	func _buscar() -> void:
		var t: float = zona.T
		var p: Vector2 = zona.jugador.position / t
		var v: PackedByteArray = rio
		var vw: int = zona.ANCHO + 1
		var vh: int = zona.ALTO + 1
		var r := int(ceil(lejos)) + 1
		var mejor := 1.0e9
		var mp := Vector2.ZERO
		for y in range(maxi(0, int(p.y) - r), mini(vh, int(p.y) + r + 2)):
			for x in range(maxi(0, int(p.x) - r), mini(vw, int(p.x) + r + 2)):
				if v[y * vw + x] == 1:
					var d2 := p.distance_squared_to(Vector2(x, y))
					if d2 < mejor:
						mejor = d2
						mp = Vector2(x, y)
		if mejor > 1.0e8:
			distancia = 99.0
			objetivo = 0.0
			return
		distancia = maxf(0.0, sqrt(mejor) - 0.5)       # el agua empieza media casilla antes de su vértice
		punto = mp * t
		objetivo = cerca / maxf(distancia, cerca) * (1.0 - smoothstep(lejos * 0.65, lejos, distancia))


# ================================================================= fuentes del mundo en escenas 2D (tanda 3)

# Un sonido del mundo en una escena 2D (Oakhaven: la taberna, el letrero del cuervo): suena desde «pos» (px, en el
# padre), a la izquierda o a la derecha según dónde quede en la pantalla. Volumen por la distancia a «quien» (el que
# anda; sin él, la cámara 2D): todo a «cerca» casillas o menos, la mitad cada vez que se dobla la distancia y callado,
# sin sonar, hacia «lejos» («dos_d» del catálogo; «casilla»: px por casilla). Si el catálogo dice «cada» ([mín, máx] s),
# no es un bucle: de vez en cuando suena una de sus variantes (el cuervo que chirría); si no, el bucle con un fundido
# (la taberna). Por el bus del catálogo (Ambiente), con la pausa, el silencio y el cambio de escena de siempre (es hija
# de la escena y muere con ella). Devuelve el emisor, o null si el efecto no es de este tipo.
func fuente_2d(padre: Node2D, nombre: String, pos: Vector2, quien: Node2D = null, casilla := 64.0) -> Node:
	var d: Dictionary = EFECTOS.get(nombre, {})
	if padre == null or not d.has("dos_d") or nombre in AGUA_2D.values():
		push_warning("Sonido: no se puede crear la fuente 2D «%s»" % nombre)
		return null
	var c: Dictionary = d["dos_d"]
	var e := Fuente2D.new()
	e.name = "Sonido_" + nombre
	e.son = self
	e.nombre = nombre
	e.quien = quien
	e.casilla = casilla
	e.position = pos
	e.bus = StringName(d.get("bus", "Ambiente"))
	e.base_db = float(d.get("db", 0.0))
	e.cerca = float(c.get("cerca", 1.5))
	e.lejos = float(c.get("lejos", 9.0))
	e.cada = c.get("cada", [])
	e.attenuation = 0.0                                    # el volumen lo pone Fuente2D (por casillas)
	e.max_distance = 1.0e6
	e.volume_db = -80.0
	e.process_mode = Node.PROCESS_MODE_PAUSABLE
	e.set_meta("efecto", nombre)
	if e.cada.is_empty():
		e.stream = _stream(EF + String(d["a"]) + ".wav")
		if e.stream == null:
			e.free()
			return null
		contador[nombre] = int(contador.get(nombre, 0)) + 1
	padre.add_child(e)
	_emisores.append(e)
	return e


# Una vez de una fuente 2D intermitente (el cuervo): su variante, su tono y su volumen por la distancia («nivel»
# lineal), con las reglas de efecto() (pausa, silencio, espera).
func _sonar_fuente(e: AudioStreamPlayer2D, nombre: String, nivel: float) -> bool:
	var d: Dictionary = EFECTOS.get(nombre, {})
	var bus: String = d.get("bus", "Ambiente")
	var motivo := ""
	if pausado:
		motivo = "pausa"
	elif calla(bus):
		motivo = "silencio"
	elif reloj - float(_ultimo.get(nombre, -1000.0)) < float(d.get("espera", 0.05)):
		motivo = "repetido"
	if motivo != "":
		_descartar(nombre, motivo)
		return false
	var ruta := _elegir(nombre, d, -1)
	var s := _stream(ruta)
	if s == null:
		_descartar(nombre, "sin_archivo")
		return false
	_ultimo[nombre] = reloj
	var tono := float(d.get("tono", 0.0))
	e.stream = s
	e.pitch_scale = 1.0 + _rng.randf_range(-tono, tono)
	e.volume_db = float(d.get("db", 0.0)) + linear_to_db(maxf(nivel, 0.0001)) + _rng.randf_range(-0.7, 0.7)
	e.play()
	contador[nombre] = int(contador.get(nombre, 0)) + 1
	registro.append([reloj, nombre, ruta, bus, null])
	if registro.size() > 300:
		registro.pop_front()
	return true


class Fuente2D extends AudioStreamPlayer2D:
	const FUNDIDO := 0.8                   # s de nada a todo (y de todo a nada) en los bucles
	var son
	var nombre := ""
	var quien: Node2D
	var casilla := 64.0
	var base_db := 0.0
	var cerca := 1.5
	var lejos := 9.0
	var cada: Array = []                   # [mín, máx] s entre dos veces (intermitente); vacío: bucle
	var nivel := 0.0
	var objetivo := 0.0
	var distancia := 99.0                  # casillas hasta quien anda
	var veces := 0                         # cuántas veces ha sonado (intermitente)
	var _t := 0.0

	func _ready() -> void:
		if not cada.is_empty():
			_t = son._rng.randf_range(0.5, float(cada[0]))   # la primera vez, enseguida (pero no al entrar)

	func _process(delta: float) -> void:
		var desde = _desde()
		if desde == null:
			return
		distancia = global_position.distance_to(desde) / casilla
		objetivo = cerca / maxf(distancia, cerca) * (1.0 - smoothstep(lejos * 0.65, lejos, distancia))
		if not cada.is_empty():
			_t -= delta
			if _t <= 0.0:
				_t = son._rng.randf_range(float(cada[0]), float(cada[1]))
				if objetivo > 0.01 and son._sonar_fuente(self, nombre, objetivo):
					veces += 1
			return
		nivel = move_toward(nivel, objetivo, delta / FUNDIDO)
		if nivel > 0.003:
			volume_db = base_db + linear_to_db(nivel)
			if not playing:
				play(son._rng.randf_range(0.0, maxf(0.0, stream.get_length() - 1.0)))
		elif playing:
			stop()
			volume_db = -80.0

	# Desde dónde se mide: quien anda o, si no hay, el centro de la cámara 2D.
	func _desde():
		if is_instance_valid(quien):
			return quien.global_position
		var c: Camera2D = null
		if is_inside_tree():
			c = get_viewport().get_camera_2d()
		return c.get_screen_center_position() if c != null else null
