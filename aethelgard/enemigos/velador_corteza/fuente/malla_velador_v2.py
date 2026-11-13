# e02 · Velador de Corteza v2 (13/11/2026, segunda pasada de arte): malla, atlas detallado y mapa de normales.
# Lo ejecuta crear_velador_corteza.py con «v2» (exec en su espacio de nombres: m, A, B, E, C, arm, _hs, PUNO_R,
# ESCUDO_C, DIR_MAZA…). Frente a la v1 (que se conserva): proporciones compactas (piernas ×0,74, cabeza ×1,25, brazos
# ×0,9), tronco de torno con surcos y PLACAS de corteza curvadas encima, tocón por cabeza con la máscara oval de corcho
# abombada y su reborde, escudo de anillos con canto redondo y bollón de nudo, maza de poda con mango encordado, cabeza
# nudosa y hoja de podadera curva, piernas de tronco que acaban en raíces.

A = E.AtlasV12(1024, 3, semilla=223)


def _xy(h):
    yy, xx = np.mgrid[0:h, 0:h]
    return (xx + 0.5) / h, (yy + 0.5) / h


def v2_corteza(h, rng, base=(0.36, 0.27, 0.20), musgo=0.35):
    X, Y = _xy(h)
    torcido = E.fbm(h, rng, 3, 4)
    onda = np.abs(np.sin((X * 6 + 1.2 * torcido + 0.25 * E.fbm(h, rng, 9, 3)) * math.pi))
    placas = E.grietas(h, rng, 14, 0.010)
    f = E.fbm(h, rng, 5, 6)
    img = E.color(base) * (0.62 + 0.48 * onda[..., None] * (0.7 + 0.4 * f[..., None]))
    img = E.mezclar(img, (0.58, 0.47, 0.35), np.clip((onda - 0.82) * 5, 0, 0.65))
    profundo = np.maximum(np.clip((0.2 - onda) * 6, 0, 1), placas * 0.85)
    img = E.mezclar(img, (0.10, 0.07, 0.05), profundo * 0.85)
    liquen = np.clip((E.fbm(h, rng, 10, 3) - 0.68) * 6, 0, 1) * (1 - profundo)
    img = E.mezclar(img, (0.62, 0.66, 0.52), liquen * 0.45)
    m_ = np.clip((E.fbm(h, rng, 7, 4) - (1.0 - musgo)) * 6, 0, 1) * profundo
    return E.mezclar(img, (0.20, 0.58, 0.52), m_)


def v2_corteza_clara(h, rng):
    return v2_corteza(h, rng, (0.50, 0.40, 0.30), 0.2)


def v2_anillos(h, rng):
    X, Y = _xy(h)
    cx, cy = 0.5 + rng.uniform(-0.03, 0.03), 0.5 + rng.uniform(-0.03, 0.03)
    r = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
    ang = np.arctan2(Y - cy, X - cx)
    dist = r * (1 + 0.04 * np.sin(ang * 5) + 0.05 * (E.fbm(h, rng, 4, 3) - 0.5))
    anillo = 0.5 + 0.5 * np.sin(dist * 2 * math.pi * 26)
    f = E.fbm(h, rng, 8, 4)
    img = E.color((0.76, 0.60, 0.41)) * (0.80 + 0.22 * anillo[..., None]) * (0.92 + 0.12 * f[..., None])
    img = E.mezclar(img, (0.50, 0.34, 0.22), np.clip((anillo - 0.86) * 6, 0, 0.75))
    for k in range(6):
        a0 = rng.uniform(-math.pi, math.pi)
        d = np.abs(((ang - a0 + math.pi) % (2 * math.pi)) - math.pi)
        img = E.mezclar(img, (0.18, 0.12, 0.08), np.clip((0.018 - d * r) * 140, 0, 1) * (r > 0.07) * (r < 0.41))
    img = E.mezclar(img, (0.30, 0.22, 0.16), np.clip((r - 0.44) * 30, 0, 1))
    return E.mezclar(img, (0.40, 0.28, 0.16), np.clip((0.035 - r) * 40, 0, 1))


