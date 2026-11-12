# Héroes v2 (fase B, V12): biblioteca común de clips para Kael, Lya y Garon.
#
# Cada clip es una lista de claves (segundos, pose) escrita en el espacio del personaje (rig_comun.py), así que el mismo
# clip vale para los tres esqueletos. La personalidad entra por el ESTILO de cada héroe (postura, anchura de los pies,
# ritmo, energía) y por su arma (sable, cetro o dos espadas), que cambia lo que hacen las manos.
#
# CONTRATO (lo usan heroe_v2_3d.gd y la documentación de integración; los nombres no se cambian sin avisar):
#   reposo            bucle   exploración: respira, cambia el peso y mira alrededor
#   guardia           bucle   combate: la guardia de cada uno
#   hablar, hablar_b          conversación: dos gestos distintos que empiezan y acaban en el reposo
#   asentir                   asentir con la cabeza (desde el reposo)
#   interactuar               coger o tocar algo delante y abajo; «contacto» = instante en que la mano llega
#   saltar                    salto en el sitio (exploración): «despegue» y «aterrizaje»
#   girar                     pasos en el sitio para acompañar un giro del nodo (el giro lo hace el código)
#   ataque                    ataque básico; «impacto» = instante del golpe (Kael: 0,64 s, el del salto de kael_3d.gd)
#   magia_lanzar              lanzar; «lanzamiento» = instante en que sale el hechizo (Kael 0,85 s, Lya 0,5 s)
#   magia_concentrar  bucle   concentrarse antes de una magia larga (Lya)
#   magia_poderosa            solo Lya: magia grande; «lanzamiento» a 1,5 s
#   recibir_golpe             golpe recibido: «impacto» a 0 s, vuelve a la guardia
#   derribo                   cae al suelo y se queda allí (KO)
#   derrota           bucle   en el suelo, respirando
#   levantarse                del suelo a la guardia (revivir)
#   victoria                  celebración que acaba en una pose quieta
# Los clips de andar y correr NO se rehacen: son los de captura de Meshy (mejores), renombrados «andar» y «correr».
import math

FPS = 30


def mezclar(a, b):
    """Copia de «a» con «b» encima (los diccionarios anidados se mezclan; lo demás se sustituye)."""
    r = dict(a)
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(r.get(k), dict):
            r[k] = mezclar(r[k], v)
        else:
            r[k] = v
    return r


def suma(a, b, f=1.0):
    return tuple(x + y * f for x, y in zip(tuple(a) + (0,) * (3 - len(a)), tuple(b) + (0,) * (3 - len(b))))


# ------------------------------------------------------------------ estilos de cada héroe
ESTILOS = {
    # joven, valiente, con humor: el pecho fuera, la barbilla alta, rebota en la guardia, gestos amplios y rápidos
    "Kael": {"pecho": -4.0, "barbilla": -4.0, "anchura": 0.03, "bajar": 0.0, "ritmo": 1.0, "energia": 1.15,
             "arma": "sable"},
    # inteligente y cálida: erguida, la cabeza un poco ladeada, pies juntos, gestos suaves y algo más lentos
    "Lya": {"pecho": -2.0, "barbilla": 2.0, "ladeo": 5.0, "anchura": -0.03, "bajar": 0.0, "ritmo": 1.15,
            "energia": 0.8, "arma": "cetro"},
    # veterano, disciplinado, con peso: base ancha, rodillas algo dobladas, hombros atrás, movimientos lentos y firmes
    "Garon": {"pecho": -5.0, "barbilla": 3.0, "anchura": 0.08, "bajar": 0.03, "ritmo": 1.25, "energia": 0.7,
              "arma": "dos_espadas"},
}

ABAJO = {"pos": (0.06, -0.9, 0.2), "codo": (-0.4, -0.3, 1.0), "dedos": (0.2, -1, 0.05), "palma": (0, 0, -1), "cierre": 22}


def base(e):
    an = e["anchura"]
    return {
        "cadera": (0, -0.01 - e["bajar"], 0),
        "columna": (e["pecho"], 0, 0),
        "cuello": (2, 0, 0),
        "cabeza": (e["barbilla"], e.get("ladeo", 0.0), 0),
        "pie_d": {"pos": (0.0, 0, 0.02 + an), "giro": 12},
        "pie_i": {"pos": (0.02, 0, 0.02 + an), "giro": 10},
        "mano_d": dict(ABAJO), "mano_i": dict(ABAJO),
    }


