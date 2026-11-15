# Sunken City 3D (V12, 15/11), sector «Popa Rota → Cubierta Mayor»: la ciudad en las costillas de un barco de guerra
# varado en una laguna salada (docs/diseno/ciudades_y_lugares.md §2.2, PROPUESTA). Geometría procedural propia (ningún
# recurso descargado), con las ayudas del distrito de los oficios de Oakhaven (crear_distrito.py: caja, tubo, bulto,
# tablas, puesto, barril, cajon…), que se cargan sin su llamada final, como hace crear_barrios.py.
#
#   blender -b --factory-startup -P crear_sunken.py -- <carpeta de salida>
#
# Escribe <carpeta>/sunken.glb (perfil alto) y <carpeta>/sunken_ligero.glb (medio y bajo). Misma semilla, mismo
# resultado. Coordenadas de la escena (zonas3d/sunken/trazado.gd: x al este, z al sur, y arriba; una casilla del diseño es
# un metro), YA en su sitio. LAS MEDIDAS son las de trazado.gd: si se cambia una, se cambia en los dos.
# Objetos (nombre → qué hace con él zonas3d/sunken/casco.gd):
#   edif_<n>     puede tapar a Kael: su malla cuelga de su choque y se vuelve medio transparente (costillas, popa, casas…)
#   muro_<n>     sólido, con sus choques, sin transparencia
#   bajo_<n>     tablas, atrezo, barandillas: una malla por material; sus cajas, si las hay, también chocan
#   bandera      la bandera del Águila (casco.gd la mece; choque fino y se vuelve transparente si tapa a Kael)
# Materiales: base (colores de vértice, sRGB), brillo (luz propia: cristales de los faroles, ventanas), madera (colores de
# vértice con veta), tela (colores de vértice, a dos caras: lonas, ropa tendida, la bandera).
# Vacíos: caja_<i>_<ancho cm>_<fondo cm>_<alto cm>_<y0 cm> (hijo de su objeto: choque con la base a y0) y
#         ancla_<nombre> (posiciones: los faroles, el ojo del mascarón, la lona…).
# Estado artístico: PRIMERA VERSIÓN de la arquitectura (costillas, popa, casas colgadas, palo mayor, mascarón, dique con la
# lona). Está hecha a propósito para la cámara del juego (cenital, de 34° a 58°), no para verse de cerca.
import os, sys, math
AQUI = os.path.dirname(os.path.abspath(__file__))
_DISTRITO = os.path.normpath(os.path.join(AQUI, "..", "..", "oakhaven", "fuente", "crear_distrito.py"))
_src = open(_DISTRITO, encoding="utf-8").read()
_src = _src[:_src.rfind("\nconstruir(1.0")]
exec(compile(_src, _DISTRITO, "exec"), globals())

MADERA_M, TELA_M = 2, 3

# ---------------------------------------------------------------- medidas (las mismas en trazado.gd)
ALTO_CUBIERTA = 1.2
ALTO_ARCHIVO = 0.8
NIVEL_AGUA = -0.85
MUELLE = (38.6, 52.6, 41.4, 60.6)            # x0, z0, x1, z1
POPA = (33.6, 44.2, 46.4, 53.2)
PASO_ARCHIVO = (46.4, 44.6, 49.8, 46.6)
ARCHIVO = (49.6, 42.0, 55.8, 47.8)
QUILLA = (38.4, 31.2, 41.6, 44.4)
RAMPA = (38.4, 28.8, 41.6, 31.2)
CUBIERTA = (30.0, 18.6, 50.0, 28.8)
BALCON = (50.0, 21.0, 54.6, 25.6)
COSTILLAS_QUILLA = (44.0, 38.0, 32.0)
COSTILLA_OSCURA = 38.0
COSTILLAS_CUBIERTA = (26.0, 20.0)
COSTILLAS_PROA = (14.0, 9.5)
COSTILLA_POPA = 50.0
PALO = (40.0, 23.2)

# ---------------------------------------------------------------- paleta (diseño §2.2, en sRGB)
# (15/11, segunda pasada: bajo el sol de la tarde todo salía naranja; la madera blanqueada y las lonas, algo más grises
# y apagadas, y la cubierta más oscura, para que se distingan costillas, tablas y casas)
BLANQUEADA = ((0.66, 0.63, 0.57), (0.76, 0.73, 0.66), (0.86, 0.83, 0.76))   # costillas: #CDB79A → hueso #E3D5BC, al sol
MOJADA = (0.24, 0.28, 0.25)
VERDIN = (0.31, 0.61, 0.54)
OXIDO = (0.54, 0.29, 0.16)
LONA = (0.80, 0.76, 0.66)
REMIENDO = (0.70, 0.46, 0.20)
CARMESI = (0.62, 0.15, 0.15)
ORO_AGUILA = (0.95, 0.78, 0.42)
TABLA = ((0.30, 0.22, 0.16), (0.38, 0.28, 0.20), (0.46, 0.35, 0.25))       # tablas de cubierta, curtidas y embreadas
BREA = (0.14, 0.11, 0.09)                                                  # calafate y cabos embreados
CABO = (0.58, 0.50, 0.36)
ROPA = [(0.74, 0.30, 0.24), (0.30, 0.46, 0.62), (0.90, 0.84, 0.62), (0.40, 0.56, 0.36), (0.84, 0.58, 0.30)]
# las tablas pintadas de las casas: verdín desvaído, almagre, madera blanqueada y un azul de barca
PINTURAS = [(0.36, 0.54, 0.50), (0.58, 0.32, 0.24), (0.66, 0.62, 0.55), (0.32, 0.40, 0.52), (0.52, 0.44, 0.30)]
LUZ_FAROL = (1.0, 0.80, 0.45)


def subir(M, i0, dy):
    """Sube dy (en y de Godot) los vértices de M desde el índice i0: piezas del distrito que se hacen a ras y van en alto."""
    for i in range(i0, len(M.v)):
        M.v[i].z += dy


class Grupo(Malla):
    def __init__(self):
        super().__init__()
        self.cajas_y = []          # (x, y0, z, ancho, fondo, alto)

    def choque(self, x0, z0, x1, z1, alto, y0=0.0):
        self.cajas_y.append(((x0 + x1) * 0.5, y0, (z0 + z1) * 0.5, abs(x1 - x0), abs(z1 - z0), alto))


def tono_tabla():
    return jit(mezcla(TABLA[0], TABLA[2], RND.random()), 0.04)


def entablado(M, x0, z0, x1, z1, y, a_lo_largo_z=True, ancho=0.32, grosor=0.08, huecos=0.0):
    """Tablas de cubierta (con su junta de brea) de (x0, z0) a (x1, z1) a la altura y. «huecos»: probabilidad de que
    falte una tabla (la pasarela vieja deja ver la laguna)."""
    ancho = ancho / math.sqrt(Q)
    if a_lo_largo_z:
        x = x0
        while x < x1 - 0.02:
            w = min(ancho * RND.uniform(0.85, 1.15), x1 - x)
            if RND.random() >= huecos:
                caja(M, (x + 0.012, y - grosor, z0), (x + w - 0.012, y, z1), tono_tabla(), mat=MADERA_M, caras="a")
            x += w
        caja(M, (x0, y - grosor - 0.02, z0), (x1, y - 0.03, z1), BREA, caras="a")
    else:
        z = z0
        while z < z1 - 0.02:
            w = min(ancho * RND.uniform(0.85, 1.15), z1 - z)
            if RND.random() >= huecos:
                caja(M, (x0, y - grosor, z + 0.012), (x1, y, z + w - 0.012), tono_tabla(), mat=MADERA_M, caras="a")
            z += w
        caja(M, (x0, y - grosor - 0.02, z0), (x1, y - 0.03, z1), BREA, caras="a")
    # cantos que se ven desde la cámara (sur) y los lados
    caja(M, (x0, y - 0.3, z1 - 0.06), (x1, y, z1), mezcla(TABLA[0], BREA, 0.3), mat=MADERA_M, caras="s")
    caja(M, (x0, y - 0.3, z0), (x0 + 0.06, y, z1), mezcla(TABLA[0], BREA, 0.3), mat=MADERA_M, caras="o")
    caja(M, (x1 - 0.06, y - 0.3, z0), (x1, y, z1), mezcla(TABLA[0], BREA, 0.3), mat=MADERA_M, caras="e")


def pilotes(M, x0, z0, x1, z1, y, paso=2.2):
    """Pilotes bajo una plataforma, hasta el fango de la laguna (con verdín en la línea del agua)."""
    paso = paso / math.sqrt(Q)
    for x in (x0 + 0.2, x1 - 0.2):
        z = z0 + 0.3
        while z < z1:
            r = 0.13
            tubo(M, (x, -2.2, z), (x, NIVEL_AGUA + 0.25, z), r, r, nq(6, 4), MOJADA, tapa_b=False)
            tubo(M, (x, NIVEL_AGUA + 0.25, z), (x, y - 0.1, z), r, r * 0.95, nq(6, 4), jit(TABLA[1], 0.08), tapa_a=False)
            z += paso


