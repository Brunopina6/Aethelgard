# Nix (V12): sus clips. Reutiliza la biblioteca común de los héroes v2 (personajes/heroes_v2/fuentes_blender/
# biblioteca_clips.py, poses en el espacio del personaje resueltas por IK con rig_comun.py) y la de combate v12
# (fuente/clips_combate_v12.py) con el ESTILO de Nix (sus poses de reposo y guardia sustituyen a las de la biblioteca
# solo mientras se generan sus clips; los archivos de la biblioteca no se tocan), y añade los suyos según los perfiles
# de la especificación (Aethelgard_Nix_Maga_Negra.pdf, pág. 4: anticipación 0-35 %, preparación 35-50 %, liberación
# al 50 %, recuperación 50-100 %):
#   reposo, guardia (bucles), andar y correr (captura, del esqueleto)
#   magia_lanzar      P01 «gesto_punta» 1,4 s: junta pulgar e índice y suelta una semilla (lanzamiento 0,7 s)
#   magia_estado      P02 «trazo_lateral» 1,6 s: dibuja una aguja vertical con el bastón (lanzamiento 0,8 s)
#   magia_culminante  P07 «ritual_mayor» 3,2 s: alza un aro roto y lo contrae hasta un punto (lanzamiento 1,6 s)
#   magia_concentrar  bucle mientras prepara (el bastón ante sí, la mano libre sobre el cristal)
#   recibir_golpe 0,35 s · defender 1 s (y «defensa», bucle) · victoria 2 s · derribo 1,5 s y derrota (bucle)
#   levantarse · ataque (bastonazo flojo; «impacto») · hablar, hablar_b, asentir, interactuar, saltar, girar
# Nix no invoca: no hay clip de invocación. La derrota es de rodillas y sentada sobre los talones (tumbada boca
# arriba, el sombrero rígido se clavaba en el suelo).
import math
import biblioteca_clips as BC

M = BC.mezclar
S = BC.suma
clip = BC.clip

# serena, ingeniosa y leal; mide sus palabras: erguida, la barbilla algo baja (mira por debajo del ala), la cabeza
# apenas ladeada al otro lado que Lya, pies juntos, gestos precisos y algo lentos
ESTILO = {"pecho": -3.0, "barbilla": 3.0, "ladeo": -3.0, "anchura": -0.01, "bajar": 0.0, "ritmo": 1.2,
          "energia": 0.85, "arma": "cetro"}

# la mano izquierda, expresiva (guante): en reposo, suelta junto a la falda, algo adelantada y los dedos abiertos
IZQ_CINTURON = {"pos": (0.14, -0.86, 0.12), "codo": (-0.5, -0.2, 1.0), "dedos": (0.35, -1.0, -0.15),
                "palma": (-0.2, 0.0, -1.0), "cierre": 28, "pulgar": 15}       # (nombre antiguo: el brazo cae suelto)
# el bastón en reposo: asta casi vertical, apoyada junto al pie derecho, la mano a la altura de la cadera
DER_BASTON = {"pos": (0.24, -0.90, 0.44), "codo": (-0.4, -0.4, 1.0), "hoja": (0.04, 1.0, 0.13), "filo": (1, 0, 0),
              "cierre": 72}       # v2: algo hacia fuera, la luna junto al ala (no debajo de ella)
DER_GUARDIA = {"pos": (0.42, -0.50, 0.28), "codo": (-0.3, -1.0, 0.8), "hoja": (0.45, 1.0, 0.0), "filo": (1, 0, 0),
               "cierre": 72}
IZQ_GUARDIA = {"pos": (0.55, -0.22, 0.02), "codo": (-0.3, -1.0, 0.7), "dedos": (1.0, 0.35, -0.1),
               "palma": (0.2, -0.2, -1.0), "cierre": 12, "pulgar": 5}


