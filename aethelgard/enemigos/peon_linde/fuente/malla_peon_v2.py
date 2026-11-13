# e01 · Peón de Linde v2 (13/11/2026, segunda pasada de arte): la malla, el atlas detallado y el mapa de normales.
# Lo ejecuta crear_peon_linde.py con «v2» (exec en su espacio de nombres: m, A, B, E, C, arm, _hs, PUNO, DIR_ESTACA…).
# Qué cambia frente a la v1 (que se conserva entera): proporciones compactas (piernas ×0,70, cabeza ×1,35, brazos ×0,86:
# 1,47 m, al lado de los héroes chibi sin parecer un bebé), todo con formas de torno y cajas muy redondeadas en vez de
# cajas: máscara de mojón abombada con ceja, nariz, cuencas y coronilla pintada; capucha abierta por delante; chaqueta
# acampanada con pliegues en el bajo (silueta triangular); faldón de cuatro placas curvadas que abrazan la cadera;
# mitones con pulgar y puño; botas con caña, puntera y suela.

# ================================================================== atlas (1024 en 3×3 celdas de 341 px: más detalle)

A = E.AtlasV12(1024, 3, semilla=211)


def _xy(h):
    yy, xx = np.mgrid[0:h, 0:h]
    return (xx + 0.5) / h, (yy + 0.5) / h


def v2_barro(h, rng, base=(0.58, 0.44, 0.31), grietas=1.0):
    X, Y = _xy(h)
    f = E.fbm(h, rng, 4, 6)
    f1, f2 = E.celdas_voronoi(h, rng, 30)
    img = E.color(base) * (0.78 + 0.36 * f[..., None])
    borde = np.clip((0.05 - (f2 - f1)) * 18, 0, 1)
    img = E.mezclar(img, (0.74, 0.62, 0.47), np.clip(borde * 1.5 - 0.6, 0, 0.55) * grietas)
    img = E.mezclar(img, (0.22, 0.15, 0.10), np.clip((0.010 - (f2 - f1)) * 80, 0, 0.95) * grietas)
    # chorretones de barro más oscuro (verticales) y motas de paja
    chorro = np.clip((E.ruido(h, 22, rng)[0][None, :] * np.ones((h, 1)) - 0.72) * 4, 0, 1) * np.clip(1.2 - Y * 1.5, 0, 1)
    img = E.mezclar(img, (0.40, 0.29, 0.20), chorro * 0.5)
    paja = rng.random((h, h)) < 0.004
    img[paja] = img[paja] * 0.5 + E.color((0.80, 0.70, 0.40))[0, 0] * 0.5
    return img


def v2_barro_oscuro(h, rng):
    return v2_barro(h, rng, (0.40, 0.30, 0.21), 0.75)


def v2_fibra(h, rng, base=(0.54, 0.62, 0.46)):
    """Tejido grueso de fibras: trama en damero, hebras sueltas, costuras punteadas y sombras de pliegue verticales."""
    X, Y = _xy(h)
    n = 22
    u = np.sin(X * math.pi * 2 * n)
    v = np.sin(Y * math.pi * 2 * n)
    cuadro = (np.floor(X * n) + np.floor(Y * n)) % 2
    trama = np.where(cuadro > 0, 0.5 + 0.5 * np.abs(u), 0.5 + 0.5 * np.abs(v))
    f = E.fbm(h, rng, 3, 5)
    img = E.color(base) * (0.68 + 0.30 * trama[..., None]) * (0.84 + 0.26 * f[..., None])
    pliegue = 0.5 + 0.5 * np.sin(X * math.pi * 2 * 3 + 2.5 * E.fbm(h, rng, 2, 3))
    img = img * (0.86 + 0.18 * pliegue[..., None])
    for k in range(90):
        y0, x0 = rng.uniform(0, 1), rng.uniform(0, 1)
        l, a = rng.uniform(0.04, 0.16), rng.uniform(-0.5, 0.5)
        d = np.abs((Y - y0) * math.cos(a) - (X - x0) * math.sin(a))
        dentro = (np.abs((X - x0) * math.cos(a) + (Y - y0) * math.sin(a)) < l) & (d < 0.0025)
        img[dentro] = img[dentro] * (0.55 if k % 2 else 1.3)
    for y0 in (0.18, 0.82):                                  # costuras
        punt = (np.abs(Y - y0) < 0.006) & ((np.floor(X * 40) % 2) == 0)
        img[punt] = img[punt] * 0.55
    return np.clip(img, 0, 1)


