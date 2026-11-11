# Ismena (la cartógrafa del campamento) y Oren (su hermano, el superviviente) — PROTOTIPOS V12 (12/11/2026,
# especialista de animaciones). Sustituyen a las cápsulas de zonas3d/mar_cristal_3d.gd solo cuando el coordinador lo
# decida (interruptor apagado por defecto: ver personajes/desierto/npc_desierto_3d.gd).
#
#   blender -b --factory-startup -P crear_ismena_oren.py -- <raíz aethelgard> <carpeta de láminas> [ismena|oren|ambos]
#
# Escribe:
#   personajes/desierto/ismena/ismena.glb (+ ismena_atlas.png dentro del GLB) y lo mismo para oren
#   <láminas>/ismena_lamina.png, oren_lamina.png (silueta, frente, 3/4 y espalda junto a Kael a escala) y una pose por
#   clip (<nombre>_<clip>.png)
#
# Estilo: chibi de fantasía como Kael, Lya y Garon (cabeza grande, ojos grandes de anime, manos sencillas), pero con
# geometría y atlas propios (no son de Meshy). Ellos dos son hermanos: el mismo tono de piel, de pelo y de ojos.
# Lo que dice la narrativa (docs/v12/NARRATIVA_DESIERTO.md §1): Ismena dibuja mapas y espera en el campamento; ironía
# cansada, orienta («frases de dirección y medida»). Oren lleva un carro de toldo rojo, se pierde siempre, charlatán y
# optimista. Las cápsulas daban ya: a ella túnica azul verdosa, pañuelo y sombrero de ala ancha; a él chaleco pardo y el
# pañuelo rojo del toldo en la cabeza. Se conservan.
#
# Clips (30 fps; en bucle solo «reposo»; todos acaban en la pose del reposo para mezclar limpio):
#   Ismena: reposo (4 s), hablar (2,5 s: señala la dirección con el lápiz), mapa (4 s: levanta la tablilla y traza),
#           horizonte (4 s: se hace sombra con la mano y mira al sur, por donde tiene que volver él),
#           reganar (2 s: brazos en jarras y un golpe de lápiz al aire)
#   Oren:   reposo (3 s: inquieto, se balancea), hablar (2,5 s: abre los brazos), risa (2,5 s: se rasca la nuca y se ríe
#           de sí mismo), encogerse (1,8 s: se hace el tonto)
import bpy, sys, os, math
from mathutils import Vector, Euler, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import desierto_comun as C

argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ = argv[0]
LAMINAS = argv[1]
QUIEN = argv[2] if len(argv) > 2 else "ambos"

# ------------------------------------------------------------------ medidas comunes (m)
CAB_C = Vector((0, 0, 1.24))       # centro de la cabeza
CAB_R = (0.265, 0.245, 0.25)       # radios x, y (fondo), z
HOMBRO = Vector((0.15, 0.0, 0.885))
CODO = Vector((0.215, 0.0, 0.705))
MUNECA = Vector((0.255, -0.012, 0.545))
MANO_F = Vector((0.268, -0.018, 0.46))
CADERA_L = Vector((0.085, 0.0, 0.54))
RODILLA = Vector((0.09, 0.0, 0.28))
TOBILLO = Vector((0.09, 0.012, 0.085))
PUNTA = Vector((0.09, -0.11, 0.02))
OJO = (0.17, 0.44, 0.084, 0.104)  # en la loseta de la cara: separación, altura, radios


def esp(v, lado):
    return Vector((v.x * lado, v.y, v.z))


def huesos(lado_nombre=(("L", 1), ("R", -1))):
    h = [("raiz", (0, 0, 0), (0, 0, 0.12), None),
         ("cadera", (0, 0, 0.54), (0, 0, 0.62), "raiz"),
         ("columna", (0, 0, 0.62), (0, 0, 0.74), "cadera"),
         ("pecho", (0, 0, 0.74), (0, 0, 0.92), "columna"),
         ("cuello", (0, 0, 0.92), (0, 0, 1.0), "pecho"),
         ("cabeza", (0, 0, 1.0), (0, 0, 1.46), "cuello")]
    for s, l in lado_nombre:
        ojo_top = ojo_mundo(l, arriba=True)
        h += [("parpado." + s, ojo_top, ojo_top + Vector((0, 0, -0.05)), "cabeza"),
              ("hombro." + s, (0.04 * l, 0, 0.875), esp(HOMBRO, l), "pecho"),
              ("brazo." + s, esp(HOMBRO, l), esp(CODO, l), "hombro." + s),
              ("antebrazo." + s, esp(CODO, l), esp(MUNECA, l), "brazo." + s),
              ("mano." + s, esp(MUNECA, l), esp(MANO_F, l), "antebrazo." + s),
              ("muslo." + s, esp(CADERA_L, l), esp(RODILLA, l), "cadera"),
              ("pierna." + s, esp(RODILLA, l), esp(TOBILLO, l), "muslo." + s),
              ("pie." + s, esp(TOBILLO, l), esp(PUNTA, l), "pierna." + s)]
    return h


# --- la cara: proyección frontal de la cabeza sobre la loseta «cara» -----------------------------------------------

def cara_uv(co):
    u = (co.x - CAB_C.x) / (2 * CAB_R[0]) + 0.5
    v = (co.z - CAB_C.z) / (2 * CAB_R[2]) + 0.5
    return u, v


def ojo_mundo(lado, arriba=False):
    """Punto de la superficie de la cabeza en el centro del ojo (o justo encima del párpado superior)."""
    sep, alto, rx, ry = OJO
    u = 0.5 + sep * (-1 if lado > 0 else 1) * -1   # el ojo izquierdo del personaje (+X) cae a la derecha de la loseta
    v = alto + (ry * 1.18 if arriba else 0.0)
    x = (u - 0.5) * 2 * CAB_R[0]
    z = (v - 0.5) * 2 * CAB_R[2] + CAB_C.z
    nx, nz = x / CAB_R[0], (z - CAB_C.z) / CAB_R[2]
    ny = -math.sqrt(max(1 - nx * nx - nz * nz, 0.01))
    return Vector((x, ny * CAB_R[1] * barbilla_k(z), z))


def barbilla_k(z):
    """Afinado de la mitad de abajo de la cabeza (mentón redondo de chibi)."""
    d = (CAB_C.z - z) / CAB_R[2]
    return 1.0 - 0.22 * max(d, 0) ** 2


def deform_cabeza(co):
    k = barbilla_k(co.z)
    return Vector((co.x * k, co.y * k, co.z))


