# Oakhaven 3D completo (V12, fase 2, migración región a región: Oakhaven): lo que faltaba de la ciudad 2D en la 3D.
#   - la muralla (norte, oeste, este y los dos tramos del sur, a los lados de la Puerta del Sur);
#   - la Torre de la Campana y la ronda de la muralla este, en alto (con sus tres faroles y la trampilla de la escalera);
#   - la Colina del Crematorio: un altozano de 1,2 m con su muro de contención y la subida; el crematorio de piedra hueso,
#     su chimenea y la puerta sellada; el jardín de urnas;
#   - el muro del callejón con la grieta, el Patio de las Velas cerrado y su altar (el anillo partido y las velas);
#   - la raíz cortada junto al Árbol, el tablón del gremio en la plaza y la mesa de juego del Patio del Cuervo;
#   - plantillas que la escena repite: el cofre (cuerpo y tapa), el brasero de los proyectos del gremio;
#   - los seis vecinos que faltaban (Selene, Pip, Rosa, Albar, Bastián y Doña Encina) y Aldric, como figuras sencillas
#     del mismo estilo que Ferro, Hilda y Mirta (crear_distrito.py, figura): PROVISIONALES, sin esqueleto.
# Geometría procedural propia (ningún recurso descargado), con las mismas funciones que el distrito de los oficios: este
# guion carga crear_distrito.py sin su llamada final y usa sus ayudas (caja, tubo, bulto, muro_bloques, tejado…).
#
#   blender -b --factory-startup -P crear_barrios.py -- <carpeta de salida>
#
# Escribe <carpeta>/barrios.glb (perfil alto) y <carpeta>/barrios_ligero.glb (medio y bajo). Misma semilla, mismo
# resultado. Coordenadas de Oakhaven 3D (una casilla es un metro; x al este, z al sur, y arriba), YA en su sitio, salvo
# las plantillas (plantilla_*) y los vecinos (pnj_*), en el origen con los pies en el suelo y de cara al sur.
# Objetos (nombre → qué hace con él zonas3d/oakhaven/barrios.gd):
#   edif_<n>     puede tapar a Kael: su malla cuelga de su choque y se vuelve medio transparente
#   muro_<n>     muralla, muros y lo bajo: una malla por objeto y material, con sus choques
#   suelo_<n>    se pisa por encima (el altozano de la colina, la ronda): choque, sin bloqueo en el suelo de la ciudad
#   plantilla_<n>, pnj_<n>   mallas sueltas que la escena coloca
# Vacíos: caja_<i>_<ancho>_<fondo>_<alto> (cm; choque con la base en el suelo) y ancla_<nombre> (posiciones).
import os, sys, math
AQUI = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(AQUI, "crear_distrito.py"), encoding="utf-8").read()
_src = _src[:_src.rfind("\nconstruir(1.0")]
exec(compile(_src, os.path.join(AQUI, "crear_distrito.py"), "exec"), globals())

# ---------------------------------------------------------------- medidas (las mismas en barrios.gd)
ALTO_COLINA = 1.2           # el altozano de la colina
ALTO_RONDA = 4.0            # el adarve de la ronda
ALTO_MURALLA = 4.6
ALTO_MURALLA_SUR = 3.6
COLINA = (56.0, 0.8, 79.2, 19.0)          # x0, z0, x1, z1 del altozano
RAMPA = (64.0, 19.0, 66.0, 25.0)          # la subida de la colina (de y = ALTO_COLINA en z = 19 a 0 en z = 25)
RONDA = (75.0, 28.0, 79.2, 42.0)          # el bloque de la ronda (el adarve: x 76 a 78,6)
HUESO = ((0.70, 0.67, 0.60), (0.80, 0.77, 0.69), (0.88, 0.85, 0.78))   # la piedra hueso del crematorio
HIERBA_FRIA = ((0.26, 0.34, 0.28), (0.33, 0.41, 0.33), (0.42, 0.48, 0.40))
ESCARCHA = (0.70, 0.75, 0.78)
CERA = (0.95, 0.91, 0.80)
LLAMA = (1.0, 0.78, 0.38)
BRONCE = (0.62, 0.45, 0.22)


def caja_c(M, x0, z0, x1, z1, alto):
    M.caja_choque(x0, z0, x1, z1, alto)


def almenas(M, x0, z0, x1, z1, y, a_lo_largo_x, alto=0.6, paso=1.3, ancho=0.7, pal=PIEDRA):
    """Merlones sobre un muro (de x0,z0 a x1,z1, a la altura y)."""
    largo = (x1 - x0) if a_lo_largo_x else (z1 - z0)
    n = max(1, int(largo / (paso / max(Q, 0.5))))
    for i in range(n):
        t = (i + 0.5) / n
        if a_lo_largo_x:
            cx = x0 + largo * t
            caja(M, (cx - ancho * 0.5, y, z0), (cx + ancho * 0.5, y + alto, z1), jit(pal[1], 0.05), caras="nseoa")
        else:
            cz = z0 + largo * t
            caja(M, (x0, y, cz - ancho * 0.5), (x1, y + alto, cz + ancho * 0.5), jit(pal[1], 0.05), caras="nseoa")


def muro(M, x0, z0, x1, z1, alto, vistas, pal=PIEDRA, bloque=(0.9, 0.45), choque=True, tapa=True):
    """Muro alineado de (x0, z0) a (x1, z1), de alto «alto». «vistas»: caras con sillares («n», «s», «e», «o»); las demás,
    lisas solo si se piden en mayúscula (casi nunca se ven)."""
    if tapa:
        caja(M, (x0, alto - 0.12, z0), (x1, alto, z1), mezcla(pal[1], (1, 1, 1), 0.08), caras="a")
    for c in vistas:
        if c == "s":
            muro_bloques(M, (x0, 0, z1), (1, 0, 0), x1 - x0, alto, (0, 0, 1), pal, bloque)
        elif c == "n":
            muro_bloques(M, (x1, 0, z0), (-1, 0, 0), x1 - x0, alto, (0, 0, -1), pal, bloque)
        elif c == "e":
            muro_bloques(M, (x1, 0, z1), (0, 0, -1), z1 - z0, alto, (1, 0, 0), pal, bloque)
        elif c == "o":
            muro_bloques(M, (x0, 0, z0), (0, 0, 1), z1 - z0, alto, (-1, 0, 0), pal, bloque)
        elif c in "NSEO":
            caja(M, (x0, 0, z0), (x1, alto, z1), pal[1], caras={"N": "n", "S": "s", "E": "e", "O": "o"}[c])
    if choque:
        caja_c(M, x0, z0, x1, z1, alto)


