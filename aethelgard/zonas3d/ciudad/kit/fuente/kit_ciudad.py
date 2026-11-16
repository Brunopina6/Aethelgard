# BIBLIOTECA MODULAR de la «ciudad completa de Oakhaven» (V12, 16/11; EN PRUEBAS, todo PROPUESTA [P]).
# Módulos de Blender por guion, a escala de los personajes (Kael ≈ 1,7 m; puertas ≥ 2,2 m; escalones de 0,165 m de alto y
# 0,32 m de huella), con el ACABADO APROBADO del barrio y de la muestra de la calle: la misma arquitectura de entramado,
# los mismos colores, las 8 texturas de zonas3d/muestra_calle/texturas (sin repintar), los mismos 11 materiales (que en
# Godot se cambian por los 4 sombreados de la muestra) y la misma luz de la tarde dorada (sol 252°/24°, cielo frío,
# escala de luz 2,229). NO toca zonas3d/barrio/ ni zonas3d/muestra_calle/: IMPORTA su kit (kit_barrio.py) y LEE de
# crear_barrio.py las funciones de arquitectura y atrezo (puerta_calle, casa_alero, casa_hastial, nave, toldo…) sin
# ejecutar su main (ast: solo esas definiciones). Ningún recurso descargado, de pago ni de la nube.
#
#   blender -b --factory-startup -P kit_ciudad.py -- <carpeta zonas3d/ciudad/kit> [opciones]
#     --laminas DIR      renders de cada módulo y la lámina de conjunto (por defecto, sin láminas)
#     --solo a,b         solo esos módulos
#     --sin-horneado     sin luz en los vértices (no exporta: para mirar números)
#     --muestras N       muestras de Cycles del horneado (por defecto 128)
#     --depurar          en las láminas, las caras de espaldas en magenta (en Godot no se dibujan: cull_back)
#     --tramo DIR        además, el TRAMO DE PRUEBA de una calle de las Terrazas montado solo con el kit, horneado como un
#                        sector del barrio (mapa de luz 2048 + vértices), con su render de la cámara de juego
#     --sin-modulos      no exporta los módulos (con --tramo: solo el tramo)
#
# Salidas en <carpeta>/modelos/: <módulo>.glb (objetos «<módulo>_fijo», «_piezas» y «_vegetacion», todos con la luz
# horneada EN LOS VÉRTICES —el módulo suelto se ve terminado con calle_vertice / calle_hoja / calle_brillo—, vacíos
# «choque_<módulo>_<n>» (caja: escala = medio tamaño) y «ancla_<módulo>_<n>»), y kit_ciudad.json (medidas, huella,
# triángulos, anclas y sector de cada módulo). Para el ACABADO de un sector se monta con la API (colocar) dentro del
# generador del sector y se hornea el sector entero con mapa de luz, como crear_barrio.py (ver --tramo).
#
# Convenciones (las de crear_barrio.py): coordenadas de Godot (x este, y arriba, z SUR); la cámara del juego mira al
# norte sin girar, así que las fachadas miran a +z. Pivote de cada tipo:
#   fachada / muro / arco / puerta: la esquina inferior OESTE del frente; ocupa x ∈ [0, W], z ∈ [−F, 0]; y = 0 el umbral.
#   escalera / rampa: el borde oeste del primer peldaño; sube hacia −z (norte) desde z = 0.
#   suelo: como las fachadas, x ∈ [0, 4], z ∈ [−4, 0].
#   atrezo, fuente, árboles: el centro de la base.
import sys, os, ast, json, math, random, time, zlib
sys.dont_write_bytecode = True              # (no dejar __pycache__ en zonas3d/barrio/fuente, que no es nuestra)
from contextlib import contextmanager

AQUI = os.path.dirname(os.path.abspath(__file__))
FUENTE_BARRIO = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "barrio", "fuente"))
TEXTURAS = os.path.normpath(os.path.join(AQUI, "..", "..", "..", "muestra_calle", "texturas"))
sys.path.insert(0, FUENTE_BARRIO)
import kit_barrio as K
from kit_barrio import (Vector, Matrix, Malla, MallaMarco, R, caja, caja_mm, placa, cilindro, cono, viga, voronoi, losa,
                        ventana, entramado, faldon, cumbrera, chimenea, farol, farol_pared, barril, cajon, maceta,
                        carretilla, mata, mata_flores, hojas, hiedra, jit, mezcla, elige, lin, ruido2, choque, ancla_p,
                        normal_de, uv_mundo, REVOQUE_A, REVOQUE_B, REVOQUE_C, MADERA_OSC, MADERA, MADERA_GRIS,
                        VERDE_PUERTA, AZUL_POSTIGO, ROJO_POSTIGO, TEJA, PIZARRA, MUSGO, PIEDRA, SILLAR, TIERRA, HIERRO,
                        LATON, BARRO, CRISTAL, LUZ_FAROL, LUZ_VENTANA, HOJA, HIERBA, FLORES, TELAS)
import bpy
import numpy as np

T0 = time.time()
ESCALA = 2.229212239845512          # la escala de la luz de la muestra y del barrio (COMÚN: sin saltos de brillo)
GAMMA_VERTICE = 1.5                 # cómo sale en Godot el color del vértice (ajustado contra la captura de la muestra)


def nota(t):
    print("[kit %6.1f s] %s" % (time.time() - T0, t), flush=True)


# ================================================================ lo que se reutiliza de crear_barrio.py (sin tocarlo)
# crear_barrio.py ejecuta main() al cargarse (lee barrio.json, construye y hornea), así que no se puede importar. Se leen
# con ast SOLO estas definiciones y se ejecutan en un espacio con el kit del barrio; lo que esperan de su guion (U, AZ, CH,
# DECORADO, cota…) se da aquí con el mismo significado. Si crear_barrio.py cambia el nombre de alguna, esto avisa.
_FUNCIONES_BARRIO = ("postes_auto", "puerta_calle", "cesta_pan", "escaparate", "toldo", "letrero_con",
                     "zocalo_y_esquinas", "vuelo_y_mensulas", "ventanas_lado", "casa_alero", "casa_hastial", "nave",
                     "porton", "muro_piedra", "arco_rebajado", "rueda", "mesa", "cajita", "frutas", "tinaja", "fardo",
                     "saco", "farol_pie", "arbol", "valla_varas", "tendedero", "hornacina", "escribir_import")
_CONSTANTES_BARRIO = ("REVOQUE_D", "REVOQUE_E", "REVOQUE_F", "OCRE_POSTIGO", "VERDE_POSTIGO", "PAJA", "AGUA", "OSCURO",
                      "PAN", "PAN_OSC")


def _cargar_barrio():
    ruta = os.path.join(FUENTE_BARRIO, "crear_barrio.py")
    with open(ruta, encoding="utf-8") as f:
        arbol = ast.parse(f.read(), ruta)
    elegidos, vistos = [], set()
    for n in arbol.body:
        if isinstance(n, ast.FunctionDef) and n.name in _FUNCIONES_BARRIO:
            elegidos.append(n)
            vistos.add(n.name)
        elif isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id in _CONSTANTES_BARRIO for t in n.targets):
            elegidos.append(n)
            vistos.update(t.id for t in n.targets if isinstance(t, ast.Name))
    falta = set(_FUNCIONES_BARRIO + _CONSTANTES_BARRIO) - vistos
    if falta:
        raise RuntimeError("crear_barrio.py ya no tiene: %s" % ", ".join(sorted(falta)))
    ns = {k: v for k, v in vars(K).items() if not k.startswith("__")}
    ns.update({"K": K, "os": os, "math": math, "DECORADO": True,
               "U": lambda a, b: K.RND.uniform(a, b), "AZ": lambda: K.RND.random(), "CH": lambda s: K.RND.choice(s),
               "cota": lambda x, z: 0.0, "altura": lambda x, z: 0.0, "pieza_local": lambda *a, **k: True})
    exec(compile(ast.Module(body=elegidos, type_ignores=[]), ruta, "exec"), ns)
    return ns


B = _cargar_barrio()
REVOQUE_D, REVOQUE_E, REVOQUE_F = B["REVOQUE_D"], B["REVOQUE_E"], B["REVOQUE_F"]
OCRE_POSTIGO, VERDE_POSTIGO, PAJA, AGUA, OSCURO = B["OCRE_POSTIGO"], B["VERDE_POSTIGO"], B["PAJA"], B["AGUA"], B["OSCURO"]
puerta_calle, toldo, escaparate, letrero_con = B["puerta_calle"], B["toldo"], B["escaparate"], B["letrero_con"]
casa_alero, casa_hastial, nave, porton = B["casa_alero"], B["casa_hastial"], B["nave"], B["porton"]
muro_piedra, arco_rebajado, rueda, mesa = B["muro_piedra"], B["arco_rebajado"], B["rueda"], B["mesa"]
cajita, frutas, tinaja, fardo, saco = B["cajita"], B["frutas"], B["tinaja"], B["fardo"], B["saco"]
farol_pie, cesta_pan, tendedero, hornacina = B["farol_pie"], B["cesta_pan"], B["tendedero"], B["hornacina"]
vuelo_y_mensulas, zocalo_y_esquinas, escribir_import = B["vuelo_y_mensulas"], B["zocalo_y_esquinas"], B["escribir_import"]


def U(a, b):
    return K.RND.uniform(a, b)


def AZ():
    return K.RND.random()


def CH(s):
    return K.RND.choice(s)


# ================================================================ colores nuevos (dentro de la paleta aprobada)
GLIC = ((0.58, 0.44, 0.80), (0.68, 0.54, 0.88), (0.80, 0.70, 0.94), (0.90, 0.84, 0.98))   # glicinia: violeta → lavanda
HOJA_GLIC = ((0.40, 0.56, 0.26), (0.48, 0.62, 0.30), (0.36, 0.50, 0.24))
CIPRES = ((0.28, 0.44, 0.26), (0.34, 0.50, 0.30), (0.24, 0.38, 0.22), (0.38, 0.54, 0.30))
CIPRES_NUCLEO = (0.15, 0.25, 0.15)
TRONCO = (0.46, 0.38, 0.32)
PIEDRA_NOBLE = (0.87, 0.81, 0.71)
MURALLA = (0.84, 0.79, 0.70)
AGUA_CLARA = (0.64, 0.80, 0.84)
FIGURA = (0.40, 0.46, 0.60)          # la silueta de escala de las láminas (Kael, 1,7 m): no se exporta


# ================================================================ utilidades de construcción

@contextmanager
def sub(o, giro=0.0):
    """Un marco ANIDADO que compone con el que esté en uso (kit_barrio.marco no compone): la geometría (envolviendo la
    malla) y también las anclas y los choques (K.XF). with sub((u, 0, 0)) as S: hornacina(S(m), S(p), S(v))."""
    antes = K.XF
    o, r = Vector(o), Matrix.Rotation(math.radians(giro), 3, 'Y')
    K.XF = (o, r, giro) if antes is None else (antes[0] + antes[1] @ o, antes[1] @ r, antes[2] + giro)
    try:
        yield lambda M: MallaMarco(M, o, r)
    finally:
        K.XF = antes


class SeparaTela:
    """Envuelve una malla: cada cara de tela se aparta 1,5 mm hacia su normal. Las telas de dos caras (ropa, lonas,
    toldos) llevan la misma cara al derecho y al revés; al soldar vértices (a_blender) Blender borraba una de las dos y
    en Godot (cull_back) la tela se veía por un solo lado."""
    def __init__(self, base):
        self.base = base

    def cara(self, pts, mat, col, uvs=None, suave=False):
        if mat == "tela":
            pts = [Vector(q) for q in pts]
            n = normal_de(pts) * 0.0015
            pts = [q + n for q in pts]
        self.base.cara(pts, mat, col, uvs, suave)


def cara_hacia(M, pts, mat, col, hacia):
    """Una cara orientada hacia «hacia» (en Godot lo de espaldas no se dibuja: cull_back)."""
    pts = [Vector(p) for p in pts]
    if normal_de(pts).dot(Vector(hacia)) < 0:
        pts.reverse()
    M.cara(pts, mat, col)


def flores_jardineras(V, sitios):
    """Las flores de las jardineras que devuelven las casas (como casa() de crear_barrio.py)."""
    for q in sitios:
        if q is None:
            continue
        for k in range(3):
            mata_flores(V, q + Vector((-0.3 + k * 0.3, 0.0, 0.0)), 0.15, CH(FLORES), 8, 0.26)
        hojas(V, q + Vector((0, -0.12, 0.08)), 0.3, 22, HOJA, 0.07, flex=0.3, aplastar=0.4)


def pie_matas(V, x0, x1, z, y=0.0, salvo=(), frac=0.4):
    """Matas al pie de una fachada que mira al sur, más en las esquinas (pie_fachada de crear_barrio.py)."""
    x = x0
    while x < x1:
        if not any(a - 0.2 < x < b + 0.2 for a, b in salvo):
            if AZ() < (0.9 if min(abs(x - x0), abs(x - x1)) < 0.8 else frac):
                mata(V, (x, y, z + U(0.0, 0.18)), U(0.14, 0.26), K.RND.randint(10, 20), U(0.22, 0.42))
        x += U(0.3, 0.65)