def dibujar_cara(A, P):
    L = C.Lienzo(A, "cara")
    L.fondo(P["piel"])
    sep, alto, rx, ry = OJO
    # rubor y nariz
    for s in (-1, 1):
        L.elipse(0.5 + s * 0.2, 0.335, 0.055, 0.03, P["rubor"], 0.35)
    L.elipse(0.5, 0.365, 0.010, 0.007, [c * 0.82 for c in P["piel"]], 0.8)
    if P.get("pecas"):
        for (x, y) in ((0.30, 0.37), (0.33, 0.35), (0.28, 0.345), (0.70, 0.37), (0.67, 0.35), (0.72, 0.345),
                       (0.31, 0.33), (0.69, 0.33)):
            L.elipse(x, y, 0.006, 0.005, [c * 0.72 for c in P["piel"]], 0.7)
    for s in (-1, 1):
        cx, cy = 0.5 + s * sep, alto
        L.elipse(cx, cy, rx, ry * 0.96, (0.97, 0.96, 0.93))
        L.degradado_elipse(cx, cy - 0.006, rx * 0.80, ry * 0.86, P["iris_arriba"], P["iris_abajo"])
        L.elipse(cx, cy - 0.002, rx * 0.36, ry * 0.46, [c * 0.35 for c in P["iris_arriba"]])
        L.elipse(cx - 0.022, cy + 0.032, 0.019, 0.022, (1, 1, 1))
        L.elipse(cx + 0.018, cy - 0.034, 0.009, 0.009, (1, 1, 1), 0.85)
        if P.get("cansada"):
            # párpado a media altura: la mirada de quien lleva días esperando (ironía cansada)
            L.rect(cx - rx * 1.3, cy + ry * 0.42, cx + rx * 1.3, cy + ry * 1.3, P["piel"])
            L.arco(cx, cy + ry * 0.05, rx * 1.12, ry * 0.40, 8, 172, 0.016, P["pestanas"])
            L.arco(cx, cy + ry * 0.12, rx * 1.05, ry * 0.36, 30, 150, 0.006, [c * 0.85 for c in P["piel"]], 0.7)
        else:
            L.arco(cx, cy - ry * 0.08, rx * 1.10, ry * 1.02, 12, 168, 0.018, P["pestanas"])
        # rabillo hacia fuera
        fx = cx + s * rx * 1.06
        L.linea([(fx, cy + ry * (0.45 if P.get("cansada") else 0.25)), (fx + s * 0.018, cy + ry * 0.55)], 0.012,
                P["pestanas"], grosor_fin=0.003)
        L.arco(cx, cy + ry * 0.15, rx * 0.95, ry * 1.05, 235, 305, 0.005, P["pestanas"], 0.7)
        # cejas
        if P.get("cansada"):
            L.arco(cx + s * 0.01, alto + 0.115, 0.075, 0.025, 20, 160, 0.010, P["cejas"])
        else:
            L.arco(cx, alto + 0.135, 0.07, 0.035, 25, 155, 0.011, P["cejas"])
    boca = P["boca"]
    if boca == "media_sonrisa":
        L.linea([(0.455, 0.268), (0.50, 0.262), (0.535, 0.272), (0.548, 0.286)], 0.009, P["labios"])
    elif boca == "risa":
        L.elipse(0.5, 0.272, 0.06, 0.048, (0.45, 0.12, 0.12))
        L.rect(0.43, 0.272, 0.57, 0.34, P["piel"])
        L.rect(0.452, 0.262, 0.548, 0.272, (0.98, 0.97, 0.94))
        L.elipse(0.5, 0.238, 0.028, 0.014, (0.86, 0.42, 0.42))
        L.arco(0.5, 0.29, 0.06, 0.035, 200, 340, 0.006, P["labios"], 0.8)
    return L


def dibujar_parpado(A, nombre, piel, pestanas):
    """Muestra del párpado: piel arriba y la raya de pestañas abajo (lo que se ve cuando parpadea)."""
    A.muestra(nombre, piel, plano=True)
    x0, y0, c = A.muestras[nombre]
    px, py, pc = int(x0 * A.tam), int(y0 * A.tam), int(c * A.tam)
    A.img[py:py + int(pc * 0.30), px:px + pc, :3] = pestanas


# ------------------------------------------------------------------ partes del cuerpo comunes

def pesos_brazo(l, s):
    a, b = esp(HOMBRO, l), esp(MANO_F, l)
    te = (esp(CODO, l) - a).length / (b - a).length
    tm = (esp(MUNECA, l) - a).length / (b - a).length
    return C.por_eje(a, b, [(-0.06, "pecho"), (0.06, "hombro." + s), (0.14, "brazo." + s), (te - 0.07, "brazo." + s),
                            (te + 0.07, "antebrazo." + s), (tm - 0.04, "antebrazo." + s), (tm + 0.03, "mano." + s)])


def pesos_pierna(s):
    return [(0.03, "pie." + s), (0.10, "pierna." + s), (0.25, "pierna." + s), (0.31, "muslo." + s),
            (0.50, "muslo." + s), (0.60, "cadera")]


def cuerpo(M, P):
    for s, l in (("L", 1), ("R", -1)):
        # piernas (debajo de pantalón y botas)
        M.pintar(M.tubo([esp(CADERA_L, l) + Vector((0, 0, 0.03)), esp(RODILLA, l), esp(TOBILLO, l)],
                        [0.07, 0.052, 0.045], 10), P["pantalon"], pesos=pesos_pierna(s))
        # botas: caña y pie
        M.pintar(M.tubo([esp(TOBILLO, l) + Vector((0, 0, -0.06)), esp(TOBILLO, l) + Vector((0, 0, 0.07)),
                         esp(RODILLA, l) + Vector((0, 0, -0.08))], [0.058, 0.056, 0.06], 10), P["botas"],
                 pesos=pesos_pierna(s))
        M.pintar(M.esfera(esp(Vector((0.09, -0.045, 0.045)), l), (0.058, 0.098, 0.05), (12, 8)), P["botas"],
                 pesos=lambda co, s=s: {"pie." + s: 1.0} if co.y < -0.02 else {"pie." + s: 0.6, "pierna." + s: 0.4},
                 deform=lambda co: Vector((co.x, co.y, max(co.z, 0.0))))
        M.pintar(M.tubo([esp(Vector((0.09, -0.045, 0.003)), l), esp(Vector((0.09, -0.045, 0.016)), l)],
                        [(0.06, 0.10), (0.06, 0.10)], 12, ref=Vector((1, 0, 0))), P["suela"], pesos="pie." + s)
        # brazo: hombro, brazo, antebrazo y mano (la manga la pone cada uno)
        a, e, w, f = esp(HOMBRO, l), esp(CODO, l), esp(MUNECA, l), esp(MANO_F, l)
        M.pintar(M.tubo([a + Vector((-0.03 * l, 0, 0)), a, e, w], [0.04, 0.042, 0.036, 0.031], 10), P["piel_cuerpo"],
                 pesos=pesos_brazo(l, s))
        M.pintar(M.tubo([w, w + (f - w) * 0.35, f + (f - w) * 0.15], [(0.028, 0.02), (0.034, 0.024), (0.02, 0.016)],
                        10, ref=Vector((0, 1, 0))), P["piel_cuerpo"], pesos="mano." + s)
        M.pintar(M.esfera(w + (f - w) * 0.3 + Vector((-0.022 * l, -0.02, 0)), (0.013, 0.013, 0.03), (8, 6),
                          giro=Euler((0.3, 0.4 * l, 0))), P["piel_cuerpo"], pesos="mano." + s)
    # cadera y tronco
    M.pintar(M.esfera((0, 0, 0.58), (0.15, 0.11, 0.10), (16, 10)), P["pantalon"],
             pesos=[(0.5, "cadera"), (0.62, "cadera"), (0.70, "columna")])
    M.pintar(M.tubo([(0, 0, 0.56), (0, 0, 0.70), (0, 0, 0.84), (0, 0, 0.92), (0, 0.005, 0.95)],
                    [(0.14, 0.10), (0.125, 0.09), (0.145, 0.10), (0.12, 0.09), (0.06, 0.05)], 14),
             P["camisa"], pesos=[(0.6, "cadera"), (0.68, "columna"), (0.76, "columna"), (0.82, "pecho")])
    M.pintar(M.tubo([(0, 0.01, 0.9), (0, 0.0, 1.05)], [0.048, 0.044], 10), P["piel_cuerpo"],
             pesos=[(0.92, "pecho"), (0.95, "cuello"), (1.02, "cabeza")])
    # cabeza con la cara proyectada y orejas
    def uv_cabeza(co, fc):
        rel = fc - CAB_C           # por cara (no por vértice): una cara nunca mezcla la loseta y la muestra
        if rel.y < -0.10 and abs(rel.x) < 0.24 and rel.z > -0.25:
            return M.atlas.uv_loseta("cara", *cara_uv(co))
        return M.atlas.uv_muestra(P["piel_plana"], 0.5)
    M.pintar(M.esfera(CAB_C, CAB_R, (28, 18)), uvf=uv_cabeza, pesos="cabeza", deform=deform_cabeza)
    for l in ((1, -1) if P.get("orejas") else ()):
        M.pintar(M.esfera((0.245 * l, 0.02, 1.20), (0.03, 0.045, 0.06), (8, 6)), P["piel_plana"], pesos="cabeza")
    # párpados (cerrados en el modelo; los clips los recogen con la escala del hueso «parpado»)
    sep, alto, rx, ry = OJO
    for s, l in (("L", 1), ("R", -1)):
        cu = 0.5 - sep * l * -1
        def fuera(co, cu=cu):
            u, v = cara_uv(co)
            return co.y > 0 or ((u - cu) / (rx * 1.35)) ** 2 + ((v - alto) / (ry * 1.25)) ** 2 > 1.0
        sup = ojo_mundo(l, arriba=True)
        M.pintar(M.esfera(CAB_C, [r * 1.012 for r in CAB_R], (40, 28)), P["parpado"], pesos="parpado." + s,
                 deform=deform_cabeza, quitar=fuera)