# ------------------------------------------------------------------ manos con arma
def mano_arma(e, que):
    """Mano derecha (y la izquierda de Garon) según el arma y la situación."""
    a = e["arma"]
    if a == "sable":
        return {
            # sable al hombro: es su reposo de siempre (el clip de Meshy), conservado como identidad
            "hombro": {"pos": (0.28, 0.02, -0.2), "codo": (0.3, -1.0, 0.5), "hoja": (-0.85, 0.5, 0.12),
                       "filo": (0.3, 0.9, 0.0), "cierre": 75},
            "guardia": {"pos": (0.5, -0.45, 0.2), "codo": (-0.2, -1, 0.6), "hoja": (0.75, 0.85, 0.08),
                        "filo": (0.6, -0.5, 0.2), "cierre": 75},
            "abajo": {"pos": (0.15, -0.88, 0.22), "codo": (-0.4, -0.3, 1.0), "hoja": (0.6, -1.0, 0.1),
                      "filo": (1, 0.4, 0), "cierre": 75},
        }[que]
    if a == "cetro":
        return {
            "hombro": {"pos": (0.25, -0.78, 0.32), "codo": (-0.4, -0.4, 1.0), "hoja": (0.05, 1.0, 0.0),
                       "filo": (1, 0, 0), "cierre": 70},
            "guardia": {"pos": (0.45, -0.55, 0.3), "codo": (-0.3, -1.0, 0.8), "hoja": (0.2, 1.0, 0.05),
                        "filo": (1, 0, 0), "cierre": 70},
            "abajo": {"pos": (0.25, -0.78, 0.32), "codo": (-0.4, -0.4, 1.0), "hoja": (0.05, 1.0, 0.0),
                      "filo": (1, 0, 0), "cierre": 70},
        }[que]
    # dos espadas (Garon): las hojas bajas hacia delante; en guardia, cruzadas delante del cuerpo
    return {
        "hombro": {"pos": (0.12, -0.86, 0.25), "codo": (-0.4, -0.3, 1.0), "hoja": (0.55, -1.0, 0.15),
                   "filo": (1, 0.5, 0), "cierre": 78},
        "guardia": {"pos": (0.6, -0.4, 0.05), "codo": (-0.2, -1, 0.7), "hoja": (0.7, 0.75, -0.45),
                    "filo": (0.6, -0.6, 0.3), "cierre": 78},
        "abajo": {"pos": (0.12, -0.86, 0.25), "codo": (-0.4, -0.3, 1.0), "hoja": (0.55, -1.0, 0.15),
                  "filo": (1, 0.5, 0), "cierre": 78},
    }[que]


def mano_libre(e, que):
    """La otra mano (izquierda) de Kael y Lya; Garon lleva la segunda espada."""
    if e["arma"] == "dos_espadas":
        return mano_arma(e, que)
    if e["arma"] == "sable":
        return {
            "hombro": {"ref": "cadera", "pos": (0.02, 0.04, 0.2), "codo": (-0.3, 0.0, 1.0), "dedos": (0.5, -1.0, -0.3),
                       "palma": (0, 0, -1), "cierre": 35, "pulgar": 10},   # mano en la cadera
            "guardia": {"pos": (0.55, -0.35, 0.1), "codo": (-0.3, -1, 0.6), "dedos": (1, 0.4, 0.0), "palma": (0, -0.3, -1),
                        "cierre": 18},
            "abajo": dict(ABAJO),
        }[que]
    return {   # Lya: la izquierda recogida delante, junto a la cintura, con calma
        "hombro": {"pos": (0.35, -0.72, -0.05), "codo": (-0.4, -0.6, 1.0), "dedos": (0.6, -0.3, -1.0), "palma": (0, 1, -0.3),
                   "cierre": 25},
        "guardia": {"pos": (0.6, -0.3, 0.05), "codo": (-0.3, -1.0, 0.8), "dedos": (1, 0.3, -0.2), "palma": (0.3, 0, -1),
                    "cierre": 15},
        "abajo": dict(ABAJO),
    }[que]


def reposo_pose(e):
    d = base(e)
    d["mano_d"] = mano_arma(e, "hombro")
    d["mano_i"] = mano_libre(e, "hombro")
    if e["arma"] == "sable":   # Kael: el peso en una pierna, la cadera suelta
        d = mezclar(d, {"cadera": (0, -0.012, 0.02), "cadera_giro": (0, -3, 4), "columna": (e["pecho"], 2, -3),
                        "pie_d": {"pos": (0.04, 0, 0.05), "giro": 18}})
    elif e["arma"] == "cetro":  # Lya: un pie algo adelantado, como quien posa sin querer
        d = mezclar(d, {"pie_d": {"pos": (0.05, 0, 0.0), "giro": 14}, "cadera_giro": (0, 2, -3)})
    else:                        # Garon: plantado, ancho, hombros atrás
        d = mezclar(d, {"hombro_d": (-3, -4), "hombro_i": (-3, -4)})
    return d


def guardia_pose(e):
    d = base(e)
    if e["arma"] == "sable":
        d = mezclar(d, {"cadera": (0, -0.07, 0), "cadera_giro": (4, 0, 22), "columna": (8, 0, -14), "cabeza": (-2, 0, -12),
                        "pie_i": {"pos": (0.12, 0, 0.05), "giro": 0}, "pie_d": {"pos": (-0.1, 0, 0.08), "giro": 40}})
    elif e["arma"] == "cetro":
        d = mezclar(d, {"cadera": (0, -0.03, 0), "cadera_giro": (0, 0, 12), "columna": (3, 0, -8), "cabeza": (0, 3, -6),
                        "pie_i": {"pos": (0.07, 0, 0.03), "giro": 5}, "pie_d": {"pos": (-0.04, 0, 0.04), "giro": 25}})
    else:
        d = mezclar(d, {"cadera": (0, -0.1, 0), "cadera_giro": (5, 0, 10), "columna": (10, 0, -6), "cabeza": (4, 0, -6),
                        "pie_i": {"pos": (0.12, 0, 0.08), "giro": 8}, "pie_d": {"pos": (-0.1, 0, 0.1), "giro": 30},
                        "hombro_d": (2, 6), "hombro_i": (2, 6)})
    d["mano_d"] = mano_arma(e, "guardia")
    d["mano_i"] = mano_libre(e, "guardia")
    d["mirada"] = 4.0                # mire como se incline, los ojos van al enemigo
    return d


