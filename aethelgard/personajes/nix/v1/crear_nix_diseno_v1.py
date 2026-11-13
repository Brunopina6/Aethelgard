# Nix (V12, cuarta heroína, PROTOTIPO APAGADO): diseño modelado por guion sobre su esqueleto en reposo en T.
#
# Lo usa fuente/crear_nix.py. El esqueleto es el de Lya (el rig común de los héroes v2: mismos nombres, jerarquía y
# orientaciones) con otras PROPORCIONES (crear_nix.py, ajustar_esqueleto): piernas más cortas (×0,78), brazos algo más
# cortos (×0,9) y la cadera más baja. La cabeza es geometría más grande (no cambia el esqueleto): influencia chibi.
#
# Dirección (docs/v12/NIX_V12.md; especificación del usuario: Aethelgard_Nix_Maga_Negra.pdf, págs. 5-6, y la lámina
# de referencia que facilitó el usuario, que NO se calca): sombrero de maga alto y facetado, inclinado atrás, con la
# punta doblada una vez, ala elíptica de dos niveles (ciruela arriba, lavanda debajo) con una muesca de media luna,
# banda de cobre con tres grapas y un broche de disco negro descentrado con una luna; pelo corto ciruela casi negro en
# cuatro masas (flequillo de lado, laterales hasta la mandíbula, nuca despejada) con un mechón plateado; abrigo corto
# ciruela con cuello alto, peto marfil, ribetes de cobre, falda de cuatro paneles con forro lavanda; capa corta hasta
# el codo con un rombo detrás; cinturón de cuero con hebilla de cobre; mangas ajustadas con puños marfil; guantes;
# medias grafito; botines de cuero con vuelta. El bastón (cristal lavanda dentro de un arco de hierro roto) va en el
# hueso «arma_d», rígido.
#
# Ejes (como rig_comun.py tras importar el FBX): el personaje mira a -Y, su derecha es -X y arriba es +Z.
import math, random
from mathutils import Vector, Quaternion, Matrix
import geometria_v3 as G

P = G.P
ADEL, ARR, DER = G.ADEL, G.ARR, G.DER

# ------------------------------------------------------------------ paleta (sRGB) y tipo de material
# Los colores de la especificación (ciruela #3B223F, lavanda #A58ACB, marfil #E9DDC8, cobre #A5744D) con sus luces y
# sombras; el horneado de texturas (crear_nix_texturas.py) añade degradados, grano y oclusión.
COL = {
    "ciruela": (0.231, 0.133, 0.247),
    "ciruela_claro": (0.34, 0.20, 0.36),
    "lavanda": (0.647, 0.541, 0.796),
    "marfil": (0.914, 0.867, 0.784),
    "cobre": (0.647, 0.455, 0.302),
    "piel": (0.98, 0.84, 0.76),
    "pelo": (0.17, 0.10, 0.17),
    "plata": (0.78, 0.78, 0.82),
    "guante": (0.22, 0.13, 0.18),
    "medias": (0.29, 0.27, 0.30),
    "cuero": (0.38, 0.22, 0.14),
    "cuero_claro": (0.50, 0.31, 0.19),
    "cuero_osc": (0.20, 0.12, 0.09),
    "hierro": (0.20, 0.19, 0.21),
    "cristal": (0.70, 0.54, 0.96),
    "negro": (0.05, 0.04, 0.06),
    "asta": (0.20, 0.11, 0.19),
}

# nombre de material -> (color base, tipo para el horneado: tela, piel, cuero, metal, cristal, pelo)
MATERIALES = {
    "piel": ("piel", "piel"),
    "pelo": ("pelo", "pelo"),
    "pelo_plata": ("plata", "pelo"),
    "abrigo": ("ciruela", "tela"),
    "abrigo_claro": ("ciruela_claro", "tela"),
    "forro": ("lavanda", "tela"),
    "lavanda": ("lavanda", "tela"),
    "marfil": ("marfil", "tela"),
    "cobre": ("cobre", "metal"),
    "guante": ("guante", "cuero"),
    "medias": ("medias", "tela"),
    "bota": ("cuero", "cuero"),
    "bota_vuelta": ("cuero_claro", "cuero"),
    "cinturon": ("cuero_osc", "cuero"),
    "sombrero": ("ciruela", "tela"),
    "sombrero_ala": ("ciruela", "tela"),
    "sombrero_ala_baja": ("lavanda", "tela"),
    "hierro": ("hierro", "metal"),
    "cristal": ("cristal", "cristal"),
    "negro": ("negro", "metal"),
    "asta": ("asta", "cuero"),
}


def PALETA_VERTICE():
    """Paleta para el borrador con color por vértice (geometria_v3.colorear)."""
    p = {}
    for n, (c, t) in MATERIALES.items():
        tipo = {"tela": "tela", "piel": "piel", "cuero": "cuero", "metal": "metal", "cristal": "cristal",
                "pelo": "pelo"}[t]
        p[n] = {"color": COL[c], "tipo": tipo}
    return p


# ------------------------------------------------------------------ medidas de la cabeza (se fijan en construir)
CRANEO = {"c": Vector((0.003, -0.045, 1.37)), "rx": 0.190, "ry": 0.178, "rz": 0.196}
CARA = {}


def _u(theta, phi):
    """Dirección desde el centro del cráneo: theta desde arriba (grados), phi alrededor (0 = delante, + = izquierda)."""
    t, p = math.radians(theta), math.radians(phi)
    return Vector((math.sin(t) * math.sin(p), -math.sin(t) * math.cos(p), math.cos(t)))


def _elip(u, k=1.0):
    """Punto sobre la cabeza DEFORMADA (la cara aplanada, la mandíbula estrecha) a k veces su radio."""
    C = CRANEO["c"]
    d = _cabeza_deformar(u.normalized())
    return C + Vector((d.x * CRANEO["rx"], d.y * CRANEO["ry"], d.z * CRANEO["rz"])) * k


def _slerp(a, b, s):
    a = a.normalized(); b = b.normalized()
    om = math.acos(max(-1.0, min(1.0, a.dot(b))))
    if om < 1e-5:
        return a.copy()
    return (a * math.sin((1 - s) * om) + b * math.sin(s * om)) / math.sin(om)


def _cabeza_deformar(u):
    """Cráneo chibi adulto: frente amplia, pómulos suaves, mandíbula que se estrecha a una barbilla pequeña y una
    nariz pequeña modelada (no un punto pintado)."""
    x, y, z = u.x, u.y, u.z
    if z < 0:
        k = G.suave(0.0, -1.0, z)
        x *= 1.0 - 0.40 * k
        y *= 1.0 - 0.20 * k
        if y < 0:
            y -= 0.07 * k * (1.0 - abs(x) * 1.7)
        z *= 0.90
    if y < 0:
        x *= 1.0 - 0.06 * min(1.0, -y * 1.6)
    if y < -0.62:
        y = -0.62 + (y + 0.62) * 0.70
    if y > 0:
        y *= 1.05
        if z < 0.1:                                          # nuca: algo más llena (el pelo la cubre)
            y *= 1.0 + 0.04 * G.suave(0.1, -0.5, z)
    # nariz: un bulto pequeño delante, entre los ojos y la boca
    if y < -0.5:
        dn = math.hypot(x / 0.10, (z + 0.30) / 0.16)
        if dn < 1.0:
            y -= 0.045 * (1.0 - dn) ** 2 * (1.0 if z < -0.30 else 0.7)
    return Vector((x, y, z))