def arco_muro(m, W, H, grueso, luz, arranque, flecha=None, mat="sillar", col=SILLAR, dovelas=True, col_dov=SILLAR):
    """Un muro de frente en z = 0 (fondo hasta −grueso), de 0 a W y de 0 a H, con un vano en arco centrado: «luz» de
    ancho, salmeres a «arranque» y flecha (por defecto, medio punto = luz/2; menos, arco rebajado). Con «grueso» grande
    es una bóveda de paso (paso bajo casa). Dovelas de sillería en las dos caras."""
    u, semi = W / 2.0, luz / 2.0
    f = semi if flecha is None else flecha
    Rr = (semi * semi + f * f) / (2.0 * f)
    yc = arranque + f - Rr
    a_ini = math.atan2(arranque - yc, semi)
    n = 12
    arco = [(u + math.cos(a) * Rr, yc + math.sin(a) * Rr)
            for a in [math.pi - a_ini - (math.pi - 2 * a_ini) * k / n for k in range(n + 1)]]   # de oeste a este
    caja_mm(m, (0.0, 0.0, -grueso), (u - semi, H, 0.0), mat, jit(col, 0.02))
    caja_mm(m, (u + semi, 0.0, -grueso), (W, H, 0.0), mat, jit(col, 0.02))
    for k in range(n):
        (xa, ya), (xb, yb) = arco[k], arco[k + 1]
        for z, h in ((0.0, (0, 0, 1)), (-grueso, (0, 0, -1))):
            cara_hacia(m, [(xa, ya, z), (xb, yb, z), (xb, H, z), (xa, H, z)], mat, col, h)
        xm, ym = (xa + xb) / 2, (ya + yb) / 2
        cara_hacia(m, [(xa, ya, 0.0), (xb, yb, 0.0), (xb, yb, -grueso), (xa, ya, -grueso)], mat, col,
                   (u - xm, yc - ym, 0))
    caja_mm(m, (u - semi, H - 0.01, -grueso), (u + semi, H, 0.0), mat, col, caras="a")
    if dovelas:
        nd = 9
        for cara_z, eu in ((0.0, (1, 0, 0)), (-grueso, (-1, 0, 0))):
            for k in range(nd):
                a0 = math.pi - a_ini - (math.pi - 2 * a_ini) * k / nd
                a1 = math.pi - a_ini - (math.pi - 2 * a_ini) * (k + 1) / nd
                r1 = Rr + (0.32 if k % 2 == 0 else 0.26)
                pts = [(math.cos(a1) * Rr, math.sin(a1) * Rr), (math.cos(a1) * r1, math.sin(a1) * r1),
                       (math.cos(a0) * r1, math.sin(a0) * r1), (math.cos(a0) * Rr, math.sin(a0) * Rr)]
                if eu[0] < 0:
                    pts = [(-x, y) for x, y in reversed(pts)]
                placa(m, [(x * 0.99, y * 0.99) for x, y in pts], (u, yc, cara_z), eu, (0, 1, 0),
                      0.035 if k != nd // 2 else 0.06, "sillar", jit(col_dov, 0.05))
    return arco


def peldanos(m, x0, x1, z0, y0, n, ch=0.165, hu=0.32, col=SILLAR, base=-0.3):
    """n peldaños macizos que suben hacia −z desde z0 (cota y0): cada uno una caja de sillería de su huella, con el canto
    algo gastado. Devuelve (cota, z) de arriba."""
    for k in range(n):
        za, zb = z0 - k * hu, z0 - (k + 1) * hu
        top = y0 + (k + 1) * ch
        c = jit(col, 0.05)
        caja_mm(m, (x0, y0 + base, zb), (x1, top - 0.03, za), "sillar", c, jit_v=0.004, caras="eoas")
        caja_mm(m, (x0 + 0.01, top - 0.03, zb), (x1 - 0.01, top, za + 0.012), "sillar",
                mezcla(c, (0.62, 0.60, 0.56), 0.15), jit_v=0.004, caras="eoasn")
    return y0 + n * ch, z0 - n * hu


def pretil_escalonado(m, x0, x1, z0, y0, n, ch=0.165, hu=0.32, alto=0.85, col=SILLAR):
    """El pretil de piedra de una escalera, en escalones (uno por peldaño) con su albardilla."""
    for k in range(n):
        za, zb = z0 - k * hu, z0 - (k + 1) * hu
        top = y0 + (k + 1) * ch + alto
        caja_mm(m, (x0, y0 - 0.3, zb), (x1, top, za), "sillar", jit(col, 0.03), caras="eoas")
        caja_mm(m, (x0 - 0.04, top, zb - 0.01), (x1 + 0.04, top + 0.09, za + 0.01), "sillar", jit(SILLAR, 0.05),
                caras="eoasn")


def balaustres(m, x0, x1, z, y, alto=1.0, pilares=True, col=SILLAR, eje="x"):
    """Balaustrada de piedra a lo largo de x (o de z con eje «z», de x0 a x1 = z0 a z1): plinto, balaustres torneados,
    pasamanos y pilares en los extremos. Frente hacia +z (o +x)."""
    def P(u, yy, d):
        return Vector((u, yy, z + d)) if eje == "x" else Vector((z + d, yy, u))
    def C(a, b, mat, c):
        a, b = P(*a), P(*b)
        caja_mm(m, (min(a.x, b.x), min(a.y, b.y), min(a.z, b.z)), (max(a.x, b.x), max(a.y, b.y), max(a.z, b.z)), mat, c)
    C((x0, y - 0.05, -0.3), (x1, y + 0.18, 0.0), "sillar", jit(col, 0.03))
    hp = alto - 0.12
    C((x0, y + hp, -0.33), (x1, y + hp + 0.12, 0.03), "sillar", jit(col, 0.04))
    perfil = [(0, 0.075), (0.05, 0.075), (0.11, 0.045), (0.3, 0.1), (0.46, 0.062), (0.56, 0.05), (0.6, 0.08),
              (hp - 0.18, 0.08)]
    u = x0 + 0.3
    while u < x1 - 0.2:
        cilindro(m, P(u, y + 0.18, -0.15), perfil, 6, "sillar", jit(col, 0.04), tapa_arriba=False)
        u += 0.29
    if pilares:
        for uu in (x0 + 0.17, x1 - 0.17):
            C((uu - 0.17, y + 0.18, -0.32), (uu + 0.17, y + alto + 0.08, 0.02), "sillar", jit(col, 0.03))
            C((uu - 0.2, y + alto + 0.08, -0.35), (uu + 0.2, y + alto + 0.16, 0.05), "sillar", jit(SILLAR, 0.04))


def racimo(V, top, largo, ancho):
    """Un racimo de glicinia colgante: pirámide de 4 lados estirada hacia abajo, violeta arriba y lavanda en la punta
    (el alfa del vértice es el viento de calle_hoja: quieto arriba, suelto abajo)."""
    a0 = U(0.0, math.pi / 2)
    top = Vector(top)
    deriva = Vector((U(-0.06, 0.06), 0.0, U(-0.06, 0.06)))
    def anillo(y, r, s):
        return [top + Vector((math.cos(a0 + k * math.pi / 2) * r, -y, math.sin(a0 + k * math.pi / 2) * r)) + deriva * s
                for k in range(4)]
    r0, r1 = anillo(0.0, ancho * 0.8, 0.0), anillo(largo * 0.45, ancho, 0.4)
    punta = top + Vector((0.0, -largo, 0.0)) + deriva
    c0, c1, c2 = jit(GLIC[0], 0.05), jit(CH(GLIC[1:3]), 0.05), jit(GLIC[3], 0.03)
    for k in range(4):
        k1 = (k + 1) % 4
        V.cara([r0[k], r0[k1], r1[k1], r1[k]], "hoja", [lin(c0, 0.45), lin(c0, 0.45), lin(c1, 0.7), lin(c1, 0.7)])
        V.cara([r1[k], r1[k1], punta], "hoja", [lin(c1, 0.7), lin(c1, 0.7), lin(c2, 1.0)])


def glicinia(P, V, ruta, racimos=20, grosor=0.09, n_hojas=16, colgar=(0.35, 0.6), desde=0.45):
    """La glicinia: un tronco retorcido por la ruta (puntos), hojas a lo largo de su parte alta (desde la fracción
    «desde») y racimos colgantes debajo."""
    pts = [Vector(q) for q in ruta]
    total = sum((pts[i + 1] - pts[i]).length for i in range(len(pts) - 1))
    acc, muestras = 0.0, []
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = (b - a).length
        n = max(1, int(L / 0.32))
        prev = a
        for k in range(1, n + 1):
            t = k / n
            q = a.lerp(b, t)
            if k < n:
                q = q + Vector((U(-0.05, 0.05), U(-0.03, 0.03), U(-0.03, 0.03)))
            g = grosor * (1.0 - 0.55 * (acc + L * t) / total)
            viga(P, prev, q, g, "madera", jit(TRONCO, 0.05))
            muestras.append((q, (acc + L * t) / total))
            prev = q
        acc += L
    altos = [q for q, f in muestras if f >= desde] or [pts[-1]]
    for q in altos:
        hojas(V, q + Vector((0.0, 0.06, 0.04)), 0.34, n_hojas, HOJA_GLIC, 0.085, flex=0.45, aplastar=0.55)
    for k in range(racimos):
        q = altos[k % len(altos)]
        racimo(V, q + Vector((U(-0.28, 0.28), U(-0.14, 0.0), U(-0.04, 0.16))), U(*colgar), U(0.07, 0.1))


def cipres(P, V, c, alto=7.0, radio=0.7):
    """Ciprés estilizado: un huso macizo verde oscuro (lo que tapa) cubierto de hojas en rombo hacia fuera, más claras
    arriba y al sol; tronco corto."""
    c = Vector(c)
    cilindro(P, c + Vector((0, -0.05, 0)), [(0, 0.13), (0.55, 0.11)], 7, "madera", jit(TRONCO, 0.05))
    def r_de(h):
        t = h / alto
        return radio * (math.sin(math.pi * min(1.0, 0.12 + t * 0.95)) ** 0.75) * (1.0 - 0.25 * t)
    perfil = [(0.4, r_de(0.4) * 0.8)] + [(alto * t, r_de(alto * t) * 0.82) for t in (0.2, 0.4, 0.6, 0.8, 0.92)] + \
             [(alto, 0.02)]
    cilindro(P, c, perfil, 7, "hoja", jit(CIPRES_NUCLEO, 0.05), suave=True)
    n = int(alto * radio * 115)
    for k in range(n):
        h = 0.45 + (alto - 0.55) * math.sqrt(AZ()) if AZ() < 0.5 else 0.45 + (alto - 0.55) * AZ()
        a = U(0.0, math.tau)
        r = r_de(h) * U(0.9, 1.08)
        p = c + Vector((math.cos(a) * r, h, math.sin(a) * r))
        nrm = Vector((math.cos(a), 0.35, math.sin(a))).normalized()
        t1 = nrm.cross(Vector((0.0, 1.0, 0.0))).normalized()
        t2 = nrm.cross(t1).normalized()
        s = U(0.13, 0.2)
        col = jit(elige(CIPRES), 0.08)
        if math.cos(a - math.radians(252.0 - 90.0)) > 0.3:          # el lado del sol, algo más claro
            col = mezcla(col, (0.56, 0.66, 0.34), 0.18)
        f = 0.12 + 0.35 * h / alto
        V.cara([p - t1 * s * 0.5, p - t2 * s, p + t1 * s * 0.5, p + t2 * s], "hoja", [lin(col, f)] * 4)
    choque(c + Vector((0, 1.0, 0)), (radio * 1.4, 2.0, radio * 1.4), 0.0, "tronco")


def figura(M, c):
    """La silueta de escala de las láminas: Kael, 1,70 m (piernas, cuerpo, hombros y cabeza). No se exporta."""
    c = Vector(c)
    cilindro(M, c, [(0, 0.11), (0.78, 0.13), (0.86, 0.17), (1.3, 0.2), (1.42, 0.13), (1.47, 0.06)], 8, "tela", FIGURA)
    cilindro(M, c + Vector((0, 1.45, 0)), [(0, 0.0), (0.03, 0.09), (0.12, 0.12), (0.21, 0.1), (0.25, 0.0)], 8, "tela",
             FIGURA, tapa_arriba=False)


# ================================================================ el registro de módulos

MODULOS = []
MOD = {}


def modulo(nombre, sectores, uso, tipo="fachada"):
    """Registra un constructor f(m, p, v) en coordenadas locales (pivote según «tipo»: fachada, escalera, suelo,
    atrezo). f puede devolver {"huella": (x0, z0, x1, z1), …}."""
    def d(f):
        md = {"nombre": nombre, "sectores": sectores, "uso": uso, "tipo": tipo, "f": f}
        MODULOS.append(md)
        MOD[nombre] = md
        return f
    return d


def colocar(nombre, mallas, origen=(0.0, 0.0, 0.0), giro=0.0):
    """API para el generador de un sector: construye el módulo «nombre» en las mallas (fijo, piezas, vegetación) del
    sector EN USO (K.usar), con su pivote en «origen» (Godot) y girado «giro» grados (0 = mira al sur; 90 = al este;
    −90 = al oeste; 180 = al norte). Las anclas y los choques van al sector con su sitio en el mundo."""
    M, P, V = mallas
    with sub(origen, giro) as S:
        return MOD[nombre]["f"](SeparaTela(S(M)), SeparaTela(S(P)), SeparaTela(S(V))) or {}


# ================================================================ FACHADAS (una casa entera; frente en z = 0)

@modulo("vivienda_terrazas", ["4 Las Terrazas"],
        "Vivienda de las Terrazas: hastial a la calle, balcón de madera con macetas y una glicinia que trepa por la "
        "jamba y corre bajo el balcón. Puerta en arco 1,15 × 2,4 m.")
def m_vivienda_terrazas(m, p, v):
    W, F = 6.4, 6.0
    e = dict(rev=REVOQUE_D, post=VERDE_POSTIGO, pb=2.95, p1=2.4, pb_mat="revoque", balcon=3.2,
             ventanas_p1=[(1.15, 0.6), (5.25, 0.6, True)], ventanas_pb=[(1.2, 0.7, 1.0, 1.1), (5.2, 0.7, 1.0, 1.1, True)],
             chimenea=(4.9, -3.4), polea=False, alto_tejado=2.7, musgo=0.2)
    fl = casa_hastial(m, p, v, W, F, e)
    puerta_calle(m, p, 3.2, 1.15, 2.4, "arco", VERDE_PUERTA)
    flores_jardineras(v, fl)
    glicinia(p, v, [(2.38, 0.0, 0.3), (2.25, 1.2, 0.34), (2.42, 2.45, 0.42), (3.0, 2.85, 1.16), (4.25, 2.9, 1.16)],
             racimos=16, desde=0.5)
    glicinia(p, v, [(2.42, 2.45, 0.42), (1.5, 2.95, 0.62), (0.35, 3.05, 0.62), (0.2, 4.1, 0.6)], racimos=12,
             grosor=0.06, desde=0.2)
    for x in (2.15, 4.25):
        maceta(p, v, (x, 0.0, 0.45), 0.2, 0.3)
    pie_matas(v, 0.0, W, 0.1, salvo=((2.4, 4.0),))
    choque((W / 2, 1.5, -F / 2), (W, 3.0, F), 0.0, "casa")
    ancla_p("puerta", (3.2, 0.0, 0.9))
    return {"huella": (0.0, -F, W, 0.0)}


@modulo("vivienda_terrazas_escalera", ["4 Las Terrazas"],
        "Vivienda de las Terrazas con escalera exterior de 17 peldaños (0,176 × 0,30 m) a la puerta del piso y rellano "
        "volado sobre la puerta de abajo; macetas en los peldaños y baranda de madera.")
def m_vivienda_terrazas_escalera(m, p, v):
    W, F = 8.0, 5.6
    yb = 3.0
    e = dict(rev=REVOQUE_A, post=AZUL_POSTIGO, pb=yb, p1=2.5, vuelo=0.12, mensulas=[0.3],
             ventanas_p1=[(1.5, 0.6), (3.7, 0.6, True)], ventanas_pb=[], chimenea=(1.2, -3.0), musgo=0.25,
             alto_tejado=2.5)
    fl = casa_alero(m, p, v, W, F, e)
    flores_jardineras(v, fl)
    n, ch, hu, x0 = 17, yb / 17.0, 0.30, 0.45
    for k in range(n):                                     # los peldaños, macizos de sillería (suben hacia el este)
        xa, xb = x0 + k * hu, x0 + (k + 1) * hu
        caja_mm(m, (xa, -0.3, 0.02), (xb, (k + 1) * ch, 1.0), "sillar", jit(SILLAR, 0.05), jit_v=0.004, caras="eosa")
    xl = x0 + n * hu                                        # el rellano (losa volada sobre la puerta de abajo)
    caja_mm(m, (xl, yb - 0.24, 0.0), (7.3, yb, 1.25), "sillar", jit(SILLAR, 0.03))
    for xm in (xl + 0.2, 7.1):
        viga(m, (xm, yb - 0.9, 0.05), (xm, yb - 0.26, 1.0), 0.14, "madera", MADERA_OSC, alto=0.14)
    puerta_calle(m, p, 6.4, 1.05, 2.3, "dintel", VERDE_PUERTA)
    puerta_calle(m, p, 6.35, 0.95, 2.2, "dintel", AZUL_POSTIGO, y=yb, z=0.12)
    for k in range(0, n + 1, 3):                            # la baranda de madera (postes y pasamanos)
        x = x0 + k * hu + 0.15
        viga(m, (x, k * ch, 0.94), (x, k * ch + 0.95, 0.94), 0.07, "madera", MADERA_OSC)
    viga(m, (x0 + 0.15, 0.95, 0.94), (xl, yb + 0.95, 0.94), 0.06, "madera", MADERA)
    viga(m, (xl, yb + 0.95, 1.2), (7.3, yb + 0.95, 1.2), 0.06, "madera", MADERA)
    viga(m, (xl, yb + 0.95, 0.94), (xl, yb + 0.95, 1.2), 0.06, "madera", MADERA)
    for x in (xl, 7.25):
        viga(m, (x, yb, 1.2), (x, yb + 0.95, 1.2), 0.07, "madera", MADERA_OSC)
    for k in range(2, n, 4):                                # geranios en los peldaños
        maceta(p, v, (x0 + k * hu + 0.15, (k + 1) * ch, 0.25), 0.13, 0.2)
    maceta(p, v, (7.0, yb, 0.35), 0.18, 0.26)
    farol_pared(m, (5.4, 2.6, 0.02), (0.0, 0.0, 1.0))
    pie_matas(v, 6.0, W, 0.1, salvo=((5.8, 7.0),))
    choque((W / 2, 1.5, -F / 2), (W, 3.0, F), 0.0, "casa")
    choque(((x0 + xl) / 2, 0.75, 0.5), (xl - x0, 1.5, 1.0), 0.0, "escalera")
    ancla_p("puerta", (6.4, 0.0, 0.9))
    ancla_p("puerta_alta", (6.35, yb, 0.75))
    return {"huella": (0.0, -F, W, 1.25)}


@modulo("forja", ["3 Calle de los Oficios"],
        "Taller y forja: planta baja de sillería con la boca del taller en arco rebajado, fragua encendida bajo un "
        "tejadillo, yunque, pila de templar, chimenea ancha y letrero de la herradura.")
def m_forja(m, p, v):
    W, F = 7.6, 6.2
    e = dict(rev=REVOQUE_B, post=ROJO_POSTIGO, pb=3.4, p1=2.5, vuelo=0.25, mensulas=[0.3], pb_mat="sillar",
             ventanas_p1=[(1.4, 0.6), (3.8, 0.6, True), (6.2, 0.6)], chimenea=(6.0, -2.6, 0.9, 1.1, 0.9), musgo=0.08,
             alto_tejado=2.4)
    casa_alero(m, p, v, W, F, e)
    arco_rebajado(m, 2.0, 2.45, 2.2, 1.35, 0.0, col=SILLAR)
    caja_mm(m, (1.4, 0.0, 0.004), (2.6, 0.35, 0.01), "brillo", (1.0, 0.45, 0.16))        # el resplandor de dentro
    # la fragua, bajo su tejadillo, a la calle: murete de ladrillo, brasas, campana y fuelle
    fx, fz = 5.6, 0.75
    caja_mm(m, (fx - 0.75, 0.0, fz - 0.5), (fx + 0.75, 0.85, fz + 0.45), "sillar", jit((0.70, 0.46, 0.36), 0.05))
    caja_mm(m, (fx - 0.55, 0.85, fz - 0.35), (fx + 0.55, 0.92, fz + 0.3), "brillo", (1.0, 0.42, 0.14))
    ancla_p("brasa_0", (fx, 1.05, fz))
    cono(m, (fx, 1.85, fz - 0.15), 0.7, 0.75, 4, "hierro", (0.24, 0.22, 0.22), rot=R(45))
    viga(m, (fx, 2.55, fz - 0.15), (fx, 3.05, -0.05), 0.24, "hierro", (0.24, 0.22, 0.22))
    caja(m, (fx + 1.05, 0.62, fz), (0.5, 0.36, 0.42), "tela", (0.46, 0.32, 0.24), rot=R(0, 0, 18))          # fuelle
    faldon(m, (3.75, 2.75, 1.9), (7.75, 2.75, 1.9), (0.0, 0.45, -1.85), TEJA, musgo=0.05)
    for x in (3.9, 7.6):
        viga(m, (x, 0.0, 1.75), (x, 2.75, 1.75), 0.14, "madera", MADERA_OSC)
    viga(m, (3.8, 2.7, 1.75), (7.7, 2.7, 1.75), 0.16, "madera", MADERA_OSC)
    cilindro(p, (3.6, 0.0, 1.25), [(0, 0.3), (0.62, 0.28)], 9, "madera", jit(TRONCO, 0.05))           # el yunque
    caja(p, (3.6, 0.72, 1.25), (0.5, 0.2, 0.22), "hierro", HIERRO)
    cono(p, (3.88, 0.66, 1.25), 0.1, 0.22, 4, "hierro", HIERRO, rot=R(0, 0, -90))
    barril(p, (2.95, 0.0, 1.55), 0.3, 0.7)
    caja(p, (2.95, 0.7, 1.55), (0.48, 0.02, 0.48), "hierro", AGUA, caras="a")
    for k, x in enumerate((6.95, 7.15, 7.3)):               # tenazas y barras apoyadas
        viga(p, (x, 0.0, 0.25), (x - 0.12, 1.1 + k * 0.1, 0.12), 0.03, "hierro", HIERRO)
    letrero_con(m, (0.1, 2.9, 0.05), (-0.2, 0.0, 1.0), "herradura")
    choque((W / 2, 1.5, -F / 2), (W, 3.0, F), 0.0, "casa")
    choque((fx, 0.6, fz), (1.6, 1.2, 1.0), 0.0, "fragua")
    ancla_p("puerta", (2.0, 0.0, 1.2))
    return {"huella": (0.0, -F, W, 0.0)}


@modulo("tienda_toldo", ["2 Plaza del Tapiz", "3 Calle de los Oficios"],
        "Tienda con escaparate encendido de telas, toldo a rayas (borde a 2,28 m), letrero y puerta de dintel.")
def m_tienda_toldo(m, p, v):
    W, F = 6.8, 5.5
    e = dict(rev=REVOQUE_E, post=OCRE_POSTIGO, pb=3.1, p1=2.5, ventanas_p1=[(1.3, 0.6), (3.4, 0.6, True), (5.5, 0.6)],
             chimenea=(5.3, -3.2), musgo=0.2, alto_tejado=2.5)
    fl = casa_alero(m, p, v, W, F, e)
    flores_jardineras(v, fl)
    escaparate(m, p, v, 0.6, 3.7, 0.85, 1.35, "telas", True)
    puerta_calle(m, p, 5.05, 1.1, 2.35, "dintel", AZUL_POSTIGO)
    toldo(m, 0.35, 3.95, 2.95, 2.5, 1.45, [TELAS[2], TELAS[0]])
    letrero_con(m, (W - 0.1, 2.95, 0.05), (0.25, 0.0, 1.0), "tela")
    for k in range(2):
        cajita(p, (4.1 + k * 0.05, 0.0 + k * 0.42, 0.7), (0.55, 0.42, 0.45), yaw=U(-8, 8))
    maceta(p, v, (6.25, 0.0, 0.4), 0.2, 0.3)
    pie_matas(v, 0.0, W, 0.1, salvo=((0.5, 3.8), (4.4, 5.7)))
    choque((W / 2, 1.5, -F / 2), (W, 3.0, F), 0.0, "casa")
    ancla_p("puerta", (5.05, 0.0, 0.9))
    return {"huella": (0.0, -F, W, 0.0)}


@modulo("casa_pasajes", ["5 Pasajes Viejos"],
        "Casa de los Pasajes Viejos: estrecha (3,8 m), de tres alturas con dos vuelos, revoque gris de cal, hiedra, "
        "farol y un leve desplome hacia el este (antigua).")
def m_casa_pasajes(m, p, v):
    W, F = 3.8, 6.0
    e = dict(rev=REVOQUE_F, post=OCRE_POSTIGO, pb=2.75, p1=2.35, p2=2.3, pb_mat="sillar", ventanas_p1=[(1.9, 0.55)],
             chimenea=(2.9, -3.6), polea=True, alto_tejado=6.2, musgo=0.55)
    m2 = Malla()                                           # se construye aparte para desplomarla
    fl = casa_hastial(m2, p, v, W, F, e)
    puerta_calle(m2, p, 1.9, 1.0, 2.3, "dintel", (0.42, 0.30, 0.22))
    farol_pared(m2, (3.55, 2.5, 0.05), (0.3, 0.0, 1.0))
    def desplome(q):                                       # 2,5 cm por metro hacia el este
        return Vector((q.x + 0.025 * max(0.0, q.y), q.y, q.z))
    for pts, mat, col, uvs, sv in m2.caras:
        m.cara([desplome(q) for q in pts], mat, col, uvs, sv)
    flores_jardineras(v, [desplome(q) for q in fl if q is not None])
    hiedra(v, 0.35, 0.0, 3.6)
    pie_matas(v, 0.0, W, 0.1, salvo=((1.3, 2.5),), frac=0.6)
    choque((W / 2, 1.5, -F / 2), (W, 3.0, F), 0.0, "casa")
    ancla_p("puerta", (1.9, 0.0, 0.9))
    return {"huella": (0.0, -F, W, 0.0)}


def balcon_hierro(m, p, v, u0, u1, y, salida=0.7):
    """Balcón de losa de piedra con moldura, ménsulas y baranda de barrotes de hierro (el Barrio Alto)."""
    caja_mm(m, (u0, y - 0.16, 0.0), (u1, y, salida), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (u0 - 0.04, y - 0.22, 0.0), (u1 + 0.04, y - 0.16, salida + 0.04), "sillar", jit(SILLAR, 0.04))
    for x in (u0 + 0.25, u1 - 0.25):
        viga(m, (x, y - 0.75, 0.04), (x, y - 0.22, salida - 0.1), 0.14, "sillar", SILLAR, alto=0.16)
    x = u0 + 0.06
    while x <= u1 - 0.05:
        caja_mm(m, (x - 0.012, y, salida - 0.06), (x + 0.012, y + 0.92, salida - 0.035), "hierro", HIERRO)
        x += 0.12
    for zz in (0.06, salida - 0.05):
        for xx in (u0 + 0.03, u1 - 0.03):
            caja_mm(m, (xx - 0.015, y, zz - 0.012), (xx + 0.015, y + 0.92, zz + 0.012), "hierro", HIERRO)
    caja_mm(m, (u0, y + 0.9, salida - 0.07), (u1, y + 0.95, salida - 0.02), "hierro", HIERRO)
    caja_mm(m, (u0, y + 0.9, 0.0), (u0 + 0.04, y + 0.95, salida - 0.02), "hierro", HIERRO)
    caja_mm(m, (u1 - 0.04, y + 0.9, 0.0), (u1, y + 0.95, salida - 0.02), "hierro", HIERRO)
    caja_mm(m, (u0, y + 0.1, salida - 0.07), (u1, y + 0.13, salida - 0.02), "hierro", HIERRO)


@modulo("casa_noble", ["7 Barrio Alto de las Raíces"],
        "Casa noble del Barrio Alto: planta baja de sillería con portada en arco (1,7 × 3,1 m) entre pilastras, rejas, "
        "piso noble con balcón corrido de hierro, cornisa y tejado de pizarra con dos chimeneas.")
def m_casa_noble(m, p, v):
    W, F = 9.6, 8.0
    yb, y1 = 3.8, 7.4
    u = W / 2
    caja_mm(m, (0.0, -0.6, -F), (W, 0.5, 0.08), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (0.02, 0.5, -F), (W - 0.02, yb, 0.0), "sillar", jit(PIEDRA_NOBLE, 0.02))
    caja_mm(m, (0.04, yb, -F), (W - 0.04, y1, 0.0), "revoque", REVOQUE_C)
    caja_mm(m, (-0.04, yb - 0.06, -F), (W + 0.04, yb + 0.14, 0.14), "sillar", jit(SILLAR, 0.03))       # imposta
    caja_mm(m, (-0.08, y1 - 0.06, -F - 0.08), (W + 0.08, y1 + 0.12, 0.2), "sillar", jit(SILLAR, 0.03))  # cornisa
    caja_mm(m, (-0.16, y1 + 0.12, -F - 0.16), (W + 0.16, y1 + 0.26, 0.32), "sillar", jit(SILLAR, 0.03))
    for xe, s in ((0.0, 1), (W, -1)):                       # esquinas de sillería en el piso noble
        y, k = yb + 0.14, 0
        while y < y1 - 0.1:
            h = 0.4
            w = 0.46 if k % 2 == 0 else 0.3
            caja_mm(m, (xe if s > 0 else xe - w, y, -0.4), (xe + w if s > 0 else xe, min(y1 - 0.06, y + h - 0.02), 0.04),
                    "sillar", jit(SILLAR, 0.05), jit_v=0.006)
            y += h
            k += 1
    puerta_calle(m, p, u, 1.7, 3.1, "arco", (0.36, 0.26, 0.20), marco_col=PIEDRA_NOBLE, y=0.0)
    for s in (-1, 1):                                       # pilastras y entablamento de la portada
        caja_mm(m, (u + s * 1.55 - 0.2, 0.0, 0.0), (u + s * 1.55 + 0.2, 3.45, 0.16), "sillar", jit(SILLAR, 0.03))
        caja_mm(m, (u + s * 1.55 - 0.26, 0.0, 0.0), (u + s * 1.55 + 0.26, 0.45, 0.2), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (u - 1.85, 3.45, 0.0), (u + 1.85, 3.72, 0.22), "sillar", jit(SILLAR, 0.03))
    placa(m, [(-0.35, 0.0), (0.35, 0.0), (0.35, 0.5), (0.0, 0.62), (-0.35, 0.5)], (u, 3.0, 0.0), (1, 0, 0), (0, 1, 0),
          0.06, "sillar", jit(PIEDRA_NOBLE, 0.03))        # la cartela (lisa: sin emblema)
    for x in (1.6, W - 1.6):                                # ventanas bajas con reja
        ventana(m, x, 1.3, 0.0, 0.8, 1.3, None)
        for k in range(6):
            caja_mm(m, (x - 0.42 + k * 0.168, 1.2, 0.13), (x - 0.4 + k * 0.168, 2.7, 0.15), "hierro", HIERRO)
        for yy in (1.25, 2.0, 2.65):
            caja_mm(m, (x - 0.46, yy, 0.12), (x + 0.46, yy + 0.04, 0.16), "hierro", HIERRO)
    balcon_hierro(m, p, v, u - 1.7, u + 1.7, yb + 0.16, 0.75)
    fl = []
    for x in (u - 0.85, u + 0.85):                          # puertas-ventana del balcón
        ventana(m, x, yb + 0.2, 0.0, 0.75, 2.0, AZUL_POSTIGO, luz=x > u)
    for x in (1.5, W - 1.5):
        fl.append(ventana(m, x, yb + 0.9, 0.0, 0.75, 1.6, AZUL_POSTIGO, jardinera=True))
        caja_mm(m, (x - 0.55, yb + 2.62, 0.0), (x + 0.55, yb + 2.78, 0.16), "sillar", jit(SILLAR, 0.03))  # guardapolvo
    flores_jardineras(v, fl)
    for k in range(3):
        maceta(p, v, (u - 1.2 + k * 1.2, yb + 0.16, 0.42), 0.15, 0.22)
    yr = y1 + 0.26 + 3.0
    za, zb = 0.6, -F - 0.45
    zr = (za + zb) / 2
    faldon(m, (-0.3, y1 + 0.2, za), (W + 0.3, y1 + 0.2, za), (0, yr - y1 - 0.2, zr - za), PIZARRA, musgo=0.05)
    faldon(m, (W + 0.3, y1 + 0.2, zb), (-0.3, y1 + 0.2, zb), (0, yr - y1 - 0.2, zr - zb), PIZARRA, musgo=0.0)
    cumbrera(m, (-0.3, yr + 0.02, zr), (W + 0.3, yr + 0.02, zr), PIZARRA[1])
    for xh, s in ((0.0, -1), (W, 1)):
        pts = [Vector((xh, y1 + 0.26, 0.2)), Vector((xh, yr - 0.05, zr)), Vector((xh, y1 + 0.26, -F))]
        m.cara(list(reversed(pts)) if s > 0 else pts, "sillar", PIEDRA_NOBLE)
    chimenea(m, 0.9, zr, yr - 1.0, yr + 0.9, 0.9, 0.7)
    chimenea(m, W - 0.9, zr, yr - 1.0, yr + 0.9, 0.9, 0.7)
    vx = u                                                  # buhardilla de pizarra al centro
    caja_mm(m, (vx - 0.7, yr - 2.45, za - 1.9), (vx + 0.7, yr - 0.75, za - 1.1), "revoque", REVOQUE_C)
    ventana(m, vx, yr - 1.85, za - 1.1, 0.55, 0.75, None, luz=True)
    faldon(m, (vx - 0.9, yr - 0.8, za - 0.9), (vx - 0.9, yr - 0.8, za - 2.6), (0.9, 0.5, 0), PIZARRA, musgo=0.0, solape=0.3)
    faldon(m, (vx + 0.9, yr - 0.8, za - 2.6), (vx + 0.9, yr - 0.8, za - 0.9), (-0.9, 0.5, 0), PIZARRA, musgo=0.0, solape=0.3)
    farol_pared(m, (u - 2.3, 2.9, 0.05), (0.0, 0.0, 1.0))
    farol_pared(m, (u + 2.3, 2.9, 0.05), (0.0, 0.0, 1.0))
    pie_matas(v, 0.0, W, 0.12, salvo=((u - 2.0, u + 2.0),), frac=0.25)
    choque((W / 2, 1.5, -F / 2), (W, 3.0, F), 0.0, "casa")
    ancla_p("puerta", (u, 0.0, 1.0))
    return {"huella": (0.0, -F, W, 0.0)}


@modulo("almacen_ribera", ["8 La Ribera Baja"],
        "Almacén de la Ribera: nave de tablas sobre zócalo, portón doble abierto (2,8 × 3,0 m), puerta del pajar con "
        "viga de polea, muelle de carga de piedra, sacos y toneles.")
def m_almacen_ribera(m, p, v):
    W, F = 9.0, 7.0
    nave(m, p, v, W, F, 4.5, dict(vanos=3, alto_tejado=2.3, musgo=0.6, tabla=(0.58, 0.55, 0.50)))
    caja_mm(m, (1.6, 0.0, 0.045), (4.4, 3.0, 0.05), "hierro", OSCURO)                   # la boca, a ras de calle
    porton(m, 3.0, 2.8, 3.0, abierto=True, color=MADERA_GRIS, z=0.05, y=0.0)
    caja_mm(m, (6.2, 2.7, 0.025), (7.4, 3.85, 0.03), "hierro", OSCURO)                     # la puerta del pajar
    for x in (6.15, 7.45):
        viga(m, (x, 2.65, 0.08), (x, 3.9, 0.08), 0.1, "madera", MADERA_OSC)
    viga(m, (6.05, 2.62, 0.09), (7.55, 2.62, 0.09), 0.12, "madera", MADERA_OSC)
    viga(m, (6.8, 4.25, -0.4), (6.8, 4.25, 1.3), 0.17, "madera", MADERA_OSC, alto=0.19)     # la viga de la polea
    cilindro(m, (6.76, 4.08, 1.15), [(0, 0.12), (0.08, 0.12)], 10, "madera", MADERA, rot=R(0, 0, 90))
    viga(m, (6.84, 4.08, 1.15), (6.84, 1.9, 1.15), 0.022, "tela", (0.70, 0.62, 0.48))
    caja(m, (6.84, 1.85, 1.15), (0.06, 0.1, 0.03), "hierro", HIERRO)
    caja_mm(m, (5.0, -0.3, 0.0), (8.8, 0.6, 1.4), "sillar", jit(SILLAR, 0.03))             # el muelle de carga
    caja_mm(m, (4.95, 0.6, -0.05), (8.85, 0.68, 1.45), "sillar", jit(SILLAR, 0.05))
    for k in range(4):
        saco(p, (5.5 + k * 0.42, 0.68, 0.55 + (k % 2) * 0.35), U(0, 90))
    barril(p, (8.3, 0.68, 0.6), 0.3, 0.8)
    barril(p, (7.7, 0.68, 0.9), 0.3, 0.8)
    cajita(p, (0.8, 0.0, 0.6), (0.7, 0.55, 0.6), yaw=6)
    cajita(p, (0.75, 0.55, 0.62), (0.55, 0.42, 0.5), yaw=-10)
    letrero_con(m, (W - 0.15, 3.3, 0.06), (0.3, 0.0, 1.0), "tonel")
    farol_pared(m, (4.75, 3.25, 0.06), (0.0, 0.0, 1.0))
    pie_matas(v, 0.0, W, 0.1, salvo=((1.4, 4.6), (4.9, 8.9)), frac=0.6)
    choque((W / 2, 1.5, -F / 2), (W, 3.0, F), 0.0, "nave")
    choque((6.9, 0.35, 0.7), (3.8, 0.7, 1.4), 0.0, "muelle")
    ancla_p("puerta", (3.0, 0.0, 1.2))
    return {"huella": (0.0, -F, W, 1.45)}


# ================================================================ ARCOS, PUERTAS Y VENTANAS (piezas de muro)

@modulo("arco_paso", ["5 Pasajes Viejos", "1 Puerta del Sur", "7 Barrio Alto"],
        "Arco de paso en un muro de sillería de 0,7 m: vano de 2,4 m de medio punto (clave a 3,6 m), dovelas en las dos "
        "caras y albardilla.")
def m_arco_paso(m, p, v):
    W, H, g = 4.6, 4.3, 0.7
    arco_muro(m, W, H, g, 2.4, 2.4, mat="sillar", col=MURALLA)
    caja_mm(m, (-0.05, H, -g - 0.05), (W + 0.05, H + 0.14, 0.06), "sillar", jit(SILLAR, 0.05))
    hiedra(v, 0.5, 0.0, 3.2)
    choque((0.55, 2.0, -g / 2), (1.1, 4.0, g), 0.0, "pila_o")
    choque((W - 0.55, 2.0, -g / 2), (1.1, 4.0, g), 0.0, "pila_e")
    ancla_p("paso", (W / 2, 0.0, -g / 2))
    return {"huella": (0.0, -g, W, 0.0)}


@modulo("arco_rebajado_paso", ["3 Calle de los Oficios", "8 La Ribera Baja", "2 Plaza del Tapiz"],
        "Arco rebajado de paso (vano 3,2 m, clave a 3,1 m) en un muro de revoque de 0,6 m con dovelas de sillería.")
def m_arco_rebajado_paso(m, p, v):
    W, H, g = 5.2, 4.0, 0.6
    arco_muro(m, W, H, g, 3.2, 2.35, flecha=0.75, mat="revoque", col=REVOQUE_D)
    caja_mm(m, (0.0, -0.3, -g - 0.02), (W, 0.4, 0.04), "sillar", jit(SILLAR, 0.03), caras="eoasn")
    caja_mm(m, (-0.05, H, -g - 0.05), (W + 0.05, H + 0.12, 0.06), "sillar", jit(SILLAR, 0.05))
    farol_pared(m, (0.55, 2.9, 0.02), (0.0, 0.0, 1.0))
    choque((0.5, 2.0, -g / 2), (1.0, 4.0, g), 0.0, "pila_o")
    choque((W - 0.5, 2.0, -g / 2), (1.0, 4.0, g), 0.0, "pila_e")
    ancla_p("paso", (W / 2, 0.0, -g / 2))
    return {"huella": (0.0, -g, W, 0.0)}


def panel(m, W, H, col=REVOQUE_D, grueso=0.4, zoc=0.45):
    caja_mm(m, (0.0, 0.0, -grueso), (W, H, 0.0), "revoque", col)
    caja_mm(m, (-0.02, -0.3, -grueso - 0.02), (W + 0.02, zoc, 0.04), "sillar", jit(SILLAR, 0.03), caras="eoasn")


@modulo("puerta_arco", ["todos"], "Puerta de calle en arco de dovelas (1,2 × 2,5 m), hoja verde de tablas con aldaba, en "
        "un paño de muro de 2,8 × 3,4 m.", tipo="muro")
def m_puerta_arco(m, p, v):
    panel(m, 2.8, 3.4)
    puerta_calle(m, p, 1.4, 1.2, 2.5, "arco", VERDE_PUERTA, z=0.0)
    maceta(p, v, (0.35, 0.0, 0.35), 0.2, 0.3)
    ancla_p("puerta", (1.4, 0.0, 0.9))
    choque((1.4, 1.5, -0.2), (2.8, 3.0, 0.4), 0.0, "muro")
    return {"huella": (0.0, -0.4, 2.8, 0.0)}


@modulo("puerta_dintel", ["todos"], "Puerta de dintel de madera sobre jambas de piedra (1,1 × 2,3 m), hoja roja, en un "
        "paño de 2,6 × 3,2 m.", tipo="muro")
def m_puerta_dintel(m, p, v):
    panel(m, 2.6, 3.2, REVOQUE_E)
    puerta_calle(m, p, 1.3, 1.1, 2.3, "dintel", ROJO_POSTIGO)
    ancla_p("puerta", (1.3, 0.0, 0.9))
    choque((1.3, 1.5, -0.2), (2.6, 3.0, 0.4), 0.0, "muro")
    return {"huella": (0.0, -0.4, 2.6, 0.0)}


@modulo("porton_doble", ["3 Calle de los Oficios", "8 La Ribera Baja", "1 Caravanas"],
        "Portón de dos hojas abierto (2,6 × 2,8 m) en un paño de tablas de 4 × 3,6 m.", tipo="muro")
def m_porton_doble(m, p, v):
    W, H = 4.0, 3.6
    caja_mm(m, (0.0, 0.45, -0.3), (W, H, -0.02), "madera", jit(MADERA_GRIS, 0.03), veta="larga")
    x = 0.12
    while x < W:
        if not (0.7 < x < 3.3):
            caja_mm(m, (x - 0.11, 0.47, -0.02), (x + 0.11, H - 0.1, 0.02), "madera", jit(MADERA_GRIS, 0.06), veta="larga")
        x += 0.24
    caja_mm(m, (0.7, 0.45, 0.022), (3.3, 0.45 + 2.8, 0.028), "hierro", OSCURO)
    caja_mm(m, (0.7, 3.25, -0.02), (3.3, H - 0.1, 0.02), "madera", jit(MADERA_GRIS, 0.04), veta="larga")
    caja_mm(m, (-0.02, -0.3, -0.32), (W + 0.02, 0.45, 0.04), "sillar", jit(SILLAR, 0.03), caras="eoasn")
    porton(m, 2.0, 2.6, 2.8, abierto=True, color=MADERA, z=0.03, y=0.45)
    ancla_p("puerta", (2.0, 0.0, 1.2))
    return {"huella": (0.0, -0.3, W, 0.0)}


@modulo("ventana_postigos", ["todos"], "Ventana de 0,7 × 1,0 m con postigos abiertos, jardinera y flores, en un paño de "
        "1,6 × 2,0 m (para cosido de fachadas).", tipo="muro")
def m_ventana_postigos(m, p, v):
    panel(m, 1.6, 2.0, REVOQUE_D, 0.3, zoc=0.0)
    flores_jardineras(v, [ventana(m, 0.8, 0.6, 0.0, 0.7, 1.0, VERDE_POSTIGO, jardinera=True)])
    return {"huella": (0.0, -0.3, 1.6, 0.0)}


@modulo("ventana_encendida", ["todos"], "Ventana encendida (cristal que da luz) de 0,6 × 0,95 m con postigos azules.",
        tipo="muro")
def m_ventana_encendida(m, p, v):
    panel(m, 1.6, 2.0, REVOQUE_A, 0.3, zoc=0.0)
    ventana(m, 0.8, 0.6, 0.0, 0.6, 0.95, AZUL_POSTIGO, luz=True)
    return {"huella": (0.0, -0.3, 1.6, 0.0)}


@modulo("hornacina", ["5 Pasajes Viejos"], "Paño de muro (1,8 × 3,4 m) con la hornacina de la muestra: arco, velas "
        "encendidas, figurilla y flores.", tipo="muro")
def m_hornacina(m, p, v):
    panel(m, 1.8, 3.4, REVOQUE_F)
    with sub((0.9, 0.0, 0.0)) as S:
        hornacina(S(m), S(p), S(v))
    hiedra(v, 1.6, 0.0, 2.6)
    return {"huella": (0.0, -0.4, 1.8, 0.0)}


# ================================================================ ESCALERAS Y RAMPAS (suben hacia −z desde z = 0)

@modulo("escalera_recta", ["4 Las Terrazas", "7 Barrio Alto", "5 Pasajes Viejos"],
        "Escalera recta de 6 peldaños (contrahuella 0,165 m, huella 0,32 m; sube 0,99 m en 1,92 m), 2,2 m de ancho, "
        "con zancas de sillería escalonadas.", tipo="escalera")
def m_escalera_recta(m, p, v):
    W = 2.2
    yt, zt = peldanos(m, 0.0, W, 0.0, 0.0, 6)
    for x0, x1 in ((-0.3, 0.0), (W, W + 0.3)):
        pretil_escalonado(m, x0, x1, 0.0, 0.0, 6, alto=0.12)
    for x in (-0.15, W + 0.15):
        mata(v, (x, 0.12, -0.2), 0.12, 8, 0.2)
    ancla_p("pie", (W / 2, 0.0, 0.5))
    ancla_p("cima", (W / 2, yt, zt - 0.4))
    return {"huella": (-0.3, zt, W + 0.3, 0.0), "sube": yt, "largo": -zt}


@modulo("escalera_rellano", ["4 Las Terrazas", "7 Barrio Alto (Calle del Árbol)"],
        "Escalera de dos tramos de 6 peldaños con rellano de 1,6 m (sube 1,98 m en 5,44 m), 2,4 m de ancho, pretiles de "
        "piedra, balaustrada en el rellano, farol y macetas.", tipo="escalera")
def m_escalera_rellano(m, p, v):
    W = 2.4
    y1, z1 = peldanos(m, 0.0, W, 0.0, 0.0, 6)
    caja_mm(m, (0.0, -0.3, z1 - 1.6), (W, y1, z1), "sillar", jit(SILLAR, 0.03), caras="eoas")       # el rellano
    for k in range(4):
        for j in range(3):
            caja_mm(p, (0.04 + k * 0.6, y1 - 0.01, z1 - 1.56 + j * 0.52), (0.6 + k * 0.6 - 0.02, y1 + 0.03,
                    z1 - 1.08 + j * 0.52), "sillar", jit(elige(PIEDRA), 0.05), jit_v=0.004)
    y2, z2 = peldanos(m, 0.0, W, z1 - 1.6, y1, 6)
    for x0, x1 in ((-0.35, 0.0), (W, W + 0.35)):
        pretil_escalonado(m, x0, x1, 0.0, 0.0, 6)
        pretil_escalonado(m, x0, x1, z1 - 1.6, y1, 6)
    for x0, x1 in ((-0.35, 0.0), (W, W + 0.35)):           # los costados del rellano, bajo la balaustrada
        caja_mm(m, (x0, -0.3, z1 - 1.6), (x1, y1 - 0.05, z1), "sillar", jit(SILLAR, 0.03), caras="eoasn")
    balaustres(m, z1 - 1.6, z1, -0.02, y1, eje="z", pilares=False)
    with sub((W + 0.35, 0.0, 0.0)) as S:
        balaustres(S(m), z1 - 1.6, z1, 0.0, y1, eje="z", pilares=False)
    farol_pie(m, p, 0.22, z1 - 1.4, y1)
    for z in (z1 - 0.3, z1 - 1.3):
        maceta(p, v, (W - 0.3, y1, z), 0.2 if z > z1 - 1 else 0.16, 0.28)
    for k in range(6):                                     # hierba en las juntas de los peldaños
        if AZ() < 0.6:
            mata(v, (U(0.1, W - 0.1), (k + 1) * 0.165, -k * 0.32 - 0.3), 0.06, 5, 0.12, ladeo=0.6)
    ancla_p("pie", (W / 2, 0.0, 0.5))
    ancla_p("rellano", (W / 2, y1, z1 - 0.8))
    ancla_p("cima", (W / 2, y2, z2 - 0.4))
    return {"huella": (-0.35, z2, W + 0.35, 0.0), "sube": y2, "largo": -z2}


def losas_en(P, rect, y_de, paso=0.42, jit_s=0.15, tonos=PIEDRA, densidad=1.0, musgo=0.1):
    """Losas de Voronoi (las de la muestra) dentro de un rectángulo (x0, z0, x1, z1), recortadas a sus bordes, a la cota
    y_de(x, z) (con su pendiente)."""
    x0, z0, x1, z1 = rect
    semillas = []
    x = x0 + paso * 0.5
    while x < x1:
        z = z0 + paso * 0.5
        while z < z1:
            semillas.append((x + U(-jit_s, jit_s), z + U(-jit_s, jit_s)))
            z += paso
        x += paso
    j = 0.0225
    for sd, poly in voronoi(semillas, None, 0.045):
        for eje, lim, sig in ((0, x0 + j, 1), (0, x1 - j, -1), (1, z0 + j, 1), (1, z1 - j, -1)):
            out = []
            for k in range(len(poly)):
                a, b = poly[k], poly[(k + 1) % len(poly)]
                da, db = (a[eje] - lim) * sig, (b[eje] - lim) * sig
                if da >= 0:
                    out.append(a)
                if (da >= 0) != (db >= 0):
                    f = da / (da - db)
                    out.append((a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f))
            poly = out
            if len(poly) < 3:
                break
        if len(poly) < 3 or AZ() > densidad:
            continue
        cx = sum(q[0] for q in poly) / len(poly)
        cz = sum(q[1] for q in poly) / len(poly)
        col = jit(elige(tonos), 0.08)
        if AZ() < musgo:
            col = mezcla(col, MUSGO, U(0.1, 0.3))
        dy = (y_de(cx + 0.1, cz) - y_de(cx - 0.1, cz)) / 0.2, (y_de(cx, cz + 0.1) - y_de(cx, cz - 0.1)) / 0.2
        losa(P, poly, y_de(cx, cz) - 0.05, U(0.035, 0.06), col, (dy[0] + U(-0.02, 0.02), dy[1] + U(-0.02, 0.02)))


def tierra_base(m, rect, y_de, paso=1.0, tono=TIERRA):
    """La tierra bajo las losas (se ve por las juntas), en una rejilla que sigue la cota."""
    x0, z0, x1, z1 = rect
    nx, nz = max(1, int(round((x1 - x0) / paso))), max(1, int(round((z1 - z0) / paso)))
    for i in range(nx):
        for j in range(nz):
            xa, xb = x0 + (x1 - x0) * i / nx, x0 + (x1 - x0) * (i + 1) / nx
            za, zb = z0 + (z1 - z0) * j / nz, z0 + (z1 - z0) * (j + 1) / nz
            pts = [Vector((xa, y_de(xa, za) - 0.04, za)), Vector((xa, y_de(xa, zb) - 0.04, zb)),
                   Vector((xb, y_de(xb, zb) - 0.04, zb)), Vector((xb, y_de(xb, za) - 0.04, za))]
            m.cara(pts, "tierra", jit(tono, 0.04))


@modulo("rampa", ["3 Calle de los Oficios", "8 Rampa de los Carros"],
        "Rampa empedrada de 2,6 × 6 m que sube 0,6 m (5,7°), con bordillos de sillería y costados de piedra.",
        tipo="escalera")
def m_rampa(m, p, v):
    W, L, H = 2.6, 6.0, 0.6
    def y_de(x, z):
        return H * min(1.0, max(0.0, -z / L))
    tierra_base(m, (0.0, -L, W, 0.0), y_de)
    losas_en(p, (0.2, -L, W - 0.2, 0.0), y_de, paso=0.45)
    for x in (0.1, W - 0.1):
        viga(m, (x, 0.08, 0.0), (x, H + 0.08, -L), 0.22, "sillar", jit(SILLAR, 0.04), alto=0.24)
    for x, h in ((0.0, (-1, 0, 0)), (W, (1, 0, 0))):
        cara_hacia(m, [(x, -0.3, 0.0), (x, -0.04, 0.0), (x, H - 0.04, -L), (x, -0.3, -L)], "sillar", jit(SILLAR, 0.03), h)
    ancla_p("pie", (W / 2, 0.0, 0.5))
    ancla_p("cima", (W / 2, H, -L - 0.4))
    return {"huella": (0.0, -L, W, 0.0), "sube": H, "largo": L}


@modulo("empedrado_4x4", ["todos"], "Losa de suelo de 4 × 4 m: losas irregulares de Voronoi (las de la muestra) sobre "
        "tierra; se repite sin costura visible.", tipo="suelo")
def m_empedrado(m, p, v):
    tierra_base(m, (0.0, -4.0, 4.0, 0.0), lambda x, z: 0.0, paso=2.0)
    losas_en(p, (0.0, -4.0, 4.0, 0.0), lambda x, z: 0.0, paso=0.42)
    return {"huella": (0.0, -4.0, 4.0, 0.0)}


@modulo("losas_plaza_4x4", ["2 Plaza del Tapiz", "7 Barrio Alto"], "Losa de suelo de 4 × 4 m: losas rectangulares a "
        "matajunta (las de la plaza del barrio).", tipo="suelo")
def m_losas_plaza(m, p, v):
    tierra_base(m, (0.0, -4.0, 4.0, 0.0), lambda x, z: 0.0, paso=2.0)
    j = 0.0225
    tonos = ((0.74, 0.70, 0.64), (0.70, 0.67, 0.62), (0.78, 0.73, 0.66), (0.68, 0.64, 0.58))
    z = -4.0
    while z < -0.05:
        h = CH((0.5, 0.57, 0.66))
        z1 = min(z + h, 0.0)
        x = -U(0.0, 0.6)
        while x < 4.0:
            w = U(0.6, 1.1)
            x0, x1 = max(x, 0.0), min(x + w, 4.0)
            x += w
            if x1 - x0 < 0.15:
                continue
            poly = [(x0 + j, z + j), (x1 - j, z + j), (x1 - j, z1 - j), (x0 + j, z1 - j)]
            col = jit(elige(tonos), 0.07)
            if AZ() < 0.1:
                col = mezcla(col, MUSGO, U(0.1, 0.25))
            losa(p, poly, -0.05, U(0.035, 0.055), col, (U(-0.015, 0.015), U(-0.015, 0.015)))
        z = z1
    return {"huella": (0.0, -4.0, 4.0, 0.0)}


# ================================================================ BALCONES Y TEJADOS

@modulo("balcon_madera", ["4 Las Terrazas", "5 Pasajes Viejos"],
        "Balcón volado de madera (2,0 × 0,8 m) con ménsulas, balaustres de tabla, puerta-ventana y macetas; se pega a "
        "una fachada con el suelo a ≥ 2,6 m.", tipo="muro")
def m_balcon_madera(m, p, v):
    panel(m, 2.6, 2.6, REVOQUE_D, 0.3, zoc=0.0)
    y = 0.3
    caja_mm(m, (0.3, y, 0.0), (2.3, y + 0.08, 0.8), "madera", MADERA)
    for k in range(10):
        xx = 0.35 + k * 0.2
        caja_mm(m, (xx - 0.03, y + 0.08, 0.74), (xx + 0.03, y + 0.92, 0.79), "madera", MADERA_OSC)
    caja_mm(m, (0.28, y + 0.9, -0.02), (2.32, y + 0.98, 0.82), "madera", MADERA)
    for xx in (0.32, 2.28):
        caja_mm(m, (xx - 0.04, y + 0.08, 0.0), (xx + 0.04, y + 0.92, 0.8), "madera", MADERA_OSC)
        viga(m, (xx, y - 0.7, 0.04), (xx, y - 0.04, 0.7), 0.13, "madera", MADERA_OSC, alto=0.13)
    ventana(m, 1.3, y + 0.12, 0.0, 0.85, 1.75, VERDE_POSTIGO)
    for k in range(3):
        maceta(p, v, (0.6 + k * 0.7, y + 0.08, 0.45), 0.13, 0.18)
    return {"huella": (0.0, -0.3, 2.6, 0.8), "nota": "y = 0 del módulo = suelo del balcón − 0,3 m"}


@modulo("balcon_hierro", ["7 Barrio Alto de las Raíces", "2 Plaza del Tapiz"],
        "Balcón de losa de piedra con moldura y baranda de barrotes de hierro (2,6 × 0,75 m) y puerta-ventana.",
        tipo="muro")
def m_balcon_hierro(m, p, v):
    panel(m, 3.2, 2.8, REVOQUE_C, 0.3, zoc=0.0)
    balcon_hierro(m, p, v, 0.3, 2.9, 0.4, 0.75)
    ventana(m, 1.6, 0.45, 0.0, 0.85, 2.0, AZUL_POSTIGO, luz=True)
    maceta(p, v, (0.65, 0.4, 0.45), 0.15, 0.22)
    return {"huella": (0.0, -0.3, 3.2, 0.75)}


@modulo("tejado_dos_aguas", ["todos"], "Tejado suelto a dos aguas de teja (cubre 6 × 5 m, alero de 0,45 m, cumbrera a "
        "2,2 m sobre el alero) con hastiales de revoque; para cuerpos añadidos.", tipo="muro")
def m_tejado_dos_aguas(m, p, v):
    W, F, h = 6.0, 5.0, 2.2
    za, zb = 0.45, -F - 0.45
    zr = (za + zb) / 2
    faldon(m, (-0.45, 0.0, za), (W + 0.45, 0.0, za), (0, h, zr - za), TEJA, musgo=0.3)
    faldon(m, (W + 0.45, 0.0, zb), (-0.45, 0.0, zb), (0, h, zr - zb), TEJA, musgo=0.1)
    cumbrera(m, (-0.45, h + 0.02, zr), (W + 0.45, h + 0.02, zr))
    for xh, s in ((0.0, -1), (W, 1)):
        pts = [Vector((xh, 0.0, 0.0)), Vector((xh, h - 0.05, zr)), Vector((xh, 0.0, -F))]
        m.cara(list(reversed(pts)) if s > 0 else pts, "revoque", REVOQUE_D)
        viga(m, (xh + s * 0.42, -0.08, za), (xh + s * 0.42, h + 0.06, zr), 0.06, "madera", MADERA_OSC, alto=0.22)
    return {"huella": (-0.45, zb, W + 0.45, za), "nota": "y = 0 = la línea del alero (encima del muro)"}


@modulo("tejado_alero_largo", ["3 Calle de los Oficios", "1 Caravanas", "8 La Ribera Baja"],
        "Tejadillo de un agua con alero largo (5 × 2 m) sobre canes y tornapuntas, pegado a un muro (de 3,2 m a 2,6 m: "
        "se pasa debajo).", tipo="muro")
def m_tejado_alero_largo(m, p, v):
    W, D = 5.0, 2.0
    panel(m, W, 3.6, REVOQUE_B, 0.3)
    faldon(m, (-0.1, 2.6, D), (W + 0.1, 2.6, D), (0, 0.65, -D), TEJA, musgo=0.25)
    for k in range(6):
        x = 0.25 + k * (W - 0.5) / 5
        viga(m, (x, 3.2, 0.0), (x, 2.55, D - 0.05), 0.1, "madera", MADERA_OSC, alto=0.13)
        if k in (0, 5):
            viga(m, (x, 1.9, 0.02), (x, 2.75, 1.25), 0.1, "madera", MADERA_OSC)
    return {"huella": (0.0, -0.3, W, D)}


@modulo("tejado_soportal", ["1 Caravanas", "2 Plaza (Calle Mayor)", "6 Patio del Cuervo"],
        "Porche de madera: tejado de un agua sobre pies derechos con zapatas (6 × 2,4 m; libre 2,55 m), para delante "
        "de una fachada.", tipo="muro")
def m_tejado_soportal(m, p, v):
    W, D = 6.0, 2.4
    for x in (0.15, W / 2, W - 0.15):
        viga(m, (x, 0.0, D - 0.15), (x, 2.55, D - 0.15), 0.18, "madera", MADERA_OSC)
        caja(m, (x, 0.06, D - 0.15), (0.3, 0.12, 0.3), "sillar", SILLAR)
        caja(m, (x, 2.5, D - 0.15), (0.7, 0.12, 0.2), "madera", MADERA_OSC, veta="larga")
    viga(m, (-0.1, 2.65, D - 0.15), (W + 0.1, 2.65, D - 0.15), 0.2, "madera", MADERA_OSC, alto=0.2)
    for k in range(7):
        x = 0.1 + k * (W - 0.2) / 6
        viga(m, (x, 3.2, 0.0), (x, 2.75, D + 0.3), 0.1, "madera", MADERA_OSC, alto=0.12)
    faldon(m, (-0.2, 2.8, D + 0.35), (W + 0.2, 2.8, D + 0.35), (0, 0.55, -D - 0.35), TEJA, musgo=0.2)
    caja_mm(m, (-0.2, 3.2, -0.05), (W + 0.2, 3.36, 0.06), "madera", MADERA_OSC)
    for x in (0.15, W / 2, W - 0.15):
        choque((x, 1.2, D - 0.15), (0.3, 2.4, 0.3), 0.0, "pie")
    return {"huella": (0.0, 0.0, W, D + 0.35), "nota": "z = 0 = la fachada a la que se arrima (sin muro propio)"}


# ================================================================ SOPORTALES, CORREDORES Y PASOS BAJO CASA

@modulo("soportal_arcos", ["2 Plaza del Tapiz (lonja)", "2 Calle Mayor"],
        "Soportal de piedra de dos arcos de medio punto sobre columnas (fondo 2,4 m; clave a 4,2 m) con piso de "
        "entramado encima y tejado de alero (7,2 × 6 m).")
def m_soportal_arcos(m, p, v):
    W, F, fs = 7.2, 6.0, 2.4
    yb, y1 = 4.7, 7.3
    caja_mm(m, (0.0, -0.6, -F), (W, 0.12, 0.05), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (0.1, 0.12, -F), (W - 0.1, yb, -fs), "revoque", REVOQUE_F)
    puerta_calle(m, p, W * 0.3, 1.1, 2.4, "dintel", MADERA, z=-fs, y=0.12)
    ventana(m, W * 0.72, 1.2, -fs, 0.8, 1.1, VERDE_POSTIGO, luz=True)
    cols = (0.3, W / 2, W - 0.3)
    for uu in cols:                                         # columnas adosadas a los machones (asoman al frente)
        cilindro(m, (uu, 0.12, 0.06), [(0, 0.26), (0.14, 0.26), (0.18, 0.19), (2.55, 0.18), (2.6, 0.26), (2.72, 0.28)],
                 10, "sillar", jit(SILLAR, 0.04))
        cilindro(m, (uu, 0.12, -fs + 0.3), [(0, 0.24), (2.72, 0.24)], 8, "sillar", jit(SILLAR, 0.04))
    luz = (cols[1] - cols[0]) - 0.44
    semi = luz / 2
    ys = 2.84
    for k in range(2):                                     # cada arco llena justo de columna a columna (sin solapes)
        with sub((cols[k], 0.0, 0.0)) as S:
            arco_muro(S(m), cols[k + 1] - cols[k], yb, 0.5, luz, ys, mat="sillar", col=SILLAR, col_dov=SILLAR)
    caja_mm(m, (0.0, 0.0, -0.5), (cols[0], yb, 0.0), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (cols[2], 0.0, -0.5), (W, yb, 0.0), "sillar", jit(SILLAR, 0.03))
    caja_mm(m, (0.0, ys + semi, -fs), (W, yb, -0.5), "madera", MADERA_OSC, caras="b")       # techo del soportal
    for k in range(5):
        viga(m, (0.2, yb - 0.12, -0.6 - k * 0.42), (W - 0.2, yb - 0.12, -0.6 - k * 0.42), 0.14, "madera", MADERA_OSC)
    caja_mm(m, (0.1, 0.12, -fs), (W - 0.1, 0.14, 0.0), "sillar", jit(SILLAR, 0.02), caras="a")
    vuelo_y_mensulas(m, W, yb, 0.4, [0.3, W / 2, W - 0.3])
    entramado(m, 0.0, W, yb, y1, 0.4, [1.2, 2.4, 3.6, 4.8, 6.0], REVOQUE_F, MADERA_OSC, cruces=(0, 5))
    caja_mm(m, (0.0, yb, -F), (0.12, y1, 0.28), "revoque", REVOQUE_F)
    caja_mm(m, (W - 0.12, yb, -F), (W, y1, 0.28), "revoque", REVOQUE_F)
    caja_mm(m, (0.12, yb, -F), (W - 0.12, y1, 0.3), "revoque", REVOQUE_F, caras="b")
    fl = [ventana(m, 1.8, yb + 0.75, 0.44, 0.6, 0.95, VERDE_POSTIGO, jardinera=True),
          ventana(m, 5.4, yb + 0.75, 0.44, 0.6, 0.95, VERDE_POSTIGO, luz=True)]
    flores_jardineras(v, fl)
    yr = y1 + 2.3
    za, zb = 1.0, -F - 0.4
    zr = (za + zb) / 2
    faldon(m, (-0.4, y1 - 0.05, za), (W + 0.4, y1 - 0.05, za), (0, yr - y1 + 0.05, zr - za), TEJA, musgo=0.3)
    faldon(m, (W + 0.4, y1 - 0.05, zb), (-0.4, y1 - 0.05, zb), (0, yr - y1 + 0.05, zr - zb), TEJA, musgo=0.1)
    cumbrera(m, (-0.4, yr + 0.02, zr), (W + 0.4, yr + 0.02, zr))
    for xh, s in ((0.0, -1), (W, 1)):
        pts = [Vector((xh, y1, 0.4)), Vector((xh, yr - 0.05, zr)), Vector((xh, y1, -F))]
        m.cara(list(reversed(pts)) if s > 0 else pts, "revoque", REVOQUE_F)
    farol_pared(m, (W / 2, 3.6, -fs + 0.02), (0.0, 0.0, 1.0))
    saco(p, (W - 1.0, 0.14, -fs + 0.35), 30)
    fardo(p, (W - 1.6, 0.36, -fs + 0.4), (0.8, 0.44, 0.5), 5)
    for uu in cols:
        choque((uu, 1.4, -0.25), (0.56, 2.8, 0.56), 0.0, "columna")
    choque((W / 2, 1.5, -(F + fs) / 2), (W, 3.0, F - fs), 0.0, "casa")
    ancla_p("puerta", (W * 0.3, 0.12, -fs + 0.9))
    return {"huella": (0.0, -F, W, 0.0), "nota": "soportal andable: z de −2,4 a 0, suelo a +0,12"}


@modulo("corredor_cubierto", ["5 Pasajes Viejos", "6 Patio del Cuervo"],
        "Corredor cubierto de madera (tramo de 4 m que se repite en x; 2,4 m de ancho, libre 2,5 m): pies derechos con "
        "zapatas, carreras, tirantes y tejadillo a dos aguas.", tipo="muro")
def m_corredor_cubierto(m, p, v):
    W, D, alto = 4.0, 2.4, 2.5
    for x in (0.1, 2.1):
        for z in (-0.1, -D + 0.1):
            viga(m, (x, 0.0, z), (x, alto, z), 0.16, "madera", MADERA_OSC)
            caja(m, (x, 0.05, z), (0.28, 0.1, 0.28), "sillar", SILLAR)
            caja(m, (x, alto - 0.04, z), (0.6, 0.1, 0.18), "madera", MADERA_OSC, veta="larga")
        viga(m, (x, alto + 0.08, 0.1), (x, alto + 0.08, -D - 0.1), 0.14, "madera", MADERA_OSC, alto=0.16)
        viga(m, (x, alto + 0.12, -D / 2), (x, alto + 0.62, -D / 2), 0.1, "madera", MADERA_OSC)
    for z in (-0.1, -D + 0.1):
        viga(m, (0.0, alto + 0.08, z), (W, alto + 0.08, z), 0.16, "madera", MADERA_OSC, alto=0.18)
    faldon(m, (0.0, alto + 0.18, 0.35), (W, alto + 0.18, 0.35), (0, 0.55, -D / 2 - 0.35), TEJA, musgo=0.35)
    faldon(m, (W, alto + 0.18, -D - 0.35), (0.0, alto + 0.18, -D - 0.35), (0, 0.55, D / 2 + 0.35), TEJA, musgo=0.2)
    cumbrera(m, (0.0, alto + 0.75, -D / 2), (W, alto + 0.75, -D / 2))
    for x in (0.1, 2.1):
        for z in (-0.1, -D + 0.1):
            choque((x, 1.25, z), (0.2, 2.5, 0.2), 0.0, "pie")
    return {"huella": (0.0, -D, W, 0.0), "nota": "repetir cada 4 m en x; el siguiente tramo pone sus pies a x+0,1"}


@modulo("paso_bajo_casa", ["5 Pasajes Viejos (Paso Cubierto de la Botica)"],
        "Paso bajo casa: bóveda rebajada de 2,8 m de luz (clave a 3,0 m) que atraviesa 5 m de casa, con piso de "
        "entramado volado encima y tejado; farol dentro.")
def m_paso_bajo_casa(m, p, v):
    W, F, yb, y1 = 5.6, 5.0, 3.6, 6.05
    arco_muro(m, W, yb, F, 2.8, 2.35, flecha=0.65, mat="revoque", col=REVOQUE_F, col_dov=SILLAR)
    caja_mm(m, (-0.02, -0.3, -F), (1.4, 0.45, 0.04), "sillar", jit(SILLAR, 0.03), caras="eoasn")
    caja_mm(m, (4.2, -0.3, -F), (W + 0.02, 0.45, 0.04), "sillar", jit(SILLAR, 0.03), caras="eoasn")
    vuelo_y_mensulas(m, W, yb, 0.45, [0.3, W - 0.3])
    entramado(m, 0.0, W, yb, y1, 0.45, [1.1, 2.8, 4.5], REVOQUE_F, MADERA_OSC, cruces=(1, 2))
    caja_mm(m, (0.0, yb, -F), (0.12, y1, 0.33), "revoque", REVOQUE_F)
    caja_mm(m, (W - 0.12, yb, -F), (W, y1, 0.33), "revoque", REVOQUE_F)
    caja_mm(m, (0.12, yb, -F), (W - 0.12, y1, 0.35), "revoque", REVOQUE_F, caras="bn")
    flores_jardineras(v, [ventana(m, 1.9, yb + 0.7, 0.49, 0.55, 0.9, OCRE_POSTIGO, jardinera=True)])
    ventana(m, 3.7, yb + 0.7, 0.49, 0.55, 0.9, OCRE_POSTIGO, luz=True)
    yr = y1 + 2.4
    za, zb = 1.05, -F - 0.45
    zr = (za + zb) / 2
    faldon(m, (-0.45, y1 - 0.05, za), (W + 0.45, y1 - 0.05, za), (0, yr - y1 + 0.05, zr - za), TEJA, musgo=0.5)
    faldon(m, (W + 0.45, y1 - 0.05, zb), (-0.45, y1 - 0.05, zb), (0, yr - y1 + 0.05, zr - zb), TEJA, musgo=0.3)
    cumbrera(m, (-0.45, yr + 0.02, zr), (W + 0.45, yr + 0.02, zr))
    for xh, s in ((0.0, -1), (W, 1)):
        pts = [Vector((xh, y1, 0.45)), Vector((xh, yr - 0.05, zr)), Vector((xh, y1, -F))]
        m.cara(list(reversed(pts)) if s > 0 else pts, "revoque", REVOQUE_F)
    chimenea(m, 4.6, zr - 0.6, yr - 1.2, yr + 0.5)
    farol_pared(m, (1.41, 2.15, -F / 2), (1.0, 0.0, 0.0))
    for k in range(7):                                       # vigas a la vista bajo la bóveda (de lado a lado)
        z = -0.35 - k * (F - 0.7) / 6
        viga(m, (1.4, 2.32, z), (4.2, 2.32, z), 0.12, "madera", MADERA_OSC, alto=0.14)
    hiedra(v, 0.6, 0.0, 2.8)
    choque((0.7, 1.5, -F / 2), (1.4, 3.0, F), 0.0, "pila_o")
    choque((W - 0.7, 1.5, -F / 2), (1.4, 3.0, F), 0.0, "pila_e")
    ancla_p("paso_sur", (W / 2, 0.0, 0.6))
    ancla_p("paso_norte", (W / 2, 0.0, -F - 0.6))
    return {"huella": (0.0, -F, W, 0.0), "nota": "el paso (x 1,4-4,2) es andable; techo libre 2,32 m bajo las vigas"}


# ================================================================ BALAUSTRADAS, MUROS Y MURALLA

@modulo("balaustrada", ["4 Las Terrazas", "7 Barrio Alto (miradores)"],
        "Balaustrada de piedra de 3 m (1,0 m de alto): plinto, balaustres torneados, pasamanos y pilares; se repite en "
        "x.", tipo="muro")
def m_balaustrada(m, p, v):
    balaustres(m, 0.0, 3.0, 0.0, 0.0)
    choque((1.5, 0.5, -0.15), (3.0, 1.0, 0.36), 0.0, "pretil")
    return {"huella": (0.0, -0.36, 3.0, 0.05)}


@modulo("muro_terraza", ["4 Las Terrazas", "7 Barrio Alto"],
        "Muro de contención de una terraza: sillería de 5 m × 2,4 m con albardilla, mechinales, plantas que cuelgan y "
        "flores en las juntas (la terraza alta queda detrás, a +2,4).", tipo="muro")
def m_muro_terraza(m, p, v):
    W, H = 5.0, 2.4
    caja_mm(m, (0.0, -0.3, -0.9), (W, H, 0.0), "sillar", jit(MURALLA, 0.02))
    for k in range(int(W / 1.0)):                           # el talud de la base
        u0 = k * 1.0
        m.cara([Vector((u0, -0.05, 0.3)), Vector((u0 + 1.0, -0.05, 0.3)), Vector((u0 + 1.0, 0.6, 0.0)),
                Vector((u0, 0.6, 0.0))], "sillar", jit(MURALLA, 0.04))
    caja_mm(m, (-0.04, H, -0.95), (W + 0.04, H + 0.14, 0.08), "sillar", jit(SILLAR, 0.05))
    for x in (0.9, 2.5, 4.1):
        caja_mm(m, (x - 0.07, 0.9, 0.002), (x + 0.07, 1.04, 0.006), "hierro", OSCURO)
    for k in range(9):                                      # lo que cuelga de arriba
        x = 0.3 + k * 0.55 + U(-0.1, 0.1)
        hojas(v, (x, H + 0.05, 0.12), 0.32, 18, HOJA, 0.08, flex=0.45, aplastar=0.6, hacia=(0, -0.3, 1))
        if AZ() < 0.55:
            hojas(v, (x + U(-0.1, 0.1), H - U(0.4, 0.9), 0.08), 0.22, 10, HOJA, 0.07, flex=0.5, aplastar=1.4,
                  hacia=(0, 0, 1))
    for k in range(4):
        mata_flores(v, (U(0.3, W - 0.3), U(0.8, 1.9), 0.02), 0.1, CH(FLORES), 5, 0.14)
    pie_matas(v, 0.0, W, 0.32, frac=0.5)
    choque((W / 2, H / 2, -0.45), (W, H, 0.9), 0.0, "muro")
    return {"huella": (0.0, -0.9, W, 0.3), "sube": H}


@modulo("muralla_almena", ["muralla (1, 7, 8)"],
        "Tramo de muralla de 6 m: 7 m de alto y 2,4 m de grueso, talud, dos arcos ciegos de descarga en la cara de "
        "dentro (la que ve la cámara), adarve a 7 m y parapeto almenado hacia fuera.", tipo="muro")
def m_muralla_almena(m, p, v):
    W, H, g = 6.0, 7.0, 2.4
    caja_mm(m, (0.0, -0.6, -g), (W, H, 0.0), "sillar", jit(MURALLA, 0.02))
    for k in range(int(W / 1.2)):
        u0 = k * 1.2
        m.cara([Vector((u0, 0.0, 0.5)), Vector((u0 + 1.2, 0.0, 0.5)), Vector((u0 + 1.2, 1.1, 0.0)), Vector((u0, 1.1, 0.0))],
               "sillar", jit((0.80, 0.75, 0.66), 0.04))
    for cu in (1.5, 4.5):                                   # arcos ciegos (resaltan 12 cm del muro)
        with sub((cu - 1.35, 0.0, 0.12)) as S:
            arco_muro(S(m), 2.7, 4.6, 0.12, 2.1, 3.0, flecha=0.55, mat="sillar", col=mezcla(MURALLA, (0.6, 0.56, 0.5), 0.15))
    caja_mm(m, (-0.02, H - 0.25, -0.15), (W + 0.02, H, 0.12), "sillar", jit(SILLAR, 0.04))      # bocel del adarve
    caja_mm(m, (0.0, H, -g), (W, H + 1.0, -g + 0.6), "sillar", jit(MURALLA, 0.03))              # parapeto exterior
    x = 0.15
    while x + 0.9 <= W:
        caja_mm(m, (x, H + 1.0, -g), (x + 0.9, H + 1.9, -g + 0.55), "sillar", jit(SILLAR, 0.05), jit_v=0.01)
        x += 1.5
    caja_mm(m, (0.0, H, -0.35), (W, H + 0.35, 0.0), "sillar", jit(MURALLA, 0.03))               # pretil bajo de dentro
    for k in range(5):
        mata(v, (U(0.2, W - 0.2), H, -U(0.6, 1.7)), 0.15, 10, 0.25)
    hiedra(v, 5.2, 0.0, 4.5)
    pie_matas(v, 0.0, W, 0.5, frac=0.5)
    choque((W / 2, H / 2, -g / 2), (W, H, g), 0.0, "muralla")
    ancla_p("adarve", (W / 2, H, -1.2))
    return {"huella": (0.0, -g, W, 0.5), "sube": H}


@modulo("torre_muralla", ["8 Ribera (ronda)", "1 Puerta del Sur", "muralla"],
        "Torre cuadrada de muralla (4,6 × 4,6 m, 11 m hasta las almenas) con saeteras, puerta en arco, matacán y "
        "chapitel de pizarra (cumbre a 15,5 m).")
def m_torre_muralla(m, p, v):
    W, H = 4.6, 11.0
    caja_mm(m, (0.0, -0.6, -W), (W, H, 0.0), "sillar", jit(MURALLA, 0.02))
    for y in (0.0, 3.6, 7.2):                               # impostas
        caja_mm(m, (-0.06, y + 3.4, -W - 0.06), (W + 0.06, y + 3.55, 0.06), "sillar", jit(SILLAR, 0.04))
    for y in (4.4, 8.0):                                    # saeteras
        caja_mm(m, (W / 2 - 0.06, y, 0.002), (W / 2 + 0.06, y + 1.0, 0.006), "hierro", OSCURO)
        caja_mm(m, (W + 0.002, y, -W / 2 - 0.06), (W + 0.006, y + 1.0, -W / 2 + 0.06), "hierro", OSCURO)
    puerta_calle(m, p, W / 2, 1.2, 2.45, "arco", (0.36, 0.26, 0.20), marco_col=SILLAR)
    caja_mm(m, (-0.3, H, -W - 0.3), (W + 0.3, H + 0.9, 0.3), "sillar", jit(MURALLA, 0.03))     # el parapeto volado
    for k in range(9):
        caja_mm(m, (0.1 + k * 0.5, H - 0.45, 0.0), (0.35 + k * 0.5, H, 0.3), "sillar", jit(SILLAR, 0.05))
    for lado in range(4):
        with sub((W / 2, 0.0, -W / 2), 90.0 * lado) as S:
            s = S(m)
            x = -W / 2 - 0.3
            while x + 0.7 <= W / 2 + 0.3:
                caja_mm(s, (x, H + 0.9, W / 2 + 0.05), (x + 0.7, H + 1.65, W / 2 + 0.3), "sillar", jit(SILLAR, 0.05),
                        jit_v=0.01)
                x += 1.25
    caja_mm(m, (0.5, H + 0.9, -W + 0.5), (W - 0.5, H + 2.0, -0.5), "sillar", jit(MURALLA, 0.03))
    cono(m, (W / 2, H + 2.0, -W / 2), 2.6, 3.6, 4, "tejas", PIZARRA[0], rot=R(45))
    cilindro(m, (W / 2, H + 5.55, -W / 2), [(0, 0.05), (0.6, 0.03)], 6, "hierro", HIERRO)
    farol_pared(m, (W / 2 + 1.0, 2.9, 0.02), (0.0, 0.0, 1.0))
    hiedra(v, 0.5, 0.0, 3.8)
    choque((W / 2, 1.5, -W / 2), (W, 3.0, W), 0.0, "torre")
    ancla_p("puerta", (W / 2, 0.0, 0.9))
    return {"huella": (0.0, -W, W, 0.0)}


# ================================================================ FUENTE Y TOLDOS

@modulo("fuente_plaza", ["2 Plaza del Tapiz"],
        "Fuente de la plaza (propuesta del aspecto «dorado» de la referencia, adaptado a la paleta): grada y pila "
        "octogonales de sillería (Ø 4,6 m), fuste con dos tazas de latón dorado, remate de piña y cortinas de agua.",
        tipo="atrezo")
def m_fuente_plaza(m, p, v):
    f8 = math.pi / 8
    cilindro(m, (0, -0.2, 0), [(0, 2.3), (0.35, 2.3)], 8, "sillar", jit(SILLAR, 0.03), suave=False, fase=f8)
    cilindro(m, (0, 0.15, 0), [(0, 1.98), (0.5, 1.98), (0.55, 2.06), (0.66, 2.06), (0.66, 1.76), (0.2, 1.76)], 8, "sillar",
             jit(PIEDRA_NOBLE, 0.03), suave=False, fase=f8, tapa_arriba=False)
    agua = [Vector((math.cos(f8 + k * math.pi / 4) * 1.77, 0.62, math.sin(f8 + k * math.pi / 4) * 1.77)) for k in range(8)]
    cara_hacia(m, agua, "hierro", AGUA, (0, 1, 0))
    cilindro(m, (0, 0.6, 0), [(0, 0.42), (0.18, 0.42), (0.26, 0.3), (1.0, 0.24), (1.12, 0.32)], 8, "sillar",
             jit(PIEDRA_NOBLE, 0.03), fase=f8)
    cilindro(m, (0, 1.72, 0), [(0, 0.2), (0.18, 0.75), (0.3, 1.05), (0.36, 1.1), (0.38, 1.0), (0.3, 0.9)], 16, "barro",
             LATON, tapa_arriba=True)
    cilindro(m, (0, 2.02, 0), [(0, 0.13), (0.55, 0.1), (0.62, 0.14)], 8, "sillar", jit(PIEDRA_NOBLE, 0.03))
    cilindro(m, (0, 2.6, 0), [(0, 0.12), (0.12, 0.45), (0.2, 0.62), (0.25, 0.64), (0.27, 0.56)], 14, "barro", LATON)
    for y, r in ((2.035, 0.92), (2.875, 0.57)):            # el agua de las tazas
        cara_hacia(m, [Vector((math.cos(k * math.tau / 12) * r, y, math.sin(k * math.tau / 12) * r)) for k in range(12)],
                   "hierro", AGUA, (0, 1, 0))
    cilindro(m, (0, 2.82, 0), [(0, 0.08), (0.1, 0.14), (0.28, 0.12), (0.42, 0.05), (0.48, 0.0)], 8, "barro",
             mezcla(LATON, (1.0, 0.9, 0.6), 0.2))
    for r, y0, y1, n in ((1.1, 0.63, 2.05, 16), (0.64, 2.04, 2.86, 10)):   # los chorros que caen del borde de las tazas
        for k in range(n):
            a = (k + 0.5) * math.tau / n
            d = Vector((math.cos(a), 0.0, math.sin(a)))
            viga(m, d * r + Vector((0, y1, 0)), d * (r + 0.12) + Vector((0, y0, 0)), 0.035, "hierro", AGUA_CLARA)
    for k in range(4):                                     # caños de latón en el fuste
        a = k * math.pi / 2 + f8
        d = Vector((math.cos(a), 0, math.sin(a)))
        viga(m, Vector((0, 1.15, 0)) + d * 0.25, Vector((0, 1.08, 0)) + d * 0.65, 0.05, "barro", LATON)
        viga(m, Vector((0, 1.08, 0)) + d * 0.66, Vector((0, 0.64, 0)) + d * 0.9, 0.04, "hierro", AGUA_CLARA)
    for k in range(6):
        a = U(0, math.tau)
        mata(v, (math.cos(a) * 2.25, 0.15, math.sin(a) * 2.25), 0.1, 6, 0.16)
    choque((0, 0.45, 0), (3.9, 0.9, 1.6), 0.0, "pila_a")
    choque((0, 0.45, 0), (1.6, 0.9, 3.9), 0.0, "pila_b")
    choque((0, 0.45, 0), (3.2, 0.9, 3.2), 45.0, "pila_c")
    return {"huella": (-2.3, -2.3, 2.3, 2.3)}


def lona_rayas(M, esquinas, n, colores, comba=0.08, doble=True):
    """Una lona a rayas entre cuatro esquinas (a, b del borde «u» y d, c del otro), en n franjas, con algo de comba."""
    a, b, c, d = [Vector(q) for q in esquinas]
    for k in range(n):
        t0, t1 = k / n, (k + 1) / n
        p0, p1 = a.lerp(b, t0), a.lerp(b, t1)
        q0, q1 = d.lerp(c, t0), d.lerp(c, t1)
        caida = Vector((0, -comba, 0))
        pts = [p0, p1, (p1 + q1) / 2 + caida, (p0 + q0) / 2 + caida]
        pts2 = [(p0 + q0) / 2 + caida, (p1 + q1) / 2 + caida, q1, q0]
        col = jit(colores[k % len(colores)], 0.03)
        for pp in (pts, pts2):
            M.cara(pp, "tela", col)
            if doble:
                M.cara(list(reversed(pp)), "tela", mezcla(col, (0.3, 0.3, 0.3), 0.25))


@modulo("toldo_mercado", ["2 Gran Mercado", "6 Patio del Cuervo (Feria)"],
        "Puesto de mercado con toldo a dos aguas de lona a rayas (2,8 × 2,2 m; borde a 2,3 m, cumbrera a 2,85 m) sobre "
        "cuatro postes, mesa de caballetes con fruta, coles y cestas.", tipo="atrezo")
def m_toldo_mercado(m, p, v):
    W, D = 2.8, 2.2
    x0, z0 = -W / 2, -D / 2
    for x in (x0 + 0.08, -x0 - 0.08):
        for z in (z0 + 0.08, -z0 - 0.08):
            viga(m, (x, 0.0, z), (x, 2.4, z), 0.08, "madera", MADERA_OSC)
        viga(m, (x, 2.85, 0.0), (x, 2.4, -z0 - 0.08), 0.06, "madera", MADERA_OSC)
        viga(m, (x, 2.85, 0.0), (x, 2.4, z0 + 0.08), 0.06, "madera", MADERA_OSC)
    viga(m, (x0 - 0.1, 2.88, 0.0), (-x0 + 0.1, 2.88, 0.0), 0.06, "madera", MADERA_OSC)
    cols = [CH([TELAS[2], TELAS[1], TELAS[4]]), TELAS[0]]
    lona_rayas(m, [(x0 - 0.15, 2.32, -z0 + 0.2), (-x0 + 0.15, 2.32, -z0 + 0.2), (-x0 + 0.15, 2.9, 0.0),
                   (x0 - 0.15, 2.9, 0.0)], 9, cols, comba=0.04)
    lona_rayas(m, [(-x0 + 0.15, 2.32, z0 - 0.2), (x0 - 0.15, 2.32, z0 - 0.2), (x0 - 0.15, 2.9, 0.0),
                   (-x0 + 0.15, 2.9, 0.0)], 9, cols, comba=0.04)
    for zz in (-z0 + 0.2, z0 - 0.2):                        # faldón colgante
        for k in range(9):
            xa = x0 - 0.15 + (W + 0.3) * k / 9
            xb = xa + (W + 0.3) / 9
            pts = [Vector((xa, 2.32, zz)), Vector((xb, 2.32, zz)), Vector((xb, 2.12, zz)), Vector((xa, 2.12, zz))]
            col = jit(cols[k % 2], 0.03)
            m.cara(pts, "tela", col)
            m.cara(list(reversed(pts)), "tela", col)
    y = mesa(p, (x0 + 0.15, 0.05, W - 0.3, 0.8), 0.0)
    for k, tipo in enumerate(("manzanas", "peras", "coles", "cebollas")):
        cx = x0 + 0.55 + k * 0.58
        caja(p, (cx, y + 0.08, 0.45), (0.46, 0.16, 0.5), "madera", jit(MADERA_GRIS, 0.06), rot=R(U(-5, 5)), veta="larga")
        frutas(p, v, (cx, y + 0.1, 0.45), 0.22, tipo)
    cesta_pan(p, (-x0 - 0.45, 0.0, -0.4), 0.22)
    cajita(p, (x0 + 0.5, 0.0, -0.55), (0.6, 0.45, 0.5), yaw=8)
    saco(p, (x0 + 1.2, 0.0, -0.6), 20)
    choque((0, 0.45, 0.45), (W - 0.3, 0.9, 0.8), 0.0, "mesa")
    ancla_p("vendedor", (0.0, 0.0, -0.55))
    return {"huella": (x0, z0, -x0, -z0)}


@modulo("toldo_vela", ["2 Gran Mercado", "4 Las Terrazas (patios)", "6 Patio del Cuervo"],
        "Toldo de vela a rayas tendido entre cuatro mástiles (3,6 × 3,0 m; de 3,0 m detrás a 2,55 m delante) con sus "
        "cuerdas; para dar sombra a un paso o un patio.", tipo="atrezo")
def m_toldo_vela(m, p, v):
    W, D = 3.6, 3.0
    esq = [(-W / 2, 2.55, D / 2), (W / 2, 2.55, D / 2), (W / 2, 3.0, -D / 2), (-W / 2, 3.0, -D / 2)]
    lona_rayas(m, esq, 7, [TELAS[3], TELAS[0]], comba=0.18)
    for (x, y, z) in esq:
        xm, zm = x * 1.12, z * 1.12
        viga(m, (xm, 0.0, zm), (xm, y + 0.45, zm), 0.09, "madera", MADERA_OSC)
        caja(m, (xm, 0.08, zm), (0.3, 0.16, 0.3), "sillar", SILLAR)
        viga(m, (x, y, z), (xm, y + 0.4, zm), 0.015, "tela", (0.70, 0.62, 0.48))
        choque((xm, 1.3, zm), (0.2, 2.6, 0.2), 0.0, "mastil")
    return {"huella": (-W * 0.56, -D * 0.56, W * 0.56, D * 0.56)}


# ================================================================ MOBILIARIO (pivote en el centro de la base)

@modulo("banco_piedra", ["todos"], "Banco de piedra (1,6 × 0,45 m, asiento a 0,45 m).", tipo="atrezo")
def m_banco_piedra(m, p, v):
    for x in (-0.55, 0.55):
        caja(p, (x, 0.2, 0.0), (0.22, 0.4, 0.4), "sillar", jit(SILLAR, 0.04), jit_v=0.006)
    caja(p, (0.0, 0.43, 0.0), (1.6, 0.08, 0.46), "sillar", jit(SILLAR, 0.04), jit_v=0.006)
    choque((0, 0.23, 0), (1.6, 0.46, 0.46), 0.0, "banco")
    ancla_p("sentarse", (0.0, 0.45, 0.35))
    return {"huella": (-0.8, -0.23, 0.8, 0.23)}


@modulo("banco_madera", ["todos"], "Banco de tablas con respaldo (1,7 × 0,5 m).", tipo="atrezo")
def m_banco_madera(m, p, v):
    for x in (-0.7, 0.7):
        viga(p, (x, 0.0, 0.18), (x, 0.42, 0.18), 0.07, "madera", MADERA_OSC)
        viga(p, (x, 0.0, -0.18), (x, 0.9, -0.24), 0.07, "madera", MADERA_OSC)
    for k in range(3):
        caja(p, (0.0, 0.44, 0.15 - k * 0.14), (1.7, 0.04, 0.12), "madera", jit(MADERA, 0.05), veta="larga")
    for k in range(2):
        caja(p, (0.0, 0.62 + k * 0.2, -0.22), (1.7, 0.1, 0.03), "madera", jit(MADERA, 0.05), rot=R(0, -8), veta="larga")
    choque((0, 0.45, 0), (1.7, 0.9, 0.5), 0.0, "banco")
    ancla_p("sentarse", (0.0, 0.45, 0.35))
    return {"huella": (-0.85, -0.25, 0.85, 0.25)}


@modulo("barriles", ["3 Oficios", "6 Patio del Cuervo", "8 Ribera Baja"], "Grupo de tres barriles (dos de pie y uno "
        "tumbado sobre calzos).", tipo="atrezo")
def m_barriles(m, p, v):
    barril(p, (-0.4, 0.0, -0.1), 0.32, 0.85)
    barril(p, (0.3, 0.0, -0.25), 0.3, 0.8)
    barril(p, (0.1, 0.3, 0.55), 0.28, 0.75, tumbado=True, yaw=10)
    for x in (-0.18, 0.38):
        caja(p, (x, 0.05, 0.55), (0.1, 0.1, 0.5), "madera", MADERA_OSC)
    return {"huella": (-0.75, -0.6, 0.65, 0.85)}


@modulo("cajas", ["1 Caravanas", "3 Oficios", "8 Ribera Baja"], "Pila de cajones y sacos de mercancía.", tipo="atrezo")
def m_cajas(m, p, v):
    cajita(p, (-0.3, 0.0, 0.0), (0.7, 0.55, 0.6), yaw=4)
    cajita(p, (0.45, 0.0, 0.1), (0.6, 0.5, 0.55), yaw=-8)
    cajita(p, (-0.25, 0.55, 0.02), (0.55, 0.42, 0.5), yaw=12)
    saco(p, (0.5, 0.0, 0.65), 40)
    saco(p, (-0.2, 0.0, 0.62), 110)
    return {"huella": (-0.7, -0.35, 0.8, 0.85)}


@modulo("puesto_mercado", ["2 Gran Mercado"], "Puesto sin toldo: mesa de caballetes (2,2 × 0,8 m) con cajones de fruta, "
        "cesta de pan y tinaja.", tipo="atrezo")
def m_puesto_mercado(m, p, v):
    y = mesa(p, (-1.1, -0.4, 2.2, 0.8), 0.0)
    for k, tipo in enumerate(("manzanas", "nabos", "peras")):
        cx = -0.7 + k * 0.7
        caja(p, (cx, y + 0.08, 0.0), (0.5, 0.16, 0.55), "madera", jit(MADERA_GRIS, 0.06), rot=R(U(-5, 5)), veta="larga")
        frutas(p, v, (cx, y + 0.1, 0.0), 0.23, tipo)
    cesta_pan(p, (1.4, 0.0, 0.2), 0.22)
    tinaja(p, (-1.45, 0.0, -0.1), 0.6, 0.22)
    choque((0, 0.45, 0), (2.2, 0.9, 0.8), 0.0, "mesa")
    return {"huella": (-1.7, -0.4, 1.65, 0.45)}


@modulo("farol_pie", ["todos"], "Farol de pie de la muestra (poste de 3,3 m con brazo y farol encendido).", tipo="atrezo")
def m_farol_pie(m, p, v):
    farol_pie(m, p, 0.0, 0.0, 0.0)
    choque((0, 0.6, 0), (0.34, 1.2, 0.34), 0.0, "poste")
    return {"huella": (-0.17, -0.17, 0.85, 0.17)}


@modulo("farol_pared", ["todos"], "Farol en brazo de hierro para colgar de una fachada (pivote en el muro, a 2,9 m).",
        tipo="muro")
def m_farol_pared(m, p, v):
    caja_mm(m, (-0.12, 2.6, 0.0), (0.12, 3.05, 0.04), "hierro", HIERRO)
    farol_pared(m, (0.0, 2.9, 0.03), (0.0, 0.0, 1.0))
    return {"huella": (-0.2, 0.0, 0.2, 0.7), "nota": "y = 0 = el suelo bajo el farol"}


@modulo("macetas", ["4 Las Terrazas", "todos"], "Grupo de tres macetas de barro con flores (geranios, margaritas, "
        "lavanda).", tipo="atrezo")
def m_macetas(m, p, v):
    maceta(p, v, (-0.35, 0.0, 0.0), 0.24, 0.34)
    maceta(p, v, (0.2, 0.0, 0.12), 0.18, 0.26)
    maceta(p, v, (0.05, 0.0, -0.35), 0.15, 0.22)
    return {"huella": (-0.6, -0.5, 0.4, 0.3)}


@modulo("maceta_limonero", ["4 Las Terrazas", "7 Barrio Alto", "2 Plaza"], "Tinaja grande con un limonero (1,9 m) y "
        "sus limones.", tipo="atrezo")
def m_maceta_limonero(m, p, v):
    cilindro(p, (0, 0, 0), [(0, 0.26), (0.25, 0.4), (0.55, 0.38), (0.62, 0.42), (0.66, 0.4)], 12, "barro",
             jit(BARRO, 0.05))
    caja(p, (0, 0.63, 0), (0.6, 0.02, 0.6), "tierra", (0.40, 0.32, 0.26), caras="a")
    viga(p, (0, 0.6, 0), (0.05, 1.3, 0.02), 0.07, "madera", jit(TRONCO, 0.05))
    for c in ((0, 1.55, 0), (0.25, 1.4, 0.15), (-0.22, 1.45, -0.1)):
        hojas(v, c, 0.36, 60, HOJA, 0.075, flex=0.3, aplastar=0.85)
    for k in range(9):
        a, h = U(0, math.tau), U(1.25, 1.8)
        caja(p, (math.cos(a) * 0.36, h, math.sin(a) * 0.36), (0.07, 0.09, 0.07), "barro", (0.98, 0.84, 0.30),
             rot=R(U(0, 90)))
    choque((0, 0.35, 0), (0.8, 0.7, 0.8), 0.0, "tinaja")
    return {"huella": (-0.42, -0.42, 0.42, 0.42)}


@modulo("abrevadero", ["1 Caravanas", "8 La Ribera Baja", "3 Oficios"],
        "Abrevadero de piedra (2,2 × 0,7 × 0,6 m) con agua y su pilar con caño de latón.", tipo="atrezo")
def m_abrevadero(m, p, v):
    L, A, H = 2.2, 0.7, 0.6
    caja_mm(m, (-L / 2, 0.0, -A / 2), (L / 2, 0.12, A / 2), "sillar", jit(SILLAR, 0.03))
    for (a, b) in (((-L / 2, -A / 2), (L / 2, -A / 2 + 0.12)), ((-L / 2, A / 2 - 0.12), (L / 2, A / 2)),
                   ((-L / 2, -A / 2), (-L / 2 + 0.12, A / 2)), ((L / 2 - 0.12, -A / 2), (L / 2, A / 2))):
        caja_mm(m, (a[0], 0.12, a[1]), (b[0], H, b[1]), "sillar", jit(SILLAR, 0.04), jit_v=0.005)
    caja_mm(m, (-L / 2 + 0.12, 0.45, -A / 2 + 0.12), (L / 2 - 0.12, 0.47, A / 2 - 0.12), "hierro", AGUA, caras="a")
    caja_mm(m, (-L / 2 - 0.55, -0.1, -0.3), (-L / 2 - 0.05, 1.5, 0.25), "sillar", jit(MURALLA, 0.03))
    caja_mm(m, (-L / 2 - 0.6, 1.5, -0.35), (-L / 2, 1.62, 0.3), "sillar", jit(SILLAR, 0.04))
    viga(m, (-L / 2 - 0.06, 1.05, 0.0), (-L / 2 + 0.22, 1.0, 0.0), 0.05, "barro", LATON)
    viga(m, (-L / 2 + 0.23, 0.99, 0.0), (-L / 2 + 0.3, 0.47, 0.0), 0.035, "hierro", AGUA_CLARA)
    mata(v, (L / 2 + 0.1, 0.0, 0.3), 0.15, 10, 0.3)
    choque((0, H / 2, 0), (L, H, A), 0.0, "pila")
    choque((-L / 2 - 0.3, 0.8, 0), (0.6, 1.6, 0.6), 0.0, "pilar")
    return {"huella": (-L / 2 - 0.6, -A / 2, L / 2, A / 2)}


@modulo("carro", ["1 Caravanas", "3 Oficios", "8 La Ribera Baja"],
        "Carro de dos ruedas (Ø 1,2 m) cargado de sacos, un tonel y cajones, con la lanza apoyada en el suelo.",
        tipo="atrezo")
def m_carro(m, p, v):
    for s in (-1, 1):
        rueda(p, (0.0, 0.6, s * 0.78), 0.6, 0.0, radios=10)
    viga(p, (0.0, 0.6, -0.72), (0.0, 0.6, 0.72), 0.07, "hierro", HIERRO)
    caja_mm(p, (-1.2, 0.74, -0.62), (1.0, 0.8, 0.62), "madera", jit(MADERA, 0.05), veta="larga")
    for s in (-1, 1):
        caja_mm(p, (-1.2, 0.8, s * 0.62 - 0.03), (1.0, 1.12, s * 0.62 + 0.03), "madera", jit(MADERA_GRIS, 0.05),
                veta="larga")
    for x in (-1.2, 1.0):
        caja_mm(p, (x - 0.03, 0.8, -0.62), (x + 0.03, 1.08, 0.62), "madera", jit(MADERA_GRIS, 0.05))
    for s in (-1, 1):
        viga(p, (1.0, 0.76, s * 0.4), (2.5, 0.05, s * 0.48), 0.07, "madera", MADERA_OSC)
    for k in range(3):
        saco(p, (-0.8 + k * 0.4, 0.8, U(-0.3, 0.3)), U(0, 90))
    barril(p, (0.55, 0.8, -0.25), 0.26, 0.7)
    cajita(p, (0.5, 0.8, 0.3), (0.5, 0.4, 0.45), yaw=8)
    viga(p, (-1.5, 0.02, 0.4), (-1.25, 0.4, 0.5), 0.05, "madera", MADERA_GRIS)
    choque((0.0, 0.6, 0.0), (2.4, 1.2, 1.7), 0.0, "carro")
    return {"huella": (-1.25, -0.85, 2.5, 0.85)}


@modulo("carretilla", ["3 Oficios", "4 Las Terrazas"], "La carretilla de la muestra, con sacos.", tipo="atrezo")
def m_carretilla(m, p, v):
    carretilla(p, v, (0.0, 0.0, 0.0), 0.0)
    return {"huella": (-1.3, -0.4, 0.9, 0.4)}


@modulo("tendedero", ["4 Las Terrazas"], "Cuerda de tender de 4 m con ropa, entre dos escuadras de hierro a 3,2 m (por "
        "encima de Kael); se cuelga de una fachada.", tipo="muro")
def m_tendedero(m, p, v):
    tendedero(m, p, 0.0, 4.0, 0.75, 3.2)
    return {"huella": (0.0, 0.0, 4.0, 0.8), "nota": "z = 0 = la fachada"}


# ================================================================ VEGETACIÓN ESTILIZADA

@modulo("glicinia_pergola", ["4 Las Terrazas", "7 Barrio Alto (jardines)"],
        "Pérgola de madera (3,0 × 2,4 m, libre 2,6 m) cubierta por una glicinia en flor: tronco retorcido en un pie, "
        "hojas por encima y racimos colgantes (el más bajo a ≈ 2,0 m).", tipo="atrezo")
def m_glicinia_pergola(m, p, v):
    W, D, alto = 3.0, 2.4, 2.6
    x0, z0 = -W / 2, -D / 2
    for x in (x0 + 0.08, -x0 - 0.08):
        for z in (z0 + 0.08, -z0 - 0.08):
            viga(m, (x, 0.0, z), (x, alto, z), 0.14, "madera", MADERA_OSC)
            caja(m, (x, 0.06, z), (0.26, 0.12, 0.26), "sillar", SILLAR)
            choque((x, 1.3, z), (0.2, 2.6, 0.2), 0.0, "pie")
    for z in (z0 + 0.08, -z0 - 0.08):
        viga(m, (x0 - 0.3, alto + 0.08, z), (-x0 + 0.3, alto + 0.08, z), 0.14, "madera", MADERA_OSC, alto=0.18)
    for k in range(7):
        x = x0 + 0.1 + k * (W - 0.2) / 6
        viga(m, (x, alto + 0.24, z0 - 0.3), (x, alto + 0.24, -z0 + 0.3), 0.08, "madera", MADERA, alto=0.12)
    glicinia(p, v, [(x0 + 0.2, 0.0, -z0 - 0.12), (x0 + 0.15, 1.3, -z0 - 0.1), (x0 + 0.25, alto + 0.3, -z0 - 0.1),
                    (0.0, alto + 0.4, 0.4), (-x0 - 0.2, alto + 0.42, -0.3), (-x0 - 0.4, alto + 0.35, z0 + 0.2)],
             racimos=46, desde=0.3, n_hojas=22, colgar=(0.32, 0.55))
    glicinia(p, v, [(x0 + 0.25, alto + 0.3, -z0 - 0.1), (x0 + 0.5, alto + 0.42, z0 + 0.1), (0.3, alto + 0.45, z0 - 0.1)],
             racimos=22, grosor=0.06, desde=0.0, n_hojas=20, colgar=(0.3, 0.5))
    for k in range(14):
        hojas(v, (U(x0, -x0), alto + 0.45, U(z0, -z0)), 0.45, 22, HOJA_GLIC, 0.09, flex=0.4, aplastar=0.45)
    return {"huella": (x0 - 0.3, z0 - 0.3, -x0 + 0.3, -z0 + 0.3)}


@modulo("glicinia_muro", ["4 Las Terrazas", "5 Pasajes Viejos"],
        "Glicinia en flor para arrimar a una fachada (3,2 m de ancho, hasta 4,3 m): tronco que sube junto a una puerta y "
        "dos ramas con racimos.", tipo="muro")
def m_glicinia_muro(m, p, v):
    glicinia(p, v, [(0.4, 0.0, 0.18), (0.32, 1.4, 0.2), (0.5, 2.7, 0.24), (1.6, 3.0, 0.32), (3.1, 3.05, 0.3)],
             racimos=26, desde=0.45)
    glicinia(p, v, [(0.5, 2.7, 0.24), (1.2, 3.6, 0.22), (2.3, 4.3, 0.2)], racimos=14, grosor=0.06, desde=0.0)
    caja(m, (1.6, 2.95, 0.05), (3.2, 0.04, 0.04), "hierro", HIERRO)        # el alambre que la guía
    return {"huella": (0.0, 0.0, 3.2, 0.45), "nota": "z = 0 = la fachada"}


@modulo("cipres_alto", ["7 Barrio Alto", "4 Las Terrazas", "muralla"], "Ciprés estilizado de 7 m (Ø 1,4 m).",
        tipo="atrezo")
def m_cipres_alto(m, p, v):
    cipres(p, v, (0, 0, 0), 7.0, 0.72)
    return {"huella": (-0.75, -0.75, 0.75, 0.75)}


@modulo("cipres_bajo", ["7 Barrio Alto", "4 Las Terrazas", "2 Plaza"], "Ciprés joven de 4,2 m (Ø 1 m).", tipo="atrezo")
def m_cipres_bajo(m, p, v):
    cipres(p, v, (0, 0, 0), 4.2, 0.5)
    return {"huella": (-0.55, -0.55, 0.55, 0.55)}


# ================================================================ horneado, exportación y láminas

def area(M):
    """La superficie de una malla (m²): para repartir el atlas de luz."""
    tot = 0.0
    for pts, *_ in M.caras:
        for k in range(1, len(pts) - 1):
            tot += (pts[k] - pts[0]).cross(pts[k + 1] - pts[0]).length * 0.5
    return tot


def uv_atlas(fijos, areas, res):
    """Las UV del mapa de luz («luz») de TODOS los módulos en un solo atlas (una sola textura de luz para el kit). Cada
    módulo se despliega aparte (proyección inteligente y empaquetado en su cuadrado) y después su cuadrado se coloca en
    el atlas por estantes, con un lado proporcional a la raíz de su superficie (la misma densidad de téxeles para
    todos) y 3 téxeles de separación. (Desplegar todos a la vez empaqueta cada objeto en el cuadrado entero: se
    solapaban.) Devuelve los téxeles por metro."""
    for ob in fijos:
        bpy.ops.object.select_all(action='DESELECT')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        ob.data.uv_layers.active = ob.data.uv_layers["luz"]
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.008, area_weight=0.0,
                                 correct_aspect=True, scale_to_bounds=False)
        bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, margin=0.008)
        bpy.ops.object.mode_set(mode='OBJECT')       # («luz» queda ACTIVA: es la que usa el horneado)
    orden = sorted(range(len(fijos)), key=lambda i: -areas[i])
    def estantes(k):
        out, x, y, alto = {}, 0.0, 0.0, 0.0
        for i in orden:
            lado = k * math.sqrt(max(areas[i], 0.05))
            if x + lado > 1.0:
                x, y, alto = 0.0, y + alto, 0.0
            if lado > 1.0 or y + lado > 1.0:
                return None
            out[i] = (x, y, lado)
            x += lado
            alto = max(alto, lado)
        return out
    lo, hi = 0.0, 1.0 / math.sqrt(max(areas))
    for _ in range(40):
        mid = (lo + hi) / 2
        if estantes(mid) is None:
            hi = mid
        else:
            lo = mid
    sitio = estantes(lo)
    sep = 3.0 / res
    for i, ob in enumerate(fijos):
        x, y, lado = sitio[i]
        uv = ob.data.uv_layers["luz"].data
        a = np.zeros(len(uv) * 2, np.float32)
        uv.foreach_get("uv", a)
        a = a.reshape(-1, 2)
        a = np.clip(a, 0.0, 1.0) * (lado - 2 * sep) + np.array([x + sep, y + sep], np.float32)
        uv.foreach_set("uv", a.ravel())
    return lo * res * math.sqrt(0.6)          # (el cuadrado de cada módulo se llena ≈ al 60 %)


