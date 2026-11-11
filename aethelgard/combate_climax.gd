extends RefCounted
# Clímax musical de los grandes jefes (V12, 11/11; docs/v12/MUSICA_JEFES.md, sección «El sistema»). Cuando la vida de un
# jefe autorizado cae al UMBRAL o menos, la música del combate se aparta y entra su canción de clímax desde el principio
# (hoy, solo Bramavidrio con «REBELUM — Volverá a amanecer»). Solo cuentas y configuración, sin estado propio:
# combate.gd guarda lo de cada combate (climax_*) y llama a vigilar() y empezar().
#
# Reglas (pruebas/prueba_climax_jefe.gd):
#   - Se activa al CRUZAR el umbral en un golpe que no lo mata (la vida de antes por encima, la de después entre 1 y el
#     umbral). Nunca con la vida sin poner (hp_max 0) ni si el jefe ya empezaba por debajo.
#   - Espera a que acabe el golpe que lo provocó: combate.gd lo deja pendiente y lo empieza cuando el combate vuelve a
#     esperar o a pedir órdenes (nunca a mitad de una animación). Si el jefe cae antes, no empieza.
#   - Una sola vez por combate (aunque haya varios jefes autorizados), no se reinicia con más golpes y no vuelve atrás si
#     el jefe se cura por encima del umbral.
#   - Música: la habitual baja en FUNDIDO s, suena un golpe de energía breve (el de la segunda fase, ya licenciado) y la
#     canción entra desde 0 por el bus Musica (respeta el volumen del jugador; en combate ese bus se aparta solo cuando
#     suenan efectos, sonido.gd APARTAR_MUSICA_EN_COMBATE). Desde ahí es la música del combate: la victoria, la derrota y
#     la huida la cierran con el fundido de siempre (combate.gd _bajar_musica).
#   - Nada se pausa: no cambia el estado del combate, ni el ATB, ni los menús, ni las animaciones.
#
# Cómo desactivarlo: ACTIVO = false (todo el sistema) o «activo»: false en el jefe de JEFES.

const ACTIVO := true
const UMBRAL := 0.2                     # parte de la vida máxima
const FUNDIDO := 0.9                    # segundos en que se aparta la música habitual
const GOLPE := "fase2"                  # el golpe de energía al empezar (sonido.gd; «» = ninguno)
const GOLPE_DB := -6.0

# Las canciones de clímax. «loop_offset»: dónde vuelve el bucle (el .import no lo lleva: se pone al sonar). «estallido»:
# segundos hasta el gran momento de la canción (el destello cae ahí).
# «db» (12/11): medido con ebur128, la música de combate normal suena a −12,2 LUFS −6 dB = −18,2 LUFS efectivos; el clímax
# (−13,9 LUFS) a −7 dB quedaba en −20,9, casi 3 dB por DEBAJO de la música que sustituye. A −4,5 dB queda en −18,4.
const PISTAS := {
	"volvera_a_amanecer": {"ruta": "res://audio/musica/jefes/volvera_a_amanecer_climax.ogg", "loop_offset": 13.62,
		"estallido": 1.2, "db": -4.5, "titulo": "Volverá a amanecer"},
}

# Categorías: quién puede tenerlo. Los enemigos normales, los de élite y los minijefes, nunca por defecto; los jefes
# principales se pueden elegir; los grandes jefes narrativos son los candidatos; los jefes finales tendrán su propia
# banda (una pista suya en PISTAS).
const CATEGORIAS := {
	"normal": {"permitido": false},
	"elite": {"permitido": false},
	"minijefe": {"permitido": false},
	"jefe": {"permitido": true},
	"gran_jefe": {"permitido": true},
	"final": {"permitido": true, "pista_propia": true},
}

# Jefes (la clave de ENEMIGOS en combate.gd). Solo Bramavidrio está activo (demostración pedida por el usuario).
const JEFES := {
	"bramavidrio": {"categoria": "gran_jefe", "pista": "volvera_a_amanecer", "activo": true},
	"coloso_falla": {"categoria": "jefe", "pista": "volvera_a_amanecer", "activo": false},
	"guardian_bosque": {"categoria": "gran_jefe", "pista": "volvera_a_amanecer", "activo": false},
	"gorthor": {"categoria": "jefe", "pista": "volvera_a_amanecer", "activo": false},
	"guardian": {"categoria": "minijefe", "activo": false},
	"golem_ambar": {"categoria": "minijefe", "activo": false},
}


# La configuración del clímax de este enemigo, o {} si no tiene. Los de élite, nunca.
static func de(e: Dictionary) -> Dictionary:
	if not ACTIVO or e.get("hero", false) or e.get("elite", false):
		return {}
	var j: Dictionary = JEFES.get(str(e.get("clave", "")), {})
	if j.is_empty() or not j.get("activo", false):
		return {}
	if not CATEGORIAS.get(j.get("categoria", "normal"), {}).get("permitido", false):
		return {}
	if not PISTAS.has(j.get("pista", "")) or not ResourceLoader.exists(PISTAS[j["pista"]]["ruta"]):
		return {}
	return j


# ¿Este golpe lo cruza? «antes» y «despues», su vida; solo si sigue en pie y empezaba por encima del umbral.
static func cruza(antes: int, despues: int, hp_max: int) -> bool:
	if hp_max <= 0 or despues <= 0:
		return false
	var u := hp_max * UMBRAL
	return float(antes) > u and float(despues) <= u


# El reproductor de la canción (aún sin sonar): bus Musica, bucle con su loop_offset.
static func reproductor(pista: String) -> AudioStreamPlayer:
	var d: Dictionary = PISTAS[pista]
	var s = load(d["ruta"])
	if s is AudioStreamOggVorbis or s is AudioStreamMP3:
		s.loop = true
		s.loop_offset = float(d["loop_offset"])
	var p := AudioStreamPlayer.new()
	p.name = "MusicaClimax"
	p.stream = s
	p.volume_db = float(d["db"])
	p.bus = &"Musica"
	return p