# ------------------------------------------------------------------ Ismena

def ismena(M, P):
    A = M.atlas
    # pantalón y botas ya están; túnica larga (hasta la rodilla) con cinturón, abierta un poco abajo
    M.pintar(M.tubo([(0, 0.005, 0.95), (0, 0, 0.90), (0, 0, 0.80), (0, 0, 0.66), (0, 0, 0.56), (0, 0.01, 0.42),
                     (0, 0.015, 0.27)],
                    [(0.075, 0.06), (0.135, 0.10), (0.155, 0.112), (0.138, 0.102), (0.17, 0.125), (0.19, 0.145),
                     (0.215, 0.165)], 18, tapas=(False, False)),
             P["tunica"], pesos=[(0.30, "cadera"), (0.56, "cadera"), (0.66, "columna"), (0.76, "columna"),
                                 (0.84, "pecho"), (0.93, "pecho"), (0.96, "cuello")],
             quitar=lambda co: co.z < 0.45 and co.y < -0.12 and abs(co.x) < 0.035)
    # ribete claro del bajo
    M.pintar(M.tubo([(0, 0.015, 0.30), (0, 0.016, 0.255)], [(0.212, 0.163), (0.218, 0.168)], 18, (False, False)),
             P["pañuelo"], pesos="cadera",
             quitar=lambda co: co.y < -0.12 and abs(co.x) < 0.035)
    # cinturón y bolsas
    M.pintar(M.tubo([(0, 0, 0.635), (0, 0, 0.675)], [(0.147, 0.108), (0.145, 0.106)], 16), P["cuero"],
             pesos=[(0.62, "cadera"), (0.68, "columna")])
    M.pintar(M.caja((0.0, -0.11, 0.655), (0.05, 0.02, 0.045)), P["laton"], pesos="columna", liso=False)
    for x, h in ((0.12, 0.08), (-0.135, 0.07)):
        M.pintar(M.caja((x, -0.06, 0.6), (0.06, 0.05, h), Euler((0, 0, 0.5 if x > 0 else -0.5))), P["cuero"],
                 pesos="cadera", liso=False)
    # mangas holgadas hasta la muñeca, con puño claro remangado
    for s, l in (("L", 1), ("R", -1)):
        a, e, w = esp(HOMBRO, l), esp(CODO, l), esp(MUNECA, l)
        M.pintar(M.tubo([a + Vector((-0.04 * l, 0, 0.01)), a + Vector((0.01 * l, 0, 0.005)), e, w + (e - w) * 0.25],
                        [0.06, 0.062, 0.056, 0.058], 12), P["tunica"], pesos=pesos_brazo(l, s))
        M.pintar(M.tubo([w + (e - w) * 0.30, w + (e - w) * 0.12], [0.062, 0.06], 12), P["pañuelo"],
                 pesos=pesos_brazo(l, s))
    # pañuelo arena al cuello, con una punta que cae por delante
    anillo = [(0.12 * math.cos(a), 0.10 * math.sin(a) + 0.005, 0.93 + 0.012 * math.sin(a))
              for a in [math.radians(d) for d in range(-90, 300, 30)]]
    M.pintar(M.tubo(anillo, [0.04] * len(anillo), 8), P["pañuelo"], pesos=[(0.9, "pecho"), (0.97, "cuello")])
    M.pintar(M.tubo([(0.03, -0.11, 0.92), (0.05, -0.135, 0.83), (0.055, -0.13, 0.76)], [(0.04, 0.012), (0.045, 0.012),
                                                                                        (0.03, 0.01)], 6),
             P["pañuelo"], pesos="pecho")
    # pelo: casquete, flequillo de lado, mechones y la trenza sobre el hombro derecho (que cae por delante)
    hair_c = CAB_C + Vector((0, 0.012, 0.02))
    def sin_frente(co):
        r = co - hair_c
        return (r.y < -0.05 and r.z < 0.13 - 0.25 * max(-r.x, 0) * 0) or r.z < -0.20 or (r.y < 0.10 and r.z < -0.02)
    M.pintar(M.esfera(hair_c, (0.282, 0.262, 0.262), (24, 16)), P["pelo"], pesos="cabeza", deform=deform_cabeza,
             quitar=sin_frente)
    for i, (bx, bz, tx, ty, tz, r) in enumerate((
            (-0.17, 1.40, -0.21, -0.22, 1.19, 0.05), (-0.09, 1.43, -0.13, -0.25, 1.28, 0.055),
            (0.0, 1.44, 0.02, -0.255, 1.31, 0.055), (0.09, 1.43, 0.13, -0.25, 1.30, 0.05),
            (0.18, 1.40, 0.24, -0.20, 1.22, 0.045))):
        base = Vector((bx, -0.13, bz))
        M.pintar(M.tubo([base, base.lerp(Vector((tx, ty, tz)), 0.55) + Vector((0, -0.03, 0.01)), Vector((tx, ty, tz))],
                        [(r * 1.15, r * 0.42), (r * 0.95, r * 0.36), (0.014, 0.008)], 6, ref=Vector((1, 0, 0))),
                 P["pelo"], pesos="cabeza")
    for l in (1, -1):   # mechones a los lados de la cara
        M.pintar(M.tubo([(0.24 * l, -0.12, 1.36), (0.265 * l, -0.13, 1.20), (0.245 * l, -0.115, 1.10)],
                        [(0.045, 0.03), (0.04, 0.026), (0.016, 0.01)], 6), P["pelo"], pesos="cabeza")
    trenza = [Vector((-0.17, 0.12, 1.08)), Vector((-0.2, 0.06, 0.96)), Vector((-0.17, -0.06, 0.86)),
              Vector((-0.15, -0.105, 0.76)), Vector((-0.145, -0.115, 0.67))]
    for i in range(len(trenza) - 1):
        for k in range(2):
            p = trenza[i].lerp(trenza[i + 1], 0.25 + 0.5 * k)
            M.pintar(M.esfera(p, (0.035, 0.032, 0.045), (10, 6)), P["pelo"],
                     pesos=lambda co: C.por_altura(co.z, [(0.82, "pecho"), (1.0, "cabeza")]))
    M.pintar(M.esfera((-0.145, -0.118, 0.645), (0.022, 0.022, 0.014), (8, 5)), P["cinta"], pesos="pecho")
    # sombrero de ala ancha (algo caído) con cinta azul verdosa y una aguja de latón
    sc = Vector((0, 0.02, 1.47))
    giro = Euler((math.radians(-8), 0, 0))
    def caida(co):
        r = co - sc
        d = math.hypot(r.x, r.y)
        return co + Vector((0, 0, -0.05 * max(d - 0.22, 0) / 0.22))
    ala = M.tubo([sc + Vector((0, 0, -0.008)), sc + Vector((0, 0, 0.008))], [0.44, 0.44], 28, ref=Vector((1, 0, 0)))
    M.pintar(ala, P["sombrero"], pesos="cabeza", deform=lambda co: giro_alrededor(caida(co), sc, giro))
    copa = M.tubo([sc, sc + Vector((0, 0, 0.09)), sc + Vector((0, 0, 0.15)), sc + Vector((0, 0, 0.165))],
                  [(0.215, 0.20), (0.20, 0.19), (0.17, 0.16), (0.08, 0.075)], 20)
    M.pintar(copa, P["sombrero"], pesos="cabeza", deform=lambda co: giro_alrededor(co, sc, giro))
    M.pintar(M.tubo([sc + Vector((0, 0, 0.012)), sc + Vector((0, 0, 0.045))], [(0.218, 0.203), (0.212, 0.198)], 20),
             P["cinta"], pesos="cabeza", deform=lambda co: giro_alrededor(co, sc, giro))
    M.pintar(M.esfera(sc + Vector((0.12, -0.17, 0.03)), (0.022, 0.012, 0.022), (8, 6)), P["laton"], pesos="cabeza",
             deform=lambda co: giro_alrededor(co, sc, giro))
    # el estuche de mapas a la espalda (cruzado) con dos rollos que asoman, y la correa
    t0, t1 = Vector((-0.17, 0.16, 0.55)), Vector((0.16, 0.17, 1.02))
    M.pintar(M.tubo([t0, t1], [0.048, 0.048], 12), P["cuero"],
             pesos=lambda co: C.por_altura(co.z, [(0.6, "columna"), (0.8, "pecho")]))
    for p in (t0, t1):
        M.pintar(M.tubo([p - (t1 - t0).normalized() * 0.012, p + (t1 - t0).normalized() * 0.012], [0.053, 0.053], 12),
                 P["laton"], pesos="pecho" if p.z > 0.8 else "columna")
    for dx, largo in ((0.018, 0.13), (-0.02, 0.09)):
        b = t1 + Vector((dx, 0.0, 0.0))
        M.pintar(M.tubo([b, b + (t1 - t0).normalized() * largo], [0.019, 0.019], 8), P["pergamino"], pesos="pecho")
        M.pintar(M.tubo([b + (t1 - t0).normalized() * (largo * 0.5 - 0.006),
                         b + (t1 - t0).normalized() * (largo * 0.5 + 0.006)], [0.0205, 0.0205], 8), P["cinta_roja"],
                 pesos="pecho")
    correa = [Vector((0.15, 0.10, 0.96)), Vector((0.15, -0.06, 0.92)), Vector((0.04, -0.125, 0.80)),
              Vector((-0.12, -0.11, 0.64)), Vector((-0.17, 0.05, 0.58))]
    M.pintar(M.tubo(correa, [(0.012, 0.024)] * len(correa), 6, ref=Vector((0, 1, 0))), P["cuero"],
             pesos=lambda co: C.por_altura(co.z, [(0.62, "cadera"), (0.70, "columna"), (0.85, "pecho")]))
    # la tablilla con el mapa (mano izquierda) y el lápiz (mano derecha)
    w, f = esp(MUNECA, 1), esp(MANO_F, 1)
    eje = (f - w).normalized()
    centro = w + eje * 0.07 + Vector((0.0, -0.035, 0.0))
    tabla = M.caja(centro, (0.015, 0.22, 0.28), Euler((0.25, 0, 0.18)))
    def uv_tabla(co, fc):
        r = co - centro
        return A.uv_loseta("detalle", min(max(0.5 + r.y / 0.24, 0), 1), min(max(0.5 + r.z / 0.30, 0), 1))
    M.pintar(tabla, uvf=uv_tabla, pesos="mano.L", liso=False)
    wr, fr = esp(MUNECA, -1), esp(MANO_F, -1)
    pl = wr + (fr - wr) * 0.55 + Vector((0.0, -0.025, 0.0))
    d = Vector((0.0, -0.35, -1.0)).normalized()
    M.pintar(M.tubo([pl - d * 0.05, pl + d * 0.07], [0.006, 0.006], 6), P["lapiz"], pesos="mano.R")
    M.pintar(M.cono(pl + d * 0.07, pl + d * 0.09, 0.006, 6), P["grafito"], pesos="mano.R")