# ------------------------------------------------------------------ utilidades de claves
def var(d, **cambios):
    return mezclar(d, cambios)


def cadera_mas(d, v):
    return mezclar(d, {"cadera": suma(d.get("cadera", (0, 0, 0)), v)})


def col_mas(d, v, clave="columna"):
    return mezclar(d, {clave: suma(d.get(clave, (0, 0, 0)), v)})


def clip(nombre, dur, claves, bucle=False, eventos=None):
    return {"nombre": nombre, "dur": dur, "claves": claves, "bucle": bucle, "eventos": eventos or {}}


# ------------------------------------------------------------------ clips
def c_reposo(e):
    r = e["ritmo"]
    p = reposo_pose(e)
    dur = 4.0 * r
    a = p
    b = col_mas(cadera_mas(p, (0, -0.006, 0)), (1.5, 0, 0))                  # suelta el aire
    c = col_mas(col_mas(cadera_mas(p, (0, 0.002, -0.01)), (-1.0, 0, 2), "columna"), (2, -2, 14), "cabeza")   # mira a un lado
    d2 = col_mas(cadera_mas(p, (0, -0.006, 0)), (1.0, 0, 0))
    return clip("reposo", dur, [(0, a), (dur * 0.27, b), (dur * 0.5, c), (dur * 0.62, c), (dur * 0.8, d2), (dur, a)],
                bucle=True)


def c_guardia(e):
    g = guardia_pose(e)
    if e["arma"] == "sable":   # rebota sobre las puntas, joven e impaciente
        dur = 1.0
        arriba = mezclar(cadera_mas(g, (0, 0.025, 0)), {"pie_d": {"punta": 10}, "pie_i": {"punta": 10}})
        abajo = col_mas(cadera_mas(g, (0, -0.012, 0)), (2, 0, 0))
        return clip("guardia", dur, [(0, abajo), (0.25, arriba), (0.5, abajo), (0.75, arriba), (1.0, abajo)], bucle=True)
    if e["arma"] == "cetro":   # ligera, el cetro late con la respiración
        dur = 2.4
        b = col_mas(cadera_mas(g, (0, 0.008, 0)), (-1.5, 0, 0))
        b = mezclar(b, {"mano_i": {"pos": suma(g["mano_i"]["pos"], (0.03, 0.05, 0))}})
        return clip("guardia", dur, [(0, g), (1.2, b), (2.4, g)], bucle=True)
    dur = 3.0                   # Garon: firme; solo respira y asienta el peso
    b = col_mas(cadera_mas(g, (0, -0.012, 0)), (1.5, 0, 0))
    return clip("guardia", dur, [(0, g), (1.5, b), (3.0, g)], bucle=True)


def c_hablar(e, variante=False):
    r = e["ritmo"]
    p = reposo_pose(e)
    en = e["energia"]
    if not variante:   # la mano libre se abre hacia quien escucha, palma arriba, y vuelve
        ma = {"pos": (0.55, -0.35 + 0.1 * en, 0.15), "codo": (-0.3, -1, 0.7), "dedos": (1, 0.1, 0.25),
              "palma": (0, 1, 0), "cierre": 10, "pulgar": 0}
        mb = mezclar(ma, {"pos": (0.45, -0.32 + 0.1 * en, 0.42), "dedos": (0.6, 0.15, 0.8)})
        if e["arma"] == "dos_espadas":
            ma = mezclar(mano_arma(e, "hombro"), {"pos": (0.4, -0.55, 0.15), "hoja": (0.9, -0.7, 0.1)})
            mb = mezclar(ma, {"pos": (0.42, -0.5, 0.25)})
        k1 = mezclar(col_mas(p, (3, 0, 0)), {"mano_i": ma, "cabeza": suma(p["cabeza"], (4, 0, -4))})
        k2 = mezclar(col_mas(p, (2, 0, 4)), {"mano_i": mb, "cabeza": suma(p["cabeza"], (1, 3, 4))})
        dur = 2.4 * r
        return clip("hablar", dur, [(0, p), (0.45 * r, k1), (1.1 * r, k2), (1.6 * r, k2), (dur, p)])
    # variante: la mano libre al pecho (sincero, «yo»), un leve ladeo y vuelta
    mc = {"pos": (0.35, -0.22, -0.4), "codo": (-0.2, -1, 0.8), "dedos": (0.0, 0.3, -1.0), "palma": (-1, 0, 0),
          "cierre": 15}
    if e["arma"] == "dos_espadas":   # Garon: puño al pecho, saludo de soldado
        mc = mezclar(mano_arma(e, "hombro"), {"pos": (0.42, -0.2, -0.35), "hoja": (0.3, -1.0, 0.0), "codo": (-0.2, -1, 1.0)})
    k1 = mezclar(col_mas(p, (-2, 0, 0)), {"mano_i": mc, "cabeza": suma(p["cabeza"], (-3, -5, 0))})
    k2 = mezclar(k1, {"cabeza": suma(p["cabeza"], (5, -3, 0))})
    dur = 2.2 * r
    return clip("hablar_b", dur, [(0, p), (0.5 * r, k1), (1.2 * r, k2), (1.6 * r, k2), (dur, p)])


def c_asentir(e):
    r = e["ritmo"]
    p = reposo_pose(e)
    ab = mezclar(p, {"cabeza": suma(p["cabeza"], (14 * e["energia"], 0, 0)), "cuello": (6, 0, 0)})
    ar = mezclar(p, {"cabeza": suma(p["cabeza"], (-3, 0, 0))})
    dur = 0.9 * r
    return clip("asentir", dur, [(0, p), (0.18 * r, ab), (0.36 * r, ar), (0.54 * r, ab), (dur, p)])