# ================================================================= la muralla

def muralla(G):
    N = G["muro_muralla_n"] = Malla()
    muro(N, 0.0, 0.0, 80.0, 0.8, ALTO_MURALLA, "s")
    almenas(N, 0.0, 0.0, 80.0, 0.35, ALTO_MURALLA, True)
    O = G["muro_muralla_o"] = Malla()
    muro(O, 0.0, 0.8, 0.8, 55.2, ALTO_MURALLA, "e")
    almenas(O, 0.0, 0.8, 0.35, 55.2, ALTO_MURALLA, False)
    E = G["muro_muralla_e"] = Malla()
    muro(E, 79.2, 0.8, 80.0, RONDA[1], ALTO_MURALLA, "o")
    muro(E, 79.2, RONDA[3], 80.0, 55.2, ALTO_MURALLA, "o")
    almenas(E, 79.65, 0.8, 80.0, RONDA[1], ALTO_MURALLA, False)
    almenas(E, 79.65, RONDA[3], 80.0, 55.2, ALTO_MURALLA, False)
    # los dos tramos del sur, a los lados de los torreones de la Puerta del Sur (puerta_sur.glb: 34,7-37,4 y 43,7-46,4):
    # tapan a Kael si va pegado a ellos, así que van aparte (edif_) y se vuelven transparentes
    for nombre, x0, x1 in (("edif_muralla_so", 0.0, 35.2), ("edif_muralla_se", 45.9, 80.0)):
        S = G[nombre] = Malla()
        muro(S, x0, 54.4, x1, 55.2, ALTO_MURALLA_SUR, "ns")
        almenas(S, x0, 54.85, x1, 55.2, ALTO_MURALLA_SUR, True)
        for x in range(int(x0) + 6, int(x1) - 3, 12):        # contrafuertes por dentro
            caja(S, (x - 0.35, 0, 53.9), (x + 0.35, ALTO_MURALLA_SUR - 0.8, 54.4), PIEDRA[0], caras="nseoa")


# ================================================================= la ronda y la Torre de la Campana

def ronda(G):
    R = G["suelo_ronda"] = Malla()
    x0, z0, x1, z1 = RONDA
    muro(R, x0, z0, x1, z1, ALTO_RONDA, "ons", choque=False, tapa=False)
    caja_c(R, x0, z0, x1, z1, ALTO_RONDA)
    # el adarve: losas
    z = z0
    while z < z1 - 0.05:
        largo = min(RND.uniform(0.7, 1.1) / math.sqrt(Q), z1 - z)
        x = 76.0
        while x < 78.55:
            ancho = min(RND.uniform(0.6, 0.9) / math.sqrt(Q), 78.6 - x)
            caja(R, (x + 0.02, ALTO_RONDA - 0.04, z + 0.02), (x + ancho - 0.02, ALTO_RONDA + 0.02, z + largo - 0.02),
                 jit(mezcla(PIEDRA[1], PIEDRA[2], RND.random()), 0.04), caras="a")
            x += ancho
        z += largo
    caja(R, (75.0, ALTO_RONDA - 0.05, z0), (76.0, ALTO_RONDA, z1), PIEDRA[0], caras="a")
    # pretil del oeste (hasta la torre), del norte y del sur; merlones al este
    P = G["muro_ronda_pretil"] = Malla()
    pretil = ALTO_RONDA + 0.75
    caja(P, (75.0, ALTO_RONDA, z0), (76.0, pretil, 38.0), PIEDRA[1], caras="nseoa")
    caja_c(P, 75.0, z0, 76.0, 38.0, pretil)
    caja(P, (75.0, ALTO_RONDA, z0), (79.2, pretil, z0 + 0.4), PIEDRA[1], caras="nseoa")
    caja_c(P, 75.0, z0, 79.2, z0 + 0.4, pretil)
    caja(P, (76.0, ALTO_RONDA, z1 - 0.3), (79.2, pretil, z1), PIEDRA[1], caras="nseoa")
    caja_c(P, 76.0, z1 - 0.3, 79.2, z1, pretil)
    caja(P, (78.6, ALTO_RONDA, z0), (79.2, ALTO_RONDA + 0.6, z1), PIEDRA[1], caras="nseoa")
    almenas(P, 78.6, z0, 79.2, z1, ALTO_RONDA + 0.6, False, alto=0.7)
    caja_c(P, 78.6, z0, 79.2, z1, ALTO_RONDA + 1.3)
    # los tres faroles de la ronda (el fuego lo pone barrios.gd: encendidos o apagados según la partida)
    for i, zf in enumerate((38.5, 34.5, 31.5)):
        b = V(78.25, ALTO_RONDA, zf)
        tubo(P, b, b + V(0, 2.2, 0), 0.06, 0.05, nq(6, 4), HIERRO)
        caja(P, (b.x - 0.42, b.y + 2.15, b.z - 0.03), (b.x + 0.02, b.y + 2.21, b.z + 0.03), HIERRO)
        caja(P, (b.x - 0.52, b.y + 1.78, b.z - 0.11), (b.x - 0.3, b.y + 2.12, b.z + 0.11), (0.20, 0.20, 0.24))   # el farol apagado
        caja(P, (b.x - 0.56, b.y + 2.12, b.z - 0.14), (b.x - 0.26, b.y + 2.18, b.z + 0.14), HIERRO)
        ancla("farol_%d" % (i + 1), (b.x - 0.41, b.y + 1.95, b.z))
    # la trampilla de la escalera, junto a la torre
    caja(P, (76.15, ALTO_RONDA, 40.35), (77.25, ALTO_RONDA + 0.05, 41.45), MADERA_OSC, caras="a")
    for k in range(4):
        caja(P, (76.2 + 0.25 * k, ALTO_RONDA + 0.05, 40.4), (76.43 + 0.25 * k, ALTO_RONDA + 0.08, 41.4), jit(MADERA, 0.08), caras="a")
    caja(P, (76.25, ALTO_RONDA + 0.08, 40.8), (77.15, ALTO_RONDA + 0.1, 40.9), HIERRO, caras="a")
    ancla("ronda_bajar", (76.5, ALTO_RONDA, 41.5))


