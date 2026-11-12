# Héroes v3 (V12): diseño de KAEL, modelado por guion sobre su esqueleto (el común de los v2, en reposo en T).
#
# Lo que se conserva para reconocerle (dirección: docs/v12/DIRECCION_HEROES_V3.md):
#   pelo negro azulado alborotado con flequillo entre los ojos y un mechón rebelde arriba; ojos azules; la cicatriz en
#   cruz de la mejilla izquierda; abrigo largo blanco abierto con cuello alto, forro y bajos azul hielo y ribetes
#   dorados; camisa azul marino con el colgante de estrella; cinturones de cuero con hebillas; guantes negros sin
#   dedos; pantalón oscuro y botas altas marrones con correas. El sable lo pone el juego (hueso arma_d).
# Lo nuevo: cabeza más grande (chibi 1 : 2,9), ojos grandes de atlas propio, cejas que se mueven, mechones con volumen,
# abrigo en piezas que se separan al andar, manos con dedos y siluetas más limpias (picos del pelo y faldones).
import math
from mathutils import Vector, Quaternion
import geometria_v3 as G

P = G.P

# ------------------------------------------------------------------ paleta (sRGB) y tipos de material
def _abrigo(co):
    # blanco arriba que pasa a azul hielo hacia los bajos (el degradado del abrigo original)
    t = G.suave(0.62, 0.30, co.z)
    return G.mezcla((0.88, 0.89, 0.92), (0.62, 0.77, 0.92), t)


def _forro(co):
    t = G.suave(0.9, 0.35, co.z)
    return G.mezcla((0.38, 0.58, 0.84), (0.56, 0.76, 0.93), t)


def _piel(co):
    # rubor suave en las mejillas (delante de la cara, a la altura de la boca)
    base = (0.99, 0.91, 0.88)
    for sx in (-1, 1):
        d = Vector((co.x - (0.010 + sx * 0.098), (co.y + 0.16) * 0.7, co.z - 1.262)).length
        k = max(0.0, 1.0 - d / 0.045) ** 1.5 * 0.55
        if k > 0:
            base = G.mezcla(base, (0.98, 0.66, 0.62), k)
    return base


def _pelo(co):
    # negro azulado con las puntas algo más claras y azules
    t = G.suave(1.45, 1.70, co.z) * 0.6
    return G.mezcla((0.30, 0.27, 0.30), (0.34, 0.35, 0.46), t)


PALETA = {
    "piel": {"color": _piel, "tipo": "piel"},
    "pelo": {"color": _pelo, "tipo": "pelo"},
    "abrigo": {"color": _abrigo, "tipo": "tela"},
    "forro": {"color": _forro, "tipo": "tela"},
    "azul": {"color": (0.34, 0.53, 0.78), "tipo": "tela"},
    "azul_hielo": {"color": (0.58, 0.75, 0.90), "tipo": "tela"},
    "oro": {"color": (0.86, 0.74, 0.50), "tipo": "metal"},
    "plata": {"color": (0.80, 0.84, 0.90), "tipo": "metal"},
    "marino": {"color": (0.15, 0.18, 0.31), "tipo": "tela"},
    "marino_claro": {"color": (0.20, 0.27, 0.46), "tipo": "tela"},
    "pantalon": {"color": (0.11, 0.11, 0.15), "tipo": "tela"},
    "cuero": {"color": (0.43, 0.27, 0.16), "tipo": "cuero"},
    "cuero_osc": {"color": (0.27, 0.17, 0.11), "tipo": "cuero"},
    "bota": {"color": (0.47, 0.31, 0.19), "tipo": "cuero"},
    "suela": {"color": (0.17, 0.11, 0.08), "tipo": "cuero"},
    "guante": {"color": (0.10, 0.10, 0.12), "tipo": "cuero"},
    "cristal": {"color": (0.36, 0.74, 0.95), "tipo": "cristal"},
    "boca": {"color": (0.55, 0.25, 0.25), "tipo": "piel"},
}

# Cara (cara_v3.py): dónde van ojos, boca, cejas y la cicatriz (coordenadas del mundo en reposo) y sus colores
CARA = {
    "ojo": {"x": 0.070, "z": 1.306, "ancho": 0.122, "alto": 0.122},
    "boca": {"x": 0.0, "z": 1.226, "ancho": 0.056, "alto": 0.046},
    "ceja": {"z": 1.378, "largo": 0.052, "grueso": 0.010, "inclinacion": 6.0},
    "marca": {"x": 0.112, "z": 1.262, "ancho": 0.034, "alto": 0.034, "lado": 1},   # cicatriz en su mejilla izquierda
    "iris": ((0.10, 0.30, 0.78), (0.42, 0.80, 1.0)),      # de arriba (oscuro) a abajo (claro)
    "linea": (0.10, 0.08, 0.10),
    "ceja_color": (0.09, 0.09, 0.13),
    "mirada": "viva",          # forma base del ojo: «viva» (Kael: algo afilada) o «dulce» (Lya: redonda)
    "centro_x": 0.010,
}

