# Bestiario común de producción de REBELUM (V12, 13/11/2026, especialista de enemigos «bestiario»).
# Lo que comparten los diez enemigos bípedos del encargo «Aethelgard_Bestiario_Produccion.pdf» (e01-e10): el RIG BASE de
# 22 huesos deformantes + raíz (pág. 23 del documento), los sockets, la locomoción y las reacciones comunes, la lámina de
# revisión (frente, perfil y espalda junto a Kael) y la exportación. Cada enemigo pone su malla, su atlas y sus ataques
# en enemigos/<nombre>/fuente/crear_<nombre>.py. Se apoya en desierto_comun.py y enemigos_v12_blender.py (obra propia).
#
# Nombres: el proyecto nombra los huesos en español (los guiones de los enemigos v12 y el Rig de enemigos_v12_blender, que
# busca «raiz», «muslo», «pierna», «pie», «brazo», «antebrazo» y «mano»). Equivalencia con el documento:
#   root→raiz (no deforma)  pelvis→cadera  spine_01→columna_01  spine_02→columna_02  chest→pecho  neck→cuello
#   head→cabeza  clavicle→clavicula  upper_arm→brazo  forearm→antebrazo  hand→mano  thigh→muslo  shin→pierna
#   foot→pie  toe→dedos   (22 deformantes: 6 del tronco + 8 por lado)
# Sockets: weapon.R→arma.R y weapon.L→arma.L (llevan malla rígida: deforman, como accesorios; tope del documento: 32),
# chest_fx→pecho_fx (no deforma). Además «luz» (no deforma, sin malla): su escala X es el brillo de los ojos en cada
# fotograma (lo lee enemigo_v12_3d.gd). Sin escalas negativas ni escalado animado de huesos que deformen.
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z. 1 unidad = 1 m, plantas en Z = 0.
import bpy, bmesh, math, os
from mathutils import Vector, Matrix, Quaternion
import desierto_comun as C
import enemigos_v12_blender as E

FPS = E.FPS
MAPA_HUESOS = {"root": "raiz", "pelvis": "cadera", "spine_01": "columna_01", "spine_02": "columna_02",
               "chest": "pecho", "neck": "cuello", "head": "cabeza", "clavicle": "clavicula", "upper_arm": "brazo",
               "forearm": "antebrazo", "hand": "mano", "thigh": "muslo", "shin": "pierna", "foot": "pie",
               "toe": "dedos", "weapon": "arma", "chest_fx": "pecho_fx"}
DEFORMANTES = ["cadera", "columna_01", "columna_02", "pecho", "cuello", "cabeza"] + \
    [h + s for s in (".L", ".R") for h in ("clavicula", "brazo", "antebrazo", "mano", "muslo", "pierna", "pie", "dedos")]
# Equivalencia de los 18 clips del documento con los nombres del juego (enemigo_v12_3d.gd los busca así). «carga» y
# «carga_espera» son de la adaptación al ATB (el aviso largo del tercer ataque pasa a un turno de preparación).
MAPA_CLIPS_BASE = {"spawn": "entrada", "idle": "reposo", "alert": "alerta", "walk_fwd": "caminar", "run_fwd": "correr",
                   "strafe_l": "lateral_izq", "strafe_r": "lateral_der", "turn_l": "girar_izq", "turn_r": "girar_der",
                   "hit_front": "recibir_golpe", "hit_back": "recibir_golpe_espalda", "stagger": "aturdido",
                   "death": "derrota", "despawn": "desaparecer"}

# Plantilla de 1,65 m (el Peón). Para otra altura se escala; «ancho» ensancha hombros y caderas.
_PLANTILLA = [
    ("cadera", (0, 0, 0.90), (0, 0, 0.99), "raiz"),
    ("columna_01", (0, 0, 0.99), (0, 0, 1.10), "cadera"),
    ("columna_02", (0, 0, 1.10), (0, 0, 1.22), "columna_01"),
    ("pecho", (0, 0, 1.22), (0, 0, 1.37), "columna_02"),
    ("cuello", (0, -0.005, 1.37), (0, -0.015, 1.45), "pecho"),
    ("cabeza", (0, -0.015, 1.45), (0, -0.015, 1.65), "cuello"),
]
_PLANTILLA_LADO = [
    ("clavicula", (0.03, 0.0, 1.345), (0.15, 0.01, 1.355), "pecho"),
    ("brazo", (0.16, 0.01, 1.345), (0.31, 0.035, 1.12), "clavicula"),
    ("antebrazo", (0.31, 0.035, 1.12), (0.40, -0.01, 0.905), "brazo"),
    ("mano", (0.40, -0.01, 0.905), (0.44, -0.035, 0.79), "antebrazo"),
    ("muslo", (0.11, 0.0, 0.90), (0.13, -0.02, 0.50), "cadera"),
    ("pierna", (0.13, -0.02, 0.50), (0.14, 0.01, 0.10), "muslo"),
    ("pie", (0.14, 0.01, 0.10), (0.14, -0.11, 0.035), "pierna"),
    ("dedos", (0.14, -0.11, 0.035), (0.14, -0.20, 0.03), "pie"),
]