def torre(G):
    T = G["edif_torre"] = Malla()
    x0, z0, x1, z1 = 72.0, 38.0, 76.0, 42.0
    alto = 11.0
    muro(T, x0, z0, x1, z1, alto, "soen", choque=False, tapa=False)
    caja_c(T, x0, z0, x1, z1, alto + 6.0)
    for (a, b) in ((6.0, 6.4), (alto - 0.3, alto)):                           # impostas
        caja(T, (x0 - 0.12, a, z0 - 0.12), (x1 + 0.12, b, z1 + 0.12), PIEDRA[2], caras="nseoa")
    caja(T, (x0 - 0.1, 0, z0 - 0.1), (x1 + 0.1, 0.5, z1 + 0.1), PIEDRA[0], caras="nseoa")   # zócalo
    # el campanario: cuatro pilares, la campana y el tejado de pizarra
    for (px, pz) in ((x0, z0), (x1 - 0.6, z0), (x0, z1 - 0.6), (x1 - 0.6, z1 - 0.6)):
        caja(T, (px, alto, pz), (px + 0.6, alto + 2.6, pz + 0.6), PIEDRA[1], caras="nseoa")
    caja(T, (x0 + 0.05, alto, z0 + 0.05), (x1 - 0.05, alto + 0.15, z1 - 0.05), PIEDRA[0], caras="a")
    c = V((x0 + x1) * 0.5, alto + 1.9, (z0 + z1) * 0.5)
    tubo(T, c, c - V(0, 1.1, 0), 0.22, 0.72, nq(12, 8), BRONCE, tapa_a=True, tapa_b=True)
    caja(T, (c.x - 0.04, c.y - 1.15, c.z - 0.04), (c.x + 0.04, c.y - 0.9, c.z + 0.04), HIERRO)
    caja(T, (x0 - 0.15, alto + 2.6, z0 - 0.15), (x1 + 0.15, alto + 2.85, z1 + 0.15), PIEDRA[2], caras="nseoa")
    cima = V((x0 + x1) * 0.5, alto + 6.2, (z0 + z1) * 0.5)
    e = [V(x0 - 0.35, alto + 2.85, z1 + 0.35), V(x1 + 0.35, alto + 2.85, z1 + 0.35), V(x1 + 0.35, alto + 2.85, z0 - 0.35),
         V(x0 - 0.35, alto + 2.85, z0 - 0.35)]
    for i in range(4):
        tejado(T, cima, cima, e[i], e[(i + 1) % 4], PIZARRA, 6, 4, labio=False)
    tubo(T, cima, cima + V(0, 0.9, 0), 0.05, 0.01, 5, HIERRO)
    # la puerta (al sur, al pie de la torre) y saeteras
    puerta(T, (73.5, 0.0, z1), 1.2, 2.3, (1, 0, 0), (0, 0, 1), MADERA_OSC, 5)
    caja(T, (72.75, 2.3, z1), (74.25, 2.6, z1 + 0.12), PIEDRA[2], caras="nsa")
    farolillo(T, (74.6, 2.4, z1 + 0.18))
    for y in (4.2, 7.4):
        for (cx, cz, h) in ((74.0, z1, (0, 0, 1)), (x0, 40.0, (-1, 0, 0))):
            p = V(cx, y, cz) + V(h) * 0.02
            U = V(1, 0, 0) if h[2] else V(0, 0, 1)
            cara(T, [p - U * 0.12, p + U * 0.12, p + U * 0.12 + V(0, 0.8, 0), p - U * 0.12 + V(0, 0.8, 0)], (0.08, 0.07, 0.08), h)
    ancla("puerta_torre", (73.5, 0.0, 42.6))


# ================================================================= la Colina del Crematorio

