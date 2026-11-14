# Nix vestuario (V12, 14/11): los dibujos de la ropa, calculados en coordenadas del cuerpo (metros, en reposo: mira a
# -Y, su izquierda es +X, pies en z = 0). Colores en sRGB (como se guardan en el PNG).
#   pintar(P3, N3, PR, PZ, ID) -> color (N,3), rugosidad (N,), metal (N,)
# Paleta del canon: negro, púrpura oscuro y dorado envejecido; amatistas.
import math
import numpy as np
import p8_pintura as PT

NEGRO = np.array([0.052, 0.043, 0.058], np.float32)
NEGRO_C = np.array([0.080, 0.052, 0.095], np.float32)        # corpiño: negro con un punto de púrpura
PURPURA = np.array([0.36, 0.12, 0.52], np.float32)           # forro
PURPURA_O = np.array([0.16, 0.055, 0.22], np.float32)
ORO = np.array([0.76, 0.58, 0.30], np.float32)               # dorado envejecido
ORO_O = np.array([0.50, 0.36, 0.17], np.float32)
CUERO = np.array([0.24, 0.145, 0.095], np.float32)
AMATISTA = np.array([0.58, 0.22, 0.88], np.float32)
AA = 0.0011                                                   # medio texel de 2048 en metros (aprox.)


class Capa:
    """Color, rugosidad y metal de un grupo de texeles, con composición por cobertura."""

    def __init__(self, n, base, rug, met=0.0):
        self.c = np.tile(base, (n, 1)).astype(np.float32)
        self.r = np.full(n, rug, np.float32)
        self.m = np.full(n, met, np.float32)

    def poner(self, a, color, rug, met):
        a = np.clip(a, 0, 1).astype(np.float32)
        if not np.any(a > 0):
            return
        col = np.broadcast_to(np.asarray(color, np.float32), self.c.shape)
        self.c = self.c * (1 - a[:, None]) + col * a[:, None]
        self.r = self.r * (1 - a) + rug * a
        self.m = self.m * (1 - a) + met * a

    def oro(self, a, P3=None):
        if P3 is not None:
            v = 0.88 + 0.12 * PT.ruido(P3, 7, 2.0)[:, None]
            col = np.clip(ORO * v, 0, 1)
        else:
            col = ORO
        self.poner(a, col, 0.36, 1.0)

    def gema(self, a):
        self.poner(a, AMATISTA, 0.12, 0.0)


def tela(P3, base, semilla, fuerza=0.10):
    n = PT.ruido(P3, semilla, 1.0) * fuerza + PT.ruido(P3, semilla + 11, 5.0) * fuerza * 0.4
    return np.clip(base[None, :] * (1.0 + n[:, None]), 0, 1)


def banda(d, a, b):
    """Cobertura de la franja a <= d <= b (con antialias)."""
    return np.clip((d - a) / AA * 0.5 + 0.5, 0, 1) * np.clip((b - d) / AA * 0.5 + 0.5, 0, 1)


def rombo(Q, c, rx, ry):
    """Cobertura de un rombo centrado en c (2D) de semiejes rx, ry."""
    q = np.abs(Q - np.asarray(c, np.float32))
    f = q[:, 0] / rx + q[:, 1] / ry
    return np.clip((1.0 - f) * min(rx, ry) / AA * 0.5 + 0.5, 0, 1)


def estrella4(Q, c, r):
    """Estrella de cuatro puntas (astroide)."""
    q = np.abs(Q - np.asarray(c, np.float32)) / r
    f = np.sqrt(q[:, 0] + 1e-9) + np.sqrt(q[:, 1] + 1e-9)
    return np.clip((1.0 - f) * r * 0.5 / AA * 0.5 + 0.5, 0, 1)


def circulo(Q, c, r):
    d = np.linalg.norm(Q - np.asarray(c, np.float32), axis=1)
    return np.clip((r - d) / AA * 0.5 + 0.5, 0, 1)