CADERA_Z = 0.90                     # altura de la cadera en la plantilla
HOMBRO = (0.16, 0.01, 1.345)        # cabeza del brazo en la plantilla (los brazos se acortan alrededor de él)


def proporcion(p, piernas=1.0, cabeza=1.0, brazos=1.0, hueso="", extremo=0):
    """Un punto de la plantilla con proporciones más compactas (v2 del bestiario, 13/11): piernas cortas (lo que está
    bajo la cadera se escala en z y el tronco baja), cabeza más grande (la cola de la cabeza se alarga) y brazos más
    cortos (alrededor del hombro). Con 1, 1, 1, el punto de siempre (la v1)."""
    x, y, z = p
    baja = CADERA_Z * (1 - piernas)
    if piernas != 1.0:
        if p[2] <= CADERA_Z:
            z, y = z * piernas, y * piernas
        else:
            z = z - baja
    if brazos != 1.0 and hueso.split(".")[0] in ("brazo", "antebrazo", "mano"):
        hz = HOMBRO[2] - baja
        sx = HOMBRO[0] if p[0] >= 0 else -HOMBRO[0]
        x, y, z = sx + (x - sx) * brazos, HOMBRO[1] + (y - HOMBRO[1]) * brazos, hz + (z - hz) * brazos
    if cabeza != 1.0 and hueso == "cabeza" and extremo == 1:
        z0 = 1.45 - baja
        z = z0 + (z - z0) * cabeza
    return (x, y, z)


def huesos(alto=1.65, ancho=1.0, hombros=1.0, piernas=1.0, cabeza=1.0, brazos=1.0):
    """Lista [(nombre, cabeza, cola, padre)] del rig base a «alto» metros. ancho: caderas y piernas; hombros: brazos;
    piernas, cabeza y brazos: las proporciones compactas de la v2 (proporcion()). Por defecto, la plantilla de la v1."""
    k = alto / 1.65

    def P(p, f=1.0, hueso="", extremo=0):
        p = proporcion(p, piernas, cabeza, brazos, hueso, extremo)
        return (p[0] * k * f, p[1] * k, p[2] * k)
    out = [("raiz", (0, 0, 0), (0, 0, 0.2 * k), None)]
    for n, a, b, p in _PLANTILLA:
        out.append((n, P(a, 1.0, n, 0), P(b, 1.0, n, 1), p))
    for s, l in ((".L", 1), (".R", -1)):
        for n, a, b, p in _PLANTILLA_LADO:
            f = ancho if n in ("muslo", "pierna", "pie", "dedos") else hombros
            a2, b2 = P(a, f, n, 0), P(b, f, n, 1)
            a2 = (a2[0] * l, a2[1], a2[2])
            b2 = (b2[0] * l, b2[1], b2[2])
            out.append((n + s, a2, b2, (p + s) if p not in ("raiz", "cadera", "pecho") else p))
    return out


def crear(nombre, col, alto=1.65, ancho=1.0, hombros=1.0, sockets=None, piernas=1.0, cabeza=1.0, brazos=1.0):
    """Crea la armadura. sockets: {nombre: (cabeza, cola, padre, deforma)} (arma.R, arma.L, pecho_fx, luz…)."""
    hs = huesos(alto, ancho, hombros, piernas, cabeza, brazos)
    for n, (a, b, p, _) in (sockets or {}).items():
        hs.append((n, tuple(a), tuple(b), p))
    arm = C.crear_armadura(nombre, hs, col)
    for n, (_, _, _, deforma) in (sockets or {}).items():
        arm.data.bones[n].use_deform = deforma
    arm.data.bones["raiz"].use_deform = False
    return arm, hs


def punto(arm, hueso, t=0.0):
    """Punto de reposo a lo largo de un hueso (0 cabeza, 1 cola), en espacio de armadura."""
    b = arm.data.bones[hueso]
    return b.head_local.lerp(b.tail_local, t)