def colina(G):
    C = G["suelo_colina"] = Malla()
    x0, z0, x1, z1 = COLINA
    h = ALTO_COLINA
    caja_c(C, x0, z0, x1, z1, h)
    # la tierra de arriba: hierba fría con escarcha, en una rejilla con su color
    paso = 1.0 / max(Q, 0.5)
    nx, nz = int((x1 - x0) / paso) + 1, int((z1 - z0) / paso) + 1
    for i in range(nz):
        for j in range(nx):
            a, b = x0 + (x1 - x0) * j / nx, x0 + (x1 - x0) * (j + 1) / nx
            c, d = z0 + (z1 - z0) * i / nz, z0 + (z1 - z0) * (i + 1) / nz
            n = noise.noise(V(a * 0.23, c * 0.23, 0.7))
            col = mezcla(HIERBA_FRIA[0], HIERBA_FRIA[2], 0.5 + 0.5 * n)
            if noise.noise(V(a * 0.5, c * 0.5, 3.1)) > 0.35:
                col = mezcla(col, ESCARCHA, 0.45)
            cara(C, [(a, h, c), (b, h, c), (b, h, d), (a, h, d)], jit(col, 0.03), (0, 1, 0))
    # el muro de contención (sur, sin el hueco de la subida, y oeste) con su albardilla
    for (a, b) in ((x0, RAMPA[0]), (RAMPA[2], x1)):
        muro_bloques(C, (a, 0, z1), (1, 0, 0), b - a, h, (0, 0, 1), PIEDRA_FRIA, (0.7, 0.4))
        caja(C, (a, h - 0.02, z1 - 0.25), (b, h + 0.12, z1 + 0.06), PIEDRA_FRIA[2], caras="nsa")
    muro_bloques(C, (x0, 0, z0), (0, 0, 1), z1 - z0, h, (-1, 0, 0), PIEDRA_FRIA, (0.7, 0.4))
    caja(C, (x0 - 0.06, h - 0.02, z0), (x0 + 0.25, h + 0.12, z1), PIEDRA_FRIA[2], caras="oea")
    # la subida: rampa empedrada con peldaños bajos y su pretil
    S = G["muro_subida"] = Malla()
    rx0, rz0, rx1, rz1 = RAMPA
    n = nq(10, 6)
    for i in range(n):
        za, zb = rz1 - (rz1 - rz0) * i / n, rz1 - (rz1 - rz0) * (i + 1) / n
        ya, yb = h * i / n, h * (i + 1) / n
        cara(S, [(rx0, ya + 0.02, za), (rx1, ya + 0.02, za), (rx1, yb + 0.02, zb), (rx0, yb + 0.02, zb)],
             jit(mezcla(PIEDRA_FRIA[1], PIEDRA_FRIA[2], RND.random()), 0.05), (0, 1, 0.2))
        cara(S, [(rx0, ya + 0.02, za), (rx1, ya + 0.02, za), (rx1, ya + 0.07, za), (rx0, ya + 0.07, za)], PIEDRA_FRIA[0], (0, 0, 1))
    for (a, b) in ((rx0 - 0.3, rx0), (rx1, rx1 + 0.3)):
        for i in range(n):
            za, zb = rz1 - (rz1 - rz0) * i / n, rz1 - (rz1 - rz0) * (i + 1) / n
            caja(S, (a, 0, zb), (b, h * (i + 1) / n + 0.55, za), jit(PIEDRA_FRIA[1], 0.03), caras="eoa")
        caja_c(S, a, rz0, b, rz1, h + 0.6)
    ancla("rampa_pie", ((rx0 + rx1) * 0.5, 0.0, rz1))
    ancla("rampa_cima", ((rx0 + rx1) * 0.5, h, rz0))
    # el camino de losas, de la subida a la puerta del crematorio y al jardín de urnas
    for (a, b) in ((V(65.0, 0, 18.8), V(67.0, 0, 15.6)), (V(64.0, 0, 17.4), V(60.0, 0, 13.8))):
        largo = (b - a).length
        k = int(largo / 0.55) + 1
        for i in range(k):
            p = a.lerp(b, i / max(1, k - 1)) + V(RND.uniform(-0.25, 0.25), 0, RND.uniform(-0.15, 0.15))
            r = RND.uniform(0.22, 0.32)
            caja(C, (p.x - r, h, p.z - r * 0.8), (p.x + r, h + 0.04, p.z + r * 0.8),
                 jit(mezcla(HUESO[0], PIEDRA_FRIA[1], 0.5), 0.05), caras="a")
    # cipreses fríos y piedras
    for (x, z, s) in ((57.3, 3.0, 1.0), (58.6, 2.4, 0.85), (74.5, 3.2, 1.1), (76.5, 6.5, 0.95), (77.4, 14.0, 1.05),
                      (57.4, 17.2, 0.9), (73.6, 17.6, 0.8)):
        caja(C, (x - 0.08, h, z - 0.08), (x + 0.08, h + 0.5, z + 0.08), MADERA_OSC, caras="nseo")
        bulto(C, (x, h + 0.5 + 1.6 * s, z), 0.55 * s, (1.0, 3.2, 1.0), 1, 0.12,
              lambda d, q: jit(mezcla((0.13, 0.22, 0.17), (0.22, 0.32, 0.25), 0.5 + 0.5 * d.y), 0.04), x)
    for (x, z) in ((69.0, 3.0), (73.0, 5.2), (59.5, 16.0), (76.0, 10.0)):
        bulto(C, (x, h + 0.1, z), 0.35, (1.3, 0.6, 1.0), 1, 0.25, lambda d, q: jit(PIEDRA_FRIA[1], 0.05), z)