def barandilla(M, a, b, y, alto=0.9, paso=1.4):
    a, b = V(a), V(b)
    largo = (b - a).length
    n = max(1, int(largo / (paso / math.sqrt(Q))))
    for i in range(n + 1):
        p = a.lerp(b, i / n)
        tubo(M, (p.x, y, p.z), (p.x, y + alto, p.z), 0.05, 0.045, nq(5, 4), jit(TABLA[1], 0.1))
    tubo(M, (a.x, y + alto, a.z), (b.x, y + alto, b.z), 0.045, 0.045, nq(5, 4), mezcla(TABLA[1], BREA, 0.2))
    tubo(M, (a.x, y + alto * 0.5, a.z), (b.x, y + alto * 0.5, b.z), 0.025, 0.025, 4, CABO)


def cabo(M, a, b, r=0.022, comba=0.0, n=6):
    """Un cabo de a a b con algo de comba (se combina en tramos)."""
    a, b = V(a), V(b)
    pts = [a.lerp(b, i / n) - V(0, comba * math.sin(math.pi * i / n), 0) for i in range(n + 1)]
    for p, q in zip(pts, pts[1:]):
        tubo(M, p, q, r, r, 4, mezcla(CABO, BREA, 0.35), tapa_a=False, tapa_b=False)


# ================================================================= las costillas

def punto_costilla(t, semi, alto, y0=-1.6, cx=40.0):
    a = math.pi * t
    c, s = math.cos(a), math.sin(a)
    x = cx - semi * math.copysign(abs(c) ** 0.72, c)
    y = y0 + (alto - y0) * (s ** 0.55)
    return x, y


def color_costilla(y, k):
    if y < NIVEL_AGUA + 0.2:
        return mezcla(MOJADA, VERDIN, 0.35 + 0.2 * k)
    if y < 0.9:
        return mezcla(MOJADA, BLANQUEADA[0], (y - NIVEL_AGUA) / 1.9)
    return jit(mezcla(BLANQUEADA[1], BLANQUEADA[2], k), 0.03)


def costilla(M, z, semi, alto, rota=None, nombre="", ancla_farol=None, sin_farol=False):
    """Una costilla en arco de lado a lado, con el bao arriba (la cuaderna entera). «rota»: (t0, t1) que falta."""
    n = nq(30, 14)
    puntos = []
    for i in range(n + 1):
        t = i / n
        x, y = punto_costilla(t, semi, alto)
        puntos.append((t, V(x, y, z)))
    anillos = []
    for i, (t, p) in enumerate(puntos):
        if rota and rota[0] < t < rota[1]:
            anillos.append(None)
            continue
        if i == 0:
            d = puntos[1][1] - p
        elif i == n:
            d = p - puntos[n - 1][1]
        else:
            d = puntos[i + 1][1] - puntos[i - 1][1]
        d.normalize()
        normal = V(-d.y, d.x, 0.0)                         # hacia dentro del arco
        s = math.sin(math.pi * t)
        ancho = 0.50 - 0.14 * s                            # a lo largo de z (más fina arriba)
        hondo = 0.70 - 0.24 * s                            # hacia dentro
        if rota and (abs(t - rota[0]) < 0.02 or abs(t - rota[1]) < 0.02):
            hondo *= 0.6                                   # la astilla del corte
        k = 0.5 + 0.5 * math.sin(z * 1.7 + i * 0.9)
        c = color_costilla(p.y, k)
        fuera_c = mezcla(c, (1, 1, 1), 0.06)               # el lomo, al sol
        dentro_c = mezcla(c, (0.10, 0.12, 0.14), 0.30)     # el intradós, en sombra (se lee el arco)
        anillos.append([(p + normal * hondo * sx + V(0, 0, ancho * 0.5 * sz), fuera_c if sx < 0 else dentro_c)
                        for (sx, sz) in ((-0.5, -1), (0.5, -1), (0.5, 1), (-0.5, 1))])
    for a, b in zip(anillos, anillos[1:]):
        if a is None or b is None:
            continue
        for j in range(4):
            j2 = (j + 1) % 4
            q = [a[j][0], a[j2][0], b[j2][0], b[j][0]]
            ia = [M.vert(q[0], a[j][1]), M.vert(q[1], a[j2][1]), M.vert(q[2], b[j2][1]), M.vert(q[3], b[j][1])]
            nrm = (M.v[ia[1]] - M.v[ia[0]]).cross(M.v[ia[2]] - M.v[ia[0]])
            centro = sum((x for x in q), V(0, 0, 0)) / 4
            eje = (a[0][0] + a[2][0]) * 0.5
            fuera = V(centro.x - eje.x, -(centro.z - eje.z), centro.y - eje.y)
            if nrm.dot(fuera) < 0:
                ia.reverse()
            M.cara(ia, MADERA_M)
    # tapas de los cortes y de los pies
    for i, an in enumerate(anillos):
        vecino_falta = (i > 0 and anillos[i - 1] is None) or (i < len(anillos) - 1 and anillos[i + 1] is None)
        if an is not None and (i in (0, len(anillos) - 1) or vecino_falta):
            cara(M, [x[0] for x in an], mezcla(an[0][1], (0, 0, 0), 0.25), None)
    # flejes de hierro oxidado
    for t in (0.18, 0.5, 0.82):
        if rota and rota[0] - 0.03 < t < rota[1] + 0.03:
            continue
        x, y = punto_costilla(t, semi, alto)
        s = math.sin(math.pi * t)
        caja(M, (x - 0.35, y - 0.12, z - 0.33 + 0.09 * s), (x + 0.35, y + 0.12, z + 0.33 - 0.09 * s), OXIDO, caras="nseoa")
    # el choque (para que se vuelva transparente si tapa a Kael): la parte alta del arco
    xa, ya = punto_costilla(0.3, semi, alto)
    M.choque(xa - 0.2, z - 0.32, 2 * 40.0 - xa + 0.2, z + 0.32, alto - ya + 0.6, ya - 0.3)
    # el farol (o la cuerda cortada de la costilla que no alumbra)
    if ancla_farol is not None:
        xf = 40.9
        _, yf_top = punto_costilla(0.5, semi, alto)
        if sin_farol:
            cabo(M, (xf, yf_top - 0.4, z), (xf, 6.2, z), r=0.025)
            for k in range(4):                               # el cabo deshilachado
                ang = k * math.pi / 2
                tubo(M, (xf, 6.2, z), (xf + 0.08 * math.cos(ang), 5.95, z + 0.08 * math.sin(ang)), 0.01, 0.004, 3, CABO)
            ancla(ancla_farol, (xf, 3.2, z))
        else:
            cabo(M, (xf, yf_top - 0.4, z), (xf, 3.75, z), r=0.025)
            farol_barco(M, (xf, 3.3, z))
            ancla(ancla_farol, (xf, 3.3, z))


def farol_barco(M, p):
    """Farol de barco: jaula de latón de seis lados con su cristal encendido (brillo)."""
    p = V(p)
    tubo(M, p + V(0, -0.26, 0), p + V(0, 0.26, 0), 0.15, 0.15, 6, LUZ_FAROL, mat=BRILLO)
    tubo(M, p + V(0, 0.26, 0), p + V(0, 0.42, 0), 0.19, 0.06, 6, OXIDO)
    tubo(M, p + V(0, -0.34, 0), p + V(0, -0.26, 0), 0.17, 0.19, 6, OXIDO)
    for k in range(6):
        a = 2 * math.pi * (k + 0.5) / 6
        q = p + V(math.cos(a) * 0.16, 0, math.sin(a) * 0.16)
        tubo(M, q + V(0, -0.26, 0), q + V(0, 0.26, 0), 0.016, 0.016, 3, OXIDO, tapa_a=False, tapa_b=False)


def costillas(G):
    # «costilla_<z en dm>»: casco.gd las hace medio transparentes cuando quedan entre la cámara y Kael (pasan por encima)
    for z in COSTILLAS_QUILLA:
        M = G["costilla_%d" % int(z * 10)] = Grupo()
        rota = (0.08, 0.17) if z == 32.0 else None          # a la del norte le falta un trozo por el oeste
        costilla(M, z, 10.6, 8.4, rota, ancla_farol="farol_%d" % int(z), sin_farol=(z == COSTILLA_OSCURA))
    for z in COSTILLAS_CUBIERTA:
        M = G["costilla_%d" % int(z * 10)] = Grupo()
        costilla(M, z, 10.8, 8.9, ancla_farol="farol_%d" % int(z))
    for z, semi, alto in ((COSTILLAS_PROA[0], 8.0, 8.0), (COSTILLAS_PROA[1], 5.4, 7.2)):
        M = G["costilla_%d" % int(z * 10)] = Grupo()
        costilla(M, z, semi, alto)
    M = G["costilla_%d" % int(COSTILLA_POPA * 10)] = Grupo()
    costilla(M, COSTILLA_POPA, 8.6, 7.4, rota=(0.58, 1.01))   # rota del lado de estribor: el muñón se queda en pie