# ------------------------------------------------------------------ construir
def construir(H):
    """Devuelve la lista de piezas (geometria_v3.Pieza) en la pose de reposo, y fija CRANEO y CARA."""
    hd = H.c("Head")
    CRANEO["c"] = Vector((hd.x, hd.y - 0.012, hd.z + 0.150))
    C = CRANEO["c"]
    # la cara (cara_v3.py): medidas en el mundo; ojos almendrados grandes, boca pequeña, cejas finas y legibles
    CARA.clear()
    CARA.update({
        "ojo": {"x": 0.074, "z": C.z - 0.040, "ancho": 0.118, "alto": 0.118},
        "boca": {"x": 0.0, "z": C.z - 0.128, "ancho": 0.048, "alto": 0.040},
        "ceja": {"z": C.z + 0.030, "largo": 0.052, "grueso": 0.0070, "inclinacion": 6.0},
        "marca": None,
        "iris": ((0.30, 0.10, 0.48), (0.78, 0.55, 0.98)),         # amatista: oscuro arriba, claro abajo
        "linea": (0.16, 0.08, 0.14),
        "ceja_color": (0.22, 0.12, 0.20),
        "mirada": "almendra",
        "centro_x": C.x,
    })
    piezas = []
    piezas += _cabeza(H)
    piezas += _torso(H)
    piezas += _falda(H)
    piezas += _capa(H)
    piezas += _brazos(H)
    piezas += _piernas(H)
    piezas += _pelo()
    piezas.append(_sombrero(H))
    return piezas


# ------------------------------------------------------------------ cabeza y cuello
def _cabeza(H):
    C = CRANEO["c"]
    cab = G.Pieza("nix_cabeza", ["piel"], [("Head", 1.0)])
    G.esfera(cab, C, CRANEO["rx"], CRANEO["ry"], CRANEO["rz"], segs=24, anillos=18, deformar=_cabeza_deformar)
    # orejas pequeñas (casi tapadas por el pelo)
    for sx in (-1, 1):
        G.esfera(cab, C + Vector((sx * 0.178, 0.010, -0.050)), 0.016, 0.012, 0.026, segs=6, anillos=5)
    n0, n1 = H.c("Neck"), H.c("Head")
    cue = G.Pieza("nix_cuello", ["piel"], [("Neck", 1.0), ("Head", 0.6), ("Spine2", 0.4)], p=3)
    G.tubo(cue, [(n0 + Vector((0, 0.002, -0.03)), ADEL, 0.036, 0.040), (n0.lerp(n1, 0.6), ADEL, 0.030, 0.033),
                 (n1 + Vector((0, 0.006, 0.06)), ADEL, 0.032, 0.035)], segs=12)
    return [cab, cue]


# ------------------------------------------------------------------ torso: abrigo corto con cuello alto y peto marfil
def _angs_peto(n_lado=7):
    """Ángulos de un tubo con el peto delante (marfil, ±0,42 rad), un ribete de cobre a cada lado y el resto del
    abrigo. Devuelve (ángulos, función ángulo -> material)."""
    a = []
    # delante: peto
    for k in range(-3, 4):
        a.append(k * 0.14)
    for s in (1, -1):
        a.append(s * 0.47)
        a.append(s * 0.53)
    # alrededor
    for k in range(1, 12):
        a.append(0.53 + k * (math.pi * 2 - 1.06) / 12)
    a = sorted(set(round(x % (2 * math.pi), 5) for x in a))
    return a


def _mat_peto(a0, a1, peto, ribete, resto):
    m = ((a0 + a1) * 0.5)
    if a1 < a0:
        m = ((a0 + a1 + 2 * math.pi) * 0.5) % (2 * math.pi)
    d = min(m, 2 * math.pi - m)                # distancia angular al frente
    if d < 0.47:
        return peto
    if d < 0.53:
        return ribete
    return resto


def _torso(H):
    hip, sp, sp1, sp2, nk = H.c("Hips"), H.c("Spine"), H.c("Spine1"), H.c("Spine2"), H.c("Neck")
    piezas = []
    tor = G.Pieza("nix_torso", ["abrigo", "marfil", "cobre"],
                  [("Hips", 1.0), ("Spine", 1.0), ("Spine1", 1.0), ("Spine2", 1.0), ("Neck", 0.3),
                   ("LeftShoulder", 0.5), ("RightShoulder", 0.5)], p=3)
    angs = _angs_peto()
    z0 = hip.z
    # (z relativo a la cadera, ancho, fondo, delante, detrás): cintura estrecha, pecho suave adulto (sin exagerar)
    perfil = [(-0.02, 0.080, 0.070, 1.0, 1.0), (0.06, 0.074, 0.064, 1.0, 1.0), (0.12, 0.068, 0.060, 1.02, 1.0),
              (0.18, 0.076, 0.066, 1.12, 1.0), (0.225, 0.086, 0.070, 1.16, 1.0), (0.255, 0.098, 0.066, 1.06, 1.0),
              (0.278, 0.082, 0.056, 1.0, 1.0)]
    an = []
    for dz, rx, ry, fa, fe in perfil:
        z = z0 + dz
        y = hip.y + (sp2.y - hip.y) * max(0.0, min(1.0, dz / 0.25)) * 0.6
        an.append({"c": Vector((hip.x, y, z)), "f": ADEL, "rx": ry, "ry": rx, "fa": fa, "fe": fe})
    nj = len(angs)
    G.tubo(tor, an, angulos=angs, tapa0=True, tapa1=True, abombar=0.25,
           mat=lambda i, j: _mat_peto(angs[j], angs[(j + 1) % nj], 1, 2, 0))
    # costura central del peto (dos botones de cobre) y el broche del cuello
    for dz in (0.12, 0.185):
        G.esfera(tor, Vector((hip.x, hip.y - 0.072 - 0.010 * (dz > 0.15), z0 + dz)), 0.008, 0.005, 0.008, segs=8,
                 anillos=5, mat=2)
    piezas.append(tor)
    # cuello alto (abierto delante en V) con ribete de cobre arriba
    cu = G.Pieza("nix_cuello_alto", ["abrigo", "cobre", "forro"],
                 [("Neck", 1.0), ("Spine2", 0.8)], p=3, grosor=0.004, interior="forro")
    zc = nk.z - 0.015
    angs_c = [math.radians(a) for a in range(24, 337, 24)]
    anc = [(Vector((nk.x, nk.y + 0.004, zc)), ADEL, 0.052, 0.056), (Vector((nk.x, nk.y + 0.006, zc + 0.045)), ADEL, 0.048, 0.052),
           (Vector((nk.x, nk.y + 0.010, zc + 0.080)), ADEL, 0.052, 0.056)]
    G.tubo(cu, anc, angulos=angs_c, cerrado=False, mat=lambda i, j: 1 if i == 1 else 0)
    piezas.append(cu)
    # broche del cuello: rombo de cobre
    br = G.Pieza("nix_broche_cuello", ["cobre", "lavanda"], [("Neck", 0.6), ("Spine2", 1.0)], p=3)
    G.gema(br, Vector((nk.x, nk.y - 0.058, zc + 0.004)), ARR, ADEL, 0.016, 0.034, mat=0)
    G.gema(br, Vector((nk.x, nk.y - 0.066, zc + 0.004)), ARR, ADEL, 0.008, 0.018, mat=1)
    piezas.append(br)
    # cinturón de cuero con hebilla cuadrada de cobre
    ci = G.Pieza("nix_cinturon", ["cinturon", "cobre"], [("Hips", 1.0), ("Spine", 0.5)], p=3)
    zb = z0 + 0.035
    G.tubo(ci, [(Vector((hip.x, hip.y, zb - 0.017)), ADEL, 0.076, 0.087), (Vector((hip.x, hip.y, zb + 0.017)), ADEL, 0.074, 0.085)],
           segs=20)
    hb = Vector((hip.x, hip.y - 0.080, zb))
    for (dx, dz, sx, sz) in ((0, 0.019, 0.024, 0.0045), (0, -0.019, 0.024, 0.0045), (0.020, 0, 0.0045, 0.021),
                             (-0.020, 0, 0.0045, 0.021)):
        G.caja(ci, hb + Vector((dx, 0, dz)), (DER, ADEL, ARR), (sx, 0.005, sz), mat=1)
    G.caja(ci, hb + Vector((0, -0.002, 0)), (DER, ADEL, ARR), (0.0025, 0.004, 0.018), mat=1)    # el pasador
    piezas.append(ci)
    return piezas