def dilatar(img, pasos=4):
    """El margen de las islas del atlas, rellenado DESPUÉS del horneado: con varios objetos en una imagen, el margen
    del horneado de Blender de un objeto pisa los téxeles ya horneados de otro (tejas sueltas oscuras). Cada paso
    rellena los téxeles vacíos (sin luz ninguna: el horneado los deja a 0) con la media de sus vecinos horneados."""
    w, h = img.size
    a = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    a[..., 3] = (a[..., :3].max(-1) > 1e-7).astype(np.float32)
    nota("atlas: %.1f %% de téxeles horneados" % (100.0 * a[..., 3].mean()))
    for _ in range(pasos):
        lleno = a[..., 3] > 0.5
        suma = np.zeros((h, w, 3), np.float32)
        n = np.zeros((h, w), np.float32)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            m = np.roll(lleno, (dy, dx), (0, 1))
            suma += np.roll(a[..., :3], (dy, dx), (0, 1)) * m[..., None]
            n += m
        nuevo = (~lleno) & (n > 0)
        a[nuevo, :3] = suma[nuevo] / n[nuevo, None]
        a[nuevo, 3] = 1.0
    img.pixels.foreach_set(a.ravel())


def vertices_como_mapa(objs):
    """(solo las láminas: la tierra y la silueta) la luz en los vértices con el tono de lo que va en mapa de luz:
    textura × tinte × luz, en lugar de la regla de las piezas del barrio."""
    for ob in objs:
        vm = ob.data
        col, luz = vm.color_attributes["Col"], vm.color_attributes["LuzV"]
        n = len(col.data)
        c = np.zeros(n * 4, np.float32)
        l = np.zeros(n * 4, np.float32)
        col.data.foreach_get("color", c)
        luz.data.foreach_get("color", l)
        c, l = c.reshape(n, 4), l.reshape(n, 4)
        c[:, :3] = np.clip(c[:, :3] * l[:, :3] / ESCALA, 0.0, 1.0) ** (1.0 / GAMMA_VERTICE)
        col.data.foreach_set("color", c.ravel())
        vm.color_attributes.remove(luz)
        vm.color_attributes.active_color = vm.color_attributes["Col"]