def giro_alrededor(co, centro, euler):
    return Vector(centro) + euler.to_matrix() @ (Vector(co) - Vector(centro))


def dibujar_mapa(A, P):
    """El mapa de la tablilla: pergamino, la costa de cristal, dunas, el oasis, una ruta punteada y la rosa."""
    L = C.Lienzo(A, "detalle")
    L.fondo(P["pergamino_rgb"], grano=0.03)
    tinta = (0.28, 0.18, 0.10)
    L.rect(0.0, 0.0, 1.0, 0.03, (0.55, 0.40, 0.25))
    L.rect(0.0, 0.97, 1.0, 1.0, (0.55, 0.40, 0.25))
    costa = [(0.05, 0.85), (0.18, 0.78), (0.25, 0.82), (0.38, 0.72), (0.52, 0.76), (0.63, 0.66), (0.80, 0.70),
             (0.95, 0.60)]
    L.linea(costa, 0.008, tinta)
    L.linea([(x, y + 0.03) for x, y in costa], 0.003, (0.35, 0.55, 0.6), 0.7)
    for i in range(14):
        x, y = 0.1 + (i * 0.137) % 0.8, 0.15 + (i * 0.23) % 0.45
        L.arco(x, y, 0.04, 0.02, 20, 160, 0.004, tinta, 0.8)
    L.elipse(0.72, 0.38, 0.06, 0.04, (0.35, 0.55, 0.62), 0.8)
    pts = [(0.15, 0.08), (0.25, 0.22), (0.38, 0.30), (0.5, 0.42), (0.62, 0.5), (0.7, 0.62)]
    for a, b in zip(pts, pts[1:]):
        for k in range(3):
            t0, t1 = k / 3, k / 3 + 0.18
            L.linea([(a[0] + (b[0] - a[0]) * t0, a[1] + (b[1] - a[1]) * t0),
                     (a[0] + (b[0] - a[0]) * t1, a[1] + (b[1] - a[1]) * t1)], 0.006, (0.65, 0.15, 0.12))
    L.linea([(0.66, 0.58), (0.74, 0.66)], 0.008, (0.65, 0.15, 0.12))
    L.linea([(0.74, 0.58), (0.66, 0.66)], 0.008, (0.65, 0.15, 0.12))
    cx, cy = 0.2, 0.62
    L.linea([(cx, cy - 0.09), (cx, cy + 0.09)], 0.006, tinta)
    L.linea([(cx - 0.09, cy), (cx + 0.09, cy)], 0.006, tinta)
    L.linea([(cx, cy + 0.09), (cx - 0.02, cy + 0.05), (cx + 0.02, cy + 0.05), (cx, cy + 0.09)], 0.008, tinta)
    L.arco(cx, cy, 0.05, 0.05, 0, 360, 0.003, tinta, n=40)