# ------------------------------------------------------------------ falda del abrigo: cuatro paneles y el peto en punta
def _falda(H):
    hip = H.c("Hips")
    piezas = []
    z0 = hip.z + 0.02
    largo = 0.30
    # paneles: (centro del panel en grados, mitad del ancho en grados); 0 = delante. Delante quedan dos paneles que
    # dejan ver la punta del peto; los costados se abren un poco (aberturas).
    paneles = [(52, 44), (-52, 44), (140, 44), (-140, 44)]
    huesos = [("Hips", 1.3), ("LeftUpLeg", 0.55), ("RightUpLeg", 0.55), ("Bone_008", 0.6), ("Bone_007", 0.5)]
    for k, (cen, mitad) in enumerate(paneles):
        pz = G.Pieza("nix_falda_%d" % k, ["abrigo", "cobre", "lavanda"], huesos, p=2.6, grosor=0.005,
                     interior="forro")
        bm = pz.bm
        na = 8
        nr = 6
        filas = []
        for i in range(nr + 1):
            s = i / nr
            fila = []
            for j in range(na + 1):
                t = j / na
                a = math.radians(cen - mitad + 2 * mitad * t)
                # bajo en punta suave en el centro del panel (como en la referencia, sin calcarla)
                punta = 1.0 - abs(t - 0.5) * 2
                z = z0 - (largo + 0.05 * punta ** 1.6) * s
                if abs(cen) > 90:
                    z -= 0.03 * s                      # detrás, algo más largo
                rx = 0.090 + 0.13 * s ** 0.85
                ry = 0.080 + 0.11 * s ** 0.85
                onda = 1.0 + 0.045 * math.sin(t * math.pi * 3) * s       # pliegues suaves del vuelo
                p = Vector((hip.x + math.sin(a) * rx * onda, hip.y + 0.008 - math.cos(a) * ry * onda, z))
                fila.append(bm.verts.new(p))
            filas.append(fila)
        G._uv_filas(pz, filas, [Vector((hip.x, hip.y, z0 - largo * i / nr)) for i in range(nr + 1)], cerrado=False)
        for i in range(nr):
            for j in range(na):
                f = bm.faces.new((filas[i][j], filas[i + 1][j], filas[i + 1][j + 1], filas[i][j + 1]))
                # ribete de cobre en el bajo; franja lavanda junto al borde delantero de los paneles de delante
                if i == nr - 1:
                    f.material_index = 1
                elif abs(cen) < 90 and ((cen > 0 and j == 0) or (cen < 0 and j == na - 1)):
                    f.material_index = 2
                else:
                    f.material_index = 0
        piezas.append(pz)
    # el peto marfil sigue por debajo del cinturón hasta una punta, entre los dos paneles delanteros
    pe = G.Pieza("nix_peto_bajo", ["marfil", "cobre"], [("Hips", 1.3), ("LeftUpLeg", 0.4), ("RightUpLeg", 0.4)], p=2.6,
                 grosor=0.004, interior="marfil")
    bm = pe.bm
    filas = []
    nr = 6
    for i in range(nr + 1):
        s = i / nr
        ancho = 0.075 * (1.0 - s ** 1.8 * 0.92)
        z = z0 + 0.01 - 0.27 * s
        fila = []
        for j in range(5):
            t = j / 4 - 0.5
            a = t * 2 * ancho / 0.10
            r = 0.088 + 0.10 * s ** 0.9
            fila.append(bm.verts.new(Vector((hip.x + math.sin(a) * r * 0.95, hip.y - 0.002 - math.cos(a) * r * 0.92, z))))
        filas.append(fila)
    G._uv_filas(pe, filas, [Vector((hip.x, hip.y, z0 - 0.27 * i / nr)) for i in range(nr + 1)], cerrado=False)
    for i in range(nr):
        for j in range(4):
            f = bm.faces.new((filas[i][j], filas[i + 1][j], filas[i + 1][j + 1], filas[i][j + 1]))
            f.material_index = 1 if (j in (0, 3) or i == nr - 1) else 0
    piezas.append(pe)
    return piezas