def contar_deformantes(arm):
    return sum(1 for b in arm.data.bones if b.use_deform)


# ================================================================== pesos

def eje(arm, cadena):
    """Pesos a lo largo de una cadena de huesos [(hueso, t_en_el_hueso)...] proyectando en el segmento de la primera
    cabeza a la última cola (codo y rodilla mezclados suave)."""
    a = punto(arm, cadena[0][0], 0.0)
    b = punto(arm, cadena[-1][0], 1.0)
    lon = (b - a).length
    pts = []
    for h, t in cadena:
        p = punto(arm, h, t)
        pts.append(((p - a).dot((b - a).normalized()) / lon, h))
    return C.por_eje(a, b, pts)


def mezcla(f1, f2, t_de):
    """Pesos que mezclan dos funciones según t_de(co) (0: f1, 1: f2)."""
    def f(co):
        t = min(max(t_de(co), 0.0), 1.0)
        w = {}
        for h, x in f1(co).items():
            w[h] = w.get(h, 0.0) + x * (1 - t)
        for h, x in f2(co).items():
            w[h] = w.get(h, 0.0) + x * t
        return w
    return f


def fijo(hueso):
    return lambda co: {hueso: 1.0}


# ================================================================== locomoción y reacciones comunes (in-place)

def pasos(rig, dur, paso, alto_pie, bote, tobillo, ancho=None, inclina=0.0, brazos=14.0, base=None, lateral=0.0,
          extra=None):
    """Ciclo de pasos en el sitio (la raíz no avanza: el controlador mueve al actor). Pies por IK apoyados la mitad del
    ciclo (sin patinar respecto a su recorrido), bote de cadera, giro de pecho contrario y braceo. lateral: ±1 para
    paso lateral (strafe), el pie se desplaza en X en vez de en Y. extra(seg, fase) -> claves propias del enemigo."""
    ancho = tobillo[0] if ancho is None else ancho
    base = base or {}

    def f(seg):
        out = {}
        for s, desfase, l in ((".L", 0.0, 1), (".R", 0.5, -1)):
            fa = (seg / dur + desfase) % 1.0
            if fa < 0.5:
                d, z, rx = paso / 2 - paso * (fa / 0.5), tobillo[2], 0.0
            else:
                t = (fa - 0.5) / 0.5
                d = -paso / 2 + paso * (0.5 - 0.5 * math.cos(math.pi * t))
                z = tobillo[2] + alto_pie * math.sin(math.pi * t)
                rx = -16 * math.sin(math.pi * t) * (0 if lateral else 1)
            if lateral:
                out["pie" + s + "@ik"] = (ancho * l + d * lateral, tobillo[1], z)
            else:
                out["pie" + s + "@ik"] = (ancho * l, tobillo[1] - d, z)
            out["pie" + s + "@rot"] = (rx, 0, 0)
        fase = 2 * math.pi * seg / dur
        out["raiz@loc"] = (0.02 * math.sin(fase) * (0 if lateral else 1), 0, -bote * (0.5 + 0.5 * math.cos(2 * fase)))
        out["pecho"] = tuple(a + b for a, b in zip(base.get("pecho", (0, 0, 0)), (inclina, 0, -6 * math.sin(fase))))
        out["cadera"] = (0, 0, 5 * math.sin(fase))
        out["cabeza"] = tuple(a + b for a, b in zip(base.get("cabeza", (0, 0, 0)), (-inclina * 0.6, 0, 3 * math.sin(fase))))
        bL = base.get("brazo.L", (0, 0, 0))
        bR = base.get("brazo.R", (0, 0, 0))
        out["brazo.L"] = (bL[0] + brazos * math.sin(fase), bL[1], bL[2])
        out["brazo.R"] = (bR[0] - brazos * math.sin(fase), bR[1], bR[2])
        if extra:
            out.update(extra(seg, fase))
        return out
    return f