def crematorio(G):
    C = G["edif_crematorio"] = Malla()
    x0, z0, x1, z1 = 62.0, 7.0, 72.0, 15.0
    b = ALTO_COLINA
    alto = 4.4
    caja_c(C, x0, z0, x1, z1, b + alto + 1.0)
    caja(C, (x0 - 0.15, b, z0 - 0.15), (x1 + 0.15, b + 0.45, z1 + 0.15), HUESO[0], caras="nseoa")    # zócalo
    for (o, U, largo, N) in (((x0, b, z1), (1, 0, 0), x1 - x0, (0, 0, 1)), ((x0, b, z0), (0, 0, 1), z1 - z0, (-1, 0, 0)),
                             ((x1, b, z1), (0, 0, -1), z1 - z0, (1, 0, 0)), ((x1, b, z0), (-1, 0, 0), x1 - x0, (0, 0, -1))):
        muro_bloques(C, o, U, largo, alto, N, HUESO, (0.6, 0.34))
    for x in (x0, x1 - 0.5):                                          # pilastras de las esquinas
        for z in (z0, z1 - 0.5):
            caja(C, (x - 0.1, b, z - 0.1), (x + 0.6, b + alto + 0.2, z + 0.6), HUESO[2], caras="nseoa")
    caja(C, (x0 - 0.2, b + alto, z0 - 0.2), (x1 + 0.2, b + alto + 0.25, z1 + 0.2), HUESO[1], caras="nseoa")   # cornisa
    # tejado de pizarra a dos aguas (cumbrera de este a oeste) y sus piñones
    cy = b + alto + 0.25
    cz = (z0 + z1) * 0.5
    cumbre = cy + 2.6
    tejado(C, (x0 - 0.4, cumbre, cz), (x1 + 0.4, cumbre, cz), (x0 - 0.4, cy - 0.2, z1 + 0.55), (x1 + 0.4, cy - 0.2, z1 + 0.55), PIZARRA, 7, 16)
    tejado(C, (x1 + 0.4, cumbre, cz), (x0 - 0.4, cumbre, cz), (x1 + 0.4, cy - 0.2, z0 - 0.55), (x0 - 0.4, cy - 0.2, z0 - 0.55), PIZARRA, 7, 16)
    for x, N in ((x0, (-1, 0, 0)), (x1, (1, 0, 0))):
        cara(C, [(x, cy, z0 - 0.2), (x, cy, z1 + 0.2), (x, cumbre - 0.1, cz)], HUESO[1], N)
    # la chimenea alta, de donde sale el humo blanco
    ch = (69.6, 8.6)
    caja(C, (ch[0] - 0.6, b, ch[1] - 0.6), (ch[0] + 0.6, cumbre + 3.4, ch[1] + 0.6), HUESO[1], caras="nseo")
    muro_bloques(C, (ch[0] - 0.6, cy, ch[1] + 0.6), (1, 0, 0), 1.2, cumbre + 3.4 - cy, (0, 0, 1), HUESO, (0.4, 0.3))
    caja(C, (ch[0] - 0.72, cumbre + 3.4, ch[1] - 0.72), (ch[0] + 0.72, cumbre + 3.7, ch[1] + 0.72), HUESO[2], caras="nseoa")
    cara(C, [(ch[0] - 0.5, cumbre + 3.71, ch[1] - 0.5), (ch[0] + 0.5, cumbre + 3.71, ch[1] - 0.5),
             (ch[0] + 0.5, cumbre + 3.71, ch[1] + 0.5), (ch[0] - 0.5, cumbre + 3.71, ch[1] + 0.5)], (0.06, 0.05, 0.05), (0, 1, 0))
    ancla("humo_crematorio", (ch[0], cumbre + 3.8, ch[1]))
    # la puerta sellada: dos hojas de roble con bandas de hierro y el sello, un disco con el anillo
    px = 67.0
    caja(C, (px - 1.25, b, z1), (px + 1.25, b + 3.3, z1 + 0.25), HUESO[2], caras="nseoa")              # el marco
    for s in (-1, 1):
        tablas(C, (px - 0.95 if s < 0 else px + 0.02, b + 0.02, z1 + 0.27), (1, 0, 0), 0.93, 2.75, (0, 0, 1), MADERA_OSC, nq(4, 3))
    for hh in (0.6, 1.5, 2.4):
        caja(C, (px - 0.95, b + hh, z1 + 0.28), (px + 0.95, b + hh + 0.08, z1 + 0.31), HIERRO, caras="sa")
    caja(C, (px - 0.06, b + 0.02, z1 + 0.28), (px + 0.06, b + 2.77, z1 + 0.32), HIERRO, caras="s")
    tubo(C, (px, b + 1.55, z1 + 0.31), (px, b + 1.55, z1 + 0.38), 0.3, 0.3, nq(14, 8), (0.42, 0.10, 0.10))   # lacre
    tubo(C, (px, b + 1.55, z1 + 0.38), (px, b + 1.55, z1 + 0.42), 0.18, 0.18, nq(12, 8), HIERRO, tapa_a=False)
    caja(C, (px - 1.35, b + 3.3, z1), (px + 1.35, b + 3.55, z1 + 0.4), HUESO[1], caras="nseoa")
    # ventanas altas, estrechas y apagadas
    for x in (63.6, 65.2, 68.8, 70.4):
        p = V(x, b + 2.0, z1 + 0.02)
        cara(C, [p - V(0.14, 0, 0), p + V(0.14, 0, 0), p + V(0.14, 1.3, 0), p - V(0.14, 1.3, 0)], (0.10, 0.11, 0.14), (0, 0, 1))
        cara(C, [p - V(0.14, 0, 0) + V(0, 1.3, 0), p + V(0.14, 1.3, 0), p + V(0, 1.48, 0)], (0.10, 0.11, 0.14), (0, 0, 1))
    # dos faroles de piedra a los lados de la puerta (luz fría)
    for s in (-1, 1):
        q = V(px + 2.5 * s, b, z1 + 0.9)
        caja(C, (q.x - 0.2, q.y, q.z - 0.2), (q.x + 0.2, q.y + 1.1, q.z + 0.2), HUESO[1], caras="nseoa")
        caja(C, (q.x - 0.14, q.y + 1.1, q.z - 0.14), (q.x + 0.14, q.y + 1.4, q.z + 0.14), (0.82, 0.88, 0.95), BRILLO, jitter=0)
        caja(C, (q.x - 0.24, q.y + 1.4, q.z - 0.24), (q.x + 0.24, q.y + 1.5, q.z + 0.24), HUESO[2], caras="nseoa")
        caja_c(C, q.x - 0.22, q.z - 0.22, q.x + 0.22, q.z + 0.22, b + 1.5)
    ancla("sello", (px, b, z1 + 1.0))


def urnas(G):
    U = G["muro_urnas"] = Malla()
    x0, z0, x1, z1 = 57.0, 9.0, 62.0, 14.0
    b = ALTO_COLINA
    for (a, c, d, e) in ((x0, z0, x1, z0 + 0.25), (x0, z1 - 0.25, 58.9, z1), (60.1, z1 - 0.25, x1, z1),
                         (x0, z0, x0 + 0.25, z1)):
        caja(U, (a, b, c), (d, b + 0.35, e), PIEDRA_FRIA[1], caras="nseoa")
    for i in range(3):
        for j in range(3):
            if i == 1 and j == 2:
                continue                                                 # el paso de la entrada
            cx, cz = 58.0 + 1.6 * i, 10.0 + 1.5 * j
            caja(U, (cx - 0.26, b, cz - 0.26), (cx + 0.26, b + 0.55, cz + 0.26), HUESO[0], caras="nseoa")
            col = [HUESO[1], (0.55, 0.52, 0.50), (0.45, 0.50, 0.55)][(i + j) % 3]
            tubo(U, (cx, b + 0.55, cz), (cx, b + 0.85, cz), 0.14, 0.24, nq(10, 6), col, tapa_a=True, tapa_b=False)
            tubo(U, (cx, b + 0.85, cz), (cx, b + 1.08, cz), 0.24, 0.12, nq(10, 6), col, tapa_a=False, tapa_b=False)
            tubo(U, (cx, b + 1.08, cz), (cx, b + 1.15, cz), 0.13, 0.13, nq(10, 6), mezcla(col, (0, 0, 0), 0.2), tapa_a=False)
            caja_c(U, cx - 0.28, cz - 0.28, cx + 0.28, cz + 0.28, b + 1.2)
    for (x, z) in ((61.2, 9.7), (61.2, 13.3)):
        bulto(U, (x, b + 0.25, z), 0.3, (1.2, 0.7, 1.1), 1, 0.2, lambda d, q: jit((0.24, 0.32, 0.27), 0.05), z)


# ================================================================= el callejón y el Patio de las Velas