# ------------------------------------------------------------------ capa corta (hasta el codo) con el rombo detrás
def _capa(H):
    sp2, nk = H.c("Spine2"), H.c("Neck")
    ls, rs = H.c("LeftArm"), H.c("RightArm")
    pz = G.Pieza("nix_capa", ["abrigo", "cobre", "lavanda"],
                 [("Spine2", 1.2), ("Neck", 0.35), ("LeftShoulder", 1.0), ("RightShoulder", 1.0), ("LeftArm", 0.40),
                  ("RightArm", 0.40), ("Spine1", 0.5)], p=3.0, grosor=0.006, interior="forro")
    bm = pz.bm
    # anillos desde el cuello hacia fuera y abajo; delante queda abierta (hueco de 2×20°). En la pose en T la capa
    # pasa POR ENCIMA de los brazos (casi horizontal sobre ellos) y cae delante y detrás; con los brazos bajados
    # (pesos de la parte de fuera en los brazos) cae sobre ellos hasta el codo.
    na = 22
    hueco = math.radians(20)
    angs = [hueco + (2 * math.pi - 2 * hueco) * j / (na - 1) for j in range(na)]
    nr = 7
    zc = nk.z - 0.012

    def brazo_arriba(x):
        """Altura de la parte de arriba de la manga a la distancia x del centro (en T)."""
        lado = "Left" if x > 0 else "Right"
        a0, a1 = H.c(lado + "Arm"), H.c(lado + "ForeArm")
        t = max(0.0, min(1.0, (abs(x) - abs(a0.x)) / max(1e-4, abs(a1.x) - abs(a0.x))))
        return a0.z + (a1.z - a0.z) * t + 0.050 - 0.010 * t

    filas = []
    for i in range(nr + 1):
        s = i / nr
        fila = []
        for a in angs:
            ca, sa = math.cos(a), math.sin(a)          # ca = delante, sa = izquierda
            lateral = abs(sa) ** 1.5
            r_lat = 0.064 + 0.230 * s ** 0.95
            r_fb = 0.060 + 0.105 * s ** 0.9
            x = sa * (r_lat * lateral + r_fb * (1 - lateral))
            y = -ca * (r_fb + 0.010 * s) * (1.10 if ca < 0 else 1.0)
            z_fb = zc - (0.13 if ca > 0 else 0.15) * s ** 1.15
            z_lat = max(zc - 0.03 * s, brazo_arriba(x) + 0.018) if abs(x) > 0.07 else zc - 0.01 * s
            z = z_lat * lateral + z_fb * (1 - lateral)
            fila.append(bm.verts.new(Vector((sp2.x + x, sp2.y + 0.006 + y, z))))
        filas.append(fila)
    G._uv_filas(pz, filas, [Vector((sp2.x, sp2.y, zc - 0.1 * i / nr)) for i in range(nr + 1)], cerrado=False)
    for i in range(nr):
        for j in range(na - 1):
            f = bm.faces.new((filas[i][j], filas[i][j + 1], filas[i + 1][j + 1], filas[i + 1][j]))
            borde = i == nr - 1 or j == 0 or j == na - 2
            f.material_index = 1 if borde else 0
    piezas = [pz]
    # rombo de cobre con el centro lavanda en la espalda (sobre el bajo de la capa)
    ro = G.Pieza("nix_capa_rombo", ["cobre", "lavanda"], [("Spine2", 1.0), ("Spine1", 0.6)], p=3)
    j_atras = na // 2
    pb = filas[nr - 1][j_atras].co.copy()
    pb.y += 0.010
    G.gema(ro, pb + Vector((0, 0.002, 0.01)), ARR, -ADEL, 0.022, 0.050, mat=0)
    G.gema(ro, pb + Vector((0, 0.010, 0.01)), ARR, -ADEL, 0.011, 0.028, mat=1)
    piezas.append(ro)
    return piezas


# ------------------------------------------------------------------ brazos: manga ajustada, puño marfil, guante
def _brazos(H):
    piezas = []
    for lado, sx in (("Left", 1), ("Right", -1)):
        sh, ar, fa, hd = H.c(lado + "Shoulder"), H.c(lado + "Arm"), H.c(lado + "ForeArm"), H.c(lado + "Hand")
        fuera = Vector((sx, 0, 0))
        mg = G.Pieza("nix_manga_" + lado, ["abrigo"],
                     [(lado + "Shoulder", 0.6), (lado + "Arm", 1.0), (lado + "ForeArm", 1.0), (lado + "Hand", 0.3)], p=4)
        pts = [ar - fuera * 0.05, ar, ar.lerp(fa, 0.5), fa, fa.lerp(hd, 0.55)]
        rad = [(0.050, 0.052), (0.043, 0.045), (0.036, 0.037), (0.031, 0.032), (0.028, 0.029)]
        G.tubo(mg, G.cadena(pts, ARR, rad, 2), segs=12)
        piezas.append(mg)
        # puño marfil acampanado con ribete de cobre en los dos bordes
        pu = G.Pieza("nix_puno_" + lado, ["marfil", "cobre"],
                     [(lado + "ForeArm", 1.0), (lado + "Hand", 0.35)], p=4, grosor=0.004, interior="marfil")
        c0 = fa.lerp(hd, 0.42)
        c1 = fa.lerp(hd, 0.98)
        an = [(c0, ARR, 0.035, 0.036), (c0.lerp(c1, 0.12), ARR, 0.037, 0.038), (c0.lerp(c1, 0.5), ARR, 0.041, 0.042),
              (c0.lerp(c1, 0.88), ARR, 0.046, 0.047), (c1, ARR, 0.047, 0.048)]
        G.tubo(pu, an, segs=12, mat=lambda i, j: 1 if i in (0, 3) else 0)
        piezas.append(pu)
        piezas.append(_mano(H, lado, sx))
    return piezas


def _mano(H, lado, sx):
    """Guante: palma, cuatro dedos (con los pesos del corazón, el único dedo largo de este esqueleto) y el pulgar."""
    hd = H.c(lado + "Hand")
    nud = H.c(lado + "HandMiddle1")
    eje = (nud - hd).normalized()
    m = G.Pieza("nix_mano_" + lado, ["guante"],
                [(lado + "Hand", 1.0)] + [(lado + "Hand" + d + str(i), 1.0) for d in ("Thumb", "Middle") for i in (1, 2, 3)],
                p=5)
    abajo = Vector((0, 0, -1))
    # algo grandes (chibi): la palma 1,15 veces la de Lya
    k = 1.15
    pal = [(hd - eje * 0.030, abajo, 0.024 * k, 0.025 * k), (hd - eje * 0.006, abajo, 0.019 * k, 0.024 * k),
           (hd.lerp(nud, 0.45), abajo, 0.018 * k, 0.030 * k), (nud - eje * 0.006, abajo, 0.016 * k, 0.033 * k),
           (nud + eje * 0.006, abajo, 0.012 * k, 0.030 * k)]
    G.tubo(m, pal, segs=10, tapa1=True, abombar=0.3)
    med = [H.c(lado + "HandMiddle" + str(i)) for i in (1, 2, 3, 4)] + [H.k(lado + "HandMiddle4")]
    lat = Vector((0, -1, 0))
    for off, r, kk in ((0.019, 0.0083, 0.90), (0.0, 0.0090, 1.0), (-0.018, 0.0083, 0.92), (-0.033, 0.0072, 0.76)):
        pts = [nud - eje * 0.004 + lat * off * k]
        for q in med[1:]:
            pts.append(nud + (q - nud) * kk * 1.08 + lat * off * k)
        ra = [(r, r), (r, r), (r * 0.94, r * 0.94), (r * 0.86, r * 0.86), (r * 0.72, r * 0.72)]
        G.tubo(m, G.cadena(pts, abajo, ra, 1), segs=6, tapa1=True, abombar=0.6)
    th = [H.c(lado + "HandThumb" + str(i)) for i in (1, 2, 3, 4)] + [H.k(lado + "HandThumb4")]
    th = [th[0] - eje * 0.006] + [th[0] + (q - th[0]) * 1.12 for q in th[1:]]
    G.tubo(m, G.cadena(th, abajo, [(0.0098, 0.0098)] * 3 + [(0.0086, 0.0086), (0.007, 0.007)], 1), segs=6, tapa1=True,
           abombar=0.6)
    return m