def envolvente(mallas):
    mn = Vector((1e9, 1e9, 1e9))
    mx = Vector((-1e9, -1e9, -1e9))
    for M in mallas:
        for pts, *_ in M.caras:
            for q in pts:
                mn = Vector((min(mn.x, q.x), min(mn.y, q.y), min(mn.z, q.z)))
                mx = Vector((max(mx.x, q.x), max(mx.y, q.y), max(mx.z, q.z)))
    return mn, mx


def suelo_lamina(mn, mx, paso=0.5):
    """La tierra bajo un módulo en las láminas (recibe su sombra; no se exporta)."""
    G = Malla()
    alto = max(1.0, mx.y)
    x0, x1 = math.floor(mn.x - 5.0), math.ceil(mx.x + min(28.0, 2.3 * alto + 3.0))
    z0, z1 = math.floor(mn.z - min(10.0, 0.8 * alto + 3.0)), math.ceil(mx.z + 6.0)
    nx, nz = int((x1 - x0) / paso), int((z1 - z0) / paso)
    for i in range(nx):
        for j in range(nz):
            xa, za = x0 + i * paso, z0 + j * paso
            t = 0.5 + 0.5 * ruido2(xa * 0.5, za * 0.5, 1.0)
            G.cara([Vector((xa, -0.045, za)), Vector((xa, -0.045, za + paso)), Vector((xa + paso, -0.045, za + paso)),
                    Vector((xa + paso, -0.045, za))], "tierra", mezcla(TIERRA, (0.72, 0.64, 0.50), t))
    return G