def velas(G):
    M = G["muro_velas"] = Malla()
    alto = 3.0
    # el muro del callejón (al norte del patio) con la grieta: la grieta se ve, pero no se cruza andando (una pieza la pasa)
    for (a, b) in ((18.4, 23.36), (23.64, 28.6)):
        muro(M, a, 35.1, b, 35.9, alto, "ns", PIEDRA, (0.55, 0.32), choque=False)
    caja_c(M, 18.4, 35.1, 28.6, 35.9, alto)
    for (a, b) in ((23.36, 23.42), (23.58, 23.64)):                      # los labios de la grieta, oscuros
        caja(M, (a, 0, 35.1), (b, alto - 0.4, 35.9), (0.10, 0.08, 0.08), caras="nseo")
    cara(M, [(23.42, 0.0, 35.5), (23.58, 0.0, 35.5), (23.56, alto - 0.5, 35.5), (23.44, alto - 0.5, 35.5)], (1.0, 0.70, 0.36), (0, 0, 1), BRILLO)
    cara(M, [(23.42, 0.0, 35.5), (23.58, 0.0, 35.5), (23.56, alto - 0.5, 35.5), (23.44, alto - 0.5, 35.5)], (1.0, 0.70, 0.36), (0, 0, -1), BRILLO)
    caja(M, (23.36, alto - 0.4, 35.1), (23.64, alto, 35.9), PIEDRA[1], caras="nsa")
    muro(M, 18.4, 35.9, 19.0, 40.6, alto, "eo")
    muro(M, 28.0, 35.9, 28.6, 40.6, alto, "eo")
    S = G["edif_velas_sur"] = Malla()
    muro(S, 18.4, 40.0, 28.6, 40.6, 2.4, "ns", PIEDRA, (0.55, 0.32))
    # el suelo del patio: losas viejas con musgo
    B = G["muro_velas_suelo"] = Malla()
    z = 36.0
    while z < 39.95:
        x = 19.05
        while x < 27.95:
            w = min(RND.uniform(0.5, 0.8), 27.95 - x)
            col = jit(mezcla(PIEDRA[0], (0.30, 0.38, 0.26), RND.uniform(0.1, 0.5)), 0.04)
            caja(B, (x + 0.03, 0.0, z + 0.03), (x + w - 0.03, 0.035, z + 0.45 - 0.03), col, caras="a")
            x += w
        z += 0.45
    # el altar pequeño: un bloque de piedra, el anillo partido y las velas (las llamas, de barrios.gd)
    ax, az = 25.5, 38.3
    caja(B, (ax - 0.7, 0, az - 0.35), (ax + 0.7, 0.75, az + 0.35), PIEDRA[1], caras="nseoa")
    caja(B, (ax - 0.78, 0.75, az - 0.42), (ax + 0.78, 0.85, az + 0.42), PIEDRA[2], caras="nseoa")
    caja_c(B, ax - 0.8, az - 0.45, ax + 0.8, az + 0.45, 0.9)
    for (a0, a1, dx) in ((0.25, 2.9, -0.04), (3.3, 5.95, 0.04)):         # el anillo, partido en dos
        k = 7
        for i in range(k):
            t0 = a0 + (a1 - a0) * i / k
            t1 = a0 + (a1 - a0) * (i + 1) / k
            p0 = V(ax + dx + math.cos(t0) * 0.16, 0.86 + 0.16 + math.sin(t0) * 0.16, az + 0.1)
            p1 = V(ax + dx + math.cos(t1) * 0.16, 0.86 + 0.16 + math.sin(t1) * 0.16, az + 0.1)
            tubo(B, p0, p1, 0.022, 0.022, 5, ORO, tapa_a=False, tapa_b=False)
    for i, (dx, dz, h) in enumerate(((-0.55, 0.0, 0.16), (-0.3, -0.18, 0.24), (0.32, -0.15, 0.22), (0.56, 0.05, 0.14),
                                     (0.1, -0.25, 0.18))):
        if Q < 1.0 and i == 4:
            break
        p = V(ax + dx, 0.85, az + dz)
        tubo(B, p, p + V(0, h, 0), 0.035, 0.032, 6, CERA)
        ancla("vela_%d" % i, (p.x, p.y + h + 0.05, p.z))
    ancla("altar_velas", (ax, 0.0, az))


# ================================================================= piezas sueltas de la ciudad

def piezas(G):
    P = G["muro_tablon_gremio"] = Malla()
    # el tablón del Gremio de aventureros, en la plaza (37, 23): dos postes, el tablero con contratos y el escudo
    cx, cz = 37.0, 22.75
    for s in (-1, 1):
        caja(P, (cx + 0.62 * s - 0.06, 0, cz - 0.06), (cx + 0.62 * s + 0.06, 2.15, cz + 0.06), MADERA_OSC)
    caja(P, (cx - 0.68, 0.85, cz - 0.04), (cx + 0.68, 1.85, cz + 0.04), MADERA, caras="nsa")
    for (a, c, w, hh) in ((-0.55, 1.2, 0.34, 0.45), (-0.12, 1.25, 0.3, 0.4), (0.25, 1.15, 0.36, 0.5), (-0.4, 0.95, 0.4, 0.2)):
        caja(P, (cx + a, c, cz + 0.04), (cx + a + w, c + hh, cz + 0.06), jit(CREMA, 0.04), caras="s")
    caja(P, (cx - 0.82, 1.95, cz - 0.3), (cx + 0.82, 2.05, cz + 0.3), (0.34, 0.20, 0.14), caras="nseoa")
    emblema_escudo(P, (cx, 1.88, cz + 0.07), V(1, 0, 0), V(0, 0, 1), 0.45)
    caja_c(P, cx - 0.7, cz - 0.12, cx + 0.7, cz + 0.12, 2.1)
    # la mesa de juego del Patio del Cuervo (14,7, 30,7): redonda, con las cartas, y dos taburetes
    J = G["muro_mesa_parejas"] = Malla()
    mx, mz = 14.7, 30.75
    tubo(J, (mx, 0, mz), (mx, 0.68, mz), 0.06, 0.05, 6, MADERA_OSC)
    tubo(J, (mx, 0.68, mz), (mx, 0.74, mz), 0.42, 0.42, nq(12, 8), MADERA_CLARA)
    for i in range(6):
        a = i * 1.05
        p = V(mx + math.cos(a) * 0.22, 0.745, mz + math.sin(a) * 0.2)
        caja_t(J, p, (0.1, 0.008, 0.14), (math.cos(a + 0.5), 0, math.sin(a + 0.5)), (0, 1, 0), CREMA if i % 2 else (0.55, 0.20, 0.18))
    for (dx, dz) in ((-0.62, 0.15), (0.6, -0.1)):
        tubo(J, (mx + dx, 0, mz + dz), (mx + dx, 0.44, mz + dz), 0.17, 0.15, 7, MADERA)
    caja_c(J, mx - 0.45, mz - 0.45, mx + 0.45, mz + 0.45, 0.8)
    # la raíz cortada junto al Árbol (45, 10): un tocón con sus anillos (el negro, muy hondo)
    R = G["muro_raiz_cortada"] = Malla()
    rx, rz = 45.2, 9.7
    tubo(R, (rx, 0, rz), (rx + 0.1, 0.55, rz), 0.48, 0.42, nq(12, 8), (0.36, 0.26, 0.18), tapa_a=False, tapa_b=False, plano=True)
    for k, r in enumerate((0.42, 0.34, 0.27, 0.2, 0.13, 0.07)):
        col = (0.14, 0.10, 0.08) if k == 3 else ((0.72, 0.58, 0.40) if k % 2 == 0 else (0.62, 0.48, 0.32))
        tubo(R, (rx + 0.1, 0.55 + 0.004 * k, rz), (rx + 0.1, 0.556 + 0.004 * k, rz), r, r, nq(12, 8), col, tapa_a=False)
    for a in (0.6, 2.4, 4.4):
        tubo(R, (rx + math.cos(a) * 0.35, 0.15, rz + math.sin(a) * 0.35), (rx + math.cos(a) * 0.95, 0.02, rz + math.sin(a) * 0.95),
             0.14, 0.06, 6, (0.34, 0.25, 0.17))
    caja_c(R, rx - 0.45, rz - 0.45, rx + 0.55, rz + 0.45, 0.6)