def reposo_pose(e=ESTILO):
    d = BC.base(e)
    d = M(d, {"pie_d": {"pos": (0.035, 0, 0.0), "giro": 16}, "pie_i": {"pos": (-0.01, 0, 0.01), "giro": 6},
              "cadera_giro": (0, -2, 4), "columna": (e["pecho"], 1.5, -3)})
    d["mano_d"] = dict(DER_BASTON)
    d["mano_i"] = dict(IZQ_CINTURON)
    return d


def guardia_pose(e=ESTILO):
    """En guardia: medio perfil al enemigo, el bastón en diagonal delante (la cabeza del bastón hacia el enemigo) y
    la mano izquierda abierta a la altura del pecho, lista para trazar."""
    d = BC.base(e)
    d = M(d, {"cadera": (0, -0.035, 0), "cadera_giro": (2, 0, 16), "columna": (4, 0, -10), "cabeza": (2, -2, -8),
              "pie_i": {"pos": (0.08, 0, 0.03), "giro": 4}, "pie_d": {"pos": (-0.05, 0, 0.05), "giro": 28}})
    d["mano_d"] = dict(DER_GUARDIA)
    d["mano_i"] = dict(IZQ_GUARDIA)
    d["mirada"] = 4.0
    return d


def _mano_libre_nix(e, que):
    return {"hombro": dict(IZQ_CINTURON), "guardia": dict(IZQ_GUARDIA), "abajo": dict(BC.ABAJO)}[que]


def _mano_arma_nix(e, que):
    return {"hombro": dict(DER_BASTON), "guardia": dict(DER_GUARDIA), "abajo": dict(DER_BASTON)}[que]


def instalar():
    """Mientras se generan los clips de Nix, la biblioteca usa sus poses (no se tocan los archivos)."""
    BC.reposo_pose = reposo_pose
    BC.guardia_pose = guardia_pose
    BC.mano_libre = _mano_libre_nix
    BC.mano_arma = _mano_arma_nix


# ------------------------------------------------------------------ bucles
def c_reposo(e=ESTILO):
    p = reposo_pose(e)
    inspira = M(BC.cadera_mas(p, (0, 0.006, 0)), {"columna": S(p["columna"], (-1.5, 0, 0)), "hombro_d": (2, 0),
                                                  "hombro_i": (2, 0)})
    peso = M(p, {"cadera": S(p["cadera"], (0, -0.004, -0.012)), "cadera_giro": (0, -4, 5), "columna": S(p["columna"], (0, 2.5, 0)),
                 "cabeza": S(p["cabeza"], (0, 3, 6))})
    peso_insp = M(BC.cadera_mas(peso, (0, 0.006, 0)), {"columna": S(peso["columna"], (-1.5, 0, 0))})
    return clip("reposo", 6.0, [(0, p), (1.4, inspira), (2.8, p), (3.6, peso), (4.6, peso_insp), (6.0, p)], bucle=True)


def c_guardia(e=ESTILO):
    g = guardia_pose(e)
    insp = M(BC.cadera_mas(g, (0, 0.010, 0)), {"columna": S(g["columna"], (-2, 0, 0)), "hombro_d": (2, 0), "hombro_i": (2, 0),
                                               "mano_i": M(g["mano_i"], {"pos": S(g["mano_i"]["pos"], (0, 0.03, 0)), "cierre": 18})})
    return clip("guardia", 2.4, [(0, g), (1.2, insp), (2.4, g)], bucle=True)


def c_concentrar(e=ESTILO):
    g = guardia_pose(e)
    k = M(BC.cadera_mas(g, (0, -0.012, 0)), {"mirada": 18.0, "columna": (0, 0, -4), "cabeza": (8, 0, -4),
          "mano_d": {"pos": (0.40, -0.35, 0.42), "hoja": (0.10, 1.0, 0.35), "codo": (-0.2, -1, 0.8)},
          "mano_i": {"pos": (0.48, 0.02, -0.25), "dedos": (0.2, 1.0, 0.1), "palma": (0.1, 0, 1), "cierre": 20, "pulgar": 10}})
    k2 = M(BC.cadera_mas(k, (0, 0.010, 0)), {"columna": (-2, 0, -4), "mano_i": {"pos": (0.50, 0.06, -0.23), "cierre": 8}})
    return clip("magia_concentrar", 2.2, [(0, k), (1.1, k2), (2.2, k)], bucle=True)