# ------------------------------------------------------------------ piernas: medias y botines con vuelta
def _piernas(H):
    piezas = []
    for lado, sx in (("Left", 1), ("Right", -1)):
        ul, lg, ft, tb = H.c(lado + "UpLeg"), H.c(lado + "Leg"), H.c(lado + "Foot"), H.c(lado + "ToeBase")
        pi = G.Pieza("nix_pierna_" + lado, ["medias"], [("Hips", 0.5), (lado + "UpLeg", 1.0), (lado + "Leg", 1.0),
                                                         (lado + "Foot", 0.3)], p=4)
        pts = [ul + Vector((-sx * 0.02, 0, 0.04)), ul, ul.lerp(lg, 0.5), lg, lg.lerp(ft, 0.45), ft + Vector((0, 0, 0.03))]
        rad = [(0.074, 0.072), (0.076, 0.074), (0.064, 0.062), (0.050, 0.052), (0.050, 0.054), (0.036, 0.038)]
        G.tubo(pi, G.cadena(pts, ADEL, rad, 2), segs=12)
        piezas.append(pi)
        bo = G.Pieza("nix_bota_" + lado, ["bota", "bota_vuelta", "cinturon", "cobre"],
                     [(lado + "Leg", 0.8), (lado + "Foot", 1.4), (lado + "ToeBase", 1.0)], p=5)
        dirp = Vector((tb.x - ft.x, tb.y - ft.y, 0)).normalized()
        tob = Vector((ft.x, ft.y, ft.z))
        # caña hasta media espinilla
        caña = [(Vector((tob.x, tob.y + 0.004, 0.035)), ADEL, 0.047, 0.056),
                (Vector((tob.x, tob.y + 0.004, tob.z)), ADEL, 0.041, 0.045),
                (lg.lerp(ft, 0.70), ADEL, 0.055, 0.058),
                (lg.lerp(ft, 0.48), ADEL, 0.060, 0.062)]
        G.tubo(bo, caña, segs=12)
        # pie: del talón a la punta redonda (botín robusto: pies estables)
        talon = Vector((ft.x, ft.y + 0.018, 0.0))
        punta = Vector((tb.x, tb.y, 0.0)) + dirp * 0.060
        an = [(talon + Vector((0, 0.020, 0.050)), ADEL, 0.044, 0.046),
              (talon.lerp(punta, 0.30) + Vector((0, 0, 0.052)), ADEL, 0.047, 0.044),
              (talon.lerp(punta, 0.62) + Vector((0, 0, 0.040)), ADEL, 0.045, 0.036),
              (talon.lerp(punta, 0.88) + Vector((0, 0, 0.030)), ADEL, 0.038, 0.028),
              (punta + Vector((0, 0, 0.026)), ADEL, 0.026, 0.020)]
        an = [{"c": a[0], "f": ARR, "rx": a[3], "ry": a[2]} for a in an]
        G.tubo(bo, an, segs=12, tapa0=True, tapa1=True, abombar=0.6)
        # suela y tacón bajo
        G.caja(bo, talon + Vector((0, 0.012, 0.012)), (DER, ADEL, ARR), (0.036, 0.030, 0.012), mat=2)
        G.tubo(bo, [{"c": talon.lerp(punta, 0.35) + Vector((0, 0, 0.006)), "f": ARR, "rx": 0.006, "ry": 0.046},
                    {"c": talon.lerp(punta, 0.95) + Vector((0, 0, 0.006)), "f": ARR, "rx": 0.006, "ry": 0.034}],
               segs=8, tapa0=True, tapa1=True, mat=lambda i, j: 2)
        # vuelta ancha (cuero más claro) arriba de la caña, abierta un poco hacia fuera
        cv = lg.lerp(ft, 0.48)
        vu = [(cv + Vector((0, 0, -0.012)), ADEL, 0.063, 0.065), (cv + Vector((0, 0, 0.022)), ADEL, 0.069, 0.071),
              (cv + Vector((0, 0, 0.050)), ADEL, 0.072, 0.074)]
        G.tubo(bo, vu, segs=14, tapa0=False, mat=lambda i, j: 1)
        # correa con hebilla de cobre en el empeine
        G.tubo(bo, [{"c": talon.lerp(punta, 0.36) + Vector((0, 0, 0.052)), "f": ARR, "rx": 0.049, "ry": 0.049},
                    {"c": talon.lerp(punta, 0.44) + Vector((0, 0, 0.050)), "f": ARR, "rx": 0.048, "ry": 0.048}],
               segs=12, mat=lambda i, j: 2)
        hb = talon.lerp(punta, 0.40) + Vector((sx * 0.048, 0, 0.042))
        G.caja(bo, hb, (Vector((sx, 0, 0)), ADEL, ARR), (0.004, 0.010, 0.010), mat=3)
        piezas.append(bo)
    return piezas


# ------------------------------------------------------------------ pelo: bob en cuatro masas y el mechón plateado
def _mechon(pz, t0, f0, t1, f1, ancho, grueso, k=1.08, levantar=0.08, segs=8, mas=0.0, mat=0, curvar=0.0,
            perfil=None, lados=6):
    u0, u1 = _u(t0, f0), _u(t1, f1)
    pts, nor = [], []
    for i in range(segs + 1):
        s = i / segs * (1.0 + mas)
        u = _slerp(u0, u1, min(s, 1.0))
        if s > 1.0:
            u = (u1 + (u1 - _slerp(u0, u1, 0.9)) * (s - 1.0) * 10).normalized()
        kk = k + levantar * (s ** 2.2) - 0.05 * (1 - s) ** 3
        th = math.degrees(math.acos(max(-1.0, min(1.0, u.z))))
        ph = math.degrees(math.atan2(u.x, -u.y))
        p = _casco_punto(th, ph, kk, CRANEO["c"])
        if curvar:
            # las puntas se recogen hacia dentro (bob)
            p += Vector((-u.x, -u.y, 0)).normalized() * curvar * max(0.0, s - 0.6) ** 2 * 2.5 if (u.x or u.y) else Vector()
        pts.append(p)
        nor.append(u)
    G.mechon_pts(pz, pts, nor, ancho, grueso, lados=lados, mat=mat, perfil=perfil)