def v2_corcho(h, rng):
    f = E.fbm(h, rng, 7, 5)
    img = E.color((0.78, 0.60, 0.42)) * (0.80 + 0.32 * f[..., None])
    poros = rng.random((h, h)) < 0.035
    img[poros] = img[poros] * 0.45
    f1, f2 = E.celdas_voronoi(h, rng, 46)
    img = E.mezclar(img, (0.46, 0.32, 0.20), np.clip((0.018 - (f2 - f1)) * 45, 0, 0.65))
    return E.mezclar(img, (0.90, 0.76, 0.58), np.clip((f - 0.7) * 3, 0, 0.4))


def v2_musgo(h, rng):
    f = E.fbm(h, rng, 9, 5)
    img = E.color((0.16, 0.44, 0.38)) * (0.58 + 0.62 * f[..., None])
    motas = rng.random((h, h)) < 0.06
    img[motas] = np.clip(img[motas] * 1.4, 0, 1)
    return img


def v2_madera(h, rng):
    X, Y = _xy(h)
    veta = E.ruido(h, 40, rng)[0][None, :] * np.ones((h, 1))
    img = E.color((0.56, 0.42, 0.28)) * (0.70 + 0.42 * veta[..., None])
    return E.mezclar(img, (0.30, 0.20, 0.13), E.grietas(h, rng, 12, 0.003) * 0.5)


def v2_nudo(h, rng):
    X, Y = _xy(h)
    f = E.fbm(h, rng, 3, 5)
    rem = np.sin((X * 6 + f * 4) * math.pi) * np.cos((Y * 5 + f * 3) * math.pi)
    img = E.color((0.32, 0.22, 0.15)) * (0.72 + 0.38 * (0.5 + 0.5 * rem)[..., None])
    return E.mezclar(img, (0.14, 0.10, 0.07), E.grietas(h, rng, 16, 0.005) * 0.65)


def v2_hierro(h, rng):
    X, Y = _xy(h)
    f = E.fbm(h, rng, 6, 4)
    img = E.color((0.30, 0.31, 0.32)) * (0.74 + 0.4 * f[..., None])
    img = E.mezclar(img, (0.50, 0.30, 0.17), np.clip((E.fbm(h, rng, 5, 3) - 0.58) * 4, 0, 0.75))
    return E.mezclar(img, (0.74, 0.75, 0.74), np.clip((Y - 0.84) * 8, 0, 0.85))


def v2_cuero(h, rng):
    """Cuerda de corteza trenzada del mango: espiras diagonales."""
    X, Y = _xy(h)
    esp = 0.5 + 0.5 * np.sin((X + Y) * math.pi * 2 * 10)
    f = E.fbm(h, rng, 5, 4)
    return E.color((0.42, 0.32, 0.22)) * (0.62 + 0.42 * esp[..., None]) * (0.88 + 0.2 * f[..., None])


for nombre, f in (("corteza", v2_corteza), ("corteza_clara", v2_corteza_clara), ("anillos", v2_anillos),
                  ("corcho", v2_corcho), ("musgo", v2_musgo), ("madera", v2_madera), ("nudo", v2_nudo),
                  ("hierro", v2_hierro), ("cuero", v2_cuero)):
    A.celda(nombre, f)

m = C.Malla(None, ("atlas", "brillo"))
CR = E.caja_redonda


def pieza(vs, celda, pesos, escala=0.45, liso=True):
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


Zc = _hs["cadera"][0].z
Zp = _hs["pecho"][0].z
Zcu = _hs["cuello"][0].z
Zca = _hs["cabeza"][0].z
TRONCO = por_z([(Zc + 0.04, "cadera"), (_hs["columna_01"][0].z + 0.04, "columna_01"),
                (_hs["columna_02"][0].z + 0.06, "columna_02"), (Zp + 0.08, "pecho")])