def v2_fibra_oscura(h, rng):
    return v2_fibra(h, rng, (0.36, 0.44, 0.32))


def v2_mojon(h, rng):
    """Arenisca del mojón: grano, golpes de cincel, vetas, desconchones claros y manchas de liquen salvia."""
    X, Y = _xy(h)
    f = E.fbm(h, rng, 5, 6)
    img = E.color((0.78, 0.74, 0.65)) * (0.80 + 0.30 * f[..., None])
    img = E.mezclar(img, (0.50, 0.46, 0.40), E.grietas(h, rng, 18, 0.0035) * 0.5)
    cincel = E.ruido(h, 70, rng)
    img = E.mezclar(img, (0.88, 0.85, 0.77), np.clip((cincel - 0.70) * 4, 0, 0.65))
    vet = np.abs(np.sin((Y * 7 + E.fbm(h, rng, 3, 3) * 1.5) * math.pi))
    img = E.mezclar(img, (0.66, 0.60, 0.50), np.clip((0.08 - vet) * 8, 0, 0.5))
    liquen = np.clip((E.fbm(h, rng, 9, 4) - 0.66) * 7, 0, 1)
    return E.mezclar(img, (0.62, 0.70, 0.50), liquen * 0.6)


def v2_madera(h, rng):
    X, Y = _xy(h)
    veta = E.ruido(h, 46, rng)[0][None, :] * np.ones((h, 1))
    f = E.fbm(h, rng, 3, 4)
    img = E.color((0.72, 0.56, 0.36)) * (0.70 + 0.42 * veta[..., None] * (0.7 + 0.3 * f[..., None]))
    img = E.mezclar(img, (0.42, 0.29, 0.17), E.grietas(h, rng, 12, 0.003) * 0.5)
    return E.mezclar(img, (0.86, 0.74, 0.55), np.clip((veta - 0.85) * 5, 0, 0.4))


def v2_banda(h, rng):
    X, Y = _xy(h)
    franja = (np.floor(Y * 4) % 2) > 0
    f = E.fbm(h, rng, 6, 4)
    img = np.where(franja[..., None], E.color((0.94, 0.92, 0.85)), E.color((0.76, 0.30, 0.15)))
    img = img * (0.86 + 0.18 * f[..., None])
    gastado = np.clip((E.fbm(h, rng, 9, 3) - 0.60) * 5, 0, 1)
    img = E.mezclar(img, (0.68, 0.54, 0.36), gastado * 0.8)
    return E.mezclar(img, (0.30, 0.22, 0.16), np.clip((0.008 - np.abs((Y * 4) % 1.0 - 0.0)) * 60, 0, 0.5))


def v2_franja(h, rng):
    tejido = v2_fibra(h, rng, (0.80, 0.82, 0.74))
    f = E.fbm(h, rng, 6, 4)
    img = E.mezclar(tejido, (0.95, 0.94, 0.89), np.clip(0.55 + (f - 0.5) * 2.5, 0, 0.92))
    return img


def v2_placa(h, rng):
    """Placas de arcilla cocida: incisiones de linde, muescas, desconchones y borde quemado."""
    X, Y = _xy(h)
    f = E.fbm(h, rng, 4, 5)
    img = E.color((0.62, 0.46, 0.34)) * (0.80 + 0.30 * f[..., None])
    for y0 in (0.22, 0.5, 0.78):
        img = E.mezclar(img, (0.34, 0.22, 0.15), np.clip((0.006 - np.abs(Y - y0)) * 180, 0, 0.85))
    muescas = (np.abs(((X * 7) % 1.0) - 0.5) < 0.035) & (np.abs(Y - 0.5) < 0.09)
    img[muescas] = img[muescas] * 0.5
    chip = np.clip((E.fbm(h, rng, 7, 3) - 0.70) * 6, 0, 1)
    img = E.mezclar(img, (0.78, 0.64, 0.50), chip * 0.6)
    return E.mezclar(img, (0.30, 0.20, 0.14), E.grietas(h, rng, 12, 0.004) * 0.45)