def material_vista(nombre, imgs, luz_img=None, depurar=False):
    """Un material que ENSEÑA en Blender lo que pinta Godot con los sombreados de la muestra (sin luz: emisión):
    textura × color del vértice leído como sRGB (Godot lo pasa a lineal: ≈ potencia 2,2) × [mapa de luz] × escala.
    Las caras de espaldas no se ven (cull_back), salvo las hojas; con «depurar», en magenta."""
    mt = bpy.data.materials.new("vista_" + nombre + ("_luz" if luz_img else ""))
    mt.use_nodes = True
    nt = mt.node_tree
    for n in list(nt.nodes):
        nt.nodes.remove(n)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    ga = nt.nodes.new("ShaderNodeGamma")
    ga.inputs["Gamma"].default_value = GAMMA_VERTICE
    nt.links.new(vc.outputs["Color"], ga.inputs["Color"])
    def mul(a, b):
        mx = nt.nodes.new("ShaderNodeMix")
        mx.data_type = 'RGBA'
        mx.blend_type = 'MULTIPLY'
        mx.inputs["Factor"].default_value = 1.0
        ent = {so.identifier: so for so in mx.inputs}
        nt.links.new(a, ent["A_Color"])
        nt.links.new(b, ent["B_Color"])
        return {so.identifier: so for so in mx.outputs}["Result_Color"]
    if nombre == "brillo":
        color = ga.outputs["Color"]
        em.inputs["Strength"].default_value = 1.2
    else:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = imgs[K.TEX_DE[nombre]]
        uvn = nt.nodes.new("ShaderNodeUVMap")
        uvn.uv_map = "UVMap"
        nt.links.new(uvn.outputs["UV"], tex.inputs["Vector"])
        color = mul(tex.outputs["Color"], ga.outputs["Color"])
        if luz_img is not None:
            lz = nt.nodes.new("ShaderNodeTexImage")
            lz.image = luz_img
            lz.extension = 'EXTEND'
            uvl = nt.nodes.new("ShaderNodeUVMap")
            uvl.uv_map = "luz"
            nt.links.new(uvl.outputs["UV"], lz.inputs["Vector"])
            color = mul(color, lz.outputs["Color"])
        em.inputs["Strength"].default_value = ESCALA
    nt.links.new(color, em.inputs["Color"])
    if nombre in ("hoja", "tela"):                         # (hojas: sin cull; telas: ya llevan las dos caras)
        nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
        return mt
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    mix = nt.nodes.new("ShaderNodeMixShader")
    if depurar:
        otra = nt.nodes.new("ShaderNodeEmission")
        otra.inputs["Color"].default_value = (1.0, 0.0, 1.0, 1.0)
        otra.inputs["Strength"].default_value = 1.0
        o2 = otra.outputs["Emission"]
    else:
        o2 = nt.nodes.new("ShaderNodeBsdfTransparent").outputs["BSDF"]
    nt.links.new(geo.outputs["Backfacing"], mix.inputs["Fac"])
    nt.links.new(em.outputs["Emission"], mix.inputs[1])
    nt.links.new(o2, mix.inputs[2])
    nt.links.new(mix.outputs["Shader"], out.inputs["Surface"])
    return mt


