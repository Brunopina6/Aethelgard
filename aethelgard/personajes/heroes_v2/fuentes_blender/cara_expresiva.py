# Héroes v2 (fase B, V12): cara expresiva para modelos SIN formas de cara (Meshy pinta ojos y boca en la textura).
#
# Cómo funciona:
#   1. Se buscan por rayos, desde delante, las caras de la malla que se ven en la zona de ojos y boca (un rectángulo por
#      héroe, CONFIG). Se duplican en un objeto aparte, «cara_v2», ligeramente adelantado (0,6 mm) y con los mismos
#      pesos de hueso, así que sigue a la cabeza en todos los clips.
#   2. Se proyecta desde delante el color original de esas caras (solo albedo, sin luz) en una loseta: la cara «normal»
#      es idéntica a la del modelo.
#   3. Las demás losetas se pintan sobre esa (numpy, sin programas externos): ojos cerrados, entrecerrados, sonrisa,
#      dolor, grito y sorpresa. Atlas de 4 × 2 losetas (WebP en el GLB).
#   4. En el juego, heroe_v2_3d.gd mueve el desplazamiento UV del material de «cara_v2» para cambiar de expresión
#      (y parpadear). Con la expresión «normal» se oculta: el modelo queda exactamente como el original.
# Garon no lleva cara: su yelmo es cerrado (su expresión es el cuerpo).
import os, sys, math
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "dialogos", "retratos",
                                "fuentes_blender"))
import imgutil as U

TIENE_CARA = {"Kael": True, "Lya": True, "Garon": False}
EXPRESIONES = ["normal", "cerrados", "sonrisa", "dolor", "grito", "sorpresa", "entrecerrados", "normal2"]
COLS, FILAS = 4, 2
ALTO_LOSETA = 320

# Medidas en píxeles de un render de referencia (1024 px, ortográfico de frente, solo albedo: cara_frente.py), con su
# centro y su escala, para no depender de la resolución. Ojos: (x0, y0, x1, y1); boca: (cx, cy, ancho); cejas: idem.
CONFIG = {
    "Kael": {"ref_centro": (0.00996, 1.43375), "ref_orto": 0.51757,
             "rect_px": (190, 640, 830, 1060),
             "ojos": [(222, 742, 382, 888), (596, 742, 770, 888)],
             "cejas": [(270, 685, 395, 735), (580, 682, 720, 735)],
             "boca": (507, 985, 70)},
    "Lya": {"ref_centro": (0.00332, 1.42), "ref_orto": 0.32,
            "rect_px": (150, 120, 870, 700),
            "ojos": [(168, 272, 392, 482), (622, 272, 848, 482)],
            "cejas": [(230, 140, 380, 175), (640, 140, 790, 175)],
            "boca": (505, 600, 150)},
}


def _px_a_mundo(cfg, px, py):
    cx, cz = cfg["ref_centro"]; s = cfg["ref_orto"] / 1024.0
    return cx + (px - 512) * s, cz + (512 - py) * s


class Cara:
    def __init__(self, obj, mat_map, tw, th):
        self.obj = obj; self.map = mat_map; self.tw = tw; self.th = th

    def poner(self, nombre):
        i = EXPRESIONES.index(nombre)
        c, f = i % COLS, i // COLS
        self.map.inputs['Location'].default_value = (c / COLS, -f / FILAS, 0)
        self.obj.hide_render = (nombre == "normal")

    def expresion_para(self, clip, frac):
        # solo para los renders de comprobación (en el juego lo decide heroe_v2_3d.gd)
        tabla = {"recibir_golpe": "dolor", "derribo": "dolor", "derrota": "cerrados", "victoria": "sonrisa",
                 "ataque": "grito", "magia_lanzar": "grito", "magia_poderosa": "grito", "magia_concentrar": "entrecerrados",
                 "hablar": "sonrisa", "saltar": "sorpresa"}
        self.poner(tabla.get(clip, "normal") if 0.15 < frac < 0.95 or clip in ("derrota",) else "normal")