# ------------------------------------------------------------------ Oren

def oren(M, P):
    # pantalón holgado (abombado por encima de la bota) con un remiendo en la rodilla
    for s, l in (("L", 1), ("R", -1)):
        M.pintar(M.tubo([esp(CADERA_L, l) + Vector((0, 0, 0.05)), esp(CADERA_L, l) + Vector((0.005 * l, 0, -0.08)),
                         esp(RODILLA, l), esp(RODILLA, l) + Vector((0, 0, -0.08)), esp(TOBILLO, l) + Vector((0, 0, 0.1))],
                        [0.085, 0.088, 0.078, 0.075, 0.062], 12), P["pantalon"], pesos=pesos_pierna(s))
        M.pintar(M.caja(esp(RODILLA, l) + Vector((0.0, -0.075, 0.01)), (0.06, 0.012, 0.06)), P["remiendo"],
                 pesos=pesos_pierna(s), liso=False)
    # chaleco pardo abierto por delante, sobre la camisa
    M.pintar(M.tubo([(0, 0, 0.62), (0, 0, 0.72), (0, 0, 0.84), (0, 0.005, 0.915)],
                    [(0.152, 0.112), (0.137, 0.102), (0.157, 0.112), (0.13, 0.10)], 16, tapas=(False, False)),
             P["chaleco"], pesos=[(0.62, "cadera"), (0.68, "columna"), (0.76, "columna"), (0.82, "pecho")],
             quitar=lambda co: co.y < -0.06 and abs(co.x) < 0.045)
    # faja ocre
    M.pintar(M.tubo([(0, 0, 0.60), (0, 0, 0.665)], [(0.158, 0.118), (0.152, 0.112)], 16), P["faja"],
             pesos=[(0.6, "cadera"), (0.68, "columna")])
    M.pintar(M.tubo([(0.11, -0.08, 0.62), (0.13, -0.1, 0.53), (0.12, -0.09, 0.47)], [(0.03, 0.01), (0.028, 0.01),
                                                                                    (0.024, 0.008)], 6),
             P["faja"], pesos="cadera")
    # mangas remangadas hasta el codo (antebrazos al sol)
    for s, l in (("L", 1), ("R", -1)):
        a, e = esp(HOMBRO, l), esp(CODO, l)
        M.pintar(M.tubo([a + Vector((-0.04 * l, 0, 0.01)), a + Vector((0.01 * l, 0, 0.005)), e + (a - e) * 0.15],
                        [0.06, 0.062, 0.058], 12), P["camisa"], pesos=pesos_brazo(l, s))
        M.pintar(M.tubo([e + (a - e) * 0.22, e + (a - e) * 0.02], [0.064, 0.06], 12), P["camisa"],
                 pesos=pesos_brazo(l, s))
        # muñequera de cuero
        w = esp(MUNECA, l)
        M.pintar(M.tubo([w + (e - w) * 0.2, w + (e - w) * 0.04], [0.038, 0.036], 10), P["cuero"],
                 pesos=pesos_brazo(l, s))
    # pañuelo arena suelto al cuello
    anillo = [(0.125 * math.cos(a), 0.10 * math.sin(a) + 0.005, 0.925 + 0.02 * math.sin(a))
              for a in [math.radians(d) for d in range(-90, 300, 30)]]
    M.pintar(M.tubo(anillo, [0.038] * len(anillo), 8), P["pañuelo"], pesos=[(0.9, "pecho"), (0.97, "cuello")])
    # la bota de agua (vacía: dos días de sed) a la cadera derecha y la bolsa del libro de cuentas a la izquierda
    M.pintar(M.esfera((-0.17, -0.02, 0.50), (0.05, 0.04, 0.08), (12, 8)), P["odre"], pesos="cadera",
             deform=lambda co: co + Vector((0, 0, -0.02 * max(0, 0.5 - co.z) / 0.08)))
    M.pintar(M.tubo([(-0.17, -0.02, 0.575), (-0.17, -0.02, 0.61)], [0.014, 0.012], 6), P["cuero"], pesos="cadera")
    M.pintar(M.caja((0.175, 0.01, 0.50), (0.05, 0.12, 0.11), Euler((0, 0.1, 0))), P["cuero"], pesos="cadera",
             liso=False)
    M.pintar(M.caja((0.18, -0.005, 0.535), (0.055, 0.125, 0.04), Euler((0, 0.1, 0))), P["cuero_osc"],
             pesos="cadera", liso=False)
    # la cuerda del arriero, enrollada en bandolera (hombro izquierdo a cadera derecha): silueta propia de Oren
    for k, dz in enumerate((0.0, 0.025, -0.022)):
        aro = [Vector((0.02 + 0.155 * math.cos(a) * 0.95, 0.123 * math.sin(a) * 1.1, 0.72 + dz + 0.17 * math.cos(a)))
               for a in [math.radians(d) for d in range(0, 375, 22)]]
        M.pintar(M.tubo(aro, [0.017] * len(aro), 6), "cuerda",
                 pesos=lambda co: C.por_altura(co.z, [(0.6, "cadera"), (0.7, "columna"), (0.85, "pecho")]))
    # pelo castaño revuelto que asoma y el pañuelo rojo del toldo atado a la cabeza
    hair_c = CAB_C + Vector((0, 0.01, 0.015))
    M.pintar(M.esfera(hair_c, (0.278, 0.258, 0.258), (24, 16)), P["pelo"], pesos="cabeza", deform=deform_cabeza,
             quitar=lambda co: (co - hair_c).y < -0.06 and (co - hair_c).z < 0.12 or (co - hair_c).z < -0.16)
    for (bx, bz, tx, ty, tz, r) in ((-0.16, 1.38, -0.22, -0.24, 1.25, 0.05), (-0.06, 1.41, -0.07, -0.27, 1.30, 0.05),
                                    (0.05, 1.41, 0.09, -0.27, 1.29, 0.05), (0.15, 1.38, 0.23, -0.23, 1.24, 0.045),
                                    (0.24, 1.30, 0.32, -0.10, 1.18, 0.04), (-0.24, 1.30, -0.32, -0.08, 1.20, 0.04),
                                    (0.22, 1.22, 0.29, 0.10, 1.08, 0.04), (-0.21, 1.22, -0.28, 0.12, 1.07, 0.04),
                                    (0.0, 1.25, 0.03, 0.30, 1.08, 0.05)):
        base = Vector((bx, -0.12 if ty < 0 else 0.10, bz))
        M.pintar(M.tubo([base, base.lerp(Vector((tx, ty, tz)), 0.5) + Vector((0, 0, 0.03)), Vector((tx, ty, tz))],
                        [(r, r * 0.6), (r * 0.7, r * 0.45), 0.004], 6), P["pelo"], pesos="cabeza")
    bc = CAB_C + Vector((0, 0.015, 0.06))
    M.pintar(M.esfera(bc, (0.29, 0.27, 0.26), (24, 14)), P["toldo"], pesos="cabeza", deform=deform_cabeza,
             quitar=lambda co: (co - bc).z < 0.07 + 0.06 * max(0.0, -(co - bc).y) / 0.27)
    M.pintar(M.tubo([bc + Vector((0, 0, 0.06))] + [bc + Vector((0, 0, 0.12))],
                    [(0.29, 0.27), (0.27, 0.25)], 24, (False, False)), P["toldo_osc"], pesos="cabeza",
             deform=deform_cabeza)
    nudo = Vector((0.0, 0.27, 1.32))
    M.pintar(M.esfera(nudo, (0.045, 0.035, 0.04), (10, 6)), P["toldo"], pesos="cabeza")
    for l in (1, -1):
        M.pintar(M.tubo([nudo, nudo + Vector((0.07 * l, 0.06, -0.08)), nudo + Vector((0.09 * l, 0.07, -0.20))],
                        [(0.04, 0.008), (0.035, 0.008), (0.02, 0.006)], 6, ref=Vector((1, 0, 0))), P["toldo"],
                 pesos="cabeza")