def vestir_vista(ob, vistas):
    for i, mt in enumerate(ob.data.materials):
        if mt is not None and mt.name.split(".")[0] in vistas:
            ob.data.materials[i] = vistas[mt.name.split(".")[0]]


def hornear_vertices(objs):
    bpy.ops.object.select_all(action='DESELECT')
    for ob in objs:
        vm = ob.data
        vm.color_attributes.active_color = vm.color_attributes.new("LuzV", 'FLOAT_COLOR', 'CORNER')
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
    bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, target='VERTEX_COLORS', use_clear=True)


def tono_godot(lin):
    """El paso final de la muestra en Godot (muestra_calle.gd, _crear_ambiente): Filmic con exposición 0,86 (blanco 1),
    a sRGB, y después contraste y saturación 1,12. lin: (h, w, ≥3) lineal; devuelve sRGB 0-1."""
    c = np.maximum(lin[..., :3], 0.0) * 0.86
    A, Bf, C, D, E, Fv = 0.22 * 4.0, 0.30 * 2.0, 0.10, 0.20, 0.01, 0.30
    def f(x):
        return ((x * (A * x + C * Bf) + D * E) / (x * (A * x + Bf) + D * Fv)) - E / Fv
    c = np.clip(f(c) / f(1.0), 0.0, 1.0)
    c = np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)
    c = 0.5 + (c - 0.5) * 1.12
    gris = c.sum(-1, keepdims=True) / 3.0
    c = gris + (c - gris) * 1.12
    out = np.ones(lin.shape[:2] + (4,), np.float32)
    out[..., :3] = np.clip(c, 0.0, 1.0)
    return out