for nombre, f in (("barro", v2_barro), ("barro_oscuro", v2_barro_oscuro), ("fibra", v2_fibra),
                  ("fibra_oscura", v2_fibra_oscura), ("mojon", v2_mojon), ("madera", v2_madera),
                  ("banda", v2_banda), ("franja", v2_franja), ("placa", v2_placa)):
    A.celda(nombre, f)

# ================================================================== malla

m = C.Malla(None, ("atlas", "brillo"))
CR = E.caja_redonda


def pieza(vs, celda, pesos, escala=0.40, liso=True):
    return E.proyectar(m, A, vs, celda, escala, pesos, 0, liso)


def brillo(vs, hueso):
    for f in {f for v in vs for f in v.link_faces}:
        f.material_index = 1
        f.smooth = True
        for lp in f.loops:
            lp[m.uv].uv = (0.5, 0.5)
    m.pesar(vs, hueso)
    return vs


def giro(ax=0, ay=0, az=0):
    return Euler((math.radians(ax), math.radians(ay), math.radians(az)), 'XYZ')


def por_z(cadena):
    return lambda co: C.por_altura(co.z, cadena)


Zc = _hs["cadera"][0].z            # 0,63
Zp = _hs["pecho"][0].z
Zcu = _hs["cuello"][0].z
Zca = _hs["cabeza"][0].z
TRONCO = por_z([(Zc + 0.03, "cadera"), (_hs["columna_01"][0].z + 0.03, "columna_01"),
                (_hs["columna_02"][0].z + 0.05, "columna_02"), (Zp + 0.06, "pecho")])