def c_interactuar(e):
    r = e["ritmo"]
    p = reposo_pose(e)
    # se inclina y alarga la mano libre hacia algo delante y abajo; la del arma se queda donde está
    alcanza = {"ref": "mundo", "pos": (0.32, 0.42, -0.04), "codo": (-0.3, 0.2, 1.0), "dedos": (0.5, -1.0, 0.0),
               "palma": (0, -1, -0.3), "cierre": 10, "pulgar": 5, "marco_mano": "mundo"}
    agarra = mezclar(alcanza, {"cierre": 60, "pulgar": 30})
    k1 = mezclar(cadera_mas(p, (-0.03, -0.12, 0)), {"columna": (30, 0, 0), "cabeza": (12, 0, 0),
                                                    "pie_i": {"pos": (0.1, 0, 0.04)}, "mano_i": alcanza})
    k2 = mezclar(k1, {"mano_i": agarra})
    medio = mezclar(cadera_mas(p, (-0.01, -0.05, 0)), {"columna": (12, 0, 0),
                                                         "mano_i": {"pos": (0.5, -0.35, 0.05), "dedos": (1, 0.3, 0),
                                                                    "palma": (0, 1, 0), "cierre": 55, "codo": (-0.3, -1, 0.6)}})
    dur = 1.4 * r
    return clip("interactuar", dur, [(0, p), (0.45 * r, k1), (0.6 * r, k2), (0.95 * r, medio), (dur, p)],
                eventos={"contacto": 0.6 * r})


def c_saltar(e):
    p = reposo_pose(e)
    sube = 0.32 / e["ritmo"]
    agacha = mezclar(cadera_mas(p, (0, -0.16, 0)), {"columna": (18, 0, 0),
                                                     "mano_i": {"pos": (-0.2, -0.75, 0.25), "dedos": (-0.3, -1, 0.1)}})
    impulso = mezclar(cadera_mas(p, (0, 0.12, 0)), {"columna": (-4, 0, 0), "pie_d": {"pos": (-0.02, 0.1, 0.02), "punta": 40},
                                                     "pie_i": {"pos": (0.02, 0.1, 0.02), "punta": 40},
                                                     "mano_i": {"pos": (0.4, -0.1, 0.3), "dedos": (1, 0.5, 0.2)}})
    alto = mezclar(cadera_mas(p, (0, sube, 0)), {"columna": (6, 0, 0), "pie_d": {"pos": (-0.05, sube + 0.12, 0.02), "punta": 20},
                                                  "pie_i": {"pos": (0.06, sube + 0.18, 0.02), "punta": 15},
                                                  "mano_i": {"pos": (0.35, 0.0, 0.45), "dedos": (0.5, 0.6, 0.6)}})
    cae = mezclar(cadera_mas(p, (0, -0.13, 0)), {"columna": (16, 0, 0)})
    return clip("saltar", 0.95, [(0, p), (0.16, agacha), (0.3, impulso), (0.47, alto), (0.62, impulso), (0.7, cae),
                                 (0.95, p)], eventos={"despegue": 0.3, "aterrizaje": 0.65})


def c_girar(e):
    p = reposo_pose(e)
    r = e["ritmo"]
    k1 = mezclar(p, {"cabeza": suma(p["cabeza"], (0, 0, 18)), "pie_d": {"pos": (0.0, 0.07, 0.03), "giro": 35}})
    k2 = mezclar(p, {"columna": suma(p["columna"], (0, 0, 6)), "pie_d": {"giro": 30}})
    k3 = mezclar(k2, {"pie_i": {"pos": (0.02, 0.07, 0.0), "giro": -10}})
    dur = 0.6 * r
    return clip("girar", dur, [(0, p), (0.15 * r, k1), (0.3 * r, k2), (0.45 * r, k3), (dur, p)])