# ------------------------------------------------------------------ magias (perfiles P01, P02, P07)
def c_magia_lanzar(e=ESTILO):
    """P01 «gesto_punta», 1,4 s: junta pulgar e índice delante del pecho (anticipación), recoge la mano junto al
    hombro (preparación) y la abre hacia el enemigo al 50 % (0,7 s): sale la semilla. Recupera la guardia."""
    g = guardia_pose(e)
    junta = M(BC.cadera_mas(g, (-0.01, -0.005, 0)), {"columna": (2, 0, -16), "cabeza": (4, 0, -12), "mirada": 8.0,
              "mano_i": {"pos": (0.45, -0.02, -0.28), "codo": (-0.4, -1.0, 0.5), "dedos": (0.4, 0.8, -0.4),
                         "palma": (0, 0, 1), "cierre": 55, "pulgar": 70}})
    recoge = M(BC.cadera_mas(g, (-0.02, 0.0, 0)), {"columna": (-2, 0, -22), "cabeza": (2, 0, -14), "mirada": 4.0,
               "mano_i": {"pos": (0.15, 0.20, -0.05), "codo": (-0.6, -0.8, 0.6), "dedos": (0.2, 1.0, 0.0),
                          "palma": (0.4, 0, 1), "cierre": 60, "pulgar": 75},
               "mano_d": M(DER_GUARDIA, {"pos": (0.35, -0.55, 0.35)})})
    suelta = M(BC.cadera_mas(g, (0.04, -0.03, 0)), {"columna": (10, 0, 4), "cabeza": (2, 0, -2), "mirada": 2.0,
               "pie_i": {"pos": (0.13, 0, 0.03)},
               "mano_i": {"pos": (0.98, 0.05, 0.0), "codo": (0, -1, 0.4), "dedos": (1.0, 0.15, 0.0), "palma": (0.3, -0.2, -1),
                          "cierre": 2, "pulgar": 0}})
    sigue = M(suelta, {"columna": (7, 0, 2), "mano_i": {"pos": (0.92, 0.02, 0.05), "cierre": 10}})
    return clip("magia_lanzar", 1.4, [(0, g), (0.35, junta), (0.49, junta), (0.63, recoge), (0.70, suelta), (0.95, sigue),
                                      (1.4, g)], eventos={"lanzamiento": 0.7})


def c_magia_estado(e=ESTILO):
    """P02 «trazo_lateral», 1,6 s: alza el bastón en vertical ante sí y, al 50 % (0,8 s), traza de arriba abajo una
    aguja con la punta; la mano libre marca el ritmo a un lado."""
    g = guardia_pose(e)
    alza = M(BC.cadera_mas(g, (0, 0.012, 0)), {"columna": (-6, 0, -6), "cabeza": (-6, 0, -6), "mirada": -12.0,
             "mano_d": {"pos": (0.40, 0.40, 0.75), "hoja": (0.15, 1.0, 0.45), "filo": (1, 0, 0), "codo": (0, -0.6, 1)},
             "mano_i": {"pos": (0.35, -0.25, 0.55), "dedos": (0.3, -0.2, 1.0), "palma": (1, 0, 0), "cierre": 8}})
    arriba = M(alza, {"columna": (-9, 0, -6), "pie_d": {"punta": 12}, "pie_i": {"punta": 8},
               "mano_d": {"pos": (0.35, 0.58, 0.75), "hoja": (0.05, 1.0, 0.40)}})
    traza = M(BC.cadera_mas(g, (0.03, -0.04, 0)), {"columna": (12, 0, -4), "cabeza": (4, 0, -4), "mirada": 6.0,
              "pie_d": {"punta": 0}, "pie_i": {"pos": (0.12, 0, 0.03), "punta": 0},
              "mano_d": {"pos": (0.80, -0.20, 0.06), "hoja": (0.85, -0.45, 0.0), "filo": (0, 1, 0), "codo": (0, -1, 0.6)},
              "mano_i": {"pos": (0.30, -0.35, 0.70), "dedos": (0.2, -0.5, 1.0), "palma": (1, 0, 0), "cierre": 4}})
    sigue = M(traza, {"columna": (9, 0, -4), "mano_d": {"pos": (0.76, -0.28, 0.08)}})
    return clip("magia_estado", 1.6, [(0, g), (0.42, alza), (0.56, arriba), (0.72, arriba), (0.80, traza), (1.05, sigue),
                                      (1.6, g)], eventos={"lanzamiento": 0.8})