# ================================================================= plantillas (en el origen)

def plantillas(G):
    B = G["plantilla_cofre_base"] = Malla()
    caja(B, (-0.38, 0, -0.24), (0.38, 0.36, 0.24), MADERA, caras="nseoa")
    for x in (-0.3, 0.3):
        caja(B, (x - 0.03, 0, -0.25), (x + 0.03, 0.37, 0.25), HIERRO, caras="nseoa")
    caja(B, (-0.06, 0.2, 0.24), (0.06, 0.32, 0.27), ORO, caras="s")
    caja(B, (-0.34, 0.33, -0.2), (0.34, 0.35, 0.2), (0.25, 0.14, 0.08), caras="a")
    T = G["plantilla_cofre_tapa"] = Malla()                                  # origen en la bisagra (atrás, arriba)
    n = nq(6, 4)
    for i in range(n):
        a0, a1 = math.pi * i / n, math.pi * (i + 1) / n
        z0, y0 = 0.24 - 0.24 * (1 - math.cos(a0)), math.sin(a0) * 0.2
        z1, y1 = 0.24 - 0.24 * (1 - math.cos(a1)), math.sin(a1) * 0.2
        cara(T, [(-0.38, y0, z0 + 0.24), (0.38, y0, z0 + 0.24), (0.38, y1, z1 + 0.24), (-0.38, y1, z1 + 0.24)],
             jit(MADERA, 0.05), (0, (y0 + y1) * 0.5 + 0.01, (z0 + z1) * 0.5 + 0.0001))
    for x in (-0.38, 0.38):
        pts = [(x, math.sin(math.pi * i / n) * 0.2, 0.48 - 0.24 * (1 - math.cos(math.pi * i / n))) for i in range(n + 1)]
        cara(T, pts, MADERA_OSC, (1 if x > 0 else -1, 0, 0))
    for x in (-0.3, 0.3):
        for i in range(n):
            a0, a1 = math.pi * i / n, math.pi * (i + 1) / n
            p0 = V(x, math.sin(a0) * 0.205, 0.48 - 0.24 * (1 - math.cos(a0)))
            p1 = V(x, math.sin(a1) * 0.205, 0.48 - 0.24 * (1 - math.cos(a1)))
            caja_t(T, (p0 + p1) * 0.5, (0.06, 0.012, (p1 - p0).length + 0.01), (1, 0, 0), (0, p0.y + p1.y + 0.001, (p0.z + p1.z) * 0.5 - 0.24), HIERRO)
    R = G["plantilla_brasero"] = Malla()
    for a in (0.3, 2.4, 4.5):
        tubo(R, (math.cos(a) * 0.28, 0, math.sin(a) * 0.28), (math.cos(a) * 0.12, 0.62, math.sin(a) * 0.12), 0.03, 0.03, 5, HIERRO)
    tubo(R, (0, 0.6, 0), (0, 0.85, 0), 0.18, 0.36, nq(10, 7), HIERRO, tapa_a=True, tapa_b=False)
    bulto(R, (0, 0.8, 0), 0.3, (1.0, 0.3, 1.0), 1, 0.3, lambda d, q: elige(BRASA), 1.0, mat=BRILLO)


# ================================================================= los vecinos (PROVISIONALES, sin esqueleto)

def capa(M, s, ancho, color, largo=1.05):
    """Una capa por la espalda, de los hombros hacia abajo."""
    y0, y1 = 1.36 * s, (1.36 - largo) * s
    cara(M, [(-0.28 * ancho, y0, -0.2 * ancho), (0.28 * ancho, y0, -0.2 * ancho), (0.36 * ancho, y1, -0.32 * ancho),
             (-0.36 * ancho, y1, -0.32 * ancho)], color, (0, 0, -1))
    cara(M, [(-0.28 * ancho, y0, -0.2 * ancho), (0.28 * ancho, y0, -0.2 * ancho), (0.36 * ancho, y1, -0.32 * ancho),
             (-0.36 * ancho, y1, -0.32 * ancho)], mezcla(color, (0, 0, 0), 0.3), (0, 0, 1))


