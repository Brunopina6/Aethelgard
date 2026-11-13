# Combate V12 (animación de combate, 12/11/2026): clips NUEVOS de combate para los héroes v2 (Kael, Lya y Garon).
#
# Se escriben con la misma biblioteca de poses que los clips de los héroes v2
# (personajes/heroes_v2/fuentes_blender/biblioteca_clips.py y rig_comun.py: poses en el espacio del personaje, manos y pies
# por IK), así que el mismo clip vale para los tres esqueletos y la personalidad entra por el ESTILO de cada uno.
# NO sustituyen a ningún clip: todos llevan el prefijo «c12_» y van en una biblioteca de animación aparte
# (personajes/heroes_v2/<héroe>/<héroe>_v2_combate_v12.res), que solo se usa con el interruptor «combate_anim_v12».
#
# Todos «en el sitio» (la cadera no avanza): el combate mueve al personaje en pantalla SOLO mientras los pies no tocan
# el suelo (entre «despegue» y «aterrizaje») o, al correr, a la velocidad del clip de correr (combate_anim_v12.gd), así
# que los pies no patinan.
#
# CONTRATO (combate_anim_v12.gd; los nombres no se cambian sin avisar):
#   c12_arranque         0,26 s · anticipación antes de lanzarse: baja el peso, recoge el arma y se inclina hacia el
#                                 enemigo (los pies quietos). Al acabar, el combate funde con «correr».
#   c12_frenada          0,42 s · empieza en el aire y apoya el pie de delante en «parado»: el cuerpo atrás y la guardia.
#                                 «parado» = instante en que el cuerpo deja de avanzar.
#   c12_salto_atras      0,62 s · (Kael y Lya) brinco hacia atrás, de cara al enemigo. «despegue» y «aterrizaje».
#   c12_paso_atras       0,70 s · (Garon) paso largo y pesado hacia atrás sin perder la guardia. «despegue» (el pie
#                                 de delante se levanta) y «aterrizaje» (apoya).
#   c12_recibir_fuerte   0,95 s · golpe fuerte: se dobla, retrocede medio paso y se rehace a la guardia.
#   c12_bloqueo          0,50 s · con la defensa puesta: para el golpe con el arma, el impacto le empuja y aguanta.
#   c12_defensa          1,60 s · (bucle) la postura de defensa, el arma cruzada delante.
#   c12_magia_carga      1,20 s · (bucle; Kael) concentra el hechizo con el sable vertical ante sí.
#   c12_tecnica_carga    0,80 s · preparación de una técnica: Kael carga el sable atrás (Filo Arcano / Quiebra);
#                                 Garon cruza las espadas y las separa (Juicio y Giro); Lya alza el cetro (magia grande).
#   c12_embuir           1,20 s · (Garon) pasa la mano izquierda por la hoja derecha: «toque» = el elemento prende.
#   c12_remate           0,55 s · recuperación tras un golpe: un medio giro del arma y vuelta a la guardia con aplomo.
#   c12_carrera          0,62 s · (bucle; Garon) carrera pesada por IK, el pie apoyado recto hacia atrás a velocidad fija.
import math
import biblioteca_clips as BC
from biblioteca_clips import mezclar, suma, cadera_mas, col_mas, clip, guardia_pose, reposo_pose, mano_arma, mano_libre

FPS = BC.FPS


def _arma_recogida(e):
    """El arma pegada al cuerpo y atrás, para lanzarse (la mano derecha; la izquierda de Garon igual)."""
    a = e["arma"]
    if a == "sable":
        return {"pos": (-0.05, -0.62, 0.3), "hoja": (-0.75, -0.45, 0.25), "filo": (0.2, -1.0, 0.0), "codo": (-0.6, -0.4, 1.0),
                "cierre": 75}
    if a == "cetro":
        return {"pos": (0.0, -0.6, 0.3), "hoja": (-0.55, 0.8, 0.15), "filo": (1, 0, 0), "codo": (-0.5, -0.5, 1.0), "cierre": 70}
    return {"pos": (-0.05, -0.7, 0.3), "hoja": (-0.6, -0.7, 0.2), "filo": (1, 0.3, 0), "codo": (-0.6, -0.3, 1.0), "cierre": 78}