def c_ataque(e):
    g = guardia_pose(e)
    if e["arma"] == "sable":
        # el salto con caída cortante de kael_3d.gd: se agacha (0,2 s), salta con el sable en alto (0,3 s) y corta
        # (0,14 s): impacto a 0,64 s. El combate mueve el salto en pantalla; aquí solo el cuerpo.
        agacha = mezclar(cadera_mas(g, (0, -0.16, 0)), {"columna": (28, 0, -10), "cabeza": (-12, 0, -10),
                         "mano_d": {"pos": (-0.1, -0.7, 0.35), "hoja": (-0.7, -0.5, 0.3), "codo": (-0.6, -0.4, 1.0)},
                         "mano_i": {"pos": (0.6, -0.4, 0.1)}})
        despega = mezclar(cadera_mas(g, (0, 0.12, 0)), {"mirada": None, "columna": (0, 0, -6), "pie_d": {"pos": (-0.12, 0.08, 0.06), "punta": 45},
                          "pie_i": {"pos": (0.1, 0.08, 0.04), "punta": 40},
                          "mano_d": {"pos": (0.1, 0.5, 0.15), "hoja": (-0.4, 0.9, 0.1), "codo": (0, -0.3, 1.0)}})
        alto = mezclar(cadera_mas(g, (0, 0.16, 0)), {"mirada": -8.0, "columna": (-14, 0, -4), "cabeza": (-14, 0, -6),
                       "pie_d": {"pos": (-0.18, 0.32, 0.04), "punta": 25}, "pie_i": {"pos": (0.05, 0.38, 0.03), "punta": 15},
                       "mano_d": {"pos": (0.0, 0.95, 0.05), "hoja": (-0.55, 0.8, 0.05), "filo": (0.8, 0.6, 0), "codo": (0, 0, 1.0)},
                       "mano_i": {"pos": (0.15, 0.85, -0.1), "dedos": (0, 1, 0), "codo": (0, 0, 1.0)}})
        corte = mezclar(cadera_mas(g, (0.04, -0.14, 0)), {"cadera_giro": (6, 0, 8), "columna": (14, 0, 4), "cabeza": (0, 0, -4), "mirada": 12.0,
                        "pie_i": {"pos": (0.16, 0, 0.05)}, "pie_d": {"pos": (-0.14, 0, 0.08), "giro": 30, "punta": 25},
                        "mano_d": {"pos": (0.85, -0.1, -0.05), "hoja": (0.95, -0.35, 0.0), "filo": (-0.3, -1.0, 0.0), "marco_mano": "mundo",
                                   "codo": (0, -1, 0.5)},
                        "mano_i": {"pos": (0.2, -0.75, 0.55), "dedos": (-0.3, -1, 0.5)}})
        sigue = mezclar(cadera_mas(corte, (0, -0.02, 0)), {"mano_d": {"pos": (0.75, -0.3, 0.0), "hoja": (0.8, -0.5, -0.1)}})
        return clip("ataque", 1.3, [(0, g), (0.2, agacha), (0.32, despega), (0.5, alto), (0.64, corte), (0.82, sigue),
                                    (1.3, g)], eventos={"impacto": 0.64})
    if e["arma"] == "cetro":
        # Lya: un golpe con el cetro (como el «golpe» de gestos_3d.gd), impacto a 0,45 s (sin cambiar).
        # 13/11 (pulido): más anticipación. Carga el peso atrás y enrosca el tronco con el cetro alto detrás del hombro
        # (0,1-0,3 s), lo sostiene un instante (0,36), golpea rápido (0,45), sigue de largo (0,55) y vuelve.
        carga = mezclar(cadera_mas(g, (-0.03, -0.02, 0)), {"columna": (-4, 0, -14), "cabeza": (0, 3, -2),
                        "mano_d": {"pos": (0.05, 0.2, 0.45), "hoja": (-0.3, 0.95, 0.25), "codo": (-0.3, -0.6, 1)},
                        "mano_i": {"pos": (0.55, -0.15, 0.1), "dedos": (1, 0.3, 0.0), "palma": (0, -0.3, -1), "cierre": 12}})
        prep = mezclar(cadera_mas(g, (-0.05, -0.05, 0)), {"mirada": 6.0, "columna": (-10, 0, -28), "cabeza": (0, 3, 8),
                       "pie_d": {"punta": 8},
                       "mano_d": {"pos": (-0.22, 0.45, 0.38), "hoja": (-0.65, 0.75, 0.35), "codo": (-0.3, -0.4, 1)},
                       "mano_i": {"pos": (0.6, -0.05, 0.05), "dedos": (1, 0.4, -0.1), "palma": (0, -0.3, -1), "cierre": 10}})
        sost = mezclar(prep, {"columna": (-11, 0, -31), "mano_d": {"pos": (-0.25, 0.48, 0.38)}})
        golpe = mezclar(cadera_mas(g, (0.06, -0.07, 0)), {"columna": (16, 0, 12), "pie_i": {"pos": (0.15, 0, 0.03)},
                        "mano_d": {"pos": (0.8, -0.2, 0.0), "hoja": (0.9, -0.3, -0.1), "codo": (0, -1, 0.6)},
                        "mano_i": {"pos": (0.2, -0.6, 0.45), "dedos": (-0.3, -1, 0.3)}})
        sigue = mezclar(cadera_mas(golpe, (0.01, -0.01, 0)), {"columna": (20, 0, 16),
                        "mano_d": {"pos": (0.72, -0.42, -0.12), "hoja": (0.7, -0.65, -0.25), "codo": (0, -1, 0.5)}})
        return clip("ataque", 1.0, [(0, g), (0.12, carga), (0.3, prep), (0.36, sost), (0.45, golpe), (0.55, sigue),
                                    (0.68, sigue), (1.0, g)], eventos={"impacto": 0.45})
    # Garon: tajo doble contundente (dos espadas de arriba abajo), impacto a 0,7 s
    prep = mezclar(cadera_mas(g, (-0.03, -0.04, 0)), {"columna": (-10, 0, -10), "cabeza": (0, 0, -4),
                   "mano_d": {"pos": (0.0, 0.8, 0.2), "hoja": (-0.6, 0.8, 0.1), "codo": (0, 0, 1)},
                   "mano_i": {"pos": (0.0, 0.8, 0.2), "hoja": (-0.6, 0.8, -0.1), "codo": (0, 0, 1)}})
    golpe = mezclar(cadera_mas(g, (0.06, -0.12, 0)), {"columna": (30, 0, 0), "pie_i": {"pos": (0.2, 0, 0.08)},
                    "mano_d": {"pos": (0.8, -0.3, 0.1), "hoja": (0.7, -0.7, 0.05), "codo": (0, -1, 0.6)},
                    "mano_i": {"pos": (0.8, -0.3, 0.1), "hoja": (0.7, -0.7, -0.05), "codo": (0, -1, 0.6)}})
    return clip("ataque", 1.5, [(0, g), (0.45, prep), (0.58, prep), (0.7, golpe), (0.95, golpe), (1.5, g)],
                eventos={"impacto": 0.7})