def _bob(pz, f, t1, ancho, grueso, rnd, mat=0, recoger=0.025, mas=0.0):
    """Masa del bob que baja por el lateral o la nuca desde la coronilla hasta la línea de la mandíbula."""
    j = lambda a: rnd.uniform(-a, a)
    _mechon(pz, 18 + j(3), f * 0.6 + j(4), t1 + j(3), f + j(3), ancho + j(0.004), grueso, k=1.10, levantar=0.10,
            segs=9, mat=mat, curvar=recoger, mas=mas,
            perfil=lambda s: (0.55 + 0.45 * math.sin(min(1.0, s / 0.3) * math.pi / 2)) * (1.0 - max(0.0, s - 0.72) / 0.28) ** 0.7)


def _theta_bajo(phi):
    """Dónde acaba el pelo en cada columna (grados desde arriba): delante, en el nacimiento (lo tapa el flequillo);
    a los lados, hasta la línea de la mandíbula; detrás, algo más arriba (nuca despejada)."""
    a = abs(((phi + 180) % 360) - 180)
    if a < 50:
        return 72.0
    if a < 78:
        t = G.suave(50, 78, a)
        return 72.0 + (140.0 - 72.0) * t
    if a < 120:
        return 140.0
    return 140.0 + (124.0 - 140.0) * G.suave(120, 180, a)


def _casco_punto(theta, phi, k, C):
    """Punto de la melena: sobre el cráneo hasta el ecuador y, por debajo, cae casi recta y se abre un poco (bob)."""
    if theta <= 90:
        return _elip(_u(theta, phi), k)
    p90 = _elip(_u(90, phi), k)
    hz = Vector((p90.x - C.x, p90.y - C.y, 0))
    t = (theta - 90) / 50.0
    abre = 1.0 + 0.16 * t ** 1.2
    z = C.z + CRANEO["rz"] * k * math.cos(math.radians(theta)) * 0.95
    return Vector((C.x + hz.x * abre, C.y + hz.y * abre, z))


def _pelo():
    rnd = random.Random(23)
    j = lambda a: rnd.uniform(-a, a)
    C = CRANEO["c"]
    pz = G.Pieza("nix_pelo", ["pelo", "pelo_plata"], [("Head", 1.0)], p=3.0, grosor=0.012, interior="pelo")
    pm = G.Pieza("nix_pelo_mechones", ["pelo", "pelo_plata"], [("Head", 1.0)], p=3.0)
    bm = pz.bm
    # 1) la melena: una sola masa con volumen (casquete que cae en campana), con el bajo en ondas (cada onda, un
    #    mechón) que se recoge hacia dentro; la cara queda libre
    ncol = 34
    nfil = 9
    mechones = 9                                      # ondas del bajo alrededor de la cabeza
    filas = []
    for i in range(nfil + 1):
        s = i / nfil
        fila = []
        for jj in range(ncol):
            phi = -180 + 360 * jj / ncol
            tb = _theta_bajo(phi)
            ond = math.cos(math.radians(phi) * mechones)
            tb_o = tb + (3.5 * ond if tb > 100 else 0.0)
            th = 6 + (tb_o - 6) * s
            k = 1.085 + 0.09 * s ** 1.6 + 0.025 * ond * s ** 2.5
            if i == nfil:                              # la punta se recoge hacia dentro (bob)
                k -= 0.035
            fila.append(bm.verts.new(_casco_punto(th, phi, k, C)))
        filas.append(fila)
    polo = bm.verts.new(_elip(_u(0, 0), 1.075))
    G._uv_filas(pz, filas, [_casco_punto(6 + 120 * i / nfil, 90, 1.1, C) for i in range(nfil + 1)], cerrado=True)
    pz.uv(polo, 0.0, 0.0)
    for i in range(nfil):
        for jj in range(ncol):
            j2 = (jj + 1) % ncol
            f = bm.faces.new((filas[i][jj], filas[i][j2], filas[i + 1][j2], filas[i + 1][jj]))
            f.material_index = 0
    for jj in range(ncol):
        f = bm.faces.new((polo, filas[0][(jj + 1) % ncol], filas[0][jj]))
        f.material_index = 0

    # 2) flequillo de lado: de la raya (a la derecha del personaje, phi < 0) barre hacia su izquierda; masas anchas que
    #    se superponen y acaban en punta redondeada sobre la ceja
    perfil_fleq = lambda s: (0.70 + 0.30 * math.sin(min(1.0, s / 0.35) * math.pi / 2)) * (1.0 - max(0.0, s - 0.62) / 0.38) ** 0.55
    for (f0, f1, t1, an, gr) in ((-46, -24, 90, 0.090, 0.024), (-34, 8, 86, 0.120, 0.028), (-20, 42, 94, 0.115, 0.028)):
        _mechon(pm, 14 + j(2), f0, t1 + j(1.5), f1 + j(2), an, gr, k=1.10, levantar=0.05, segs=9, perfil=perfil_fleq,
                lados=7)
    # 3) mechones de la cara: uno a cada lado, por delante de la oreja hasta la mandíbula
    perfil_lado = lambda s: (0.75 + 0.25 * math.sin(min(1.0, s / 0.3) * math.pi / 2)) * (1.0 - max(0.0, s - 0.7) / 0.3) ** 0.6
    _mechon(pm, 40, -66, 130, -72, 0.055, 0.022, k=1.11, levantar=0.04, segs=9, perfil=perfil_lado, lados=8, curvar=0.02)
    # el mechón PLATEADO: al lado izquierdo de la cara (a la derecha de la imagen de frente), de la raya a la mandíbula
    _mechon(pm, 22, 34, 128, 60, 0.036, 0.020, k=1.13, levantar=0.04, segs=11, mat=1, perfil=perfil_lado, lados=8,
            curvar=0.02)
    return [pz, pm]