def c_magia_culminante(e=ESTILO):
    """P07 «ritual_mayor», 3,2 s: planta el bastón, alza los brazos (un aro roto sobre la cabeza), los cierra en un
    punto (contrae el aro) y, al 50 % (1,6 s), lo descarga hacia delante. Recupera despacio."""
    g = guardia_pose(e)
    planta = M(BC.cadera_mas(g, (0, -0.03, 0)), {"columna": (6, 0, 0), "cabeza": (8, 0, 0), "mirada": 20.0,
               "cadera_giro": (2, 0, 6),
               "mano_d": {"pos": (0.40, -0.60, 0.25), "hoja": (0.0, 1.0, 0.0), "filo": (1, 0, 0), "codo": (-0.3, -1, 0.8)},
               "mano_i": {"pos": (0.42, -0.10, -0.20), "dedos": (0.3, 1.0, 0.2), "palma": (0, 0, 1), "cierre": 25}})
    abre = M(BC.cadera_mas(g, (0, 0.02, 0)), {"mirada": -28.0, "columna": (-14, 0, 0), "cabeza": (-14, 0, 0),
             "cadera_giro": (-2, 0, 4), "pie_d": {"punta": 10}, "pie_i": {"punta": 10},
             "mano_d": {"pos": (0.10, 0.70, 0.95), "hoja": (0.0, 0.75, 0.85), "codo": (0, -0.3, 1)},
             "mano_i": {"pos": (0.25, 0.88, 0.45), "dedos": (0.1, 1.0, -0.3), "palma": (0, 0, -1), "cierre": 4, "pulgar": 0}})
    cierra = M(abre, {"columna": (-16, 0, 0), "cabeza": (-18, 0, 0), "mirada": -32.0,
               "mano_d": {"pos": (0.20, 0.80, 0.80), "hoja": (0.05, 0.80, 0.80)},
               "mano_i": {"pos": (0.32, 0.96, -0.02), "dedos": (0.0, 1.0, 0.3), "cierre": 55, "pulgar": 60}})
    descarga = M(BC.cadera_mas(g, (0.06, -0.10, 0)), {"columna": (20, 0, 0), "cabeza": (6, 0, 0), "mirada": 6.0,
                 "pie_i": {"pos": (0.17, 0, 0.04), "punta": 0}, "pie_d": {"punta": 0},
                 "mano_d": {"pos": (0.92, 0.12, 0.10), "hoja": (1.0, 0.25, 0.0), "filo": (0, 1, 0), "codo": (0, -1, 0.6)},
                 "mano_i": {"pos": (0.90, 0.05, -0.05), "dedos": (1.0, 0.0, 0.0), "palma": (0.2, 0, -1), "cierre": 2, "pulgar": 0}})
    sigue = M(descarga, {"columna": (16, 0, 0), "mano_d": {"pos": (0.86, 0.08, 0.12)}, "mano_i": {"pos": (0.82, 0.0, -0.02)}})
    vuelve = M(BC.cadera_mas(g, (0.0, -0.02, 0)), {"columna": (6, 0, -6), "mirada": 6.0})
    return clip("magia_culminante", 3.2, [(0, g), (0.45, planta), (0.85, abre), (1.12, abre), (1.45, cierra), (1.52, cierra),
                                          (1.60, descarga), (2.05, sigue), (2.6, vuelve), (3.2, g)],
                eventos={"lanzamiento": 1.6, "preparacion": 1.12})