def enredadera_en(Q, largo, desde, eje_b, onda, paso, semilla, grosor=0.0016, fase=0.0, hojas=True):
    """Cobertura de una enredadera dorada: Q (N,2) en coordenadas (a a lo largo, b de lado); el tallo empieza en
    a = desde y ondula alrededor de b = eje_b."""
    tallo, hs = PT.enredadera(largo, onda, paso, semilla, fase)
    tallo = tallo + np.array([desde, eje_b], np.float32)
    caja = (Q[:, 0] > desde - 0.03) & (Q[:, 0] < desde + largo + 0.03) & (np.abs(Q[:, 1] - eje_b) < onda + paso * 0.5)
    a = np.zeros(Q.shape[0], np.float32)
    if not caja.any():
        return a
    q = Q[caja]
    cov = PT.trazo(PT.d_segmentos(q, tallo), grosor, AA)
    if hojas:
        for (cx, cy), ang, L, wd in hs:
            cov = np.maximum(cov, PT.hoja(q, (cx + desde, cy + eje_b), ang, L, wd))
    a[caja] = cov
    return a


# ---------------------------------------------------------------- emblema de la espalda
def emblema(Q, c, R):
    """Ojo de Horus dentro de una estrella de SEIS puntas hecha con dos triángulos (no pentagrama). Q en coordenadas de
    la imagen vista desde detrás (X a la derecha de quien mira, Z arriba)."""
    cx, cz = c
    a = np.zeros(Q.shape[0], np.float32)
    caja = (np.abs(Q[:, 0] - cx) < R * 1.1) & (np.abs(Q[:, 1] - cz) < R * 1.1)
    if not caja.any():
        return a
    q = Q[caja]
    g = 0.0042
    cov = np.zeros(q.shape[0], np.float32)
    for desfase in (90.0, 270.0):                          # triángulo hacia arriba y hacia abajo
        pts = [(cx + R * math.cos(math.radians(desfase + k * 120)), cz + R * math.sin(math.radians(desfase + k * 120)))
               for k in range(4)]
        cov = np.maximum(cov, PT.trazo(PT.d_segmentos(q, pts), g, AA))
    # el ojo
    ew, eh_s, eh_i = 0.036, 0.017, 0.011
    xs = np.linspace(-ew, ew, 40)
    sup = [(cx + x, cz + 0.002 + eh_s * (1 - (x / ew) ** 2) ** 0.8) for x in xs]
    inf = [(cx + x, cz + 0.002 - eh_i * (1 - (x / ew) ** 2) ** 0.9) for x in xs]
    cov = np.maximum(cov, PT.trazo(PT.d_segmentos(q, sup), 0.0026, AA))
    cov = np.maximum(cov, PT.trazo(PT.d_segmentos(q, inf), 0.0022, AA))
    # ceja
    ceja = [(cx - ew * 1.02 + 2 * ew * 1.02 * k / 20, cz + 0.030 + 0.006 * math.sin(math.pi * k / 20)) for k in range(21)]
    cov = np.maximum(cov, PT.trazo(PT.d_segmentos(q, ceja), 0.0024, AA))
    # iris (aro dorado y centro oscuro)
    d = np.linalg.norm(q - np.array([cx + 0.002, cz + 0.002], np.float32), axis=1)
    cov = np.maximum(cov, PT.trazo(np.abs(d - 0.0085), 0.0022, AA))
    cov = np.maximum(cov, np.clip((0.0035 - d) / AA * 0.5 + 0.5, 0, 1))
    # la lágrima (línea vertical) y la espiral de la mejilla
    cov = np.maximum(cov, PT.trazo(PT.d_segmentos(q, [(cx - 0.004, cz - 0.008), (cx - 0.006, cz - 0.034)]), 0.0022, AA))
    esp = []
    for k in range(40):
        t = k / 39.0
        ang = -math.pi / 2 + t * 2.6 * math.pi
        r = 0.016 * (1 - t * 0.75)
        esp.append((cx + 0.010 + t * 0.020 + r * math.cos(ang) * 0.6, cz - 0.016 - t * 0.010 + r * math.sin(ang) * 0.5))
    cov = np.maximum(cov, PT.trazo(PT.d_segmentos(q, [(cx + 0.010, cz - 0.008)] + esp), 0.0020, AA))
    a[caja] = cov
    return a


