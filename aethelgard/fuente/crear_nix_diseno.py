# Nix (V12, cuarta heroína, PROTOTIPO APAGADO): diseño modelado por guion sobre su esqueleto en reposo en T.
# v2 (13/11, segunda pasada, centrada en la silueta; la v1 se conserva en personajes/nix/v1/).
#
# Lo usa fuente/crear_nix.py. El esqueleto es el de Lya (el rig común de los héroes v2: mismos nombres, jerarquía y
# orientaciones) con otras PROPORCIONES (crear_nix.py, ajustar_esqueleto): piernas ×0,66 y brazos ×0,85, la cadera más
# baja. La cabeza es geometría más grande (no cambia el esqueleto): unas 3,4 cabezas sin sombrero.
#
# Dirección (docs/v12/NIX_V12.md; especificación del usuario: Aethelgard_Nix_Maga_Negra.pdf, y la lámina de referencia
# que facilitó el usuario, que se sigue sin calcarla). Lo que más se lee, y a lo que va la geometría:
#   - SOMBRERO enorme: copa alta facetada inclinada atrás con la punta doblada hacia atrás (y a su izquierda); ala muy
#     ancha (más de dos veces el pelo), ondulada, caída a su izquierda y levantada a su derecha, donde está la muesca de
#     media luna; canto lavanda levantado y lavanda por debajo; cinta de cobre ancha con hebillas y el broche redondo
#     negro con la luna creciente de cobre.
#   - PELO: media melena con volumen (una masa en campana con las puntas recogidas), mechones encima que la parten,
#     flequillo de lado desde la raya a su izquierda y el mechón gris a ese lado; un mechón largo enmarca la cara.
#   - ROPA con vuelo: abrigo con peto crema con forma (pecho, costura, punta bajo el cinturón), faldón en dos alturas
#     que se abre en picos con ribete de cobre y franjas lilas, forro lila; capa corta en tres paños con el rombo
#     detrás; cuello alto con broche en rombo; puños crema; guantes grandes; medias grafito; botas anchas con vuelta.
#   - BASTÓN: asta con contera de cobre, y arriba un arco de hierro en media luna, con picos, que rodea el cristal
#     violeta, sujeto por una barra de cobre que lo atraviesa. Va en el hueso «arma_d», rígido.
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
    "ciruela": (0.25, 0.14, 0.26),
    "ciruela_claro": (0.34, 0.20, 0.36),
    "lavanda": (0.647, 0.541, 0.796),
    "marfil": (0.90, 0.85, 0.76),
    "cobre": (0.68, 0.46, 0.29),
    "piel": (0.96, 0.80, 0.69),
    "pelo": (0.19, 0.10, 0.17),
    "plata": (0.80, 0.79, 0.83),
    "guante": (0.26, 0.15, 0.19),
    "medias": (0.30, 0.28, 0.30),
    "cuero": (0.42, 0.25, 0.15),
    "cuero_claro": (0.52, 0.33, 0.20),
    "cuero_osc": (0.22, 0.13, 0.10),
    "hierro": (0.22, 0.21, 0.23),
    "cristal": (0.70, 0.54, 0.96),
    "negro": (0.05, 0.04, 0.06),
    "asta": (0.22, 0.12, 0.20),
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
        p[n] = {"color": COL[c], "tipo": t}
    return p


# ------------------------------------------------------------------ medidas de la cabeza (se fijan en construir)
CRANEO = {"c": Vector((0.003, -0.045, 1.30)), "rx": 0.208, "ry": 0.195, "rz": 0.214}
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
        if z < 0.1:
            y *= 1.0 + 0.04 * G.suave(0.1, -0.5, z)
    if y < -0.5:
        dn = math.hypot(x / 0.10, (z + 0.30) / 0.16)
        if dn < 1.0:
            y -= 0.045 * (1.0 - dn) ** 2 * (1.0 if z < -0.30 else 0.7)
    return Vector((x, y, z))