def _libre_adelante(e, alto=-0.3):
    if e["arma"] == "dos_espadas":
        r = _arma_recogida(e)
        return mezclar(r, {"hoja": (-0.6, -0.7, -0.2)})
    return {"pos": (0.55, alto, 0.12), "codo": (-0.3, -1, 0.6), "dedos": (1, 0.2, 0.0), "palma": (0, -0.3, -1), "cierre": 30}


def c_arranque(e):
    g = guardia_pose(e)
    en = e["energia"]
    baja = mezclar(cadera_mas(g, (-0.04, -0.09 - 0.03 * en, 0)), {
        "columna": (14 + 6 * en, 0, -6), "cabeza": (-10, 0, -4), "mirada": 2.0,
        "mano_d": _arma_recogida(e), "mano_i": _libre_adelante(e, -0.35)})
    lanza = mezclar(cadera_mas(g, (0.05, -0.06, 0)), {
        "columna": (22 + 6 * en, 0, -2), "cabeza": (-16, 0, 0), "mirada": 0.0,
        "pie_d": {"pos": (-0.14, 0.0, 0.06), "giro": 15, "punta": 38}, "pie_i": {"pos": (0.12, 0, 0.04), "giro": 4},
        "mano_d": _arma_recogida(e), "mano_i": _libre_adelante(e, -0.2)})
    if e["arma"] == "dos_espadas":
        baja["mano_i"] = mezclar(_arma_recogida(e), {"hoja": (-0.6, -0.7, -0.25)})
        lanza["mano_i"] = baja["mano_i"]
    d = 0.26 * (1.0 + (e["ritmo"] - 1.0) * 0.5)
    return clip("c12_arranque", d, [(0, g), (d * 0.55, baja), (d, lanza)])


def c_frenada(e):
    # Llega en el aire (el combate la empieza en la fase de vuelo de la carrera): el pie de delante se estira y
    # APOYA en «parado» (desde ahí el cuerpo ya no avanza en pantalla y ese pie no se mueve), el cuerpo se echa atrás
    # para frenar, el pie de atrás se acerca y, con un paso corto, queda en la guardia.
    g = guardia_pose(e)
    gi = g["pie_i"]["pos"]
    gd = g["pie_d"]["pos"]
    vuelo = mezclar(cadera_mas(g, (0.05, -0.02, 0)), {
        "columna": (14, 0, -4), "cabeza": (-10, 0, -4), "mirada": 2.0,
        "pie_i": {"pos": (0.24, 0.05, 0.05), "giro": 2, "punta": -10, "dedos_pie": 0},
        "pie_d": {"pos": (-0.2, 0.08, 0.08), "giro": 18, "punta": 30},
        "mano_d": _arma_recogida(e), "mano_i": _libre_adelante(e, -0.15)})
    apoya = mezclar(cadera_mas(g, (0.06, -0.1, 0)), {
        "columna": (10, 0, -4), "cabeza": (-8, 0, -4), "mirada": 2.0,
        "pie_i": {"pos": (0.24, 0, 0.05), "giro": 2, "punta": -6, "dedos_pie": 0},
        "pie_d": {"pos": (-0.18, 0.04, 0.08), "giro": 18, "punta": 35},
        "mano_d": _arma_recogida(e), "mano_i": _libre_adelante(e, -0.1)})
    frena = mezclar(cadera_mas(g, (0.02, -0.13, 0)), {
        "columna": (-5, 0, -8), "cabeza": (2, 0, -6), "mirada": 3.0,
        "pie_i": {"pos": (0.24, 0, 0.05), "giro": 2},
        "pie_d": {"pos": (gd[0] - 0.02, 0.06, gd[2]), "giro": 24, "punta": 15},
        "mano_i": _libre_adelante(e, -0.05)})
    junta = mezclar(cadera_mas(g, (0.01, -0.05, 0)), {
        "pie_i": {"pos": (0.24, 0, 0.05)}, "pie_d": {"pos": gd}})
    paso = mezclar(cadera_mas(g, (0.0, -0.03, 0)), {"pie_i": {"pos": ((0.24 + gi[0]) * 0.5, 0.05, gi[2])}})
    if e["arma"] == "dos_espadas":
        vuelo["mano_i"] = mezclar(_arma_recogida(e), {"hoja": (-0.6, -0.7, -0.25)})
        apoya["mano_i"] = vuelo["mano_i"]
    d = 0.42 * (1.0 + (e["ritmo"] - 1.0) * 0.5)
    return clip("c12_frenada", d, [(0, vuelo), (d * 0.17, apoya), (d * 0.4, frena), (d * 0.62, junta),
                                   (d * 0.8, paso), (d, g)],
                eventos={"parado": round(d * 0.17, 4)})