def vecinos(G):
    def f(nombre, **k):
        M = Malla()
        G["pnj_" + nombre] = M
        extra = k.pop("extra", None)
        figura(M, **k)
        if extra:
            extra(M, k.get("alto", 1.75) / 1.75, k.get("ancho", 1.0))
    def aldric(M, s, a):
        capa(M, s, a, AZUL, 1.15)
        tubo(M, (0.42, 0.0, 0.08), (0.42, 2.35, 0.08), 0.025, 0.02, 5, MADERA)
        tubo(M, (0.42, 2.35, 0.08), (0.42, 2.6, 0.08), 0.05, 0.0, 5, ACERO_CLARO, tapa_b=False)
        caja(M, (-0.3 * a, 1.2 * s, -0.02), (0.3 * a, 1.36 * s, 0.25 * a), ACERO, caras="nseoa")       # hombreras
        tubo(M, (0, 1.6 * s, 0.0), (0, 1.74 * s, -0.01), 0.175, 0.15, 9, ACERO, tapa_a=False)         # yelmo abierto
    f("aldric", alto=1.86, ancho=1.18, ropa=ACERO, pelo=(0.30, 0.22, 0.16), barba=(0.30, 0.22, 0.16), extra=aldric)
    def selene(M, s, a):
        tubo(M, (0, 1.68 * s, -0.01), (0, 2.2 * s, -0.05), 0.24, 0.0, 9, (0.24, 0.15, 0.36), tapa_a=True, tapa_b=False)
        tubo(M, (0, 1.66 * s, -0.01), (0, 1.69 * s, -0.01), 0.36, 0.36, 10, (0.24, 0.15, 0.36))
        tubo(M, (0.4, 0.0, 0.1), (0.4, 1.95, 0.1), 0.025, 0.025, 5, MADERA_OSC)
        bulto(M, (0.4, 2.0, 0.1), 0.07, (1, 1.2, 1), 0, 0.0, (0.55, 0.85, 1.0), 2, mat=BRILLO)
    f("selene", alto=1.72, ancho=1.0, ropa=(0.36, 0.24, 0.54), falda=(0.30, 0.20, 0.46), pelo=(0.86, 0.84, 0.88),
      peinado="trenza", extra=selene)
    def pip(M, s, a):
        bulto(M, (0, 1.64 * s, -0.04), 0.19, (1.05, 1.0, 1.1), 1, 0.06, (0.38, 0.30, 0.20), 3)        # la capucha
        caja(M, (-0.2 * a, 1.32 * s, -0.05), (0.2 * a, 1.4 * s, 0.2 * a), ROJO, caras="nseoa")       # pañuelo
        caja(M, (0.18 * a, 0.78 * s, 0.1), (0.3 * a, 0.92 * s, 0.22), CUERO, caras="nseoa")          # la bolsa
    f("pip", alto=1.5, ancho=0.92, ropa=(0.32, 0.42, 0.24), pelo=(0.36, 0.22, 0.12), peinado="mono", extra=pip)
    def rosa(M, s, a):
        b = V(0.32 * a, 0.8 * s, 0.18)
        tubo(M, b, b + V(0, 0.16, 0), 0.15, 0.17, 8, MADERA_CLARA)
        for k in range(nq(6, 4)):
            bulto(M, b + V(math.cos(k) * 0.08, 0.19, math.sin(k) * 0.08), 0.05, (1, 0.8, 1), 0, 0.2, FLORES[k % 4], k)
    f("rosa", alto=1.62, ancho=0.98, ropa=CREMA, falda=(0.74, 0.36, 0.42), delantal=(0.95, 0.93, 0.88),
      pelo=(0.86, 0.68, 0.36), peinado="trenza", extra=rosa)
    def albar(M, s, a):
        b = V(0.34 * a, 0.72 * s, 0.14)
        farolillo(M, (b.x, b.y - 0.2, b.z), colgado=True)
        capa(M, s, a, (0.50, 0.50, 0.55), 1.2)
    f("albar", alto=1.76, ancho=0.94, ropa=(0.70, 0.70, 0.74), falda=(0.58, 0.58, 0.62), pelo=(0.82, 0.82, 0.84),
      barba=(0.88, 0.88, 0.90), extra=albar)
    def bastian(M, s, a):
        tubo(M, (0, 1.64 * s, 0), (0, 1.72 * s, -0.02), 0.17, 0.15, 9, AZUL, tapa_a=False)              # la gorra
        caja(M, (-0.1, 1.66 * s, 0.1), (0.1, 1.68 * s, 0.24), AZUL, caras="nseoa")
        tubo(M, (0.3, 0.0, 0.12), (0.34, 2.1, 0.12), 0.02, 0.02, 5, MADERA)                              # la pértiga
        caja(M, (0.31, 2.05, 0.06), (0.37, 2.12, 0.2), HIERRO, caras="nseoa")
    f("bastian", alto=1.28, ancho=0.86, ropa=(0.30, 0.42, 0.70), pelo=(0.52, 0.36, 0.20), peinado="mono", extra=bastian)
    def encina(M, s, a):
        capa(M, s, a, (0.30, 0.42, 0.26), 0.6)                                                          # el chal
        tubo(M, (-0.32 * a, 0.0, 0.16), (-0.3 * a, 0.95 * s, 0.14), 0.025, 0.025, 5, MADERA_OSC)       # el bastón
    f("encina", alto=1.5, ancho=1.0, ropa=(0.40, 0.52, 0.32), falda=(0.42, 0.30, 0.20), pelo=(0.90, 0.90, 0.90),
      peinado="mono", extra=encina)


def construir_barrios(calidad, ruta):
    global Q
    Q = calidad
    globals()["Q"] = calidad
    RND.seed(11)
    ANCLAS.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    G = {}
    muralla(G)
    ronda(G)
    torre(G)
    colina(G)
    crematorio(G)
    urnas(G)
    velas(G)
    piezas(G)
    plantillas(G)
    vecinos(G)
    total = 0
    for nombre, M in G.items():
        objeto(nombre, M)
        tri = M.triangulos()
        total += tri
        print("GRUPO %-24s triángulos %6d  cajas %d" % (nombre, tri, len(M.cajas)))
    for nombre, (x, y, z) in ANCLAS.items():
        e = bpy.data.objects.new("ancla_" + nombre, None)
        e.location = (x, -z, y)
        bpy.context.scene.collection.objects.link(e)
    print("BARRIOS (calidad %.2f) triángulos: %d" % (calidad, total))
    if ruta:
        bpy.ops.export_scene.gltf(filepath=ruta, export_format='GLB', use_selection=False, export_animations=False,
                                  export_yup=True, export_vertex_color='ACTIVE', export_cameras=False,
                                  export_lights=False, export_apply=True)
        print("EXPORTADO", ruta)


construir_barrios(1.0, os.path.join(CARPETA, "barrios.glb") if CARPETA else "")
construir_barrios(0.55, os.path.join(CARPETA, "barrios_ligero.glb") if CARPETA else "")