def c_magia_lanzar(e):
    g = guardia_pose(e)
    if e["arma"] == "sable":   # sable en vertical y estocada: el hechizo sale de la punta a 0,85 s
        # 13/11 (pulido): el sable MÁS ALTO, por encima de la cabeza y algo por fuera (antes, a la altura de la cara:
        # la empuñadura la tapaba); la izquierda, abierta junto a la hoja. Mismos instantes.
        alza = mezclar(cadera_mas(g, (0, 0.015, 0)), {"mirada": -6.0, "columna": (-5, 0, -4), "cabeza": (-2, 0, -4),
                       "mano_d": {"pos": (0.35, 0.72, 0.18), "hoja": (0.08, 1.0, 0.05), "filo": (1, 0, 0), "codo": (0, -0.6, 1)},
                       "mano_i": {"pos": (0.45, 0.4, -0.3), "dedos": (0.0, 1.0, 0.2), "palma": (1, 0, 0), "cierre": 5}})
        lanza = mezclar(cadera_mas(g, (0.05, -0.08, 0)), {"columna": (16, 0, -10), "cabeza": (0, 0, -10),
                        "pie_i": {"pos": (0.18, 0, 0.05)},
                        "mano_d": {"pos": (0.95, 0.05, 0.0), "hoja": (1.0, 0.2, -0.1), "filo": (0, -1, 0), "codo": (0, -1, 0.5)},
                        "mano_i": {"pos": (0.2, -0.5, 0.6), "dedos": (-0.3, -0.5, 1.0)}})
        return clip("magia_lanzar", 1.4, [(0, g), (0.45, alza), (0.7, alza), (0.85, lanza), (1.1, lanza), (1.4, g)],
                    eventos={"lanzamiento": 0.85})
    # Lya: el cetro en alto y la mano libre abierta hacia delante; sale a 0,5 s
    alza = mezclar(cadera_mas(g, (0, 0.01, 0)), {"columna": (-6, 0, 0), "cabeza": (-6, 2, 0),
                   "mano_d": {"pos": (0.35, 0.55, 0.25), "hoja": (0.25, 1.0, 0.0), "codo": (-0.2, -1, 1)},
                   "mano_i": {"pos": (0.75, 0.0, 0.1), "dedos": (1, 0.2, 0), "palma": (1, 0, 0), "cierre": 5, "pulgar": 0}})
    suelta = mezclar(alza, {"columna": (6, 0, 0), "mano_i": {"pos": (0.95, -0.1, 0.05)},
                            "mano_d": {"pos": (0.5, 0.6, 0.2), "hoja": (0.5, 0.9, 0)}})
    return clip("magia_lanzar", 1.1, [(0, g), (0.35, alza), (0.5, suelta), (0.75, suelta), (1.1, g)],
                eventos={"lanzamiento": 0.5})


def c_magia_concentrar(e):
    g = guardia_pose(e)
    k = mezclar(cadera_mas(g, (0, -0.01, 0)), {"mirada": 22.0, "columna": (-3, 0, 0), "cabeza": (10, 0, 0),
                "mano_d": {"pos": (0.45, -0.1, 0.0), "hoja": (0.05, 1.0, 0.0), "codo": (-0.2, -1, 0.8)},
                "mano_i": {"pos": (0.5, -0.05, -0.35), "dedos": (0.3, 1.0, 0.2), "palma": (0.2, 0, 1), "cierre": 10}})
    k2 = mezclar(cadera_mas(k, (0, 0.012, 0)), {"columna": (-5, 0, 0), "mano_i": {"pos": (0.52, 0.0, -0.33)}})
    return clip("magia_concentrar", 2.0, [(0, k), (1.0, k2), (2.0, k)], bucle=True)


def c_magia_poderosa(e):
    g = guardia_pose(e)
    conc = c_magia_concentrar(e)["claves"][0][1]
    alza = mezclar(cadera_mas(g, (0, 0.03, 0)), {"mirada": -25.0, "columna": (-14, 0, 0), "cabeza": (-16, 0, 0),
                   "pie_d": {"punta": 15}, "pie_i": {"punta": 15},
                   "mano_d": {"pos": (0.2, 0.95, 0.15), "hoja": (0.1, 1.0, 0.0), "codo": (0, -0.5, 1)},
                   "mano_i": {"pos": (0.2, 0.9, 0.35), "dedos": (0.1, 1, 0.3), "palma": (1, 0, 0), "cierre": 5, "pulgar": 0}})
    baja = mezclar(cadera_mas(g, (0.04, -0.1, 0)), {"columna": (18, 0, 0), "cabeza": (0, 0, 0),
                   "pie_i": {"pos": (0.15, 0, 0.04)},
                   "mano_d": {"pos": (0.85, 0.15, 0.1), "hoja": (1.0, 0.5, 0.0), "codo": (0, -1, 0.6)},
                   "mano_i": {"pos": (0.9, -0.05, 0.05), "dedos": (1, 0.1, 0), "palma": (1, 0, 0), "cierre": 5, "pulgar": 0}})
    return clip("magia_poderosa", 2.4, [(0, g), (0.4, conc), (0.9, conc), (1.3, alza), (1.5, baja), (1.9, baja), (2.4, g)],
                eventos={"lanzamiento": 1.5})