# ------------------------------------------------------------------ golpes, defensa, victoria y derrota
def c_recibir_golpe(e=ESTILO):
    g = guardia_pose(e)
    golpe = M(BC.cadera_mas(g, (-0.045, -0.025, 0)), {"mirada": None, "columna": S(g["columna"], (-14, 4, 6)),
              "cabeza": S(g["cabeza"], (-12, -5, 9)),
              "mano_i": M(g["mano_i"], {"pos": S(g["mano_i"]["pos"], (-0.22, 0.12, 0.18)), "cierre": 40})})
    vuelve = M(BC.cadera_mas(g, (-0.015, -0.03, 0)), {"columna": S(g["columna"], (3, 0, 0))})
    return clip("recibir_golpe", 0.35, [(0, g), (0.06, golpe), (0.18, vuelve), (0.35, g)], eventos={"impacto": 0.0})


def defensa_pose(e=ESTILO):
    g = guardia_pose(e)
    return M(BC.cadera_mas(g, (-0.01, -0.05, 0)), {"columna": (8, 0, -10), "cabeza": (8, 0, -8), "mirada": 6.0,
             "pie_i": {"pos": (0.10, 0, 0.05)}, "pie_d": {"pos": (-0.08, 0, 0.06), "giro": 30},
             "mano_d": {"pos": (0.55, -0.05, 0.35), "hoja": (0.15, 0.25, -1.0), "filo": (1, 0, 0), "codo": (-0.2, -1, 0.6)},
             "mano_i": {"pos": (0.55, -0.02, -0.30), "codo": (-0.2, -1, 0.6), "dedos": (0.2, 0.2, -1.0), "palma": (1, 0, 0),
                        "cierre": 70, "pulgar": 60}})


def c_defender(e=ESTILO):
    """1 s: cruza el bastón en horizontal ante sí con las dos manos y se agacha un poco; acaba quieta en la guardia
    alta (la sigue «defensa», en bucle)."""
    g = guardia_pose(e)
    d = defensa_pose(e)
    llega = M(d, {"cadera": S(d["cadera"], (0, -0.015, 0)), "columna": S(d["columna"], (3, 0, 0))})
    return clip("defender", 1.0, [(0, g), (0.25, llega), (0.45, d), (1.0, d)])


def c_defensa(e=ESTILO):
    d = defensa_pose(e)
    r = M(BC.cadera_mas(d, (0, 0.008, 0)), {"columna": S(d["columna"], (-2, 0, 0))})
    return clip("defensa", 1.6, [(0, d), (0.8, r), (1.6, d)], bucle=True)


def c_victoria(e=ESTILO):
    """2 s: gira el bastón en alto, a un lado (no bajo el ala), lo apoya a su lado y pone la mano izquierda en la
    cadera, con una media sonrisa (no salta)."""
    g = guardia_pose(e)
    p = reposo_pose(e)
    alza = M(BC.cadera_mas(g, (0, 0.015, 0)), {"mirada": -10.0, "columna": (-6, 0, 0), "cabeza": (-8, -4, 0),
             "mano_d": {"pos": (0.10, 0.45, 0.95), "hoja": (0.0, 0.85, 0.75), "filo": (1, 0, 0), "codo": (0, -0.3, 1)},
             "mano_i": {"pos": (0.40, -0.30, 0.25), "dedos": (0.5, -0.3, 0.6), "palma": (0, 0, -1), "cierre": 15}})
    gira = M(alza, {"mano_d": {"pos": (0.12, 0.50, 0.95), "hoja": (-0.25, 0.8, 0.9)}})
    # v2: con los brazos chibi la mano no llega al ala (mucho más ancha): mano en la cadera, segura
    sombrero = {"ref": "cadera", "pos": (0.02, 0.04, 0.22), "codo": (-0.3, 0.0, 1.0), "dedos": (0.5, -1.0, -0.3),
                "palma": (0, 0, -1), "cierre": 35, "pulgar": 10}
    final = M(p, {"cabeza": S(p["cabeza"], (6, 3, 8)), "columna": S(p["columna"], (0, 2, 3)),
                  "mano_d": {"pos": (0.26, -0.86, 0.46), "hoja": (0.10, 1.0, 0.16), "codo": (-0.4, -0.4, 1.0)},
                  "mano_i": sombrero})
    asienta = M(final, {"cabeza": S(final["cabeza"], (4, 0, 0)), "mano_i": M(sombrero, {"pos": (0.02, 0.03, 0.22)})})
    return clip("victoria", 2.0, [(0, g), (0.35, alza), (0.6, gira), (0.95, final), (1.4, asienta), (2.0, asienta)])