# ================================================================= el casco: quilla, tracas y roda

def casco(G):
    B = G["bajo_casco"] = Grupo()
    # la quilla, bajo la pasarela (asoma por los huecos de las tablas)
    caja(B, (39.4, -1.4, 6.0), (40.6, -0.35, 54.5), mezcla(TABLA[0], MOJADA, 0.4), mat=MADERA_M)
    for z in range(8, 54, 3):
        caja(B, (39.3, -0.5, z - 0.12), (40.7, -0.3, z + 0.12), OXIDO, caras="nseoa")
    # las tracas del costado que quedan, a ras del agua (el contorno del barco en la laguna)
    def contorno(t):                     # t de 0 (popa) a 1 (proa): semimanga
        z = 53.5 - 46.0 * t
        semi = 10.4 if 0.12 < t < 0.72 else (10.4 - (0.12 - t) * 18.0 if t <= 0.12 else 10.4 * (1 - ((t - 0.72) / 0.28) ** 1.6) + 0.3)
        return z, max(0.6, semi)
    n = nq(46, 20)
    for lado in (-1, 1):
        for i in range(n):
            if RND.random() < 0.18:
                continue                                    # tracas que faltan
            z0, s0 = contorno(i / n)
            z1, s1 = contorno((i + 1) / n)
            alto = RND.uniform(-0.2, 0.9) if 0.1 < i / n < 0.75 else RND.uniform(0.2, 1.6)
            for f in range(3):
                y0 = -1.5 + f * 0.55
                if y0 > alto:
                    break
                c = mezcla(MOJADA, TABLA[1], min(1.0, (y0 + 1.2) / 1.6))
                cara(B, [(40 + lado * s0, y0, z0), (40 + lado * s1, y0, z1), (40 + lado * s1, y0 + 0.5, z1),
                         (40 + lado * s0, y0 + 0.5, z0)], jit(c, 0.08), (lado, 0, 0), MADERA_M)
                cara(B, [(40 + lado * (s0 - 0.12), y0, z0), (40 + lado * (s1 - 0.12), y0, z1),
                         (40 + lado * (s1 - 0.12), y0 + 0.5, z1), (40 + lado * (s0 - 0.12), y0 + 0.5, z0)],
                     mezcla(c, (0, 0, 0), 0.2), (-lado, 0, 0), MADERA_M)
    # percebes y verdín en la línea del agua (manchas)
    if Q >= 0.7:
        for k in range(26):
            lado = 1 if k % 2 else -1
            t = RND.uniform(0.12, 0.7)
            z, s = contorno(t)
            bulto(B, (40 + lado * s, NIVEL_AGUA + 0.05, z), 0.22, (0.5, 0.35, 1.6), 0, 0.3,
                  lambda d, q: jit(mezcla(VERDIN, (0.75, 0.74, 0.66), RND.random() * 0.5), 0.1), k)


# ================================================================= la popa rota

def popa_z(x):
    """La cara de fuera del espejo de popa, curva en planta: sale al sur en el centro y se recoge a los lados."""
    u = (x - 40.0) / 7.6
    return 54.0 - 1.3 * u * u


def popa(G):
    """El espejo de popa, partido por la mitad (la brecha por la que entra el muelle): curvo, inclinado hacia fuera,
    alto en las aletas y roto hacia el centro; tablas oscuras, galería de ventanas, molduras de oro gastado y la tabla
    del nombre con solo los clavos de las letras."""
    E = G["edif_popa"] = Grupo()
    grueso = 0.5
    vuelo = 0.55                                            # lo que sale hacia fuera arriba (la popa se inclina)

    def alto_en(x):                                         # las aletas altas; la brecha, rota y astillada
        d = abs(x - 40.0)
        if d < 2.1:
            return 0.0
        return min(4.8, 0.6 + (d - 2.1) * 1.25 + 0.55 * math.sin(x * 3.7) * (1.0 if d < 4.6 else 0.25))

    def fuera(x, y, extra=0.0):                             # un punto de la cara de fuera (con su inclinación)
        return V(x, y, popa_z(x) + extra + vuelo * max(0.0, y) / 4.8)

    for lado in (-1, 1):
        n = nq(14, 8)
        xs = [40 + lado * (2.1 + (7.6 - 2.1) * i / n) for i in range(n + 1)]
        for xa, xb in zip(xs, xs[1:]):
            h = (alto_en(xa) + alto_en(xb)) * 0.5
            ha = h + RND.uniform(-0.18, 0.18) if abs(xa - 40) < 4.6 else h
            c = jit(mezcla(TABLA[0], TABLA[2], RND.random() * 0.6), 0.06)
            for y0, y1 in ((-0.9, 0.15), (0.15, h)):
                if y1 <= y0:
                    continue
                cc = mezcla(MOJADA, c, 0.3) if y0 < 0 else c
                cara(E, [fuera(xa, y0), fuera(xb, y0), fuera(xb, y1), fuera(xa, ha if y1 == h else y1)], cc, (0, 0, 1),
                     MADERA_M)
                cara(E, [fuera(xa, y0, -grueso), fuera(xb, y0, -grueso), fuera(xb, y1, -grueso),
                         fuera(xa, ha if y1 == h else y1, -grueso)], mezcla(cc, (0, 0, 0), 0.25), (0, 0, -1), MADERA_M)
            # el canto de arriba, claro (blanqueado por el sol)
            cara(E, [fuera(xa, ha), fuera(xb, h), fuera(xb, h, -grueso), fuera(xa, ha, -grueso)],
                 jit(mezcla(TABLA[2], BLANQUEADA[0], 0.35), 0.05), (0, 1, 0), MADERA_M)
        # el canto de la brecha: tablas astilladas
        xb = 40 + lado * 2.1
        for k in range(4):
            y = 0.1 + k * 0.32
            tubo(E, fuera(xb, y, -0.25), fuera(xb - lado * RND.uniform(0.15, 0.45), y + 0.25, -0.25), 0.05, 0.01, 4,
                 BLANQUEADA[0], mat=MADERA_M)
        # la aleta: el canto de fuera, más grueso
        x_out = 40 + lado * 7.6
        caja(E, (min(x_out, x_out + lado * 0.35), -0.9, popa_z(x_out) - grueso - 0.1),
             (max(x_out, x_out + lado * 0.35), 4.8, popa_z(x_out) + 0.6), TABLA[0], mat=MADERA_M)
        # las molduras (oro gastado) y la galería de ventanas, rotas
        for y in (1.15, 3.55):
            pts = [40 + lado * (2.6 + (7.4 - 2.6) * i / 8) for i in range(9)]
            for xa, xb2 in zip(pts, pts[1:]):
                if alto_en(xa) < y + 0.2 or alto_en(xb2) < y + 0.2:
                    continue
                caja_t(E, (fuera((xa + xb2) * 0.5, y, 0.05)), (abs(xb2 - xa) + 0.02, 0.16, 0.1), (1, 0, 0), (0, 1, 0),
                       mezcla(ORO_AGUILA, OXIDO, 0.45))
        for k in range(2):
            cx = 40 + lado * (4.9 + k * 1.5)
            if alto_en(cx) < 3.4:
                continue
            caja_t(E, fuera(cx, 2.55, 0.02), (0.85, 1.0, 0.04), (1, 0, 0), (0, 1, 0), (0.08, 0.10, 0.12))
            caja_t(E, fuera(cx, 2.0, 0.06), (1.0, 0.1, 0.12), (1, 0, 0), (0, 1, 0), mezcla(ORO_AGUILA, OXIDO, 0.4))
            caja_t(E, fuera(cx, 3.1, 0.06), (1.0, 0.1, 0.12), (1, 0, 0), (0, 1, 0), mezcla(ORO_AGUILA, OXIDO, 0.4))
            caja_t(E, fuera(cx, 2.55, 0.05), (0.06, 1.0, 0.06), (1, 0, 0), (0, 1, 0), MADERA_OSC)
        # choques: la aleta entera (la cámara la hace transparente si tapa a Kael)
        x0, x1 = sorted((40 + lado * 2.1, x_out))
        E.choque(x0, popa_z(x1 if lado > 0 else x0) - grueso, x1, 54.6, 4.8, -0.9)
        # el nombre del barco, raspado: la tabla y solo los clavos de las letras
        xa, xb2 = sorted((40 + lado * 2.7, 40 + lado * 6.2))
        for i in range(nq(8, 4)):
            u0 = xa + (xb2 - xa) * i / nq(8, 4)
            u1 = xa + (xb2 - xa) * (i + 1) / nq(8, 4)
            caja_t(E, fuera((u0 + u1) * 0.5, 0.68, 0.04), (u1 - u0 + 0.01, 0.42, 0.05), (1, 0, 0), (0, 1, 0), (0.22, 0.17, 0.13))
        for k in range(nq(24, 12)):
            letra = k // 3
            cx = xa + 0.2 + letra * ((xb2 - xa - 0.4) / 8.0) + RND.uniform(-0.08, 0.08)
            cy = 0.68 + RND.uniform(-0.13, 0.13)
            if RND.random() < 0.5:                          # el raspado: madera clara alrededor
                caja_t(E, fuera(cx, cy, 0.075), (0.18, 0.2, 0.004), (1, 0, 0), (0, 1, 0), (0.56, 0.46, 0.34))
            caja_t(E, fuera(cx, cy, 0.09), (0.04, 0.04, 0.04), (1, 0, 0), (0, 1, 0), (0.62, 0.58, 0.50))
    ancla("popa_nombre", tuple(fuera(36.0, 0.68)))
    # el grabado por dentro, junto a la brecha (al oeste): una muesca de navaja y un ancla rayada, en madera clara
    p = fuera(37.5, 1.3, -grueso - 0.01)
    caja_t(E, p, (0.7, 0.5, 0.01), (1, 0, 0), (0, 1, 0), (0.62, 0.52, 0.38))
    tubo(E, p + V(0, 0.2, -0.01), p + V(0, -0.15, -0.01), 0.02, 0.02, 4, (0.24, 0.18, 0.13))
    caja_t(E, p + V(0, 0.1, -0.012), (0.24, 0.03, 0.01), (1, 0, 0), (0, 1, 0), (0.24, 0.18, 0.13))
    ancla("grabado", tuple(p))
    # el timón partido, caído junto a la brecha
    B = G["bajo_popa"] = Grupo()
    caja_t(B, (43.6, -0.3, 56.0), (0.5, 3.4, 1.4), (0.2, 1, 0), (1, 0, 0), mezcla(TABLA[0], MOJADA, 0.3), MADERA_M)
    for y in (-0.8, 0.4):
        caja_t(B, (43.6 + 0.2 * y, y, 56.0), (0.6, 0.16, 1.5), (0.2, 1, 0), (1, 0, 0), OXIDO)