def girar(rig, sentido, tobillo, base, dur=0.5):
    """Giro en el sitio (0,5 s): el pecho y la cabeza se adelantan hacia el lado y los pies dan dos pasitos. La raíz no
    gira: el combate (o el mapa) gira al actor mientras suena el clip; al final vuelve a la pose de partida."""
    l = 1 if sentido == "izq" else -1

    def f(seg):
        t = seg / dur
        out = {}
        for s, lado, t0 in ((".L", 1, 0.0), (".R", -1, 0.45)):
            u = min(max((t - t0) / 0.5, 0.0), 1.0)
            z = tobillo[2] + 0.07 * math.sin(math.pi * u)
            out["pie" + s + "@ik"] = (tobillo[0] * lado + 0.04 * l * math.sin(math.pi * u), tobillo[1], z)
        a = math.sin(math.pi * t)
        out["pecho"] = tuple(x + y for x, y in zip(base.get("pecho", (0, 0, 0)), (0, 0, 22 * l * a)))
        out["cabeza"] = tuple(x + y for x, y in zip(base.get("cabeza", (0, 0, 0)), (0, 0, 18 * l * a)))
        out["cadera"] = (0, 0, 8 * l * a)
        out["raiz@loc"] = (0, 0, -0.025 * a)
        return out
    return f


def aturdido_proc(base, dur=0.8, amp=1.0):
    """Tambaleo en bucle (stagger/aturdido): la cabeza y el pecho dan vueltas pequeñas, cambia el peso de pie."""
    def f(seg):
        a = 2 * math.pi * seg / dur
        out = {"cabeza": (10 + 8 * amp * math.sin(a), 6 * amp * math.cos(a), 12 * amp * math.cos(a)),
               "pecho": (base.get("pecho", (0, 0, 0))[0] + 4 * amp * math.sin(a), 6 * amp * math.cos(a), 0),
               "raiz@loc": (0.04 * amp * math.cos(a), 0.01, -0.05), "luz@esc": ((0.45 + 0.25 * math.sin(3 * a)),) * 3}
        return out
    return f


# ================================================================== lámina de revisión: frente, perfil, espalda y Kael

def lamina(esc, arm, ob, raiz, ruta, titulo, sep=1.25, alto_cam=0.9, orto=6.0, clip="reposo", fotograma=1,
           ocultar=()):
    """Silueta de perfil | frente | perfil | espalda | Kael (1,7 m), con rótulos. Devuelve la cámara."""
    C.preparar_render(esc, 2400, 1100)
    C.luces_desierto(esc)
    C.suelo(esc, color=(0.62, 0.70, 0.52))
    vistas = [("silueta (perfil)", -90, True), ("frente", 0, False), ("perfil", -90, False), ("espalda", 180, False)]
    n = len(vistas) + 1
    xs = [(i - (n - 1) / 2) * sep for i in range(n)]
    copias = []
    for i, (rot, giro, sil) in enumerate(vistas):
        if i == 1:
            a2, m2 = arm, ob
        else:
            a2 = arm.copy()
            esc.collection.objects.link(a2)
            a2.animation_data_clear()
            a2.animation_data_create()
            m2 = C.silueta_de(ob, esc) if sil else ob.copy()
            if not sil:
                esc.collection.objects.link(m2)
            m2.parent = a2
            m2.modifiers["esqueleto"].object = a2
        if clip in bpy.data.actions:
            C.accion(a2, clip)
        a2.location = (xs[i], 0, 0)
        a2.rotation_euler = (0, 0, math.radians(giro))
        copias.append(a2)
    C.importar_kael(raiz, 1.7, (xs[-1], 0, 0))
    for x, t in zip(xs, [v[0] for v in vistas] + ["Kael (1,7 m)"]):
        C.texto(esc, t, (x, 0.0, 2.05), 0.11)
    C.texto(esc, titulo, (0, 0.5, 2.35), 0.13)
    esc.frame_set(fotograma)
    cam = C.camara(esc, (0, 0, alto_cam), 16, 0, 6, orto=orto)
    esc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    for o in esc.objects:
        if o.name.startswith("txt"):
            o.hide_render = True
    for c in copias[:1] + copias[2:]:
        c.hide_render = True
        for h in c.children:
            h.hide_render = True
    return cam, xs


def rellenar_pesos(m):
    """Red de seguridad: un vértice sin ningún peso (se queda quieto en el reposo y se estira como una púa al moverse)
    toma los pesos del vértice con pesos más cercano. Devuelve cuántos había."""
    from mathutils.kdtree import KDTree
    con = [v for v in m.bm.verts if len(v[m.dv]) > 0]
    sin = [v for v in m.bm.verts if len(v[m.dv]) == 0]
    if not sin:
        return 0
    kd = KDTree(len(con))
    for i, v in enumerate(con):
        kd.insert(v.co, i)
    kd.balance()
    for v in sin:
        _, i, _ = kd.find(v.co)
        d = v[m.dv]
        for g, w in con[i][m.dv].items():
            d[g] = w
    return len(sin)