def _rodillas(e=ESTILO):
    """De rodillas y sentada sobre los talones, vencida hacia delante; el bastón caído a su lado."""
    d = BC.base(e)
    return M(d, {"cadera": (-0.10, -0.44, 0), "cadera_giro": (12, 3, 0), "columna": (22, 4, 0), "cabeza": (16, 0, 6),
                 "mirada": None,
                 "pie_d": {"pos": (-0.36, 0.0, 0.04), "rodilla": (1.0, -0.6, 0.15), "punta": -75, "dedos_pie": -75},
                 "pie_i": {"pos": (-0.34, 0.0, 0.02), "rodilla": (1.0, -0.6, 0.1), "punta": -75, "dedos_pie": -75},
                 "mano_d": {"ref": "mundo", "pos": (0.30, 0.03, 0.32), "codo": (-0.6, 0, 1.0), "hoja": (0.3, 0.02, 1.0),
                            "filo": (0, 1, 0), "marco_mano": "mundo", "cierre": 40},
                 "mano_i": {"ref": "mundo", "pos": (0.34, 0.03, -0.18), "codo": (-0.6, 0, -0.4), "dedos": (1.0, -0.2, 0.0),
                            "palma": (0, -1, 0), "marco_mano": "mundo", "cierre": 20}})


def c_derribo(e=ESTILO):
    g = guardia_pose(e)
    golpe = M(BC.cadera_mas(g, (-0.05, -0.04, 0)), {"mirada": None, "columna": (-18, 6, 0), "cabeza": (-18, 0, 8)})
    cae = M(BC.base(e), {"cadera": (-0.08, -0.26, 0), "cadera_giro": (-6, 4, 0), "columna": (-4, 6, 0), "cabeza": (-6, 0, 10),
                         "pie_d": {"pos": (-0.10, 0, 0.05), "punta": 25}, "pie_i": {"pos": (0.05, 0, 0.04)},
                         "mano_d": {"pos": (0.2, -0.75, 0.40), "hoja": (0.6, 0.2, 0.6), "filo": (1, 0, 0)},
                         "mano_i": {"pos": (0.2, -0.75, 0.40)}})
    r = _rodillas(e)
    rebote = M(r, {"cadera": S(r["cadera"], (0, 0.02, 0)), "columna": (16, 4, 0)})
    return clip("derribo", 1.5, [(0, g), (0.12, golpe), (0.45, cae), (0.95, r), (1.1, rebote), (1.5, r)],
                eventos={"suelo": 0.95})


def c_derrota(e=ESTILO):
    r = _rodillas(e)
    b = M(r, {"columna": S(r["columna"], (-3, 0, 0)), "cadera": S(r["cadera"], (0, 0.006, 0))})
    return clip("derrota", 3.0, [(0, r), (1.5, b), (3.0, r)], bucle=True)