# Influencia chibi: la cabeza y el pelo se agrandan desde la base del cráneo (crear_heroes_v3.py)
ESCALA_CABEZA = 1.16

# Cráneo (centro y radios) para la cara y el pelo
CRANEO = {"c": Vector((0.010, -0.020, 1.356)), "rx": 0.186, "ry": 0.172, "rz": 0.182}


def _cabeza_deformar(u):
    x, y, z = u.x, u.y, u.z
    # mandíbula: se estrecha hacia la barbilla, que queda pequeña y algo adelantada
    if z < 0:
        k = G.suave(0.0, -1.0, z)
        x *= 1.0 - 0.36 * k
        y *= 1.0 - 0.22 * k
        if y < 0:
            y -= 0.10 * k * (1.0 - abs(x) * 1.6)
        z *= 0.93
    # la cara, algo más estrecha que el cráneo y poco plana (donde van ojos y boca); nuca redonda
    if y < 0:
        x *= 1.0 - 0.07 * min(1.0, -y * 1.6)
    if y < -0.60:
        y = -0.60 + (y + 0.60) * 0.72
    if y > 0:
        y *= 1.04
    return Vector((x, y, z))


def construir(H):
    piezas = []
    C = CRANEO["c"]

    # ------------------------------------------------------------ cabeza, orejas, nariz y cuello
    cab = G.Pieza("kael_cabeza", ["piel"], [("Head", 1.0)])
    G.esfera(cab, C, CRANEO["rx"], CRANEO["ry"], CRANEO["rz"], segs=28, anillos=18, deformar=_cabeza_deformar)
    for sx in (-1, 1):
        G.esfera(cab, C + Vector((sx * 0.172, 0.014, -0.05)), 0.016, 0.013, 0.026, segs=8, anillos=6)
    # nariz: una cuña pequeña (en el estilo chibi apenas se ve; de cerca da el perfil)
    piezas.append(cab)

    cuello = G.Pieza("kael_cuello", ["piel"], [("Neck", 1.0), ("Head", 0.6), ("Spine2", 0.4)], p=3)
    n0, n1 = H.c("Neck"), H.c("Head")
    G.tubo(cuello, [(n0 + Vector((0, 0, -0.03)), G.ADEL, 0.040, 0.044), (n0.lerp(n1, 0.6), G.ADEL, 0.035, 0.038),
                    (n1 + Vector((0, 0.004, 0.05)), G.ADEL, 0.036, 0.040)], segs=10)
    piezas.append(cuello)

    # ------------------------------------------------------------ torso (camisa azul marino)
    tor = G.Pieza("kael_torso", ["marino", "marino_claro", "cuero"],
                  [("Hips", 1.0), ("Spine", 1.0), ("Spine1", 1.0), ("Spine2", 1.0), ("Neck", 0.3),
                   ("LeftShoulder", 0.5), ("RightShoulder", 0.5)], p=3)
    hip, sp, sp1, sp2, nk = H.c("Hips"), H.c("Spine"), H.c("Spine1"), H.c("Spine2"), H.c("Neck")
    an = [
        (Vector((hip.x, hip.y, 0.69)), G.ADEL, 0.082, 0.112),
        (Vector((hip.x, hip.y, 0.76)), G.ADEL, 0.085, 0.114),
        (Vector((sp.x, sp.y, 0.86)), G.ADEL, 0.077, 0.101),
        (Vector((sp1.x, sp1.y, 0.95)), G.ADEL, 0.081, 0.108),
        (Vector((sp1.x, sp1.y, 1.01)), G.ADEL, 0.083, 0.116),
        (Vector((sp2.x, sp2.y, 1.06)), G.ADEL, 0.075, 0.118),
        (Vector((nk.x, nk.y, 1.105)), G.ADEL, 0.052, 0.070),
    ]
    G.tubo(tor, an, segs=14, tapa0=True, tapa1=True, abombar=0.2,
           mat=lambda i, j: 1 if (i >= 4 and (j <= 1 or j >= 13)) else 0)
    piezas.append(tor)

    # ------------------------------------------------------------ piernas (pantalón), botas
    for lado, sx in (("Left", 1), ("Right", -1)):
        ul, lg, ft, tb = H.c(lado + "UpLeg"), H.c(lado + "Leg"), H.c(lado + "Foot"), H.c(lado + "ToeBase")
        pierna = G.Pieza("kael_pierna_" + lado, ["pantalon"],
                         [("Hips", 0.5), (lado + "UpLeg", 1.0), (lado + "Leg", 1.0)], p=4)
        pts = [ul + Vector((sx * -0.02, 0, 0.03)), ul, ul.lerp(lg, 0.5), lg + Vector((0, 0, 0.03)), lg,
               lg.lerp(ft, 0.45)]
        rad = [(0.052, 0.052), (0.058, 0.058), (0.058, 0.059), (0.054, 0.056), (0.054, 0.054), (0.050, 0.050)]
        # el pantalón algo abombado por encima de las botas
        G.tubo(pierna, G.cadena(pts, G.ADEL, rad, 2), segs=12, tapa1=True)
        piezas.append(pierna)

        bota = G.Pieza("kael_bota_" + lado, ["bota", "cuero_osc", "oro", "suela"],
                       [(lado + "Leg", 1.0), (lado + "Foot", 1.4)], p=5)
        eje = (ft - lg).normalized()
        tope = lg + eje * 0.06
        b_an = [
            (ft + Vector((0, 0.006, -0.055)), G.ADEL, 0.050, 0.047),
            (ft + Vector((0, 0.004, -0.02)), G.ADEL, 0.051, 0.048),
            (ft.lerp(tope, 0.35), G.ADEL, 0.054, 0.051),
            (ft.lerp(tope, 0.7), G.ADEL, 0.058, 0.055),
            (tope, G.ADEL, 0.062, 0.060),
            (tope + Vector((0, 0, 0.012)), G.ADEL, 0.071, 0.068),      # vuelta de la caña
            (tope + Vector((0, 0, 0.045)), G.ADEL, 0.074, 0.071),
            (tope + Vector((0, 0, 0.052)), G.ADEL, 0.064, 0.062),
        ]
        G.tubo(bota, b_an, segs=12, mat=lambda i, j: 1 if i >= 5 else 0)
        # correas con hebilla (dos)
        for zc in (0.20, 0.29):
            c = Vector((ft.x + (tope.x - ft.x) * (zc - ft.z) / max(tope.z - ft.z, 1e-3), ft.y, zc))
            r = 0.053 + (zc - 0.17) * 0.07
            G.tubo(bota, [(c + Vector((0, 0, -0.009)), G.ADEL, r + 0.006, r + 0.005),
                          (c + Vector((0, 0, 0.009)), G.ADEL, r + 0.006, r + 0.005)], segs=12,
                   mat=lambda i, j: 1)
            hb = c + Vector((sx * (r + 0.008), -0.012, 0))
            G.caja(bota, hb, (Vector((sx, 0, 0)), G.ADEL, G.ARR), (0.004, 0.011, 0.012), mat=2)
        # pie: del talón a la punta, con la puntera redonda
        dirp = Vector((tb.x - ft.x, tb.y - ft.y, 0)).normalized()
        talon = Vector((ft.x, ft.y, 0.05)) - dirp * 0.040
        punta = Vector((tb.x, tb.y, 0.034)) + dirp * 0.045
        lateral = Vector((-dirp.y, dirp.x, 0))
        pie_an = [
            (talon, G.ARR, 0.042, 0.044),
            (talon.lerp(punta, 0.3) + Vector((0, 0, 0.006)), G.ARR, 0.050, 0.050),
            (talon.lerp(punta, 0.62), G.ARR, 0.036, 0.050),
            (talon.lerp(punta, 0.86) + Vector((0, 0, -0.004)), G.ARR, 0.030, 0.046),
            (punta + Vector((0, 0, -0.006)), G.ARR, 0.022, 0.034),
        ]
        G.tubo(bota, pie_an, segs=12, tapa0=True, tapa1=True, abombar=0.5)
        # suela
        sue = [(Vector((p[0].x, p[0].y, 0.010)), G.ARR, 0.011, p[3] + 0.004) for p in pie_an]
        G.tubo(bota, sue, segs=10, tapa0=True, tapa1=True, abombar=0.5, mat=lambda i, j: 3)
        piezas.append(bota)

    # ------------------------------------------------------------ brazos (manga de la camisa) y manos
    for lado, sx in (("Left", 1), ("Right", -1)):
        sh, ar, fa, hd = H.c(lado + "Shoulder"), H.c(lado + "Arm"), H.c(lado + "ForeArm"), H.c(lado + "Hand")
        brazo = G.Pieza("kael_brazo_" + lado, ["marino"],
                        [(lado + "Shoulder", 0.6), (lado + "Arm", 1.0), (lado + "ForeArm", 1.0), (lado + "Hand", 0.6)],
                        p=4)
        pts = [ar - Vector((sx * 0.035, 0, 0)), ar, ar.lerp(fa, 0.5), fa, fa.lerp(hd, 0.5), hd]
        rad = [(0.046, 0.046), (0.045, 0.045), (0.040, 0.040), (0.034, 0.034), (0.031, 0.031), (0.027, 0.027)]
        G.tubo(brazo, G.cadena(pts, G.ADEL, rad, 2), segs=10)
        piezas.append(brazo)
        piezas.append(_mano(H, lado, sx))

    # ------------------------------------------------------------ abrigo
    piezas += _abrigo_piezas(H)

    # ------------------------------------------------------------ cinturones, colgante y cristales
    cin = G.Pieza("kael_cinturones", ["cuero", "oro", "cuero_osc", "cristal"],
                  [("Hips", 1.0), ("Spine", 0.8)], p=3)
    # cinturón ancho de la cintura
    G.tubo(cin, [(Vector((hip.x, hip.y - 0.002, 0.825)), G.ADEL, 0.089, 0.111),
                 (Vector((hip.x, hip.y - 0.002, 0.855)), G.ADEL, 0.087, 0.108)], segs=16, mat=lambda i, j: 0)
    G.caja(cin, Vector((hip.x, hip.y - 0.093, 0.840)), (G.DER, G.ADEL, G.ARR), (0.020, 0.005, 0.019), mat=1)
    G.caja(cin, Vector((hip.x, hip.y - 0.097, 0.840)), (G.DER, G.ADEL, G.ARR), (0.012, 0.003, 0.011), mat=2)
    # cinturón caído en diagonal sobre la cadera
    eje = Quaternion(G.ADEL, math.radians(9)) @ G.ARR
    c0 = Vector((hip.x, hip.y, 0.765))
    G.tubo(cin, [(c0 - eje * 0.011, G.ADEL, 0.096, 0.121), (c0 + eje * 0.011, G.ADEL, 0.095, 0.120)], segs=16)
    G.caja(cin, c0 + Vector((-0.045, -0.092, -0.004)), (G.DER, G.ADEL, G.ARR), (0.016, 0.005, 0.016), mat=1)
    # cristales colgando de las caderas (los del abrigo original)
    for sx, z in ((1, 0.73), (-1, 0.72)):
        G.gema(cin, Vector((hip.x + sx * 0.118, hip.y - 0.03, z - 0.035)), G.ARR, G.ADEL, 0.008, 0.032, mat=3)
        G.tubo(cin, [(Vector((hip.x + sx * 0.118, hip.y - 0.03, z - 0.018)), G.ADEL, 0.002, 0.002),
                     (Vector((hip.x + sx * 0.116, hip.y - 0.03, z + 0.03)), G.ADEL, 0.002, 0.002)], segs=4, mat=lambda i, j: 1)
    piezas.append(cin)

    col = G.Pieza("kael_colgante", ["oro", "cristal"], [("Spine2", 1.0), ("Spine1", 0.6)], p=3)
    centro = Vector((sp2.x, sp2.y - 0.088, 1.005))
    # estrella de cuatro puntas: dos rombos cruzados
    G.gema(col, centro, G.ARR, G.ADEL, 0.008, 0.050, mat=1)
    G.gema(col, centro + Vector((0, -0.002, 0)), G.DER, G.ADEL, 0.007, 0.036, mat=1)
    for sx in (-1, 1):
        G.tubo(col, [(centro + Vector((0, 0, 0.026)), G.ADEL, 0.0018, 0.0018),
                     (Vector((sp2.x + sx * 0.040, sp2.y - 0.075, 1.085)), G.ADEL, 0.0018, 0.0018)], segs=4,
               mat=lambda i, j: 0)
    piezas.append(col)

    # ------------------------------------------------------------ pelo
    piezas.append(_pelo_piezas())
    return piezas