def c_recibir_golpe(e):
    g = guardia_pose(e)
    f = 1.0 / max(e["energia"], 0.5) if e["arma"] != "dos_espadas" else 0.6   # Garon apenas se mueve
    golpe = mezclar(cadera_mas(g, (-0.05 * f, -0.03, 0)), {"mirada": None, "columna": suma(g["columna"], (-16 * f, 5 * f, 6)),
                    "cabeza": suma(g["cabeza"], (-14 * f, -6, 10)), "pie_d": {"punta": 0}, "pie_i": {"punta": 0}})
    golpe["mano_i"] = mezclar(g["mano_i"], {"pos": suma(g["mano_i"]["pos"], (-0.25, 0.15, 0.2))})
    vuelve = mezclar(cadera_mas(g, (-0.02, -0.04, 0)), {"columna": suma(g["columna"], (4, 0, 0))})
    return clip("recibir_golpe", 0.7, [(0, g), (0.08, golpe), (0.28, vuelve), (0.7, g)], eventos={"impacto": 0.0})


def _suelo_base(e):
    # tumbado boca arriba, los brazos abiertos en el suelo; el arma suelta junto a la mano
    return {"cadera": (-0.3, -0.74, 0), "cadera_giro": (-86, 0, 0), "columna": (-4, 0, 0), "cuello": (0, 0, 0),
            "cabeza": (-6, 4, 22),
            "pie_d": {"pos": (0.48, 0.06, 0.08), "rodilla": (0, 1, 0.3), "punta": -60},
            "pie_i": {"pos": (0.42, 0.14, 0.03), "rodilla": (0, 1, 0.1), "punta": -50},
            "mano_d": {"pos": (-0.1, 0.1, 0.9), "codo": (-1, 0, 0.3), "dedos": (0, 0.2, 1), "palma": (-1, 0, 0), "cierre": 40,
                       "hoja": (0.35, 0.02, 1.0), "filo": (0, 1, 0), "marco_mano": "mundo"},
            "mano_i": {"pos": (0.15, 0.2, 0.85), "codo": (-1, 0, 0.3), "dedos": (0.2, 0.2, 1), "palma": (-1, 0, 0), "cierre": 30}}


def _suelo(e):
    s = _suelo_base(e)
    if e["arma"] == "cetro":    # Lya: las piernas estiradas y juntas (con la falda, las rodillas en alto se veían mal)
        s = mezclar(s, {"cadera_giro": (-88, 6, 0), "pie_d": {"pos": (0.7, 0.03, 0.04), "rodilla": (0, 1, 0.2), "punta": -70},
                        "pie_i": {"pos": (0.66, 0.06, 0.0), "rodilla": (0, 1, 0.1), "punta": -65}})
    return s


def c_derribo(e):
    g = guardia_pose(e)
    golpe = mezclar(cadera_mas(g, (-0.05, -0.04, 0)), {"mirada": None, "columna": (-18, 6, 0), "cabeza": (-18, 0, 8)})
    rodillas = mezclar(base(e), {"cadera": (-0.12, -0.3, 0), "cadera_giro": (-12, 4, 0), "columna": (-10, 6, 0),
                                 "cabeza": (-8, 0, 10), "pie_d": {"pos": (0.06, 0, 0.06)}, "pie_i": {"pos": (0.08, 0, 0.05)},
                                 "mano_d": {"pos": (-0.1, -0.7, 0.45)}, "mano_i": {"pos": (-0.1, -0.7, 0.45)}})
    sentado = mezclar(_suelo(e), {"cadera": (-0.2, -0.62, 0), "cadera_giro": (-45, 3, 0), "columna": (-10, 0, 0),
                                  "cabeza": (-10, 0, 10), "pie_d": {"pos": (0.32, 0.0, 0.08), "punta": -20},
                                  "pie_i": {"pos": (0.28, 0.04, 0.05), "punta": -20}})
    s = _suelo(e)
    rebote = cadera_mas(s, (0, 0.025, 0))
    return clip("derribo", 1.3, [(0, g), (0.12, golpe), (0.38, rodillas), (0.62, sentado), (0.9, s), (1.02, rebote),
                                 (1.3, s)], eventos={"suelo": 0.9})


def c_derrota(e):
    s = _suelo(e)
    b = mezclar(s, {"columna": (-6, 0, 0)})
    return clip("derrota", 3.0, [(0, s), (1.5, b), (3.0, s)], bucle=True)


def c_levantarse(e):
    g = guardia_pose(e)
    s = _suelo(e)
    sentado = mezclar(_suelo(e), {"cadera": (-0.2, -0.62, 0), "cadera_giro": (-30, 0, 0), "columna": (14, 0, 0),
                                  "cabeza": (6, 0, 0), "pie_d": {"pos": (0.25, 0.0, 0.08), "punta": -10},
                                  "pie_i": {"pos": (0.15, 0.0, 0.05), "punta": 0},
                                  "mano_d": {"pos": (-0.3, -0.85, 0.35), "codo": (-1, 0, 0.5)},
                                  "mano_i": {"pos": (-0.3, -0.85, 0.35), "codo": (-1, 0, 0.5)}})
    rodilla = mezclar(base(e), {"cadera": (0, -0.32, 0), "cadera_giro": (10, 0, 0), "columna": (22, 0, 0),
                                "pie_d": {"pos": (-0.15, 0.0, 0.06), "punta": 40}, "pie_i": {"pos": (0.15, 0, 0.04)},
                                "mano_i": {"pos": (0.55, -0.6, 0.1)}})
    return clip("levantarse", 1.3, [(0, s), (0.35, sentado), (0.75, rodilla), (1.3, g)])