def crear(heroe, arm, malla, rig, carpeta, evid):
    cfg = CONFIG[heroe]
    x0, z1 = _px_a_mundo(cfg, cfg["rect_px"][0], cfg["rect_px"][1])
    x1, z0 = _px_a_mundo(cfg, cfg["rect_px"][2], cfg["rect_px"][3])
    rig.reset()
    deps = bpy.context.evaluated_depsgraph_get()
    ev = malla.evaluated_get(deps)
    mwi = ev.matrix_world.inverted()
    caras = set()
    n = 220
    for i in range(n):
        for j in range(int(n * (z1 - z0) / (x1 - x0)) + 1):
            x = x0 + (x1 - x0) * (i + 0.5) / n
            z = z0 + (x1 - x0) * (j + 0.5) / n
            if z > z1:
                continue
            o = mwi @ Vector((x, -2.0, z))
            d = (mwi.to_3x3() @ Vector((0, 1, 0))).normalized()
            # la PIEL, no el flequillo: se sigue el rayo y se toma la cara de delante tras la que viene un tramo largo
            # dentro de la cabeza (un mechón es una lámina fina: tras entrar, sale enseguida)
            golpes = []
            p = o.copy()
            for _ in range(10):
                ok, loc, nor, idx = ev.ray_cast(p, d)
                if not ok:
                    break
                golpes.append((loc.copy(), nor.dot(d) < 0, idx))
                p = loc + d * 1e-4
            for k, (loc, delante, idx) in enumerate(golpes):
                if not delante:
                    continue
                sig = golpes[k + 1][0] if k + 1 < len(golpes) else None
                if sig is None or (sig - loc).length > 0.025 / malla.matrix_world.to_scale().x:
                    caras.add(idx)
                    break
    me = malla.data
    sel = [f for f in caras if (malla.matrix_world.to_3x3() @ me.polygons[f].normal).normalized().y < -0.2]
    print("CARA", heroe, "caras de la zona:", len(sel))
    # duplicar esas caras en un objeto aparte (con sus pesos)
    bpy.ops.object.select_all(action='DESELECT')
    bpy.context.view_layer.objects.active = malla
    malla.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_mode(type='FACE')
    bpy.ops.mesh.select_all(action='DESELECT')
    bpy.ops.object.mode_set(mode='OBJECT')
    for f in sel:
        me.polygons[f].select = True
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.duplicate()
    bpy.ops.mesh.separate(type='SELECTED')
    bpy.ops.object.mode_set(mode='OBJECT')
    cara = [o for o in bpy.context.selected_objects if o != malla][0]
    cara.name = "cara_v2"
    cara.data.name = "cara_v2"
    # adelantarla un poco hacia delante (una dirección fija: con la normal de cada vértice se abrían las costuras de UV)
    bm = bmesh.new(); bm.from_mesh(cara.data)
    adel = (malla.matrix_world.to_3x3().inverted() @ Vector((0, -1, 0))).normalized()
    for v in bm.verts:
        v.co += adel * 0.0008 * rig.altura / malla.matrix_world.to_scale().x
    bm.to_mesh(cara.data); bm.free()
    # 2. proyección del albedo original (solo esta malla, de frente)
    tw = int(round(ALTO_LOSETA * (x1 - x0) / (z1 - z0)))
    th = ALTO_LOSETA
    loseta = _proyectar(cara, malla, x0, x1, z0, z1, tw, th, evid)
    # 3. losetas con expresiones
    atlas = np.zeros((th * FILAS, tw * COLS, 4), dtype=np.float32)
    feats = _rasgos(cfg, x0, x1, z0, z1, tw, th)
    for k, nombre in enumerate(EXPRESIONES):
        t = _expresion(loseta.copy(), nombre, feats)
        c, f = k % COLS, k // COLS
        atlas[f * th:(f + 1) * th, c * tw:(c + 1) * tw] = t
    ruta_atlas = os.path.join(evid, "%s_cara_atlas.png" % heroe.lower())   # va dentro del GLB (WebP)
    U.guardar(atlas, ruta_atlas)
    # UV plana de frente, en la loseta 0 del atlas
    me2 = cara.data
    uv = me2.uv_layers.active.data
    mw = cara.matrix_world
    for poly in me2.polygons:
        for li in poly.loop_indices:
            p = mw @ me2.vertices[me2.loops[li].vertex_index].co
            u = (p.x - x0) / (x1 - x0)
            v = (p.z - z0) / (z1 - z0)
            uv[li].uv = (u / COLS, 1.0 - 1.0 / FILAS + v / FILAS)
    # material del atlas (en el GLB: color base; el juego lo cambia por el suyo)
    mat = bpy.data.materials.new("cara_v2")
    mat.use_nodes = True
    nt = mat.node_tree
    bs = nt.nodes["Principled BSDF"]
    bs.inputs["Roughness"].default_value = 0.75
    ti = nt.nodes.new("ShaderNodeTexImage")
    ti.image = bpy.data.images.load(ruta_atlas)
    ti.interpolation = 'Linear'
    mp = nt.nodes.new("ShaderNodeMapping")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    nt.links.new(tc.outputs["UV"], mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"], ti.inputs["Vector"])
    nt.links.new(ti.outputs["Color"], bs.inputs["Base Color"])
    nt.links.new(ti.outputs["Alpha"], bs.inputs["Alpha"])
    cara.data.materials.clear()
    cara.data.materials.append(mat)
    c = Cara(cara, mp, tw, th)
    c.poner("normal")
    return c


def _proyectar(cara, malla, x0, x1, z0, z1, tw, th, evid):
    sc = bpy.context.scene
    viejo = (sc.render.resolution_x, sc.render.resolution_y, sc.camera, sc.world, sc.render.filter_size)
    malla.hide_render = True
    # material de emisión con el color base (solo para este render)
    mats = list(cara.data.materials)
    emis = []
    for m in mats:
        m2 = m.copy(); nt = m2.node_tree
        bs = [nd for nd in nt.nodes if nd.type == 'BSDF_PRINCIPLED'][0]
        src = bs.inputs['Base Color'].links[0].from_socket
        em = nt.nodes.new('ShaderNodeEmission'); nt.links.new(src, em.inputs['Color'])
        out = [nd for nd in nt.nodes if nd.type == 'OUTPUT_MATERIAL'][0]
        nt.links.new(em.outputs['Emission'], out.inputs['Surface'])
        emis.append(m2)
    cara.data.materials.clear()
    for m in emis:
        cara.data.materials.append(m)
    w = bpy.data.worlds.new("negro_cara"); w.use_nodes = True
    w.node_tree.nodes['Background'].inputs['Strength'].default_value = 0
    sc.world = w
    cd = bpy.data.cameras.new("cam_cara"); cd.type = 'ORTHO'; cd.ortho_scale = max(x1 - x0, z1 - z0)
    cam = bpy.data.objects.new("cam_cara", cd); sc.collection.objects.link(cam)
    cam.location = ((x0 + x1) / 2, -3.0, (z0 + z1) / 2)
    cam.rotation_euler = (math.radians(90), 0, 0)
    sc.camera = cam
    sc.render.resolution_x = tw * 2; sc.render.resolution_y = th * 2
    sc.render.filter_size = 0.6
    ruta = os.path.join(evid, "tmp_cara_proyeccion.png")
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    im = U.cargar(ruta)
    os.remove(ruta)
    im = U.reescalar(im, tw, th)
    # rellenar los huecos transparentes del borde con el vecino (sin bordes negros al filtrar)
    for _ in range(4):
        a = im[:, :, 3:4]
        pad = np.pad(im, ((1, 1), (1, 1), (0, 0)), mode='edge')
        vec = (pad[:-2, 1:-1] + pad[2:, 1:-1] + pad[1:-1, :-2] + pad[1:-1, 2:]) / 4
        im[:, :, :3] = np.where(a > 0.5, im[:, :, :3], vec[:, :, :3])
    im[:, :, 3] = 1.0
    # restaurar
    cara.data.materials.clear()
    for m in mats:
        cara.data.materials.append(m)
    malla.hide_render = False
    sc.render.resolution_x, sc.render.resolution_y, sc.camera, sc.world, sc.render.filter_size = viejo
    bpy.data.objects.remove(cam, do_unlink=True)
    return im


def _rasgos(cfg, x0, x1, z0, z1, tw, th):
    def a_loseta(px, py):
        x, z = _px_a_mundo(cfg, px, py)
        return (x - x0) / (x1 - x0) * tw, (z1 - z) / (z1 - z0) * th
    ojos = []
    for (a, b, c, d) in cfg["ojos"]:
        p0 = a_loseta(a, b); p1 = a_loseta(c, d)
        ojos.append((p0[0], p0[1], p1[0], p1[1]))
    cejas = []
    for (a, b, c, d) in cfg["cejas"]:
        p0 = a_loseta(a, b); p1 = a_loseta(c, d)
        cejas.append((p0[0], p0[1], p1[0], p1[1]))
    bx, by, bw = cfg["boca"]
    c = a_loseta(bx, by)
    w = a_loseta(bx + bw / 2, by)[0] - c[0]
    return {"ojos": ojos, "cejas": cejas, "boca": (c[0], c[1], w)}


# ------------------------------------------------------------------ pintar
def _elipse(h, w, cx, cy, rx, ry, suave=1.5):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.sqrt(((xx - cx) / max(rx, 1e-3)) ** 2 + ((yy - cy) / max(ry, 1e-3)) ** 2)
    return np.clip((1.0 - d) * min(rx, ry) / suave + 0.5, 0, 1)


def _trazo(h, w, pts, grosor):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.full((h, w), 1e9, dtype=np.float32)
    for (ax, ay), (bx, by) in zip(pts[:-1], pts[1:]):
        vx, vy = bx - ax, by - ay
        L2 = vx * vx + vy * vy + 1e-9
        t = np.clip(((xx - ax) * vx + (yy - ay) * vy) / L2, 0, 1)
        dx = xx - (ax + t * vx); dy = yy - (ay + t * vy)
        d = np.minimum(d, np.sqrt(dx * dx + dy * dy))
    return np.clip(grosor / 2 - d + 0.5, 0, 1)


def _arco(cx, cy, ancho, flecha, n=16):
    # arco de ancho «ancho» con la flecha «flecha» (> 0: hacia abajo, como ∪; < 0: hacia arriba, como ∩)
    pts = []
    for i in range(n + 1):
        t = i / n * 2 - 1
        pts.append((cx + t * ancho / 2, cy + flecha * (1 - t * t)))
    return pts


def _mezclar(img, mascara, color):
    m = mascara[:, :, None]
    img[:, :, :3] = img[:, :, :3] * (1 - m) + np.array(color, dtype=np.float32)[None, None, :] * m
    return img


def _color_piel(img, caja):
    x0, y0, x1, y1 = [int(v) for v in caja]
    h = y1 - y0
    zona = img[min(img.shape[0] - 1, y1 + h // 6):min(img.shape[0], y1 + h // 2), max(0, x0):x1, :3].reshape(-1, 3)
    if len(zona) == 0:
        return (0.98, 0.88, 0.8)
    luz = zona.sum(1)
    zona = zona[luz > np.percentile(luz, 40)]
    return tuple(np.median(zona, 0))


def _color_raya(img, caja):
    x0, y0, x1, y1 = [int(v) for v in caja]
    zona = img[y0:y1, x0:x1, :3].reshape(-1, 3)
    luz = zona.sum(1)
    return tuple(np.median(zona[luz <= np.percentile(luz, 4)], 0) * 0.9)


def _tapar_ojo(img, caja, piel, alto=1.0):
    x0, y0, x1, y1 = caja
    h, w = img.shape[:2]
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    rx, ry = (x1 - x0) / 2 * 1.04, (y1 - y0) / 2 * 1.04
    m = _elipse(h, w, cx, cy, rx, ry, 3.0)
    if alto < 1.0:   # solo la parte de arriba (párpado a media altura)
        yy = np.mgrid[0:h, 0:w][0].astype(np.float32)
        m *= np.clip((cy - ry + 2 * ry * alto) - yy + 1.5, 0, 1)
    # piel con un poco de sombra del párpado
    _mezclar(img, m, piel)
    sombra = _elipse(h, w, cx, cy - ry * 0.2, rx * 0.85, ry * 0.5, 4.0) * 0.12
    _mezclar(img, sombra * m, (piel[0] * 0.85, piel[1] * 0.78, piel[2] * 0.78))
    return img


def _tapar_boca(img, boca, piel):
    cx, cy, w = boca
    h, ww = img.shape[:2]
    m = _elipse(h, ww, cx, cy, w * 1.15, w * 0.55, 3.0)
    return _mezclar(img, m, piel)


def _expresion(img, nombre, f):
    if nombre in ("normal", "normal2"):
        return img
    h, w = img.shape[:2]
    escala = h / 320.0
    ojos = f["ojos"]
    pieles = [_color_piel(img, o) for o in ojos]
    raya = _color_raya(img, ojos[0])
    piel_boca = _color_piel(img, (f["boca"][0] - f["boca"][2], f["boca"][1] - 10, f["boca"][0] + f["boca"][2],
                                  f["boca"][1]))
    boca_osc = (0.42, 0.14, 0.14)
    lengua = (0.86, 0.45, 0.45)
    g = 6.5 * escala                      # trazos gruesos: en el juego la cara mide 40-80 px
    if nombre in ("cerrados", "sonrisa", "dolor", "entrecerrados"):
        for i, (o, piel) in enumerate(zip(ojos, pieles)):
            x0, y0, x1, y1 = o
            cx = (x0 + x1) / 2; ow = (x1 - x0)
            if nombre == "entrecerrados":
                _tapar_ojo(img, o, piel, alto=0.45)
                yb = y0 + (y1 - y0) * 0.45
                _mezclar(img, _trazo(h, w, _arco(cx, yb, ow * 0.95, -(y1 - y0) * 0.06), g * 1.1), raya)
                continue
            _tapar_ojo(img, o, piel)
            yb = y0 + (y1 - y0) * 0.62
            if nombre == "cerrados":
                pts = _arco(cx, yb, ow * 0.85, (y1 - y0) * 0.12)
            elif nombre == "sonrisa":
                pts = _arco(cx, yb + (y1 - y0) * 0.05, ow * 0.8, -(y1 - y0) * 0.25)
            else:   # dolor: > <  (apretados)
                s = 1 if i == 0 else -1
                xa, xb = cx - ow * 0.38 * s, cx + ow * 0.38 * s
                pts = [(xa, yb - (y1 - y0) * 0.22), (xb, yb), (xa, yb + (y1 - y0) * 0.18)]
            _mezclar(img, _trazo(h, w, pts, g * 1.15), raya)
    cx, cy, bw = f["boca"]
    if nombre == "sonrisa":
        _tapar_boca(img, f["boca"], piel_boca)
        pts = _arco(cx, cy - bw * 0.15, bw * 1.7, bw * 0.4)
        _mezclar(img, _trazo(h, w, pts, g * 0.9), raya)
    elif nombre == "dolor":
        _tapar_boca(img, f["boca"], piel_boca)
        m = _elipse(h, w, cx, cy + bw * 0.05, bw * 0.55, bw * 0.22, 1.5)
        _mezclar(img, m, boca_osc)
        _mezclar(img, _elipse(h, w, cx, cy + bw * 0.05, bw * 0.4, bw * 0.08, 1.0), (0.97, 0.95, 0.93))   # dientes
    elif nombre == "grito":
        _tapar_boca(img, f["boca"], piel_boca)
        m = _elipse(h, w, cx, cy + bw * 0.15, bw * 0.55, bw * 0.45, 1.5)
        _mezclar(img, m, boca_osc)
        _mezclar(img, _elipse(h, w, cx, cy + bw * 0.42, bw * 0.32, bw * 0.15, 1.5) * m, lengua)
        for o, piel in zip(ojos, pieles):           # mirada decidida: el párpado de arriba baja un poco
            x0, y0, x1, y1 = o
            _tapar_ojo(img, o, piel, alto=0.22)
            _mezclar(img, _trazo(h, w, _arco((x0 + x1) / 2, y0 + (y1 - y0) * 0.24, (x1 - x0) * 0.98, -(y1 - y0) * 0.05),
                                 g * 1.2), raya)
    elif nombre == "sorpresa":
        _tapar_boca(img, f["boca"], piel_boca)
        m = _elipse(h, w, cx, cy + bw * 0.15, bw * 0.38, bw * 0.48, 1.5)
        _mezclar(img, m, boca_osc)
    return img