# ------------------------------------------------------------------ construir
def construir(H):
    """Devuelve la lista de piezas (geometria_v3.Pieza) en la pose de reposo, y fija CRANEO y CARA."""
    hd = H.c("Head")
    CRANEO["c"] = Vector((hd.x, hd.y - 0.014, hd.z + 0.165))
    C = CRANEO["c"]
    CARA.clear()
    CARA.update({
        "ojo": {"x": 0.082, "z": C.z - 0.046, "ancho": 0.132, "alto": 0.132},
        "boca": {"x": 0.0, "z": C.z - 0.142, "ancho": 0.056, "alto": 0.046},
        "ceja": {"z": C.z + 0.030, "largo": 0.060, "grueso": 0.0090, "inclinacion": 9.0},
        "marca": None,
        "iris": ((0.32, 0.10, 0.50), (0.80, 0.56, 1.0)),          # amatista: oscuro arriba, claro abajo
        "linea": (0.13, 0.06, 0.12),
        "ceja_color": (0.20, 0.10, 0.18),
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
    G.esfera(cab, C, CRANEO["rx"], CRANEO["ry"], CRANEO["rz"], segs=22, anillos=16, deformar=_cabeza_deformar)
    for sx in (-1, 1):
        G.esfera(cab, C + Vector((sx * 0.196, 0.010, -0.055)), 0.017, 0.013, 0.028, segs=6, anillos=5)
    n0, n1 = H.c("Neck"), H.c("Head")
    cue = G.Pieza("nix_cuello", ["piel"], [("Neck", 1.0), ("Head", 0.6), ("Spine2", 0.4)], p=3)
    G.tubo(cue, [(n0 + Vector((0, 0.002, -0.03)), ADEL, 0.037, 0.041), (n0.lerp(n1, 0.6), ADEL, 0.032, 0.035),
                 (n1 + Vector((0, 0.006, 0.06)), ADEL, 0.034, 0.037)], segs=10)
    return [cab, cue]


# ------------------------------------------------------------------ torso: abrigo con cuello alto y peto crema con forma
def _angs_peto():
    a = []
    for k in range(-3, 4):
        a.append(k * 0.15)
    for s in (1, -1):
        a.append(s * 0.50)
        a.append(s * 0.56)
    for k in range(1, 10):
        a.append(0.56 + k * (math.pi * 2 - 1.12) / 10)
    return sorted(set(round(x % (2 * math.pi), 5) for x in a))


def _mat_peto(a0, a1, peto, ribete, resto):
    m = ((a0 + a1) * 0.5)
    if a1 < a0:
        m = ((a0 + a1 + 2 * math.pi) * 0.5) % (2 * math.pi)
    d = min(m, 2 * math.pi - m)
    if d < 0.50:
        return peto
    if d < 0.56:
        return ribete
    return resto


def _torso(H):
    hip, sp, sp1, sp2, nk = H.c("Hips"), H.c("Spine"), H.c("Spine1"), H.c("Spine2"), H.c("Neck")
    piezas = []
    tor = G.Pieza("nix_torso", ["abrigo", "marfil", "cobre", "lavanda"],
                  [("Hips", 1.0), ("Spine", 1.0), ("Spine1", 1.0), ("Spine2", 1.0), ("Neck", 0.3),
                   ("LeftShoulder", 0.5), ("RightShoulder", 0.5)], p=3)
    angs = _angs_peto()
    z0 = hip.z
    # (z relativo a la cadera, ancho, fondo, delante, detrás): caderas anchas, cintura, pecho adulto suave
    perfil = [(-0.03, 0.112, 0.084, 1.0, 1.0), (0.05, 0.080, 0.066, 1.0, 1.0), (0.12, 0.070, 0.060, 1.02, 1.0),
              (0.18, 0.078, 0.066, 1.18, 1.0), (0.225, 0.088, 0.070, 1.22, 1.0), (0.255, 0.098, 0.066, 1.06, 1.0),
              (0.278, 0.080, 0.056, 1.0, 1.0)]
    an = []
    for dz, rx, ry, fa, fe in perfil:
        y = hip.y + (sp2.y - hip.y) * max(0.0, min(1.0, dz / 0.25)) * 0.6
        an.append({"c": Vector((hip.x, y, z0 + dz)), "f": ADEL, "rx": ry, "ry": rx, "fa": fa, "fe": fe})
    nj = len(angs)
    G.tubo(tor, an, angulos=angs, tapa0=True, tapa1=True, abombar=0.25,
           mat=lambda i, j: _mat_peto(angs[j], angs[(j + 1) % nj], 1, 2, 0))
    for dz in (0.11, 0.165, 0.215):                    # botones de cobre en la costura del peto
        G.esfera(tor, Vector((hip.x, hip.y - 0.074 - 0.012 * (dz > 0.15), z0 + dz)), 0.008, 0.005, 0.008, segs=6,
                 anillos=4, mat=2)
    piezas.append(tor)
    # cuello alto con ribete de cobre y la vista lila por dentro
    cu = G.Pieza("nix_cuello_alto", ["abrigo", "cobre", "forro"], [("Neck", 1.0), ("Spine2", 0.8)], p=3, grosor=0.004,
                 interior="forro")
    zc = nk.z - 0.015
    angs_c = [math.radians(a) for a in range(26, 335, 28)]
    anc = [(Vector((nk.x, nk.y + 0.004, zc)), ADEL, 0.054, 0.058), (Vector((nk.x, nk.y + 0.006, zc + 0.048)), ADEL, 0.050, 0.054),
           (Vector((nk.x, nk.y + 0.010, zc + 0.082)), ADEL, 0.054, 0.058)]
    G.tubo(cu, anc, angulos=angs_c, cerrado=False, mat=lambda i, j: 1 if i == 1 else 0)
    piezas.append(cu)
    br = G.Pieza("nix_broche_cuello", ["cobre", "lavanda"], [("Neck", 0.6), ("Spine2", 1.0)], p=3)
    G.gema(br, Vector((nk.x, nk.y - 0.060, zc + 0.004)), ARR, ADEL, 0.018, 0.038, mat=0)
    G.gema(br, Vector((nk.x, nk.y - 0.069, zc + 0.004)), ARR, ADEL, 0.009, 0.020, mat=1)
    piezas.append(br)
    # cinturón de cuero ancho con hebilla cuadrada de cobre
    ci = G.Pieza("nix_cinturon", ["cinturon", "cobre"], [("Hips", 1.0), ("Spine", 0.5)], p=3)
    zb = z0 + 0.04
    G.tubo(ci, [(Vector((hip.x, hip.y, zb - 0.020)), ADEL, 0.080, 0.093), (Vector((hip.x, hip.y, zb + 0.020)), ADEL, 0.076, 0.088)],
           segs=18)
    hb = Vector((hip.x, hip.y - 0.084, zb))
    for (dx, dz, sx, sz) in ((0, 0.022, 0.028, 0.005), (0, -0.022, 0.028, 0.005), (0.024, 0, 0.005, 0.024),
                             (-0.024, 0, 0.005, 0.024)):
        G.caja(ci, hb + Vector((dx, 0, dz)), (DER, ADEL, ARR), (sx, 0.006, sz), mat=1)
    G.caja(ci, hb + Vector((0, -0.002, 0)), (DER, ADEL, ARR), (0.003, 0.004, 0.020), mat=1)
    piezas.append(ci)
    return piezas


# ------------------------------------------------------------------ faldón: dos alturas que se abren en picos
def _hacia(cen, t):
    """De 0 (borde del costado) a 1 (borde que mira a la línea del centro, delante o detrás) a lo ancho del paño."""
    delante = abs(cen) < 90
    return (1.0 - t) if (cen > 0) == delante else t


def _panel(pz, hip, z0, cen, mitad, largo, r0x, r0y, vuelo_x, vuelo_y, pico, na, nr, franja=True, atras=0.0):
    """Un paño del faldón: de la cintura (z0) hacia abajo, con el pico en el borde que mira al centro (delante o
    detrás). Ribete de cobre abajo y en el borde del pico; franja lila junto a él (si «franja»)."""
    bm = pz.bm
    filas = []
    for i in range(nr + 1):
        s = i / nr
        fila = []
        for j in range(na + 1):
            t = j / na
            a = math.radians(cen - mitad + 2 * mitad * t)
            hacia = _hacia(cen, t)                      # 1 en el borde que mira al centro: el pico
            z = z0 - (largo + pico * hacia ** 1.6) * s - atras * s
            rx = r0x + vuelo_x * s ** 0.85
            ry = r0y + vuelo_y * s ** 0.85
            onda = 1.0 + 0.05 * math.sin(t * math.pi * 2.0) * s
            fila.append(bm.verts.new(Vector((hip.x + math.sin(a) * rx * onda, hip.y + 0.008 - math.cos(a) * ry * onda, z))))
        filas.append(fila)
    G._uv_filas(pz, filas, [Vector((hip.x, hip.y, z0 - largo * i / nr)) for i in range(nr + 1)], cerrado=False)
    for i in range(nr):
        for j in range(na):
            f = bm.faces.new((filas[i][j], filas[i + 1][j], filas[i + 1][j + 1], filas[i][j + 1]))
            hacia = _hacia(cen, (j + 0.5) / na)
            if i == nr - 1 or hacia > 1.0 - 1.0 / na:
                f.material_index = 1                    # cobre: bajo y borde del pico
            elif franja and hacia > 1.0 - 2.0 / na:
                f.material_index = 2                    # franja lila
            else:
                f.material_index = 0


def _falda(H):
    hip = H.c("Hips")
    piezas = []
    huesos = [("Hips", 1.3), ("LeftUpLeg", 0.55), ("RightUpLeg", 0.55), ("Bone_008", 0.5), ("Bone_007", 0.4)]
    # paño largo: delante dos (dejan ver el peto en punta), detrás dos (pico en el centro de la espalda)
    for k, (cen, mitad) in enumerate(((50, 40), (-50, 40), (135, 45), (-135, 45))):
        pz = G.Pieza("nix_falda_%d" % k, ["abrigo", "cobre", "lavanda"], huesos, p=2.6, grosor=0.005, interior="forro")
        _panel(pz, hip, hip.z + 0.02, cen, mitad, 0.27, 0.116, 0.096, 0.17, 0.15, 0.07, 7, 5,
               franja=abs(cen) < 90, atras=0.02 if abs(cen) > 90 else 0.0)
        piezas.append(pz)
    # paño corto de encima (peplo), en picos, sobre las caderas
    for k, (cen, mitad) in enumerate(((58, 34), (-58, 34), (128, 38), (-128, 38))):
        pz = G.Pieza("nix_peplo_%d" % k, ["abrigo", "cobre", "lavanda"], huesos[:3], p=2.6, grosor=0.004,
                     interior="forro")
        _panel(pz, hip, hip.z + 0.025, cen, mitad, 0.080, 0.124, 0.104, 0.09, 0.08, 0.05, 5, 2, franja=False)
        piezas.append(pz)
    # el peto crema sigue bajo el cinturón hasta una punta, entre los dos paños de delante
    pe = G.Pieza("nix_peto_bajo", ["marfil", "cobre"], [("Hips", 1.3), ("LeftUpLeg", 0.4), ("RightUpLeg", 0.4)], p=2.6,
                 grosor=0.004, interior="marfil")
    bm = pe.bm
    z0 = hip.z + 0.02
    filas = []
    nr = 5
    for i in range(nr + 1):
        s = i / nr
        ancho = 0.082 * (1.0 - s ** 1.7 * 0.94)
        z = z0 + 0.01 - 0.29 * s
        fila = []
        for j in range(5):
            t = j / 4 - 0.5
            a = t * 2 * ancho / 0.10
            r = 0.104 + 0.10 * s ** 0.9
            fila.append(bm.verts.new(Vector((hip.x + math.sin(a) * r * 0.95, hip.y - 0.002 - math.cos(a) * r * 0.92, z))))
        filas.append(fila)
    G._uv_filas(pe, filas, [Vector((hip.x, hip.y, z0 - 0.25 * i / nr)) for i in range(nr + 1)], cerrado=False)
    for i in range(nr):
        for j in range(4):
            f = bm.faces.new((filas[i][j], filas[i + 1][j], filas[i + 1][j + 1], filas[i][j + 1]))
            f.material_index = 1 if (j in (0, 3) or i == nr - 1) else 0
    piezas.append(pe)
    return piezas


# ------------------------------------------------------------------ capa corta en tres paños con el rombo detrás
def _capa(H):
    sp2, nk = H.c("Spine2"), H.c("Neck")
    pz = G.Pieza("nix_capa", ["abrigo", "cobre", "lavanda"],
                 [("Spine2", 1.2), ("Neck", 0.35), ("LeftShoulder", 1.0), ("RightShoulder", 1.0), ("LeftArm", 0.70),
                  ("RightArm", 0.70), ("Spine1", 0.5)], p=3.0, grosor=0.006, interior="forro")
    bm = pz.bm
    na = 26
    hueco = math.radians(18)
    angs = [hueco + (2 * math.pi - 2 * hueco) * j / (na - 1) for j in range(na)]
    nr = 6
    zc = nk.z - 0.012

    def brazo_arriba(x):
        lado = "Left" if x > 0 else "Right"
        a0, a1 = H.c(lado + "Arm"), H.c(lado + "ForeArm")
        t = max(0.0, min(1.0, (abs(x) - abs(a0.x)) / max(1e-4, abs(a1.x) - abs(a0.x))))
        return a0.z + (a1.z - a0.z) * t + 0.052 - 0.010 * t

    def es_corte(a):
        g = math.degrees(a)
        return abs(g - 100) < 7 or abs(g - 260) < 7          # las dos aberturas: tres paños

    filas = []
    for i in range(nr + 1):
        s = i / nr
        fila = []
        for a in angs:
            ca, sa = math.cos(a), math.sin(a)
            lateral = abs(sa) ** 1.5
            r_lat = 0.066 + 0.225 * s ** 0.95
            r_fb = 0.064 + 0.112 * s ** 0.9
            x = sa * (r_lat * lateral + r_fb * (1 - lateral))
            y = -ca * (r_fb + 0.010 * s) * (1.10 if ca < 0 else 1.0)
            # picos: detrás en el centro y delante en cada borde de la abertura
            pico = 0.05 * max(0.0, -ca) ** 6 + 0.035 * max(0.0, ca) ** 3
            z_fb = zc - (0.12 if ca > 0 else 0.13) * s ** 1.15 - pico * s ** 2
            z_lat = max(zc - 0.03 * s, brazo_arriba(x) + 0.018) if abs(x) > 0.07 else zc - 0.01 * s
            z = z_lat * lateral + z_fb * (1 - lateral)
            fila.append(bm.verts.new(Vector((sp2.x + x, sp2.y + 0.006 + y, z))))
        filas.append(fila)
    G._uv_filas(pz, filas, [Vector((sp2.x, sp2.y, zc - 0.1 * i / nr)) for i in range(nr + 1)], cerrado=False)
    for i in range(nr):
        for j in range(na - 1):
            am = (angs[j] + angs[j + 1]) * 0.5
            if i >= nr // 2 and es_corte(am):
                continue
            f = bm.faces.new((filas[i][j], filas[i][j + 1], filas[i + 1][j + 1], filas[i + 1][j]))
            borde_corte = i >= nr // 2 and (es_corte(angs[j] - 0.12) or es_corte(angs[j + 1] + 0.12))
            if i == nr - 1 or j == 0 or j == na - 2 or borde_corte:
                f.material_index = 1
            elif i == nr - 2:
                f.material_index = 2                     # franja lila sobre el ribete
            else:
                f.material_index = 0
    piezas = [pz]
    ro = G.Pieza("nix_capa_rombo", ["cobre", "lavanda"], [("Spine2", 1.0), ("Spine1", 0.6)], p=3)
    j_atras = (na - 1) // 2
    pb = filas[nr - 1][j_atras].co.copy()
    pb.y += 0.010
    G.gema(ro, pb + Vector((0, 0.002, 0.01)), ARR, -ADEL, 0.026, 0.058, mat=0)
    G.gema(ro, pb + Vector((0, 0.010, 0.01)), ARR, -ADEL, 0.012, 0.030, mat=1)
    piezas.append(ro)
    return piezas


# ------------------------------------------------------------------ brazos: manga ajustada, puño crema, guante grande
def _brazos(H):
    piezas = []
    for lado, sx in (("Left", 1), ("Right", -1)):
        sh, ar, fa, hd = H.c(lado + "Shoulder"), H.c(lado + "Arm"), H.c(lado + "ForeArm"), H.c(lado + "Hand")
        fuera = Vector((sx, 0, 0))
        mg = G.Pieza("nix_manga_" + lado, ["abrigo"],
                     [(lado + "Shoulder", 0.6), (lado + "Arm", 1.0), (lado + "ForeArm", 1.0), (lado + "Hand", 0.3)], p=4)
        pts = [ar - fuera * 0.05, ar, ar.lerp(fa, 0.5), fa, fa.lerp(hd, 0.55)]
        rad = [(0.052, 0.054), (0.045, 0.047), (0.038, 0.039), (0.033, 0.034), (0.030, 0.031)]
        G.tubo(mg, G.cadena(pts, ARR, rad, 2), segs=10)
        piezas.append(mg)
        pu = G.Pieza("nix_puno_" + lado, ["marfil", "cobre"],
                     [(lado + "ForeArm", 1.0), (lado + "Hand", 0.35)], p=4, grosor=0.004, interior="marfil")
        c0 = fa.lerp(hd, 0.36)
        c1 = fa.lerp(hd, 1.02)
        an = [(c0, ARR, 0.037, 0.038), (c0.lerp(c1, 0.15), ARR, 0.043, 0.044), (c0.lerp(c1, 0.85), ARR, 0.052, 0.054),
              (c1, ARR, 0.054, 0.056)]
        G.tubo(pu, an, segs=11, mat=lambda i, j: 1 if i in (0, 2) else 0)
        piezas.append(pu)
        piezas.append(_mano(H, lado, sx))
    return piezas


def _mano(H, lado, sx):
    """Guante grande (chibi): palma, cuatro dedos (con los pesos del corazón) y el pulgar; caña del guante."""
    hd = H.c(lado + "Hand")
    nud = H.c(lado + "HandMiddle1")
    eje = (nud - hd).normalized()
    m = G.Pieza("nix_mano_" + lado, ["guante"],
                [(lado + "Hand", 1.0)] + [(lado + "Hand" + d + str(i), 1.0) for d in ("Thumb", "Middle") for i in (1, 2, 3)],
                p=5)
    abajo = Vector((0, 0, -1))
    k = 1.36
    pal = [(hd - eje * 0.034, abajo, 0.026 * k, 0.027 * k), (hd - eje * 0.006, abajo, 0.019 * k, 0.024 * k),
           (hd.lerp(nud, 0.45), abajo, 0.018 * k, 0.030 * k), (nud - eje * 0.004, abajo, 0.016 * k, 0.033 * k),
           (nud + eje * 0.010, abajo, 0.012 * k, 0.030 * k)]
    G.tubo(m, pal, segs=9, tapa1=True, abombar=0.3)
    med = [H.c(lado + "HandMiddle" + str(i)) for i in (1, 2, 3, 4)] + [H.k(lado + "HandMiddle4")]
    lat = Vector((0, -1, 0))
    for off, r, kk in ((0.020, 0.0098, 0.92), (0.0, 0.0106, 1.0), (-0.019, 0.0098, 0.94), (-0.035, 0.0085, 0.80)):
        pts = [nud - eje * 0.004 + lat * off * k]
        for q in med[1:]:
            pts.append(nud + (q - nud) * kk * 1.22 + lat * off * k)
        ra = [(r, r), (r, r), (r * 0.94, r * 0.94), (r * 0.86, r * 0.86), (r * 0.74, r * 0.74)]
        G.tubo(m, G.cadena(pts, abajo, ra, 1), segs=5, tapa1=True, abombar=0.6)
    th = [H.c(lado + "HandThumb" + str(i)) for i in (1, 2, 3, 4)] + [H.k(lado + "HandThumb4")]
    th = [th[0] - eje * 0.006] + [th[0] + (q - th[0]) * 1.30 for q in th[1:]]
    G.tubo(m, G.cadena(th, abajo, [(0.0115, 0.0115)] * 3 + [(0.010, 0.010), (0.008, 0.008)], 1), segs=5, tapa1=True,
           abombar=0.6)
    return m


# ------------------------------------------------------------------ piernas gruesas y botas anchas con vuelta
def _piernas(H):
    piezas = []
    for lado, sx in (("Left", 1), ("Right", -1)):
        ul, lg, ft, tb = H.c(lado + "UpLeg"), H.c(lado + "Leg"), H.c(lado + "Foot"), H.c(lado + "ToeBase")
        pi = G.Pieza("nix_pierna_" + lado, ["medias"], [("Hips", 0.5), (lado + "UpLeg", 1.0), (lado + "Leg", 1.0),
                                                         (lado + "Foot", 0.3)], p=4)
        pts = [ul + Vector((-sx * 0.02, 0, 0.04)), ul, ul.lerp(lg, 0.5), lg, lg.lerp(ft, 0.45), ft + Vector((0, 0, 0.03))]
        rad = [(0.104, 0.098), (0.106, 0.100), (0.090, 0.085), (0.068, 0.068), (0.072, 0.074), (0.050, 0.052)]
        G.tubo(pi, G.cadena(pts, ADEL, rad, 2), segs=10)
        piezas.append(pi)
        bo = G.Pieza("nix_bota_" + lado, ["bota", "bota_vuelta", "cinturon", "cobre"],
                     [(lado + "Leg", 0.8), (lado + "Foot", 1.4), (lado + "ToeBase", 1.0)], p=5)
        dirp = Vector((tb.x - ft.x, tb.y - ft.y, 0)).normalized()
        tob = Vector((ft.x, ft.y, ft.z))
        caña = [(Vector((tob.x, tob.y + 0.004, 0.040)), ADEL, 0.064, 0.072),
                (Vector((tob.x, tob.y + 0.004, tob.z)), ADEL, 0.062, 0.066),
                (lg.lerp(ft, 0.66), ADEL, 0.076, 0.079),
                (lg.lerp(ft, 0.40), ADEL, 0.080, 0.082)]
        G.tubo(bo, caña, segs=12)
        talon = Vector((ft.x, ft.y + 0.020, 0.0))
        punta = Vector((tb.x, tb.y, 0.0)) + dirp * 0.078
        an = [(talon + Vector((0, 0.022, 0.060)), 0.060, 0.060),
              (talon.lerp(punta, 0.30) + Vector((0, 0, 0.064)), 0.066, 0.056),
              (talon.lerp(punta, 0.62) + Vector((0, 0, 0.049)), 0.064, 0.045),
              (talon.lerp(punta, 0.88) + Vector((0, 0, 0.036)), 0.053, 0.034),
              (punta + Vector((0, 0, 0.032)), 0.034, 0.024)]
        an = [{"c": a[0], "f": ARR, "rx": a[2], "ry": a[1]} for a in an]
        G.tubo(bo, an, segs=12, tapa0=True, tapa1=True, abombar=0.6)
        # suela gruesa y tacón bajo
        G.caja(bo, talon + Vector((0, 0.014, 0.015)), (DER, ADEL, ARR), (0.050, 0.036, 0.015), mat=2)
        G.tubo(bo, [{"c": talon.lerp(punta, 0.35) + Vector((0, 0, 0.008)), "f": ARR, "rx": 0.009, "ry": 0.065},
                    {"c": talon.lerp(punta, 0.97) + Vector((0, 0, 0.008)), "f": ARR, "rx": 0.009, "ry": 0.046}],
               segs=8, tapa0=True, tapa1=True, mat=lambda i, j: 2)
        # vuelta ancha (cuero más claro) que se abre arriba de la caña
        cv = lg.lerp(ft, 0.40)
        vu = [(cv + Vector((0, 0, -0.020)), ADEL, 0.084, 0.086), (cv + Vector((0, 0, 0.018)), ADEL, 0.094, 0.096),
              (cv + Vector((0, 0, 0.052)), ADEL, 0.102, 0.104)]
        G.tubo(bo, vu, segs=14, mat=lambda i, j: 1)
        # correa con hebilla de cobre en el empeine
        G.tubo(bo, [{"c": talon.lerp(punta, 0.36) + Vector((0, 0, 0.060)), "f": ARR, "rx": 0.066, "ry": 0.068},
                    {"c": talon.lerp(punta, 0.44) + Vector((0, 0, 0.057)), "f": ARR, "rx": 0.065, "ry": 0.067}],
               segs=12, mat=lambda i, j: 2)
        hb = talon.lerp(punta, 0.40) + Vector((sx * 0.066, 0, 0.054))
        G.caja(bo, hb, (Vector((sx, 0, 0)), ADEL, ARR), (0.004, 0.012, 0.012), mat=3)
        piezas.append(bo)
    return piezas


# ------------------------------------------------------------------ pelo: media melena con volumen y mechones
def _theta_bajo(phi):
    """Dónde acaba la melena en cada columna (grados desde arriba): delante, en el nacimiento (lo tapa el flequillo);
    a los lados, hasta la mandíbula; detrás, algo más arriba (nuca despejada)."""
    a = abs(((phi + 180) % 360) - 180)
    if a < 48:
        return 72.0
    if a < 78:
        return 72.0 + (140.0 - 72.0) * G.suave(48, 78, a)
    if a < 118:
        return 140.0
    return 140.0 + (124.0 - 140.0) * G.suave(118, 180, a)


def _casco_punto(theta, phi, k, C):
    """Punto de la melena: sobre el cráneo hasta el ecuador y, por debajo, cae casi recta y se abre (campana)."""
    if theta <= 90:
        return _elip(_u(theta, phi), k)
    p90 = _elip(_u(90, phi), k)
    hz = Vector((p90.x - C.x, p90.y - C.y, 0))
    t = (theta - 90) / 50.0
    abre = 1.0 + 0.30 * t ** 1.15
    z = C.z + CRANEO["rz"] * k * math.cos(math.radians(theta)) * 0.95
    return Vector((C.x + hz.x * abre, C.y + hz.y * abre, z))


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
        if curvar and (u.x or u.y):
            p += Vector((-u.x, -u.y, 0)).normalized() * curvar * max(0.0, s - 0.6) ** 2 * 2.5
        pts.append(p)
        nor.append(u)
    G.mechon_pts(pz, pts, nor, ancho, grueso, lados=lados, mat=mat, perfil=perfil)


def _pelo():
    rnd = random.Random(23)
    j = lambda a: rnd.uniform(-a, a)
    C = CRANEO["c"]
    pz = G.Pieza("nix_pelo", ["pelo", "pelo_plata"], [("Head", 1.0)], p=3.0, grosor=0.012, interior="pelo")
    pm = G.Pieza("nix_pelo_mechones", ["pelo", "pelo_plata"], [("Head", 1.0)], p=3.0)
    bm = pz.bm
    # 1) la melena: una masa con volumen que cae en campana; el bajo en ondas (cada onda, un mechón) recogidas dentro
    ncol, nfil, ondas = 32, 7, 8
    filas = []
    for i in range(nfil + 1):
        s = i / nfil
        fila = []
        for jj in range(ncol):
            phi = -180 + 360 * jj / ncol
            tb = _theta_bajo(phi)
            ond = math.cos(math.radians(phi) * ondas)
            tb_o = tb + (4.0 * ond if tb > 100 else 0.0)
            th = 6 + (tb_o - 6) * s
            k = 1.10 + 0.19 * s ** 1.3 + 0.03 * ond * s ** 2.5
            if i == nfil:
                k -= 0.07
            fila.append(bm.verts.new(_casco_punto(th, phi, k, C)))
        filas.append(fila)
    polo = bm.verts.new(_elip(_u(0, 0), 1.09))
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
    # 2) mechones sobre la melena (la parten en capas): de la coronilla a las puntas, por los lados y detrás
    perfil_capa = lambda s: (0.75 + 0.25 * math.sin(min(1.0, s / 0.3) * math.pi / 2)) * (1.0 - max(0.0, s - 0.74) / 0.26) ** 0.6
    for phi in (78, 104, 132, 160, -158, -130, -100):
        tb = _theta_bajo(phi)
        _mechon(pm, 20 + j(4), phi * 0.8 + j(5), tb + 4 + j(3), phi + j(4), 0.090 + j(0.006), 0.022, k=1.14,
                levantar=0.17, segs=8, lados=5, perfil=perfil_capa, curvar=0.025)
    # 3) flequillo de lado: de la raya (a su IZQUIERDA, phi > 0, junto al mechón gris) barre hacia su derecha y tapa
    #    media frente; masas anchas que se superponen y acaban en punta redondeada sobre la ceja
    perfil_fleq = lambda s: (0.72 + 0.28 * math.sin(min(1.0, s / 0.35) * math.pi / 2)) * (1.0 - max(0.0, s - 0.58) / 0.42) ** 0.85
    for (f0, f1, t1, an, gr) in ((32, 12, 86, 0.115, 0.028), (24, -16, 90, 0.128, 0.030), (16, -42, 99, 0.120, 0.029),
                                 (8, -66, 114, 0.100, 0.027)):
        _mechon(pm, 14 + j(2), f0, t1 + j(1.5), f1 + j(2), an, gr, k=1.12, levantar=0.06, segs=9, perfil=perfil_fleq,
                lados=6)
    # 4) un mechón largo enmarca la cara a su derecha, hasta la barbilla
    perfil_lado = lambda s: (0.75 + 0.25 * math.sin(min(1.0, s / 0.3) * math.pi / 2)) * (1.0 - max(0.0, s - 0.7) / 0.3) ** 0.6
    _mechon(pm, 40, -58, 138, -68, 0.072, 0.024, k=1.14, levantar=0.10, segs=9, perfil=perfil_lado, lados=6, curvar=0.02)
    # el mechón GRIS: a su izquierda, de la raya a la mandíbula, por delante de la melena
    _mechon(pm, 18, 34, 138, 62, 0.064, 0.024, k=1.18, levantar=0.10, segs=11, mat=1, perfil=perfil_lado, lados=6,
            curvar=0.02)
    return [pz, pm]


# ------------------------------------------------------------------ sombrero (rígido, ligado a la cabeza)
def _sombrero(H):
    C = CRANEO["c"]
    pz = G.Pieza("nix_sombrero", ["sombrero", "sombrero_ala", "sombrero_ala_baja", "cobre", "negro"], [("Head", 1.0)], p=3)
    bm = pz.bm
    incl = math.radians(12)
    base_c = C + Vector((0, 0.026, 0.108))
    rot = Matrix.Rotation(-incl, 3, 'X')                  # hacia atrás (la copa se inclina a +Y)
    rb_x, rb_y = 0.238, 0.224

    def P(v):
        return base_c + rot @ v

    # --- copa: cono facetado de 9 caras, alto
    nf = 9
    anillos = [(0.000, 1.00), (0.025, 0.96), (0.085, 0.80), (0.170, 0.60), (0.270, 0.42), (0.370, 0.28), (0.460, 0.19)]

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
    # la punta se dobla una vez HACIA ATRÁS (y algo a su izquierda) y cae
    dob = Vector((0.06, 0.17, 0.0))
    for (h, k, s) in ((0.52, 0.13, 0.45), (0.555, 0.08, 0.85)):
        cc = Vector((0, 0, h)) + dob * s - Vector((0, 0, 0.06 * s * s))
        fila = []
        for jj in range(nf):
            a = 2 * math.pi * (jj + 0.5) / nf
            fila.append(bm.verts.new(P(cc + Vector((math.sin(a) * rb_x * k, -math.cos(a) * rb_y * k, 0)))))
        filas.append(fila)
    tip = bm.verts.new(P(Vector((0, 0, 0.53)) + dob * 1.45 - Vector((0, 0, 0.13))))
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
    # --- cinta de cobre ANCHA con un reborde arriba y abajo
    hb0, hb1 = 0.018, 0.092
    banda = []
    for (h, sale) in ((hb0, 0.012), (hb0 + 0.008, 0.016), (hb1 - 0.008, 0.016), (hb1, 0.012)):
        k = kcopa(h)
        fila = []
        for jj in range(nf):
            a = 2 * math.pi * (jj + 0.5) / nf
            fila.append(bm.verts.new(P(Vector((math.sin(a) * (rb_x * k + sale), -math.cos(a) * (rb_y * k + sale), h)))))
            pz.uv(fila[-1], 0.0, 0.0)
        banda.append(fila)
    for i in range(3):
        for jj in range(nf):
            j2 = (jj + 1) % nf
            f = bm.faces.new((banda[i][jj], banda[i][j2], banda[i + 1][j2], banda[i + 1][jj]))
            f.material_index = 3
    hc = (hb0 + hb1) * 0.5
    kc = kcopa(hc)
    # hebillas: dos barras verticales cruzadas por dos horizontales (#), delante a su derecha y detrás
    for ang in (-28, 180):
        a = math.radians(ang)
        cpos = P(Vector((math.sin(a) * (rb_x * kc + 0.024), -math.cos(a) * (rb_y * kc + 0.024), hc)))
        tg = rot @ Vector((math.cos(a), math.sin(a), 0))
        nrm = rot @ Vector((math.sin(a), -math.cos(a), 0))
        up = rot @ Vector((0, 0, 1))
        for d in (-0.012, 0.012):
            G.caja(pz, cpos + tg * d, (tg, nrm, up), (0.0045, 0.006, 0.042), mat=3)
        for dz in (-0.014, 0.014):
            G.caja(pz, cpos + nrm * 0.003 + up * dz, (tg, nrm, up), (0.022, 0.005, 0.0045), mat=3)
    # broche: disco negro grande con aro de cobre y la luna creciente de cobre, a su izquierda (delante)
    a = math.radians(36)
    cpos = P(Vector((math.sin(a) * (rb_x * kc + 0.020), -math.cos(a) * (rb_y * kc + 0.020), hc + 0.006)))
    nrm = (rot @ Vector((math.sin(a), -math.cos(a), 0.18))).normalized()
    _disco(pz, cpos + nrm * 0.006, nrm, rot @ Vector((0, 0, 1)), 0.054, 0.014, mat=4, mat_aro=3, lados=20)
    _luna(pz, cpos + nrm * 0.0145, nrm, rot @ Vector((0, 0, 1)), 0.036, mat=3, n=12)
    # --- ala muy ancha y ondulada
    _ala(pz, P, rb_x, rb_y)
    return pz


def _disco(pz, c, nrm, arriba, r, grosor, mat=0, mat_aro=0, lados=18):
    bm = pz.bm
    t, n, b = G.marco(nrm, arriba)
    del_, det, aro_d = [], [], []
    for jj in range(lados):
        a = 2 * math.pi * jj / lados
        d = n * math.cos(a) + b * math.sin(a)
        del_.append(bm.verts.new(c + d * r * 0.84 + t * grosor * 0.5))
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
        a = math.radians(-125 + 250 * i / n)
        d = nn * math.cos(a) + b * math.sin(a)
        fuera.append(bm.verts.new(c + d * r))
        d2 = nn * math.cos(a) * 0.78 + b * math.sin(a) * 0.78
        dentro.append(bm.verts.new(c + d2 * r + b * r * 0.34 + t * 0.001))
    for v in fuera + dentro:
        pz.uv(v, 0.0, 0.0)
    for i in range(n):
        f = bm.faces.new((fuera[i], fuera[i + 1], dentro[i + 1], dentro[i]))
        f.material_index = mat


def _ala(pz, P, rb_x, rb_y):
    """Ala elíptica muy ancha (≈ 2,2 veces el pelo), ondulada; cae a su izquierda, sube a su derecha (donde está la
    muesca de media luna, de puntas afiladas) y algo detrás; canto lavanda levantado y todo lavanda por debajo."""
    bm = pz.bm
    na = 48
    R_x, R_y = 0.490, 0.450
    muesca_a, muesca_w, muesca_p = math.radians(-88), math.radians(27), 0.56

    def borde(a):
        d = math.atan2(math.sin(a - muesca_a), math.cos(a - muesca_a))
        if abs(d) < muesca_w:
            return 1.0 - muesca_p * math.sqrt(max(0.0, 1.0 - (d / muesca_w) ** 2))
        return 1.0

    def alto(a, s):
        sa, ca = math.sin(a), math.cos(a)
        z = -0.105 * max(0.0, sa) ** 1.5 * s ** 1.6          # cae a su izquierda
        z += 0.075 * max(0.0, -sa) ** 2 * s ** 1.8           # sube a su derecha
        z += -0.032 * max(0.0, ca) * s ** 2                  # delante, algo caída
        z += -0.040 * max(0.0, -ca) ** 2 * s ** 1.5          # detrás, sobre el pelo
        z += 0.024 * math.sin(3 * a + 0.6) * s ** 2          # ondas
        return z + 0.010 * math.sin(s * math.pi)

    nr = 5
    filas_arr, filas_aba = [], []
    for i in range(nr + 1):
        s = i / nr
        fa, fb = [], []
        for jj in range(na):
            a = 2 * math.pi * jj / na
            k = borde(a) if i > 0 else 1.0
            ss = s
            rx = rb_x * 0.97 + (R_x - rb_x * 0.97) * ss * k
            ry = rb_y * 0.97 + (R_y - rb_y * 0.97) * ss * k
            z = 0.012 + alto(a, ss)
            if i == nr:
                z += 0.012                                    # el canto se levanta (el reborde lavanda)
            fa.append(bm.verts.new(P(Vector((math.sin(a) * rx, -math.cos(a) * ry, z)))))
            fb.append(bm.verts.new(P(Vector((math.sin(a) * rx * 1.006, -math.cos(a) * ry * 1.006, z - 0.012 - 0.004 * s)))))
        filas_arr.append(fa)
        filas_aba.append(fb)
    for fila in filas_arr + filas_aba:
        for v in fila:
            pz.uv(v, 0.0, 0.0)
    for i in range(nr):
        for jj in range(na):
            j2 = (jj + 1) % na
            f = bm.faces.new((filas_arr[i][jj], filas_arr[i][j2], filas_arr[i + 1][j2], filas_arr[i + 1][jj]))
            f.material_index = 2 if i == nr - 1 else 1          # el anillo de fuera, lavanda
            f = bm.faces.new((filas_aba[i][jj], filas_aba[i + 1][jj], filas_aba[i + 1][j2], filas_aba[i][j2]))
            f.material_index = 2
    for jj in range(na):
        j2 = (jj + 1) % na
        f = bm.faces.new((filas_arr[nr][jj], filas_arr[nr][j2], filas_aba[nr][j2], filas_aba[nr][jj]))
        f.material_index = 2


# ------------------------------------------------------------------ bastón (hueso arma_d; rígido)
def baston(punto, hoja, filo, alto_ref):
    """Bastón de Nix construido en el mundo: el asta va por «hoja» desde la empuñadura (punto). Asta ciruela oscura con
    contera de cobre en punta y anillos de cobre; arriba, un arco de hierro en MEDIA LUNA, grueso en el lomo y afilado
    en las puntas, con picos, que rodea el cristal violeta; una barra de cobre lo atraviesa y sujeta el cristal."""
    pz = G.Pieza("nix_baston", ["asta", "cobre", "hierro", "cristal"], [("arma_d", 1.0)], p=2)
    Y = hoja.normalized()
    X = (filo - Y * filo.dot(Y)).normalized()
    Z = X.cross(Y)
    e = alto_ref / 1.65
    abajo, arriba = 0.75 * e, 0.42 * e                  # la contera llega al suelo; la luna, bajo el ala
    p0 = punto - Y * abajo
    p1 = punto + Y * arriba
    G.tubo(pz, [(p0 + Y * 0.06 * e, Y.cross(X), 0.0105, 0.0105), (punto, Y.cross(X), 0.0115, 0.0115),
                (p1 - Y * 0.02 * e, Y.cross(X), 0.0105, 0.0105)], segs=7)
    G.tubo(pz, [(p0 + Y * 0.080 * e, X, 0.013, 0.013), (p0 + Y * 0.055 * e, X, 0.018, 0.018),
                (p0, X, 0.002, 0.002)], segs=7, mat=lambda i, j: 1)
    for d in (-0.30, arriba / e - 0.10):
        c = punto + Y * d * e
        G.tubo(pz, [(c - Y * 0.013 * e, X, 0.0145, 0.0145), (c + Y * 0.013 * e, X, 0.0145, 0.0145)], segs=7,
               tapa0=True, tapa1=True, mat=lambda i, j: 1)
    # cuello de cobre bajo el cristal
    G.tubo(pz, [(p1 - Y * 0.035 * e, X, 0.014, 0.014), (p1, X, 0.021, 0.021), (p1 + Y * 0.016 * e, X, 0.017, 0.017)],
           segs=7, mat=lambda i, j: 1)
    # media luna de hierro: un arco grueso en el lomo (a la izquierda de la hoja) y afilado en las puntas, abierto
    # arriba a la derecha; picos hacia fuera en el lomo
    rc = 0.098 * e
    centro = p1 + Y * (0.090 * e)
    a0, a1 = math.radians(48), math.radians(338)
    n = 16
    pts, rad = [], []
    for i in range(n + 1):
        s = i / n
        a = a0 + (a1 - a0) * s
        grosor = 0.006 + 0.020 * math.sin(s * math.pi) ** 0.8
        pts.append(centro + X * math.cos(a) * rc + Y * math.sin(a) * rc)
        rad.append((0.0075, grosor))
    G.tubo(pz, [(p, Z, ry, rx) for p, (rx, ry) in zip(pts, rad)], segs=4, tapa0=True, tapa1=True,
           mat=lambda i, j: 2)
    for s in (0.32, 0.5, 0.68):
        a = a0 + (a1 - a0) * s
        d = X * math.cos(a) + Y * math.sin(a)
        b = centro + d * (rc + 0.014)
        G.tubo(pz, [(b, Z, 0.006, 0.008), (b + d * 0.028 * e, Z, 0.001, 0.001)], segs=4, mat=lambda i, j: 2)
    # cristal violeta (bipirámide alargada de 6 caras) en el centro de la luna
    G.gema(pz, centro, Y, Z, 0.034 * e, 0.140 * e, mat=3, lados=6)
    # barra de cobre que lo atraviesa de lado a lado hasta el arco, con dos casquillos
    G.tubo(pz, [(centro - X * rc * 0.98, X, 0.005, 0.005), (centro + X * rc * 0.98, X, 0.005, 0.005)], segs=6,
           mat=lambda i, j: 1)
    for sx in (-1, 1):
        q = centro + X * sx * 0.036 * e
        G.tubo(pz, [(q - X * 0.008, X, 0.009, 0.009), (q + X * 0.008, X, 0.009, 0.009)], segs=6, tapa0=True, tapa1=True,
               mat=lambda i, j: 1)
    # el cristal se apoya en el cuello: una varilla corta de cobre
    G.tubo(pz, [(p1 + Y * 0.012 * e, Y.cross(X), 0.006, 0.006), (centro - Y * 0.065 * e, Y.cross(X), 0.005, 0.005)],
           segs=6, mat=lambda i, j: 1)
    return pz