for s, l in ((".L", 1), (".R", -1)):
    pierna = B.eje(arm, [("muslo" + s, 0.0), ("muslo" + s, 0.82), ("pierna" + s, 0.12), ("pierna" + s, 1.0)])
    h0, h1 = _hs["muslo" + s]
    k0, k1 = _hs["pierna" + s]
    ax = _hs["pie" + s][0].x
    # pierna de tronco, más gruesa abajo, con su placa de rodilla curvada
    pieza(m.tubo([h0 + Vector((0, 0, 0.04)), h0.lerp(h1, 0.5), k0, k0.lerp(k1, 0.5), k1 + Vector((0, 0, 0.02))],
                 [0.125, 0.115, 0.098, 0.108, 0.118], 10), "corteza", pierna, 0.42)
    vs = CR(m, k0 + Vector((0, -0.10, 0.0)), (0.17, 0.05, 0.16), giro(-10, 0, 0), redondez=0.7, cortes=2,
            ruido_amp=0.008, semilla=5 + l)
    B.doblar(vs, (k0.x, k0.y), 0.105)
    pieza(vs, "corteza_clara", "pierna" + s, 0.3)
    # pie de raíz: un tocón ancho y cuatro raíces curvas que se clavan delante y a los lados
    pie = B.mezcla(B.fijo("pie" + s), B.fijo("dedos" + s), lambda co: (-co.y - 0.10) / 0.10)
    pieza(B.torno(m, (ax, -0.02, 0.0), [(0.0, 0.16, 0.20), (0.06, 0.15, 0.19), (0.12, 0.125, 0.15), (0.16, 0.11, 0.12)], 12,
                  pliegues=(7, 0.10, 0.0, 0.16)), "corteza_clara", pie, 0.35)
    for j, (dx, dy) in enumerate(((-0.10, -0.12), (-0.03, -0.20), (0.05, -0.19), (0.11, -0.10))):
        pieza(m.tubo([(ax + dx * 0.4, -0.02 + dy * 0.4, 0.07), (ax + dx * 0.9, -0.02 + dy * 0.9, 0.05),
                      (ax + dx * 1.25, -0.02 + dy * 1.25, 0.01)], [0.045, 0.032, 0.010], 6), "corteza", pie, 0.3)
    # brazos: tronco con la placa del codo y el puño de nudo
    brazo = B.eje(arm, [("clavicula" + s, 0.5), ("brazo" + s, 0.0), ("brazo" + s, 0.85), ("antebrazo" + s, 0.15),
                        ("antebrazo" + s, 1.0)])
    b0, b1 = _hs["brazo" + s]
    a0, a1 = _hs["antebrazo" + s]
    pieza(m.tubo([b0 + Vector((0, 0, 0.02)), b0.lerp(b1, 0.5), b1, a0.lerp(a1, 0.5), a1],
                 [0.105, 0.095, 0.085, 0.082, 0.075], 10), "corteza", brazo, 0.42)
    vs = CR(m, b1 + Vector((0, 0.085, 0)), (0.16, 0.06, 0.16), redondez=0.7, cortes=2, ruido_amp=0.008, semilla=7 + l)
    B.doblar(vs, (b1.x, b1.y), 0.09)
    pieza(vs, "corteza_clara", "antebrazo" + s, 0.3)
    mano0, mano1 = _hs["mano" + s]
    pieza(E.roca(m, mano0.lerp(mano1, 0.5), 0.095, 9 + l, 2, 0.15, (1.0, 1.05, 1.2)), "nudo", "mano" + s, 0.3)

# tronco: barril de corteza con surcos, ancho de pecho (defensor), y placas de corteza curvadas encima
pieza(B.torno(m, (0, 0.0, Zc - 0.10), [(0.0, 0.25, 0.20), (0.10, 0.27, 0.21), (0.24, 0.27, 0.20), (0.40, 0.30, 0.22),
                                       (0.56, 0.32, 0.23), (0.66, 0.28, 0.21), (0.73, 0.18, 0.15), (0.76, 0.10, 0.10)], 16,
              tapas=(True, False), pliegues=(11, 0.06, 0.0, 0.76)), "corteza", TRONCO, 0.45)
for (cx, cz, w, hh, sy) in ((-0.13, Zp + 0.10, 0.21, 0.22, -1), (0.13, Zp + 0.10, 0.21, 0.22, -1),
                            (0.0, Zc + 0.17, 0.30, 0.18, -1), (-0.12, Zp + 0.06, 0.22, 0.28, 1), (0.12, Zp + 0.06, 0.22, 0.28, 1)):
    vs = CR(m, (cx, 0.23 * sy, cz), (w, 0.05, hh), giro(8 * sy, 0, 0), redondez=0.6, cortes=2, ruido_amp=0.01,
            semilla=int(cz * 100 + cx * 10))
    B.doblar(vs, (0.0, 0.0), 0.245)
    pieza(vs, "corteza_clara", TRONCO, 0.35)
