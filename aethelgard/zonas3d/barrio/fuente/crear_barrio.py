# BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11, agente A; EN PRUEBAS: solo desde el banco de pruebas de Auditoría).
# Generador de los 6 tramos con el ACABADO APROBADO de la muestra de la calle (zonas3d/muestra_calle/: su arquitectura de
# entramado, sus colores, sus texturas, sus 4 sombreados y su luz horneada de la tarde dorada), cada tramo con su
# identidad: patio de caravanas con establo, calle comercial con el horno, plaza de mercado con lonja, patio de talleres en
# rampa, calle de las casas con tendederos y huertos, y el atajo con escalones, arco y hornacina.
# Hecho desde cero con este guion y el kit (kit_barrio.py, copia refactorizada del de crear_calle.py, que no se toca).
# Ningún recurso descargado, de pago ni de la nube. Misma semilla por sector, mismo resultado.
#
#   blender -b --factory-startup -P crear_barrio.py -- <carpeta zonas3d/barrio> [opciones]
#     --solo s1,s2              hornea y exporta solo esos sectores (construye TODOS: los demás tapan y rebotan luz)
#     --fase arquitectura|completa   sin o con atrezo y vegetación (por defecto completa)
#     --sin-horneado            sin luz horneada (no exporta: para mirar la geometría y los números)
#     --sin-recorte             sin quitar lo que ninguna cámara ve
#     --muestras N              muestras de Cycles (por defecto 256, como la muestra)
#     --res N                   lado del mapa de luz grande (por defecto 2048; el pequeño es la mitad)
#
# Lee <carpeta>/modelos/barrio.json (lo escribe fuente/exportar_trazado.gd DESDE trazado.gd: suelos, cotas, bloques,
# anclas, zonas de cámara). Escribe en <carpeta>/modelos/, por sector <s>:
#   barrio_<s>.glb             objetos «fijo_<s>» (mapa de luz, UV1), «piezas_<s>» y «vegetacion_<s>» (luz en los
#                              vértices), vacíos «choque_<id>» (uno por bloque sólido del trazado, con sus mismas medidas,
#                              más «choque_<s>_p<n>» para piezas sueltas en lo andable) y «ancla_<s>_<nombre>»
#   barrio_<s>_luz_<res>.png y _<res/2>.png   mapa de luz (luz / ESCALA común, gamma 2,2)
#   barrio_<s>_sondas.png      rejilla de 0,25 m sobre el rectángulo del sector (+1 m): R = sol, G = cielo a 1 m del suelo
#   barrio_luz.json            ESCALA común, el sol y el cielo (los de la muestra), por sector: el origen y el tamaño de su
#                              rejilla de sondas, los triángulos y qué sectores se ven desde cada zona de cámara
import sys, os, json, math, random, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit_barrio as K
from kit_barrio import (Vector, Matrix, Malla, R, caja, caja_mm, placa, cilindro, cono, viga, voronoi, losa, ventana,
                        entramado, faldon, cumbrera, chimenea, farol, farol_pared, farol_debil, barril, cajon, maceta,
                        mata, mata_flores, hojas, hiedra, jit, mezcla, elige, lin, ruido2, nota, choque, ancla_p, marco,
                        REVOQUE_A, REVOQUE_B, REVOQUE_C, MADERA_OSC, MADERA, MADERA_GRIS, VERDE_PUERTA, AZUL_POSTIGO,
                        ROJO_POSTIGO, TEJA, PIZARRA, MUSGO, PIEDRA, SILLAR, TIERRA, HIERRO, LATON, BARRO, CRISTAL,
                        LUZ_FAROL, LUZ_VENTANA, HOJA, HIERBA, FLORES, TELAS)
import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = os.path.abspath(argv[0]) if argv and not argv[0].startswith("--") else ""
SOLO = None
FASE = "completa"
HORNEAR = True
RECORTE = True
RES = 2048
i = 0
while i < len(argv):
    a = argv[i]
    if a == "--solo":
        SOLO = [s for s in argv[i + 1].split(",") if s]; i += 1
    elif a == "--fase":
        FASE = argv[i + 1]; i += 1
    elif a == "--sin-horneado":
        HORNEAR = False
    elif a == "--sin-recorte":
        RECORTE = False
    elif a == "--muestras":
        K.MUESTRAS = int(argv[i + 1]); i += 1
    elif a == "--res":
        RES = int(argv[i + 1]); i += 1
    i += 1
DECORADO = FASE == "completa"
# La escala de la luz, COMÚN a todos los sectores: la de la muestra aprobada (calle_luz.json, «escala»). Con una escala
# por horneado habría saltos de brillo en las costuras entre sectores.
ESCALA = 2.229212239845512
SEMILLAS = {"caravanas": 1601, "comercial": 1602, "plaza": 1603, "talleres": 1604, "residencial": 1605, "atajo": 1606}

# ---------------------------------------------------------------- el trazado (barrio.json, escrito desde trazado.gd)
with open(os.path.join(CARPETA, "modelos", "barrio.json"), encoding="utf-8") as f:
    D = json.load(f)
ORDEN = D["orden"]
SECTORES = {s: tuple(r) for s, r in D["sectores"].items()}
SUELOS = [(s[0], tuple(s[1]), s[2], s[3], s[4]) for s in D["suelos"]]
BLOQUES = [(b[0], b[1], tuple(b[2]), b[3], b[4], b[5], b[6]) for b in D["bloques"]]
BLOQUE = {b[0]: b for b in BLOQUES}
ANCLAS_T = {k: tuple(v) for k, v in D["anclas"].items()}
PUERTAS = D["puertas"]
GRAFO = D["grafo"]
ZONAS = D["camara_zonas"]
CAM = D["camara"]


def dentro(r, x, z):
    return r[0] <= x < r[0] + r[2] and r[1] <= z < r[1] + r[3]


def suelo_en(x, z):
    for k, s in enumerate(SUELOS):
        if dentro(s[1], x, z):
            return k
    return -1


def bloque_en(x, z):
    for b in BLOQUES:
        if b[6] and dentro(b[2], x, z):
            return b[0]
    return ""


def andable(x, z):
    return suelo_en(x, z) >= 0 and bloque_en(x, z) == ""


def _altura_suelo(k, x, z):
    s = SUELOS[k]
    r = s[1]
    if s[2] == "x":
        return s[3] + (s[4] - s[3]) * min(1.0, max(0.0, (x - r[0]) / r[2]))
    if s[2] == "z":
        return s[3] + (s[4] - s[3]) * min(1.0, max(0.0, (z - r[1]) / r[3]))
    return s[3]


def altura(x, z):
    """La de trazado.gd: la cota de lo que se pisa (fuera, la del suelo más cercano)."""
    k = suelo_en(x, z)
    if k < 0:
        mejor, dmin = 0, 1e9
        for j, s in enumerate(SUELOS):
            r = s[1]
            cx, cz = min(max(x, r[0]), r[0] + r[2]), min(max(z, r[1]), r[1] + r[3])
            d = math.hypot(cx - x, cz - z)
            if d < dmin:
                dmin, mejor = d, j
        k = mejor
    return _altura_suelo(k, x, z)


def pendiente(x, z):
    """(dy/dx, dy/dz) del suelo en (x, z) (para inclinar las losas de las rampas)."""
    k = suelo_en(x, z)
    if k < 0:
        return (0.0, 0.0)
    s = SUELOS[k]
    if s[2] == "x":
        return ((s[4] - s[3]) / s[1][2], 0.0)
    if s[2] == "z":
        return (0.0, (s[4] - s[3]) / s[1][3])
    return (0.0, 0.0)


def sector_de(x, z):
    k = suelo_en(x, z)
    if k >= 0:
        return SUELOS[k][0]
    for s in ORDEN:
        if dentro(SECTORES[s], x, z):
            return s
    return ""


def dist_rect(r, x, z):
    cx, cz = min(max(x, r[0]), r[0] + r[2]), min(max(z, r[1]), r[1] + r[3])
    return math.hypot(cx - x, cz - z)


def sector_terreno(x, z):
    """El sector al que va un trozo de terreno: el de sector_de o, fuera de todos, el del rectángulo más cercano."""
    s = sector_de(x, z)
    if s:
        return s
    return min(ORDEN, key=lambda q: dist_rect(SECTORES[q], x, z))


# Cotas del terreno que no se pisa (lo que el trazado no dice): las terrazas de los huertos y de detrás de las casas a
# 1,4; la explanada baja al sur de la plaza; fuera del muro, el camino a 0.
TERRAZAS = [((-41.0, -26.0, 36.5, 9.0), 1.4), ((-60.0, -80.0, 80.0, 50.0), 1.4), ((-40.0, -17.0, 30.0, 7.5), 1.4),
            ((-13.5, -30.0, 8.5, 18.0), 1.4)]
BAJOS = [((-12.0, 7.6, 24.0, 10.0), 0.0), ((-120.0, -30.0, 67.0, 60.0), 0.0)]


def cota(x, z):
    """La altura del terreno en (x, z): la del suelo si se pisa; si no, la de su terraza o la del suelo más cercano."""
    if suelo_en(x, z) >= 0:
        return altura(x, z)
    for r, y in BAJOS:
        if dentro(r, x, z):
            return y
    for r, y in TERRAZAS:
        if dentro(r, x, z):
            return y
    return altura(x, z)


# ---------------------------------------------------------------- rutas: dónde no se pone nada con choque
def _seg_dist(px, pz, a, b):
    ax, az, bx, bz = a[0], a[2], b[0], b[2]
    dx, dz = bx - ax, bz - az
    L2 = dx * dx + dz * dz
    t = 0.0 if L2 < 1e-9 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / L2))
    return math.hypot(px - (ax + dx * t), pz - (az + dz * t))


RUTAS = []
for n, vec in GRAFO.items():
    for m in vec:
        RUTAS.append((ANCLAS_T[n], ANCLAS_T[m]))
BUCLE = D["bucle"]
for k in range(len(BUCLE) - 1):
    RUTAS.append((ANCLAS_T[BUCLE[k]], ANCLAS_T[BUCLE[k + 1]]))
PUNTOS = list(ANCLAS_T.values()) + [tuple(p["fuera"]) for p in PUERTAS.values()]


def sitio_libre(x, z, r):
    """¿Se puede poner aquí una pieza con choque de radio r? Fuera de lo andable, sí; dentro, solo lejos (≥ r + 0,8 m) de
    las aristas del grafo y del bucle de la prueba, de las anclas, de las puertas y de los umbrales."""
    if not andable(x, z) and bloque_en(x, z) == "":
        return True
    if bloque_en(x, z) != "":
        return True
    for a, b in RUTAS:
        if _seg_dist(x, z, a, b) < r + 0.8:
            return False
    for p in PUNTOS:
        if math.hypot(x - p[0], z - p[2]) < r + 1.0:
            return False
    for pr in D["pasos"].values():
        if dist_rect(pr, x, z) < r + 0.6:
            return False
    return True


def pieza_con_choque(c, s, yaw=0.0):
    """Un choque para una pieza suelta SOLO si cae en lo andable (si no, ya no se pisa). Devuelve False si estorbaría
    una ruta (la pieza no se pone)."""
    x, z = c[0], c[2]
    r = max(s[0], s[2]) * 0.5
    if not sitio_libre(x, z, r):
        return False
    if andable(x, z):
        PIEZAS_CHOQUE[0] += 1
        choque(c, (s[0], max(1.0, s[1]), s[2]), yaw, "%s_p%02d" % (K.SECTOR.nombre, PIEZAS_CHOQUE[0]))
    return True


PIEZAS_CHOQUE = [0]


# ---------------------------------------------------------------- azar del sector en obra
def U(a, b):
    return K.RND.uniform(a, b)


def AZ():
    return K.RND.random()


def CH(seq):
    return K.RND.choice(seq)


# Colores del barrio (todos dentro de la paleta de la muestra: revoques crema y ocre, madera rojiza, teja anaranjada,
# acentos de postigos y flores)
REVOQUE_D = (0.94, 0.85, 0.68)       # crema dorada
REVOQUE_E = (0.90, 0.80, 0.70)       # rosado apagado
REVOQUE_F = (0.88, 0.86, 0.78)       # cal gris
OCRE_POSTIGO = (0.78, 0.60, 0.30)
VERDE_POSTIGO = (0.36, 0.54, 0.40)
PAJA = (0.90, 0.78, 0.46)
AGUA = (0.20, 0.30, 0.32)
OSCURO = (0.08, 0.07, 0.07)
PAN = (0.80, 0.56, 0.30)
PAN_OSC = (0.62, 0.38, 0.20)


# ================================================================ arquitectura (en el marco local de cada fachada)
# Convención de todos los constructores de casas: la fachada está en el plano z = 0 y mira a +z (el «sur» de las piezas
# de la muestra); va de u = 0 a u = W en x; la casa se mete hacia −z hasta −F; y = 0 es el pie de la fachada. El
# marco (kit.marco) la pone en su sitio y la gira si mira al este o al oeste.

def postes_auto(W, huecos, paso=1.35):
    """Los pies derechos de un entramado: a los lados de cada hueco (ventana) y, en los vanos largos, intermedios.
    Devuelve (postes, vanos sin hueco) para los jabalcones."""
    xs = []
    for u, a in huecos:
        xs += [u - a / 2 - 0.16, u + a / 2 + 0.16]
    xs = sorted(x for x in xs if 0.3 < x < W - 0.3)
    lim = [0.08] + xs + [W - 0.08]
    out = []
    for k in range(len(lim) - 1):
        a, b = lim[k], lim[k + 1]
        if any(a - 0.01 < u - h / 2 - 0.16 and u + h / 2 + 0.16 < b + 0.01 for u, h in huecos):
            continue                                      # (el vano de una ventana: sin poste en medio)
        n = int((b - a) / paso)
        for j in range(1, n + 1):
            out.append(a + (b - a) * j / (n + 1))
    postes = sorted(xs + out)
    todos = [0.08] + postes + [W - 0.08]
    libres = []
    for k in range(len(todos) - 1):
        a, b = todos[k], todos[k + 1]
        if b - a > 0.7 and not any(a - 0.05 < u < b + 0.05 for u, _a in huecos):
            libres.append(k)
    return postes, tuple(libres)


