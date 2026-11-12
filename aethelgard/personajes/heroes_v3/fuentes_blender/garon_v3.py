# Héroes v3 (V12): diseño de GARON, modelado por guion sobre su esqueleto (el común de los v2, en reposo en T).
#
# Lo que se conserva para reconocerle (dirección: docs/v12/DIRECCION_HEROES_V3.md):
#   yelmo cerrado grande con visera de rejilla y cresta, penacho rojo largo hacia atrás; armadura de acero oscuro con
#   ribetes dorados y el águila dorada en el pecho; hombreras de láminas; faldar de placas con tela roja delante y
#   detrás; rodilleras en punta; botas de placas; base ancha. Las dos espadas las pone el juego (arma_d y arma_i) y la
#   capa también (garon_3d.gd, garon_capa.png).
# Lo nuevo: un broquel redondo en el antebrazo izquierdo (su oficio de guardián, sin cambiar el combate: no estorba a
#   la espada de esa mano) y una mirada en la sombra de la visera (dos brillos que cambian con la expresión: el yelmo
#   sigue cerrado, pero se le lee el ánimo).
import math, random
from mathutils import Vector, Quaternion
import geometria_v3 as G
import kael_v3 as K

P = G.P


def _acero(co):
    return (0.25, 0.26, 0.31)


PALETA = {
    "acero": {"color": (0.44, 0.46, 0.52), "tipo": "metal"},
    "acero_claro": {"color": (0.72, 0.74, 0.80), "tipo": "metal"},
    "acero_osc": {"color": (0.24, 0.24, 0.28), "tipo": "metal"},
    "oro": {"color": (0.88, 0.72, 0.46), "tipo": "metal"},
    "rojo": {"color": (0.66, 0.12, 0.14), "tipo": "tela"},
    "rojo_osc": {"color": (0.42, 0.07, 0.09), "tipo": "tela"},
    "cota": {"color": (0.30, 0.31, 0.35), "tipo": "cuero"},
    "cuero": {"color": (0.40, 0.27, 0.17), "tipo": "cuero"},
    "negro": {"color": (0.05, 0.05, 0.07), "tipo": "oscuro"},
    "pluma": {"color": (0.82, 0.16, 0.16), "tipo": "pelo"},
    "guante": {"color": (0.44, 0.46, 0.52), "tipo": "metal"},     # nombres que usa la mano de K
    "piel": {"color": (0.40, 0.42, 0.48), "tipo": "metal"},
}

ESCALA_CABEZA = 1.08     # influencia chibi (crear_heroes_v3.py)

# El yelmo: centro y radios (el «cráneo» del que cuelga la cara)
CRANEO = {"c": Vector((0.010, -0.005, 1.430)), "rx": 0.205, "ry": 0.200, "rz": 0.205}

CARA = {
    "ojo": {"x": 0.060, "z": 1.425, "ancho": 0.070, "alto": 0.070},
    "boca": None,
    "ceja": None,
    "marca": None,
    "iris": ((1.0, 0.80, 0.50), (1.0, 0.93, 0.75)),
    "linea": (1.0, 0.85, 0.55),
    "ceja_color": (0.1, 0.1, 0.1),
    "mirada": "yelmo",
    "centro_x": 0.010,
    "sobre": "garon_visera",          # la cara se proyecta sobre la visera (no sobre la cabeza)
}