# faldón de tiras de corteza
for sy in (-1, 1):
    for l in (1, -1):
        s = ".L" if l == 1 else ".R"
        vs = CR(m, (0.13 * l, 0.19 * sy, Zc - 0.12), (0.18, 0.05, 0.26), giro(12 * sy, -10 * l, 0), redondez=0.6, cortes=2,
                ruido_amp=0.01, semilla=15 + l + sy)
        B.doblar(vs, (0.0, 0.0), 0.215)
        pieza(vs, "corteza_clara", lambda co, s=s: {"cadera": 0.6, "muslo" + s: 0.4}, 0.3)
# musgo: matas aplanadas en hombros, pecho y espalda
for p0, r0 in (((0.22, -0.20, Zp + 0.20), 0.09), ((-0.16, -0.22, Zp - 0.10), 0.07), ((0.26, 0.14, Zp + 0.22), 0.10),
               ((-0.05, 0.24, Zc + 0.10), 0.07)):
    pieza(E.roca(m, p0, r0 * 0.75, int(p0[2] * 100), 2, 0.35, (1.7, 0.18, 1.1)), "musgo", TRONCO, 0.15)
# el ALERO del hombro derecho: dos tablas de corteza en pico, con los cantos redondeados; y la hombrera izquierda
cR = _hs["brazo.R"][0]
for j, (dx, rz) in enumerate(((0.02, 32), (-0.10, 4))):
    pieza(CR(m, (cR.x + dx, 0.0, cR.z + 0.12 - j * 0.05), (0.22, 0.42, 0.05), giro(0, rz, 0), redondez=0.55, cortes=2,
             ruido_amp=0.008, semilla=20 + j), "corteza_clara", lambda co: {"clavicula.R": 0.5, "brazo.R": 0.5}, 0.35)
cL = _hs["brazo.L"][0]
pieza(CR(m, (cL.x, 0.0, cL.z + 0.06), (0.22, 0.30, 0.12), giro(0, -22, 0), redondez=0.75, cortes=2), "corteza_clara",
      lambda co: {"clavicula.L": 0.5, "brazo.L": 0.5}, 0.35)
# cuello y cabeza: un tocón con los anillos arriba y dos ramas cortadas
pieza(CR(m, (0, 0.0, Zcu + 0.03), (0.22, 0.22, 0.12), redondez=0.7, cortes=1), "corteza", "cuello", 0.3)
TOC = Zca - 0.02
pieza(B.torno(m, (0, 0.03, TOC), [(0.0, 0.17, 0.16), (0.10, 0.185, 0.17), (0.20, 0.175, 0.16), (0.27, 0.16, 0.15)], 14,
              tapas=(False, False), pliegues=(9, 0.07, 0.0, 0.33)), "corteza", por_z([(Zcu + 0.05, "cuello"),
                                                                                         (TOC + 0.05, "cabeza")]), 0.35)
E.plano_uv(m, A, B.torno(m, (0, 0.03, TOC + 0.27), [(0.0, 0.16, 0.15), (0.01, 0.13, 0.12), (0.012, 0.0, 0.0)], 14,
                         tapas=(False, False)), "anillos", (-0.16, -0.13, 0), Vector((1, 0, 0)), Vector((0, 1, 0)), 0.32,
           0.32, "cabeza")
for l, hh in ((1, 0.14), (-1, 0.09)):
    pieza(m.tubo([(0.07 * l, 0.05, TOC + 0.25), (0.12 * l, 0.07, TOC + 0.25 + hh)], [0.035, 0.024], 7), "corteza_clara",
          "cabeza", 0.3)
    E.plano_uv(m, A, m.esfera((0.12 * l, 0.07, TOC + 0.25 + hh), (0.024, 0.024, 0.008), (8, 4)), "anillos",
               (0.12 * l - 0.03, 0.04, 0), Vector((1, 0, 0)), Vector((0, 1, 0)), 0.06, 0.06, "cabeza")
# la máscara OVAL de corcho, abombada, con su reborde, cuencas y ojos de musgo encendido, y la boca de corteza
MZ = TOC - 0.01
MY = -0.13
pieza(B.torno(m, (0, MY, MZ), [(0.0, 0.05, 0.035), (0.035, 0.12, 0.07), (0.10, 0.158, 0.088), (0.17, 0.165, 0.09),
                               (0.24, 0.152, 0.084), (0.30, 0.11, 0.064), (0.33, 0.05, 0.035)], 14, frente_plano=0.35),
      "corcho", "cabeza", 0.2)