# ------------------------------------------------------------------ sombrero (rígido, ligado a la cabeza)
def _sombrero(H):
    C = CRANEO["c"]
    pz = G.Pieza("nix_sombrero", ["sombrero", "sombrero_ala", "sombrero_ala_baja", "cobre", "negro"], [("Head", 1.0)], p=3)
    bm = pz.bm
    # base del sombrero: elipse que asienta sobre el pelo, inclinada hacia atrás (la cara queda a la vista)
    incl = math.radians(13)
    base_c = C + Vector((0, 0.022, 0.100))
    rot = Matrix.Rotation(-incl, 3, 'X')                  # hacia atrás (la copa se inclina a +Y)
    rb_x, rb_y = 0.212, 0.198

    def P(v):                                              # del marco del sombrero al mundo
        return base_c + rot @ v

    # --- copa: cono facetado (9 caras), alto, con la punta doblada una vez
    nf = 9
    anillos = [(0.000, 1.00), (0.019, 0.96), (0.064, 0.80), (0.129, 0.60), (0.206, 0.40), (0.283, 0.26), (0.360, 0.17)]

    def kcopa(h):
        for (h0, k0), (h1, k1) in zip(anillos[:-1], anillos[1:]):
            if h <= h1:
                return k0 + (k1 - k0) * (h - h0) / (h1 - h0)
        return anillos[-1][1]

    filas = []
    for (h, k) in anillos:
        fila = []
        for jj in range(nf):
            a = 2 * math.pi * (jj + 0.5) / nf
            fila.append(bm.verts.new(P(Vector((math.sin(a) * rb_x * k, -math.cos(a) * rb_y * k, h)))))
        filas.append(fila)
    # punta doblada: dos anillos más que se van hacia atrás y a la derecha del personaje, y el vértice
    dob = Vector((-0.07, 0.12, 0.0))
    for (h, k, s) in ((0.41, 0.12, 0.45), (0.45, 0.07, 0.85)):
        fila = []
        cc = Vector((0, 0, h)) + dob * s - Vector((0, 0, 0.05 * s * s))
        for jj in range(nf):
            a = 2 * math.pi * (jj + 0.5) / nf
            fila.append(bm.verts.new(P(cc + Vector((math.sin(a) * rb_x * k, -math.cos(a) * rb_y * k, 0)))))
        filas.append(fila)
    tip = bm.verts.new(P(Vector((0, 0, 0.42)) + dob * 1.35 - Vector((0, 0, 0.10))))
    for fila in filas:
        for v in fila:
            pz.uv(v, 0.0, 0.0)
    pz.uv(tip, 0.0, 0.0)
    for i in range(len(filas) - 1):
        for jj in range(nf):
            j2 = (jj + 1) % nf
            f = bm.faces.new((filas[i][jj], filas[i][j2], filas[i + 1][j2], filas[i + 1][jj]))
            f.material_index = 0
    for jj in range(nf):
        f = bm.faces.new((filas[-1][jj], filas[-1][(jj + 1) % nf], tip))
        f.material_index = 0
    # --- banda de cobre (pegada a la copa, 4 mm por fuera) con tres grapas y el broche descentrado
    hb0, hb1 = 0.020, 0.070
    banda = []
    for h in (hb0, hb1):
        k = kcopa(h)
        fila = []
        for jj in range(nf):
            a = 2 * math.pi * (jj + 0.5) / nf
            fila.append(bm.verts.new(P(Vector((math.sin(a) * (rb_x * k + 0.005), -math.cos(a) * (rb_y * k + 0.005), h)))))
            pz.uv(fila[-1], 0.0, 0.0)
        banda.append(fila)
    for jj in range(nf):
        j2 = (jj + 1) % nf
        f = bm.faces.new((banda[0][jj], banda[0][j2], banda[1][j2], banda[1][jj]))
        f.material_index = 3
    hc = (hb0 + hb1) * 0.5
    kc = kcopa(hc)
    # grapas: dos barras verticales unidas por una horizontal, en tres sitios (delante-derecha, izquierda y detrás)
    for ang in (-62, 100, 200):
        a = math.radians(ang)
        cpos = P(Vector((math.sin(a) * (rb_x * kc + 0.010), -math.cos(a) * (rb_y * kc + 0.010), hc)))
        tg = rot @ Vector((math.cos(a), math.sin(a), 0))
        nrm = rot @ Vector((math.sin(a), -math.cos(a), 0))
        up = rot @ Vector((0, 0, 1))
        for d in (-0.009, 0.009):
            G.caja(pz, cpos + tg * d, (tg, nrm, up), (0.0032, 0.0045, 0.028), mat=3)
        G.caja(pz, cpos + nrm * 0.003, (tg, nrm, up), (0.014, 0.0035, 0.0032), mat=3)
    # broche: disco negro con aro de cobre y una luna creciente de cobre, descentrado (delante, a la izquierda)
    a = math.radians(30)
    cpos = P(Vector((math.sin(a) * (rb_x * kc + 0.006), -math.cos(a) * (rb_y * kc + 0.006), hc + 0.004)))
    nrm = (rot @ Vector((math.sin(a), -math.cos(a), 0.22))).normalized()
    _disco(pz, cpos + nrm * 0.006, nrm, rot @ Vector((0, 0, 1)), 0.036, 0.010, mat=4, mat_aro=3)
    _luna(pz, cpos + nrm * 0.0125, nrm, rot @ Vector((0, 0, 1)), 0.024, mat=3)
    # --- ala elíptica de dos niveles: arriba ciruela, debajo (y asomando por el borde) lavanda; muesca de media luna
    _ala(pz, P, rot, rb_x, rb_y)
    return pz


def _disco(pz, c, nrm, arriba, r, grosor, mat=0, mat_aro=0, lados=18):
    bm = pz.bm
    t, n, b = G.marco(nrm, arriba)
    del_, det = [], []
    aro_d, aro_t = [], []
    for jj in range(lados):
        a = 2 * math.pi * jj / lados
        d = n * math.cos(a) + b * math.sin(a)
        del_.append(bm.verts.new(c + d * r * 0.86 + t * grosor * 0.5))
        aro_d.append(bm.verts.new(c + d * r + t * grosor * 0.35))
        det.append(bm.verts.new(c + d * r - t * grosor * 0.5))
    for v in del_ + det + aro_d:
        pz.uv(v, 0.0, 0.0)
    cen = bm.verts.new(c + t * grosor * 0.55)
    pz.uv(cen, 0.0, 0.0)
    for jj in range(lados):
        j2 = (jj + 1) % lados
        f = bm.faces.new((del_[jj], del_[j2], cen)); f.material_index = mat
        f = bm.faces.new((aro_d[jj], aro_d[j2], del_[j2], del_[jj])); f.material_index = mat_aro
        f = bm.faces.new((det[jj], det[j2], aro_d[j2], aro_d[jj])); f.material_index = mat_aro


def _luna(pz, c, nrm, arriba, r, mat=0, n=10):
    """Media luna creciente (plana, con algo de grosor) sobre el disco."""
    bm = pz.bm
    t, nn, b = G.marco(nrm, arriba)
    fuera, dentro = [], []
    for i in range(n + 1):
        a = math.radians(-120 + 240 * i / n)
        d = nn * math.cos(a) + b * math.sin(a)
        fuera.append(bm.verts.new(c + d * r))
        # el borde de dentro: otro círculo desplazado (la luna)
        d2 = nn * math.cos(a) * 0.80 + b * math.sin(a) * 0.80
        dentro.append(bm.verts.new(c + d2 * r + b * r * 0.32 + t * 0.001))
    for v in fuera + dentro:
        pz.uv(v, 0.0, 0.0)
    for i in range(n):
        f = bm.faces.new((fuera[i], fuera[i + 1], dentro[i + 1], dentro[i]))
        f.material_index = mat