# ================================================================= suelos: muelle, popa, Quilla, rampa, Cubierta Mayor

def suelos(G):
    S = G["bajo_suelos"] = Grupo()
    x0, z0, x1, z1 = MUELLE
    entablado(S, x0, 53.6, x1, 66.0, 0.0, a_lo_largo_z=False, ancho=0.34)
    pilotes(S, x0, 54.0, x1, 66.0, 0.0, 2.6)
    for z in (55.2, 58.0, 60.8, 63.6):
        for x in (x0 - 0.05, x1 + 0.05):
            tubo(S, (x, -1.0, z), (x, 0.75, z), 0.12, 0.1, nq(6, 4), jit(TABLA[0], 0.1))     # norays del muelle
    cabo(S, (x0 - 0.05, 0.6, 55.2), (x0 - 0.05, 0.6, 63.6), r=0.03, comba=0.25, n=8)
    cabo(S, (x1 + 0.05, 0.6, 55.2), (x1 + 0.05, 0.6, 63.6), r=0.03, comba=0.25, n=8)
    x0, z0, x1, z1 = POPA
    entablado(S, x0, z0, x1, z1, 0.0)
    pilotes(S, x0, z0, x1, z1, 0.0)
    barandilla(S, (x0, 0, z0 + 0.3), (x0, 0, z1 - 0.2), 0.0)
    barandilla(S, (x1, 0, z0 + 0.3), (x1, 0, 44.6), 0.0)
    barandilla(S, (x1, 0, 46.6), (x1, 0, z1 - 0.2), 0.0)
    barandilla(S, (x0, 0, z0), (QUILLA[0], 0, z0), 0.0)
    barandilla(S, (QUILLA[2], 0, z0), (x1, 0, z0), 0.0)
    x0, z0, x1, z1 = PASO_ARCHIVO
    i0 = len(S.v)
    entablado(S, x0, z0, 48.6, z1, 0.0, a_lo_largo_z=False, ancho=0.3)
    for i in range(i0, len(S.v)):                           # la rampa del pasillo (de 0 a ALTO_ARCHIVO)
        x = S.v[i].x
        S.v[i].z += ALTO_ARCHIVO * max(0.0, min(1.0, (x - 46.4) / 2.2))
    entablado(S, 48.6, z0, x1, z1, ALTO_ARCHIVO, a_lo_largo_z=False, ancho=0.3)
    pilotes(S, x0, z0, x1, z1, ALTO_ARCHIVO, 3.0)
    x0, z0, x1, z1 = QUILLA
    entablado(S, x0, z0, x1, z1, 0.0, a_lo_largo_z=False, ancho=0.3, huecos=0.06)
    pilotes(S, x0, z0, x1, z1, 0.0)
    x0, z0, x1, z1 = RAMPA
    i0 = len(S.v)
    entablado(S, x0, z0, x1, z1, 0.0, a_lo_largo_z=False, ancho=0.28)
    for i in range(i0, len(S.v)):
        z = -S.v[i].y
        S.v[i].z += ALTO_CUBIERTA * max(0.0, min(1.0, (31.2 - z) / 2.4))
    for x in (x0 - 0.05, x1 + 0.05):                          # pasamanos de la rampa
        cabo(S, (x, 0.9, 31.2), (x, 0.9 + ALTO_CUBIERTA, 28.8), r=0.035, n=2)
        for z, y in ((31.2, 0.0), (28.8, ALTO_CUBIERTA)):
            tubo(S, (x, y, z), (x, y + 0.95, z), 0.05, 0.045, 5, jit(TABLA[1], 0.1))
    x0, z0, x1, z1 = CUBIERTA
    entablado(S, x0, z0, x1, z1, ALTO_CUBIERTA, a_lo_largo_z=True, ancho=0.36)
    # el borde sur de la Cubierta Mayor: el canto alto que se ve desde la Quilla
    caja(S, (x0, -0.9, z1 - 0.12), (x1, ALTO_CUBIERTA, z1), mezcla(TABLA[0], BREA, 0.15), mat=MADERA_M, caras="sa")
    pilotes(S, x0, z0, x1, z1, ALTO_CUBIERTA, 3.0)
    barandilla(S, (x0, ALTO_CUBIERTA, z0), (x0, ALTO_CUBIERTA, z1), ALTO_CUBIERTA)
    barandilla(S, (x1, ALTO_CUBIERTA, z1), (x1, ALTO_CUBIERTA, 25.6), ALTO_CUBIERTA)
    barandilla(S, (x1, ALTO_CUBIERTA, 21.0), (x1, ALTO_CUBIERTA, z0), ALTO_CUBIERTA)
    barandilla(S, (x0, ALTO_CUBIERTA, z1), (QUILLA[0] - 0.05, ALTO_CUBIERTA, z1), ALTO_CUBIERTA)
    barandilla(S, (QUILLA[2] + 0.05, ALTO_CUBIERTA, z1), (x1, ALTO_CUBIERTA, z1), ALTO_CUBIERTA)
    x0, z0, x1, z1 = BALCON
    entablado(S, x0, z0, x1, z1, ALTO_CUBIERTA, a_lo_largo_z=False, ancho=0.3)
    pilotes(S, x0, z0, x1, z1, ALTO_CUBIERTA, 2.2)
    barandilla(S, (x1, ALTO_CUBIERTA, z0), (x1, ALTO_CUBIERTA, z1), ALTO_CUBIERTA)
    barandilla(S, (x0, ALTO_CUBIERTA, z0), (x1, ALTO_CUBIERTA, z0), ALTO_CUBIERTA)
    barandilla(S, (x0 + 0.9, ALTO_CUBIERTA, z1), (x1, ALTO_CUBIERTA, z1), ALTO_CUBIERTA)
    # la tabla suelta de la costilla que no alumbra (el secreto): un poco levantada, del color de las demás
    caja_t(S, (38.75, 0.035, COSTILLA_OSCURA), (0.34, 0.06, 1.1), (1, 0, 0), (0.06, 1, 0), mezcla(TABLA[1], BREA, 0.1), MADERA_M)
    ancla("tabla", (38.75, 0.0, COSTILLA_OSCURA))


# ================================================================= las casas colgadas de las costillas