def c_victoria(e):
    g = guardia_pose(e)
    p = reposo_pose(e)
    if e["arma"] == "sable":
        # 13/11 (pulido): alza el sable POR FUERA del hombro, da un saltito, lo baja en un barrido por el costado y
        # acaba con el sable a un lado, en diagonal hacia delante y abajo, el puño en la cadera, sonriendo a la cámara.
        # Antes acababa con el sable al hombro (su reposo) y, girado hacia la cámara del combate, la hoja asomaba por
        # detrás de la cabeza como un pincho; y al bajar pasaba por dentro de ella («gira», con la mano hacia dentro).
        # Ahora la mano no pasa por encima ni por dentro de la cabeza (fuera ≥ 0,38) y la punta no toca el suelo.
        alza = mezclar(cadera_mas(g, (0, 0.02, 0)), {"mirada": -15.0, "cadera_giro": (0, 0, 8), "columna": (-10, 0, -4), "cabeza": (-12, 0, 0),
                       "mano_d": {"pos": (0.2, 0.92, 0.38), "hoja": (0.1, 1.0, 0.3), "filo": (0.3, 0, 1), "codo": (0, -0.2, 1)},
                       "mano_i": {"pos": (0.3, -0.5, 0.3)}})
        salto = mezclar(cadera_mas(alza, (0, 0.08, 0)), {"pie_d": {"pos": (0.0, 0.06, 0.05), "punta": 30},
                                                          "pie_i": {"pos": (0.02, 0.08, 0.05), "punta": 30}})
        sable_lado = {"pos": (0.22, -0.5, 0.42), "hoja": (0.3, -0.6, 0.72), "filo": (0.3, -0.75, -0.6), "codo": (-0.3, -1, 0.7),
                      "cierre": 75}
        final = mezclar(p, {"cabeza": suma(p["cabeza"], (-4, -6, 8)), "columna": suma(p["columna"], (-3, 3, 0)),
                            "mano_d": sable_lado})
        barre = mezclar(alza, {"cadera": suma(alza["cadera"], (0, -0.02, 0)), "columna": (2, 0, 4),
                               "mano_d": {"pos": (0.4, 0.15, 0.6), "hoja": (0.55, 0.25, 0.8), "filo": (0.4, -1, 0), "codo": (-0.2, -1, 0.8)}})
        asienta = cadera_mas(final, (0, -0.03, 0))
        return clip("victoria", 1.8, [(0, g), (0.35, alza), (0.6, salto), (0.76, barre), (0.92, asienta),
                                      (1.2, final), (1.8, final)])
    if e["arma"] == "cetro":
        # gira el cetro en alto y lo apoya ante sí, con una sonrisa
        alza = mezclar(cadera_mas(g, (0, 0.02, 0)), {"mirada": -15.0, "columna": (-8, 0, 0), "cabeza": (-10, 6, 0),
                       "pie_d": {"punta": 20},
                       "mano_d": {"pos": (0.3, 0.8, 0.3), "hoja": (0.1, 1.0, 0.0), "codo": (0, -0.3, 1)},
                       "mano_i": {"pos": (0.4, 0.3, 0.6), "dedos": (0.3, 1, 0.5), "palma": (1, 0, 0), "cierre": 5}})
        final = mezclar(p, {"cabeza": suma(p["cabeza"], (2, 6, 0)),
                            "mano_d": {"pos": (0.32, -0.6, 0.3), "hoja": (0.1, 1.0, 0.22), "codo": (-0.3, -1, 0.8)},   # 13/11: al lado, no ante la cara
                            "mano_i": {"pos": (0.5, -0.45, -0.25), "dedos": (0.4, 0.2, -1), "palma": (-0.3, 0.2, -1)}})
        return clip("victoria", 1.8, [(0, g), (0.45, alza), (0.9, final), (1.8, final)])
    # Garon: clava la mirada al frente, cruza las espadas y las baja; asiente una vez: disciplina
    cruza = mezclar(g, {"columna": (-6, 0, 0), "mano_d": {"pos": (0.45, 0.2, -0.1), "hoja": (0.3, 1.0, -0.5)},
                        "mano_i": {"pos": (0.45, 0.2, -0.1), "hoja": (0.3, 1.0, -0.5)}})
    final = mezclar(p, {"cabeza": suma(p["cabeza"], (6, 0, 0))})
    return clip("victoria", 2.0, [(0, g), (0.5, cruza), (0.9, cruza), (1.4, final), (1.6, mezclar(final, {"cabeza": suma(p["cabeza"], (12, 0, 0))})),
                                  (2.0, final)])


def clips_de(heroe):
    e = ESTILOS[heroe]
    lista = [c_reposo(e), c_guardia(e), c_hablar(e), c_hablar(e, True), c_asentir(e), c_interactuar(e), c_saltar(e),
             c_girar(e), c_ataque(e), c_recibir_golpe(e), c_derribo(e), c_derrota(e), c_levantarse(e), c_victoria(e)]
    if e["arma"] != "dos_espadas":          # Garon no usa magia (D-037)
        lista += [c_magia_lanzar(e)]
    if e["arma"] == "cetro":
        lista += [c_magia_concentrar(e), c_magia_poderosa(e)]
    return lista