for s, l in ((".L", 1), (".R", -1)):
    pierna = B.eje(arm, [("muslo" + s, 0.0), ("muslo" + s, 0.82), ("pierna" + s, 0.12), ("pierna" + s, 1.0)])
    h0, h1 = _hs["muslo" + s]
    k0, k1 = _hs["pierna" + s]
    ax = _hs["pie" + s][0].x
    # pierna de barro: muslo, rodilla, pantorrilla abultada y tobillo (12 lados, pesos suaves en la rodilla)
    pieza(m.tubo([h0 + Vector((0, 0, 0.03)), h0.lerp(h1, 0.5), k0, k0.lerp(k1, 0.38), k0.lerp(k1, 0.8)],
                 [0.100, 0.090, 0.070, 0.074, 0.060], 10), "barro", pierna, 0.32)
    # rodillera redonda de arcilla
    pieza(CR(m, k0 + Vector((0, -0.068, 0.005)), (0.105, 0.05, 0.10), giro(-10, 0, 0), redondez=0.85, cortes=2),
          "placa", "pierna" + s, 0.25)
    # polaina de fibra en la espinilla (rompe el tubo de la pierna) con dos vendas
    pieza(B.torno(m, k0.lerp(k1, 0.15), [(0.0, 0.070, 0.070), (-0.08, 0.080, 0.080), (-0.16, 0.074, 0.072),
                                         (-0.20, 0.068, 0.066)], 10, tapas=(False, False)), "fibra", "pierna" + s, 0.25)
    # bota: caña de fibra, pie redondo con puntera alzada y suela
    pieza(B.torno(m, (ax, 0.0, 0.085), [(0.0, 0.074, 0.074), (0.04, 0.078, 0.078), (0.09, 0.072, 0.070),
                                        (0.10, 0.066, 0.064)], 12, tapas=(False, False)), "fibra_oscura", "pierna" + s, 0.25)
    pie = B.mezcla(B.fijo("pie" + s), B.fijo("dedos" + s), lambda co: (-co.y - 0.06) / 0.07)
    pieza(CR(m, (ax, -0.035, 0.065), (0.15, 0.25, 0.115), redondez=0.80, cortes=2, ruido_amp=0.006,
             semilla=3 + l), "barro_oscuro", pie, 0.25)
    pieza(CR(m, (ax, -0.135, 0.06), (0.135, 0.10, 0.095), giro(12, 0, 0), redondez=0.9, cortes=2), "barro_oscuro",
          pie, 0.25)
    pieza(CR(m, (ax, -0.045, 0.014), (0.16, 0.29, 0.028), redondez=0.7, cortes=2), "placa", pie, 0.25)

    # brazo: hombrera abullonada, manga hasta el codo, antebrazo de barro y puño de fibra
    brazo = B.eje(arm, [("clavicula" + s, 0.5), ("brazo" + s, 0.0), ("brazo" + s, 0.85), ("antebrazo" + s, 0.15),
                        ("antebrazo" + s, 1.0)])
    b0, b1 = _hs["brazo" + s]
    a0, a1 = _hs["antebrazo" + s]
    pieza(CR(m, b0 + Vector((0.01 * l, 0.0, 0.0)), (0.13, 0.15, 0.11), giro(0, -20 * l, 0), redondez=0.9, cortes=2),
          "fibra", lambda co, s=s: {"clavicula" + s: 0.35, "brazo" + s: 0.65}, 0.28)
    pieza(m.tubo([b0, b0.lerp(b1, 0.5), b1, b1.lerp(a1, 0.12)], [0.062, 0.060, 0.056, 0.054], 12), "fibra", brazo, 0.28)
    pieza(m.tubo([b1.lerp(a0, 0.0) + (a1 - a0) * 0.05, a0.lerp(a1, 0.5), a1], [0.050, 0.047, 0.043], 12), "barro",
          brazo, 0.28)
    pieza(B.torno(m, a0.lerp(a1, 0.78) - Vector((0, 0, 0.03)), [(0.0, 0.054, 0.052), (0.05, 0.056, 0.054)], 12),
          "fibra_oscura", "antebrazo" + s, 0.22)
    # mitón: palma redonda más ancha hacia los dedos, pulgar, y el puño cerrado alrededor de la estaca
    P0 = PUNO[s]
    dm = (_hs["mano" + s][1] - _hs["mano" + s][0]).normalized()
    rot_mano = Vector((0, 0, -1)).rotation_difference(dm).to_euler()
    pieza(CR(m, P0 - dm * 0.005, (0.135, 0.125, 0.16), rot_mano, redondez=0.9, cortes=2, ruido_amp=0.004,
             semilla=5 + l, afinar=lambda z: 0.92 + 0.16 * (0.5 - z)), "barro_oscuro", "mano" + s, 0.22)
    pieza(m.esfera(P0 + Vector((-0.050 * l, -0.05, 0.03)), (0.034, 0.038, 0.05), (10, 8), giro(20, 0, 30 * l)),
          "barro_oscuro", "mano" + s, 0.22)

    # la estaca: madera de seis caras, punta embarrada, culata redonda y bandas ocre y blanca
    d = DIR_ESTACA[s]
    culata, punta = P0 - d * 0.20, P0 + d * 0.70
    ha = "arma" + s
    E.plano_uv(m, A, m.tubo([culata, P0 + d * 0.56], [(0.031, 0.031), (0.028, 0.028)], 6, ref=Vector((1, 0, 0))),
               "madera", culata, Vector((1, 0, 0)), d, 0.1, 0.5, ha)
    pieza(m.tubo([P0 + d * 0.56, P0 + d * 0.64, punta], [(0.028, 0.028), (0.020, 0.020), (0.003, 0.003)], 6),
          "barro_oscuro", ha, 0.2, liso=False)
    E.plano_uv(m, A, m.tubo([culata + d * 0.02, culata + d * 0.15], [0.034, 0.034], 6), "banda", culata,
               Vector((1, 0, 0)), d, 0.1, 0.14, ha)
    pieza(m.esfera(culata, (0.036, 0.036, 0.036), (8, 6)), "madera", ha, 0.2)

    # faldón: dos placas curvas por lado (delante y detrás), arriba con la cadera y abajo con el muslo
    for sy in (-1, 1):
        fald = (lambda co, s=s: {"cadera": max(0.0, min(1.0, (co.z - (Zc - 0.20)) / 0.22)) * 0.6 + 0.4,
                                 "muslo" + s: 0.6 - max(0.0, min(1.0, (co.z - (Zc - 0.20)) / 0.22)) * 0.6})
        vs = CR(m, (0.12 * l, 0.16 * sy, Zc - 0.15), (0.165, 0.032, 0.24), giro(16 * sy, -18 * l, 0), redondez=0.75,
                cortes=3)
        B.doblar(vs, (0.0, 0.005), 0.175)
        pieza(vs, "placa", fald, 0.25)