# ================================================================== formas redondeadas (v2, 13/11)

def torno(m, base, perfil, lados=16, tapas=(True, True), pliegues=None, frente_plano=0.0, giro_z=0.0):
    """Sólido de revolución alrededor de la vertical que pasa por «base»: perfil [(dz, rx, ry)] de abajo arriba (rx a lo
    ancho, ry de delante atrás). pliegues: (n, amplitud, dz0, dz1): ondula el radio entre dz0 y dz1 (pliegues de tela o
    surcos), más fuerte abajo. frente_plano: aplana la cara de delante (-Y) esa fracción (máscaras)."""
    b = Vector(base)
    pts = [b + Vector((0, 0, dz)) for dz, _, _ in perfil]
    vs = m.tubo(pts, [(rx, ry) for _, rx, ry in perfil], lados, tapas, ref=Vector((1, 0, 0)), giro_seccion=giro_z)
    for v in vs:
        r = v.co - b
        if pliegues:
            n, amp, a, c = pliegues
            if a <= r.z <= c:
                w = 1.0 - (r.z - a) / max(c - a, 1e-6)
                f = 1.0 + amp * w * math.sin(n * math.atan2(r.y, r.x))
                v.co.x = b.x + r.x * f
                v.co.y = b.y + r.y * f
        if frente_plano and r.y < 0:
            v.co.y = b.y + r.y * (1.0 - frente_plano)
    return vs


def doblar(vs, eje, radio):
    """Curva una pieza alrededor de un eje vertical que pasa por «eje» (x, y): la acerca a un arco de ese radio (mitad
    del camino) para que abrace el cuerpo (placas de faldón o de corteza)."""
    cx, cy = eje
    for v in vs:
        if not v.is_valid:
            continue
        dx, dy = v.co.x - cx, v.co.y - cy
        r = math.hypot(dx, dy)
        if r < 1e-6:
            continue
        ang = math.atan2(dy, dx)
        v.co.x = cx + math.cos(ang) * (radio + (r - radio) * 0.5)
        v.co.y = cy + math.sin(ang) * (radio + (r - radio) * 0.5)
    return vs


def borrar(m, vs, quitar):
    """Quita los vértices de «vs» que cumplen quitar(co) (abrir una capucha por delante). Devuelve los que quedan."""
    fuera = [v for v in vs if v.is_valid and quitar(v.co)]
    if fuera:
        bmesh.ops.delete(m.bm, geom=fuera, context='VERTS')
    return [v for v in vs if v.is_valid]


def normal_desde_alturas(img, fuerza=2.0, celda=None):
    """Mapa de normales (espacio tangente) a partir de la luminancia del atlas pintado: lo oscuro (grietas, surcos,
    hebras) queda hundido. Por celdas, para no mezclar bordes. Devuelve un array h×w×3 (0..1)."""
    import numpy as np
    h, w, _ = img.shape
    alt = img[..., 0] * 0.3 + img[..., 1] * 0.59 + img[..., 2] * 0.11
    n = np.zeros((h, w, 3), dtype=np.float32)
    c = celda or h
    for y0 in range(0, h, c):
        for x0 in range(0, w, c):
            a = alt[y0:y0 + c, x0:x0 + c]
            a = (a + np.roll(a, 1, 0) + np.roll(a, -1, 0) + np.roll(a, 1, 1) + np.roll(a, -1, 1)) / 5.0
            gx = (np.roll(a, -1, 1) - np.roll(a, 1, 1)) * 0.5 * fuerza
            gy = (np.roll(a, -1, 0) - np.roll(a, 1, 0)) * 0.5 * fuerza
            gx[:, 0] = 0
            gx[:, -1] = 0
            gy[0, :] = 0
            gy[-1, :] = 0
            nz = 1.0 / np.sqrt(gx * gx + gy * gy + 1.0)
            n[y0:y0 + c, x0:x0 + c, 0] = -gx * nz
            n[y0:y0 + c, x0:x0 + c, 1] = -gy * nz
            n[y0:y0 + c, x0:x0 + c, 2] = nz
    return n * 0.5 + 0.5