def c_salto_atras(e):
    g = guardia_pose(e)
    agacha = mezclar(cadera_mas(g, (0.02, -0.14, 0)), {"columna": (16, 0, -6), "mirada": 4.0,
                                                       "pie_d": {"punta": 10}, "pie_i": {"punta": 10}})
    impulso = mezclar(cadera_mas(g, (-0.03, 0.05, 0)), {"columna": (-2, 0, -6), "mirada": 4.0,
                       "pie_d": {"pos": (-0.1, 0.04, 0.08), "punta": 45, "dedos_pie": 10},
                       "pie_i": {"pos": (0.1, 0.06, 0.05), "punta": 45, "dedos_pie": 10}})
    aire = mezclar(cadera_mas(g, (-0.03, 0.2, 0)), {"columna": (-8, 0, -4), "cabeza": (2, 0, -4), "mirada": 6.0,
                   "pie_d": {"pos": (-0.04, 0.3, 0.08), "punta": 25, "rodilla": (1.0, 0.3, 0.25)},
                   "pie_i": {"pos": (0.12, 0.24, 0.05), "punta": 20, "rodilla": (1.0, 0.3, 0.25)},
                   "mano_i": mezclar(g["mano_i"], {"pos": suma(g["mano_i"]["pos"], (-0.15, 0.2, 0.25))})})
    cae = mezclar(cadera_mas(g, (0.02, -0.16, 0)), {"columna": (18, 0, -6), "mirada": 4.0,
                  "pie_d": {"pos": (-0.12, 0, 0.08)}, "pie_i": {"pos": (0.1, 0, 0.05)}})
    return clip("c12_salto_atras", 0.62, [(0, g), (0.1, agacha), (0.19, impulso), (0.31, aire), (0.42, impulso),
                                          (0.46, cae), (0.62, g)], eventos={"despegue": 0.19, "aterrizaje": 0.44})


def c_paso_atras(e):
    # Garon: el pie de delante sube y se va atrás, el cuerpo le sigue con peso; las espadas no se mueven de la guardia
    g = guardia_pose(e)
    pi0 = g["pie_i"]["pos"]
    pd0 = g["pie_d"]["pos"]
    carga = mezclar(cadera_mas(g, (-0.03, -0.03, 0)), {"columna": suma(g["columna"], (-2, 0, 0))})
    sube = mezclar(cadera_mas(g, (-0.08, 0.0, 0)), {"pie_i": {"pos": (pi0[0] - 0.12, 0.12, pi0[2]), "punta": 10},
                   "columna": suma(g["columna"], (-4, 0, 0))})
    apoya = mezclar(cadera_mas(g, (0.0, -0.05, 0)), {"columna": suma(g["columna"], (3, 0, 0))})
    return clip("c12_paso_atras", 0.7, [(0, g), (0.14, carga), (0.32, sube), (0.5, apoya), (0.7, g)],
                eventos={"despegue": 0.16, "aterrizaje": 0.5})