# ------------------------------------------------------------------ paletas

PIEL = (0.86, 0.64, 0.50)              # los dos, al sol del desierto
PELO = (0.34, 0.16, 0.10)              # castaño rojizo oscuro, el mismo
OJOS = ((0.30, 0.20, 0.10), (0.85, 0.62, 0.26))   # ámbar: arriba oscuro, abajo claro


def paleta(A, quien):
    P = {"piel": PIEL, "rubor": (0.95, 0.52, 0.48), "iris_arriba": OJOS[0], "iris_abajo": OJOS[1],
         "pestanas": (0.16, 0.08, 0.06), "cejas": (0.30, 0.14, 0.09), "labios": (0.55, 0.25, 0.22)}
    A.muestra("piel_plana", PIEL, plano=True)
    A.muestra("piel_cuerpo", PIEL, oscuro=0.9, claro=1.02, grano=0)
    dibujar_parpado(A, "parpado", PIEL, (0.16, 0.08, 0.06))
    A.muestra("pelo", PELO, oscuro=0.75, claro=1.15, grano=0.03)
    A.muestra("suela", (0.22, 0.16, 0.11))
    A.muestra("cuero", (0.42, 0.27, 0.16))
    A.muestra("cuero_osc", (0.30, 0.19, 0.12))
    A.muestra("pañuelo", (0.86, 0.78, 0.60))
    if quien == "ismena":
        P.update(cansada=True, boca="media_sonrisa", pergamino_rgb=(0.93, 0.85, 0.66))
        A.muestra("tunica", (0.26, 0.47, 0.56), oscuro=0.72)
        A.muestra("camisa", (0.80, 0.74, 0.60))
        A.muestra("pantalon", (0.55, 0.45, 0.33))
        A.muestra("botas", (0.50, 0.33, 0.20), oscuro=0.7)
        A.muestra("sombrero", (0.80, 0.62, 0.38), oscuro=0.75, claro=1.08)
        A.muestra("cinta", (0.20, 0.38, 0.45))
        A.muestra("laton", (0.85, 0.66, 0.30), oscuro=0.7, claro=1.15)
        A.muestra("pergamino", (0.93, 0.85, 0.66))
        A.muestra("cinta_roja", (0.72, 0.20, 0.16))
        A.muestra("lapiz", (0.35, 0.22, 0.12))
        A.muestra("grafito", (0.12, 0.12, 0.12))
    else:
        P.update(cansada=False, boca="risa", pecas=True, orejas=True)
        A.muestra("camisa", (0.90, 0.85, 0.72))
        A.muestra("chaleco", (0.62, 0.36, 0.22), oscuro=0.72)
        A.muestra("pantalon", (0.52, 0.44, 0.30), oscuro=0.62)
        A.muestra("remiendo", (0.40, 0.48, 0.42))
        A.muestra("botas", (0.40, 0.27, 0.17), oscuro=0.7)
        A.muestra("faja", (0.80, 0.55, 0.22))
        A.muestra("toldo", (0.80, 0.24, 0.20), oscuro=0.75)
        A.muestra("toldo_osc", (0.70, 0.20, 0.17))
        A.muestra("odre", (0.55, 0.36, 0.22), oscuro=0.7)
        A.muestra("cuerda", (0.72, 0.62, 0.42), oscuro=0.75)
    for k in list(A.muestras):
        P.setdefault(k, k)
    P["piel_plana"] = "piel_plana"
    P["piel_cuerpo"] = "piel_cuerpo"
    P["parpado"] = "parpado"
    return P


# ------------------------------------------------------------------ poses y clips

ABIERTOS = {"parpado.L@esc": (1, 0.04, 1), "parpado.R@esc": (1, 0.04, 1)}
CERRADOS = {"parpado.L@esc": (1, 1, 1), "parpado.R@esc": (1, 1, 1)}


def con_ojos(p, cerrados=False):
    return C.sumar(p, CERRADOS if cerrados else ABIERTOS)


def reposo_ismena():
    # peso en la pierna derecha, tablilla contra la cadera (brazo izquierdo doblado), lápiz colgando en la derecha
    return {"cadera": (0, -3, 4), "columna": (2, 2, -3), "pecho": (0, 1, 0), "cabeza": (4, -3, 5),
            "cuello": (-2, 0, 0),
            "brazo.L": (-10, -8, 8), "antebrazo.L": (-62, 0, 25), "mano.L": (0, 0, -20),
            "brazo.R": (2, 6, -6), "antebrazo.R": (-18, 0, -5), "mano.R": (-8, 0, 0),
            "muslo.L": (-4, -3, 6), "pierna.L": (8, 0, 0), "pie.L": (-4, 0, 6),
            "muslo.R": (0, 1, -3), "pie.R": (0, 0, -4), "raiz@loc": (-0.012, 0, 0)}


def reposo_oren():
    # pulgar en la faja (mano izquierda), la derecha suelta; un pie adelantado, siempre a punto de contar algo
    return {"cadera": (0, 3, -4), "columna": (-3, -2, 4), "pecho": (-2, 0, 0), "cabeza": (-3, 4, -4),
            "brazo.L": (6, -14, 0), "antebrazo.L": (-60, 0, -35), "mano.L": (10, 0, 10),
            "brazo.R": (-4, 10, -4), "antebrazo.R": (-25, 0, 0), "mano.R": (-6, 0, 0),
            "muslo.L": (-8, -4, 8), "pierna.L": (6, 0, 0), "pie.L": (3, 0, 10),
            "muslo.R": (2, 2, -4), "pie.R": (-2, 0, -6), "raiz@loc": (0.01, 0, 0)}