def _ala(pz, P, rot, rb_x, rb_y):
    bm = pz.bm
    na = 32
    # radios del ala (desde el centro de la base): ~1,35 veces el ancho de hombros con la capa (crear_nix.py lo mide)
    R_x, R_y = 0.315, 0.285
    # muesca de media luna en el borde delantero derecho del personaje (ángulo -50°)
    muesca_a, muesca_w, muesca_p = math.radians(-55), math.radians(26), 0.48

    def borde(a):
        d = math.atan2(math.sin(a - muesca_a), math.cos(a - muesca_a))
        k = 1.0
        if abs(d) < muesca_w:
            k -= muesca_p * math.cos(d / muesca_w * math.pi * 0.5) ** 1.5
        return k

    def caida(a, s):
        # el ala cae un poco a los lados y delante, sube detrás (inclinada como la copa)
        return (-0.030 * abs(math.sin(a)) - 0.012 * max(0.0, -math.cos(a)) + 0.030 * max(0.0, math.cos(a + math.pi))
                * 0.0) * s ** 1.6 - 0.006 * s

    filas_arr, filas_aba = [], []
    nr = 4
    for i in range(nr + 1):
        s = i / nr
        fa, fb = [], []
        for jj in range(na):
            a = 2 * math.pi * jj / na
            k = borde(a) if i > 0 else 1.0
            rx = rb_x * 0.97 + (R_x - rb_x * 0.97) * s * k
            ry = rb_y * 0.97 + (R_y - rb_y * 0.97) * s * k
            z = 0.012 + caida(a, s) + 0.010 * math.sin(s * math.pi)          # bóveda suave
            v = Vector((math.sin(a) * rx, -math.cos(a) * ry, z))
            fa.append(bm.verts.new(P(v)))
            # nivel de abajo: algo mayor (asoma 1 cm por el borde) y debajo
            rx2 = rb_x * 0.95 + (R_x * 1.035 - rb_x * 0.95) * s * k
            ry2 = rb_y * 0.95 + (R_y * 1.035 - rb_y * 0.95) * s * k
            fb.append(bm.verts.new(P(Vector((math.sin(a) * rx2, -math.cos(a) * ry2, z - 0.010 - 0.004 * s)))))
        filas_arr.append(fa)
        filas_aba.append(fb)
    for fila in filas_arr + filas_aba:
        for v in fila:
            pz.uv(v, 0.0, 0.0)
    for i in range(nr):
        for jj in range(na):
            j2 = (jj + 1) % na
            f = bm.faces.new((filas_arr[i][jj], filas_arr[i][j2], filas_arr[i + 1][j2], filas_arr[i + 1][jj]))
            f.material_index = 1
            f = bm.faces.new((filas_aba[i][jj], filas_aba[i + 1][jj], filas_aba[i + 1][j2], filas_aba[i][j2]))
            f.material_index = 2
    # canto: une el borde de arriba con el de abajo (lavanda)
    for jj in range(na):
        j2 = (jj + 1) % na
        f = bm.faces.new((filas_arr[nr][jj], filas_arr[nr][j2], filas_aba[nr][j2], filas_aba[nr][jj]))
        f.material_index = 2


# ------------------------------------------------------------------ bastón (hueso arma_d; rígido)
def baston(punto, hoja, filo, alto_ref):
    """Bastón de Nix construido en el mundo: el asta va por «hoja» desde la empuñadura (punto). Devuelve la Pieza.
    Asta fina ciruela oscura con contera de cobre en punta, anillos de cobre y, arriba, un arco de hierro roto y
    asimétrico que sostiene un cristal lavanda opaco con tres garras de metal."""
    pz = G.Pieza("nix_baston", ["asta", "cobre", "hierro", "cristal"], [("arma_d", 1.0)], p=2)
    Y = hoja.normalized()
    X = (filo - Y * filo.dot(Y)).normalized()
    Z = X.cross(Y)
    e = alto_ref / 1.65
    abajo, arriba = 0.52 * e, 0.66 * e                       # de la empuñadura: largo hacia abajo y hacia arriba
    p0 = punto - Y * abajo
    p1 = punto + Y * arriba
    # asta
    G.tubo(pz, [(p0 + Y * 0.06 * e, Y.cross(X), 0.0095, 0.0095), (punto, Y.cross(X), 0.0105, 0.0105),
                (p1 - Y * 0.02 * e, Y.cross(X), 0.0100, 0.0100)], segs=8)
    # contera de cobre en punta
    G.tubo(pz, [(p0 + Y * 0.075 * e, X, 0.012, 0.012), (p0 + Y * 0.05 * e, X, 0.016, 0.016),
                (p0, X, 0.002, 0.002)], segs=8, mat=lambda i, j: 1)
    # anillos de cobre (bajo, empuñadura y cuello)
    for d in (-0.32, 0.08, arriba / e - 0.06):
        c = punto + Y * d * e
        G.tubo(pz, [(c - Y * 0.012 * e, X, 0.0135, 0.0135), (c + Y * 0.012 * e, X, 0.0135, 0.0135)], segs=8,
               tapa0=True, tapa1=True, mat=lambda i, j: 1)
    # cuello de cobre bajo el arco
    G.tubo(pz, [(p1 - Y * 0.03 * e, X, 0.013, 0.013), (p1, X, 0.018, 0.018), (p1 + Y * 0.012 * e, X, 0.015, 0.015)],
           segs=8, mat=lambda i, j: 1)
    # arco de hierro roto: un aro casi completo en el plano de la hoja y el filo, abierto arriba a un lado, con las
    # puntas quebradas (asimétrico)
    rc = 0.085 * e
    centro = p1 + Y * (rc + 0.005 * e)
    pts = []
    a0, a1 = math.radians(-215), math.radians(28)            # abierto arriba a la derecha
    n = 18
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        r = rc * (1.0 + 0.06 * math.sin(i * 1.7))
        pts.append(centro + X * math.cos(a) * r + Y * math.sin(a) * r)
    rad = [(0.0085, 0.012)] * (n + 1)
    rad[0] = (0.005, 0.010); rad[-1] = (0.004, 0.008)
    G.tubo(pz, [(p, Z, ry, rx) for p, (rx, ry) in zip(pts, rad)], segs=6, tapa0=True, tapa1=True,
           mat=lambda i, j: 2)
    # punta quebrada que sale hacia fuera en el extremo abierto
    q = pts[-1]
    G.tubo(pz, [(q, Z, 0.006, 0.004), (q + (X * 0.5 + Y * 1.0).normalized() * 0.03 * e, Z, 0.001, 0.001)], segs=5,
           mat=lambda i, j: 2)
    q = pts[0]
    G.tubo(pz, [(q, Z, 0.007, 0.005), (q + (-X * 0.6 + Y * 1.0).normalized() * 0.038 * e, Z, 0.001, 0.001)], segs=5,
           mat=lambda i, j: 2)
    # cristal lavanda (bipirámide alargada de 6 caras) dentro del arco y sus tres garras
    G.gema(pz, centro + Y * 0.006 * e, Y, Z, 0.030 * e, 0.125 * e, mat=3, lados=6)
    for ang in (90, 210, 330):
        a = math.radians(ang)
        d = X * math.cos(a) + Z * math.sin(a)
        base = p1 + Y * 0.012 * e
        G.tubo(pz, [(base + d * 0.010, d, 0.003, 0.003), (centro - Y * 0.035 * e + d * 0.022 * e, d, 0.0028, 0.0028),
                    (centro - Y * 0.005 * e + d * 0.026 * e, d, 0.0015, 0.0015)], segs=4, tapa1=True,
               mat=lambda i, j: 1)
    return pz