def c_recibir_fuerte(e):
    g = guardia_pose(e)
    f = 1.0 / max(e["energia"], 0.5) if e["arma"] != "dos_espadas" else 0.55
    dobla = mezclar(cadera_mas(g, (-0.07 * f, -0.06, 0)), {"mirada": None,
                    "columna": suma(g["columna"], (18 * f, 6 * f, 10)), "cabeza": suma(g["cabeza"], (16 * f, -8, 12)),
                    "pie_d": {"punta": 0}, "pie_i": {"punta": 0}})
    dobla["mano_i"] = mezclar(g["mano_i"], {"pos": suma(g["mano_i"]["pos"], (-0.2, -0.1, -0.2))})
    echa = mezclar(cadera_mas(g, (-0.12 * f, -0.08, 0)), {"mirada": None,
                   "columna": suma(g["columna"], (-14 * f, -4 * f, 8)), "cabeza": suma(g["cabeza"], (-12 * f, 4, 8)),
                   "pie_i": {"pos": (0.0, 0.06, g["pie_i"]["pos"][2]), "punta": 15}})
    echa["mano_i"] = mezclar(g["mano_i"], {"pos": suma(g["mano_i"]["pos"], (-0.3, 0.2, 0.3))})
    apoya = mezclar(cadera_mas(g, (-0.08 * f, -0.1, 0)), {"columna": suma(g["columna"], (6, 0, 4)),
                    "pie_i": {"pos": (-0.06, 0, g["pie_i"]["pos"][2])}})
    return clip("c12_recibir_fuerte", 0.95, [(0, g), (0.07, dobla), (0.22, echa), (0.42, apoya), (0.62, apoya),
                                             (0.95, g)], eventos={"impacto": 0.0})


def _arma_defensa(e, lado="d"):
    a = e["arma"]
    if a == "sable":    # el sable horizontal delante de la cara, la izquierda apoyada en el lomo
        return {"pos": (0.55, -0.05, 0.12), "hoja": (0.15, 0.25, -1.0), "filo": (1, 0.2, 0), "codo": (-0.3, -1, 0.6),
                "cierre": 78}
    if a == "cetro":    # 13/11 (pulido): el cetro en alto hacia el enemigo, como un asta en guardia (la cabeza del
        # cetro delante, lejos de la cara); la otra mano sujeta el asta (antes, horizontal a la altura del vientre: no paraba nada)
        return {"pos": (0.45, -0.45, 0.28), "hoja": (0.78, 0.55, -0.3), "filo": (0, 0, 1), "codo": (-0.3, -1, 0.7),
                "cierre": 75}
    if lado == "d":     # 13/11 (pulido) Garon: la derecha alta y casi vertical, la izquierda más baja y tendida: cruzan
        # en X a distinta altura y se ven las dos desde la cámara (antes, iguales: una tapaba a la otra)
        return {"pos": (0.6, 0.02, 0.06), "hoja": (0.3, 0.88, -0.38), "filo": (1, 0, 0), "codo": (-0.3, -1, 0.6),
                "cierre": 80}
    return {"pos": (0.52, -0.32, 0.02), "hoja": (0.45, 0.42, -0.78), "filo": (1, 0, 0), "codo": (-0.3, -1, 0.6), "cierre": 80}


def _libre_defensa(e):
    if e["arma"] == "dos_espadas":
        return _arma_defensa(e, "i")
    if e["arma"] == "sable":
        return {"pos": (0.6, -0.02, -0.25), "dedos": (0.0, 0.3, 1.0), "palma": (1, 0, 0), "codo": (-0.3, -1, 0.5), "cierre": 20}
    # Lya: la izquierda agarra el asta por encima de la derecha
    return {"pos": (0.55, -0.18, -0.12), "dedos": (0.1, 0.2, -1.0), "palma": (0, -1, 0), "codo": (-0.3, -1, 0.6), "cierre": 70}