def render_godot(ruta_png):
    """Renderiza en lineal (EXR) y aplica tono_godot: la imagen es la que daría Godot con el ambiente de la muestra."""
    sc = bpy.context.scene
    exr = ruta_png[:-4] + "_lineal.exr"
    sc.render.image_settings.file_format = 'OPEN_EXR'
    sc.render.image_settings.color_mode = 'RGB'
    sc.render.filepath = exr
    bpy.ops.render.render(write_still=True)
    im = bpy.data.images.load(exr, check_existing=False)
    w, h = im.size
    a = np.array(im.pixels[:], np.float32).reshape(h, w, 4)
    bpy.data.images.remove(im)
    os.remove(exr)
    guardar_png(tono_godot(a), ruta_png)


def preparar_render(res, muestras=24):
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = muestras
    sc.cycles.use_denoising = False
    sc.cycles.max_bounces = 0
    sc.cycles.transparent_max_bounces = 8
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = False
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    sc.view_settings.exposure = 0.0
    sc.view_settings.gamma = 1.0
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGB'
    w = sc.world
    bg = w.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (0.50, 0.47, 0.41, 1.0)
    bg.inputs["Strength"].default_value = 1.0


def camara(nombre="Camara"):
    cd = bpy.data.cameras.new(nombre)
    co = bpy.data.objects.new(nombre, cd)
    bpy.context.scene.collection.objects.link(co)
    bpy.context.scene.camera = co
    return co


def apuntar(co, pos_g, dir_g, fov_v):
    """Cámara en pos (Godot) mirando en dir (Godot), con campo vertical fov_v (grados)."""
    co.location = (pos_g[0], -pos_g[2], pos_g[1])
    d = Vector((dir_g[0], -dir_g[2], dir_g[1])).normalized()
    co.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    co.data.sensor_fit = 'VERTICAL'
    co.data.angle = math.radians(fov_v)
    co.data.clip_start = 0.1
    co.data.clip_end = 400.0


def rotulo(co, texto, fov_v, aspecto):
    """Un rótulo de dos o tres líneas arriba a la izquierda de la cámara, sobre una placa clara."""
    mt = bpy.data.materials.get("rotulo_tinta")
    if mt is None:
        mt = bpy.data.materials.new("rotulo_tinta")
        mt.use_nodes = True
        nt = mt.node_tree
        for n in list(nt.nodes):
            nt.nodes.remove(n)
        e = nt.nodes.new("ShaderNodeEmission")
        e.inputs["Color"].default_value = (0.05, 0.035, 0.025, 1)
        o = nt.nodes.new("ShaderNodeOutputMaterial")
        nt.links.new(e.outputs["Emission"], o.inputs["Surface"])
        mp = bpy.data.materials.new("rotulo_placa")
        mp.use_nodes = True
        nt = mp.node_tree
        for n in list(nt.nodes):
            nt.nodes.remove(n)
        e = nt.nodes.new("ShaderNodeEmission")
        e.inputs["Color"].default_value = (0.86, 0.80, 0.68, 1)
        o = nt.nodes.new("ShaderNodeOutputMaterial")
        nt.links.new(e.outputs["Emission"], o.inputs["Surface"])
    hh = math.tan(math.radians(fov_v) / 2)
    hw = hh * aspecto
    ob = bpy.data.objects.get("rotulo")
    if ob is None:
        cu = bpy.data.curves.new("rotulo", 'FONT')
        ob = bpy.data.objects.new("rotulo", cu)
        bpy.context.scene.collection.objects.link(ob)
        cu.materials.append(bpy.data.materials["rotulo_tinta"])
        me = bpy.data.meshes.new("rotulo_placa")
        me.from_pydata([(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)], [], [[0, 1, 2, 3]])
        me.materials.append(bpy.data.materials["rotulo_placa"])
        pl = bpy.data.objects.new("rotulo_placa", me)
        bpy.context.scene.collection.objects.link(pl)
    pl = bpy.data.objects["rotulo_placa"]
    ob.parent = co
    pl.parent = co
    ob.data.body = texto
    lineas = texto.split("\n")
    s = hh * 0.062
    ob.data.size = s
    ob.location = (-hw + 0.035 * hh, hh - 0.04 * hh - s * 0.85, -1.0)
    ob.rotation_euler = (0, 0, 0)
    ancho = max(len(t) for t in lineas) * s * 0.52 + 0.05 * hh
    alto = len(lineas) * s * 1.22 + 0.06 * hh
    pl.location = (-hw, hh - alto, -1.001)
    pl.scale = (min(ancho, 2 * hw), alto, 1.0)
    pl.rotation_euler = (0, 0, 0)


def leer_png(ruta):
    im = bpy.data.images.load(ruta, check_existing=False)
    w, h = im.size
    a = np.array(im.pixels[:], np.float32).reshape(h, w, 4)
    bpy.data.images.remove(im)
    return a