def casa(E, B, x0, x1, z0, z1, y, alto, puerta_hacia, semilla, techo="lona", piso=False):
    """Casa de tablas sobre pilotes entre dos costillas. «puerta_hacia»: +1 (al este) o -1 (al oeste), hacia la Quilla."""
    RND.seed(semilla)
    pilotes(B, x0, z0, x1, z1, y, 2.0)
    caja(B, (x0 - 0.1, y - 0.18, z0 - 0.1), (x1 + 0.1, y, z1 + 0.1), mezcla(TABLA[0], BREA, 0.2), mat=MADERA_M)
    base_c = jit(mezcla(PINTURAS[semilla % len(PINTURAS)], TABLA[1], RND.uniform(0.1, 0.35)), 0.05)   # tablas pintadas
    tablas(E, (x0, y, z1), (1, 0, 0), x1 - x0, alto, (0, 0, 1), base_c, nq(int((x1 - x0) / 0.35), 4))
    tablas(E, (x1 if puerta_hacia < 0 else x0, y, z0), (0, 0, 1), z1 - z0, alto, (puerta_hacia * -1, 0, 0),
           mezcla(base_c, (0, 0, 0), 0.1), nq(int((z1 - z0) / 0.35), 4))
    xp = x1 if puerta_hacia > 0 else x0
    tablas(E, (xp, y, z0), (0, 0, 1), z1 - z0, alto, (puerta_hacia, 0, 0), mezcla(base_c, (1, 1, 1), 0.05),
           nq(int((z1 - z0) / 0.35), 4))
    tablas(E, (x0, y, z0), (1, 0, 0), x1 - x0, alto, (0, 0, -1), mezcla(base_c, (0, 0, 0), 0.15), 3)
    zc = (z0 + z1) * 0.5
    puerta(B, (xp + puerta_hacia * 0.01, y, zc), 0.9, 1.9, (0, 0, 1), (puerta_hacia, 0, 0), mezcla(TABLA[0], BREA, 0.2))
    ventana(B, (xp + puerta_hacia * 0.01, y + 1.6, zc + 1.3 * (1 if z1 - z0 > 3.2 else 0.6)), 0.55, 0.5, (0, 0, 1),
            (puerta_hacia, 0, 0), MADERA_OSC)
    ventana(B, ((x0 + x1) * 0.5, y + 1.7, z1 + 0.01), 0.6, 0.55, (1, 0, 0), (0, 0, 1), MADERA_OSC,
            contraventanas=jit(ROPA[semilla % len(ROPA)], 0.1), macetero=RND.random() < 0.5)
    top = y + alto
    if techo == "lona":                                     # toldo de lona con remiendos, cae hacia la Quilla
        alto_fondo = top + 0.9
        filas = nq(4, 2)
        for i in range(filas):
            za, zb = z0 - 0.2 + (z1 - z0 + 0.4) * i / filas, z0 - 0.2 + (z1 - z0 + 0.4) * (i + 1) / filas
            c = REMIENDO if RND.random() < 0.25 else jit(LONA, 0.04)
            xa, xb = (x0 - 0.2, x1 + 0.5) if puerta_hacia > 0 else (x1 + 0.2, x0 - 0.5)
            cara(E, [(xa, alto_fondo, za), (xa, alto_fondo, zb), (xb, top, zb), (xb, top, za)], c, (0, 1, 0), TELA_M)
    else:                                                   # tejado de tablas
        tejado(E, (x0 - 0.2, top + 0.8, zc), (x1 + 0.2, top + 0.8, zc), (x0 - 0.2, top, z1 + 0.25), (x1 + 0.2, top, z1 + 0.25),
               TABLA, 3, 5, alero=BREA)
        tejado(E, (x1 + 0.2, top + 0.8, zc), (x0 - 0.2, top + 0.8, zc), (x1 + 0.2, top, z0 - 0.25), (x0 - 0.2, top, z0 - 0.25),
               TABLA, 3, 5, alero=BREA)
    E.choque(x0, z0, x1, z1, alto + 1.0, y)
    if piso and Q >= 0.7:                                   # un cuarto colgado más arriba, contra la costilla
        y2 = top + 1.2
        xa, xb = (x0, x0 + (x1 - x0) * 0.6) if puerta_hacia > 0 else (x0 + (x1 - x0) * 0.4, x1)
        caja(E, (xa, y2, z0 + 0.4), (xb, y2 + 2.0, z1 - 0.4), jit(mezcla(base_c, BLANQUEADA[1], 0.3), 0.05), mat=MADERA_M)
        ventana(E, ((xa + xb) * 0.5, y2 + 1.1, z1 - 0.39), 0.5, 0.45, (1, 0, 0), (0, 0, 1), MADERA_OSC)
        caja(E, (xa - 0.15, y2 + 2.0, z0 + 0.25), (xb + 0.15, y2 + 2.12, z1 - 0.25), REMIENDO, mat=TELA_M)
        for xx in (xa + 0.2, xb - 0.2):
            cabo(E, (xx, y2 + 2.1, (z0 + z1) * 0.5), (xx, y2 + 5.0, (z0 + z1) * 0.5), r=0.03, n=1)
        E.choque(xa, z0 + 0.4, xb, z1 - 0.4, 2.2, y2)


def casas(G):
    # entre las costillas de la Quilla (z 32, 38, 44) y a los dos lados de la pasarela
    tramos = ((32.5, 37.5), (38.5, 43.5))
    n = 0
    for (za, zb) in tramos:
        for lado in (-1, 1):
            n += 1
            E = G["edif_casa_%d" % n] = Grupo()
            B = G["bajo_casa_%d" % n] = Grupo()
            if lado < 0:
                casa(E, B, 32.6 + RND.uniform(0, 0.6), 37.6, za + 0.3, zb - 0.3, 0.3, 2.8 + RND.uniform(0, 0.6), 1, 11 + n,
                     techo="lona" if n % 2 else "tablas", piso=(n % 2 == 1))
            else:
                casa(E, B, 42.4, 47.6 - RND.uniform(0, 0.6), za + 0.3, zb - 0.3, 0.3, 2.8 + RND.uniform(0, 0.6), -1, 21 + n,
                     techo="tablas" if n % 2 else "lona", piso=(n % 2 == 0))
    # dos chozas más pequeñas junto a la rampa
    for lado, semilla in ((-1, 41), (1, 43)):
        n += 1
        E = G["edif_casa_%d" % n] = Grupo()
        B = G["bajo_casa_%d" % n] = Grupo()
        if lado < 0:                                        # (tablas: un toldo claro tan cerca de la cámara deslumbraba)
            casa(E, B, 34.0, 37.6, 28.9, 31.6, 0.3, 2.6, 1, semilla, techo="tablas")
        else:
            casa(E, B, 42.4, 46.0, 28.9, 31.6, 0.3, 2.6, -1, semilla, techo="tablas")
    # ropa tendida de lado a lado de la Quilla, entre los pisos altos
    T = G["bajo_tendederos"] = Grupo()
    for z in (35.2, 41.0):
        a, b = V(37.6, 4.6, z), V(42.4, 4.4, z + 0.3)
        cabo(T, a, b, r=0.015, comba=0.35, n=6)
        for k in range(nq(6, 3)):
            t = (k + 0.5) / nq(6, 3)
            p = a.lerp(b, t) - V(0, 0.35 * math.sin(math.pi * t), 0)
            w, h = RND.uniform(0.35, 0.6), RND.uniform(0.45, 0.8)
            cara(T, [(p.x - w / 2, p.y, p.z), (p.x + w / 2, p.y, p.z), (p.x + w / 2, p.y - h, p.z), (p.x - w / 2, p.y - h, p.z)],
                 jit(ROPA[(k + int(z)) % len(ROPA)], 0.08), (0, 0, 1), TELA_M)
    # redes secándose y nasas en los rincones de la popa
    R = G["bajo_redes"] = Grupo()
    for (x, z) in ((34.4, 45.4), (45.4, 51.6), (34.6, 51.2)):
        for k in range(3):
            caja(R, (x - 0.35 + k * 0.05, 0.0, z - 0.25), (x + 0.35, 0.5 + 0.1 * k, z + 0.25),
                 jit(mezcla(CABO, BREA, 0.4), 0.1), caras="nseoa")
        barril(R, (x + 0.75, 0.0, z + 0.1), 0.26, 0.62)
    for (x, z) in ((44.8, 45.0), (35.2, 48.6)):
        cajon(R, (x, 0.0, z), (0.7, 0.45, 0.55), MADERA_CLARA, (0.55, 0.62, 0.66), int(x))
    R.choque(33.6, 44.2, 35.6, 46.0, 0.8)


# ================================================================= el Archivo del Águila