def defensa_pose(e):
    g = guardia_pose(e)
    return mezclar(cadera_mas(g, (-0.03, -0.06, 0)), {"columna": suma(g["columna"], (4, 0, 4)),
                   "cabeza": suma(g["cabeza"], (6, 0, 2)), "mirada": 2.0,
                   "mano_d": _arma_defensa(e), "mano_i": _libre_defensa(e)})


def c_defensa(e):
    d = defensa_pose(e)
    b = col_mas(cadera_mas(d, (0, -0.012, 0)), (1.5, 0, 0))
    return clip("c12_defensa", 1.6, [(0, d), (0.8, b), (1.6, d)], bucle=True)


def c_bloqueo(e):
    d = defensa_pose(e)
    empuja = mezclar(cadera_mas(d, (-0.07, -0.05, 0)), {"columna": suma(d["columna"], (-10, 0, 0)),
                     "cabeza": suma(d["cabeza"], (-6, 0, 0)),
                     "mano_d": {"pos": suma(d["mano_d"]["pos"], (-0.12, 0.05, 0))},
                     "pie_d": {"punta": 0}, "pie_i": {"punta": 0}})
    if "pos" in d["mano_i"]:
        empuja["mano_i"] = mezclar(d["mano_i"], {"pos": suma(d["mano_i"]["pos"], (-0.12, 0.05, 0))})
    aguanta = mezclar(cadera_mas(d, (-0.03, -0.08, 0)), {"columna": suma(d["columna"], (4, 0, 0))})
    return clip("c12_bloqueo", 0.5, [(0, d), (0.06, empuja), (0.22, aguanta), (0.5, d)], eventos={"impacto": 0.0})


def c_magia_carga(e):
    # Kael: el sable vertical ante sí, la izquierda abierta junto a la hoja, rodillas dobladas; respira con el hechizo
    g = guardia_pose(e)
    k = mezclar(cadera_mas(g, (0, -0.08, 0)), {"mirada": 10.0, "columna": (4, 0, -8), "cabeza": (8, 0, -6),
                "mano_d": {"pos": (0.55, -0.2, 0.32), "hoja": (0.1, 1.0, 0.12), "filo": (1, 0, 0), "codo": (-0.3, -1, 0.7)},
                "mano_i": {"pos": (0.6, 0.0, 0.1), "dedos": (0.1, 1.0, 0.3), "palma": (0.2, 0, 1), "cierre": 8}})
    k2 = mezclar(cadera_mas(k, (0, -0.02, 0)), {"columna": (6, 0, -8),
                 "mano_i": {"pos": (0.61, 0.05, 0.12)}, "mano_d": {"pos": (0.55, -0.18, 0.32)}})
    return clip("c12_magia_carga", 1.2, [(0, k), (0.6, k2), (1.2, k)], bucle=True)