def c_levantarse(e=ESTILO):
    g = guardia_pose(e)
    r = _rodillas(e)
    rodilla = M(BC.base(e), {"cadera": (0, -0.34, 0), "cadera_giro": (10, 0, 0), "columna": (18, 0, 0),
                             "pie_d": {"pos": (-0.18, 0.0, 0.06), "punta": 40}, "pie_i": {"pos": (0.14, 0, 0.04)},
                             "mano_d": {"pos": (0.35, -0.55, 0.30), "hoja": (0.1, 1.0, 0.1), "filo": (1, 0, 0)},
                             "mano_i": {"pos": (0.55, -0.55, 0.10)}})
    return clip("levantarse", 1.3, [(0, r), (0.55, rodilla), (1.3, g)])


def c_ataque(e=ESTILO):
    """Bastonazo flojo (como el de Lya: impacto a 0,45 s, preparación hasta 0,3 s), pero de LADO y bajo: con el ala
    tan ancha, el bastón no puede pasar por encima del hombro (atravesaría el sombrero). Carga atrás y fuera, barre
    hacia delante a la altura del pecho y sigue de largo."""
    g = guardia_pose(e)
    carga = M(BC.cadera_mas(g, (-0.03, -0.02, 0)), {"columna": (-4, 0, -16), "cabeza": (0, 3, -2),
              "mano_d": {"pos": (0.05, -0.10, 0.75), "hoja": (-0.6, 0.45, 0.65), "filo": (0, 1, 0), "codo": (-0.3, -0.6, 1)},
              "mano_i": {"pos": (0.55, -0.15, 0.1), "dedos": (1, 0.3, 0.0), "palma": (0, -0.3, -1), "cierre": 12}})
    prep = M(BC.cadera_mas(g, (-0.05, -0.05, 0)), {"mirada": 6.0, "columna": (-8, 0, -30), "cabeza": (0, 3, 8),
             "pie_d": {"punta": 8},
             "mano_d": {"pos": (-0.15, 0.0, 0.78), "hoja": (-0.7, 0.30, 0.65), "filo": (0, 1, 0), "codo": (-0.3, -0.4, 1)},
             "mano_i": {"pos": (0.6, -0.05, 0.05), "dedos": (1, 0.4, -0.1), "palma": (0, -0.3, -1), "cierre": 10}})
    sost = M(prep, {"columna": (-9, 0, -32), "mano_d": {"pos": (-0.17, 0.02, 0.78)}})
    golpe = M(BC.cadera_mas(g, (0.06, -0.07, 0)), {"columna": (14, 0, 14), "pie_i": {"pos": (0.15, 0, 0.03)},
              "mano_d": {"pos": (0.80, -0.25, 0.15), "hoja": (0.85, 0.10, -0.50), "filo": (0, 1, 0), "codo": (0, -1, 0.6)},
              "mano_i": {"pos": (0.2, -0.6, 0.45), "dedos": (-0.3, -1, 0.3)}})
    sigue = M(BC.cadera_mas(golpe, (0.01, -0.01, 0)), {"columna": (18, 0, 18),
              "mano_d": {"pos": (0.70, -0.40, -0.10), "hoja": (0.60, -0.30, -0.75), "filo": (0, 1, 0), "codo": (0, -1, 0.5)}})
    return clip("ataque", 1.0, [(0, g), (0.12, carga), (0.3, prep), (0.36, sost), (0.45, golpe), (0.55, sigue),
                                (0.68, sigue), (1.0, g)], eventos={"impacto": 0.45, "prep": 0.3})


def clips_de():
    """Todos los clips de Nix: los suyos y los de la biblioteca común con su estilo."""
    instalar()
    e = ESTILO
    lista = [c_reposo(e), c_guardia(e), BC.c_hablar(e), BC.c_hablar(e, True), BC.c_asentir(e), BC.c_interactuar(e),
             BC.c_saltar(e), BC.c_girar(e), c_ataque(e), c_recibir_golpe(e), c_derribo(e), c_derrota(e),
             c_levantarse(e), c_victoria(e), c_magia_lanzar(e), c_magia_estado(e), c_magia_culminante(e),
             c_concentrar(e), c_defender(e), c_defensa(e)]
    return lista