def archivo(G):
    E = G["edif_archivo"] = Grupo()
    B = G["bajo_archivo"] = Grupo()
    y = ALTO_ARCHIVO
    x0, z0, x1, z1 = 49.2, 41.6, 56.2, 48.2
    entablado(B, x0, z0, x1, z1, y, a_lo_largo_z=True, ancho=0.3)
    pilotes(B, x0, z0, x1, z1, y, 2.2)
    pared = mezcla(TABLA[1], (0.36, 0.30, 0.26), 0.4)
    # pared norte (alta), este y oeste (con la puerta), y el pretil del sur (bajo: la cámara ve dentro)
    caja(E, (x0, y, z0), (x1, y + 3.6, z0 + 0.4), pared, mat=MADERA_M)
    caja(E, (x1 - 0.4, y, z0), (x1, y + 3.2, z1), pared, mat=MADERA_M)
    caja(E, (x0, y, z0), (x0 + 0.4, y + 3.2, 44.6), pared, mat=MADERA_M)
    caja(E, (x0, y, 46.6), (x0 + 0.4, y + 3.2, z1), pared, mat=MADERA_M)
    caja(E, (x0, y + 2.3, 44.6), (x0 + 0.4, y + 3.2, 46.6), mezcla(pared, (0, 0, 0), 0.1), mat=MADERA_M)
    caja(E, (x0 + 0.4, y, z1 - 0.4), (x1 - 0.4, y + 1.0, z1), pared, mat=MADERA_M)
    for x in (51.0, 52.6, 54.2):                             # balaustres del pretil
        caja(E, (x - 0.07, y + 1.0, z1 - 0.3), (x + 0.07, y + 3.4, z1 - 0.1), mezcla(pared, (0, 0, 0), 0.15), mat=MADERA_M)
    E.choque(x0, z0, x1, z0 + 0.4, 3.6, y)
    E.choque(x1 - 0.4, z0, x1, z1, 3.2, y)
    E.choque(x0, z0, x0 + 0.4, 44.6, 3.2, y)
    E.choque(x0, 46.6, x0 + 0.4, z1, 3.2, y)
    E.choque(x0 + 0.4, z1 - 0.4, x1 - 0.4, z1, 1.0, y)
    # remate de pan de oro en la pared norte (era el camarote del capitán): el águila pintada, descolorida
    for k in range(5):
        a = math.radians(160 - k * 35)
        caja(E, (52.7 + 1.4 * math.cos(a) - 0.25, y + 2.6 + 0.7 * math.sin(a), z0 + 0.41),
             (52.7 + 1.4 * math.cos(a) + 0.25, y + 2.7 + 0.7 * math.sin(a), z0 + 0.43), mezcla(ORO_AGUILA, pared, 0.35), caras="s")
    # la lona del techo (solo la mitad del fondo: delante, el camarote está abierto al cielo) y las vigas
    L = G["edif_archivo_lona"] = Grupo()
    for i in range(nq(6, 3)):
        xa, xb = x0 - 0.2 + (x1 - x0 + 0.4) * i / nq(6, 3), x0 - 0.2 + (x1 - x0 + 0.4) * (i + 1) / nq(6, 3)
        c = REMIENDO if i == 2 else jit(LONA, 0.03)
        cara(L, [(xa, y + 3.7, z0 - 0.2), (xb, y + 3.7, z0 - 0.2), (xb, y + 3.0, 44.4), (xa, y + 3.0, 44.4)], c, (0, 1, 0.3), TELA_M)
    L.choque(x0, z0, x1, 44.4, 0.8, y + 3.0)
    for z in (44.4, 46.3, 48.0):
        caja(B, (x0, y + 3.2, z - 0.09), (x1, y + 3.38, z + 0.09), mezcla(TABLA[0], BREA, 0.3), mat=MADERA_M)
    # los archivadores: cajones ordenados y casilleros de rollos (contra la pared norte)
    for k in range(nq(6, 3)):
        xa = 49.8 + k * (5.8 / nq(6, 3))
        xb = xa + 5.8 / nq(6, 3) - 0.06
        caja(B, (xa, y, 42.0), (xb, y + 2.2, 42.7), mezcla(TABLA[0], (0.30, 0.22, 0.16), 0.5), mat=MADERA_M)
        for f in range(4):
            yy = y + 0.25 + f * 0.48
            caja(B, (xa + 0.06, yy, 42.7), (xb - 0.06, yy + 0.38, 42.72), mezcla(TABLA[1], (0.30, 0.22, 0.16), 0.3), caras="s")
            caja(B, ((xa + xb) * 0.5 - 0.06, yy + 0.16, 42.72), ((xa + xb) * 0.5 + 0.06, yy + 0.22, 42.76), ORO_AGUILA, caras="sa")
    # la mesa de Ulla con el libro mayor y el tintero; el atril de los contratos con su cinta carmesí
    caja(B, (51.6, y, 44.0), (53.8, y + 0.78, 44.8), mezcla(TABLA[0], BREA, 0.2), mat=MADERA_M)
    caja(B, (51.5, y + 0.78, 43.95), (53.9, y + 0.84, 44.85), TABLA[1], mat=MADERA_M)
    caja(B, (52.2, y + 0.84, 44.15), (53.0, y + 0.9, 44.65), (0.92, 0.88, 0.76), caras="nseoa")
    tubo(B, (53.4, y + 0.84, 44.4), (53.4, y + 0.95, 44.4), 0.05, 0.04, 6, (0.12, 0.14, 0.22))
    tubo(B, (54.9, y, 46.2), (54.9, y + 1.05, 46.2), 0.06, 0.05, 6, MADERA_OSC)
    caja_t(B, (54.9, y + 1.12, 46.2), (0.62, 0.05, 0.46), (1, 0, 0), (0, 1, 0.45), (0.93, 0.89, 0.78))
    caja_t(B, (54.9, y + 1.08, 46.2), (0.05, 0.6, 0.02), (1, 0, 0), (0, 0.45, -1), CARMESI)
    ancla("contratos", (54.9, y + 1.12, 46.2))
    farolillo(B, (52.7, y + 2.7, 43.4))
    ancla("farol_archivo", (52.7, y + 2.7, 43.4))
    B.choque(51.6, 44.0, 53.8, 44.8, 0.85, y)
    B.choque(49.6, 42.0, 55.8, 42.7, 2.2, y)


# ================================================================= la Cubierta Mayor: palo mayor, bandera, mercado, escotilla