# cadera, chaqueta acampanada con pliegues (trapecio: la silueta triangular), su ribete y el cuello alto
pieza(CR(m, (0, 0.005, Zc + 0.02), (0.30, 0.22, 0.17), redondez=0.8, cortes=1), "barro", "cadera", 0.3)
HEM = Zc - 0.04
pieza(B.torno(m, (0, 0.012, HEM), [(0.0, 0.245, 0.190), (0.05, 0.240, 0.185), (0.14, 0.200, 0.158),
                                    (0.23, 0.172, 0.138), (0.33, 0.176, 0.134), (0.42, 0.166, 0.128),
                                    (0.47, 0.135, 0.108), (0.505, 0.090, 0.078)], 16, tapas=(True, False),
                 pliegues=(9, 0.07, 0.0, 0.17)), "fibra", TRONCO, 0.28)
pieza(B.torno(m, (0, 0.012, HEM - 0.012), [(0.0, 0.252, 0.196), (0.035, 0.256, 0.200), (0.05, 0.246, 0.192)], 18,
              tapas=(False, False), pliegues=(9, 0.07, 0.0, 0.05)), "fibra_oscura",
      por_z([(HEM, "cadera"), (HEM + 0.06, "columna_01")]), 0.25)
anillo = [(math.cos(a) * 0.105, 0.012 + math.sin(a) * 0.088, Zcu + 0.005) for a in np.linspace(0, 2 * math.pi, 15)]
pieza(m.tubo(anillo, [0.034] * 15, 8, tapas=(False, False)), "fibra_oscura",
      por_z([(Zcu - 0.02, "pecho"), (Zcu + 0.04, "cuello")]), 0.22)
pieza(CR(m, (0, -0.005, Zcu + 0.04), (0.10, 0.10, 0.10), redondez=0.8, cortes=1), "barro", "cuello", 0.25)

# capucha de fibra oscura, abierta por delante
CAB = Zca - 0.04
cap = B.torno(m, (0, 0.035, CAB), [(0.0, 0.12, 0.11), (0.06, 0.168, 0.152), (0.16, 0.180, 0.165),
                                    (0.25, 0.158, 0.148), (0.31, 0.10, 0.10), (0.335, 0.03, 0.03)], 14)
cap = B.borrar(m, cap, lambda co: co.y < -0.035 and CAB + 0.03 < co.z < CAB + 0.29)
pieza(cap, "fibra_oscura", por_z([(Zcu + 0.03, "cuello"), (CAB + 0.06, "cabeza")]), 0.22)

# la máscara de MOJÓN: piedra abombada, más estrecha en la barbilla, cara algo plana, coronilla redonda
MZ = CAB + 0.02
MY = -0.03
pieza(B.torno(m, (0, MY, MZ), [(0.0, 0.070, 0.060), (0.04, 0.100, 0.082), (0.10, 0.120, 0.094), (0.17, 0.124, 0.096),
                               (0.22, 0.119, 0.092), (0.27, 0.108, 0.084), (0.305, 0.090, 0.070), (0.33, 0.06, 0.048),
                               (0.345, 0.02, 0.018)], 16, frente_plano=0.22), "mojon", "cabeza", 0.18)