def _mano(H, lado, sx):
    hd, hk = H.c(lado + "Hand"), H.k(lado + "Hand")
    m = G.Pieza("kael_mano_" + lado, ["guante", "piel", "oro"],
                [(lado + "Hand", 1.0)] + [(lado + "Hand" + d + str(i), 1.0)
                                          for d in ("Thumb", "Index", "Middle", "Ring", "Pinky") for i in (1, 2, 3)],
                p=5)
    eje = (hk - hd).normalized()
    nudillos = H.c(lado + "HandMiddle1")
    # palma: plana (la palma mira abajo en la T), con el dorso abombado
    abajo = Vector((0, 0, -1))
    pal = [
        (hd - eje * 0.012, abajo, 0.019, 0.025),
        (hd + eje * 0.010, abajo, 0.019, 0.029),
        (hd.lerp(nudillos, 0.6), abajo, 0.018, 0.034),
        (nudillos - eje * 0.004, abajo, 0.016, 0.033),
        (nudillos + eje * 0.006, abajo, 0.012, 0.030),
    ]
    G.tubo(m, pal, segs=10, tapa1=True, abombar=0.3)
    # muñequera dorada (el brazalete del original)
    G.tubo(m, [(hd - eje * 0.030, abajo, 0.032, 0.033), (hd - eje * 0.012, abajo, 0.032, 0.033)], segs=10,
           mat=lambda i, j: 2)
    for d, r in (("Index", 0.0085), ("Middle", 0.0090), ("Ring", 0.0085), ("Pinky", 0.0075), ("Thumb", 0.0095)):
        pts = [H.c(lado + "Hand" + d + str(i)) for i in (1, 2, 3, 4)]
        pts.append(H.k(lado + "Hand" + d + "4"))
        if d != "Thumb":
            pts[0] = pts[0] - eje * 0.004
        ra = [(r, r)] * 2 + [(r * 0.92, r * 0.92), (r * 0.85, r * 0.85), (r * 0.7, r * 0.7)]
        # sin dedos: la primera falange con guante, el resto piel
        G.tubo(m, G.cadena(pts[:4] + [pts[3].lerp(pts[4], 0.5)], abajo, ra[:5], 1), segs=6, tapa1=True, abombar=0.6,
               mat=lambda i, j: 0 if i < 1 else 1)
    return m