def c_tecnica_carga(e):
    g = guardia_pose(e)
    if e["arma"] == "sable":       # 13/11 (pulido): el sable alto, por encima de la cabeza y algo por fuera, inclinado
        # atrás (antes, echado detrás de la cabeza: no se veía), el cuerpo
        # enroscado como un muelle y la izquierda apuntando al enemigo
        k1 = mezclar(cadera_mas(g, (-0.05, -0.13, 0)), {"cadera_giro": (4, 0, 18), "columna": (-6, 0, -18),
                     "cabeza": (-4, 0, 12), "mirada": 2.0,
                     "mano_d": {"pos": (0.14, 0.92, 0.42), "hoja": (-0.35, 0.82, 0.45), "filo": (0, 0, 1), "codo": (0, -0.2, 1)},
                     "mano_i": {"pos": (0.75, 0.05, -0.05), "dedos": (1, 0.1, 0), "palma": (0, -0.3, -1), "cierre": 10}})
        k2 = mezclar(k1, {"cadera": suma(k1["cadera"], (0, -0.02, 0)), "columna": (-8, 0, -20),
                          "mano_d": {"pos": (0.1, 0.95, 0.42)}})
        return clip("c12_tecnica_carga", 0.8, [(0, g), (0.3, k1), (0.8, k2)])
    if e["arma"] == "cetro":       # el cetro en alto, la otra mano abierta abajo: reúne la luz
        k1 = mezclar(cadera_mas(g, (0, 0.0, 0)), {"columna": (-8, 0, 0), "cabeza": (-10, 3, 0), "mirada": -6.0,
                     "pie_d": {"punta": 12},
                     "mano_d": {"pos": (0.25, 0.85, 0.2), "hoja": (0.05, 1.0, 0.0), "codo": (0, -0.4, 1)},
                     "mano_i": {"pos": (0.35, -0.55, 0.45), "dedos": (0.3, -0.6, 1.0), "palma": (0, -1, 0), "cierre": 5}})
        k2 = mezclar(k1, {"columna": (-10, 0, 0), "mano_d": {"pos": (0.25, 0.9, 0.2)}})
        return clip("c12_tecnica_carga", 0.8, [(0, g), (0.35, k1), (0.8, k2)])
    # Garon: cruza las espadas ante el yelmo y las separa de golpe, rodillas abajo
    cruza = mezclar(cadera_mas(g, (0, -0.06, 0)), {"columna": suma(g["columna"], (-6, 0, 0)),
                    "mano_d": {"pos": (0.45, 0.25, -0.1), "hoja": (0.3, 1.0, -0.5)},
                    "mano_i": {"pos": (0.45, 0.25, -0.1), "hoja": (0.3, 1.0, -0.5)}})
    abre = mezclar(cadera_mas(g, (0, -0.14, 0)), {"columna": suma(g["columna"], (6, 0, 0)),
                   "mano_d": {"pos": (0.3, -0.45, 0.55), "hoja": (0.5, -0.4, 0.75), "codo": (-0.3, -1, 0.8)},
                   "mano_i": {"pos": (0.3, -0.45, 0.55), "hoja": (0.5, -0.4, 0.75), "codo": (-0.3, -1, 0.8)}})
    return clip("c12_tecnica_carga", 0.8, [(0, g), (0.3, cruza), (0.48, cruza), (0.62, abre), (0.8, abre)],
                eventos={"abre": 0.6})


def c_embuir(e):
    # Garon: la espada derecha vertical ante sí; la mano izquierda (con su espada baja, hacia atrás) pasa por la hoja
    g = guardia_pose(e)
    ar = {"pos": (0.5, -0.15, 0.05), "hoja": (0.15, 1.0, -0.1), "filo": (1, 0, 0), "codo": (-0.3, -1, 0.7), "cierre": 80}
    li0 = {"pos": (0.45, -0.25, -0.25), "hoja": (-0.4, -1.0, -0.2), "filo": (1, 0, 0), "codo": (-0.3, -1, 0.6), "cierre": 78}
    li1 = mezclar(li0, {"pos": (0.5, 0.25, -0.2)})
    k0 = mezclar(cadera_mas(g, (0, -0.05, 0)), {"mirada": 12.0, "columna": suma(g["columna"], (-2, 0, 0)), "mano_d": ar,
                 "mano_i": li0})
    k1 = mezclar(k0, {"mano_i": li1})
    return clip("c12_embuir", 1.2, [(0, g), (0.3, k0), (0.75, k1), (0.95, k1), (1.2, g)], eventos={"toque": 0.75})


def c_remate(e):
    g = guardia_pose(e)
    k = mezclar(cadera_mas(g, (0.0, -0.03, 0)), {"columna": suma(g["columna"], (-4, 0, 6)),
                "mano_d": mezclar(g["mano_d"], {"pos": suma(g["mano_d"]["pos"], (0.05, 0.15, 0.1))})})
    return clip("c12_remate", 0.55, [(0, g), (0.25, k), (0.55, g)])