def cubierta(G):
    y = ALTO_CUBIERTA
    M = G["edif_palo"] = Grupo()
    px, pz = PALO
    # el tocón del palo mayor (partido a 7,6 m), con sus zunchos y la cabilla de las drizas
    tubo(M, (px, y, pz), (px, y + 7.6, pz), 0.55, 0.42, nq(12, 8), jit(mezcla(TABLA[1], BLANQUEADA[0], 0.4), 0.05), mat=MADERA_M)
    for k in range(5):
        cx = px + 0.3 * math.cos(k * 1.3)
        cz = pz + 0.3 * math.sin(k * 1.3)
        tubo(M, (cx, y + 7.6, cz), (cx + 0.05, y + 7.6 + RND.uniform(0.3, 0.9), cz), 0.16, 0.02, 4, BLANQUEADA[1], mat=MADERA_M)
    for yy in (1.2, 3.0, 4.8, 6.6):
        tubo(M, (px, y + yy, pz), (px, y + yy + 0.12, pz), 0.58 - yy * 0.02, 0.58 - yy * 0.02, nq(12, 8), OXIDO)
    caja(M, (px - 0.95, y, pz - 0.95), (px + 0.95, y + 0.35, pz + 0.95), mezcla(TABLA[0], BREA, 0.2), mat=MADERA_M)   # fogonadura
    caja(M, (px - 0.06, y + 0.9, pz + 0.55), (px + 0.06, y + 1.1, pz + 0.75), OXIDO)        # la cornamusa de la driza
    # la verga baja (de donde cuelga la bandera, hacia el OESTE: así no se cruza entre la cámara y el mascarón cuando Kael
    # se asoma a la proa por el este) y los obenques
    tubo(M, (px + 0.2, y + 6.4, pz + 0.5), (px - 4.2, y + 6.4, pz + 0.5), 0.09, 0.07, nq(6, 4), mezcla(TABLA[0], BREA, 0.2), mat=MADERA_M)
    cabo(M, (px - 0.2, y + 7.4, pz), (px - 4.2, y + 6.45, pz + 0.5), r=0.02, n=2)
    cabo(M, (px + 0.1, y + 1.0, pz + 0.65), (px - 0.4, y + 6.4, pz + 0.55), r=0.015, n=2)   # la driza
    for (bx, bz) in ((31.0, 21.0), (31.0, 26.0), (49.0, 21.0), (49.0, 26.0)):
        cabo(M, (px, y + 7.3, pz), (bx, y + 0.9, bz), r=0.025, n=2)
    M.choque(px - 0.6, pz - 0.6, px + 0.6, pz + 0.6, 7.6, y)
    ancla("sello", (px + 0.1, y + 1.0, pz + 0.7))
    # la bandera del Águila (aparte: casco.gd la mece): carmesí remendada, el águila dorada siempre entera
    F = G["bandera"] = Grupo()
    bx0, bx1, by1, by0 = px - 4.0, px - 0.3, y + 6.35, y + 3.1
    nx, ny = nq(8, 4), nq(6, 3)
    for i in range(nx):
        for j in range(ny):
            xa, xb = bx0 + (bx1 - bx0) * i / nx, bx0 + (bx1 - bx0) * (i + 1) / nx
            ya, yb = by1 - (by1 - by0) * j / ny, by1 - (by1 - by0) * (j + 1) / ny
            remiendo = (i == 1 and j == ny - 1) or (i == nx - 2 and j == 1)
            c = mezcla(CARMESI, (0.30, 0.10, 0.08), 0.35) if remiendo else CARMESI
            cara(F, [(xa, yb, pz + 0.5), (xb, yb, pz + 0.5), (xb, ya, pz + 0.5), (xa, ya, pz + 0.5)], jit(c, 0.05), (0, 0, 1), TELA_M)
    cx, cy, zz = (bx0 + bx1) * 0.5, (by0 + by1) * 0.5 + 0.05, pz + 0.52
    oro = jit(ORO_AGUILA, 0.03)
    for lado in (-1, 1):                                    # el águila: alas abiertas en plumas, cuerpo, cabeza y cola
        hombro = V(cx + lado * 0.16, cy + 0.32, zz)
        for k in range(6):
            a = math.radians(4 + k * 13)
            largo = 1.45 - k * 0.14
            punta = hombro + V(lado * math.cos(a) * largo, math.sin(a) * largo * 0.62, 0)
            base = hombro + V(lado * 0.1, -0.18 - k * 0.02, 0)
            cara(F, [hombro, punta, base], oro if k % 2 == 0 else mezcla(oro, (1, 1, 1), 0.12), (0, 0, 1), TELA_M)
    cara(F, [(cx - 0.2, cy + 0.42, zz), (cx + 0.2, cy + 0.42, zz), (cx + 0.14, cy - 0.55, zz), (cx - 0.14, cy - 0.55, zz)],
         oro, (0, 0, 1), TELA_M)                           # el cuerpo
    cara(F, [(cx - 0.15, cy + 0.42, zz), (cx + 0.12, cy + 0.42, zz), (cx + 0.16, cy + 0.74, zz), (cx - 0.1, cy + 0.78, zz)],
         oro, (0, 0, 1), TELA_M)                           # el cuello y la cabeza, de perfil
    cara(F, [(cx + 0.15, cy + 0.76, zz + 0.001), (cx + 0.42, cy + 0.66, zz + 0.001), (cx + 0.14, cy + 0.6, zz + 0.001)],
         (0.98, 0.62, 0.20), (0, 0, 1), TELA_M)            # el pico
    for k in range(3):                                     # la cola en abanico
        cara(F, [(cx, cy - 0.45, zz), (cx - 0.32 + k * 0.32, cy - 1.05, zz), (cx - 0.16 + k * 0.32, cy - 1.1, zz)],
             oro, (0, 0, 1), TELA_M)
    for lado in (-1, 1):                                   # las garras
        cara(F, [(cx + lado * 0.08, cy - 0.5, zz), (cx + lado * 0.3, cy - 0.78, zz), (cx + lado * 0.14, cy - 0.8, zz)],
             (0.98, 0.62, 0.20), (0, 0, 1), TELA_M)
    F.choque(bx0, pz + 0.45, bx1, pz + 0.55, by1 - by0, by0)
    # el puesto del mercado (la tienda): el del distrito, en alto, con toldo carmesí y lona, género de puerto
    B = G["bajo_cubierta"] = Grupo()
    PESCADO, LIMON, SAL, CUERDA = (0.62, 0.70, 0.74), (0.95, 0.84, 0.30), (0.95, 0.94, 0.90), (0.70, 0.58, 0.38)
    i0 = len(B.v)
    puesto(B, 30.4, 34.6, 18.8, 20.9, (CARMESI, LONA), [PESCADO, LIMON, SAL, CUERDA], 77)
    subir(B, i0, y)
    B.cajas = []
    ancla("tienda", (32.4, y, 22.3))
    # la escotilla al Casco, atrancada (brazola, tapa y una barra de hierro)
    caja(B, (43.4, y, 24.8), (45.6, y + 0.5, 26.6), mezcla(TABLA[0], BREA, 0.25), mat=MADERA_M)
    entablado(B, 43.55, 24.95, 45.45, 26.45, y + 0.56, a_lo_largo_z=True, ancho=0.24, grosor=0.05)
    caja(B, (43.3, y + 0.56, 25.6), (45.7, y + 0.68, 25.8), OXIDO, caras="nseoa")
    caja(B, (44.3, y + 0.5, 26.62), (44.9, y + 0.62, 26.64), (0.92, 0.92, 0.88), caras="s")   # la tiza
    # cajas, barriles y redes; un cañón viejo convertido en macetero
    for (x, z, s) in ((47.4, 19.2, 1.0), (48.6, 19.0, 0.8), (49.3, 19.9, 0.7)):
        cajon(B, (x, y, z), (0.8 * s, 0.6 * s, 0.7 * s), MADERA_CLARA, None, int(x * 10))
    barril(B, (30.6, y, 26.8), 0.3, 0.72)
    barril(B, (30.7, y, 27.6), 0.3, 0.72, agua=True)
    tubo(B, (31.2, y + 0.45, 27.9), (33.0, y + 0.55, 27.9), 0.2, 0.16, nq(10, 6), (0.22, 0.24, 0.24))
    for k in range(4):
        bulto(B, (32.9 + 0.1 * k, y + 0.7, 27.9), 0.16, (1, 0.9, 1), 0, 0.3, lambda d, q: jit(HOJA[2], 0.1), k)
    # la barandilla de proa con las cuerdas tendidas y el letrero
    barandilla(B, (CUBIERTA[0], y, 18.6), (CUBIERTA[2], y, 18.6), y)
    for x in (41.4, 44.6):                                  # (al este del palo: desde ahí se ve el mascarón)
        tubo(B, (x, y, 18.9), (x, y + 1.1, 18.9), 0.06, 0.05, 5, jit(TABLA[1], 0.1))
    cabo(B, (41.4, y + 0.95, 18.9), (44.6, y + 0.95, 18.9), r=0.03, comba=0.15, n=4)
    cabo(B, (41.4, y + 0.55, 18.9), (44.6, y + 0.55, 18.9), r=0.03, comba=0.1, n=4)
    caja_t(B, (43.0, y + 0.75, 18.95), (0.9, 0.42, 0.04), (1, 0, 0), (0, 1, 0), (0.80, 0.70, 0.52), MADERA_M)
    ancla("letrero_proa", (43.0, y + 0.75, 18.98))
    # los faroles de las costillas de la Cubierta Mayor ya los pone costilla(); dos más, en postes junto a la rampa
    for x in (37.6, 42.4):
        tubo(B, (x, y, 28.4), (x, y + 2.4, 28.4), 0.07, 0.06, 6, MADERA_OSC)
        farol_barco(B, (x, y + 2.75, 28.4))
        ancla("farol_poste_%d" % int(x), (x, y + 2.75, 28.4))


# ================================================================= la proa y el mascarón

