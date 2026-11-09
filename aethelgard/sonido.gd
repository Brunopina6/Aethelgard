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
#   corta la suya anterior) y como mucho MAX_GRUPO["voz"] a la vez entre todos. Los héroes no tienen voz. Las magias no
#   piden voces (su presentación está protegida: va en la propuesta de magias, docs/audio/inventario_sonidos.md).
# - Agua de las zonas 2D: agua_zona(zona) pone el río en el agua más cercana a quien anda; suena al acercarse, con un
#   fundido, y se calla lejos (Agua2D).
# - Aleatorio: todo lo del sonido usa su propio generador (_rng), nunca randf()/randi()/shuffle()/pick_random() globales:
#   así no cambia la secuencia del combate cuando una prueba fija su semilla.
# - Para las pruebas: contador (veces que ha sonado cada efecto), descartes y registro (lo último que sonó).

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
const MAX_GRUPO := {"voz": 2}                              # cuántos de un mismo grupo suenan a la vez como mucho

# a: archivo (sin .wav, dentro de audio/efectos/) o prefijo con n variantes (a + "1"… a + "n"); codigo: tono de los
# menús hecho por código (menu_combate.gd, sonidos_ui). db: volumen. tono: variación (± fracción). p: prioridad
# (0 pasos y detalles · 1 interfaz y movimientos · 2 golpes y objetos · 3 eventos · 4 victoria, derrota y jefes).
# max: cuántos a la vez. espera: s mínimos entre dos iguales. cruza: sigue al cambiar de escena. tres_d: emisor 3D.
# dos_d: emisor 2D por cercanía (agua de las zonas). grupo: comparte el límite MAX_GRUPO (las voces de los enemigos).
# tono_fijo: multiplica siempre el tono (el Gólem de ámbar usa el ataque de la piedra, más agudo).
const EFECTOS := {
	# ---- pasos
	"paso_hierba": {"a": "pasos/hierba_", "n": 6, "db": -15.0, "tono": 0.06, "p": 0, "max": 2, "espera": 0.09},
	"paso_piedra": {"a": "pasos/piedra_", "n": 6, "db": -14.0, "tono": 0.06, "p": 0, "max": 2, "espera": 0.09},
	"paso_hojas": {"a": "pasos/hojas_", "n": 5, "db": -15.0, "tono": 0.06, "p": 0, "max": 2, "espera": 0.09},
	"paso_nieve": {"a": "pasos/nieve_", "n": 5, "db": -15.0, "tono": 0.06, "p": 0, "max": 2, "espera": 0.09},
	"paso_grava": {"a": "pasos/grava_", "n": 5, "db": -16.0, "tono": 0.06, "p": 0, "max": 2, "espera": 0.09},
	"paso_arena": {"a": "pasos/arena_", "n": 4, "db": -14.0, "tono": 0.06, "p": 0, "max": 2, "espera": 0.09},
	"paso_madera": {"a": "pasos/madera_", "n": 4, "db": -13.0, "tono": 0.06, "p": 0, "max": 2, "espera": 0.09},
	# ---- combate: ataques físicos, impactos y defensa (las magias no cambian: no tienen sonido aquí)
	"golpe": {"a": "combate/golpe_", "n": 4, "db": -5.0, "tono": 0.05, "p": 2, "max": 3, "espera": 0.04},
	"golpe_critico": {"a": "combate/critico_", "n": 2, "db": -5.0, "tono": 0.04, "p": 3, "max": 2, "espera": 0.04},
	"golpe_defendido": {"a": "combate/defendido_", "n": 3, "db": -7.0, "tono": 0.05, "p": 2, "max": 2, "espera": 0.04},
	"defensa": {"a": "combate/defensa", "db": -8.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.2},
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
	# ---- cofres, puertas, objetos, recompensas y momentos de la misión
	"cofre": {"a": "mundo/cofre_", "n": 3, "db": -7.0, "tono": 0.05, "p": 3, "max": 1, "espera": 0.3},
	"tesoro": {"a": "mundo/tesoro", "db": -8.0, "p": 3, "max": 1, "espera": 0.3},
	"union": {"a": "mundo/union", "db": -10.0, "p": 3, "max": 1, "espera": 1.0},
	"examinar": {"a": "mundo/examinar", "db": -11.0, "tono": 0.02, "p": 1, "max": 1, "espera": 0.3},
	"pagina": {"a": "mundo/pagina", "db": -8.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.3},
	"misterio": {"a": "mundo/misterio", "db": -10.0, "p": 3, "max": 1, "espera": 2.0},
	"palanca": {"a": "mundo/palanca", "db": -6.0, "p": 3, "max": 1, "espera": 0.5},
	"atascado": {"a": "mundo/atascado", "db": -9.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.3},
	"puente_baja": {"a": "mundo/puente_baja", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"ascensor": {"a": "mundo/ascensor", "db": -6.0, "tono": 0.03, "p": 2, "max": 1, "espera": 0.5},
	"cerrada": {"a": "mundo/cerrada", "db": -8.0, "tono": 0.04, "p": 2, "max": 1, "espera": 0.4},
	"guardado": {"a": "mundo/guardado", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"posada": {"a": "mundo/posada", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"portal": {"a": "mundo/portal", "db": -6.0, "p": 3, "max": 1, "espera": 1.0, "cruza": true},
	"entrar": {"a": "mundo/entrar", "db": -12.0, "tono": 0.05, "p": 2, "max": 1, "espera": 0.5, "cruza": true},
	"puerta_abre": {"a": "mundo/puerta_abre", "db": -9.0, "p": 3, "max": 1, "espera": 1.0},
	"brazalete": {"a": "mundo/brazalete", "db": -17.0, "tono": 0.03, "p": 1, "max": 1, "espera": 1.5},
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
	"rafaga_hierba": {"a": "ambiente/rafaga_hierba_", "n": 4, "bus": "Ambiente", "db": -14.0, "tono": 0.05, "p": 0, "max": 1, "espera": 3.0},
	"rafaga_arbol": {"a": "ambiente/rafaga_arbol_", "n": 4, "bus": "Ambiente", "db": -14.0, "tono": 0.05, "p": 0, "max": 1, "espera": 3.0},
	"pajaro": {"a": "ambiente/pajaro", "bus": "Ambiente", "db": -18.0, "tono": 0.08, "p": 0, "max": 1, "espera": 4.0},
	"hojas": {"a": "ambiente/hojas_", "n": 2, "bus": "Ambiente", "db": -16.0, "tono": 0.06, "p": 0, "max": 1, "espera": 3.0},
	"gota": {"a": "ambiente/gota_", "n": 3, "bus": "Ambiente", "db": -16.0, "tono": 0.1, "p": 0, "max": 2, "espera": 0.5},
}

# Detalles de la naturaleza por contexto de Musica: cada cuánto (s, al azar entre los dos) y qué puede sonar.
const DETALLES := {
	"pradera": {"cada": [9.0, 20.0], "efectos": ["rafaga_hierba", "rafaga_hierba", "pajaro"]},
	"ciudad": {"cada": [14.0, 28.0], "efectos": ["pajaro"]},
	"bosque": {"cada": [8.0, 18.0], "efectos": ["rafaga_arbol", "rafaga_arbol", "hojas"]},
	"viento": {"cada": [10.0, 22.0], "efectos": ["rafaga_hierba"]},
	"mazmorra": {"cada": [4.0, 11.0], "efectos": ["gota"]},
}

# Suelo de las zonas 2D (zona.gd, ESTILOS: «suelo» y «camino») → paso.
const SUELOS := {"hierba": "hierba", "hierba_oscura": "hojas", "tierra": "grava", "tierra_morada": "grava",
	"grava": "grava", "nieve": "nieve", "nieve_pisada": "nieve", "arena": "arena", "arena_dura": "arena",
	"ceniza": "arena", "basalto": "piedra", "empedrado": "piedra"}
# Fotogramas del muñeco 2D (muneco.gd, «correr», 10 por vuelta) en los que un pie toca el suelo.
const CUADROS_PASO := [1, 6]

# Voz de cada enemigo: por su clave en combate.gd (ENEMIGOS) o, si no se sabe, por su dibujo (MODELOS).
const FAMILIAS := {"slime": "limo", "grimfang": "goblin", "gorthor": "gorthor", "guardian": "piedra", "golem_ambar": "ambar"}
const FAMILIA_MODELO := {"slime": "limo", "grimfang": "goblin", "hollin": "goblin", "hollin_a": "goblin", "hollin_b": "goblin",
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
var _voz_de := {}                                          # enemigo → [su última voz, su orden] (una voz por enemigo)
var _det_ctx := ""
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
# variación de tono ni de volumen; lo usan las pruebas de señal). Devuelve el reproductor, o null si no suena
# (efecto que no existe, silencio, pausa, repetido demasiado pronto o sin voz libre).
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
	var bus: String = d.get("bus", "Efectos")
	if pausado:
		return _descartar(nombre, "pausa")
	if calla(bus):
		return _descartar(nombre, "silencio")
	var ahora := reloj                                     # tiempo de juego: igual a 30 que a 60 FPS y en las pruebas
	if ahora - float(_ultimo.get(nombre, -1000.0)) < float(d.get("espera", 0.05)):
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
	var p := _voz(nombre, bus, prioridad, int(d.get("max", 2)), op.get("en"))
	if p == null:
		return _descartar(nombre, "sin_voz")
	_ultimo[nombre] = ahora
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
	registro.append([ahora, nombre, ruta, bus])
	if registro.size() > 300:
		registro.pop_front()
	return p


# Un golpe físico resuelto: normal, crítico o contra quien se defiende. db: más bajo (el segundo tajo del doble ataque,
# que solo tiembla y no hace daño, suena así: −6 dB).
func golpe(critico := false, defendido := false, db := 0.0) -> void:
	efecto("golpe_defendido" if defendido else ("golpe_critico" if critico else "golpe"), {"db": db} if db != 0.0 else {})


# La voz de un enemigo de combate (un diccionario de combate.gd): «ataque», «herido», «caida», «muerte» (si su familia no
# la tiene, la de caída) o «devorar». Los héroes no tienen voz. Una voz por enemigo: la nueva corta la suya de antes.
# Con «furia» (menos del 30 % de vida, combate.gd), su ataque suena más fuerte y más grave.
func voz(quien: Dictionary, evento: String) -> Node:
	if quien.is_empty() or quien.get("hero", true):
		return null
	var fam := familia(quien)
	var nombre := fam + "_" + evento
	if fam != "" and not EFECTOS.has(nombre) and evento == "muerte":
		nombre = fam + "_caida"
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
func recibe(quien: Dictionary) -> void:
	voz(quien, "caida" if int(quien.get("hp", 1)) <= 0 else "herido")


static func familia(quien: Dictionary) -> String:
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


# Un reproductor para el efecto: con dueño, uno nuevo hijo suyo; si no, uno del bus. Respeta «max» (si ya suenan
# tantos, se reutiliza el más viejo de ellos) y las prioridades (si no hay hueco, se quita el menos importante).
func _voz(nombre: String, bus: String, prioridad: int, maximo: int, dueno) -> AudioStreamPlayer:
	var mismos: Array = []
	for p in _todas():
		if p.playing and p.get_meta("efecto", "") == nombre:
			mismos.append(p)
	if mismos.size() >= maximo:
		mismos.sort_custom(func(a, b): return int(a.get_meta("t", 0)) < int(b.get_meta("t", 0)))
		var viejo: AudioStreamPlayer = mismos[0]
		if dueno == null and viejo in _voces.get(bus, []):
			viejo.stop()
			return viejo
		_apagar(viejo, 0.0)
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


# Límite de un grupo (MAX_GRUPO): si ya suenan tantos, se quita el menos importante (y más viejo) si no lo es más que el
# nuevo; si todos lo son, el nuevo no suena.
func _hueco_grupo(grupo: String, prioridad: int) -> bool:
	var lista: Array = []
	for p in _todas():
		if p.playing and p.get_meta("grupo", "") == grupo and not p.get_meta("apagando", false):
			lista.append(p)
	if lista.size() < int(MAX_GRUPO.get(grupo, 99)):
		return true
	var peor: AudioStreamPlayer = null
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
	return r


func _atenuar(bus: String, _prioridad: int, excepto: AudioStreamPlayer) -> void:
	for p in _todas():
		if p != excepto and p.playing and String(p.bus) == bus and int(p.get_meta("p", 0)) < 3:
			var t := create_tween()
			t.tween_property(p, "volume_db", p.volume_db - ATENUAR_DB, 0.15)
			p.set_meta("tween", t)


func _apagar(p: AudioStreamPlayer, fundido: float) -> void:
	_parar_fundido(p)
	if fundido <= 0.0 or not p.playing:
		p.stop()
		return
	var t := create_tween()
	t.tween_property(p, "volume_db", -60.0, fundido)
	t.tween_callback(p.stop)
	p.set_meta("tween", t)
	p.set_meta("apagando", true)                           # ya se va: no cuenta para el límite de su grupo


func _parar_fundido(p: AudioStreamPlayer) -> void:
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
	_detalles(delta)


# Cambio de escena: lo de Efectos y Ambiente que no «cruza» se apaga y lo programado ya no suena.
func _al_cambiar_escena() -> void:
	_gen += 1
	_voz_de.clear()                                        # los enemigos de antes ya no existen
	for p in _todas():
		if p.playing and String(p.bus) != "Interfaz" and not p.get_meta("cruza", false):
			_apagar(p, FUNDIDO_CORTE)
	_emisores = _emisores.filter(func(x): return is_instance_valid(x))
	if _oyente != null and not is_instance_valid(_oyente):
		_oyente = null


# De vez en cuando, un detalle de la naturaleza según el lugar (DETALLES). Nunca en pausa ni en combate.
func _detalles(delta: float) -> void:
	var m = get_node_or_null("/root/Musica")
	var ctx: String = m.contexto if m != null else ""
	if ctx != _det_ctx:
		_det_ctx = ctx
		_det_t = _rng.randf_range(4.0, 9.0)
	var dd: Dictionary = DETALLES.get(ctx, {})
	if dd.is_empty() or pausado or get_tree().paused:
		return
	_det_t -= delta
	if _det_t <= 0.0:
		var lista: Array = dd["efectos"]
		efecto(lista[_rng.randi_range(0, lista.size() - 1)])
		_det_t = _rng.randf_range(dd["cada"][0], dd["cada"][1])


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
# devuelve el que ya tenía (no se duplican). db: más bajo para quien no es el que escucha (los compañeros, −3 dB).
# Dos pasos del mismo suelo con menos de 0,09 s entre ellos suenan como uno («espera» del catálogo).
func pasos_3d(cuerpo: Node3D, superficie: Callable, db := 0.0) -> Node:
	if cuerpo == null:
		return null
	for h in cuerpo.get_children():
		if h is Pasos3D:
			h.superficie = superficie
			h.db = db
			return h
	var n := Pasos3D.new()
	n.name = "Pasos"
	n.son = self
	n.cuerpo = cuerpo
	n.superficie = superficie
	n.db = db
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
	var pasos := 0

	func _ready() -> void:
		_ant = cuerpo.global_position
		_buscar_pies()

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
			return
		if pies.size() == 2 and is_instance_valid(skel):
			for f in pies:
				var y: float = (skel.global_transform * skel.get_bone_global_pose(f["i"])).origin.y - p.y
				f["min"] = minf(y, float(f["min"]) + delta * 0.05)      # lo más bajo de la vuelta (se adapta despacio)
				var vy: float = (y - float(f["y"])) / delta
				f["y"] = y
				if vy < -0.2:
					f["baja"] = true
				elif f["baja"] and vy > -0.05 and y < float(f["min"]) + ALTO_SUELO:
					f["baja"] = false
					_pisar(p)
		else:                                        # sin esqueleto: un paso cada zancada (más larga al correr)
			_acum += d
			var zancada := clampf(_vel * 0.33, 0.7, 2.2)
			if _acum >= zancada:
				_acum -= zancada
				_pisar(p)

	func _pisar(p: Vector3) -> void:
		if _t - _t_ultimo < ENTRE_PASOS:
			return
		_t_ultimo = _t
		pasos += 1
		son.efecto("paso_" + String(superficie.call(p)), {"db": db + (2.0 if _vel > 5.5 else 0.0)})


# ================================================================= ambiente 3D

# Emisor fijo (la cascada) con el bucle del efecto, por el bus Ambiente. Empieza en un punto al azar del bucle.
func fuente_3d(padre: Node3D, nombre: String, pos: Vector3) -> AudioStreamPlayer3D:
	var e := _emisor(padre, nombre, AudioStreamPlayer3D.new())
	if e != null:
		e.position = pos
	return e


# Emisor a lo largo de un segmento (un río): cada fotograma se pone en el punto del cauce más cercano a quien escucha.
func fuente_linea(padre: Node3D, nombre: String, a: Vector3, b: Vector3) -> AudioStreamPlayer3D:
	var f := FuenteLineal.new()
	f.a = a
	f.b = b
	f.son = self
	var e := _emisor(padre, nombre, f)
	if e != null:
		e.position = a.lerp(b, 0.5)
	return e


func _emisor(padre: Node3D, nombre: String, e: AudioStreamPlayer3D) -> AudioStreamPlayer3D:
	var d: Dictionary = EFECTOS.get(nombre, {})
	var s := _stream(EF + String(d.get("a", "")) + ".wav") if d.has("tres_d") else null
	if padre == null or s == null:
		e.free()
		push_warning("Sonido: no se puede crear el emisor «%s»" % nombre)
		return null
	var t: Dictionary = d["tres_d"]
	e.name = "Sonido_" + nombre
	e.stream = s
	e.bus = &"Ambiente"
	e.volume_db = float(d.get("db", 0.0))
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