def _abrigo_piezas(H):
    piezas = []
    hip, sp1, sp2 = H.c("Hips"), H.c("Spine1"), H.c("Spine2")
    cx, cy = hip.x, hip.y
    # --- cuerpo del abrigo (de la cintura a los hombros), abierto delante en V
    ab = G.Pieza("kael_abrigo", ["abrigo", "oro", "azul"],
                 [("Hips", 1.0), ("Spine", 1.0), ("Spine1", 1.0), ("Spine2", 1.0), ("LeftShoulder", 0.7),
                  ("RightShoulder", 0.7)], p=3, grosor=0.006, interior="forro")
    filas = [(0.76, 0.30, 0.099, 0.130), (0.80, 0.28, 0.094, 0.124), (0.87, 0.26, 0.087, 0.112), (0.95, 0.28, 0.091, 0.118),
             (1.01, 0.34, 0.094, 0.127), (1.055, 0.48, 0.088, 0.131), (1.095, 0.72, 0.066, 0.100)]
    an = []
    for z, g, fo, a in filas:
        an.append({"c": Vector((cx, cy + 0.004, z)), "f": G.ADEL, "rx": fo, "ry": a})
    # ángulos con columnas extra junto al borde (el ribete dorado y la vista azul)
    def angulos(g):
        base = [g, g + 0.06, g + 0.26]
        n = 14
        resto = [g + 0.26 + (2 * math.pi - 2 * (g + 0.26)) * k / n for k in range(1, n)]
        return base + resto + [2 * math.pi - g - 0.26, 2 * math.pi - g - 0.06, 2 * math.pi - g]
    # mismo número de columnas en cada anillo: se interpola el hueco por anillo con un perfil de ángulo
    cols = len(angulos(0.3))
    bm_an = []
    for z, g, fo, a in filas:
        bm_an.append(angulos(g))
    # tubo con ángulos por anillo: se construye anillo a anillo
    _tubo_angulos(ab, an, bm_an, mat=lambda i, j: 1 if j == 0 or j == cols - 2 else (2 if j == 1 or j == cols - 3 else 0))
    piezas.append(ab)

    # --- faldones (de la cintura a media pantorrilla): cuatro paños que se separan con las piernas; delante se abren
    # en V hacia abajo (se ven el pantalón y las botas), con abertura atrás y a los lados
    zs = [0.26, 0.275, 0.29, 0.35, 0.44, 0.55, 0.67, 0.77, 0.85]
    def frente_de(z):
        return 0.30 + 0.62 * G.suave(0.84, 0.30, z)
    for nombre, huesos in (("del_i", [("Hips", 1.0), ("LeftUpLeg", 0.9)]),
                           ("tras_i", [("Hips", 1.6), ("LeftUpLeg", 0.5)]),
                           ("tras_d", [("Hips", 1.6), ("RightUpLeg", 0.5)]),
                           ("del_d", [("Hips", 1.0), ("RightUpLeg", 0.9)])):
        pz = G.Pieza("kael_faldon_" + nombre, ["abrigo", "oro", "azul_hielo"], huesos, p=2.5, grosor=0.006,
                     interior="forro")
        an, angs = [], []
        n = 9
        for z in zs:
            t = G.suave(0.85, 0.26, z)
            fo = 0.100 + 0.094 * t ** 0.8
            a = 0.138 + 0.127 * t ** 0.8
            an.append({"c": Vector((cx, cy + 0.012 + 0.02 * t, z)), "f": G.ADEL, "rx": fo, "ry": a})
            g = frente_de(z)
            lado_ab = 1.58 - 0.04 * t                  # abertura lateral
            tramos = {"del_i": (g, lado_ab - 0.03), "tras_i": (lado_ab + 0.03, math.pi - 0.035),
                      "tras_d": (math.pi + 0.035, 2 * math.pi - lado_ab - 0.03),
                      "del_d": (2 * math.pi - lado_ab + 0.03, 2 * math.pi - g)}
            a0, a1 = tramos[nombre]
            angs.append([a0 + (a1 - a0) * k / n for k in range(n + 1)])
        delantero = nombre.startswith("del")
        def mat(i, j, delantero=delantero, n=n, nombre=nombre):
            if i == 0:
                return 1                   # ribete dorado del bajo
            if i == 1:
                return 2                   # banda azul hielo
            if delantero and ((nombre == "del_i" and j == 0) or (nombre == "del_d" and j == n - 1)):
                return 1                   # ribete del borde delantero
            return 0
        _tubo_angulos(pz, an, angs, mat=mat)
        piezas.append(pz)

    # --- cuello alto (blanco por fuera, azul por dentro, ribete dorado arriba)
    nk = H.c("Neck")
    cu = G.Pieza("kael_cuello_abrigo", ["abrigo", "oro"], [("Spine2", 1.0), ("Neck", 0.7)], p=3, grosor=0.006,
                 interior="azul")
    an = [{"c": Vector((nk.x, nk.y + 0.004, 1.085)), "f": G.ADEL, "rx": 0.072, "ry": 0.088},
          {"c": Vector((nk.x, nk.y + 0.010, 1.135)), "f": G.ADEL, "rx": 0.080, "ry": 0.098},
          {"c": Vector((nk.x, nk.y + 0.018, 1.185)), "f": G.ADEL, "rx": 0.090, "ry": 0.108},
          {"c": Vector((nk.x, nk.y + 0.022, 1.198)), "f": G.ADEL, "rx": 0.093, "ry": 0.110}]
    angs = [0.62 + (2 * math.pi - 1.24) * k / 16 for k in range(17)]
    G.tubo(cu, an, angulos=angs, cerrado=False, mat=lambda i, j: 1 if i == 2 else 0)
    piezas.append(cu)

    # --- mangas (hasta media antebrazo, con vuelta azul y franja dorada) y hombreras
    for lado, sx in (("Left", 1), ("Right", -1)):
        ar, fa, hd = H.c(lado + "Arm"), H.c(lado + "ForeArm"), H.c(lado + "Hand")
        mg = G.Pieza("kael_manga_" + lado, ["abrigo", "azul", "oro"],
                     [(lado + "Shoulder", 0.5), (lado + "Arm", 1.0), (lado + "ForeArm", 1.0)], p=4, grosor=0.005,
                     interior="marino")
        fin = fa.lerp(hd, 0.55)
        pts = [ar - Vector((sx * 0.045, 0, -0.006)), ar, ar.lerp(fa, 0.55), fa, fa.lerp(fin, 0.6), fin,
               fin + Vector((sx * 0.004, 0, 0))]
        rad = [(0.060, 0.060), (0.059, 0.058), (0.054, 0.053), (0.050, 0.049), (0.051, 0.050), (0.054, 0.053),
               (0.054, 0.053)]
        an = G.cadena(pts, G.ADEL, rad, 1)
        nn = len(an)
        G.tubo(mg, an, segs=12, mat=lambda i, j, nn=nn: 2 if i == nn - 4 else (1 if i >= nn - 3 else 0))
        piezas.append(mg)
        hb = G.Pieza("kael_hombrera_" + lado, ["abrigo", "oro"],
                     [(lado + "Shoulder", 1.0), (lado + "Arm", 0.6), ("Spine2", 0.3)], p=4)
        c = ar + Vector((-sx * 0.004, 0.002, 0.020))
        an = [{"c": c + Vector((sx * -0.040, 0, 0)), "f": G.ARR, "rx": 0.048, "ry": 0.058},
              {"c": c + Vector((sx * 0.005, 0, -0.004)), "f": G.ARR, "rx": 0.052, "ry": 0.064},
              {"c": c + Vector((sx * 0.040, 0, -0.016)), "f": G.ARR, "rx": 0.046, "ry": 0.062},
              {"c": c + Vector((sx * 0.050, 0, -0.022)), "f": G.ARR, "rx": 0.036, "ry": 0.054}]
        G.tubo(hb, an, angulos=[-1.85 + 3.7 * k / 10 for k in range(11)], cerrado=False,
               mat=lambda i, j: 1 if i == 2 else 0)
        piezas.append(hb)
    return piezas