def clips_ismena(arm):
    R = reposo_ismena()
    resp = {"pecho": (-1.5, 0, 0), "cabeza": (1.5, 0, 0), "hombro.L": (0, 0, 2), "hombro.R": (0, 0, -2)}
    # reposo: respiración, un leve cambio de peso a los 2 s y dos parpadeos
    mov = C.sumar(R, {"cadera": (0, -1.5, -1), "raiz@loc": (-0.006, 0, 0), "cabeza": (0, 2, -6)})
    C.crear_clip(arm, "reposo", [
        (1, con_ojos(R)), (30, con_ojos(C.sumar(R, resp))), (44, con_ojos(C.sumar(R, resp), True)),
        (47, con_ojos(C.sumar(R, resp))), (61, con_ojos(mov)), (90, con_ojos(C.sumar(mov, resp))),
        (106, con_ojos(C.sumar(mov, resp), True)), (109, con_ojos(C.sumar(mov, resp))), (121, con_ojos(R))])
    # hablar: levanta el lápiz y marca la dirección (hacia su derecha y al frente), un golpe de énfasis, vuelve
    senala = C.sumar(R, {"brazo.R": (-72, 12, -18), "antebrazo.R": (2, 0, 0), "mano.R": (20, 0, 0),
                         "pecho": (0, 0, -10), "cabeza": (0, 0, -16), "columna": (0, 0, -5)})
    golpe = C.sumar(senala, {"brazo.R": (-6, 0, 0), "antebrazo.R": (-12, 0, 0), "cabeza": (5, 0, 0)})
    C.crear_clip(arm, "hablar", [
        (1, con_ojos(R)), (12, con_ojos(C.sumar(R, {"brazo.R": (-25, 6, -10), "antebrazo.R": (-50, 0, 0)}))),
        (22, con_ojos(senala)), (34, con_ojos(golpe)), (42, con_ojos(senala)), (48, con_ojos(senala, True)),
        (51, con_ojos(senala)), (66, con_ojos(C.sumar(R, {"antebrazo.R": (-30, 0, 0)}))), (76, con_ojos(R))])
    # mapa: sube la tablilla, baja la mirada y traza con el lápiz (tres trazos), la baja
    leer = C.sumar(R, {"brazo.L": (-22, 6, -4), "antebrazo.L": (-28, 0, -12), "mano.L": (-10, 0, 25),
                       "brazo.R": (-38, -4, 14), "antebrazo.R": (-55, 0, 25), "mano.R": (15, 0, 0),
                       "cabeza": (16, 0, -2), "cuello": (6, 0, 0), "pecho": (3, 0, 0)})
    claves = [(1, con_ojos(R)), (20, con_ojos(leer))]
    for i, f in enumerate(range(30, 91, 12)):
        claves.append((f, con_ojos(C.sumar(leer, {"antebrazo.R": (4 if i % 2 else -4, 0, 6 if i % 2 else -6),
                                                   "mano.R": (6 if i % 2 else -2, 0, 0)}))))
    claves += [(95, con_ojos(leer, True)), (98, con_ojos(leer)),
               (104, con_ojos(C.sumar(leer, {"cabeza": (-12, 0, 6)}))), (121, con_ojos(R))]
    C.crear_clip(arm, "mapa", claves)
    # horizonte: se vuelve hacia el camino del sur (a su derecha), aprieta la tablilla contra el pecho, mira, y suspira
    # (busca a su hermano). Con los brazos cortos de chibi la mano no llega a hacer visera (probado: queda en la
    # barbilla), así que la espera se cuenta con el giro, la tablilla y el suspiro.
    mira = C.sumar(R, {"cabeza": (-8, 0, -26), "cuello": (-4, 0, -10), "pecho": (-2, 0, -10), "columna": (0, 0, -6),
                       "brazo.L": (-14, 2, -8), "antebrazo.L": (-30, 0, 10), "mano.L": (0, 0, 10),
                       "brazo.R": (-14, -8, 6), "antebrazo.R": (-55, 0, 15), "pie.R": (0, 0, -10)})
    suspiro = C.sumar(mira, {"pecho": (8, 0, 0), "cabeza": (12, 0, 4), "hombro.L": (0, 0, -4), "hombro.R": (0, 0, 4),
                             "raiz@loc": (0, 0, -0.008)})
    C.crear_clip(arm, "horizonte", [
        (1, con_ojos(R)), (20, con_ojos(mira)), (45, con_ojos(C.sumar(mira, {"cabeza": (0, 0, -6)}))),
        (58, con_ojos(C.sumar(mira, {"cabeza": (0, 0, -6)}), True)),
        (61, con_ojos(C.sumar(mira, {"cabeza": (0, 0, -6)}))), (78, con_ojos(suspiro)),
        (90, con_ojos(suspiro, True)), (96, con_ojos(suspiro)), (121, con_ojos(R))])
    # regañar: mano izquierda (con la tablilla) en la cadera, un golpe de lápiz al aire y vuelve
    # (mc_cartografa_fin: «estalla, riñendo»). Valores que SUSTITUYEN a los del reposo (no se suman).
    rinia = {**R, "brazo.L": (15, -50, 0), "antebrazo.L": (0, 100, 0), "mano.L": (0, 0, -20),
             "brazo.R": (-50, 20, -10), "antebrazo.R": (-70, 0, 10), "cabeza": (-2, -3, 5), "pecho": (-3, 0, 0)}
    C.crear_clip(arm, "reganar", [
        (1, con_ojos(R)), (10, con_ojos(rinia)), (18, con_ojos(C.sumar(rinia, {"antebrazo.R": (-25, 0, 0),
                                                                               "cabeza": (6, 0, 0)}))),
        (25, con_ojos(rinia)), (32, con_ojos(C.sumar(rinia, {"antebrazo.R": (-25, 0, 0), "cabeza": (6, 0, 0)}))),
        (44, con_ojos(rinia)), (61, con_ojos(R))])