# la coronilla pintada de hito (ocre y blanco), un casquete encima
E.plano_uv(m, A, B.torno(m, (0, MY, MZ + 0.262), [(0.0, 0.113, 0.088), (0.03, 0.101, 0.079), (0.058, 0.066, 0.053),
                                                    (0.075, 0.022, 0.020)], 18, tapas=(False, True)),
           "banda", (0, 0, MZ + 0.25), Vector((1, 0, 0)), Vector((0, 0, 1)), 0.2, 0.09, "cabeza")
CARA = MY - 0.096 * 0.78                                   # el frente de la máscara a la altura de los pómulos
# ceja (un arco tallado), cuencas hundidas con ojos encendidos, nariz de cuña y la raya de la boca
ceja = [(x, CARA - 0.004 + 1.6 * x * x, MZ + 0.215 - 0.25 * abs(x)) for x in np.linspace(-0.095, 0.095, 9)]
pieza(m.tubo(ceja, [0.012] + [0.018] * 7 + [0.012], 8), "mojon", "cabeza", 0.15)
for l in (1, -1):
    pieza(m.esfera((0.046 * l, CARA + 0.012, MZ + 0.180), (0.032, 0.016, 0.024), (10, 8)), "barro_oscuro", "cabeza", 0.15)
    brillo(m.esfera((0.046 * l, CARA + 0.001, MZ + 0.180), (0.012, 0.006, 0.011), (8, 6)), "cabeza")
pieza(CR(m, (0, CARA - 0.012, MZ + 0.145), (0.034, 0.03, 0.062), giro(-12, 0, 0), redondez=0.7, cortes=1), "mojon",
      "cabeza", 0.15)
pieza(CR(m, (0, CARA + 0.004, MZ + 0.075), (0.07, 0.012, 0.012), redondez=0.6, cortes=1), "barro_oscuro", "cabeza", 0.15)
# la cruz de deslinde tallada en la frente
pieza(CR(m, (0, CARA + 0.012, MZ + 0.262), (0.06, 0.012, 0.012), redondez=0.6, cortes=1), "barro_oscuro", "cabeza", 0.15)
pieza(CR(m, (0, CARA + 0.012, MZ + 0.262), (0.012, 0.012, 0.05), redondez=0.6, cortes=1), "barro_oscuro", "cabeza", 0.15)

# la franja blanca vertical del pecho, pegada a la chaqueta (se busca su frente con rayos)
arbol = BVHTree.FromBMesh(m.bm)
pts, rads = [], []
for k_ in range(9):
    z = HEM + 0.07 + k_ * 0.045
    hit = arbol.ray_cast(Vector((0, -1.0, z)), Vector((0, 1, 0)), 2.0)
    y = hit[0].y if hit[0] is not None else -0.13
    pts.append((0, y - 0.005, z))
    rads.append((0.038, 0.007))
E.plano_uv(m, A, m.tubo(pts, rads, 6, ref=Vector((1, 0, 0))), "franja", (0, 0, HEM), Vector((1, 0, 0)),
           Vector((0, 0, 1)), 0.12, 0.4, TRONCO)

# las dos estacas de repuesto cruzadas a la espalda, con su abrazadera
for l in (1, -1):
    a = Vector((0.15 * l, 0.165, Zp + 0.13))
    b = Vector((-0.12 * l, 0.15, HEM + 0.06))
    d = (b - a).normalized()
    E.plano_uv(m, A, m.tubo([a, b - d * 0.10], [0.022, 0.022], 6), "madera", a, Vector((1, 0, 0)), d, 0.1, 0.5, "pecho")
    pieza(m.tubo([b - d * 0.10, b], [0.022, 0.003], 6), "barro_oscuro", "pecho", 0.2, liso=False)
    E.plano_uv(m, A, m.tubo([a + d * 0.01, a + d * 0.12], [0.025, 0.025], 6), "banda", a, Vector((1, 0, 0)), d, 0.1,
               0.12, "pecho")
pieza(CR(m, (0, 0.17, (Zp + HEM) / 2 + 0.06), (0.11, 0.05, 0.09), redondez=0.8, cortes=2), "fibra_oscura", "pecho", 0.22)