def _tubo_angulos(pz, anillos, angs_por_anillo, mat):
    """Como G.tubo con cerrado=False, pero cada anillo con sus propios ángulos (mismo número de columnas)."""
    bm = pz.bm
    filas = []
    for i, a in enumerate(anillos):
        c = Vector(a["c"])
        t = (Vector(anillos[min(i + 1, len(anillos) - 1)]["c"]) - Vector(anillos[max(i - 1, 0)]["c"]))
        t, n, b = G.marco(t, Vector(a["f"]))
        fila = []
        for ang in angs_por_anillo[i]:
            fila.append(bm.verts.new(c + n * math.cos(ang) * a["rx"] + b * math.sin(ang) * a["ry"]))
        filas.append(fila)
    G._uv_filas(pz, filas, [Vector(a["c"]) for a in anillos], cerrado=False)
    nj = len(angs_por_anillo[0])
    for i in range(len(filas) - 1):
        for j in range(nj - 1):
            f = bm.faces.new((filas[i][j], filas[i][j + 1], filas[i + 1][j + 1], filas[i + 1][j]))
            f.material_index = mat(i, j)


# ------------------------------------------------------------------ pelo
def _u(theta, phi):
    """Dirección desde el centro del cráneo: theta desde arriba (grados), phi alrededor (0 = frente, + = izquierda)."""
    t, p = math.radians(theta), math.radians(phi)
    return Vector((math.sin(t) * math.sin(p), -math.sin(t) * math.cos(p), math.cos(t)))