def puerta_calle(M, P, u, ancho, alto, tipo="arco", color=VERDE_PUERTA, abierta=False, marco_col=SILLAR, z=0.0, y=0.0):
    """Una puerta a ras de calle (la de la muestra, sin sus escalones): arco de dovelas («arco») o dintel de madera sobre
    jambas de piedra («dintel»), hoja de tablas con pernios, clavos y aldaba; «abierta»: el hueco oscuro y la hoja
    abierta hacia dentro, contra la jamba."""
    radio = ancho / 2
    alto_r = alto - radio if tipo == "arco" else alto
    caja_mm(M, (u - ancho / 2 - 0.05, y - 0.1, z - 0.25), (u + ancho / 2 + 0.05, y + 0.04, z + 0.12), "sillar",
            jit(SILLAR, 0.05))
    for lado in (-1, 1):                                   # jambas
        yy, k = y, 0
        while yy < y + alto_r - 0.05:
            h = 0.36
            w = 0.32 if k % 2 == 0 else 0.24
            caja(M, (u + lado * (ancho / 2 + w / 2), yy + h / 2, z + 0.05), (w, h - 0.02, 0.2), "sillar",
                 jit(marco_col, 0.05), jit_v=0.008)
            yy += h
            k += 1
    if tipo == "arco":
        cy, n = y + alto_r, 9
        for k in range(n):
            a0, a1 = math.pi * k / n, math.pi * (k + 1) / n
            r0, r1 = radio, radio + (0.34 if k % 2 == 0 else 0.28)
            pts = [(math.cos(a0) * r0, math.sin(a0) * r0), (math.cos(a0) * r1, math.sin(a0) * r1),
                   (math.cos(a1) * r1, math.sin(a1) * r1), (math.cos(a1) * r0, math.sin(a1) * r0)]
            pts = [(px * 0.988, py * 0.988) for px, py in pts]
            placa(M, pts, (u, cy, z - 0.05), (1, 0, 0), (0, 1, 0), 0.22 + (0.02 if k == n // 2 else 0), "sillar",
                  jit(marco_col, 0.05))

        def borde(x):
            return alto_r + math.sqrt(max(0.0, radio * radio - x * x)) - 0.02
    else:
        viga(M, (u - ancho / 2 - 0.35, y + alto + 0.1, z + 0.08), (u + ancho / 2 + 0.35, y + alto + 0.1, z + 0.08), 0.18,
             "madera", MADERA_OSC, alto=0.2, jit_v=0.01)

        def borde(x):
            return alto
    if abierta:
        hueco = [(-ancho / 2, 0.0), (ancho / 2, 0.0)] + [(ancho / 2 - ancho * k / 10, borde(ancho / 2 - ancho * k / 10))
                                                          for k in range(11)]
        placa(M, hueco, (u, y, z + 0.004), (1, 0, 0), (0, 1, 0), 0.004, "hierro", OSCURO, lados=False)
        hz = 0.004 + 0.012                                 # el umbral de dentro, de madera, que asoma
        caja_mm(M, (u - ancho / 2 + 0.04, y - 0.02, z + hz), (u + ancho / 2 - 0.04, y + 0.05, z + hz + 0.01), "madera",
                MADERA_OSC)
        for t in range(5):                                # la hoja, abierta del todo contra la fachada (a la izquierda)
            x0 = u - ancho / 2 - 0.34 - (t + 1) * ancho / 5
            placa(M, [(0.0, 0.0), (ancho / 5 - 0.012, 0.0), (ancho / 5 - 0.012, min(borde(0), alto_r + 0.1)),
                      (0.0, min(borde(0), alto_r + 0.1))], (x0, y + 0.02, z + 0.2), (1, 0, 0), (0, 1, 0), 0.05, "madera",
                  jit(color, 0.04))
        for yy in (0.35, alto_r - 0.15):
            caja(M, (u - ancho / 2 - 0.34 - ancho / 2, y + yy, z + 0.26), (ancho * 0.8, 0.06, 0.015), "hierro", HIERRO)
        return
    tablas = 6
    for k in range(tablas):
        xa = -ancho / 2 + k * ancho / tablas
        xb = xa + ancho / tablas - 0.012
        placa(M, [(xa, 0), (xb, 0), (xb, borde(xb)), (xa, borde(xa))], (u, y, z - 0.02), (1, 0, 0), (0, 1, 0), 0.06,
              "madera", jit(color, 0.04))
    for yy in (0.35, alto_r - 0.15):
        caja(M, (u - ancho * 0.2, y + yy, z + 0.05), (ancho * 0.5, 0.06, 0.015), "hierro", HIERRO)
        for dx in (-0.4, -0.2, 0.0, 0.2, 0.4):
            caja(M, (u + dx * ancho / 1.2, y + yy, z + 0.062), (0.03, 0.03, 0.02), "hierro", HIERRO)
    cilindro(M, (u + ancho * 0.24, y + 0.95, z + 0.05), [(0, 0.075), (0.02, 0.075), (0.02, 0.055), (0, 0.055)], 10,
             "hierro", LATON, rot=R(0, 90), tapa_arriba=False)


def cesta_pan(P, c, r=0.2):
    """Una cesta de mimbre con hogazas y una barra."""
    c = Vector(c)
    cilindro(P, c, [(0, r * 0.8), (r * 0.6, r), (r * 0.65, r * 1.02)], 10, "madera", (0.80, 0.66, 0.44))
    for k in range(5):
        a = k * 1.25
        q = c + Vector((math.cos(a) * r * 0.45, r * 0.62, math.sin(a) * r * 0.45))
        cilindro(P, q, [(0, 0.07), (0.05, 0.08), (0.09, 0.05), (0.1, 0.0)], 8, "barro", jit(PAN, 0.06))
    viga(P, c + Vector((-r * 0.7, r * 0.75, 0.0)), c + Vector((r * 0.8, r * 0.95, r * 0.2)), 0.06, "barro", PAN_OSC)


def escaparate(M, P, V, u0, u1, y0, alto, mercancia="cajas", luz=True, z=0.0):
    """Un escaparate de tienda: marco de madera con parteluces, cristal (encendido por dentro), un tablero bajo a la
    calle con la mercancía y los postigos plegados."""
    ancho = u1 - u0
    u = (u0 + u1) / 2
    caja_mm(M, (u0, y0, z - 0.02), (u1, y0 + alto, z), "brillo" if luz else "hierro", LUZ_VENTANA if luz else CRISTAL)
    n = int(ancho / 0.6) + 1
    for k in range(n + 1):
        caja(M, (u0 + k * ancho / n, y0 + alto / 2, z + 0.03), (0.06, alto, 0.05), "madera", MADERA_OSC)
    caja(M, (u, y0 + alto * 0.66, z + 0.03), (ancho, 0.05, 0.05), "madera", MADERA_OSC)
    caja(M, (u, y0 + alto + 0.06, z + 0.05), (ancho + 0.3, 0.14, 0.1), "madera", MADERA_OSC)
    caja(M, (u, y0 - 0.04, z + 0.2), (ancho + 0.2, 0.08, 0.42), "madera", jit(MADERA, 0.05), veta="larga")
    for s in (-1, 1):                                       # postigos plegados a los lados
        for t in range(2):
            caja(M, (u + s * (ancho / 2 + 0.12 + t * 0.07), y0 + alto / 2, z + 0.06 + t * 0.05), (0.05, alto + 0.05, 0.05),
                 "madera", jit(MADERA_GRIS, 0.05))
    if mercancia == "telas":                                # piezas de tela enrolladas
        for k in range(int(ancho / 0.28)):
            col = TELAS[k % len(TELAS)]
            cilindro(P, (u0 + 0.2 + k * 0.28, y0 + 0.06 + (0.1 if k % 3 == 0 else 0.0), z + 0.2), [(0, 0.1), (0.36, 0.1)],
                     8, "tela", jit(col, 0.05), rot=R(0, 0, 90) if k % 3 == 0 else None)
    elif mercancia == "pan":
        cesta_pan(P, (u - ancho * 0.25, y0, z + 0.2), 0.22)
        cesta_pan(P, (u + ancho * 0.22, y0, z + 0.22), 0.2)
    else:
        for k in range(int(ancho / 0.45)):
            x = u0 + 0.25 + k * 0.45
            caja(P, (x, y0 + 0.1, z + 0.2), (0.36, 0.2, 0.3), "madera", jit(MADERA_GRIS, 0.06), rot=R(U(-6, 6)), veta="larga")
            for j in range(4):
                caja(P, (x + U(-0.1, 0.1), y0 + 0.24, z + 0.2 + U(-0.08, 0.08)), (0.08, 0.08, 0.08), "barro",
                     CH([(0.86, 0.22, 0.18), (0.92, 0.70, 0.28), (0.52, 0.66, 0.30)]), rot=R(U(0, 90)))


def toldo(M, u0, u1, y_pared, y_borde, salida, colores, z=0.0):
    """Un toldo de lona a rayas: de la pared (y_pared) a su borde (y_borde, «salida» metros fuera), con faldón y dos
    tirantes de hierro."""
    n = max(2, int((u1 - u0) / 0.32))
    for k in range(n):
        a, b = u0 + (u1 - u0) * k / n, u0 + (u1 - u0) * (k + 1) / n
        col = jit(colores[k % len(colores)], 0.03)
        p = [Vector((a, y_pared, z + 0.02)), Vector((b, y_pared, z + 0.02)), Vector((b, y_borde, z + salida)),
             Vector((a, y_borde, z + salida))]
        M.cara(list(reversed(p)), "tela", col)
        M.cara(p, "tela", mezcla(col, (0.3, 0.3, 0.3), 0.25))
        f = [Vector((a, y_borde, z + salida)), Vector((b, y_borde, z + salida)), Vector((b, y_borde - 0.22, z + salida)),
             Vector((a, y_borde - 0.22, z + salida))]
        M.cara(f, "tela", col)
        M.cara(list(reversed(f)), "tela", col)
    for x in (u0 + 0.05, u1 - 0.05):
        viga(M, (x, y_pared + 0.35, z + 0.02), (x, y_borde, z + salida), 0.025, "hierro", HIERRO)


def letrero_con(M, base, hacia, simbolo):
    """El letrero colgado de la muestra (brazo de hierro con aro, cadenas y tabla paralela a la fachada) con otro emblema:
    «pan» (una hogaza y una pala), «tela» (piezas y tijeras), «tonel», «rueda», «herradura»."""
    base = Vector(base)
    h = Vector(hacia).normalized()
    punta = base + h * 1.0
    viga(M, base, punta, 0.045, "hierro", HIERRO)
    viga(M, base - Vector((0, 0.45, 0)), base + h * 0.55, 0.035, "hierro", HIERRO)
    cilindro(M, base + h * 0.3 + Vector((0, -0.12, 0)), [(0, 0.12), (0.025, 0.12), (0.025, 0.1), (0, 0.1)], 10, "hierro",
             HIERRO, rot=R(0, 0, 90), tapa_arriba=False)
    c = punta - h * 0.12 - Vector((0, 0.55, 0))
    for d in (-0.34, 0.34):
        viga(M, punta - h * 0.12 + Vector((d * 0.5, 0, 0)), c + Vector((d, 0.32, 0)), 0.012, "hierro", HIERRO)
    caja(M, c, (0.9, 0.64, 0.06), "madera", (0.36, 0.26, 0.20), veta="larga")
    caja(M, c + Vector((0, 0, 0.01)), (0.8, 0.54, 0.06), "madera", (0.80, 0.66, 0.46), veta="larga")
    f = c + Vector((0, 0, 0.05))
    if simbolo == "pan":
        cilindro(M, f + Vector((-0.24, -0.02, 0)), [(0, 0.1), (0.38, 0.12), (0.48, 0.0)], 10, "barro", PAN, rot=R(0, 0, -90))
        for k in range(3):
            caja(M, f + Vector((-0.12 + k * 0.12, 0.08, 0.05)), (0.03, 0.12, 0.02), "barro", PAN_OSC, rot=R(0, 0, 30))
        caja(M, f + Vector((0.27, -0.03, 0.0)), (0.12, 0.3, 0.04), "barro", (0.86, 0.80, 0.66))
    elif simbolo == "tela":
        for k, col in enumerate((TELAS[1], TELAS[2], TELAS[3])):
            caja(M, f + Vector((-0.08, -0.12 + k * 0.1, 0.0)), (0.46, 0.08, 0.05), "tela", col)
        caja(M, f + Vector((0.27, 0.08, 0.01)), (0.04, 0.3, 0.03), "hierro", (0.62, 0.62, 0.66), rot=R(0, 0, 25))
        caja(M, f + Vector((0.27, 0.08, 0.02)), (0.04, 0.3, 0.03), "hierro", (0.62, 0.62, 0.66), rot=R(0, 0, -25))
    elif simbolo == "tonel":
        perfil = [(0, 0.13), (0.1, 0.15), (0.2, 0.155), (0.3, 0.15), (0.4, 0.13)]
        cilindro(M, f + Vector((0, -0.2, 0.0)), perfil, 12, "madera", MADERA)
        for yy in (0.06, 0.32):
            cilindro(M, f + Vector((0, -0.2 + yy, 0.0)), [(0, 0.155), (0.03, 0.155)], 12, "hierro", HIERRO, tapa_arriba=False)
    elif simbolo == "rueda":
        cilindro(M, f, [(0, 0.22), (0.04, 0.22), (0.04, 0.18), (0, 0.18)], 14, "madera", MADERA_OSC, rot=R(0, 90),
                 tapa_arriba=False)
        for k in range(6):
            a = k * math.pi / 3
            viga(M, f, f + Vector((math.cos(a) * 0.19, math.sin(a) * 0.19, 0.0)), 0.02, "madera", MADERA_OSC)
    elif simbolo == "herradura":
        for k in range(7):
            a0, a1 = math.pi * (-0.15 + k / 6 * 1.3), math.pi * (-0.15 + (k + 1) / 6 * 1.3)
            viga(M, f + Vector((math.cos(a0) * 0.16, math.sin(a0) * 0.16 - 0.02, 0)),
                 f + Vector((math.cos(a1) * 0.16, math.sin(a1) * 0.16 - 0.02, 0)), 0.045, "hierro", HIERRO)


def zocalo_y_esquinas(M, W, F, yb, col_rev, zocalo=0.62, pb_mat="revoque", sin_esquinas=False, abajo=-0.6):
    """El zócalo de sillería, la planta baja (revoque o sillar) y las esquinas de sillar alternas (de casa_a)."""
    caja_mm(M, (0.0, abajo, -F), (W, zocalo, 0.05), "sillar", jit(SILLAR, 0.03))
    if pb_mat == "sillar":
        caja_mm(M, (0.02, zocalo, -F), (W - 0.02, yb, 0.0), "sillar", jit(SILLAR, 0.02))
        return
    caja_mm(M, (0.02, zocalo, -F), (W - 0.02, yb, 0.0), "revoque", col_rev)
    if sin_esquinas:
        return
    for xe, sig in ((0.0, 1), (W, -1)):
        y, k = zocalo, 0
        while y < yb - 0.1:
            h = U(0.32, 0.4)
            w = 0.42 if k % 2 == 0 else 0.28
            caja_mm(M, (xe if sig > 0 else xe - w, y, -(0.28 if k % 2 else 0.42)),
                    (xe + w if sig > 0 else xe, y + h - 0.02, 0.04), "sillar", jit(SILLAR, 0.06), jit_v=0.01)
            y += h
            k += 1


def vuelo_y_mensulas(M, W, yb, vuelo, mensulas):
    """Las cabezas de las viguetas bajo el piso volado y las ménsulas (de casa_a)."""
    viga(M, (0.0, yb - 0.08, vuelo - 0.1), (W, yb - 0.08, vuelo - 0.1), 0.2, "madera", MADERA_OSC, alto=0.18, jit_v=0.01)
    x = 0.25
    while x < W - 0.1:
        caja(M, (x, yb - 0.24, vuelo * 0.5 - 0.05), (0.13, 0.15, vuelo + 0.1), "madera", jit(MADERA_OSC, 0.05), veta="larga",
             jit_v=0.008)
        x += 0.48
    for xm in mensulas:
        viga(M, (xm, yb - 0.95, 0.04), (xm, yb - 0.3, 0.42 * vuelo / 0.55), 0.13, "madera", MADERA_OSC, alto=0.13)
        caja(M, (xm, yb - 1.02, 0.06), (0.16, 0.16, 0.1), "madera", MADERA_OSC)


def ventanas_lado(M, e, W, post, ancho=0.6, alto=0.85):
    for lado, lista in e.get("lados", {}).items():          # ventanas en los costados (eje x del marco local)
        for (zl, yv) in lista:
            ventana(M, zl, yv, W if lado == "e" else 0.0, ancho, alto, post, eje="x", sig=1.0 if lado == "e" else -1.0)


def casa_alero(M, P, V, W, F, e):
    """La casa larga con el alero a la calle (casa_a de la muestra, generalizada). e: estilo (ver casa())."""
    yb = e.get("pb", 3.1)
    p1 = e.get("p1", 2.55)
    vu = e.get("vuelo", 0.55)
    y1 = yb + p1
    rev, post = e["rev"], e.get("post")
    flores = []
    zocalo_y_esquinas(M, W, F, yb, rev, pb_mat=e.get("pb_mat", "revoque"))
    mens = e.get("mensulas") or [0.3] + [W * k / 4 for k in (1, 2, 3)] + [W - 0.3]
    vuelo_y_mensulas(M, W, yb, vu, mens)
    huecos = [(v[0], v[1]) for v in e.get("ventanas_p1", [])]
    postes, cruces = postes_auto(W, huecos)
    entramado(M, 0.0, W, yb, y1, vu, postes, rev, MADERA_OSC, cruces=cruces)
    caja_mm(M, (0.0, yb, -F), (0.12, y1, vu - 0.12), "revoque", rev)
    caja_mm(M, (W - 0.12, yb, -F), (W, y1, vu - 0.12), "revoque", rev)
    for v in e.get("ventanas_pb", []):
        luz = len(v) > 4 and v[4]
        flores.append(ventana(M, v[0], v[2] if len(v) > 2 else 1.05, 0.0, v[1], v[3] if len(v) > 3 else 1.15, post,
                              jardinera=not luz, luz=luz))
    for v in e.get("ventanas_p1", []):
        luz = len(v) > 2 and v[2]
        flores.append(ventana(M, v[0], yb + 0.75, vu + 0.04, v[1], 0.95, post, luz=luz, jardinera=not luz))
    ventanas_lado(M, e, W, post)
    yr = y1 + e.get("alto_tejado", 2.65)
    za = vu + 0.62                                         # el alero delantero
    zb = -F - 0.45                                         # el trasero
    zr = (za + zb) * 0.5
    faldon(M, (-0.45, y1 - 0.05, za), (W + 0.45, y1 - 0.05, za), (0, yr - y1 + 0.05, zr - za), TEJA,
           musgo=e.get("musgo", 0.3))
    faldon(M, (W + 0.45, y1 - 0.05, zb), (-0.45, y1 - 0.05, zb), (0, yr - y1 + 0.05, zr - zb), TEJA, musgo=0.1)
    cumbrera(M, (-0.45, yr + 0.02, zr), (W + 0.45, yr + 0.02, zr))
    for xh, s in ((0.0, -1), (W, 1)):
        pts = [Vector((xh, y1, vu - 0.1)), Vector((xh, yr - 0.05, zr)), Vector((xh, y1, -F))]
        M.cara(list(reversed(pts)) if s > 0 else pts, "revoque", rev)
        viga(M, (xh + s * 0.48, y1 - 0.08, za), (xh + s * 0.48, yr + 0.06, zr), 0.06, "madera", MADERA_OSC, alto=0.22)
    if e.get("buhardilla") is not None:
        bx, bz, by = e["buhardilla"], vu - 1.35, y1 + 0.9
        caja_mm(M, (bx - 0.75, y1 + 0.2, bz - 1.2), (bx + 0.75, by + 0.95, bz), "revoque", rev)
        M.cara([Vector((bx - 0.75, by + 0.95, bz)), Vector((bx + 0.75, by + 0.95, bz)), Vector((bx, by + 1.5, bz))],
               "revoque", rev)
        ventana(M, bx, by, bz, 0.55, 0.65, None, luz=e.get("buhardilla_luz", False))
        faldon(M, (bx - 0.95, by + 0.9, bz + 0.3), (bx - 0.95, by + 0.9, bz - 1.4), (0.95, 0.62, 0), TEJA, musgo=0.2,
               solape=0.3)
        faldon(M, (bx + 0.95, by + 0.9, bz - 1.4), (bx + 0.95, by + 0.9, bz + 0.3), (-0.95, 0.62, 0), TEJA, musgo=0.2,
               solape=0.3)
    if e.get("chimenea") is not None:
        cu = e["chimenea"]
        chimenea(M, cu[0], cu[1], y1 + 0.6, yr + (cu[2] if len(cu) > 2 else 0.15),
                 cu[3] if len(cu) > 3 else 0.7, cu[4] if len(cu) > 4 else 0.55)
    return flores


def casa_hastial(M, P, V, W, F, e):
    """La casa con el hastial a la calle, dos vuelos, balconcillo y viga de polea (casa_b de la muestra, generalizada)."""
    yb = e.get("pb", 2.8)
    p1 = e.get("p1", 2.35)
    y1 = yb + p1
    rev, post = e["rev"], e.get("post")
    z1 = 0.5
    flores = []
    zocalo_y_esquinas(M, W, F, yb, rev, zocalo=0.5, pb_mat=e.get("pb_mat", "sillar"))
    viga(M, (0.0, yb - 0.06, z1 - 0.1), (W, yb - 0.06, z1 - 0.1), 0.2, "madera", MADERA_OSC, alto=0.18, jit_v=0.01)
    x = 0.25
    while x < W - 0.1:
        caja(M, (x, yb - 0.2, 0.22), (0.13, 0.15, 0.6), "madera", jit(MADERA_OSC, 0.05), veta="larga", jit_v=0.008)
        x += 0.46
    for xm in (0.3, W - 0.3, W * 0.33, W * 0.66):
        viga(M, (xm, yb - 0.9, 0.04), (xm, yb - 0.28, 0.4), 0.13, "madera", MADERA_OSC, alto=0.13)
    huecos = [(v[0], v[1]) for v in e.get("ventanas_p1", [])]
    if e.get("balcon") is not None:
        huecos.append((e["balcon"], 0.85))
    postes, cruces = postes_auto(W, huecos, 1.1)
    entramado(M, 0.0, W, yb, y1, z1, postes, rev, MADERA_OSC, cruces=cruces)
    caja_mm(M, (0.0, yb, -F), (0.12, y1, z1 - 0.12), "revoque", rev)
    caja_mm(M, (W - 0.12, yb, -F), (W, y1, z1 - 0.12), "revoque", rev)
    for v in e.get("ventanas_p1", []):
        luz = len(v) > 2 and v[2]
        flores.append(ventana(M, v[0], yb + 0.7, z1 + 0.04, v[1], 0.9, post, luz=luz, jardinera=not luz))
    for v in e.get("ventanas_pb", []):
        luz = len(v) > 4 and v[4]
        flores.append(ventana(M, v[0], v[2] if len(v) > 2 else 0.95, 0.0, v[1], v[3] if len(v) > 3 else 1.05, post,
                              jardinera=not luz, luz=luz))
    ventanas_lado(M, e, W, post, 0.55, 0.8)
    if e.get("balcon") is not None:
        bx = e["balcon"]
        caja_mm(M, (bx - 0.9, yb + 0.02, z1), (bx + 0.9, yb + 0.1, z1 + 0.6), "madera", MADERA)
        for k in range(10):
            xx = bx - 0.85 + k * 0.19
            caja_mm(M, (xx - 0.025, yb + 0.1, z1 + 0.54), (xx + 0.025, yb + 0.9, z1 + 0.59), "madera", MADERA_OSC)
        caja_mm(M, (bx - 0.92, yb + 0.88, z1 - 0.02), (bx + 0.92, yb + 0.96, z1 + 0.62), "madera", MADERA)
        for xx in (bx - 0.88, bx + 0.88):
            caja_mm(M, (xx - 0.04, yb + 0.1, z1), (xx + 0.04, yb + 0.9, z1 + 0.6), "madera", MADERA_OSC)
        ventana(M, bx, yb + 0.15, z1 + 0.04, 0.85, 1.55, None, luz=False)
        if DECORADO:
            for k in range(3):
                maceta(P, V, (bx - 0.6 + k * 0.6, yb + 0.1, z1 + 0.3), 0.13, 0.18)
    z2 = z1 + 0.35
    y2 = y1 + e.get("p2", 1.0)
    viga(M, (-0.05, y1 - 0.06, z2 - 0.1), (W + 0.05, y1 - 0.06, z2 - 0.1), 0.2, "madera", MADERA_OSC, alto=0.18)
    postes2, _c = postes_auto(W, [(W / 2, 0.5)], 1.6)
    entramado(M, 0.0, W, y1, y2, z2, postes2, rev, MADERA_OSC)
    caja_mm(M, (0.0, y1, -F), (0.12, y2, z2 - 0.12), "revoque", rev)
    caja_mm(M, (W - 0.12, y1, -F), (W, y2, z2 - 0.12), "revoque", rev)
    yr = y2 + e.get("alto_tejado", 2.55) * W / 7.0
    xm = W / 2
    M.cara([Vector((0.0, y2, z2 - 0.06)), Vector((W, y2, z2 - 0.06)), Vector((xm, yr, z2 - 0.06))], "revoque", rev)
    viga(M, (0.2, y2 + 0.05, z2), (xm, yr - 0.3, z2), 0.12, "madera", MADERA_OSC, alto=0.14)
    viga(M, (W - 0.2, y2 + 0.05, z2), (xm, yr - 0.3, z2), 0.12, "madera", MADERA_OSC, alto=0.14)
    viga(M, (0.9, y2 + 0.85, z2 + 0.02), (W - 0.9, y2 + 0.85, z2 + 0.02), 0.11, "madera", MADERA_OSC, alto=0.12)
    ventana(M, xm, y2 + 0.95, z2, 0.5, 0.65, post, luz=e.get("luz_hastial", False))
    vuelo = 0.55
    for s in (-1, 1):
        xa = -vuelo if s < 0 else W + vuelo
        faldon(M, (xa, y2 - 0.35, z2 + vuelo) if s < 0 else (xa, y2 - 0.35, -F - 0.6),
               (xa, y2 - 0.35, -F - 0.6) if s < 0 else (xa, y2 - 0.35, z2 + vuelo),
               (xm - xa, yr - y2 + 0.4, 0), TEJA, musgo=e.get("musgo", 0.25))
        viga(M, (xa + 0.02 * -s, y2 - 0.4, z2 + vuelo + 0.02), (xm, yr + 0.08, z2 + vuelo + 0.02), 0.06, "madera",
             MADERA_OSC, alto=0.26)
    cumbrera(M, (xm, yr + 0.02, z2 + vuelo), (xm, yr + 0.02, -F - 0.6))
    if e.get("polea", True):
        viga(M, (xm, yr - 0.55, z2 - 0.4), (xm, yr - 0.55, z2 + 1.2), 0.17, "madera", MADERA_OSC, alto=0.19)
        cilindro(M, (xm - 0.04, yr - 0.72, z2 + 1.05), [(0, 0.12), (0.08, 0.12)], 10, "madera", MADERA, rot=R(0, 0, 90))
        viga(M, (xm + 0.07, yr - 0.72, z2 + 1.05), (xm + 0.07, yb + 0.9, z2 + 1.05), 0.022, "tela", (0.70, 0.62, 0.48))
    if e.get("chimenea") is not None:
        cu = e["chimenea"]
        chimenea(M, cu[0], cu[1], y2 + 1.0, yr + 0.2, 0.6, 0.5)
    return flores


def nave(M, P, V, W, F, alto, e):
    """Una nave de madera sobre zócalo de piedra (establo, taller, tonelería, cobertizo): tablas verticales, pies
    derechos, tejado a dos aguas con la cumbrera paralela a la fachada y alero hondo."""
    zoc = e.get("zocalo", 0.5)
    tabla = e.get("tabla", MADERA_GRIS)
    caja_mm(M, (0.0, e.get("abajo", -0.6), -F), (W, zoc, 0.04), "sillar", jit(SILLAR, 0.04))
    caja_mm(M, (0.02, zoc, -F), (W - 0.02, alto, -0.02), "madera", jit(tabla, 0.03), veta="larga")
    x = 0.12
    while x < W:                                          # las tablas, una a una (sombra entre ellas)
        caja_mm(M, (x - 0.11, zoc + 0.02, -0.02), (x + 0.11, alto - 0.15, 0.02), "madera", jit(tabla, 0.06), veta="larga")
        x += 0.24
    vanos = e.get("vanos", 3)
    for u in [0.08] + [W * k / vanos for k in range(1, vanos)] + [W - 0.08]:
        viga(M, (u, zoc, 0.06), (u, alto, 0.06), 0.18, "madera", MADERA_OSC, alto=0.16, jit_v=0.008)
    viga(M, (0.0, alto - 0.08, 0.07), (W, alto - 0.08, 0.07), 0.2, "madera", MADERA_OSC, alto=0.18, jit_v=0.01)
    viga(M, (0.0, zoc + 0.08, 0.06), (W, zoc + 0.08, 0.06), 0.16, "madera", MADERA_OSC, alto=0.14)
    yr = alto + e.get("alto_tejado", 1.9)
    za, zb = 0.8, -F - 0.5
    zr = (za + zb) * 0.5
    faldon(M, (-0.4, alto - 0.05, za), (W + 0.4, alto - 0.05, za), (0, yr - alto + 0.05, zr - za), TEJA,
           musgo=e.get("musgo", 0.45))
    faldon(M, (W + 0.4, alto - 0.05, zb), (-0.4, alto - 0.05, zb), (0, yr - alto + 0.05, zr - zb), TEJA, musgo=0.2)
    cumbrera(M, (-0.4, yr + 0.02, zr), (W + 0.4, yr + 0.02, zr))
    for xh, s in ((0.0, -1), (W, 1)):
        pts = [Vector((xh, alto, 0.0)), Vector((xh, yr - 0.05, zr)), Vector((xh, alto, -F))]
        M.cara(list(reversed(pts)) if s > 0 else pts, "madera", jit(tabla, 0.04))
        viga(M, (xh + s * 0.42, alto - 0.08, za), (xh + s * 0.42, yr + 0.06, zr), 0.06, "madera", MADERA_OSC, alto=0.22)
    for x in range(int(W / 0.6)):                         # cabezas de los cabios bajo el alero
        caja(M, (0.3 + x * 0.6, alto + 0.02, 0.35), (0.1, 0.12, 0.8), "madera", MADERA_OSC, veta="larga")


def porton(M, u, ancho, alto, abierto=True, color=MADERA, z=0.0, y=0.0):
    """Un portón de dos hojas de tablas con su dintel; abierto: el hueco oscuro y las hojas abiertas hacia fuera, casi
    contra la fachada."""
    caja_mm(M, (u - ancho / 2, y, z - 0.03), (u + ancho / 2, y + alto, z - 0.02), "hierro", OSCURO)
    viga(M, (u - ancho / 2 - 0.2, y + alto + 0.1, z + 0.08), (u + ancho / 2 + 0.2, y + alto + 0.1, z + 0.08), 0.2, "madera",
         MADERA_OSC, alto=0.22)
    hoja = ancho / 2
    for s in (-1, 1):
        viga(M, (u + s * (ancho / 2 + 0.08), y, z + 0.06), (u + s * (ancho / 2 + 0.08), y + alto, z + 0.06), 0.16, "madera",
             MADERA_OSC)
        if abierto:
            ang = math.radians(U(10, 24))                 # ángulo con la fachada
            d = Vector((s * math.cos(ang), 0.0, math.sin(ang)))
            g = Vector((u + s * (ancho / 2 + 0.18), y, z + 0.12))
            ez = d.cross(Vector((0, 1, 0))).normalized()
            rot = Matrix((d, Vector((0, 1, 0)), ez)).transposed()
            for t in range(4):
                caja(M, g + d * ((t + 0.5) * hoja / 4) + Vector((0, alto * 0.48, 0)), (hoja / 4 - 0.01, alto * 0.95, 0.06),
                     "madera", jit(color, 0.04), rot=rot, veta="larga")
            for yy in (0.25, 0.75):
                caja(M, g + d * (hoja * 0.5) + Vector((0, alto * yy, 0)) - ez * 0.04 * s, (hoja * 0.95, 0.1, 0.05),
                     "madera", MADERA_OSC, rot=rot, veta="larga")
        else:
            for t in range(4):
                x0 = u + s * (t * hoja / 4)
                x1 = x0 + s * hoja / 4
                caja_mm(M, (min(x0, x1) + 0.006, y + 0.02, z - 0.02), (max(x0, x1) - 0.006, y + alto - 0.02, z + 0.04),
                        "madera", jit(color, 0.04), veta="larga")


def muro_piedra(M, x0, x1, y0, y1, grueso, col=SILLAR, almenas=False, z=0.0, albardilla=True):
    """Un muro de sillería (frente en el plano z, mirando a +z, de x0 a x1): cuerpo, albardilla y, si se pide, almenas."""
    caja_mm(M, (x0, y0, z - grueso), (x1, y1, z), "sillar", jit(col, 0.03))
    if albardilla:
        caja_mm(M, (x0 - 0.05, y1, z - grueso - 0.06), (x1 + 0.05, y1 + 0.14, z + 0.07), "sillar", jit(col, 0.05))
    if almenas:
        x = x0 + 0.2
        while x + 0.9 <= x1:
            caja_mm(M, (x, y1 + 0.14, z - grueso + 0.05), (x + 0.9, y1 + 1.05, z - 0.02), "sillar", jit(col, 0.05),
                    jit_v=0.01)
            x += 1.6


def arco_rebajado(M, u, y_s, R_A, semi, z, col=SILLAR, oscuro=True):
    """El gran arco rebajado de dovelas de casa_b (la boca de un taller o de una tienda), con su oscuridad dentro: «semi»
    es la mitad de la luz y el arco arranca a y_s."""
    a_ini = math.acos(semi / R_A)
    yc = y_s - R_A * math.sin(a_ini)
    if oscuro:
        hueco = [(-semi, 0.0), (semi, 0.0)]
        for k in range(9):
            a = a_ini + (math.pi - 2 * a_ini) * k / 8
            hueco.append((math.cos(a) * R_A, yc + math.sin(a) * R_A))
        placa(M, hueco, (u, 0.0, z), (1, 0, 0), (0, 1, 0), 0.006, "hierro", OSCURO, lados=False)
    n = 9
    for k in range(n):
        a0 = a_ini + (math.pi - 2 * a_ini) * k / n
        a1 = a_ini + (math.pi - 2 * a_ini) * (k + 1) / n
        r0, r1 = R_A, R_A + (0.34 if k % 2 == 0 else 0.27)
        pts = [(math.cos(a0) * r0, math.sin(a0) * r0), (math.cos(a0) * r1, math.sin(a0) * r1),
               (math.cos(a1) * r1, math.sin(a1) * r1), (math.cos(a1) * r0, math.sin(a1) * r0)]
        pts = [(x * 0.995, y * 0.995) for x, y in pts]
        placa(M, pts, (u, yc, z), (1, 0, 0), (0, 1, 0), 0.1 if k != n // 2 else 0.14, "sillar", jit(col, 0.06))
    for s in (-1, 1):
        caja_mm(M, (u + s * semi - (0.3 if s > 0 else 0.0), 0.0, z), (u + s * semi + (0.3 if s < 0 else 0.0), y_s, z + 0.08),
                "sillar", jit(col, 0.05), jit_v=0.008)


# ================================================================ el suelo: terreno, empedrados con identidad
# «fondo»: lo lejano (los campos y sus árboles, fuera del barrio) en un GLB aparte, solo con luz en los vértices: así las
# cajas envolventes de los sectores siguen siendo pequeñas (el descarte por vista de Godot funciona) y se dibuja siempre.
FONDO = "fondo"
SEMILLAS[FONDO] = 1607
SECT = {s: K.Sector(s, SEMILLAS[s]) for s in ORDEN + [FONDO]}
MALLAS = {s: (Malla(), Malla(), Malla()) for s in ORDEN + [FONDO]}     # (fijo con mapa de luz, piezas, vegetación)
JUNTAS = {s: [] for s in ORDEN}


def en(s):
    """Pasa a construir en el sector s: su azar, sus anclas y sus choques; devuelve sus tres mallas."""
    K.usar(SECT[s])
    return MALLAS[s]


TONO_TIERRA = {"caravanas": ((0.70, 0.60, 0.46), (0.76, 0.66, 0.50)), "comercial": (TIERRA, (0.70, 0.62, 0.50)),
               "plaza": (TIERRA, (0.72, 0.64, 0.52)), "talleres": ((0.68, 0.58, 0.46), (0.78, 0.70, 0.56)),
               "residencial": ((0.62, 0.56, 0.42), (0.68, 0.62, 0.46)), "atajo": ((0.62, 0.58, 0.50), (0.68, 0.62, 0.52))}
FINO = [(r[0] - 2.5, r[1] - 2.5, r[2] + 5.0, r[3] + 5.0) for r in SECTORES.values()]


def bajo_casa(x, z, margen=0.35):
    """¿Cae (x, z) dentro de una casa o un muro (lo que nunca se ve)?"""
    for b in BLOQUES:
        if b[5] in ("casa", "muro") and b[6]:
            r = b[2]
            if r[0] + margen < x < r[0] + r[2] - margen and r[1] + margen < z < r[1] + r[3] - margen:
                return True
    return False


def terreno():
    """Tierra pisada (la de la muestra: rejilla de 0,5 m con relieve suave) bajo todo lo que se ve de cerca, repartida
    por sectores; más lejos, una rejilla de 2 m; y al fondo, campos en piezas de 6 m (con la luz en los vértices)."""
    def y(x, z):
        base = cota(x, z)
        return base - 0.05 + 0.012 * ruido2(x, z, 2.2) - (0.0 if andable(x, z) else 0.01)
    def color(s, cx, cz):
        a, b = TONO_TIERRA[s]
        t = 0.5 + 0.5 * ruido2(cx * 0.7, cz * 0.7, 1.0)
        c = mezcla(a, b, t)
        if not andable(cx, cz):
            c = mezcla(c, (0.62, 0.62, 0.42), 0.35 * max(0.0, ruido2(cx, cz, 0.8)) + 0.15)
        if s == "caravanas" and -2.2 < cz < 0.6 and cx < -33 and (abs(cz + 1.5) < 0.35 or abs(cz + 0.1) < 0.35):
            c = mezcla(c, (0.48, 0.40, 0.32), 0.45)              # las rodadas de los carros
        if s == "talleres" and ruido2(cx * 1.3, cz * 1.1, 1.4) > 0.45:
            c = mezcla(c, (0.90, 0.80, 0.60), 0.4)               # serrín y virutas
        return c
    x0, x1, z0, z1 = -64.0, 22.0, -50.0, 16.0
    paso = 0.5
    nx, nz = int((x1 - x0) / paso), int((z1 - z0) / paso)
    for i in range(nx):
        for j in range(nz):
            xa, za = x0 + i * paso, z0 + j * paso
            cx, cz = xa + paso * 0.5, za + paso * 0.5
            if not any(dentro(r, cx, cz) for r in FINO):
                continue
            if bajo_casa(cx, cz):
                continue
            s = sector_terreno(cx, cz)
            M, P, V = en(s)
            pts = [Vector((xa, y(xa, za), za)), Vector((xa, y(xa, za + paso), za + paso)),
                   Vector((xa + paso, y(xa + paso, za + paso), za + paso)), Vector((xa + paso, y(xa + paso, za), za))]
            M.cara(pts, "tierra", jit(color(s, cx, cz), 0.008), suave=True)
    # más lejos: rejilla de 2 m (fijo) hasta 14 m de los sectores; y los campos (piezas, 6 m) hasta el horizonte
    for (paso, x0, x1, z0, z1, lejos) in ((2.0, -78.0, 36.0, -64.0, 24.0, False), (6.0, -150.0, 90.0, -160.0, 30.0, True)):
        nx, nz = int((x1 - x0) / paso), int((z1 - z0) / paso)
        for i in range(nx):
            for j in range(nz):
                xa, za = x0 + i * paso, z0 + j * paso
                cx, cz = xa + paso * 0.5, za + paso * 0.5
                if any(dentro(r, cx, cz) for r in FINO):
                    continue
                if not lejos and not any(dist_rect(r, cx, cz) < 14.0 for r in FINO):
                    continue
                if lejos and (-78.0 <= xa < 36.0 and -64.0 <= za < 24.0):
                    continue
                s = FONDO if lejos else sector_terreno(cx, cz)
                M, P, V = en(s)
                pts = [Vector((xa, y(xa, za), za)), Vector((xa, y(xa, za + paso), za + paso)),
                       Vector((xa + paso, y(xa + paso, za + paso), za + paso)), Vector((xa + paso, y(xa + paso, za), za))]
                if lejos:                                         # campos en franjas: rastrojo, verde, labrado
                    f = int((cx * 0.13 + cz * 0.05 + 40) / 2.2) % 4
                    c = [(0.80, 0.70, 0.44), (0.56, 0.62, 0.34), (0.62, 0.50, 0.36), (0.70, 0.66, 0.40)][f]
                    P.cara(pts, "tierra", jit(c, 0.03), suave=True)
                else:
                    M.cara(pts, "tierra", jit(color(s, cx, cz), 0.01), suave=True)


# Estilo del empedrado de cada suelo del trazado: paso de las semillas (tamaño de losa), desorden, cuánto se deshace
# hacia los bordes, tonos y, para la plaza, un anillo de losas oscuras.
ESTILO_SUELO = {
    "caravanas": {"paso": 0.5, "jit": 0.2, "densidad": 0.22, "tonos": PIEDRA},
    "comercial": {"paso": 0.42, "jit": 0.17, "densidad": 1.0, "tonos": PIEDRA, "orilla_s": 4.4},
    "plaza": {"paso": 0.72, "jit": 0.05, "densidad": 1.0, "tonos": ((0.74, 0.70, 0.64), (0.70, 0.67, 0.62),
                                                                    (0.78, 0.73, 0.66), (0.68, 0.64, 0.58))},
    "talleres": {"paso": 0.46, "jit": 0.16, "densidad": 0.8, "tonos": PIEDRA},
    "residencial": {"paso": 0.4, "jit": 0.12, "densidad": 0.95, "tonos": ((0.64, 0.61, 0.57), (0.58, 0.56, 0.53),
                                                                          (0.69, 0.65, 0.60), (0.60, 0.57, 0.52))},
    "atajo": {"paso": 0.4, "jit": 0.15, "densidad": 0.9, "tonos": PIEDRA},
}


def empedrado():
    """Losas de Voronoi (las de la muestra: tapa abombada, canto biselado, algo inclinadas, alturas distintas) sobre los
    suelos del trazado, con el estilo de cada tramo; las semillas son de todo el barrio a la vez (sin costuras entre
    tramos) y cada losa va al sector de su semilla, a las piezas (luz en los vértices)."""
    rng = random.Random(4242)
    semillas, estilo = [], []
    for k, s in enumerate(SUELOS):
        sec, r = s[0], s[1]
        if sec == "plaza":
            continue                                       # (la plaza va a matajunta: losas_plaza)
        e = ESTILO_SUELO[sec]
        p = e["paso"]
        x = r[0] + p * 0.5
        while x < r[0] + r[2]:
            z = r[1] + p * 0.5
            while z < r[1] + r[3]:
                jx, jz = rng.uniform(-e["jit"], e["jit"]), rng.uniform(-e["jit"], e["jit"])
                if sec == "plaza":
                    jx += (p * 0.5 if int((z - r[1]) / p) % 2 else 0.0)   # aparejo a matajunta
                q = (x + jx, z + jz)
                if dentro(r, q[0], q[1]):
                    semillas.append(q)
                    estilo.append(sec)
                z += p
            x += p
    celdas = voronoi(semillas, None, 0.045)
    plaza = [s[1] for s in SUELOS if s[0] == "plaza"]
    for (sd, poly) in celdas:
        sec = sector_de(sd[0], sd[1]) or "comercial"
        M, P, V = en(sec)
        e = ESTILO_SUELO[sec]
        if bloque_en(sd[0], sd[1]):
            continue
        if sec in ("atajo",) and suelo_en(sd[0], sd[1]) >= 0 and SUELOS[suelo_en(sd[0], sd[1])][2] == "z":
            continue                                       # (los tramos de escalones: los pone s_atajo)
        for pr in plaza:                                   # sin meterse en la plaza (que no tiene semillas)
            if dist_rect(pr, sd[0], sd[1]) < 1.2:
                poly = recortar_poli(poly, pr)
        if len(poly) < 3:
            continue
        d = e["densidad"]
        if sec == "comercial":                               # la orilla sur se deshace en tierra (como la muestra)
            borde = e["orilla_s"] + 0.3 * ruido2(sd[0] * 0.9, 3.0, 1.0)
            if sd[1] > borde:
                d = max(0.0, 1.0 - (sd[1] - borde) / 0.8)
        if sec == "caravanas":                               # solo un camino de losas del arco a la calle comercial
            d = 0.95 if abs(sd[1] + 0.8) < 1.3 + 0.4 * ruido2(sd[0], 1.0) else 0.05
        if sec == "talleres" and suelo_en(sd[0], sd[1]) >= 0 and SUELOS[suelo_en(sd[0], sd[1])][2] == "":
            d = 0.55 if abs(sd[0]) < 3.2 else 0.25            # el patio de arriba: losas en el paso, tierra a los lados
        if K.RND.random() > d:
            if d > 0.3 or K.RND.random() < 0.06:            # (en los patios de tierra, solo alguna mata suelta)
                JUNTAS[sec].append(sd)
            continue
        y0 = altura(sd[0], sd[1])
        col = jit(elige(e["tonos"]), 0.08)
        if sec == "plaza":
            rr = math.hypot(sd[0] - (-0.5), sd[1] - (-0.5))
            if 2.3 < rr < 3.1 or rr < 0.5:
                col = mezcla(col, (0.46, 0.44, 0.42), 0.55)   # el anillo oscuro del mercado
        if K.RND.random() < 0.12:
            col = mezcla(col, MUSGO, K.RND.uniform(0.1, 0.3))
        alto = K.RND.uniform(0.035, 0.06)
        pd = pendiente(sd[0], sd[1])
        losa(P, poly, y0 - 0.05, alto, col, (pd[0] + K.RND.uniform(-0.025, 0.025), pd[1] + K.RND.uniform(-0.025, 0.025)))
        if d < 0.9 or K.RND.random() < 0.06:
            JUNTAS[sec].append(poly[K.RND.randrange(len(poly))])


def recortar_poli(poly, r, junta=0.0225):
    """Quita de un polígono (x, z) lo que cae dentro del rectángulo r (con media junta de margen): las losas de la calle
    no se meten en la plaza. Sutherland-Hodgman contra el exterior: se recorta por el lado de r que da a la semilla."""
    cx = sum(p[0] for p in poly) / len(poly)
    cz = sum(p[1] for p in poly) / len(poly)
    x0, z0, x1, z1 = r[0] - junta, r[1] - junta, r[0] + r[2] + junta, r[1] + r[3] + junta
    lados = []
    if cx < x0:
        lados.append((0, x0, -1))
    if cx > x1:
        lados.append((0, x1, 1))
    if cz < z0:
        lados.append((1, z0, -1))
    if cz > z1:
        lados.append((1, z1, 1))
    if not lados:
        return poly
    eje, lim, sig = max(lados, key=lambda t: abs((cx, cz)[t[0]] - t[1]))
    out = []
    for k in range(len(poly)):
        p0, p1 = poly[k], poly[(k + 1) % len(poly)]
        d0, d1 = (p0[eje] - lim) * sig, (p1[eje] - lim) * sig
        if d0 >= 0:
            out.append(p0)
        if (d0 >= 0) != (d1 >= 0):
            f = d0 / (d0 - d1)
            out.append((p0[0] + (p1[0] - p0[0]) * f, p0[1] + (p1[1] - p0[1]) * f))
    return out


def losas_plaza():
    """La plaza del mercado: losas RECTANGULARES a matajunta (hiladas de 0,55-0,7 m, piezas de 0,6-1,15 m), con el
    mismo canto biselado y la misma inclinación suave que las de la muestra, y un anillo de losas oscuras."""
    rng = random.Random(77)
    e = ESTILO_SUELO["plaza"]
    j = 0.0225
    for s in SUELOS:
        if s[0] != "plaza":
            continue
        M, P, V = en("plaza")
        r = s[1]
        z = r[1]
        while z < r[1] + r[3] - 0.05:
            h = rng.choice((0.55, 0.62, 0.7))
            x = r[0] - rng.uniform(0.0, 0.6)
            while x < r[0] + r[2]:
                w = rng.uniform(0.6, 1.15)
                x0, x1 = max(x, r[0]), min(x + w, r[0] + r[2])
                z0, z1 = z, min(z + h, r[1] + r[3])
                cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
                x += w
                if x1 - x0 < 0.15 or bloque_en(cx, cz):
                    continue
                if K.RND.random() > 0.97:
                    JUNTAS["plaza"].append((cx, cz))
                    continue
                poly = [(x0 + j, z0 + j), (x1 - j, z0 + j), (x1 - j, z1 - j), (x0 + j, z1 - j)]
                col = jit(elige(e["tonos"]), 0.07)
                rr = math.hypot(cx + 0.5, cz + 0.5)
                if 2.3 < rr < 3.1 or rr < 0.6:
                    col = mezcla(col, (0.46, 0.44, 0.42), 0.55)
                if K.RND.random() < 0.1:
                    col = mezcla(col, MUSGO, K.RND.uniform(0.1, 0.25))
                losa(P, poly, 0.4 - 0.05, K.RND.uniform(0.035, 0.055), col,
                     (K.RND.uniform(-0.015, 0.015), K.RND.uniform(-0.015, 0.015)))
                if K.RND.random() < 0.08:
                    JUNTAS["plaza"].append(poly[K.RND.randrange(4)])
            z += h


def choques_del_trazado():
    """Un choque por bloque sólido del trazado, con las MISMAS medidas que el blockout de barrio.gd (de base − 0,5 a base
    + alto; las puertas, desde su base): el mismo recorrido que en la fase 0."""
    for b in BLOQUES:
        if not b[6]:
            continue
        en(b[1])
        r, base, alto = b[2], b[3], b[4]
        abajo = base if b[5] == "puerta" else base - 0.5
        alto_t = base + alto - abajo
        choque((r[0] + r[2] / 2, abajo + alto_t / 2, r[1] + r[3] / 2), (r[2], alto_t, r[3]), 0.0, b[0])


# ================================================================ casas en su sitio

def casa(bid, constructor, e, frente="s", base=None, extra=None, flores=True):
    """Levanta el bloque «bid» del trazado con un constructor (casa_alero, casa_hastial…), mirando al sur, al este o al
    oeste. base: la cota del pie de la fachada (por defecto, la del bloque). extra(m, p, v, W, F): más cosas en el mismo
    marco (puertas, escaparates, toldos, letreros). Pone las flores de las jardineras."""
    b = BLOQUE[bid]
    M, P, V = en(b[1])
    r = b[2]
    y0 = b[3] if base is None else base
    if frente == "s":
        o, giro, W, F = (r[0], y0, r[1] + r[3]), 0.0, r[2], r[3]
    elif frente == "e":
        o, giro, W, F = (r[0] + r[2], y0, r[1] + r[3]), 90.0, r[3], r[2]
    else:
        o, giro, W, F = (r[0], y0, r[1]), -90.0, r[3], r[2]
    with marco(o, giro) as Fm:
        m, p, v = Fm(M), Fm(P), Fm(V)
        fl = constructor(m, p, v, W, F, e) or []
        if extra is not None:
            extra(m, p, v, W, F)
        if DECORADO and flores:
            for q in fl:
                if q is None:
                    continue
                for k in range(3):
                    mata_flores(v, q + Vector((-0.3 + k * 0.3, 0.0, 0.0)), 0.15, CH(FLORES), 8, 0.26)
                hojas(v, q + Vector((0, -0.12, 0.08)), 0.3, 22, HOJA, 0.07, flex=0.3, aplastar=0.4)
    return W, F


def pie_fachada(V, x0, x1, z, salvo=(), frac=0.45):
    """Matas al pie de una fachada que mira al sur (de x0 a x1 en z), más en las esquinas; «salvo»: tramos sin matas
    (puertas, escaparates)."""
    if not DECORADO:
        return
    x = x0
    while x < x1:
        if not any(a - 0.2 < x < b + 0.2 for a, b in salvo):
            esquina = min(abs(x - x0), abs(x - x1))
            if AZ() < (0.9 if esquina < 0.8 else frac):
                mata(V, (x, cota(x, z + 0.15), z + U(0.0, 0.18)), U(0.14, 0.26), K.RND.randint(10, 20), U(0.22, 0.42))
        x += U(0.25, 0.6)


# ================================================================ atrezo del barrio (con las piezas de la muestra)

def rueda(P, c, r, yaw=0.0, ancho=0.08, radios=10, ladeo=0.0):
    """Una rueda de carro: llanta de hierro, pina de madera, cubo y radios. Eje horizontal girado «yaw» (0 = eje z)."""
    c = Vector(c)
    rot = R(yaw) @ R(0, 90 + ladeo)
    cilindro(P, c - rot @ Vector((0, ancho / 2, 0)), [(0, r), (ancho, r), (ancho, r - 0.06), (0, r - 0.06)], 16, "madera",
             MADERA_OSC, rot=rot, tapa_arriba=False)
    cilindro(P, c - rot @ Vector((0, ancho / 2 + 0.005, 0)), [(0, r + 0.012), (ancho + 0.01, r + 0.012)], 16, "hierro",
             HIERRO, rot=rot, tapa_arriba=False)
    cilindro(P, c - rot @ Vector((0, 0.1, 0)), [(0, 0.08), (0.2, 0.08)], 8, "madera", MADERA_OSC, rot=rot, tapa_abajo=True)
    for k in range(radios):
        a = k * math.tau / radios
        d = rot @ Vector((math.cos(a), 0.0, math.sin(a)))
        viga(P, c + d * 0.07, c + d * (r - 0.05), 0.03, "madera", MADERA)


def mesa(P, r, y, alto=0.82, col=MADERA):
    """Una mesa de caballetes que llena el rectángulo r (x0, z0, ancho, fondo) a la cota y. Devuelve la cota del
    tablero."""
    x0, z0, w, h = r
    caja_mm(P, (x0 + 0.05, y + alto - 0.05, z0 + 0.05), (x0 + w - 0.05, y + alto, z0 + h - 0.05), "madera", jit(col, 0.05),
            veta="larga")
    for xx in (x0 + 0.35, x0 + w - 0.35):
        for zz in (z0 + 0.15, z0 + h - 0.15):
            viga(P, (xx, y, zz), (xx, y + alto - 0.05, z0 + h / 2), 0.06, "madera", MADERA_OSC)
        viga(P, (xx, y + alto - 0.1, z0 + 0.15), (xx, y + alto - 0.1, z0 + h - 0.15), 0.06, "madera", MADERA_OSC)
    return y + alto


def cajita(P, c, s, col=None, yaw=0.0):
    """Un cajón de tablas (el choque que le pone cajon() se descarta al exportar: solo valen los choques con nombre)."""
    cajon(P, c, s, yaw, col)


def frutas(P, V, c, r, tipo):
    """El género de un cajón o una cesta: «manzanas», «peras», «coles», «cebollas», «nabos»."""
    c = Vector(c)
    if tipo == "coles":
        for k in range(4):
            a = k * 1.6
            hojas(V, c + Vector((math.cos(a) * r * 0.45, 0.06, math.sin(a) * r * 0.45)), 0.11, 12,
                  ((0.42, 0.62, 0.36), (0.50, 0.70, 0.40), (0.36, 0.54, 0.32)), 0.08, flex=0.1, aplastar=0.7)
        return
    cols = {"manzanas": [(0.86, 0.22, 0.18), (0.92, 0.70, 0.28), (0.80, 0.30, 0.20)],
            "peras": [(0.78, 0.76, 0.34), (0.70, 0.66, 0.30)], "cebollas": [(0.76, 0.52, 0.30), (0.86, 0.66, 0.42)],
            "nabos": [(0.92, 0.88, 0.80), (0.74, 0.48, 0.66)]}[tipo]
    for k in range(9):
        a, d = U(0, math.tau), U(0, r * 0.7)
        caja(P, c + Vector((math.cos(a) * d, 0.04 + (k % 3) * 0.035, math.sin(a) * d)), (0.075, 0.075, 0.075), "barro",
             CH(cols), rot=R(U(0, 90)))


def tinaja(P, c, h, r, col=BARRO):
    """Una tinaja, un cántaro o una orza de barro."""
    cilindro(P, c, [(0, r * 0.55), (h * 0.35, r), (h * 0.75, r * 0.85), (h * 0.9, r * 0.45), (h, r * 0.5)], 10, "barro",
             jit(col, 0.06))


def fardo(P, c, s, yaw=0.0):
    """Un fardo de paja atado."""
    caja(P, c, s, "tela", jit(PAJA, 0.05), rot=R(yaw), jit_v=0.02)
    for d in (-0.25, 0.25):
        caja(P, Vector(c) + R(yaw) @ Vector((s[0] * d, 0, 0)), (0.03, s[1] + 0.01, s[2] + 0.01), "tela", (0.62, 0.50, 0.30),
             rot=R(yaw))


def saco(P, c, yaw=0.0, col=(0.86, 0.76, 0.58), h=0.42):
    cilindro(P, c, [(0, 0.17), (0.12 * h / 0.42, 0.22), (0.3 * h / 0.42, 0.2), (0.38 * h / 0.42, 0.1), (h, 0.03)], 9, "tela",
             jit(col, 0.05), rot=R(yaw))


def farol_pie(M, P, x, z, y=None):
    """El farol de pie de la muestra (zócalo, poste, brazo y farol colgado)."""
    y = cota(x, z) if y is None else y
    caja_mm(M, (x - 0.17, y - 0.1, z - 0.17), (x + 0.17, y + 0.35, z + 0.17), "sillar", SILLAR)
    viga(M, (x, y + 0.3, z), (x, y + 3.3, z), 0.13, "madera", MADERA_OSC)
    viga(M, (x, y + 3.2, z), (x + 0.62, y + 3.2, z), 0.09, "madera", MADERA_OSC)
    viga(M, (x, y + 2.7, z), (x + 0.42, y + 3.2, z), 0.07, "madera", MADERA_OSC)
    viga(M, (x + 0.55, y + 3.2, z), (x + 0.55, y + 3.0, z), 0.015, "hierro", HIERRO)
    farol(M, (x + 0.55, y + 2.64, z))


def arbol(M, V, x, z, alto=1.0, y=None, copas=None):
    """El árbol de la muestra: tronco con dos ramas y la copa en racimos de hojas."""
    y = cota(x, z) if y is None else y
    e = alto
    cilindro(M, (x, y - 0.1, z), [(0, 0.4 * e), (0.5 * e, 0.3 * e), (2.6 * e, 0.24 * e), (3.6 * e, 0.2 * e)], 9, "madera",
             (0.52, 0.42, 0.34))
    viga(M, (x, y + 2.6 * e, z), (x + 1.3 * e, y + 4.2 * e, z + 0.4 * e), 0.16 * e, "madera", (0.52, 0.42, 0.34))
    viga(M, (x, y + 3.0 * e, z), (x - 1.1 * e, y + 4.4 * e, z - 0.3 * e), 0.15 * e, "madera", (0.52, 0.42, 0.34))
    for c, r in (copas or (((0, 4.6, 0), 1.9), ((1.6, 4.4, 0.6), 1.4), ((-1.5, 4.8, -0.2), 1.5), ((0.4, 5.8, -0.3), 1.3),
                           ((2.3, 3.6, 1.0), 1.0))):
        hojas(V, (x + c[0] * e, y + c[1] * e, z + c[2] * e), r * e, int(260 * r * e), HOJA, 0.16, flex=0.5, aplastar=0.8)


def arbol_lejano(M, V, x, z, alto=1.0, y=None):
    """El árbol de la muestra para el fondo lejano: el mismo tronco y la misma copa, con menos hojas y más grandes."""
    y = cota(x, z) if y is None else y
    e = alto
    cilindro(M, (x, y - 0.1, z), [(0, 0.4 * e), (0.5 * e, 0.3 * e), (2.6 * e, 0.24 * e), (3.6 * e, 0.2 * e)], 7, "madera",
             (0.52, 0.42, 0.34))
    for c, r in (((0, 4.6, 0), 1.9), ((1.6, 4.4, 0.6), 1.4), ((-1.5, 4.8, -0.2), 1.5), ((0.4, 5.8, -0.3), 1.3)):
        hojas(V, (x + c[0] * e, y + c[1] * e, z + c[2] * e), r * e, int(55 * r * e), HOJA, 0.34, flex=0.3, aplastar=0.8)


def valla_varas(P, x0, x1, z, y=None, alto=0.95, hueco=None):
    """La cerca de varas del huerto de la muestra (postes cada 0,6 m y tres varas), de x0 a x1 en z."""
    x = x0
    while x < x1:
        if hueco is None or not (hueco[0] < x < hueco[1]):
            yy = cota(x, z) if y is None else y
            viga(P, (x, yy - 0.05, z), (x + U(-0.03, 0.03), yy + alto, z + U(-0.03, 0.03)), 0.07, "madera", MADERA_GRIS)
        x += 0.6
    for h in (0.35, 0.6, 0.85):
        a = x0
        tramos = [(x0, x1)] if hueco is None else [(x0, hueco[0]), (hueco[1], x1)]
        for a, b in tramos:
            ya = cota(a, z) if y is None else y
            yb = cota(b, z) if y is None else y
            viga(P, (a, ya + h * alto / 0.95, z), (b, yb + h * alto / 0.95 + U(-0.04, 0.04), z), 0.035, "madera",
                 jit(MADERA_GRIS, 0.06))


def matorrales(V, x0, x1, z0, z1, y=None, flores=0.6):
    """Matorrales AGRUPADOS con calvas entre ellos (la orilla de la muestra)."""
    if not DECORADO:
        return
    x = x0
    while x < x1:
        cx, cz = x + U(-0.4, 0.4), U(z0, z1)
        yy = cota(cx, cz) if y is None else y
        for k in range(K.RND.randint(4, 9)):
            a, d = U(0, math.tau), U(0, 0.75)
            mata(V, (cx + math.cos(a) * d * 1.4, yy, cz + math.sin(a) * d * 0.6), U(0.14, 0.28), K.RND.randint(10, 20),
                 U(0.3, 0.6) * (1.0 - d * 0.4))
        if AZ() < flores:
            mata_flores(V, (cx + U(-0.4, 0.4), yy, cz + 0.1), 0.25, CH(FLORES), n=12, alto=0.45)
        if AZ() < 0.3:
            hojas(V, (cx + 0.3, yy + 0.25, cz + 0.2), 0.42, 40, HOJA, 0.11, flex=0.35, aplastar=0.7)
        x += U(1.6, 3.2)


def juntas_con_hierba(s, prob=0.8):
    if not DECORADO:
        return
    M, P, V = en(s)
    for j in JUNTAS[s]:
        if AZ() < prob:
            mata(V, (j[0], altura(j[0], j[1]) - 0.02, j[1]), 0.09, K.RND.randint(5, 9), U(0.1, 0.2), ladeo=0.6)


def en_mundo(u, y, z):
    """Dentro de un marco: el punto local en el mundo (para comprobar las rutas)."""
    return K.al_mundo((u, y, z))


def pieza_local(p, u, y, z, s):
    """Dentro de un marco: ¿cabe una pieza de tamaño s (local) en (u, y, z)? Si cae en lo andable, le pone choque."""
    w = Vector(en_mundo(u, y, z))
    return pieza_con_choque((w.x, w.y + s[1] / 2, w.z), s, K.XF[2] if K.XF else 0.0)


# ================================================================ T2: la calle comercial (con el horno)

def s_comercial():
    M, P, V = en("comercial")
    # --- la tienda de telas (oeste): casa de alero crema con postigos azules, escaparate, toldo y letrero
    def telas(m, p, v, W, F):
        escaparate(m, p, v, 0.55, 3.05, 0.78, 1.45, "telas")
        puerta_calle(m, p, 4.35, 1.05, 2.25, "dintel", AZUL_POSTIGO, y=0.03)
        toldo(m, 0.35, 3.25, 2.75, 2.32, 1.05, [(0.94, 0.92, 0.86), (0.46, 0.62, 0.78)])
        letrero_con(m, (5.4, 2.75, 0.02), (0, 0, 1), "tela")
        farol_pared(m, (0.2, 2.35, 0.04), (-0.55, 0, 0.84))
    casa("tienda_o", casa_alero, dict(rev=REVOQUE_A, post=AZUL_POSTIGO, pb=3.2, p1=2.75,
                                      ventanas_p1=[(1.3, 0.72), (3.4, 0.72, True), (5.05, 0.6)], chimenea=(1.2, -5.2)),
         base=0.0, extra=telas)
    # --- EL HORNO de Maela: planta baja de sillería, puerta abierta en arco (la luz del obrador sale a la calle), el
    #     mostrador a la calle bajo un arco rebajado con su tapa levantada, la chimenea ancha del horno y su letrero
    yb_h = altura(-26.0, 0.0)
    def horno(m, p, v, W, F):
        yd = altura(-22.0, 0.0) - yb_h
        puerta_calle(m, p, 4.0, 1.3, 2.3, "arco", MADERA, abierta=True, y=yd)
        ancla_p("brasa_puerta", (4.0, yd + 1.0, 0.5))
        ym = altura(-19.5, 0.0) - yb_h
        arco_rebajado(m, 6.5, 2.25, 1.75, 1.2, 0.0)
        caja_mm(m, (5.3, -0.1, -0.1), (7.7, ym + 0.98, 0.04), "sillar", jit(SILLAR, 0.04))
        for uu in (5.55, 7.45):                            # ménsulas de piedra bajo el tablero
            caja_mm(m, (uu - 0.12, ym + 0.7, 0.0), (uu + 0.12, ym + 0.98, 0.42), "sillar", jit(SILLAR, 0.05))
        caja_mm(m, (5.25, ym + 0.98, -0.12), (7.75, ym + 1.06, 0.6), "madera", jit(MADERA, 0.04), veta="larga")
        ancla_p("brasa_mostrador", (6.5, ym + 1.6, 0.2))
        for k, (uu, zz, r) in enumerate(((5.75, 0.25, 0.2), (6.6, 0.3, 0.17), (7.35, 0.22, 0.16))):
            cesta_pan(p, (uu, ym + 1.06, zz), r)
        for k in range(4):                                 # hogazas sueltas sobre un paño
            cilindro(p, (5.9 + k * 0.35, ym + 1.06, 0.48), [(0, 0.09), (0.06, 0.1), (0.1, 0.06), (0.11, 0.0)], 8, "barro",
                     jit(PAN, 0.06))
        caja_mm(p, (5.6, ym + 1.06, 0.38), (7.4, ym + 1.075, 0.58), "tela", (0.94, 0.92, 0.86))
        tapa = [Vector((5.2, 3.0, 0.06)), Vector((7.8, 3.0, 0.06)), Vector((7.8, 2.75, 1.05)), Vector((5.2, 2.75, 1.05))]
        for k in range(5):                                 # la tapa de tablas, levantada como un tejadillo
            a, b = k / 5, (k + 1) / 5
            q = [tapa[0].lerp(tapa[1], a), tapa[0].lerp(tapa[1], b), tapa[3].lerp(tapa[2], b), tapa[3].lerp(tapa[2], a)]
            caja(m, (q[0] + q[1] + q[2] + q[3]) / 4, ((q[1] - q[0]).length - 0.012, 0.05, (q[3] - q[0]).length),
                 "madera", jit(MADERA, 0.05), rot=Matrix(((1, 0, 0), (0, math.cos(0.245), math.sin(0.245)),
                                                         (0, -math.sin(0.245), math.cos(0.245)))), veta="larga")
        for uu in (5.35, 7.65):
            viga(m, (uu, ym + 1.06, 0.55), (uu, 2.78, 1.0), 0.04, "madera", MADERA_OSC)
        letrero_con(m, (0.35, 2.55, 0.02), (0, 0, 1), "pan")
        # sacos de harina junto a la puerta (fuera del umbral) y la pala de enhornar apoyada en la pared
        if DECORADO and pieza_local(p, 1.9, 0.0, 0.32, (1.1, 0.5, 0.5)):
            for uu in (1.55, 2.15):
                saco(p, (uu, 0.0, 0.32), U(0, 90))
        viga(m, (0.95, 0.02, 0.18), (1.05, 2.05, 0.08), 0.045, "madera", MADERA_GRIS)
        caja(m, (0.95, 0.18, 0.2), (0.3, 0.32, 0.03), "madera", MADERA_GRIS)
    casa("horno", casa_alero, dict(rev=REVOQUE_D, post=OCRE_POSTIGO, pb=3.05, p1=2.6, pb_mat="sillar", vuelo=0.45,
                                   ventanas_pb=[(1.75, 0.8, 1.15, 1.0)], ventanas_p1=[(1.3, 0.7), (3.7, 0.7, True), (6.5, 0.7)],
                                   chimenea=(5.6, -5.4, 0.95, 1.25, 1.15), musgo=0.35, mensulas=[0.3, 2.6, 5.2, 7.7]),
         base=yb_h, extra=horno)
    # --- la tienda de ultramarinos (este): hastial rosado con postigos rojos, balconcillo, la boca en arco con toneles
    yb_e = altura(-18.0, 0.0)
    def ultramarinos(m, p, v, W, F):
        arco_rebajado(m, 3.6, 1.6, 1.5, 1.2, 0.0)
        if DECORADO:
            for uu in (2.95, 4.25):
                if pieza_local(p, uu, 0.0, 0.32, (0.7, 0.9, 0.7)):
                    barril(p, (uu, 0.0, 0.32), 0.3, 0.82)
            saco(p, (3.6, 0.0, 0.18), 20, (0.90, 0.82, 0.62), 0.5)
        yd = altura(-11.3, 0.0) - yb_e
        puerta_calle(m, p, 6.7, 1.0, 2.15, "dintel", ROJO_POSTIGO, y=yd)
        letrero_con(m, (7.55, 2.45, 0.02), (0, 0, 1), "tonel")
        farol_pared(m, (0.2, 2.25, 0.04), (-0.55, 0, 0.84))
    casa("tienda_e", casa_hastial, dict(rev=REVOQUE_E, post=ROJO_POSTIGO, pb=2.8, balcon=4.0,
                                        ventanas_p1=[(1.4, 0.6), (6.6, 0.6, True)], chimenea=(1.6, -4.6), luz_hastial=True),
         base=yb_e, extra=ultramarinos)
    pie_fachada(V, -32.0, -10.0, -1.0, salvo=((-31.5, -28.9), (-28.3, -27.1), (-22.8, -21.2), (-20.8, -18.2),
                                             (-15.7, -11.8)))
    # --- lado sur, BAJO (≤ 1,4 m): el puesto de verduras, el de cacharros, cajones y el carro de reparto del horno
    b = BLOQUE["puesto_c1"]
    r = b[2]
    yt = mesa(P, r, cota(r[0] + 2, r[1] + 0.8), 0.8)
    for k, tipo in enumerate(("coles", "manzanas", "cebollas", "nabos", "peras", "coles")):
        x = r[0] + 0.45 + k * 0.62
        cajita(P, (x, yt, r[1] + 0.8), (0.52, 0.22, 0.6), yaw=U(-5, 5))
        frutas(P, V, (x, yt + 0.2, r[1] + 0.8), 0.22, tipo)
    for k in range(3):                                     # cestos en el suelo, delante
        cesta = (r[0] + 0.6 + k * 1.3, cota(r[0], r[1]), r[1] - 0.05)
        cilindro(P, cesta, [(0, 0.16), (0.2, 0.22), (0.22, 0.22)], 10, "madera", (0.80, 0.66, 0.44))
        frutas(P, V, Vector(cesta) + Vector((0, 0.18, 0)), 0.18, CH(("manzanas", "cebollas")))
    b = BLOQUE["puesto_c2"]
    r = b[2]
    yt = mesa(P, r, cota(r[0] + 1.5, r[1] + 0.8), 0.62, MADERA_GRIS)
    for k in range(7):
        tinaja(P, (r[0] + 0.3 + (k % 4) * 0.7, yt, r[1] + 0.45 + (k // 4) * 0.6), U(0.3, 0.5), U(0.1, 0.17),
               CH((BARRO, (0.80, 0.56, 0.42), (0.70, 0.46, 0.34))))
    for k in range(3):
        tinaja(P, (r[0] + 0.4 + k * 1.0, cota(r[0], r[1]), r[1] - 0.15), U(0.45, 0.6), U(0.16, 0.22))
    for bid in ("cajones_c1", "cajones_c2"):
        r = BLOQUE[bid][2]
        y = cota(r[0] + 0.5, r[1] + 0.5)
        cajita(P, (r[0] + 0.55, y, r[1] + r[3] / 2), (0.8, 0.5, 0.7), yaw=U(-8, 8))
        cajita(P, (r[0] + 1.4, y, r[1] + r[3] / 2), (0.6, 0.45, 0.55), yaw=U(-8, 8))
        cajita(P, (r[0] + 0.6, y + 0.5, r[1] + r[3] / 2), (0.55, 0.38, 0.5), yaw=U(-12, 12))
    carro_horno(P, V)
    farol_pie(M, P, -25.2, 6.6)
    # --- vegetación: la orilla sur en matorrales agrupados, hiedra en la esquina de las telas, hierba en las juntas
    matorrales(V, -33.0, -9.0, 7.2, 8.6)
    for x in (-27.3, -20.6, -16.4, -11.3):
        mata(V, (x, cota(x, 5.6), 5.6 + U(0, 0.4)), 0.25, 14, 0.4)
    if DECORADO:
        hiedra(V, -31.6, -1.0, 4.4, y0=0.0)
        hojas(V, (-11.0, 0.9, -0.85), 0.45, 45, HOJA, 0.09, flex=0.3, aplastar=1.6, hacia=(0, 0, 1))   # un rosal
    juntas_con_hierba("comercial")


def carro_horno(P, V):
    """El carro de reparto del horno, PARADO: dos ruedas grandes, la caja de tablas con un cesto tapado con un paño, las
    varas apoyadas en el suelo y la rueda del sur torcida (se le partió el pasador)."""
    r = BLOQUE["carro_horno"][2]
    cx, cz = r[0] + 1.2, r[1] + r[3] / 2
    y = altura(cx, cz)
    for s, lad in ((-1, 9.0), (1, 0.0)):
        rueda(P, (cx, y + 0.56 - (0.05 if lad else 0.0), cz + s * 0.66), 0.56, 0.0, ladeo=lad * s)
    viga(P, (cx, y + 0.56, cz - 0.6), (cx, y + 0.56, cz + 0.6), 0.07, "hierro", HIERRO)
    caja_mm(P, (cx - 1.0, y + 0.72, cz - 0.52), (cx + 0.9, y + 0.78, cz + 0.52), "madera", jit(MADERA, 0.05), veta="larga")
    for zz in (-0.5, 0.5):
        caja_mm(P, (cx - 1.0, y + 0.78, cz + zz - 0.03), (cx + 0.9, y + 1.12, cz + zz + 0.03), "madera", jit(MADERA, 0.05),
                veta="larga")
    for xx in (-1.0, 0.9):
        caja_mm(P, (cx + xx - 0.03, y + 0.78, cz - 0.5), (cx + xx + 0.03, y + 1.08, cz + 0.5), "madera", jit(MADERA, 0.05))
    for s in (-1, 1):                                       # las varas, apoyadas en el suelo
        viga(P, (cx + 0.9, y + 0.74, cz + s * 0.4), (cx + 2.3, y + 0.05, cz + s * 0.46), 0.06, "madera", MADERA_OSC)
    cilindro(P, (cx - 0.3, y + 0.78, cz), [(0, 0.3), (0.3, 0.36), (0.32, 0.36)], 12, "madera", (0.80, 0.66, 0.44))
    caja(P, (cx - 0.3, y + 1.12, cz), (0.78, 0.04, 0.78), "tela", (0.94, 0.92, 0.86), rot=R(12), jit_v=0.03)
    cesta_pan(P, (cx + 0.45, y + 0.78, cz - 0.15), 0.18)
    viga(P, (cx - 1.3, y + 0.02, cz + 0.3), (cx - 1.05, y + 0.4, cz + 0.42), 0.05, "madera", MADERA_GRIS)   # una cuña


# ================================================================ T3: la plaza del mercado (con la lonja y la muralla)

def lonja(m, p, v, W, F):
    """La lonja: soportal abierto al sur con dos arcos sobre columnas, el suelo de losas dentro, bancos y fardos al fondo;
    encima, el piso de entramado con dos ventanas; tejado de alero."""
    yb, y1 = 3.2, 5.9
    fondo_s = 1.8                                          # hondo del soportal
    caja_mm(m, (0.0, -0.6, -F), (W, 0.42, 0.05), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (0.1, 0.42, -F), (W - 0.1, yb, -fondo_s), "revoque", REVOQUE_F)          # el muro del fondo
    placa(m, [(-0.55, 0.0), (0.55, 0.0), (0.55, 1.9), (-0.55, 1.9)], (W / 2, 0.42, -fondo_s), (1, 0, 0), (0, 1, 0), 0.01,
          "hierro", OSCURO, lados=False)
    caja_mm(m, (0.0, 0.42, -fondo_s), (0.2, yb, 0.0), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (W - 0.2, 0.42, -fondo_s), (W, yb, 0.0), "sillar", jit(SILLAR, 0.03))
    for uu in (0.25, W / 2, W - 0.25):                     # columnas con basa y capitel
        cilindro(m, (uu, 0.42, -0.12), [(0, 0.2), (0.12, 0.2), (0.14, 0.15), (2.0, 0.14), (2.05, 0.2), (2.15, 0.22)], 10,
                 "sillar", jit(SILLAR, 0.04))
    for k in range(2):                                     # dos arcos de medio punto entre las columnas
        cu = (0.25 + W / 2) / 2 if k == 0 else (W / 2 + W - 0.25) / 2
        semi = (W / 2 - 0.25) / 2 - 0.12
        for j in range(7):
            a0, a1 = math.pi * j / 7, math.pi * (j + 1) / 7
            pts = [(math.cos(a0) * semi, math.sin(a0) * semi), (math.cos(a0) * (semi + 0.26), math.sin(a0) * (semi + 0.26)),
                   (math.cos(a1) * (semi + 0.26), math.sin(a1) * (semi + 0.26)), (math.cos(a1) * semi, math.sin(a1) * semi)]
            placa(m, [(x * 0.99, y * 0.99) for x, y in pts], (cu, 2.57, -0.25), (1, 0, 0), (0, 1, 0), 0.24, "sillar",
                  jit(SILLAR, 0.05))
    caja_mm(m, (0.0, 2.57, -0.25), (W, yb, 0.0), "sillar", jit(SILLAR, 0.03), caras="sa")
    caja_mm(m, (0.2, yb - 0.1, -fondo_s), (W - 0.2, yb, -0.25), "madera", MADERA_OSC, caras="b")   # el techo del soportal
    caja_mm(m, (0.2, 0.42, -fondo_s), (W - 0.2, 0.44, 0.0), "sillar", jit(SILLAR, 0.02), caras="a")
    if DECORADO:
        caja_mm(p, (0.4, 0.44, -fondo_s + 0.05), (1.6, 0.86, -fondo_s + 0.45), "madera", MADERA_GRIS)   # banco
        for k in range(3):
            saco(p, (W - 0.8 + U(-0.2, 0.2), 0.44, -fondo_s + 0.35 + k * 0.32), U(0, 90))
        fardo(p, (W - 1.6, 0.66, -fondo_s + 0.4), (0.8, 0.44, 0.5), U(-10, 10))
    viga(m, (0.0, yb - 0.08, 0.05), (W, yb - 0.08, 0.05), 0.2, "madera", MADERA_OSC, alto=0.18)
    entramado(m, 0.0, W, yb, y1, 0.05, [0.9, 1.6, 2.4, 3.1], REVOQUE_F, MADERA_OSC, cruces=(0, 4))
    caja_mm(m, (0.0, yb, -F), (0.12, y1, -0.07), "revoque", REVOQUE_F)
    caja_mm(m, (W - 0.12, yb, -F), (W, y1, -0.07), "revoque", REVOQUE_F)
    fl = [ventana(m, 1.25, yb + 0.75, 0.09, 0.55, 0.9, VERDE_POSTIGO, jardinera=True),
          ventana(m, 2.75, yb + 0.75, 0.09, 0.55, 0.9, VERDE_POSTIGO, luz=True)]
    ventana(m, -2.4, yb + 0.75, 0.0, 0.55, 0.85, VERDE_POSTIGO, eje="x", sig=-1.0)
    yr = y1 + 2.0
    za, zb = 0.7, -F - 0.4
    zr = (za + zb) / 2
    faldon(m, (-0.4, y1 - 0.05, za), (W + 0.4, y1 - 0.05, za), (0, yr - y1 + 0.05, zr - za), TEJA, musgo=0.35)
    faldon(m, (W + 0.4, y1 - 0.05, zb), (-0.4, y1 - 0.05, zb), (0, yr - y1 + 0.05, zr - zb), TEJA, musgo=0.1)
    cumbrera(m, (-0.4, yr + 0.02, zr), (W + 0.4, yr + 0.02, zr))
    for xh, s in ((0.0, -1), (W, 1)):
        pts = [Vector((xh, y1, 0.0)), Vector((xh, yr - 0.05, zr)), Vector((xh, y1, -F))]
        m.cara(list(reversed(pts)) if s > 0 else pts, "revoque", REVOQUE_F)
    farol_pared(m, (0.15, 2.45, 0.05), (-0.6, 0, 0.8))
    return fl


def muralla(m, p, v, W, F, e=None):
    """La muralla oeste de Oakhaven (desde el arrabal): sillería grande con talud, contrafuertes, matacanes y almenas, y
    el POSTIGO cerrado (decorado) con su farol y un poyo de piedra."""
    alto = 8.0
    caja_mm(m, (0.0, -0.6, -F), (W, alto, 0.0), "sillar", jit((0.84, 0.79, 0.70), 0.02))
    for k in range(int(W / 1.2)):                          # el talud de la base
        u0 = k * 1.2
        pts = [Vector((u0, 0.0, 0.55)), Vector((u0 + 1.2, 0.0, 0.55)), Vector((u0 + 1.2, 1.3, 0.0)), Vector((u0, 1.3, 0.0))]
        m.cara(pts, "sillar", jit((0.80, 0.75, 0.66), 0.04))
    for uu in (3.0, 9.0, 21.0, 26.0):                       # contrafuertes
        caja_mm(m, (uu - 0.5, 0.0, 0.0), (uu + 0.5, 5.6, 0.7), "sillar", jit((0.82, 0.77, 0.68), 0.03), jit_v=0.01)
        pts = [Vector((uu - 0.5, 5.6, 0.7)), Vector((uu + 0.5, 5.6, 0.7)), Vector((uu + 0.5, 6.4, 0.0)),
               Vector((uu - 0.5, 6.4, 0.0))]
        m.cara(pts, "sillar", jit((0.80, 0.75, 0.66), 0.04))
    for k in range(int(W / 0.9)):                          # matacanes bajo el parapeto
        caja_mm(m, (k * 0.9 + 0.2, alto - 0.6, 0.0), (k * 0.9 + 0.5, alto - 0.2, 0.35), "sillar", jit(SILLAR, 0.05))
    caja_mm(m, (0.0, alto - 0.2, -0.4), (W, alto + 0.6, 0.38), "sillar", jit((0.84, 0.79, 0.70), 0.03))
    x = 0.2
    while x + 0.9 <= W:
        caja_mm(m, (x, alto + 0.6, -0.3), (x + 0.9, alto + 1.45, 0.36), "sillar", jit(SILLAR, 0.05), jit_v=0.01)
        x += 1.7
    # el postigo: arco de dovelas, hoja de roble con clavos, cerrado; un farol y un poyo
    u0 = 15.0
    puerta_calle(m, p, u0, 1.3, 2.35, "arco", (0.36, 0.26, 0.20), y=0.4, marco_col=(0.80, 0.74, 0.64))
    for k in range(5):
        for j in range(4):
            caja(m, (u0 - 0.45 + k * 0.22, 0.75 + j * 0.42, 0.06), (0.05, 0.05, 0.03), "hierro", HIERRO)
    farol_pared(m, (u0 + 1.25, 2.75, 0.04), (0.0, 0, 1.0))
    if DECORADO and pieza_local(p, 18.2, 0.4, 0.3, (1.5, 0.5, 0.5)):
        caja_mm(p, (17.5, 0.4, 0.05), (18.9, 0.85, 0.55), "sillar", jit(SILLAR, 0.05))
    if DECORADO:
        for uu in (5.0, 12.5, 23.5):
            hiedra(v, uu, 0.0, 5.0, y0=0.0)


def oakhaven_tras_la_muralla(M, P, V):
    """Lo que asoma por encima de la muralla: tejados de Oakhaven y una torre de vigía (lejos, sencillo, luz en los
    vértices). Ninguno es un edificio con nombre de la ciudad."""
    for (x0, x1, z0, z1, y1, rev) in ((12.5, 18.5, -18.0, -10.0, 8.6, REVOQUE_A), (12.5, 19.0, -8.0, 0.5, 9.4, REVOQUE_B),
                                      (13.0, 20.0, 2.0, 10.0, 8.2, REVOQUE_C), (20.0, 27.0, -14.0, -4.0, 10.6, REVOQUE_D),
                                      (21.0, 28.0, -2.0, 7.0, 9.8, REVOQUE_E)):
        caja_mm(P, (x0, 0.0, z0), (x1, y1, z1), "revoque", rev)
        ym = y1 + (z1 - z0) * 0.32
        faldon(P, (x0 - 0.4, y1 - 0.05, z1 + 0.4), (x0 - 0.4, y1 - 0.05, z0 - 0.4), ((x1 - x0) / 2 + 0.4, ym - y1, 0), TEJA,
               musgo=0.2)
        faldon(P, (x1 + 0.4, y1 - 0.05, z0 - 0.4), (x1 + 0.4, y1 - 0.05, z1 + 0.4), (-(x1 - x0) / 2 - 0.4, ym - y1, 0), TEJA,
               musgo=0.2)
        P.cara([Vector((x0, y1, z1)), Vector((x1, y1, z1)), Vector(((x0 + x1) / 2, ym, z1))], "revoque", rev)
    cilindro(P, (24.0, 0.0, 12.0), [(0, 2.1), (14.5, 1.9)], 12, "sillar", jit(SILLAR, 0.03), suave=False)
    cono(P, (24.0, 14.4, 12.0), 2.5, 3.6, 12, "tejas", PIZARRA[0])


def s_plaza():
    M, P, V = en("plaza")
    casa("muralla_oak", muralla, {}, frente="o", base=0.0, flores=False)
    casa("lonja", lambda m, p, v, W, F, e: lonja(m, p, v, W, F), {}, base=0.0)
    casa("casa_plaza_no", casa_hastial, dict(rev=REVOQUE_F, post=VERDE_POSTIGO, pb=2.8, balcon=2.5, ventanas_p1=[],
                                             ventanas_pb=[(1.0, 0.6, 0.95, 1.0), (4.0, 0.6, 0.95, 1.0, True)],
                                             lados={"e": [(-1.4, 1.1), (-2.6, 3.6)]}, chimenea=(1.2, -2.6),
                                             polea=False, alto_tejado=2.2),
         base=0.0, extra=lambda m, p, v, W, F: puerta_calle(m, p, 2.5, 1.0, 2.2, "arco", VERDE_PUERTA, y=0.4))
    casa("cobertizo", lambda m, p, v, W, F, e: nave(m, p, v, W, F, 2.4, dict(vanos=2, alto_tejado=1.1)), {}, base=0.0)
    oakhaven_tras_la_muralla(M, M, V)                     # (en lo fijo: una superficie de tejas menos en las piezas)
    # --- el pretil del sur, con macetas
    r = BLOQUE["pretil_plaza"][2]
    with marco((r[0], 0.0, r[1] + r[3]), 0.0) as Fm:
        muro_piedra(Fm(M), 0.0, r[2], -0.5, 1.0, r[3], col=(0.86, 0.81, 0.72))
    for x in (-8.6, -5.1, 1.2, 6.4):
        maceta(P, V, (x, 1.14, 7.4), 0.2, 0.26)
    # --- los puestos: el del pan de Maela (toldo a rayas bajo), el de fruta y el de hierbas y flores
    r = BLOQUE["puesto_pan"][2]
    yt = mesa(P, r, 0.4, 0.85)
    for k, (dx, rr) in enumerate(((0.45, 0.2), (1.15, 0.22), (1.85, 0.19))):
        cesta_pan(P, (r[0] + dx, yt, r[1] + 0.6), rr)
    caja_mm(P, (r[0] + 0.2, yt, r[1] + 0.95), (r[0] + 2.2, yt + 0.015, r[1] + 1.3), "tela", (0.94, 0.92, 0.86))
    for k in range(5):
        cilindro(P, (r[0] + 0.35 + k * 0.4, yt + 0.015, r[1] + 1.12), [(0, 0.09), (0.06, 0.1), (0.1, 0.06), (0.11, 0.0)], 8,
                 "barro", jit(PAN, 0.06))
    for xx in (r[0] + 0.1, r[0] + r[2] - 0.1):              # el toldo bajo, sobre cuatro varas
        for zz in (r[1] + 0.1, r[1] + r[3] - 0.1):
            viga(P, (xx, 0.4, zz), (xx, 2.0 if zz < r[1] + 0.5 else 1.85, zz), 0.045, "madera", MADERA_OSC)
    with marco((r[0], 0.0, r[1] + 0.1), 0.0) as Fm:
        toldo(Fm(M), -0.1, r[2] + 0.1, 2.02, 1.82, r[3] - 0.1, [(0.94, 0.90, 0.80), (0.80, 0.36, 0.30)])
    r = BLOQUE["puesto_p2"][2]
    yt = mesa(P, r, 0.4, 0.8, MADERA_GRIS)
    for k, tipo in enumerate(("manzanas", "peras", "manzanas", "nabos")):
        x = r[0] + 0.35 + k * 0.56
        cajita(P, (x, yt, r[1] + 0.7), (0.48, 0.2, 0.62), yaw=U(-6, 6))
        frutas(P, V, (x, yt + 0.18, r[1] + 0.7), 0.2, tipo)
    r = BLOQUE["puesto_p3"][2]
    yt = mesa(P, r, 0.4, 0.78)
    for k in range(4):
        maceta(P, V, (r[0] + 0.3 + k * 0.48, yt, r[1] + 0.6), 0.13, 0.18)
    for xx in (r[0] + 0.1, r[0] + r[2] - 0.1):
        viga(P, (xx, 0.4, r[1] + 0.1), (xx, 2.35, r[1] + 0.1), 0.045, "madera", MADERA_OSC)
        viga(P, (xx, 0.4, r[1] + r[3] - 0.1), (xx, 2.15, r[1] + r[3] - 0.1), 0.045, "madera", MADERA_OSC)
    with marco((r[0], 0.0, r[1] + 0.1), 0.0) as Fm:
        toldo(Fm(M), -0.1, r[2] + 0.1, 2.37, 2.17, r[3] - 0.1, [(0.94, 0.90, 0.80), (0.42, 0.58, 0.40)])
    # --- el árbol del mercado (al noroeste: su sombra en la plaza, sin tapar a Kael), faroles y lo suelto
    if pieza_con_choque((-8.7, 0.4 + 1.0, -6.3), (0.8, 2.0, 0.8)):
        arbol(M, V, -8.7, -6.3, 0.95, 0.4)
    farol_pie(M, P, -9.2, 6.4, 0.4)
    pieza_con_choque((-9.2, 1.4, 6.4), (0.4, 2.0, 0.4))
    farol_pie(M, P, 7.3, -6.9, 0.4)
    pieza_con_choque((7.3, 1.4, -6.9), (0.4, 2.0, 0.4))
    if DECORADO:
        for (x, z) in ((-6.9, 5.7), (6.9, 6.2), (7.9, 2.6)):
            if pieza_con_choque((x, 0.9, z), (0.8, 1.0, 0.8)):
                for k in range(2):
                    barril(P, (x + k * 0.55 - 0.25, 0.4, z + U(-0.1, 0.1)), 0.28, 0.78)
                cajita(P, (x + 0.1, 0.4 + 0.78, z), (0.5, 0.36, 0.45), yaw=U(-10, 10))
        # al pie de la muralla y del pretil, y en los rincones
        x = -9.6
        while x < 8.6:
            if AZ() < 0.5:
                mata(V, (x, 0.4, 6.95 + U(0, 0.15)), U(0.12, 0.22), K.RND.randint(8, 14), U(0.2, 0.36))
            x += U(0.4, 0.9)
        z = -15.5
        while z < 11.5:
            if AZ() < 0.55 and not (-2.4 < z < 0.4):
                mata(V, (8.75 - U(0, 0.25), cota(8.6, z), z), U(0.14, 0.26), K.RND.randint(10, 18), U(0.25, 0.45))
            z += U(0.3, 0.8)
        matorrales(V, -11.0, 10.0, 8.2, 10.0, 0.0)
        for p in ((-9.6, 0.4, -7.6), (4.7, 0.4, -7.7), (-4.8, 0.4, -7.6)):
            mata(V, p, 0.24, 14, 0.4)
    juntas_con_hierba("plaza", 0.5)


# ================================================================ T1: el patio de caravanas (con el establo)

def muro_arrabal(m, p, v, W, F, e=None):
    """El muro del arrabal: mampostería gris cálida con albardilla, contrafuertes, mechinales y algo de hiedra."""
    alto = (e or {}).get("alto", 4.5)
    col = (0.80, 0.76, 0.68)
    caja_mm(m, (0.0, -0.6, -F), (W, alto, 0.0), "sillar", jit(col, 0.03))
    caja_mm(m, (-0.05, alto, -F - 0.06), (W + 0.05, alto + 0.16, 0.08), "sillar", jit(SILLAR, 0.05))
    u = 2.5
    while u < W - 1.0:
        caja_mm(m, (u - 0.45, -0.3, 0.0), (u + 0.45, alto * 0.7, 0.55), "sillar", jit(col, 0.04), jit_v=0.01)
        m.cara([Vector((u - 0.45, alto * 0.7, 0.55)), Vector((u + 0.45, alto * 0.7, 0.55)), Vector((u + 0.45, alto * 0.85, 0.0)),
                Vector((u - 0.45, alto * 0.85, 0.0))], "sillar", jit(col, 0.05))
        for k in range(2):
            caja(m, (u + 2.0 + U(-0.4, 0.4), U(1.8, alto - 0.6), 0.005), (0.14, 0.12, 0.02), "hierro", OSCURO)
        u += 6.0
    if DECORADO:
        for k in range(int(W / 9)):
            hiedra(v, U(1.0, W - 1.0), 0.0, alto * U(0.6, 0.9), y0=0.0)


def puerta_caravanas(m, p, v, W, F, e=None):
    """El arco de caravanas en el muro oeste: dos torres almenadas con saeteras, el arco de medio punto y el RASTRILLO
    bajado (decorado: no se sale por aquí); un farol en la torre."""
    col = (0.84, 0.79, 0.70)
    for u0, u1 in ((0.0, 1.6), (4.8, 6.4)):                 # las torres (algo salientes)
        caja_mm(m, (u0, -0.6, -3.5), (u1, 6.0, 0.3), "sillar", jit(col, 0.03))
        caja_mm(m, (u0 - 0.06, 6.0, -3.56), (u1 + 0.06, 6.18, 0.36), "sillar", jit(SILLAR, 0.05))
        for uu in (u0 + 0.15, u1 - 0.65):
            caja_mm(m, (uu, 6.18, 0.0), (uu + 0.5, 6.95, 0.3), "sillar", jit(SILLAR, 0.05), jit_v=0.01)
        caja_mm(m, ((u0 + u1) / 2 - 0.06, 3.3, 0.3), ((u0 + u1) / 2 + 0.06, 4.2, 0.31), "hierro", OSCURO)   # saetera
    caja_mm(m, (1.6, 4.6, -3.5), (4.8, 6.0, 0.0), "sillar", jit(col, 0.03))
    caja_mm(m, (1.5, 6.0, -3.56), (4.9, 6.18, 0.06), "sillar", jit(SILLAR, 0.05))
    for k in range(2):
        caja_mm(m, (2.0 + k * 1.6, 6.18, -0.3), (2.6 + k * 1.6, 6.9, 0.0), "sillar", jit(SILLAR, 0.05))
    cu, rad, ys = 3.2, 1.6, 3.0
    for j in range(9):                                     # las dovelas
        a0, a1 = math.pi * j / 9, math.pi * (j + 1) / 9
        pts = [(math.cos(a0) * rad, math.sin(a0) * rad), (math.cos(a0) * (rad + 0.36), math.sin(a0) * (rad + 0.36)),
               (math.cos(a1) * (rad + 0.36), math.sin(a1) * (rad + 0.36)), (math.cos(a1) * rad, math.sin(a1) * rad)]
        placa(m, [(x * 0.99, y * 0.99) for x, y in pts], (cu, ys, -0.05), (1, 0, 0), (0, 1, 0), 0.12, "sillar",
              jit(SILLAR, 0.05))
    enjuta = [(-1.6, 0.0), (-1.6, 1.6)] + [(math.cos(math.pi * k / 12) * -1.0 * (rad + 0.36) * -1, 0) for k in range(0)]
    for s in (-1, 1):                                      # las enjutas (entre el arco y el muro de encima)
        pts = [(s * 1.6, 0.0), (s * 1.6, 1.6)]
        for k in range(7):
            a = math.pi / 2 * k / 6
            pts.append((s * math.cos(a) * (rad + 0.36), math.sin(a) * (rad + 0.36)))
        pts = [pts[0]] + list(reversed(pts[2:])) + [pts[1]] if s > 0 else pts
        placa(m, pts, (cu, ys, -0.1), (1, 0, 0), (0, 1, 0), 0.1, "sillar", jit(col, 0.04), lados=False)
    for s in (-1, 1):
        caja_mm(m, (cu + s * 1.6 - (0.0 if s > 0 else 0.0) - 0.05, 0.0, -3.5), (cu + s * 1.6 + 0.05, ys, -0.05), "sillar",
                jit(col, 0.03))
    x = 1.65                                               # el rastrillo: barrotes de madera con puntas de hierro
    while x < 4.76:
        viga(m, (x, 0.12, -1.2), (x, 4.4, -1.2), 0.07, "madera", MADERA_OSC)
        caja(m, (x, 0.06, -1.2), (0.05, 0.12, 0.05), "hierro", HIERRO)
        x += 0.26
    for y in (0.6, 1.4, 2.2, 3.0, 3.8):
        viga(m, (1.6, y, -1.14), (4.8, y, -1.14), 0.06, "madera", MADERA_OSC)
    caja_mm(m, (1.6, 4.4, -3.5), (4.8, 4.62, -0.05), "sillar", jit(col, 0.03), caras="b")
    farol_pared(m, (0.8, 3.0, 0.32), (0.0, 0, 1.0))


def establo(m, p, v, W, F, e=None):
    """El establo de Brena: nave de tablas con dos cuadras abiertas a medio portón, el pajar con su puerta y heno
    asomando, la viga de la polea, el gancho del cepillo y una herradura clavada."""
    nave(m, p, v, W, F, 3.1, dict(vanos=2, alto_tejado=1.7, musgo=0.5, tabla=(0.60, 0.54, 0.46)))
    for u0, u1 in ((0.45, 2.7), (3.3, 5.55)):
        caja_mm(m, (u0, 0.0, 0.025), (u1, 2.2, 0.03), "hierro", OSCURO)
        caja_mm(m, (u0, 0.0, 0.03), (u1, 1.15, 0.1), "madera", jit(MADERA, 0.04), veta="larga")     # medio portón
        viga(m, (u0, 0.2, 0.11), (u1, 1.05, 0.11), 0.06, "madera", MADERA_OSC)
        viga(m, (u0 - 0.05, 2.25, 0.08), (u1 + 0.05, 2.25, 0.08), 0.16, "madera", MADERA_OSC, alto=0.16)
    caja_mm(m, (2.55, 2.45, 0.025), (3.45, 3.0, 0.03), "hierro", OSCURO)
    for k in range(5):
        caja(m, (2.6 + k * 0.2, 2.5, 0.1), (0.24, 0.12, 0.22), "tela", jit(PAJA, 0.06), rot=R(U(-20, 20)), jit_v=0.02)
    viga(m, (3.0, 3.25, -0.4), (3.0, 3.25, 0.9), 0.15, "madera", MADERA_OSC, alto=0.16)
    cilindro(m, (2.96, 3.1, 0.78), [(0, 0.1), (0.08, 0.1)], 10, "madera", MADERA, rot=R(0, 0, 90))
    viga(m, (3.04, 3.1, 0.78), (3.04, 1.9, 0.78), 0.02, "tela", (0.70, 0.62, 0.48))
    viga(m, (4.4, 1.55, 0.06), (4.4, 1.55, 0.2), 0.03, "hierro", HIERRO)      # el gancho del cepillo
    viga(m, (4.4, 1.55, 0.2), (4.4, 1.68, 0.24), 0.025, "hierro", HIERRO)
    for k in range(7):                                    # la herradura, de la suerte
        a0, a1 = math.pi * (-0.15 + k / 6 * 1.3), math.pi * (-0.15 + (k + 1) / 6 * 1.3)
        viga(m, (3.0 + math.cos(a0) * 0.1, 2.0 - math.sin(a0) * 0.1, 0.1), (3.0 + math.cos(a1) * 0.1, 2.0 - math.sin(a1) * 0.1, 0.1),
             0.025, "hierro", HIERRO)
    viga(m, (0.4, 0.95, 0.2), (2.7, 0.95, 0.2), 0.08, "madera", MADERA_GRIS)   # la barra de amarre (sin choque)
    for uu in (0.45, 2.65):
        viga(m, (uu, 0.0, 0.2), (uu, 1.0, 0.2), 0.1, "madera", MADERA_OSC)


def carro_caravana(P, V):
    """El carro de la caravana: caja de tablas sobre cuatro ruedas, cargado de cajones, sacos y un tonel, con una lona
    atada sobre parte de la carga (≤ 1,8 m) y la lanza en el suelo."""
    r = BLOQUE["carro_caravana"][2]
    cx, cz = r[0] + r[2] / 2, r[1] + r[3] / 2
    for xx in (cx - 1.05, cx + 1.0):
        for s in (-1, 1):
            rueda(P, (xx, 0.45, cz + s * 0.98), 0.45, 0.0, radios=8)
    caja_mm(P, (cx - 1.5, 0.72, cz - 0.85), (cx + 1.5, 0.8, cz + 0.85), "madera", jit(MADERA, 0.05), veta="larga")
    for s in (-1, 1):
        caja_mm(P, (cx - 1.5, 0.8, cz + s * 0.85 - 0.03), (cx + 1.5, 1.15, cz + s * 0.85 + 0.03), "madera",
                jit(MADERA_GRIS, 0.05), veta="larga")
    for xx in (-1.5, 1.5):
        caja_mm(P, (cx + xx - 0.03, 0.8, cz - 0.85), (cx + xx + 0.03, 1.1, cz + 0.85), "madera", jit(MADERA_GRIS, 0.05))
    cajita(P, (cx - 0.9, 0.8, cz - 0.35), (0.7, 0.5, 0.6), yaw=4)
    cajita(P, (cx - 0.9, 0.8, cz + 0.4), (0.6, 0.45, 0.6), yaw=-6)
    cajita(P, (cx - 0.85, 1.3, cz), (0.55, 0.4, 0.5), yaw=10)
    for k in range(3):
        saco(P, (cx + 0.2 + k * 0.35, 0.8, cz + U(-0.4, 0.4)), U(0, 90))
    barril(P, (cx + 1.05, 0.8, cz - 0.4), 0.26, 0.7)
    caja(P, (cx + 0.6, 1.32, cz + 0.2), (1.2, 0.5, 1.4), "tela", (0.86, 0.80, 0.66), rot=R(3), jit_v=0.06)
    for s in (-1, 1):
        viga(P, (cx + 0.6 + s * 0.5, 1.6, cz - 0.75), (cx + 0.6 + s * 0.5, 0.8, cz - 0.9), 0.015, "tela", (0.62, 0.50, 0.30))
    viga(P, (cx + 1.5, 0.6, cz), (cx + 3.0, 0.04, cz + 0.1), 0.08, "madera", MADERA_OSC)          # la lanza


def s_caravanas():
    M, P, V = en("caravanas")
    casa("muro_oeste_n", muro_arrabal, {}, frente="e", base=0.0, flores=False)
    casa("muro_oeste_s", muro_arrabal, {}, frente="e", base=0.0, flores=False)
    with marco((-50.0, 0.0, 2.2), 90.0) as Fm:
        puerta_caravanas(Fm(M), Fm(P), Fm(V), 6.4, 3.5)
    casa("establo", establo, {}, base=0.0, flores=False)
    # el abrevadero de piedra junto al muro (con agua), el carro, el pozo bajo, el heno y la valla del sur
    r = BLOQUE["abrevadero"][2]
    caja_mm(M, (r[0], -0.1, r[1]), (r[0] + r[2], 0.68, r[1] + r[3]), "sillar", jit(SILLAR, 0.05), jit_v=0.01)
    caja_mm(M, (r[0] + 0.1, 0.5, r[1] + 0.1), (r[0] + r[2] - 0.1, 0.6, r[1] + r[3] - 0.1), "hierro", AGUA, caras="a")
    carro_caravana(P, V)
    r = BLOQUE["pozo"][2]
    px, pz = r[0] + r[2] / 2, r[1] + r[3] / 2
    cilindro(M, (px, -0.1, pz), [(0, 0.68), (0.78, 0.64), (0.84, 0.7), (0.9, 0.7)], 14, "sillar", jit(SILLAR, 0.05),
             suave=False)
    cilindro(M, (px, 0.8, pz), [(0, 0.52), (0.02, 0.52)], 14, "hierro", (0.06, 0.06, 0.07), tapa_arriba=True)
    for s in (-1, 1):
        viga(M, (px + s * 0.62, 0.8, pz), (px + s * 0.62, 1.55, pz), 0.1, "madera", MADERA_OSC)
    viga(M, (px - 0.7, 1.45, pz), (px + 0.7, 1.45, pz), 0.08, "madera", MADERA)
    viga(M, (px + 0.7, 1.45, pz), (px + 0.85, 1.25, pz), 0.04, "hierro", HIERRO)
    cilindro(P, (px + 0.35, 0.9, pz + 0.45), [(0, 0.11), (0.25, 0.13)], 9, "madera", jit(MADERA, 0.05), tapa_arriba=False)
    r = BLOQUE["heno"][2]
    for k in range(5):
        fardo(P, (r[0] + 0.5 + (k % 3) * 1.0, 0.24 + (k // 3) * 0.48, r[1] + 0.6), (0.9, 0.46, 0.55), U(-6, 6))
    valla_varas(P, -50.0, -32.0, 5.95, 0.0, 1.0)
    farol_pie(M, P, -34.6, 5.0, 0.0)
    if DECORADO:
        for (x, z) in ((-48.3, 1.4), (-42.6, -6.9)):
            if pieza_con_choque((x, 0.5, z), (0.8, 1.0, 0.8)):
                barril(P, (x, 0.0, z), 0.3, 0.84)
                cajita(P, (x + 0.65, 0.0, z + 0.1), (0.6, 0.48, 0.55), yaw=U(-10, 10))
        for k in range(24):                                # paja suelta por el patio (briznas tumbadas, claras)
            x, z = U(-49.5, -33.0), U(-7.6, 3.6)
            for j in range(K.RND.randint(3, 6)):
                a = U(0, math.tau)
                c = Vector((x + U(-0.15, 0.15), 0.0, z + U(-0.15, 0.15)))
                d = Vector((math.cos(a), U(0.0, 0.06), math.sin(a))) * U(0.12, 0.22)
                e = Vector((-math.sin(a), 0, math.cos(a))) * 0.012
                col = lin(jit(PAJA, 0.06), 0.2)
                V.cara([c - e, c + e, c + d + e, c + d - e], "hoja", [col] * 4)
        z = -13.8
        while z < 5.6:                                     # al pie del muro
            if AZ() < 0.6 and not (-2.8 < z < 0.8):
                mata(V, (-49.85 + U(0, 0.2), 0.0, z), U(0.14, 0.26), K.RND.randint(10, 18), U(0.25, 0.45))
            z += U(0.3, 0.8)
        pie_fachada(V, -50.0, -44.0, -8.0, salvo=((-49.6, -47.2), (-46.7, -44.4)))
        matorrales(V, -51.0, -31.0, 6.4, 7.8, 0.0)
        arbol(M, V, -58.0, -9.0, 1.05, 0.0)                # al otro lado del muro, asoma por encima
    juntas_con_hierba("caravanas", 0.9)


# ================================================================ T4: el patio de talleres en rampa (el carretero)

def taller(m, p, v, W, F, e=None):
    """El taller de Damián, el carretero: nave baja de tablas sobre un zócalo de piedra que baja hasta la rampa, con el
    PORTÓN doble abierto al patio, una ventana, su letrero de la rueda y aperos colgados."""
    nave(m, p, v, W, F, 2.95, dict(vanos=3, alto_tejado=1.5, zocalo=0.45, abajo=-1.2, tabla=(0.64, 0.56, 0.46), musgo=0.4))
    porton(m, 7.5, 1.8, 2.55, abierto=True, color=MADERA)
    ventana(m, 2.6, 1.15, 0.0, 0.7, 0.8, OCRE_POSTIGO)
    letrero_con(m, (5.9, 2.35, 0.05), (0, 0, 1), "rueda")
    for k, uu in enumerate((4.2, 4.65)):                   # aperos colgados: una sierra y un mazo
        viga(m, (uu, 2.1, 0.08), (uu, 1.4, 0.1), 0.04 if k else 0.02, "madera" if k else "hierro", MADERA_OSC if k else HIERRO)
    caja(m, (4.2, 1.75, 0.1), (0.04, 0.6, 0.2), "hierro", (0.62, 0.62, 0.66))
    caja(m, (4.65, 1.42, 0.1), (0.16, 0.12, 0.12), "madera", MADERA_OSC)


def toneleria(m, p, v, W, F, e=None):
    """La tonelería (decorado): nave larga sobre un zócalo alto (el patio sube), un portón abierto con duelas dentro, otro
    cerrado, ventanas, el letrero del tonel y aros apoyados."""
    nave(m, p, v, W, F, 4.6, dict(vanos=5, alto_tejado=1.6, zocalo=1.2, tabla=(0.62, 0.55, 0.45), musgo=0.45))
    porton(m, 6.0, 1.9, 2.4, abierto=True, color=MADERA, y=1.0)
    porton(m, 13.2, 1.7, 2.2, abierto=False, color=MADERA_GRIS, y=0.85)
    for uu in (2.6, 9.6, 16.4):
        ventana(m, uu, 2.5, 0.0, 0.7, 0.8, AZUL_POSTIGO, luz=uu == 9.6)
    letrero_con(m, (8.2, 3.3, 0.05), (0, 0, 1), "tonel")
    farol_pared(m, (11.0, 3.2, 0.05), (0.0, 0, 1.0))
    for k in range(3):                                     # aros de hierro apoyados contra el zócalo
        cilindro(m, (3.6 + k * 0.25, 1.0 + 0.36, 0.12 + k * 0.04), [(0, 0.36), (0.03, 0.36)], 14, "hierro", HIERRO,
                 rot=R(0, 80), tapa_arriba=False)


def s_talleres():
    M, P, V = en("talleres")
    casa("taller", taller, {}, frente="e", base=1.4, flores=False)
    casa("toneleria", toneleria, {}, frente="o", base=0.4, flores=False)
    casa("casa_patio_n", casa_hastial, dict(rev=REVOQUE_D, post=OCRE_POSTIGO, pb=2.8, balcon=5.0,
                                            ventanas_p1=[(1.6, 0.6), (8.4, 0.6, True)],
                                            ventanas_pb=[(1.6, 0.6, 0.95, 1.0), (8.4, 0.6, 0.95, 1.0)], chimenea=(2.2, -5.0)),
         base=1.4, extra=lambda m, p, v, W, F: (puerta_calle(m, p, 5.0, 1.1, 2.2, "arco", (0.36, 0.30, 0.22)),
                                                farol_pared(m, (9.7, 2.5, 0.05), (0.5, 0, 0.86))))
    casa("casa_tonel_n", casa_alero, dict(rev=REVOQUE_C, post=AZUL_POSTIGO, pb=3.0, p1=2.6,
                                          ventanas_pb=[(1.4, 0.7)], ventanas_p1=[(1.4, 0.7), (4.4, 0.7)]),
         base=1.4, extra=lambda m, p, v, W, F: puerta_calle(m, p, 4.3, 1.0, 2.15, "dintel", AZUL_POSTIGO))
    # las ruedas apoyadas en el taller (el bloque «ruedas»), la pila de cajas de Tobías y las cintas de piedra de la rampa
    for k, z in enumerate((-14.15, -14.7, -15.25)):
        y = altura(-4.6, z)
        rueda(P, (-4.72 + k * 0.04, y + 0.52, z), 0.52, 90.0, radios=12, ladeo=12.0)
    r = BLOQUE["pila_patio"][2]
    for k in range(5):
        cajita(P, (r[0] + 0.45 + (k % 2) * 0.75, 1.4 + (k // 2) * 0.5, r[1] + 0.8 + U(-0.1, 0.1)), (0.68, 0.48, 0.66),
               yaw=U(-8, 8))
    # el potro con una rueda a medio hacer, la muela de afilar, un caballete con tablones y madera apilada
    if pieza_con_choque((-3.4, 1.9, -22.6), (1.2, 1.0, 0.7)):
        for s in (-1, 1):
            viga(P, (-3.9, 1.4, -22.6 + s * 0.3), (-3.6, 2.15, -22.6), 0.07, "madera", MADERA_OSC)
            viga(P, (-2.9, 1.4, -22.6 + s * 0.3), (-3.2, 2.15, -22.6), 0.07, "madera", MADERA_OSC)
        rueda(P, (-3.4, 2.2, -22.6), 0.55, 0.0, radios=6)
        for k in range(5):
            viga(P, (-2.6 + k * 0.08, 1.4, -23.3), (-2.45 + k * 0.08, 2.0, -23.45), 0.03, "madera", MADERA)
    if pieza_con_choque((3.7, 1.9, -19.4), (0.8, 1.0, 0.6)):
        cilindro(P, (3.5, 1.95, -19.4), [(0, 0.4), (0.12, 0.4)], 14, "sillar", (0.70, 0.66, 0.60), rot=R(0, 0, 90))
        for s in (-1, 1):
            viga(P, (3.7, 1.4, -19.4 + s * 0.28), (3.7, 1.95, -19.4 + s * 0.2), 0.06, "madera", MADERA_OSC)
    if pieza_con_choque((3.9, 1.9, -27.0), (1.2, 1.0, 1.6)):
        for k in range(6):
            viga(P, (3.4 + (k % 3) * 0.18, 1.48 + (k // 3) * 0.16, -27.8), (3.4 + (k % 3) * 0.18, 1.48 + (k // 3) * 0.16, -26.2),
                 0.15, "madera", jit((0.80, 0.70, 0.52), 0.06), alto=0.14)
    if DECORADO:
        for (x, z) in ((4.3, -14.2), (4.3, -15.3)):
            if pieza_con_choque((x, altura(x, z) + 0.5, z), (0.7, 1.0, 0.7)):
                barril(P, (x, altura(x, z), z), 0.3, 0.84)
        barril(P, (4.35, altura(4.3, -14.75) + 0.88, -14.75), 0.28, 0.6, tumbado=True, yaw=90)
        z = -29.5
        while z < -8.5:                                   # al pie de la tonelería y del taller
            if AZ() < 0.5:
                mata(V, (4.8, altura(4.7, z), z), U(0.12, 0.22), K.RND.randint(8, 14), U(0.2, 0.4))
            if AZ() < 0.4 and z > -22.0:
                mata(V, (-4.82, altura(-4.7, z), z), U(0.12, 0.22), K.RND.randint(8, 14), U(0.2, 0.4))
            z += U(0.4, 0.9)
        pie_fachada(V, -5.0, 11.0, -30.0, salvo=((4.0, 6.0), (8.6, 9.8)))
        hiedra(V, -4.6, -30.0, 4.5, y0=1.4)
    juntas_con_hierba("talleres", 0.9)


# ================================================================ T5: la calle de las casas (tendederos y huertos)

def tendedero(M, P, x0, x1, z, y):
    """Una cuerda de tender a lo largo de una fachada (de x0 a x1, en z, a la altura y, POR ENCIMA de Kael), con sus
    escuadras de hierro y la ropa colgada."""
    for x in (x0, x1):
        viga(M, (x, y, z - 0.75), (x, y, z), 0.03, "hierro", HIERRO)
        viga(M, (x, y - 0.4, z - 0.75), (x, y, z - 0.1), 0.025, "hierro", HIERRO)
    pts = []
    for k in range(13):
        t = k / 12
        pts.append(Vector((x0 + (x1 - x0) * t, y - 0.18 * math.sin(math.pi * t), z)))
    for k in range(12):
        viga(M, pts[k], pts[k + 1], 0.016, "tela", (0.82, 0.76, 0.62))
    t = 0.08
    while t < 0.9:
        ancho = U(0.35, 0.7)
        largo = U(0.4, 0.75)
        col = CH(TELAS)
        c = Vector((x0 + (x1 - x0) * t, y - 0.18 * math.sin(math.pi * t), z))
        pp = []
        for j in range(4):
            for q in range(3):
                pp.append(c + Vector(((q / 2 - 0.5) * ancho, -j / 3 * largo, 0.04 * math.sin(q * 2.1 + j * 1.3 + t * 9))))
        for j in range(3):
            for q in range(2):
                cc = [pp[j * 3 + q], pp[j * 3 + q + 1], pp[(j + 1) * 3 + q + 1], pp[(j + 1) * 3 + q]]
                P.cara(cc, "tela", jit(col, 0.03), suave=True)
                P.cara(list(reversed(cc)), "tela", jit(col, 0.03), suave=True)
        caja(P, c + Vector((0, 0.02, 0)), (0.04, 0.06, 0.03), "madera", MADERA)
        t += (ancho + U(0.15, 0.4)) / (x1 - x0)


def s_residencial():
    M, P, V = en("residencial")
    casa("casa_esquina_no", casa_alero, dict(rev=REVOQUE_C, post=ROJO_POSTIGO, pb=3.0, p1=2.6,
                                             ventanas_pb=[(1.6, 0.7)], ventanas_p1=[(1.5, 0.65), (4.5, 0.65)]), base=1.4)
    casa("casa_r1", casa_alero, dict(rev=REVOQUE_A, post=AZUL_POSTIGO, pb=3.0, p1=2.65, buhardilla=4.6,
                                     ventanas_pb=[(1.4, 0.8), (6.8, 0.8)],
                                     ventanas_p1=[(1.4, 0.72), (4.6, 0.72, True), (7.7, 0.72)], chimenea=(7.4, -5.6)),
         base=1.4, extra=lambda m, p, v, W, F: (puerta_calle(m, p, 3.6, 1.05, 2.25, "arco", AZUL_POSTIGO),
                                                farol_pared(m, (8.8, 2.4, 0.04), (0.55, 0, 0.84))))
    casa("casa_r2", casa_hastial, dict(rev=REVOQUE_B, post=ROJO_POSTIGO, pb=2.8, p1=2.45, balcon=4.5,
                                       ventanas_p1=[(1.5, 0.6), (7.5, 0.6, True)], ventanas_pb=[(1.6, 0.7, 0.95, 1.0)],
                                       chimenea=(1.5, -5.5)),
         base=1.4, extra=lambda m, p, v, W, F: puerta_calle(m, p, 7.0, 1.0, 2.15, "dintel", ROJO_POSTIGO))
    def vivienda(m, p, v, W, F):
        puerta_calle(m, p, 4.0, 1.1, 2.3, "arco", VERDE_PUERTA)
        if DECORADO and pieza_local(p, 6.2, 0.0, 0.32, (1.3, 0.5, 0.45)):
            caja_mm(p, (5.6, 0.0, 0.12), (5.67, 0.42, 0.5), "madera", MADERA)
            caja_mm(p, (6.75, 0.0, 0.12), (6.82, 0.42, 0.5), "madera", MADERA)
            caja_mm(p, (5.5, 0.42, 0.08), (6.92, 0.5, 0.55), "madera", jit(MADERA_GRIS, 0.04), veta="larga")
        hojas(v, (1.0, 1.4, 0.15), 0.45, 45, HOJA, 0.09, flex=0.3, aplastar=1.7, hacia=(0, 0, 1))          # un rosal
        for k in range(10):
            c = Vector((1.0 + U(-0.35, 0.35), U(0.7, 2.0), 0.22))
            pts = [c + Vector((math.cos(j * math.tau / 5) * 0.05, math.sin(j * math.tau / 5) * 0.05, 0)) for j in range(5)]
            v.cara(pts, "hoja", [lin(jit(FLORES[4], 0.05), 0.3)] * 5)
        for uu in (3.0, 5.0):
            maceta(p, v, (uu, 0.0, 0.3), 0.18, 0.26)
    casa("vivienda", casa_alero, dict(rev=REVOQUE_A, post=VERDE_POSTIGO, pb=3.0, p1=2.65,
                                      ventanas_pb=[(1.8, 0.8), (6.3, 0.8)],
                                      ventanas_p1=[(1.6, 0.72), (4.0, 0.72, True), (6.4, 0.72)], chimenea=(6.4, -5.0)),
         base=1.4, extra=vivienda)
    casa("casa_r4", casa_alero, dict(rev=REVOQUE_E, post=OCRE_POSTIGO, pb=3.0, p1=2.65, buhardilla=6.5,
                                     ventanas_pb=[(1.3, 0.75), (6.2, 0.75), (11.6, 0.75)],
                                     ventanas_p1=[(1.5, 0.72), (4.6, 0.72), (8.2, 0.72, True), (11.4, 0.72)],
                                     chimenea=(2.6, -5.6)),
         base=1.4, extra=lambda m, p, v, W, F: (puerta_calle(m, p, 3.4, 1.0, 2.15, "dintel", OCRE_POSTIGO),
                                                puerta_calle(m, p, 9.6, 1.1, 2.3, "arco", MADERA),
                                                farol_pared(m, (0.2, 2.4, 0.04), (-0.55, 0, 0.84))))
    tendedero(M, P, -34.2, -27.4, -29.62, 3.85)          # (bajo el vuelo: el balcón y las ventanas, libres)
    tendedero(M, P, -16.4, -10.2, -29.62, 3.95)
    pie_fachada(V, -50.0, -5.0, -30.0, salvo=((-41.0, -39.8), (-28.6, -27.4), (-22.8, -21.2), (-15.2, -14.0), (-8.2, -6.8)))
    # el muro del arrabal al norte (asoma entre las casas)
    with marco((-54.0, 0.0, -42.5), 0.0) as Fm:
        muro_arrabal(Fm(M), Fm(P), Fm(V), 67.0, 1.5, dict(alto=4.0))
    # la canaleta de la calle
    x = -44.0
    while x < -5.0:
        caja_mm(P, (x, 1.32, -28.12), (x + U(0.5, 0.8), 1.38, -27.88), "sillar", jit(SILLAR, 0.06), jit_v=0.006)
        x += U(0.55, 0.85)
    # los huertos (lado sur, BAJOS): bancales con coles, tutores de judías (≤ 1,5 m), flores; la cerca de varas; al fondo,
    # una caseta de aperos y dos frutales (a más de 4 m de la calle)
    valla_varas(P, -40.0, -13.5, -25.6, 1.4, 0.9)
    for k, x0 in enumerate((-39.0, -35.6, -32.2, -28.8, -25.4, -22.0, -18.6)):
        caja_mm(M, (x0, 1.32, -24.8), (x0 + 2.4, 1.48, -21.8), "tierra", (0.46, 0.36, 0.28), caras="asneo")
        if k % 3 == 1:                                     # judías en tutores
            for j in range(4):
                xx = x0 + 0.4 + j * 0.55
                for zz in (-24.4, -22.2):
                    viga(P, (xx, 1.45, zz), (xx + 0.1, 2.85, -23.3), 0.03, "madera", MADERA_GRIS)
                hojas(V, (xx + 0.05, 2.2, -23.3), 0.28, 26, HOJA, 0.08, flex=0.3, aplastar=1.8)
        elif DECORADO:
            for zz in (-24.3, -23.5, -22.7):
                for xx in (x0 + 0.45, x0 + 1.2, x0 + 1.95):
                    if AZ() < 0.85:
                        hojas(V, (xx + U(-0.08, 0.08), 1.62, zz), 0.2, 16, ((0.42, 0.62, 0.36), (0.50, 0.70, 0.40),
                                                                           (0.36, 0.54, 0.32)), 0.11, flex=0.15, aplastar=0.6)
        if DECORADO and k % 2 == 0:
            mata_flores(V, (x0 + 1.2, 1.48, -21.4), 0.4, FLORES[k % len(FLORES)], 12, 0.4)
    caja_mm(M, (-31.0, 1.3, -20.4), (-28.6, 3.4, -18.6), "madera", jit(MADERA_GRIS, 0.04), veta="larga")
    faldon(M, (-31.3, 3.35, -18.3), (-28.3, 3.35, -18.3), (0, 0.5, -2.4), TEJA, musgo=0.6)
    if DECORADO:
        arbol(M, V, -36.5, -19.6, 0.72, 1.4)
        arbol(M, V, -15.5, -20.2, 0.78, 1.4)
        for x in (-12.8, -11.0, -9.2, -7.4, -5.8):          # el seto bajo del extremo este
            hojas(V, (x, 1.9, -25.4), 0.6, 60, HOJA, 0.12, flex=0.3, aplastar=0.7)
        matorrales(V, -40.0, -6.0, -21.0, -18.5, 1.4, 0.4)
        M2, P2, V2 = en(FONDO)
        for (x, z) in ((-75.0, -70.0), (-40.0, -78.0), (2.0, -66.0), (-14.0, -95.0), (-70.0, 10.0)):  # árboles lejanos
            arbol_lejano(P2, V2, x, z, 1.1, 1.4)
        en("residencial")
    juntas_con_hierba("residencial", 0.7)


# ================================================================ T6: el atajo (escalones, arco y hornacina)

def hornacina(m, p, v):
    """La hornacina de la esquina de la muestra, en la pared del callejón: arco, velas encendidas, una figurilla de piedra
    y flores."""
    hx, hz = 0.0, 0.0
    caja_mm(m, (hx - 0.32, 2.08, hz), (hx + 0.32, 2.82, hz + 0.01), "hierro", (0.12, 0.10, 0.10))
    caja_mm(m, (hx - 0.42, 2.0, hz), (hx + 0.42, 2.09, hz + 0.24), "sillar", SILLAR)
    placa(m, [(-0.42, 0), (0.42, 0), (0.42, 0.78), (0.0, 1.0), (-0.42, 0.78)], (hx, 2.0, hz), (1, 0, 0), (0, 1, 0), 0.12,
          "sillar", jit(SILLAR, 0.04), frente=False)
    placa(m, [(-0.32, 0.08), (0.32, 0.08), (0.32, 0.8), (0.0, 0.92), (-0.32, 0.8)], (hx, 2.0, hz), (1, 0, 0), (0, 1, 0),
          0.004, "hierro", (0.10, 0.09, 0.09), lados=False)
    for k, dx in enumerate((-0.17, 0.02, 0.18)):
        h = (0.18, 0.26, 0.14)[k]
        cilindro(m, (hx + dx, 2.09, hz + 0.12), [(0, 0.025), (h, 0.025)], 6, "tela", (0.96, 0.92, 0.80))
        caja(m, (hx + dx, 2.09 + h + 0.03, hz + 0.12), (0.025, 0.05, 0.025), "brillo", LUZ_FAROL)
    caja(m, (hx, 2.46, hz + 0.06), (0.1, 0.26, 0.08), "sillar", (0.92, 0.90, 0.84))
    ancla_p("hornacina", (hx, 2.4, hz + 0.18))
    if DECORADO:
        mata_flores(v, (hx - 0.3, 2.09, hz + 0.14), 0.1, FLORES[1], 5, 0.16)


def s_atajo():
    M, P, V = en("atajo")
    casa("casa_atajo_o", casa_alero, dict(rev=REVOQUE_C, post=VERDE_POSTIGO, pb=3.0, p1=2.6,
                                          ventanas_pb=[(5.6, 0.7, 1.75, 1.0), (10.2, 0.7, 1.9, 1.0)],
                                          ventanas_p1=[(1.6, 0.72), (5.0, 0.72), (8.6, 0.72, True), (12.4, 0.72)],
                                          lados={"o": [(-1.6, 1.1), (-4.4, 3.8)]}, chimenea=(11.0, -4.5)),
         frente="e", base=0.7,
         extra=lambda m, p, v, W, F: (puerta_calle(m, p, 2.8, 1.0, 2.15, "arco", VERDE_PUERTA),
                                      hiedra(v, 0.6, 0.0, 3.2, y0=0.0)))
    casa("casa_atajo_e", casa_hastial, dict(rev=REVOQUE_E, post=AZUL_POSTIGO, pb=2.8, balcon=None,
                                            ventanas_p1=[(1.6, 0.6), (6.4, 0.6, True)],
                                            ventanas_pb=[(5.6, 0.7, 0.95, 1.05)],
                                            lados={"o": [(-3.0, 1.4), (-8.6, 3.5), (-3.2, 3.6)]}, chimenea=(6.0, -6.0)),
         base=0.0, extra=lambda m, p, v, W, F: puerta_calle(m, p, 2.2, 1.0, 2.15, "dintel", AZUL_POSTIGO))
    # los dos tramos de escalones (de piedra; el suelo que se pisa es la rampa continua del trazado)
    for (z0, y0, y1) in ((-22.0, 1.4, 0.7), (-13.0, 0.7, 0.0)):
        for k in range(4):
            top = y0 - (y0 - y1) * (k + 0.5) / 4
            caja_mm(M, (-44.0 + U(0, 0.04), top - 0.45, z0 + k * 0.75), (-40.0 - U(0, 0.04), top, z0 + (k + 1) * 0.75 + 0.02),
                    "sillar", jit(SILLAR, 0.06), jit_v=0.012)
    # el arco de paso (rebajado, sin techo) entre las dos casas
    with marco((-42.0, 0.0, -16.4), 0.0) as Fm:
        m = Fm(M)
        arco_rebajado(m, 0.0, 2.96, 2.6, 2.0, 0.0, oscuro=False)
        pts = [(-2.0, 1.25), (2.0, 1.25)]
        for k in range(9):                                 # el muro de encima del arco, con su curva por debajo
            a = math.acos(2.0 / 2.6) + (math.pi - 2 * math.acos(2.0 / 2.6)) * k / 8
            pts.append((math.cos(a) * 2.94, 2.96 - 2.6 * math.sin(math.acos(2.0 / 2.6)) + math.sin(a) * 2.94 - 2.96 + 0.2))
        placa(m, [(-2.0, 1.0 + 0.6), (2.0, 1.0 + 0.6), (2.0, 0.7), (0.0, 0.94), (-2.0, 0.7)], (0.0, 2.96, -0.3), (1, 0, 0),
              (0, 1, 0), 0.6, "sillar", jit(SILLAR, 0.04))
        caja_mm(m, (-2.1, 4.52, -0.95), (2.1, 4.66, 0.05), "sillar", jit(SILLAR, 0.05))
    with marco((-40.0, 0.4, -14.2), -90.0) as Fm:
        hornacina(Fm(M), Fm(P), Fm(V))
    farol_pared(M, (-40.02, 3.3, -11.6), (-0.84, 0, 0.3))
    with marco((-39.8, 0.0, -22.0), 90.0) as Fm:
        valla_varas(Fm(P), 0.0, 4.0, 0.0, 1.4, 0.9)
    if DECORADO:
        for (z, y, s) in ((-21.6, 1.31, -1), (-20.8, 1.14, 1), (-12.6, 0.61, 1), (-11.1, 0.35, -1)):
            maceta(P, V, (-42.0 + s * 1.65, y, z), 0.15, 0.22)
        for k in range(4):
            for (z0, y0, y1) in ((-22.0, 1.4, 0.7), (-13.0, 0.7, 0.0)):
                top = y0 - (y0 - y1) * (k + 0.5) / 4
                for s in (-1, 1):
                    if AZ() < 0.7:
                        mata(V, (-42.0 + s * 1.85, top, z0 + k * 0.75 + 0.6), 0.1, K.RND.randint(5, 9), U(0.15, 0.28))
        hojas(V, (-42.0, 4.6, -16.6), 0.9, 70, HOJA, 0.11, flex=0.4, aplastar=0.5)          # hiedra sobre el arco
        hiedra(V, -39.95, -16.0, 3.4, eje="x", hacia=(-1, 0, 0), y0=0.7)
        z = -29.5
        while z < -8.3:
            for xx in (-43.85, -40.15):
                if AZ() < 0.35:
                    mata(V, (xx, altura(-42.0, z), z), U(0.1, 0.2), K.RND.randint(6, 12), U(0.18, 0.35))
            z += U(0.4, 1.0)
        matorrales(V, -39.5, -36.0, -25.5, -22.5, 1.4, 0.5)
    juntas_con_hierba("atajo", 0.9)


CONSTRUCTOR = {"comercial": s_comercial, "plaza": s_plaza, "caravanas": s_caravanas, "talleres": s_talleres,
               "residencial": s_residencial, "atajo": s_atajo}


# ================================================================ cámaras posibles (para el recorte)

def _foco_zona(z, kx, kz):
    if z["modo"] == "x":
        return (min(max(kx, z["x"][0]), z["x"][1]), z["z_riel"] + min(0.0, kz - z["z_riel"]) * 0.55)
    if z["modo"] == "eje":                                  # (16/11) «atraso»: el foco, tantos metros al sur de Kael
        return (z["eje"], min(max(kz + z.get("atraso", 0.0), z["z"][0]), z["z"][1]))
    return (min(max(kx, z["x"][0]), z["x"][1]), min(max(kz, z["z"][0]), z["z"][1]))


def _peso(z, x, zz):
    r = z["rect"]
    d = min(x - r[0], r[0] + r[2] - x, zz - r[1], r[1] + r[3] - zz)
    if d <= 0.0:
        return 0.0
    t = min(1.0, d / CAM["margen"])
    return t * t * (3 - 2 * t)


def foco_camara(kx, ky, kz):
    """La de trazado.gd (foco_camara): la media pesada de lo que dice cada zona; en altura, k.y·0,6."""
    suma, ax, az = 0.0, 0.0, 0.0
    for z in ZONAS:
        w = _peso(z, kx, kz)
        if w > 0:
            f = _foco_zona(z, kx, kz)
            ax += f[0] * w
            az += f[1] * w
            suma += w
    if suma <= 0:
        z = max(ZONAS, key=lambda q: min(kx - q["rect"][0], q["rect"][0] + q["rect"][2] - kx, kz - q["rect"][1],
                                          q["rect"][1] + q["rect"][3] - kz))
        f = _foco_zona(z, kx, kz)
        return (f[0], ky * 0.6, f[1])
    return (ax / suma, ky * 0.6, az / suma)


def tierra_del_suelo(cara):
    """(16/11) La tierra bajo lo que se pisa (con 0,6 m de margen) se queda siempre a la vista: las losas la tapan casi
    toda, pero por sus juntas se ve (sin ella, el fondo: los «trazos blancos»)."""
    if cara[1] != "tierra":
        return False
    pts = cara[0]
    cx = sum(p.x for p in pts) / len(pts)
    cz = sum(p.z for p in pts) / len(pts)
    for s in SUELOS:
        r = s[1]
        if r[0] - 0.6 <= cx <= r[0] + r[2] + 0.6 and r[1] - 0.6 <= cz <= r[1] + r[3] + 0.6:
            return True
    return False


def camaras():
    """Todas las cámaras posibles: Kael en cada metro de lo andable → su foco → la cámara (foco + offset, 25°, 38°),
    sin repetir las que caen a menos de ~1 m. Devuelve [(pos, adelante, arriba, derecha, sector de Kael)]."""
    off = Vector(CAM["offset"])
    a = math.radians(CAM["inclinacion"])
    ad = Vector((0.0, -math.sin(a), -math.cos(a)))
    der = ad.cross(Vector((0, 1, 0))).normalized()
    arr = der.cross(ad).normalized()
    vistas = {}
    for s in SUELOS:
        r = s[1]
        x = r[0] + 0.25
        while x < r[0] + r[2]:
            z = r[1] + 0.25
            while z < r[1] + r[3]:
                if andable(x, z):
                    f = foco_camara(x, altura(x, z), z)
                    clave = (round(f[0] / 1.2), round(f[2] / 1.2), round(f[1] / 0.5))
                    if clave not in vistas:
                        vistas[clave] = (Vector(f) + off, s[0])
                z += 1.0
            x += 1.0
    return [(p, ad, arr, der, sec) for p, sec in vistas.values()]


# ================================================================ main

def escribir_import(ruta, tipo):
    """El .import de Godot para lo nuevo, con los ajustes de la muestra (sin LOD, tangentes ni mallas de sombra; mapas
    de luz VRAM con mipmaps; sondas como Image). Si ya existe, no se toca (Godot lo completa al importar)."""
    if os.path.exists(ruta + ".import"):
        return
    if tipo == "glb":
        t = ('[remap]\n\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[params]\n\nnodes/root_type=""\n'
             'nodes/root_name=""\nnodes/apply_root_scale=true\nnodes/root_scale=1.0\nmeshes/ensure_tangents=false\n'
             'meshes/generate_lods=false\nmeshes/create_shadow_meshes=false\nmeshes/light_baking=1\n'
             'meshes/lightmap_texel_size=0.2\nmeshes/force_disable_compression=false\nanimation/import=false\n'
             'materials/extract=0\n_subresources={}\ngltf/naming_version=2\ngltf/embedded_image_handling=1\n')
    elif tipo == "luz":
        t = ('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\ncompress/mode=2\n'
             'compress/high_quality=false\ncompress/lossy_quality=0.7\ncompress/hdr_compression=1\ncompress/normal_map=0\n'
             'compress/channel_pack=0\nmipmaps/generate=true\nmipmaps/limit=-1\nprocess/fix_alpha_border=true\n'
             'process/size_limit=0\ndetect_3d/compress_to=1\n')
    else:
        t = '[remap]\n\nimporter="image"\ntype="Image"\n\n[params]\n\n'
    with open(ruta + ".import", "w", encoding="utf-8") as f:
        f.write(t)


def cobertura(bvh, inicio, cams, nx=64, nz=36):
    """Qué parte de la pantalla ocupa cada sector desde cada cámara posible: una rejilla de nx × nz rayos (16:9, 38° de
    campo) contra el BVH de todo lo fijo y las piezas. Devuelve {sector: [fracción por cámara]}: la visibilidad por
    sector de barrio.gd (con lo que ocupa menos de un umbral, el sector no se dibuja). Lo fijo y las piezas, aparte
    («<sector>» y «<sector>/piezas»): de un vecino a menudo solo asoman sus tejados."""
    tf = math.tan(math.radians(CAM["campo"]) * 0.5)
    asp = 16.0 / 9.0
    lim = []
    for k in range(len(ORDEN)):
        lim += [(inicio[2 * k], ORDEN[k]), (inicio[2 * k + 1], ORDEN[k] + "/piezas")]
    claves = [b for _a, b in lim]
    out = {q: [] for q in claves}
    for (cp, ad, arr, der, _z) in cams:
        n = {q: 0 for q in claves}
        for j in range(nz):
            v = (1.0 - 2.0 * (j + 0.5) / nz) * tf
            for i in range(nx):
                u = (2.0 * (i + 0.5) / nx - 1.0) * tf * asp
                d = (ad + arr * v + der * u).normalized()
                hit = bvh.ray_cast(cp, d, 300.0)
                if hit[0] is None:
                    continue
                q = claves[0]
                for b, nom in lim:
                    if hit[2] >= b:
                        q = nom
                n[q] += 1
        for q in claves:
            out[q].append(round(n[q] / float(nx * nz), 4))
    return out


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    carpeta_mod = os.path.join(CARPETA, "modelos")
    carpeta_tex = os.path.normpath(os.path.join(CARPETA, "..", "muestra_calle", "texturas"))
    exportar = [s for s in ORDEN if SOLO is None or s in SOLO]
    con_fondo = SOLO is None or FONDO in SOLO
    terreno()
    nota("terreno")
    empedrado()
    losas_plaza()
    nota("empedrado")
    choques_del_trazado()
    for s in ORDEN:
        CONSTRUCTOR[s]()
        nota("construido %s" % s)
    for s in ORDEN + [FONDO]:
        M, P, V = MALLAS[s]
        SECT[s].choques[:] = [c for c in SECT[s].choques if c[3]]          # solo los choques con nombre
        nota("%-12s %6d tri fijos · %6d de piezas · %6d de vegetación · %d choques · %d anclas" % (
            s, M.tris(), P.tris(), V.tris(), len(SECT[s].choques), len(SECT[s].anclas)))
    imgs = K.cargar_texturas(carpeta_tex)
    # --- recorte de lo que ninguna cámara ve (en los sectores que se exportan) y cobertura de cada sector por cámara
    vis = {s: MALLAS[s] for s in ORDEN + [FONDO]}
    ocultas = {s: Malla() for s in ORDEN + [FONDO]}
    ocultas_veg = {s: Malla() for s in ORDEN + [FONDO]}
    cams = camaras()
    nota("%d cámaras posibles" % len(cams))
    todas = []
    for s in ORDEN:
        todas += [MALLAS[s][0], MALLAS[s][1]]
    bvh, inicio = K.bvh_de(todas)
    cob = cobertura(bvh, inicio, cams)
    nota("cobertura de pantalla por sector y cámara medida")
    if RECORTE:
        c4 = [c[:4] for c in cams]
        for k, s in enumerate(ORDEN):
            if s not in exportar:
                continue
            M, P, V = MALLAS[s]
            mv, mo, _v1 = K.recortar(M, bvh, inicio[2 * k], c4, conservar=tierra_del_suelo)
            pv, po, _v2 = K.recortar(P, bvh, inicio[2 * k + 1], c4)
            # (16/11) la vegetación también: las matas, hojas e hiedra que ninguna cámara ve (tras las casas, en los
            # patios de atrás) no se exportan; no tapan nada en el bvh (no están en él) y su luz no cambia (se hornea igual)
            vv, vo, _v3 = K.recortar(V, bvh, None, c4)
            mo.caras += po.caras
            vis[s] = (mv, pv, vv)
            ocultas[s] = mo
            ocultas_veg[s] = vo
            nota("recorte %s: %d + %d + %d (vegetación) triángulos a la vista, %d que ninguna cámara ve (y %d de vegetación)" % (
                s, mv.tris(), pv.tris(), vv.tris(), mo.tris(), vo.tris()))
    # --- a Blender: un objeto fijo, uno de piezas, uno de vegetación y uno oculto por sector (el fondo: piezas y vegetación)
    luz_img = {}
    if HORNEAR:
        for s in exportar:
            luz_img[s] = bpy.data.images.new("luz_" + s, RES, RES, alpha=False, float_buffer=True)
    mats = K.materiales(imgs, next(iter(luz_img.values())) if luz_img else None)
    obs = {}
    for s in ORDEN + [FONDO]:
        mv, pv, V = vis[s]
        for malla in (V, pv):
            if not malla.caras:
                malla.cara([Vector((0, -5, 0)), Vector((0.01, -5, 0)), Vector((0, -5, 0.01))], "hoja", (0.3, 0.5, 0.2))
        obs[s] = {"fijo": K.a_blender("fijo_" + s, mv, mats, HORNEAR and s in exportar) if mv.caras else None,
                  "piezas": K.a_blender("piezas_" + s, pv, mats, False),
                  "vegetacion": K.a_blender("vegetacion_" + s, V, mats, False),
                  "oculto": K.a_blender("oculto_" + s, ocultas[s], mats, False) if ocultas[s].caras else None,
                  "oculto_veg": K.a_blender("ocultoveg_" + s, ocultas_veg[s], mats, False) if ocultas_veg[s].caras else None}
    nota("objetos en Blender")
    salida = {"version": 1, "escala": ESCALA, "res": [RES, RES // 2], "sectores": {}}
    ruta_json = os.path.join(carpeta_mod, "barrio_luz.json")
    if os.path.exists(ruta_json):
        with open(ruta_json, encoding="utf-8") as f:
            salida = json.load(f)
        salida["escala"] = ESCALA
    if not HORNEAR:
        nota("sin horneado: no se exporta nada")
        return
    anclas_todas = {}
    for s in ORDEN:
        for k, p in SECT[s].anclas.items():
            anclas_todas["%s/%s" % (s, k)] = p
    K.preparar_cycles(anclas_todas)
    cal = K.calibrar()
    for s in exportar:                                      # 1) hornear (sin escalar: los rebotes con el color crudo)
        for m in mats.values():
            n = m.node_tree.nodes.get("LUZ")
            if n is not None:
                n.image = luz_img[s]
                m.node_tree.nodes.active = n
        K.hornear(obs[s]["fijo"], [obs[s]["piezas"], obs[s]["vegetacion"]], "luz_" + s)
        nota("horneado %s" % s)
    if con_fondo:                                           # el fondo: solo a los vértices
        bpy.ops.object.select_all(action='DESELECT')
        for ob in (obs[FONDO]["piezas"], obs[FONDO]["vegetacion"]):
            vm = ob.data
            vm.color_attributes.active_color = vm.color_attributes.new("LuzV", 'FLOAT_COLOR', 'CORNER')
            ob.select_set(True)
            bpy.context.view_layer.objects.active = ob
        bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, target='VERTEX_COLORS', use_clear=True)
        nota("horneado el fondo")
    # 2) sondas con todo lo que tapa (Blender), 3) escalar y guardar, 4) exportar
    dg = bpy.context.evaluated_depsgraph_get()
    vs, ps = [], []
    for s in ORDEN:
        for o in (obs[s]["fijo"], obs[s]["piezas"], obs[s]["oculto"]):
            if o is None:
                continue
            m = o.evaluated_get(dg).data
            b = len(vs)
            vs.extend([o.matrix_world @ v.co for v in m.vertices])
            ps.extend([[b + i for i in p.vertices] for p in m.polygons])
    bvh_b = K.BVHTree.FromPolygons(vs, ps)
    hs = K.hacia_sol()
    for s in exportar:
        propia = K.escala_y_guardar(luz_img[s], carpeta_mod, [obs[s]["piezas"], obs[s]["vegetacion"]], ESCALA,
                                    "barrio_" + s)
        r = SECTORES[s]
        rs = (r[0] - 1.0, r[1] - 1.0, r[2] + 2.0, r[3] + 2.0)
        so = K.sondas(bvh_b, hs, rs, altura)
        ruta_s = os.path.join(carpeta_mod, "barrio_%s_sondas.png" % s)
        K.png_gris(ruta_s, [so["sol"], so["cielo"]], so["nx"], so["nz"])
        escribir_import(ruta_s, "sondas")
        for res in (RES, RES // 2):
            escribir_import(os.path.join(carpeta_mod, "barrio_%s_luz_%d.png" % (s, res)), "luz")
        objs = [obs[s]["fijo"], obs[s]["piezas"], obs[s]["vegetacion"]] + K.vacios(SECT[s])
        ruta_g = os.path.join(carpeta_mod, "barrio_%s.glb" % s)
        K.exportar(objs, ruta_g)
        escribir_import(ruta_g, "glb")
        mv, pv, V = vis[s]
        salida["sectores"][s] = {
            "sondas": {"origen": [so["origen"][0], so["origen"][1]], "paso": so["paso"], "nx": so["nx"], "nz": so["nz"]},
            "tris_fijo": mv.tris(), "tris_piezas": pv.tris(), "tris_vegetacion": V.tris(), "tris_oculto": ocultas[s].tris(),
            "percentil_propio": propia, "choques": len(SECT[s].choques), "muestras": K.MUESTRAS, "res": RES,
            "horneado": time.strftime("%Y-%m-%d %H:%M")}
        nota("exportado %s (percentil propio %.3f; escala común %.3f)" % (s, propia, ESCALA))
    if con_fondo:
        K.escala_vertices([obs[FONDO]["piezas"], obs[FONDO]["vegetacion"]], ESCALA)
        ruta_g = os.path.join(carpeta_mod, "barrio_fondo.glb")
        K.exportar([obs[FONDO]["piezas"], obs[FONDO]["vegetacion"]], ruta_g)
        escribir_import(ruta_g, "glb")
        salida["fondo"] = {"tris_piezas": vis[FONDO][1].tris(), "tris_vegetacion": vis[FONDO][2].tris(),
                           "horneado": time.strftime("%Y-%m-%d %H:%M")}
    salida.update({"hacia_sol": [hs.x, hs.y, hs.z], "sol_color": list(K.SOL_COLOR),
                   "sol_color_medido": [max(0.0, a - b) for a, b in zip(cal["frente"], cal["espalda"])],
                   "cielo_color": cal["espalda"]})
    salida.pop("visibles", None)
    salida["camaras"] = [[round(c[0].x, 2), round(c[0].y, 2), round(c[0].z, 2)] for c in cams]
    salida["cobertura"] = cob
    with open(ruta_json, "w", encoding="utf-8") as f:
        json.dump(salida, f)
    nota("HECHO: %s%s" % (", ".join(exportar), " y el fondo" if con_fondo else ""))


main()