def clips_oren(arm):
    R = reposo_oren()
    # reposo: inquieto; se mece de un pie a otro, mira alrededor
    a = C.sumar(R, {"cadera": (0, -3, 3), "raiz@loc": (-0.012, 0, 0.004), "cabeza": (0, -3, 10), "pecho": (-1.5, 0, 2)})
    b = C.sumar(R, {"cadera": (0, 2, -2), "raiz@loc": (0.006, 0, 0), "cabeza": (2, 2, -8), "pecho": (-1, 0, -2)})
    C.crear_clip(arm, "reposo", [
        (1, con_ojos(R)), (22, con_ojos(a)), (34, con_ojos(a, True)), (37, con_ojos(a)), (60, con_ojos(b)),
        (75, con_ojos(b)), (91, con_ojos(R))])
    # hablar: abre los dos brazos con las palmas arriba, un rebote y vuelve
    abre = C.sumar(R, {"brazo.L": (-36, -36, 0), "antebrazo.L": (-10, 0, 30), "mano.L": (0, -50, 0),
                       "brazo.R": (-36, 36, 0), "antebrazo.R": (-10, 0, -30), "mano.R": (0, 50, 0),
                       "pecho": (-6, 0, 0), "cabeza": (-6, 0, 0), "raiz@loc": (0, 0, 0.012)})
    rebote = C.sumar(abre, {"brazo.L": (-6, -5, 0), "brazo.R": (-6, 5, 0), "cabeza": (6, 0, 5),
                            "raiz@loc": (0, 0, -0.016)})
    C.crear_clip(arm, "hablar", [
        (1, con_ojos(R)), (10, con_ojos(abre)), (20, con_ojos(rebote)), (30, con_ojos(abre)), (38, con_ojos(rebote)),
        (46, con_ojos(abre, True)), (49, con_ojos(abre)), (76, con_ojos(R))])
    # risa: se ríe de sí mismo con la mano en la barriga y la cabeza hacia atrás; los hombros botan
    nuca = {**R, "brazo.R": (-22, -12, 0), "antebrazo.R": (-75, 0, 0), "mano.R": (0, 0, 20),
            "brazo.L": (-10, -18, 0), "antebrazo.L": (-30, 0, 0), "cabeza": (-16, -6, 4), "pecho": (-6, 0, 0),
            "cuello": (-6, 0, 0)}
    claves = [(1, con_ojos(R)), (12, con_ojos(nuca))]
    for i, f in enumerate(range(18, 55, 6)):
        claves.append((f, con_ojos(C.sumar(nuca, {"pecho": (4 if i % 2 else -2, 0, 0), "hombro.L": (0, 0, 5 if i % 2 else 0),
                                                  "antebrazo.R": (0, 0, 10 if i % 2 else -6)}), cerrados=True)))
    claves += [(60, con_ojos(nuca)), (76, con_ojos(R))]
    C.crear_clip(arm, "risa", claves)
    # encogerse: hombros arriba, palmas fuera, cabeza ladeada: se hace el tonto
    enc = C.sumar(R, {"hombro.L": (0, 0, 12), "hombro.R": (0, 0, -12), "brazo.L": (-6, -30, 0),
                      "antebrazo.L": (-40, 0, 40), "mano.L": (0, -60, 0), "brazo.R": (-6, 30, 0),
                      "antebrazo.R": (-40, 0, -40), "mano.R": (0, 60, 0), "cabeza": (0, 14, 0), "cuello": (-4, 0, 0)})
    C.crear_clip(arm, "encogerse", [(1, con_ojos(R)), (10, con_ojos(enc)), (28, con_ojos(enc)),
                                    (34, con_ojos(enc, True)), (37, con_ojos(enc)), (55, con_ojos(R))])


CLIPS = {"ismena": ["reposo", "hablar", "mapa", "horizonte", "reganar"],
         "oren": ["reposo", "hablar", "risa", "encogerse"]}
POSES_LAMINA = {"ismena": {"hablar": 34, "mapa": 50, "horizonte": 40, "reganar": 18},
                "oren": {"hablar": 20, "risa": 30, "encogerse": 20}}


# ------------------------------------------------------------------ construir, exportar y renderizar

def construir(quien):
    esc = C.escena_vacia()
    A = C.Atlas(512, semilla=7 if quien == "ismena" else 11)
    P = paleta(A, quien)
    dibujar_cara(A, P)
    if quien == "ismena":
        dibujar_mapa(A, P)
    else:
        L = C.Lienzo(A, "detalle")
        L.fondo((0.80, 0.24, 0.20))
    carpeta = os.path.join(RAIZ, "personajes", "desierto", quien)
    os.makedirs(carpeta, exist_ok=True)
    img = A.guardar(os.path.join(carpeta, quien + "_atlas.png"), quien + "_atlas")
    M = C.Malla(A)
    cuerpo(M, P)
    (ismena if quien == "ismena" else oren)(M, P)
    ob = M.objeto(quien + "_malla", esc.collection)
    ob.data.materials.append(C.material_atlas(quien, img, rugoso=0.8))
    arm = C.crear_armadura(quien, huesos(), esc.collection)
    # pesos de la malla
    for v in ob.data.vertices:
        pass
    C.enlazar(ob, arm)
    (clips_ismena if quien == "ismena" else clips_oren)(arm)
    tris = C.triangulos(ob)
    print("PERSONAJE", quien, "triangulos", tris, "vertices", len(ob.data.vertices), "huesos", len(arm.data.bones))
    C.exportar_glb(os.path.join(carpeta, quien + ".glb"))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(LAMINAS, quien + ".blend"))
    return esc, ob, arm, tris


def poner_clip(arm, nombre, fotograma):
    arm.animation_data.action = bpy.data.actions[nombre]
    bpy.context.scene.frame_set(fotograma)


def laminas(quien, esc, ob, arm, tris):
    C.preparar_render(esc, 2000, 1100, fondo=(0.93, 0.89, 0.80))
    C.luces_desierto(esc)
    C.suelo(esc)
    poner_clip(arm, "reposo", 1)
    # columnas: silueta | frente | 3/4 | espalda | Kael (muñeco a escala)
    xs = [-2.6, -1.3, 0.0, 1.3, 2.6]
    arm.location.x = xs[1]
    copias = []
    for i, (x, giro) in enumerate(((xs[0], 0), (xs[2], -35), (xs[3], 180))):
        a2 = arm.copy()
        a2.animation_data_clear()
        esc.collection.objects.link(a2)
        a2.animation_data_create()
        C.accion(a2, "reposo")
        m2 = C.silueta_de(ob, esc) if i == 0 else ob.copy()
        if i:
            esc.collection.objects.link(m2)
        m2.parent = a2
        m2.modifiers["esqueleto"].object = a2
        a2.location = (x, 0, 0)
        a2.rotation_euler = (0, 0, math.radians(giro))
        copias.append(a2)
    C.importar_kael(RAIZ, 1.7, (xs[4], 0, 0))
    for x, t in ((xs[0], "silueta"), (xs[1], "frente"), (xs[2], "3/4"), (xs[3], "espalda"), (xs[4], "Kael (1,7 m)")):
        C.texto(esc, t, (x, 0.0, 1.88), 0.11, giro=(90, 0, 0))
    nombre = "Ismena, la cartógrafa" if quien == "ismena" else "Oren, el superviviente"
    C.texto(esc, "%s  ·  PROTOTIPO V12  ·  %d triángulos, atlas 512, 1 material" % (nombre, tris),
            (0, 0.5, 2.15), 0.13, giro=(90, 0, 0))
    esc.frame_set(1)
    cam = C.camara(esc, (0, 0, 0.95), 14, 0, 6, orto=6.6)
    esc.render.filepath = os.path.join(LAMINAS, quien + "_lamina.png")
    bpy.ops.render.render(write_still=True)
    # primer plano de la cara (frente) y una lámina por gesto
    esc.render.resolution_x, esc.render.resolution_y = 900, 900
    for o in esc.objects:
        if o.name.startswith("txt"):
            o.hide_render = True
    for c in copias:
        c.hide_render = True
        for h in c.children:
            h.hide_render = True
    C.apuntar(cam, (xs[1], 0, 1.2), 10, 0, 4)
    cam.data.ortho_scale = 0.9
    esc.render.filepath = os.path.join(LAMINAS, quien + "_cara.png")
    bpy.ops.render.render(write_still=True)
    cam.data.ortho_scale = 2.3
    for clip, f in POSES_LAMINA[quien].items():
        poner_clip(arm, clip, f)
        C.apuntar(cam, (xs[1], 0, 0.85), 10, -25, 12)
        esc.render.filepath = os.path.join(LAMINAS, "%s_%s.png" % (quien, clip))
        bpy.ops.render.render(write_still=True)


for q in (["ismena", "oren"] if QUIEN == "ambos" else [QUIEN]):
    esc, ob, arm, tris = construir(q)
    laminas(q, esc, ob, arm, tris)