def _punto(theta, phi, k=1.0):
    C = CRANEO["c"]
    u = _u(theta, phi)
    return C + Vector((u.x * CRANEO["rx"], u.y * CRANEO["ry"], u.z * CRANEO["rz"])) * k


def _mechon_craneo(pz, theta, phi, largo, caida, salir, ancho, grueso, giro=0.0, curva=0.0, lateral=0.0, segs=7,
                   hundir=0.92):
    """Mechón que nace en (theta, phi) del cráneo y cae «caida» grados por debajo de la tangente (0 = sigue la superficie
    hacia abajo, positivo = se separa), «salir» = cuánto se separa del cráneo, «curva» = cuánto vuelve la punta hacia
    arriba (picos), «lateral» = desvío a un lado (grados)."""
    u = _u(theta, phi)
    raiz = _punto(theta, phi, hundir)
    # tangente «hacia abajo» por el meridiano
    t = _u(theta + 1.0, phi) - _u(theta, phi)
    if t.length < 1e-6:
        t = Vector((0, -1, 0))
    t.normalize()
    t = Quaternion(u, math.radians(lateral)) @ t
    eje = t.cross(u).normalized()
    d = Quaternion(eje, -math.radians(caida)) @ t        # se separa de la superficie
    c1 = raiz + u * 0.02 * salir + d * largo * 0.35
    c2 = raiz + u * 0.035 * salir + d * largo * 0.7
    punta = raiz + u * 0.03 * salir + d * largo + u * curva * largo
    G.mechon(pz, raiz, c1, c2, punta, ancho, grueso, u, segs=segs, lados=6, giro=math.radians(giro))