def proa(G):
    y = ALTO_CUBIERTA
    B = G["bajo_proa"] = Grupo()
    # la cubierta de proa (no se pisa: «Proa en obras»), con tablas sueltas y rollos de cabo
    entablado(B, 33.0, 8.0, 47.0, 18.6, y, a_lo_largo_z=True, ancho=0.36, huecos=0.12)
    pilotes(B, 33.0, 8.0, 47.0, 18.6, y, 3.0)
    for (x, z) in ((36.2, 15.6), (43.6, 12.8), (38.4, 11.2)):
        for k in range(3):
            tubo(B, (x, y + 0.08 * k, z), (x, y + 0.08 * k + 0.08, z), 0.5 - 0.1 * k, 0.5 - 0.1 * k, nq(10, 6), CABO,
                 tapa_a=False)
    for (x, z) in ((44.6, 16.6), (35.0, 10.6)):
        cajon(B, (x, y, z), (0.9, 0.6, 0.7), MADERA_CLARA, None, int(z))
    # la roda y el bauprés (hacia el norte, inclinado)
    M = G["edif_mascaron"] = Grupo()
    tubo(M, (40, -1.6, 7.6), (40, y + 2.4, 6.0), 0.5, 0.42, nq(10, 6), jit(mezcla(TABLA[1], BLANQUEADA[0], 0.4), 0.05), mat=MADERA_M)
    tubo(M, (40, y + 2.2, 6.6), (40, y + 5.4, -3.4), 0.28, 0.12, nq(10, 6), jit(mezcla(TABLA[1], BLANQUEADA[0], 0.3), 0.05), mat=MADERA_M)
    for t in (0.3, 0.6):
        p = V(40, y + 2.2, 6.6).lerp(V(40, y + 5.4, -3.4), t)
        tubo(M, p - V(0, 0, 0.1), p + V(0, 0, 0.1), 0.3 - 0.1 * t, 0.3 - 0.1 * t, nq(10, 6), OXIDO)
    # el águila dorada: cuerpo, pecho alzado, cabeza con pico, alas abiertas hacia atrás
    cuerpo_c = V(40, y + 1.9, 5.2)
    E_ = 1.45                                               # (más grande: es el hito del norte y se ve de lejos)
    oro = lambda d, q: jit(mezcla(ORO_AGUILA, (1.0, 0.92, 0.70), max(0.0, d.y) * 0.5), 0.04)
    bulto(M, cuerpo_c, 0.85 * E_, (0.9, 1.0, 1.35), 2 if Q >= 1 else 1, 0.08, oro, 3.0)
    bulto(M, cuerpo_c + V(0, 0.95, -0.85) * E_, 0.45 * E_, (0.8, 0.9, 1.0), 1, 0.06, oro, 4.0)
    tubo(M, cuerpo_c + V(0, 0.95, -1.25) * E_, cuerpo_c + V(0, 0.8, -1.75) * E_, 0.14 * E_, 0.02, 6, mezcla(ORO_AGUILA, OXIDO, 0.3))
    ancla("ojo_aguila", tuple(cuerpo_c + V(0.3, 1.05, -1.05) * E_))
    for lado in (-1, 1):
        for k in range(nq(6, 4)):
            a = math.radians(-10 + k * 16)
            raiz = cuerpo_c + V(lado * 0.6, 0.4, 0.1) * E_
            punta = raiz + V(lado * math.cos(a) * (2.6 - k * 0.22), 0.4 + math.sin(a) * 1.6, 0.6 + k * 0.28) * E_
            medio = raiz.lerp(punta, 0.5) + V(0, 0.15, 0.25) * E_
            cara(M, [raiz, punta, medio], jit(ORO_AGUILA, 0.05), (0, 1, 0))
            cara(M, [raiz, medio, punta], mezcla(ORO_AGUILA, OXIDO, 0.35), (0, -1, 0))
    M.choque(35.5, 2.6, 44.5, 7.6, 4.2, y - 0.2)
    ancla("mascaron", tuple(cuerpo_c))


# ================================================================= el dique de la Astraea y su lona

def dique(G):
    B = G["bajo_dique"] = Grupo()
    x0, z0, x1, z1 = 56.0, 6.0, 75.5, 29.0
    caja(B, (x0, -1.6, z0), (x1, 0.3, z1), (0.46, 0.44, 0.40))
    muro_bloques(B, (x0, -1.6, z1), (1, 0, 0), x1 - x0, 1.9, (0, 0, 1), PIEDRA, (1.1, 0.55))
    muro_bloques(B, (x0, -1.6, z0), (0, 0, 1), z1 - z0, 1.9, (-1, 0, 0), PIEDRA, (1.1, 0.55))
    for z in (8.0, 13.0, 18.0, 23.0, 27.5):                # norays
        tubo(B, (x0 + 0.5, 0.3, z), (x0 + 0.5, 0.9, z), 0.22, 0.18, nq(8, 5), HIERRO)
    # la lona: una joroba larga sobre algo con forma de barco, atada al dique; la proa asoma un palmo al norte
    L = G["edif_lona"] = Grupo()
    cx, ancho, alto = 65.8, 7.6, 8.2
    nz, nx = nq(18, 8), nq(14, 8)
    zs = [8.0 + (27.0 - 8.0) * i / nz for i in range(nz + 1)]
    rejilla = []
    for z in zs:
        t = (z - 8.0) / 19.0
        perfil_z = math.sin(math.pi * min(1.0, t * 1.15)) ** 0.35 if t < 0.87 else (1.0 - (t - 0.87) / 0.13) ** 0.5
        fila = []
        for i in range(nx + 1):
            u = -1.0 + 2.0 * i / nx
            h = alto * max(0.0, 1.0 - abs(u) ** 2.2) ** 0.55 * perfil_z
            x = cx + u * ancho * (0.55 + 0.45 * perfil_z)
            fila.append(V(x, 0.3 + h, z))
        rejilla.append(fila)
    for j in range(nz):
        for i in range(nx):
            q = [rejilla[j][i], rejilla[j][i + 1], rejilla[j + 1][i + 1], rejilla[j + 1][i]]
            remiendo = (i * 7 + j * 3) % 17 == 0
            lado_sombra = abs(i - nx / 2) / (nx / 2)            # los faldones, más oscuros que el lomo
            c = REMIENDO if remiendo else jit(mezcla((0.70, 0.66, 0.58), (0.42, 0.40, 0.36), 0.10 + 0.45 * lado_sombra ** 1.5), 0.03)
            cara(L, q, c, (0, 1, 0), TELA_M)
    for j in range(0, nz + 1, 3):                           # cabos que la sujetan, de lado a lado
        fila = rejilla[j]
        for a, b in zip(fila, fila[1:]):
            cabo(L, a + V(0, 0.04, 0), b + V(0, 0.04, 0), r=0.035, n=1)
        cabo(L, fila[0], V(x0 + 0.5, 0.8, fila[0].z), r=0.03, n=2)
    tubo(L, (cx, 0.4, 7.4), (cx, 3.2, 5.8), 0.3, 0.18, nq(8, 5), mezcla(ORO_AGUILA, TABLA[0], 0.55), mat=MADERA_M)
    L.choque(cx - ancho, 8.0, cx + ancho, 27.0, alto, 0.3)
    ancla("lona", (cx, alto * 0.6, 17.5))


# ================================================================= exportar

def material_m(nombre):
    m = bpy.data.materials.get(nombre)
    if m is not None:
        return m
    if nombre in ("base", "brillo"):
        return material(nombre)
    m = bpy.data.materials.new(nombre)
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    ca = m.node_tree.nodes.new("ShaderNodeVertexColor")
    ca.layer_name = "Color"
    gam = m.node_tree.nodes.new("ShaderNodeGamma")
    gam.inputs["Gamma"].default_value = 2.2
    m.node_tree.links.new(ca.outputs["Color"], gam.inputs["Color"])
    m.node_tree.links.new(gam.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.95
    return m


def objeto_s(nombre, M):
    me = bpy.data.meshes.new(nombre)
    me.from_pydata([tuple(v) for v in M.v], [], M.caras)
    me.update()
    me.polygons.foreach_set("material_index", M.mats)
    attr = me.color_attributes.new("Color", 'FLOAT_COLOR', 'POINT')
    cols = []
    for c in M.col:
        cols += list(c) + [1.0]
    attr.data.foreach_set("color", cols)
    me.color_attributes.active_color = attr
    me.validate(clean_customdata=False)
    for nm in ("base", "brillo", "madera", "tela"):
        me.materials.append(material_m(nm))
    me.shade_smooth()
    me.set_sharp_from_angle(angle=math.radians(40))
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    for i, (x, y0, z, w, d, h) in enumerate(getattr(M, "cajas_y", [])):
        e = bpy.data.objects.new("caja_%d_%d_%d_%d_%d" % (i, round(w * 100), round(d * 100), round(h * 100), round(y0 * 100)), None)
        e.empty_display_type = 'CUBE'
        e.location = (x, -z, y0)
        e.parent = ob
        bpy.context.scene.collection.objects.link(e)
    return ob


def construir_sunken(calidad, ruta):
    global Q
    Q = calidad
    RND.seed(11)
    ANCLAS.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    G = {}
    costillas(G)
    casco(G)
    popa(G)
    suelos(G)
    casas(G)
    archivo(G)
    cubierta(G)
    proa(G)
    dique(G)
    total = 0
    for nombre, M in G.items():
        if not M.caras:
            continue
        objeto_s(nombre, M)
        tri = M.triangulos()
        total += tri
        print("GRUPO %-22s triángulos %6d  cajas %d" % (nombre, tri, len(getattr(M, "cajas_y", []))))
    for nombre, (x, y, z) in ANCLAS.items():
        e = bpy.data.objects.new("ancla_" + nombre, None)
        e.location = (x, -z, y)
        bpy.context.scene.collection.objects.link(e)
    print("SUNKEN (calidad %.2f) triángulos: %d" % (calidad, total))
    if ruta:
        bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=False, export_animations=False,
                                  export_yup=True, export_vertex_color='ACTIVE', export_cameras=False,
                                  export_lights=False, export_apply=True)
        print("EXPORTADO", ruta)


construir_sunken(1.0, os.path.join(CARPETA, "sunken.glb") if CARPETA else "")
construir_sunken(0.55, os.path.join(CARPETA, "sunken_ligero.glb") if CARPETA else "")