def guardar_png(a, ruta):
    h, w = a.shape[:2]
    im = bpy.data.images.new(os.path.basename(ruta), w, h, alpha=False)
    im.pixels.foreach_set(np.ascontiguousarray(a, np.float32).ravel())
    im.filepath_raw = ruta
    im.file_format = 'PNG'
    im.save()
    bpy.data.images.remove(im)


def hoja_de_conjunto(rutas, ruta_salida, columnas=6, reducir=3):
    """La lámina de conjunto: las láminas de los módulos en una rejilla (cada una con su rótulo), reducidas."""
    tiras = []
    for r in rutas:
        a = leer_png(r)
        h, w = a.shape[:2]
        a = a[:h - h % reducir, :w - w % reducir].reshape(h // reducir, reducir, w // reducir, reducir, 4).mean((1, 3))
        tiras.append(a)
    th, tw = tiras[0].shape[:2]
    filas = (len(tiras) + columnas - 1) // columnas
    m = 6
    hoja = np.ones(((th + m) * filas + m, (tw + m) * columnas + m, 4), np.float32)
    hoja[..., :3] = (0.22, 0.19, 0.16)
    for k, t in enumerate(tiras):
        f, c = k // columnas, k % columnas
        y0 = hoja.shape[0] - m - (f + 1) * (th + m) + m        # (las imágenes de Blender van de abajo arriba)
        x0 = m + c * (tw + m)
        hoja[y0:y0 + th, x0:x0 + tw] = t
    guardar_png(hoja, ruta_salida)


def leer_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    a = {"carpeta": os.path.abspath(argv[0]) if argv and not argv[0].startswith("--") else os.path.dirname(AQUI),
         "laminas": None, "solo": None, "hornear": True, "muestras": 128, "depurar": False, "tramo": None,
         "modulos": True, "res": 2048}
    i = 0
    while i < len(argv):
        x = argv[i]
        if x == "--laminas":
            a["laminas"] = os.path.abspath(argv[i + 1]); i += 1
        elif x == "--solo":
            a["solo"] = [s for s in argv[i + 1].split(",") if s]; i += 1
        elif x == "--sin-horneado":
            a["hornear"] = False
        elif x == "--muestras":
            a["muestras"] = int(argv[i + 1]); i += 1
        elif x == "--depurar":
            a["depurar"] = True
        elif x == "--tramo":
            a["tramo"] = os.path.abspath(argv[i + 1]); i += 1
        elif x == "--sin-modulos":
            a["modulos"] = False
        elif x == "--res":
            a["res"] = int(argv[i + 1]); i += 1
        i += 1
    return a


def construir_modulos(A, mats):
    """Construye cada módulo en su sitio de la rejilla de horneado (70 m × 50 m: las sombras largas de la tarde no se
    cruzan) con su tierra y su silueta de escala. Devuelve la lista de registros."""
    lista = [md for md in MODULOS if A["solo"] is None or md["nombre"] in A["solo"]]
    regs = []
    for i, md in enumerate(lista):
        nombre = md["nombre"]
        sec = K.Sector(nombre, 5000 + zlib.crc32(nombre.encode("utf-8")) % 90000)
        K.usar(sec)
        M, P, V = Malla(), Malla(), Malla()
        info = md["f"](SeparaTela(M), SeparaTela(P), SeparaTela(V)) or {}
        mn, mx = envolvente([M, P, V])
        g = Vector(((i % 8) * 70.0, 0.0, (i // 8) * 50.0))
        obs = {}
        for parte, malla in (("fijo", M), ("piezas", P), ("vegetacion", V)):
            if malla.caras:
                ob = K.a_blender("%s_%s" % (nombre, parte), malla, mats, parte == "fijo")
                ob.location = (g.x, -g.z, 0.0)
                obs[parte] = ob
        extra = []
        Gs = suelo_lamina(mn, mx)
        ob = K.a_blender("suelo_" + nombre, Gs, mats, False)
        ob.location = (g.x, -g.z, 0.0)
        extra.append(ob)
        Fg = Malla()
        fx = mx.x + 0.7 if md["tipo"] != "escalera" else mn.x - 0.7
        figura(Fg, (fx, 0.0, max(0.6, mx.z * 0.5 + 0.4) if md["tipo"] in ("fachada", "muro", "escalera") else 0.0))
        ob = K.a_blender("figura_" + nombre, Fg, mats, False)
        ob.location = (g.x, -g.z, 0.0)
        extra.append(ob)
        tris = {"fijo": M.tris(), "piezas": P.tris(), "vegetacion": V.tris()}
        tris["total"] = sum(tris.values())
        regs.append({"md": md, "sector": sec, "info": info, "mn": mn, "mx": mx, "g": g, "obs": obs, "extra": extra,
                     "tris": tris, "area_fijo": area(M)})
        nota("%-28s %6d tri (fijo %d · piezas %d · vegetación %d) · %d anclas · %d choques" % (
            nombre, tris["total"], tris["fijo"], tris["piezas"], tris["vegetacion"], len(sec.anclas), len(sec.choques)))
    return regs


def exportar_modulos(A, regs):
    carpeta = os.path.join(A["carpeta"], "modelos")
    os.makedirs(carpeta, exist_ok=True)
    datos = {"version": 1, "generado": time.strftime("%Y-%m-%d %H:%M"), "escala_luz": ESCALA,
             "sol": {"rumbo": K.SOL_RUMBO, "elevacion": K.SOL_ELEVACION}, "texturas": "res://zonas3d/muestra_calle/texturas/",
             "mapa_luz": ["kit_luz_%d.png" % A["res"], "kit_luz_%d.png" % (A["res"] // 2)],
             "muestras": K.MUESTRAS, "modulos": {}}
    ruta_json = os.path.join(carpeta, "kit_ciudad.json")
    for r in regs:
        md, nombre = r["md"], r["md"]["nombre"]
        obs = list(r["obs"].values())
        for ob in obs:
            ob.location = (0.0, 0.0, 0.0)
        vac = K.vacios(r["sector"])
        ruta = os.path.join(carpeta, nombre + ".glb")
        K.exportar(obs + vac, ruta)
        escribir_import(ruta, "glb")
        for e in vac:
            bpy.data.objects.remove(e)
        for ob in obs:
            ob.location = (r["g"].x, -r["g"].z, 0.0)
        mn, mx = r["mn"], r["mx"]
        datos["modulos"][nombre] = {
            "sectores": md["sectores"], "uso": md["uso"], "tipo": md["tipo"],
            "envolvente": [[round(mn.x, 2), round(mn.y, 2), round(mn.z, 2)], [round(mx.x, 2), round(mx.y, 2), round(mx.z, 2)]],
            "medidas": [round(mx.x - mn.x, 2), round(mx.y - mn.y, 2), round(mx.z - mn.z, 2)],
            "huella": [round(x, 2) for x in r["info"].get("huella", (mn.x, mn.z, mx.x, mx.z))],
            "sube": r["info"].get("sube"), "nota": r["info"].get("nota"),
            "triangulos": r["tris"], "anclas": {k: [round(x, 3) for x in p] for k, p in r["sector"].anclas.items()},
            "choques": len(r["sector"].choques)}
    with open(ruta_json, "w", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False, indent=1)
    nota("kit_ciudad.json: %d módulos" % len(datos["modulos"]))


def laminas_modulos(A, regs, imgs):
    os.makedirs(A["laminas"], exist_ok=True)
    vistas = {m: material_vista(m, imgs, None, A["depurar"]) for m in K.MATS}
    atlas = bpy.data.images.load(os.path.join(A["carpeta"], "modelos", "kit_luz_%d.png" % A["res"]))
    vistas_luz = {m: material_vista(m, imgs, atlas, A["depurar"]) for m in K.MATS}
    todos = []
    for r in regs:
        for parte, ob in list(r["obs"].items()) + [("extra", e) for e in r["extra"]]:
            vestir_vista(ob, vistas_luz if parte == "fijo" else vistas)
            todos.append(ob)
    res = (1200, 900)
    preparar_render(res)
    co = camara()
    rutas = []
    fov = 30.0
    for r in regs:
        mios = set(list(r["obs"].values()) + r["extra"])
        for ob in todos:
            ob.hide_render = ob not in mios
        mn, mx = r["mn"].copy(), r["mx"].copy()
        mn.y = min(mn.y, 0.0)
        mx.y = max(mx.y, 1.75)
        c = (mn + mx) / 2 + r["g"]
        rad = (mx - mn).length / 2
        d = Vector((-0.3, 0.52, 0.8)).normalized()
        dist = rad / math.sin(math.radians(fov) / 2) * 0.95
        apuntar(co, c + d * dist, -d, fov)
        md = r["md"]
        t = r["tris"]
        rotulo(co, "%s  ·  %.1f × %.1f × %.1f m  ·  %d triángulos\n%s" % (
            md["nombre"], mx.x - mn.x, mx.z - mn.z, r["mx"].y - min(0.0, r["mn"].y), t["total"], ", ".join(md["sectores"])),
            fov, res[0] / res[1])
        ruta = os.path.join(A["laminas"], "modulo_%02d_%s.png" % (len(rutas) + 1, md["nombre"]))
        render_godot(ruta)
        rutas.append(ruta)
        nota("lámina %s" % os.path.basename(ruta))
    for ob in todos:
        ob.hide_render = False
    if len(rutas) > 1:
        hoja_de_conjunto(rutas, os.path.join(A["laminas"], "conjunto_kit_ciudad.png"))
        nota("lámina de conjunto")


# ================================================================ el TRAMO DE PRUEBA: una calle de las Terrazas
# Montado SOLO con el kit (colocar) y horneado como un sector del barrio: lo fijo con mapa de luz 2048 (UV2), las piezas
# y la vegetación en los vértices, la escala común. Calle a la cota 0 que corre de oeste a este; al norte, casas de las
# Terrazas y la escalera con rellano que sube a la terraza de arriba (+1,98); al sur, la balaustrada sobre el muro de la
# terraza de abajo (−2,4), con cipreses. La cámara es la de juego de la muestra (10,8 m arriba y 14,2 m al sur de Kael,
# −25°, 38° de campo vertical).

def tramo_terrazas(mallas):
    M, P, V = mallas
    for k in range(7):                                      # la calle: 7 × 2 losas de 4 m (z −3 … 5)
        for j in range(2):
            colocar("empedrado_4x4", mallas, (-14.0 + k * 4.0, 0.0, 1.0 + j * 4.0))
    colocar("vivienda_terrazas", mallas, (-13.2, 0.0, -3.0))
    colocar("escalera_rellano", mallas, (-6.35, 0.0, -3.0))
    colocar("vivienda_terrazas_escalera", mallas, (-3.55, 0.0, -3.0))
    colocar("vivienda_terrazas", mallas, (4.85, 0.0, -3.0))
    colocar("glicinia_pergola", mallas, (12.95, 0.0, -1.65))     # (al norte de la calle: el lado sur se deja bajo)
    colocar("macetas", mallas, (12.3, 0.0, -2.5))
    colocar("cipres_alto", mallas, (14.9, 0.0, -3.4))
    # el borde sur: muro de la terraza de abajo (mirando al sur, a la cámara) con la balaustrada encima
    for k in range(6):
        colocar("muro_terraza", mallas, (-14.0 + k * 5.0, -2.4, 6.2))
    for k in range(10):                                     # (la balaustrada mide 3 m: seguida de −14 a 16)
        colocar("balaustrada", mallas, (-14.0 + k * 3.0, 0.0, 5.0))
    tierra_base(M, (-14.0, 5.0, 16.0, 6.2), lambda x, z: 0.0, paso=2.0)
    tierra_base(M, (-16.0, 6.5, 18.0, 14.0), lambda x, z: -2.4, paso=1.0, tono=(0.62, 0.56, 0.42))   # terraza de abajo
    colocar("cipres_bajo", mallas, (-12.2, -2.4, 7.4))
    colocar("cipres_alto", mallas, (8.3, -2.4, 7.6))
    colocar("macetas", mallas, (-4.5, 0.0, 4.2))
    colocar("banco_piedra", mallas, (2.6, 0.0, 3.9))
    colocar("farol_pie", mallas, (-8.5, 0.0, 4.25))
    colocar("barriles", mallas, (10.2, 0.0, -2.1))
    colocar("maceta_limonero", mallas, (4.05, 0.0, -1.5))
    # la terraza de arriba, que asoma por la escalera
    tierra_base(M, (-8.0, -16.0, -3.0, -8.4), lambda x, z: 1.98, paso=1.0)
    colocar("cipres_bajo", mallas, (-4.9, 1.98, -10.2))
    colocar("muro_terraza", mallas, (-9.0, 1.98, -13.0))


def ejecutar_tramo(A, imgs):
    carpeta = A["tramo"]
    os.makedirs(carpeta, exist_ok=True)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    for mt in list(bpy.data.materials):                      # (los nombres «brillo», «piedra»… deben quedar libres)
        bpy.data.materials.remove(mt)
    sec = K.Sector("tramo", 2611)
    K.usar(sec)
    M, P, V = Malla(), Malla(), Malla()
    tramo_terrazas((M, P, V))
    kael = Vector((0.0, 0.0, 1.2))
    Fg = Malla()
    figura(Fg, kael)
    nota("tramo: %d tri fijos · %d de piezas · %d de vegetación · %d anclas" % (M.tris(), P.tris(), V.tris(),
                                                                              len(sec.anclas)))
    res_luz = 2048
    luz = bpy.data.images.new("luz_tramo", res_luz, res_luz, alpha=False, float_buffer=True)
    mats = K.materiales(imgs, luz)
    ob_f = K.a_blender("fijo_tramo", M, mats, True)
    ob_p = K.a_blender("piezas_tramo", P, mats, False)
    ob_v = K.a_blender("vegetacion_tramo", V, mats, False)
    ob_k = K.a_blender("kael_tramo", Fg, mats, False)
    K.MUESTRAS = 256
    K.preparar_cycles(sec.anclas)
    for m in mats.values():
        n = m.node_tree.nodes.get("LUZ")
        if n is not None:
            m.node_tree.nodes.active = n
    K.hornear(ob_f, [ob_p, ob_v, ob_k], "luz_tramo")
    K.escala_y_guardar(luz, carpeta, [ob_p, ob_v, ob_k], ESCALA, "tramo")
    K.exportar([ob_f, ob_p, ob_v], os.path.join(carpeta, "tramo_terrazas.glb"))
    luz_png = bpy.data.images.load(os.path.join(carpeta, "tramo_luz_%d.png" % res_luz))
    vistas = {m: material_vista(m, imgs, None, A["depurar"]) for m in K.MATS}
    vistas_luz = {m: material_vista(m, imgs, luz_png, A["depurar"]) for m in K.MATS}
    vestir_vista(ob_f, vistas_luz)
    for ob in (ob_p, ob_v, ob_k):
        vestir_vista(ob, vistas)
    res = (1280, 720)
    preparar_render(res, 48)
    co = camara("CamaraJuego")
    a = math.radians(25.0)
    apuntar(co, kael + Vector((0.0, 10.8, 14.2)), Vector((0.0, -math.sin(a), -math.cos(a))), 38.0)
    ruta = os.path.join(carpeta, "tramo_terrazas_camara_muestra_1280x720.png")
    render_godot(ruta)
    nota("render del tramo con la cámara de la muestra")
    apuntar(co, Vector((-9.0, 9.5, 17.0)), Vector((0.45, -0.42, -0.79)), 40.0)
    render_godot(os.path.join(carpeta, "tramo_terrazas_vista_libre_1280x720.png"))
    apuntar(co, Vector((-4.6, 4.2, 6.5)), Vector((-0.2, -0.25, -0.95)), 45.0)
    render_godot(os.path.join(carpeta, "tramo_terrazas_escalera_1280x720.png"))
    ref = os.path.normpath("D:/REBELUM_diagnostico/muestra_calle_15_11/despues_camara_muestra_medio_1600x720.png")
    if os.path.exists(ref):
        r = leer_png(ref)[:, 160:1440]
        t = leer_png(ruta)
        sep = np.zeros((8, 1280, 4), np.float32)
        sep[..., 3] = 1.0
        guardar_png(np.concatenate([t, sep, r], 0),          # (de abajo arriba: arriba la muestra, abajo el tramo)
                    os.path.join(carpeta, "comparar_arriba_muestra_aprobada_abajo_tramo_kit.png"))
        nota("comparación con la muestra aprobada")
    with open(os.path.join(carpeta, "tramo_terrazas.json"), "w", encoding="utf-8") as f:
        json.dump({"tris_fijo": M.tris(), "tris_piezas": P.tris(), "tris_vegetacion": V.tris(), "res_luz": res_luz,
                   "muestras": K.MUESTRAS, "kael": list(kael), "anclas": len(sec.anclas)}, f, indent=1)


def main():
    A = leer_args()
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    imgs = K.cargar_texturas(TEXTURAS)
    if A["modulos"]:
        atlas = bpy.data.images.new("luz_kit", A["res"], A["res"], alpha=True, float_buffer=True)
        atlas.pixels.foreach_set(np.zeros(A["res"] * A["res"] * 4, np.float32))     # alfa 0 = sin hornear (dilatar)
        mats = K.materiales(imgs, atlas)
        regs = construir_modulos(A, mats)
        sup = sum(r["area_fijo"] for r in regs)
        nota("%d módulos construidos; lo fijo suma %.0f m² → ≈ %.1f téxeles/m en el atlas de %d (aprovechando el 55 %%)"
             % (len(regs), sup, A["res"] * math.sqrt(0.55 / max(sup, 1.0)), A["res"]))
        if A["hornear"]:
            carpeta_mod = os.path.join(A["carpeta"], "modelos")
            os.makedirs(carpeta_mod, exist_ok=True)
            anclas = {}
            for r in regs:
                for k, q in r["sector"].anclas.items():
                    anclas["%s/%s" % (r["md"]["nombre"], k)] = (q[0] + r["g"].x, q[1], q[2] + r["g"].z)
            K.MUESTRAS = A["muestras"]
            K.preparar_cycles(anclas)
            fijos = [r["obs"]["fijo"] for r in regs if "fijo" in r["obs"]]
            dens = uv_atlas(fijos, [r["area_fijo"] for r in regs if "fijo" in r["obs"]], A["res"])
            nota("UV del atlas de luz hechas: ≈ %.1f téxeles/m" % dens)
            for m in mats.values():
                n = m.node_tree.nodes.get("LUZ")
                if n is not None:
                    m.node_tree.nodes.active = n
            bpy.ops.object.select_all(action='DESELECT')
            for ob in fijos:
                ob.select_set(True)
            bpy.context.view_layer.objects.active = fijos[0]
            sc = bpy.context.scene
            sc.render.bake.margin = 0
            bpy.ops.object.bake(type='DIFFUSE', pass_filter={'DIRECT', 'INDIRECT'}, margin=0, target='IMAGE_TEXTURES',
                                use_clear=True)
            dilatar(atlas, 4)
            nota("atlas de luz horneado (%d muestras)" % K.MUESTRAS)
            vert, extra = [], []
            for r in regs:
                vert += [ob for k, ob in r["obs"].items() if k != "fijo"]
                extra += r["extra"]
            hornear_vertices(vert + extra)
            if A["solo"] is None:
                K.escala_y_guardar(atlas, carpeta_mod, vert, ESCALA, "kit")
                for res in (A["res"], A["res"] // 2):
                    escribir_import(os.path.join(carpeta_mod, "kit_luz_%d.png" % res), "luz")
            else:
                K.escala_vertices(vert, ESCALA)
            vertices_como_mapa(extra)
            nota("luz de piezas y vegetación horneada en los vértices")
            if A["solo"] is None:
                exportar_modulos(A, regs)
            else:
                nota("--solo: no se exporta (el atlas es de todo el kit)")
            if A["laminas"] and A["solo"] is None:
                laminas_modulos(A, regs, imgs)
    if A["tramo"]:
        ejecutar_tramo(A, imgs)
    nota("HECHO")


if __name__ == "__main__":
    main()