def _slerp(a, b, s):
    a = a.normalized(); b = b.normalized()
    om = math.acos(max(-1.0, min(1.0, a.dot(b))))
    if om < 1e-5:
        return a.copy()
    return (a * math.sin((1 - s) * om) + b * math.sin(s * om)) / math.sin(om)


def _elip(u, k):
    C = CRANEO["c"]
    return C + Vector((u.x * CRANEO["rx"], u.y * CRANEO["ry"], u.z * CRANEO["rz"])) * k


def mechon_de(pz, t0, f0, t1, f1, ancho, grueso=0.016, k=1.10, levantar=0.10, caer=0.0, segs=9, mas=0.0):
    """Mechón que sale de (t0, f0) y va por encima del cráneo (a la distancia k) hasta (t1, f1); la punta se levanta
    «levantar» (en radios) y cae «caer» metros. «mas» lo alarga siguiendo la misma dirección."""
    u0, u1 = _u(t0, f0), _u(t1, f1)
    pts, nor = [], []
    for i in range(segs + 1):
        s = i / segs * (1.0 + mas)
        u = _slerp(u0, u1, min(s, 1.0))
        if s > 1.0:          # más allá del objetivo: sigue la tangente
            u = (u1 + (u1 - _slerp(u0, u1, 0.9)) * (s - 1.0) * 10).normalized()
        kk = k + levantar * (s ** 2.2) - 0.06 * (1 - s) ** 3
        p = _elip(u, kk) + Vector((0, 0, -caer * s ** 2))
        pts.append(p)
        nor.append(u)
    G.mechon_pts(pz, pts, nor, ancho, grueso, lados=5)