def construir(H):
    piezas = []
    C = CRANEO["c"]
    hip, sp, sp1, sp2, nk = H.c("Hips"), H.c("Spine"), H.c("Spine1"), H.c("Spine2"), H.c("Neck")

    # ------------------------------------------------------------ yelmo
    cab = G.Pieza("garon_cabeza", ["acero", "oro", "acero_claro"], [("Head", 1.0)])
    def yelmo(u):
        x, y, z = u.x, u.y, u.z
        if z < -0.1:                         # baja recto y algo más ancho (yelmo de guardián) hasta la gola
            z = -0.1 + (z + 0.1) * 1.15
            x *= 1.0 + 0.06 * min(1.0, (-0.1 - z) * 2)
        if y < -0.5:
            y = -0.5 + (y + 0.5) * 0.70      # frente plana para la visera
        return Vector((x, y, z))
    G.esfera(cab, C, CRANEO["rx"], CRANEO["ry"], CRANEO["rz"], segs=28, anillos=18, deformar=yelmo)
    # cresta dorada de delante atrás y arco dorado de la frente (en punta, el adorno del original)
    pts = [C + Vector((0, math.cos(a) * -0.215, math.sin(a) * 0.215)) for a in [math.radians(t) for t in range(20, 181, 20)]]
    for p0, p1 in zip(pts[:-1], pts[1:]):
        G.tubo(cab, [(p0, G.ARR, 0.012, 0.010), (p1, G.ARR, 0.012, 0.010)], segs=6, mat=lambda i, j: 1)
    for sx in (-1, 1):
        a0 = C + Vector((sx * 0.02, -0.195, 0.08))
        G.tubo(cab, [(a0, G.ADEL, 0.008, 0.008), (a0 + Vector((sx * 0.07, 0.02, 0.06)), G.ADEL, 0.007, 0.007),
                     (a0 + Vector((sx * 0.14, 0.07, 0.08)), G.ADEL, 0.006, 0.006)], segs=6, mat=lambda i, j: 1)
    G.gema(cab, C + Vector((0, -0.205, 0.075)), G.ARR, G.ADEL, 0.018, 0.07, mat=1)
    # borde inferior del yelmo (gola)
    G.tubo(cab, [(C + Vector((0, 0.01, -0.235)), G.ADEL, 0.168, 0.176), (C + Vector((0, 0.01, -0.21)), G.ADEL, 0.176, 0.186)],
           segs=20, mat=lambda i, j: 2)
    piezas.append(cab)
    # visera: banda oscura con barrotes (los ojos brillan en su sombra)
    vis = G.Pieza("garon_visera", ["negro", "acero_claro", "oro"], [("Head", 1.0)])
    def sup(a, fuera):
        # punto de la superficie del yelmo (frente aplanada) a la altura de la visera, algo hacia fuera
        ux, uy = math.sin(a), -math.cos(a)
        if uy < -0.5:
            uy = -0.5 + (uy + 0.5) * 0.70
        return C + Vector((ux * CRANEO["rx"], uy * CRANEO["ry"], -0.01)) + Vector((math.sin(a), -math.cos(a), 0)) * fuera
    for k in range(9):
        a = math.radians(-60 + 15 * k)
        d = Vector((math.sin(a), -math.cos(a), 0))
        G.caja(vis, sup(a, 0.004), (Vector((math.cos(a), math.sin(a), 0)), d, G.ARR), (0.027, 0.006, 0.032), mat=0)
    for k in range(5):
        a = math.radians(-50 + 25 * k)
        d = Vector((math.sin(a), -math.cos(a), 0))
        G.caja(vis, sup(a, 0.012), (Vector((math.cos(a), math.sin(a), 0)), d, G.ARR), (0.005, 0.006, 0.036), mat=1)
    # ribete de la visera (arriba y abajo)
    for dz in (0.040, -0.060):
        pts = [sup(math.radians(t), 0.010) + Vector((0, 0, dz)) for t in range(-70, 71, 14)]
        for p0, p1 in zip(pts[:-1], pts[1:]):
            G.tubo(vis, [(p0, G.ARR, 0.007, 0.007), (p1, G.ARR, 0.007, 0.007)], segs=5, mat=lambda i, j: 2)
    piezas.append(vis)
    # penacho rojo: plumas largas que salen de la cresta y caen hacia atrás
    pen = G.Pieza("garon_penacho", ["pluma"], [("Head", 1.0)], p=4)
    rnd = random.Random(5)
    base = C + Vector((0, 0.02, 0.215))
    for k in range(9):
        lado = rnd.uniform(-0.03, 0.03)
        r0 = base + Vector((lado, -0.04 + k * 0.015, 0.0))
        largo = 0.34 + rnd.uniform(-0.05, 0.10)
        G.mechon(pen, r0, r0 + Vector((lado, 0.04, 0.16)), r0 + Vector((lado * 2, 0.20, 0.16)),
                 r0 + Vector((lado * 3, largo, -0.02 - rnd.uniform(0, 0.08))), 0.048, 0.016, Vector((0, 0, 1)),
                 segs=8, lados=5, giro=rnd.uniform(-0.6, 0.6))
    piezas.append(pen)

    # ------------------------------------------------------------ torso: coraza, gola, cinturón
    cuello = G.Pieza("garon_gola", ["cota"], [("Neck", 1.0), ("Spine2", 0.6), ("Head", 0.4)], p=3)
    G.tubo(cuello, [(nk + Vector((0, 0, -0.04)), G.ADEL, 0.06, 0.07), (nk + Vector((0, 0, 0.06)), G.ADEL, 0.055, 0.06)], segs=12)
    piezas.append(cuello)
    tor = G.Pieza("garon_coraza", ["acero", "oro", "acero_claro", "cota"],
                  [("Hips", 1.0), ("Spine", 1.0), ("Spine1", 1.0), ("Spine2", 1.0), ("Neck", 0.3),
                   ("LeftShoulder", 0.5), ("RightShoulder", 0.5)], p=3)
    an = [(Vector((hip.x, hip.y, 0.80)), G.ADEL, 0.112, 0.142),
          (Vector((hip.x, hip.y, 0.86)), G.ADEL, 0.118, 0.148),
          (Vector((sp.x, sp.y, 0.93)), G.ADEL, 0.128, 0.155),
          (Vector((sp1.x, sp1.y, 1.02)), G.ADEL, 0.146, 0.170),
          (Vector((sp1.x, sp1.y, 1.09)), G.ADEL, 0.144, 0.176),
          (Vector((sp2.x, sp2.y, 1.14)), G.ADEL, 0.124, 0.166),
          (Vector((sp2.x, sp2.y, 1.18)), G.ADEL, 0.085, 0.106)]
    G.tubo(tor, an, segs=16, tapa0=True, tapa1=True, abombar=0.2,
           mat=lambda i, j: 1 if i == 4 else (2 if i == 0 else 0))
    # águila dorada del pecho: cuerpo, alas y cabeza (gemas planas)
    pe = Vector((sp1.x, sp1.y - 0.152, 1.055))
    G.gema(tor, pe, G.ARR, G.ADEL, 0.014, 0.075, mat=1)
    for sx in (-1, 1):
        for k, (dx, dz, l) in enumerate(((0.04, 0.02, 0.06), (0.06, 0.01, 0.05), (0.075, -0.005, 0.04))):
            ala = Vector((sx * dx, -0.003 * k, dz))
            G.gema(tor, pe + ala, Vector((sx, 0, 0.5)), G.ADEL, 0.010, l, mat=1)
    G.gema(tor, pe + Vector((0, -0.004, 0.045)), G.ARR, G.ADEL, 0.011, 0.024, mat=1)
    # cinturón de cuero con hebilla
    G.tubo(tor, [(Vector((hip.x, hip.y, 0.79)), G.ADEL, 0.120, 0.150), (Vector((hip.x, hip.y, 0.825)), G.ADEL, 0.121, 0.151)],
           segs=16, mat=lambda i, j: 3)
    G.caja(tor, Vector((hip.x, hip.y - 0.124, 0.807)), (G.DER, G.ADEL, G.ARR), (0.022, 0.006, 0.020), mat=1)
    piezas.append(tor)

    # ------------------------------------------------------------ faldar de placas y tela roja
    for nombre, a0, a1, huesos, rojo in (
            ("del", -0.55, 0.55, [("Hips", 1.0), ("LeftUpLeg", 0.5), ("RightUpLeg", 0.5)], True),
            ("tras", math.pi - 0.6, math.pi + 0.6, [("Hips", 1.6), ("LeftUpLeg", 0.3), ("RightUpLeg", 0.3)], True),
            ("lado_i", 0.65, 1.95, [("Hips", 1.0), ("LeftUpLeg", 0.9)], False),
            ("lado_d", 2 * math.pi - 1.95, 2 * math.pi - 0.65, [("Hips", 1.0), ("RightUpLeg", 0.9)], False)):
        mats = ["rojo", "oro", "rojo_osc"] if rojo else ["acero", "oro", "acero_claro"]
        pz = G.Pieza("garon_faldar_" + nombre, mats, huesos, p=2.5, grosor=0.006 if rojo else 0.012,
                     interior="rojo_osc" if rojo else "acero_osc")
        zs = [0.46, 0.475, 0.55, 0.64, 0.72, 0.80] if rojo else [0.56, 0.575, 0.64, 0.71, 0.78]
        an = []
        for z in zs:
            t = G.suave(0.80, 0.46, z)
            an.append({"c": Vector((hip.x, hip.y + 0.005, z)), "f": G.ADEL, "rx": 0.124 + 0.07 * t, "ry": 0.154 + 0.08 * t})
        n = 6
        G.tubo(pz, an, angulos=[a0 + (a1 - a0) * k / n for k in range(n + 1)], cerrado=False,
               mat=lambda i, j: 1 if i == 0 else 0)
        piezas.append(pz)

    # ------------------------------------------------------------ piernas: quijotes, rodilleras, grebas y escarpes
    for lado, sx in (("Left", 1), ("Right", -1)):
        ul, lg, ft, tb = H.c(lado + "UpLeg"), H.c(lado + "Leg"), H.c(lado + "Foot"), H.c(lado + "ToeBase")
        pi = G.Pieza("garon_pierna_" + lado, ["cota", "acero", "oro", "acero_claro"],
                     [("Hips", 0.5), (lado + "UpLeg", 1.0), (lado + "Leg", 1.0)], p=4)
        pts = [ul + Vector((sx * -0.02, 0, 0.03)), ul, ul.lerp(lg, 0.5), lg, lg.lerp(ft, 0.5), ft]
        rad = [(0.068, 0.070), (0.076, 0.076), (0.072, 0.072), (0.064, 0.064), (0.060, 0.060), (0.056, 0.056)]
        G.tubo(pi, G.cadena(pts, G.ADEL, rad, 2), segs=12)
        # quijote (placa del muslo)
        G.tubo(pi, [(ul.lerp(lg, 0.15), G.ADEL, 0.086, 0.087), (ul.lerp(lg, 0.55), G.ADEL, 0.083, 0.084),
                    (ul.lerp(lg, 0.85), G.ADEL, 0.076, 0.076)], segs=12,
               angulos=[-1.8 + 3.6 * k / 10 for k in range(11)], cerrado=False, mat=lambda i, j: 1)
        # rodillera en punta
        rod = lg + Vector((0, -0.05, 0.0))
        G.gema(pi, rod, G.ARR, G.ADEL, 0.045, 0.12, mat=3)
        G.gema(pi, rod + Vector((0, -0.012, 0)), G.ARR, G.ADEL, 0.022, 0.07, mat=2)
        # greba
        G.tubo(pi, [(lg.lerp(ft, 0.12), G.ADEL, 0.074, 0.074), (lg.lerp(ft, 0.6), G.ADEL, 0.072, 0.072),
                    (lg.lerp(ft, 0.92), G.ADEL, 0.070, 0.070)], segs=12, mat=lambda i, j: 1)
        piezas.append(pi)
        bota = G.Pieza("garon_bota_" + lado, ["acero", "oro", "acero_osc"],
                       [(lado + "Leg", 0.6), (lado + "Foot", 1.4), (lado + "ToeBase", 1.0)], p=5)
        dirp = Vector((tb.x - ft.x, tb.y - ft.y, 0)).normalized()
        talon = Vector((ft.x, ft.y, 0.055)) - dirp * 0.05
        punta = Vector((tb.x, tb.y, 0.034)) + dirp * 0.06
        an = [(talon, G.ARR, 0.060, 0.066), (talon.lerp(punta, 0.35) + Vector((0, 0, 0.016)), G.ARR, 0.068, 0.072),
              (talon.lerp(punta, 0.7), G.ARR, 0.050, 0.068), (punta, G.ARR, 0.030, 0.052)]
        G.tubo(bota, an, segs=12, tapa0=True, tapa1=True, abombar=0.5,
               mat=lambda i, j: 1 if i == 1 and j in (2, 3, 4) else 0)
        sue = [(Vector((p[0].x, p[0].y, 0.012)), G.ARR, 0.013, p[3] + 0.005) for p in an]
        G.tubo(bota, sue, segs=10, tapa0=True, tapa1=True, abombar=0.5, mat=lambda i, j: 2)
        piezas.append(bota)

    # ------------------------------------------------------------ brazos, hombreras, guanteletes, broquel
    for lado, sx in (("Left", 1), ("Right", -1)):
        ar, fa, hd = H.c(lado + "Arm"), H.c(lado + "ForeArm"), H.c(lado + "Hand")
        br = G.Pieza("garon_brazo_" + lado, ["cota", "acero", "oro"],
                     [(lado + "Shoulder", 0.6), (lado + "Arm", 1.0), (lado + "ForeArm", 1.0), (lado + "Hand", 0.6)], p=4)
        pts = [ar - Vector((sx * 0.04, 0, 0)), ar, ar.lerp(fa, 0.5), fa, fa.lerp(hd, 0.5), hd]
        rad = [(0.060, 0.060), (0.058, 0.058), (0.054, 0.054), (0.050, 0.050), (0.046, 0.046), (0.040, 0.040)]
        G.tubo(br, G.cadena(pts, G.ADEL, rad, 2), segs=10)
        # brazal (antebrazo) con borde dorado
        G.tubo(br, [(fa.lerp(hd, 0.05), G.ADEL, 0.050, 0.050), (fa.lerp(hd, 0.55), G.ADEL, 0.052, 0.052),
                    (fa.lerp(hd, 0.92), G.ADEL, 0.056, 0.056)], segs=10, mat=lambda i, j: 2 if i == 1 else 1)
        piezas.append(br)
        piezas.append(_guante(H, lado, sx))
        hb = G.Pieza("garon_hombrera_" + lado, ["acero", "oro", "acero_claro"],
                     [(lado + "Shoulder", 1.0), (lado + "Arm", 0.7), ("Spine2", 0.3)], p=4, grosor=0.01,
                     interior="acero_claro")
        c = ar + Vector((-sx * 0.01, 0.004, 0.035))
        # tres láminas que se solapan hacia el codo; cada una cubre el hombro por arriba, delante y detrás
        for k, (dz, r, ext) in enumerate(((0.0, 1.0, 0.0), (-0.03, 1.02, 0.035), (-0.062, 1.0, 0.065))):
            an = [{"c": c + Vector((sx * (-0.05 + ext * 0.4), 0, dz)), "f": G.ARR, "rx": 0.074 * r, "ry": 0.098 * r},
                  {"c": c + Vector((sx * (0.02 + ext), 0, dz - 0.012)), "f": G.ARR, "rx": 0.082 * r, "ry": 0.106 * r},
                  {"c": c + Vector((sx * (0.07 + ext), 0, dz - 0.036)), "f": G.ARR, "rx": 0.072 * r, "ry": 0.096 * r}]
            G.tubo(hb, an, angulos=[-1.95 + 3.9 * q / 12 for q in range(13)], cerrado=False,
                   mat=lambda i, j: 1 if i == 2 else 0)
        piezas.append(hb)
        if lado == "Left":     # broquel en el antebrazo, por fuera
            bq = G.Pieza("garon_broquel", ["acero", "oro", "rojo", "acero_claro"], [(lado + "ForeArm", 1.0)], p=4)
            cb = fa.lerp(hd, 0.45) + Vector((0, 0.0, 0.085))
            arriba = Vector((0, 0, 1))
            an = [{"c": cb + arriba * 0.000, "f": G.ADEL, "rx": 0.105, "ry": 0.105},
                  {"c": cb + arriba * 0.018, "f": G.ADEL, "rx": 0.100, "ry": 0.100},
                  {"c": cb + arriba * 0.030, "f": G.ADEL, "rx": 0.070, "ry": 0.070},
                  {"c": cb + arriba * 0.040, "f": G.ADEL, "rx": 0.030, "ry": 0.030}]
            G.tubo(bq, an, segs=18, tapa0=True, tapa1=True, abombar=0.3,
                   mat=lambda i, j: 1 if i == 0 else (2 if i == 1 else 3))
            piezas.append(bq)
    return piezas


def _guante(H, lado, sx):
    """Guantelete: la mano de K con dedos gruesos de acero (Garon tiene los huesos de todos los dedos)."""
    import lya_v3 as L                   # como Lya, su esqueleto solo trae pulgar y corazón
    m = L._mano(H, lado, sx)
    m.nombre = "garon_guante_" + lado
    return m