# ---------------------------------------------------------------- piezas
def p_cuerpo(L, P3, N3, PR):
    x, y, z = P3[:, 0], P3[:, 1], P3[:, 2]
    L.c = np.where((z > 1.075)[:, None], tela(P3, NEGRO_C, 1), tela(P3, NEGRO, 2))
    L.r[:] = 0.80
    delante = y < 0
    # cuello: ribete dorado arriba
    L.oro(banda(z, 1.531, 1.546) , P3)
    # costuras de princesa doradas (delante)
    xs = 0.040 + 0.040 * np.clip((z - 1.08) / 0.32, 0, 1) ** 1.4
    L.oro(PT.trazo(np.abs(np.abs(x) - xs), 0.0016, AA) * delante * (z > 1.08) * (z < 1.44), P3)
    # cierre central y broches
    L.oro(PT.trazo(np.abs(x), 0.0018, AA) * delante * (z > 1.08) * (z < 1.49), P3)
    Q = np.stack([x, z], -1)
    for zc in (1.18, 1.28, 1.38):
        br = np.clip((0.026 - np.abs(x)) / AA * 0.5 + 0.5, 0, 1) * np.clip((0.0055 - np.abs(z - zc)) / AA * 0.5 + 0.5, 0, 1)
        L.oro(br * delante, P3)
        L.poner(circulo(Q, (0.0, zc), 0.0035) * delante, ORO_O, 0.4, 1.0)
    # amatista del cuello con su engaste
    L.oro(rombo(Q, (0.0, 1.497), 0.016, 0.024) * delante, P3)
    L.gema(rombo(Q, (0.0, 1.497), 0.011, 0.018) * delante)
    # cinturones de cuero: uno recto y otro en diagonal; hebilla dorada con amatista
    L.poner(banda(z, 1.036, 1.072), CUERO, 0.62, 0.0)
    zb = 1.000 + 0.075 * (x + 0.2) / 0.4
    L.poner(banda(z - zb, -0.011, 0.011) * (z < 1.085), CUERO * 0.85, 0.62, 0.0)
    for borde in (1.037, 1.071):
        L.poner(PT.trazo(np.abs(z - borde), 0.0007, AA) * 0.6, CUERO * 0.5, 0.7, 0.0)
    heb = np.clip((0.024 - np.abs(x)) / AA * 0.5 + 0.5, 0, 1) * np.clip((0.017 - np.abs(z - 1.054)) / AA * 0.5 + 0.5, 0, 1)
    L.oro(heb * delante, P3)
    L.gema(rombo(Q, (0.0, 1.054), 0.009, 0.011) * delante)
    # emblema dorado de la espalda (visto desde detrás: X de la imagen = -x)
    Qe = np.stack([-x, z], -1)
    L.oro(emblema(Qe, (0.0, 1.228), 0.086) * (y > 0.0) * (N3[:, 1] > 0.15), P3)


def p_mangas(L, P3, N3, PR):
    x, y, z = P3[:, 0], P3[:, 1], P3[:, 2]
    L.c = tela(P3, NEGRO, 3)
    L.r[:] = 0.78
    s = np.abs(x)
    phi = np.arctan2(z - 1.463, -(y - 0.004))           # 0 delante, +pi/2 arriba
    a = phi * 0.045
    # puño: dos franjas doradas
    L.oro(banda(s, 0.600, 0.607) + banda(s, 0.615, 0.623), P3)
    L.oro(PT.trazo(np.abs(s - 0.398), 0.0012, AA), P3)
    # enredadera por encima del antebrazo
    Q = np.stack([s, a], -1)
    L.oro(enredadera_en(Q, 0.15, 0.43, math.pi / 2 * 0.045, 0.010, 0.055, 4, 0.0013), P3)


def ejes_pierna(P3, lado):
    x, y, z = P3[:, 0], P3[:, 1], P3[:, 2]
    t = np.clip((1.01 - z) / (1.01 - 0.085), 0, 1)
    cx = lado * (0.095 + (0.121 - 0.095) * t)
    cy = -0.01 + (0.012 + 0.01) * t
    phi = np.arctan2(lado * (x - cx), -(y - cy))      # 0 delante, + hacia fuera
    return phi, z