def _pelo_piezas():
    """Pelo de Kael: casquete de volumen y ~60 mechones en capas que salen del remolino (arriba y atrás). Los de la
    corona se levantan hacia fuera (la silueta alborotada que le reconoce), el flequillo cae en picos finos hasta las
    cejas con uno más largo entre los ojos, y la nuca se abre en puntas. Variación con semilla fija (se puede rehacer)."""
    import random
    rnd = random.Random(7)
    pz = G.Pieza("kael_pelo", ["pelo"], [("Head", 1.0)], p=4)
    C = CRANEO["c"]
    def casco(u):
        return Vector((u.x * 1.15, u.y * 1.13 + 0.02, u.z * 1.12 + 0.07))
    _casquete(pz, C, casco)
    R = (22, 178)                     # remolino
    j = lambda a: rnd.uniform(-a, a)
    # flequillo
    for f1 in range(-70, 71, 14):
        t1 = 80 + abs(f1) * 0.10 + j(4)
        mechon_de(pz, 8 + j(3), f1 * 0.35, t1, f1 + j(4), 0.044 + j(0.006), grueso=0.019, k=1.15 + j(0.02),
                  levantar=0.05 + j(0.02), segs=8)
    mechon_de(pz, 14, -10, 97, -6, 0.028, grueso=0.012, k=1.14, levantar=0.03, mas=0.04, segs=8)   # entre los ojos
    # coronilla y corona: dos capas que salen del remolino
    for capa, (kk, lev0, t0) in enumerate(((1.21, 0.26, 60), (1.29, 0.36, 70))):
        paso = 15
        for f1 in range(-180 + capa * 7, 180, paso):
            fr = abs(((f1 + 180) % 360) - 180) / 180.0        # 0 delante, 1 detrás
            t1 = t0 + 12 * fr + j(5)
            lev = (lev0 + 0.22 * fr) * (0.7 if fr < 0.3 else 1.0) + j(0.06)
            mechon_de(pz, R[0] + j(4), R[1] + j(20), t1, f1 + j(5), 0.052 + j(0.008), grueso=0.024, k=kk,
                      levantar=lev, mas=0.08 + j(0.04), segs=8)
    # picos de arriba que se levantan (rompen la silueta redonda y le dan altura)
    for f1 in (-150, -110, -70, -30, 10, 50, 90, 130, 170):
        mechon_de(pz, R[0] - 6 + j(3), R[1] + j(15), 40 + j(5), f1 + j(8), 0.05, grueso=0.024, k=1.30,
                  levantar=0.55 + j(0.1), mas=0.15, segs=8)
    # laterales y nuca
    for sx in (-1, 1):
        mechon_de(pz, 30, sx * 55, 118, sx * 76, 0.040, grueso=0.017, k=1.11, levantar=0.06, mas=0.05)
        mechon_de(pz, 32, sx * 76, 114, sx * 92, 0.050, grueso=0.019, k=1.13, levantar=0.13)
        for f1 in (100, 122, 144, 166):
            mechon_de(pz, 38 + j(4), sx * (f1 - 10), 118 + j(5), sx * f1 + j(5), 0.05 + j(0.006), grueso=0.02,
                      k=1.14, levantar=0.20 + j(0.05), mas=0.08)
    mechon_de(pz, 40, 180, 124, 180, 0.05, grueso=0.02, k=1.14, levantar=0.22, mas=0.08)
    # mechón rebelde de arriba (ahoge)
    raiz = _elip(_u(8, 10), 1.12)
    G.mechon(pz, raiz, raiz + Vector((0.0, -0.01, 0.07)), raiz + Vector((0.0, -0.06, 0.11)),
             raiz + Vector((0.0, -0.10, 0.09)), 0.014, 0.007, Vector((0, 0, 1)), segs=7, lados=5, giro=0.4)
    return pz


def _casquete(pz, C, casco):
    """Casquete de pelo: esfera algo mayor que el cráneo sin la zona de la cara (frente baja, ojos, mejillas)."""
    import bmesh
    tmp = G.Pieza("tmp", ["pelo"], [("Head", 1.0)])
    G.esfera(tmp, C, CRANEO["rx"], CRANEO["ry"], CRANEO["rz"], segs=28, anillos=16, deformar=casco)
    bm = tmp.bm
    quitar = []
    for v in bm.verts:
        u = v.co - C
        x, y, z = u.x / CRANEO["rx"], u.y / CRANEO["ry"], u.z / CRANEO["rz"]
        cara = y < -0.30 and z < 0.62 - 0.25 * abs(x)
        bajo = z < -0.28 and y < 0.55
        if cara or bajo or z < -0.62:
            quitar.append(v)
    bmesh.ops.delete(bm, geom=quitar, context='VERTS')
    # se copia al bmesh de la pieza
    me_tmp = __import__("bpy").data.meshes.new("tmp_casco")
    bm.to_mesh(me_tmp)
    bm.free()
    pz.bm.from_mesh(me_tmp)
    __import__("bpy").data.meshes.remove(me_tmp)