def guardar_imagen(arr, ruta, tam=None, lineal=True):
    """Guarda un array h×w×3 (0..1, fila 0 abajo) como WebP o PNG según la extensión, reducido a «tam» si se pide."""
    import numpy as np
    h, w, _ = arr.shape
    if tam and tam != h:
        k = h // tam
        arr = arr.reshape(tam, k, tam, k, 3).mean(axis=(1, 3))
        h = w = tam
    rgba = np.concatenate([arr, np.ones((h, w, 1), np.float32)], axis=2)
    im = bpy.data.images.new("img_%d" % h, w, h, alpha=False)
    if lineal:
        im.colorspace_settings.name = 'Non-Color'
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = ruta
    im.file_format = 'WEBP' if ruta.endswith(".webp") else 'PNG'
    try:
        im.save(quality=95)
    except TypeError:
        im.save()
    bpy.data.images.remove(im)



# ================================================================== lámina con los tres héroes (v2, 13/11)
# Alturas «como en el combate»: los héroes miden 1,7 m (maga_3d.gd ALTURA) y se dibujan a esc 0,67 (Kael y Garon) y 0,6
# (Lya) y los enemigos a 0,6 (combate.gd MODELOS): en unidades del enemigo, Kael y Garon 1,90 m y Lya 1,70 m.
HEROES = [("Kael", "kael.fbx", 1.90, "01a19b86"), ("Lya", "Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx",
                                                    1.70, "01a19663"), ("Garon", "garon.fbx", 1.90, "Thoughtful_Walk")]


def importar_heroe(raiz, archivo, alto, pos, accion="", fotograma=1):
    """Un héroe (FBX del juego) como muñeco a escala, en una pose de su clip (como desierto_comun.importar_kael)."""
    antes = set(bpy.data.objects)
    acts = set(bpy.data.actions)
    bpy.ops.import_scene.fbx(filepath=os.path.join(raiz, archivo))
    nuevos = [o for o in bpy.data.objects if o not in antes]
    arm = next((o for o in nuevos if o.type == 'ARMATURE'), None)
    if arm and arm.animation_data:
        a = next((x for x in bpy.data.actions if x not in acts and accion and accion in x.name), None)
        arm.animation_data.action = a
    bpy.context.scene.frame_set(fotograma)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in nuevos:
        if o.type != 'MESH':
            continue
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        pts += [o.matrix_world @ v.co for v in me.vertices]
        ev.to_mesh_clear()
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    s = alto / (hi.z - lo.z)
    vac = bpy.data.objects.new("heroe_" + archivo, None)
    bpy.context.scene.collection.objects.link(vac)
    for o in nuevos:
        if o.parent is None:
            o.parent = vac
            o.matrix_parent_inverse = Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z)))
    vac.scale = (s, s, s)
    vac.location = pos
    return vac


def lamina_heroes(esc, arm, ob, raiz, ruta, titulo, sep=1.15, alto_cam=1.12, orto=8.6, clip="reposo", fotograma=1,
                  heroes=None):
    """Lámina de revisión: silueta de perfil | frente | perfil | espalda | Kael | Lya | Garon (alturas de combate)."""
    heroes = HEROES if heroes is None else heroes
    C.preparar_render(esc, 2600, 1100)
    C.luces_desierto(esc)
    C.suelo(esc, color=(0.62, 0.70, 0.52))
    vistas = [("silueta (perfil)", -90, True), ("frente", 0, False), ("perfil", -90, False), ("espalda", 180, False)]
    n = len(vistas) + len(heroes)
    xs = [(i - (n - 1) / 2) * sep for i in range(n)]
    for i, (rot, giro, sil) in enumerate(vistas):
        if i == 1:
            a2 = arm
        else:
            a2 = arm.copy()
            esc.collection.objects.link(a2)
            a2.animation_data_clear()
            a2.animation_data_create()
            m2 = C.silueta_de(ob, esc) if sil else ob.copy()
            if not sil:
                esc.collection.objects.link(m2)
            m2.parent = a2
            m2.modifiers["esqueleto"].object = a2
        if clip in bpy.data.actions:
            C.accion(a2, clip)
        a2.location = (xs[i], 0, 0)
        a2.rotation_euler = (0, 0, math.radians(giro))
    for k, (nombre, archivo, alto, accion) in enumerate(heroes):
        importar_heroe(raiz, archivo, alto, (xs[len(vistas) + k], 0, 0), accion)
    rotulos = [v[0] for v in vistas] + ["%s (como en el combate)" % h[0] for h in heroes]
    for x, t_ in zip(xs, rotulos):
        C.texto(esc, t_, (x, 0.0, 2.15), 0.085)
    C.texto(esc, titulo, (0, 0.5, 2.42), 0.12)
    esc.frame_set(fotograma)
    C.camara(esc, (0, 0, alto_cam), 16, 0, 6, orto=orto)
    esc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