def p_media(L, P3, N3, PR, lado):
    L.c = tela(P3, NEGRO, 5 if lado > 0 else 4, 0.06)
    L.r[:] = 0.55
    phi, z = ejes_pierna(P3, lado)
    a = phi * 0.055
    Q = np.stack([a, z], -1)
    # liga dorada arriba con rombos
    L.oro(banda(z, 0.922, 0.932), P3)
    for k in range(12):
        L.oro(rombo(np.stack([phi, z], -1), (-math.pi + (k + 0.5) * 2 * math.pi / 12, 0.905), 0.10, 0.009), P3)
    detras = np.abs(phi) > math.pi / 2
    # detrás, en las dos: línea y estrellas (como la vista de espalda)
    ad = (np.abs(phi) - math.pi) * 0.055
    Qd = np.stack([ad, z], -1)
    lin = PT.trazo(np.abs(ad), 0.0013, AA) * (z > 0.30) * (z < 0.89)
    est = np.zeros_like(z)
    for zc in (0.80, 0.62, 0.44):
        est = np.maximum(est, estrella4(Qd, (0.0, zc), 0.020))
    L.oro((lin + est) * detras, P3)
    if lado > 0:
        # izquierda: GEOMETRÍA (línea central, estrellas de cuatro puntas, rombos y puntos)
        lin = PT.trazo(np.abs(a), 0.0014, AA) * (z > 0.29) * (z < 0.89)
        g = lin.copy()
        for zc in (0.84, 0.68, 0.52, 0.36):
            g = np.maximum(g, estrella4(Q, (0.0, zc), 0.024))
        for zc in (0.76, 0.60, 0.44):
            g = np.maximum(g, rombo(Q, (0.0, zc), 0.007, 0.011))
            for sx in (-1, 1):
                g = np.maximum(g, circulo(Q, (sx * 0.020, zc), 0.0028))
        # arcos laterales que enmarcan
        for sx in (-1, 1):
            arc = [(sx * (0.028 + 0.012 * math.sin(math.pi * (zz - 0.30) / 0.58)), zz) for zz in np.linspace(0.30, 0.88, 40)]
            g = np.maximum(g, PT.trazo(PT.d_segmentos(Q, arc), 0.0010, AA))
        L.oro(g * ~detras, P3)
    else:
        # derecha: RAMAS Y HOJAS (enredadera que sube por delante y hacia fuera)
        Qv = np.stack([z, a], -1)
        g = enredadera_en(Qv, 0.58, 0.30, 0.012, 0.020, 0.12, 9, 0.0016)
        g = np.maximum(g, enredadera_en(Qv, 0.30, 0.55, -0.030, 0.010, 0.09, 13, 0.0011, fase=1.3))
        L.oro(g * ~detras, P3)


def p_botas(L, P3, N3, PR):
    x, y, z = P3[:, 0], P3[:, 1], P3[:, 2]
    L.c = tela(P3, NEGRO * 1.1, 6, 0.05)
    L.r[:] = 0.42
    lado = np.sign(x)
    phi, _ = ejes_pierna(P3, 1.0)
    phi = np.where(lado > 0, phi, ejes_pierna(P3, -1.0)[0])
    a = phi * 0.050
    L.poner(np.clip((0.014 - z) / AA * 0.5 + 0.5, 0, 1), np.array([0.03, 0.025, 0.03]), 0.6, 0.0)   # suela
    L.oro(np.clip((-0.150 - y) / 0.002, 0, 1) * (z < 0.065) * (z > 0.012), P3)                      # puntera
    L.oro(banda(z, 0.258, 0.274), P3)                                                                 # boca
    Q = np.stack([a, z], -1)
    L.oro(PT.trazo(np.abs(rombo(Q, (0.0, 0.175), 0.016, 0.030) - 0.5), 0.12, 0.05) * (np.abs(phi) < 1.0), P3)
    L.gema(rombo(Q, (0.0, 0.175), 0.005, 0.009) * (np.abs(phi) < 1.0))
    zt = 0.115 + 0.02 * np.sin(phi)
    L.poner(banda(z - zt, -0.008, 0.008) * (z > 0.06), CUERO * 0.7, 0.55, 0.0)                       # correa