def c_carrera(e):
    # Garon: carrera pesada HECHA POR IK (su carrera de captura, con la cadera quitada, arrastra los pies: medido en
    # combate, el pie «apoyado» se movía con el cuerpo). Una clave por fotograma: el pie apoyado retrocede en línea
    # recta a velocidad constante (= la del cuerpo en pantalla: el combate la mide en el clip) y el otro vuelve por el
    # aire; dos fases de vuelo cortas por ciclo (cada pie apoya el 40 %). El cuerpo inclinado y bajo, las espadas
    # recogidas atrás, la cadera sube y baja con cada zancada y los hombros contrarrestan.
    g = guardia_pose(e)
    T = 0.62                 # ciclo (dos pasos)
    apoyo = 0.4              # parte del ciclo que cada pie está en el suelo
    S = 0.72                 # metros que recorre el pie apoyado (para 1,7 m de altura)
    n = int(round(T * FPS))
    T = n / FPS              # (el bucle cierra justo en un fotograma)
    gi = g["pie_i"]["pos"]
    gd = g["pie_d"]["pos"]
    claves = []
    for f in range(n + 1):
        t = f / FPS
        poses = {}
        for lado, base, fase0 in [("pie_i", gi, 0.0), ("pie_d", gd, 0.5)]:
            u = ((t / T) + fase0) % 1.0
            if u < apoyo:                         # en el suelo: de delante a detrás, recto
                k = u / apoyo
                x = S * (0.5 - k)
                y = 0.0
                punta = 0.0 if k < 0.7 else 35.0 * (k - 0.7) / 0.3
            else:                                 # en el aire: vuelve adelante en arco
                k = (u - apoyo) / (1.0 - apoyo)
                x = S * (-0.5 + k)
                y = 0.2 * math.sin(math.pi * k) ** 0.6   # despega deprisa: en el vuelo los dos pies ya van arriba
                punta = 35.0 * (1.0 - k) if k < 0.3 else -8.0 * (k - 0.3) / 0.7
            poses[lado] = {"pos": (x + 0.03, y, base[2] * 0.6), "giro": 4, "punta": punta, "dedos_pie": 0,
                           "rodilla": (1.0, 0.0, 0.2)}
        w = math.cos(2 * math.pi * 2 * (t / T - 0.45))   # la cadera, arriba en cada vuelo (0,45 y 0,95) y abajo al apoyar
        balanceo = math.sin(2 * math.pi * t / T)
        d = mezclar(cadera_mas(g, (0.06, -0.09 + 0.035 * w, 0)), {
            "cadera_giro": (6, 0, -6 * balanceo), "columna": (16, 0, 9 * balanceo), "cabeza": (-12, 0, -4 * balanceo),
            "mirada": 3.0, "pie_i": poses["pie_i"], "pie_d": poses["pie_d"],
            "mano_d": mezclar(_arma_recogida(e), {"pos": suma(_arma_recogida(e)["pos"], (0.12 * balanceo, 0.04 * w, 0))}),
            "mano_i": mezclar(_arma_recogida(e), {"hoja": (-0.6, -0.7, -0.25),
                                                  "pos": suma(_arma_recogida(e)["pos"], (-0.12 * balanceo, 0.04 * w, 0))})})
        claves.append((t, d))
    return clip("c12_carrera", n / FPS, claves, bucle=True, eventos={"metros_por_s_1_7": round(S / (apoyo * T), 4)})


def clips_de(heroe):
    e = BC.ESTILOS[heroe]
    lista = [c_arranque(e), c_frenada(e), c_recibir_fuerte(e), c_bloqueo(e), c_defensa(e), c_tecnica_carga(e),
             c_remate(e)]
    if e["arma"] == "dos_espadas":
        lista += [c_paso_atras(e), c_embuir(e), c_carrera(e)]
    else:
        lista += [c_salto_atras(e)]
    if e["arma"] == "sable":
        lista += [c_magia_carga(e)]
    return lista