borde = [(math.sin(a) * 0.160, MY - 0.005, MZ + 0.17 + math.cos(a) * 0.165) for a in np.linspace(0, 2 * math.pi, 17)]
pieza(m.tubo(borde, [0.016] * 17, 6, tapas=(False, False)), "corteza", "cabeza", 0.2)
CARA = MY - 0.09 * 0.65
for l in (1, -1):
    pieza(m.esfera((0.058 * l, CARA + 0.008, MZ + 0.20), (0.038, 0.014, 0.045), (10, 8)), "nudo", "cabeza", 0.15)
    brillo(m.esfera((0.058 * l, CARA - 0.004, MZ + 0.20), (0.017, 0.007, 0.021), (8, 6)), "cabeza")
pieza(CR(m, (0, CARA + 0.002, MZ + 0.09), (0.10, 0.016, 0.018), redondez=0.6, cortes=1), "nudo", "cabeza", 0.15)

# el escudo de anillos: rodaja de tronco con canto redondo, cara de anillos hacia fuera y bollón de nudo
EN = Vector((1, 0, 0))
c0 = ESCUDO_C
disco = m.tubo([c0 - EN * 0.035, c0 - EN * 0.02, c0 + EN * 0.03, c0 + EN * 0.05, c0 + EN * 0.058],
               [(0.27, 0.27), (0.305, 0.305), (0.31, 0.31), (0.30, 0.30), (0.285, 0.285)], 20, tapas=(True, True),
               ref=Vector((0, 0, 1)))
cara = [v for v in disco if (v.co - c0).dot(EN) > 0.054]
canto = [v for v in disco if (v.co - c0).dot(EN) <= 0.054]
E.plano_uv(m, A, cara, "anillos", c0 - Vector((0, 0.30, 0.30)), Vector((0, 1, 0)), Vector((0, 0, 1)), 0.60, 0.60, "arma.L")
pieza(canto, "corteza", "arma.L", 0.3)
pieza(E.roca(m, c0 + EN * 0.075, 0.06, 33, 2, 0.15, (0.6, 1.0, 1.0)), "nudo", "arma.L", 0.2)
pieza(E.roca(m, c0 + EN * 0.06 + Vector((0, -0.14, 0.17)), 0.06, 31, 2, 0.3, (0.4, 1.2, 1.0)), "musgo", "arma.L", 0.15)

# la maza de poda: mango encordado, cabeza de raíz nudosa con nudos y la hoja curva de la podadera en el canto
mango0 = PUNO_R - DIR_MAZA * 0.12
mango1 = PUNO_R + DIR_MAZA * 0.52
E.plano_uv(m, A, m.tubo([mango0, mango1], [0.028, 0.026], 8), "madera", mango0, Vector((1, 0, 0)), DIR_MAZA, 0.1, 0.6,
           "arma.R")
E.plano_uv(m, A, m.tubo([mango0 + DIR_MAZA * 0.03, mango0 + DIR_MAZA * 0.16], [0.033, 0.033], 8), "cuero", mango0,
           Vector((1, 0, 0)), DIR_MAZA, 0.1, 0.15, "arma.R")
cab = PUNO_R + DIR_MAZA * 0.68
rot = Vector((0, 0, 1)).rotation_difference(DIR_MAZA).to_euler()
pieza(E.roca(m, cab, 0.14, 41, 2, 0.16, (1.0, 1.0, 1.35), rot), "nudo", "arma.R", 0.3)
for j, (u, v_) in enumerate(((0.12, 0.05), (-0.10, 0.08), (0.02, -0.12))):
    lado1 = DIR_MAZA.orthogonal().normalized()
    lado2 = DIR_MAZA.cross(lado1)
    pieza(E.roca(m, cab + lado1 * u + lado2 * v_ + DIR_MAZA * (0.04 * j - 0.04), 0.05, 50 + j, 1, 0.2), "nudo", "arma.R", 0.2)
lado = DIR_MAZA.cross(Vector((1, 0, 0))).normalized()
hoja = [cab + lado * 0.11 + DIR_MAZA * (-0.12 + 0.26 * t) + lado * 0.12 * math.sin(math.pi * t * 0.9) for t in
        (0, 0.25, 0.5, 0.75, 1)]
pieza(m.tubo(hoja, [(0.055, 0.009), (0.065, 0.008), (0.06, 0.007), (0.04, 0.005), (0.006, 0.003)], 4,
             ref=Vector((1, 0, 0))), "hierro", "arma.R", 0.2, liso=False)