def p_capa(L, P3, N3, PR):
    x, y, z = P3[:, 0], P3[:, 1], P3[:, 2]
    L.c = tela(P3, NEGRO, 8)
    L.r[:] = 0.80
    s = np.abs(x)
    brazo = s > 0.175
    # distancia al borde: abajo (z de corte 1,40 menos el vuelo de 4,5 cm) o puño del brazo (|x| 0,33 + 1,6 cm)
    d_bajo = z - 1.355
    d_brazo = 0.346 - s
    d = np.where(brazo, d_brazo, d_bajo)
    L.oro(banda(d, 0.004, 0.016), P3)
    L.oro(PT.trazo(np.abs(d - 0.022), 0.0010, AA), P3)
    # enredadera sobre el borde (tronco: alrededor; brazo: a lo largo por encima)
    th = np.arctan2(x, -y)
    Qt = np.stack([th * 0.16, z], -1)
    g = np.zeros_like(z)
    for desde, largo in ((-math.pi * 0.16, 2 * math.pi * 0.16),):
        g = enredadera_en(Qt, largo, desde, 1.425, 0.010, 0.07, 21, 0.0013)
    phi = np.arctan2(z - 1.463, -(y - 0.004))
    Qb = np.stack([s, phi * 0.06], -1)
    gb = enredadera_en(Qb, 0.11, 0.20, math.pi / 2 * 0.06, 0.012, 0.06, 22, 0.0013)
    L.oro(np.where(brazo, gb * (d > 0.03), g * (d > 0.03) * (np.abs(th) > 0.5)), P3)
    # amatista en el centro de la espalda, arriba
    Q = np.stack([x, z], -1)
    L.oro(rombo(Q, (0.0, 1.475), 0.016, 0.022) * (y > 0.02), P3)
    L.gema(rombo(Q, (0.0, 1.475), 0.010, 0.015) * (y > 0.02))


def p_capucha(L, P3, N3, PR):
    x, y, z = P3[:, 0], P3[:, 1], P3[:, 2]
    L.c = tela(P3, NEGRO, 10)
    L.r[:] = 0.82
    u, t, phi = PR[:, 0], PR[:, 1], PR[:, 2]
    th = phi + (360.0 - 2 * phi) * u
    r = np.sqrt(x ** 2 + (y - 0.04) ** 2) + 0.02
    d_ab = np.where(phi > 1.0, np.minimum(th - phi, 360.0 - phi - th) * math.pi / 180 * r, 1.0)
    d_ab = np.minimum(d_ab, z - 1.505)
    L.oro(banda(d_ab, 0.003, 0.016), P3)
    L.oro(PT.trazo(np.abs(d_ab - 0.022), 0.0011, AA), P3)
    # adorno de la nuca (flor de lis dorada) y amatista en la frente de la capucha
    detras = y > 0.06
    Q = np.stack([-x, z], -1)
    g = PT.trazo(PT.d_segmentos(Q, [(0.0, 1.80), (0.0, 1.905)]), 0.0018, AA)
    for sx in (-1, 1):
        cur = [(sx * 0.03 * math.sin(math.pi * k / 20) * (1 - k / 40), 1.83 + 0.07 * k / 20) for k in range(21)]
        g = np.maximum(g, PT.trazo(PT.d_segmentos(Q, cur), 0.0015, AA))
        g = np.maximum(g, PT.hoja(Q, (sx * 0.022, 1.86), sx * 1.0, 0.03, 0.011))
    g = np.maximum(g, rombo(Q, (0.0, 1.915), 0.008, 0.014))
    L.oro(g * detras * (np.abs(x) < 0.06), P3)
    Qf = np.stack([x, z], -1)
    frente = (y < 0.02) & (z > 1.86)
    L.oro(rombo(Qf, (0.0, 1.905), 0.016, 0.026) * frente, P3)
    L.gema(rombo(Qf, (0.0, 1.905), 0.010, 0.017) * frente)


def p_faldon(L, P3, N3, PR):
    x, y, z = P3[:, 0], P3[:, 1], P3[:, 2]
    L.c = tela(P3, NEGRO, 12)
    L.r[:] = 0.80
    u, t = PR[:, 0], PR[:, 1]
    r = 0.22 + 0.06 * t
    ancho = math.radians(174 - 48) * r
    alto = 0.85
    d_del = u * ancho
    d_det = (1 - u) * ancho
    d_bajo = (1 - t) * alto
    d_arr = t * alto
    d = np.minimum(np.minimum(d_del, d_det), d_bajo)
    L.oro(banda(d, 0.004, 0.018), P3)
    L.oro(PT.trazo(np.abs(d - 0.026), 0.0011, AA) * (d_arr > 0.05), P3)
    # enredaderas: a lo largo del borde delantero (de arriba abajo) y del bajo
    Qd = np.stack([d_arr, d_del], -1)
    g = enredadera_en(Qd, 0.66, 0.12, 0.060, 0.018, 0.11, 31, 0.0016)
    Qb = np.stack([d_del, d_bajo], -1)
    g = np.maximum(g, enredadera_en(Qb, 0.44, 0.09, 0.062, 0.016, 0.10, 32, 0.0016) * (d_del > 0.08))
    # estrellas y rombos sueltos en el paño
    Qp = np.stack([d_del, d_arr], -1)
    for (cu, ca, rr) in ((0.20, 0.52, 0.020), (0.28, 0.30, 0.014), (0.16, 0.20, 0.010), (0.34, 0.62, 0.012)):
        g = np.maximum(g, estrella4(Qp, (cu, ca), rr))
    L.oro(g, P3)


def p_peplo(L, P3, N3, PR):
    L.c = tela(P3, NEGRO, 14)
    L.r[:] = 0.80
    u, t = PR[:, 0], PR[:, 1]
    ancho = math.radians(312) * 0.23
    d = np.minimum(np.minimum(u * ancho, (1 - u) * ancho), (1 - t) * 0.17)
    L.oro(banda(d, 0.003, 0.012), P3)
    L.oro(PT.trazo(np.abs(d - 0.018), 0.0009, AA), P3)
    Q = np.stack([u * ancho, (1 - t) * 0.17], -1)
    L.oro(enredadera_en(Q, ancho - 0.06, 0.03, 0.040, 0.010, 0.07, 41, 0.0012), P3)


def p_tabardo(L, P3, N3, PR):
    x, z = P3[:, 0], P3[:, 2]
    L.c = tela(P3, NEGRO_C, 15)
    L.r[:] = 0.80
    t = np.clip((1.045 - z) / 0.20, 0, 1)
    half = 0.078 * (1 - t ** 1.6)
    d = np.minimum(half - np.abs(x), np.where(z > 1.04, 1.0, 1.0))
    L.oro(banda(d, 0.003, 0.010), P3)
    Q = np.stack([x, z], -1)
    g = PT.trazo(PT.d_segmentos(Q, [(0.0, 1.02), (0.0, 0.88)]), 0.0015, AA)
    for sx in (-1, 1):
        g = np.maximum(g, PT.hoja(Q, (sx * 0.016, 0.955), sx * 0.6 + math.pi / 2 * (1 - sx) , 0.028, 0.010))
        cur = [(sx * 0.025 * math.sin(math.pi * k / 16), 1.00 - 0.08 * k / 16) for k in range(17)]
        g = np.maximum(g, PT.trazo(PT.d_segmentos(Q, cur), 0.0012, AA))
    L.oro(g, P3)
    L.oro(rombo(Q, (0.0, 0.925), 0.011, 0.017), P3)
    L.gema(rombo(Q, (0.0, 0.925), 0.007, 0.011))


def p_bolsas(L, P3, N3, PR):
    L.c = tela(P3, CUERO, 16, 0.12)
    L.r[:] = 0.62
    z = P3[:, 2]
    lateral = np.abs(N3[:, 2]) < 0.5
    L.poner(banda(z, 1.010, 1.016) * lateral, CUERO * 0.5, 0.7, 0.0)      # borde de la tapa
    L.oro(banda(z, 0.990, 1.004) * lateral, P3)                            # cierre dorado


def pintar(P3, N3, PR, PZ, ID):
    n = P3.shape[0]
    col = np.zeros((n, 3), np.float32)
    rug = np.ones(n, np.float32) * 0.8
    met = np.zeros(n, np.float32)
    tareas = [("cuerpo", p_cuerpo), ("mangas", p_mangas), ("botas", p_botas), ("capa", p_capa),
              ("capucha", p_capucha), ("faldon_i", p_faldon), ("faldon_d", p_faldon), ("peplo", p_peplo),
              ("tabardo", p_tabardo), ("bolsas", p_bolsas),
              ("media_i", lambda L, a, b, c: p_media(L, a, b, c, 1.0)),
              ("media_d", lambda L, a, b, c: p_media(L, a, b, c, -1.0))]
    for nombre, f in tareas:
        m = PZ == ID[nombre]
        if not m.any():
            continue
        L = Capa(int(m.sum()), NEGRO, 0.8)
        f(L, P3[m], N3[m], PR[m])
        col[m] = L.c; rug[m] = L.r; met[m] = L.m
        print("DIBUJO", nombre, int(m.sum()), "texeles; oro %.1f %%" % (100.0 * float((L.m > 0.5).mean())))
    return col, rug, met


def muestra(pid, ID, forma):
    h, w = forma
    if pid == ID["forro"]:
        return PURPURA, 0.70, 0.0
    if pid == ID["oro"]:
        return ORO * 0.92, 0.36, 1.0
    return CUERO, 0.62, 0.0
