# Héroes v3 (V12): biblioteca de geometría PROPIA para los protagonistas (Blender 5.2 por guion, sin mallas de Meshy).
#
# Todo se construye en la pose de reposo en T del esqueleto común de los v2 (rig_comun.py), alrededor de sus huesos:
#   - tubo(): «loft» de anillos (centro, dirección de frente, radios) con ángulos explícitos, para extremidades, torso,
#     botas, mangas y faldones abiertos (el abrigo es un tubo con un hueco delante). Cada cara recibe un material de la
#     paleta con una función (anillo, columna) -> material, así los ribetes son bandas de la propia malla.
#   - mechon(): un mechón de pelo (sección de lente que se afila hasta la punta) a lo largo de una curva de Bézier.
#   - cabeza(): una esfera UV deformada con proporciones chibi (cráneo grande, mejillas redondas, barbilla pequeña).
#   - Pieza: objeto con sus materiales, su regla de pesos (huesos permitidos y factor) y su grosor de tela.
#   - pesar(): pesos por distancia a los segmentos de los huesos permitidos (potencia p), suavizados en las uniones.
#   - colorear(): pasa los materiales de la paleta a color por vértice (esquinas), con degradados por posición, y
#     multiplica una oclusión ambiental calculada con rayos (BVH). El alfa del color guarda el TIPO de material para el
#     sombreador del juego (piel, tela, cuero, metal, cristal, pelo).
# Ejes (como rig_comun.py tras importar el FBX): el personaje mira a -Y, su derecha es -X y arriba es +Z.
import math, random
import bpy, bmesh
from mathutils import Vector, Matrix, Quaternion
from mathutils.bvhtree import BVHTree

P = "mixamorig:"
ADEL = Vector((0.0, -1.0, 0.0))
ARR = Vector((0.0, 0.0, 1.0))
DER = Vector((-1.0, 0.0, 0.0))     # derecha del personaje

# Tipos de material (se guardan en el alfa del color por vértice: tipo / 7)
TIPOS = {"tela": 0, "piel": 1, "cuero": 2, "metal": 3, "cristal": 4, "pelo": 5, "ojo": 6, "oscuro": 7}


# ------------------------------------------------------------------ esqueleto en reposo
class Huesos:
    """Posiciones de los huesos en la pose de reposo (mundo)."""
    def __init__(self, arm):
        self.arm = arm
        mw = arm.matrix_world
        self.h = {}
        self.t = {}
        for b in arm.data.bones:
            self.h[b.name] = mw @ b.head_local
            self.t[b.name] = mw @ b.tail_local

    def c(self, n):          # cabeza del hueso (sin prefijo mixamorig)
        return self.h[n if n in self.h else P + n].copy()

    def k(self, n):          # cola del hueso
        return self.t[n if n in self.t else P + n].copy()

    def seg(self, n):
        return self.c(n), self.k(n)


# ------------------------------------------------------------------ utilidades
def marco(t, frente):
    t = t.normalized()
    n = frente - t * frente.dot(t)
    if n.length < 1e-6:
        n = t.orthogonal()
    n.normalize()
    b = t.cross(n).normalized()
    return t, n, b


def bezier(p0, p1, p2, p3, s):
    u = 1 - s
    return p0 * (u * u * u) + p1 * (3 * u * u * s) + p2 * (3 * u * s * s) + p3 * (s * s * s)


def suave(a, b, x):
    if b == a:
        return 1.0 if x >= b else 0.0
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def mezcla(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


# ------------------------------------------------------------------ piezas
class Pieza:
    """Una parte del personaje (malla en bmesh) con sus materiales y su regla de pesos.
    huesos: lista de (nombre, factor). p: potencia de la distancia (más alta = uniones más cortas)."""
    def __init__(self, nombre, materiales, huesos, p=4.0, grosor=0.0, interior=None, sombra=True):
        self.nombre = nombre
        self.bm = bmesh.new()
        self.materiales = list(materiales)     # nombres de la paleta
        if interior is not None and interior not in self.materiales:
            self.materiales.append(interior)
        self.huesos = huesos
        self.p = p
        self.grosor = grosor                   # tela con grosor (solidificar): el interior lleva «interior»
        self.interior = interior
        self.sombra = sombra
        # coordenadas de detalle (en metros) por vértice: u alrededor, v a lo largo, c = perímetro (costura)
        self.lu = self.bm.verts.layers.float.new("u")
        self.lv = self.bm.verts.layers.float.new("v")
        self.lc = self.bm.verts.layers.float.new("c")

    def uv(self, vert, u, v, c=0.0):
        vert[self.lu] = u
        vert[self.lv] = v
        vert[self.lc] = c

    def m(self, nombre):
        if nombre not in self.materiales:
            self.materiales.append(nombre)
        return self.materiales.index(nombre)


def tubo(pz, anillos, angulos=None, segs=10, cerrado=True, tapa0=False, tapa1=False, mat=None, perfil=None,
         abombar=0.35):
    """anillos: lista de dict {c: centro, f: frente (Vector), rx, ry} o tuplas (c, f, rx, ry).
    angulos: lista de ángulos (radianes; 0 = frente, pi/2 = izquierda del personaje si el eje va hacia arriba).
    cerrado: el último ángulo se une con el primero. mat(i, j) -> índice de material de la cara (anillo i, columna j).
    perfil(i, a) -> multiplicador del radio. tapa0/tapa1: cierra los extremos con una cúpula."""
    bm = pz.bm
    if angulos is None:
        angulos = [2 * math.pi * j / segs for j in range(segs)]
    an = []
    for a in anillos:
        if isinstance(a, dict):
            an.append(a)
        else:
            an.append({"c": a[0], "f": a[1], "rx": a[2], "ry": a[3]})
    filas = []
    for i, a in enumerate(an):
        c = Vector(a["c"])
        if i == 0:
            t = Vector(an[1]["c"]) - c
        elif i == len(an) - 1:
            t = c - Vector(an[i - 1]["c"])
        else:
            t = Vector(an[i + 1]["c"]) - Vector(an[i - 1]["c"])
        t, n, b = marco(t, Vector(a["f"]))
        fila = []
        for ang in angulos:
            k = perfil(i, ang) if perfil else 1.0
            # fa / fe: el radio de delante y el de detrás por separado (pecho y espalda distintos)
            p = c + n * (math.cos(ang) * a["rx"] * k * (a.get("fa", 1.0) if math.cos(ang) > 0 else a.get("fe", 1.0))) \
                + b * (math.sin(ang) * a["ry"] * k)
            if "dz" in a:
                p = p + Vector(a["dz"]) * (1.0 - abs(math.sin(ang)))
            fila.append(bm.verts.new(p))
        filas.append(fila)
    nj = len(angulos)
    jmax = nj if cerrado else nj - 1
    _uv_filas(pz, filas, [Vector(a["c"]) for a in an], cerrado)
    caras = []
    for i in range(len(filas) - 1):
        for j in range(jmax):
            j2 = (j + 1) % nj
            f = bm.faces.new((filas[i][j], filas[i][j2], filas[i + 1][j2], filas[i + 1][j]))
            f.material_index = mat(i, j) if mat else 0
            caras.append(f)
    for tapa, fila, i, sg in ((tapa0, filas[0], 0, -1), (tapa1, filas[-1], len(filas) - 1, 1)):
        if not tapa:
            continue
        a = an[i]
        c = Vector(a["c"])
        if i == 0:
            t = (Vector(an[1]["c"]) - c).normalized()
        else:
            t = (c - Vector(an[i - 1]["c"])).normalized()
        r = (a["rx"] + a["ry"]) * 0.5
        centro = bm.verts.new(c + t * sg * r * abombar)
        pz.uv(centro, 0.0, fila[0][pz.lv] + sg * r * 0.5)
        for j in range(jmax):
            j2 = (j + 1) % nj
            vs = (fila[j], fila[j2], centro) if sg > 0 else (fila[j2], fila[j], centro)
            f = bm.faces.new(vs)
            f.material_index = mat(i if sg > 0 else 0, j) if mat else 0
            caras.append(f)
    return caras


def _uv_filas(pz, filas, centros, cerrado=True):
    """u: longitud de arco por el anillo; v: longitud por los centros; c: perímetro (si es cerrado, para la costura)."""
    v = 0.0
    for i, fila in enumerate(filas):
        if i > 0:
            v += (centros[i] - centros[i - 1]).length
        u = 0.0
        for j, vt in enumerate(fila):
            if j > 0:
                u += (vt.co - fila[j - 1].co).length
            pz.uv(vt, u, v)
        circ = u + ((fila[0].co - fila[-1].co).length if cerrado else 0.0)
        if cerrado:
            for vt in fila:
                vt[pz.lc] = circ


def cadena(puntos, frente, radios, n_por=2):
    """Anillos a lo largo de una polilínea (puntos) con radios [(rx, ry)] por punto, subdividida n_por veces."""
    an = []
    for i in range(len(puntos) - 1):
        for k in range(n_por):
            s = k / n_por
            c = puntos[i].lerp(puntos[i + 1], s)
            rx = radios[i][0] + (radios[i + 1][0] - radios[i][0]) * s
            ry = radios[i][1] + (radios[i + 1][1] - radios[i][1]) * s
            an.append((c, frente, rx, ry))
    an.append((puntos[-1], frente, radios[-1][0], radios[-1][1]))
    return an


def mechon(pz, raiz, ctrl1, ctrl2, punta, ancho, grueso, frente, segs=7, lados=6, mat=0, giro=0.0, abultar=0.25):
    """Mechón: sección de lente (ancho × grueso) que crece un poco y se afila hasta la punta, por una curva de Bézier.
    frente: hacia dónde mira la cara ancha del mechón (normal a la superficie del cráneo, hacia fuera)."""
    bm = pz.bm
    pts = [bezier(raiz, ctrl1, ctrl2, punta, s / segs) for s in range(segs + 1)]
    filas = []
    for i, c in enumerate(pts):
        s = i / segs
        if i == 0:
            t = pts[1] - pts[0]
        elif i == segs:
            t = pts[i] - pts[i - 1]
        else:
            t = pts[i + 1] - pts[i - 1]
        t, n, b = marco(t, frente)
        if giro:
            q = Quaternion(t, giro * s)
            n = q @ n
            b = q @ b
        k = (1.0 + abultar * math.sin(min(1.0, s * 2.2) * math.pi)) * (1.0 - s) ** 0.85
        if i == segs:
            filas.append([bm.verts.new(c)])
            continue
        fila = []
        for j in range(lados):
            a = 2 * math.pi * j / lados
            # lente: la cara de fuera abombada, la de dentro más plana
            gx = math.sin(a) * ancho * k
            gy = math.cos(a) * grueso * k * (1.0 if math.cos(a) > 0 else 0.6)
            fila.append(bm.verts.new(c + b * gx + n * gy))
        filas.append(fila)
    _uv_mechon(pz, filas, pts, lados)
    for i in range(segs - 1):
        for j in range(lados):
            j2 = (j + 1) % lados
            f = bm.faces.new((filas[i][j], filas[i][j2], filas[i + 1][j2], filas[i + 1][j]))
            f.material_index = mat
    pt = filas[-1][0]
    for j in range(lados):
        j2 = (j + 1) % lados
        f = bm.faces.new((filas[-2][j], filas[-2][j2], pt))
        f.material_index = mat
    # raíz cerrada (queda dentro del cráneo, pero así el borde exterior no ve agujeros)
    c0 = bm.verts.new(pts[0])
    pz.uv(c0, 0.0, 0.0)
    for j in range(lados):
        j2 = (j + 1) % lados
        f = bm.faces.new((filas[0][j2], filas[0][j], c0))
        f.material_index = mat


def _uv_mechon(pz, filas, pts, lados):
    """Mechón: u alrededor (0,06 m por vuelta: las hebras igual de finas en todos) y v a lo largo."""
    v = 0.0
    for i, fila in enumerate(filas):
        if i > 0:
            v += (pts[i] - pts[i - 1]).length
        for j, vt in enumerate(fila):
            pz.uv(vt, 0.06 * j / max(lados, 1) if len(fila) > 1 else 0.03, v, 0.06 if len(fila) > 1 else 0.0)


def esfera(pz, centro, rx, ry, rz, segs=24, anillos=16, deformar=None, mat=0):
    """Esfera UV (rx: ancho X, ry: fondo Y, rz: alto Z) con una función deformar(p_local normalizado) -> p_local."""
    bm = pz.bm
    filas = []
    polo_n = None
    polo_s = None
    for i in range(1, anillos):
        th = math.pi * i / anillos                      # 0 arriba
        fila = []
        for j in range(segs):
            ph = 2 * math.pi * j / segs                 # 0 = frente (-Y)
            u = Vector((math.sin(th) * math.sin(ph), -math.sin(th) * math.cos(ph), math.cos(th)))
            if deformar:
                u = deformar(u)
            vt = bm.verts.new(centro + Vector((u.x * rx, u.y * ry, u.z * rz)))
            r = (rx + ry) * 0.5
            pz.uv(vt, ph * r, th * (rx + rz) * 0.5, 2 * math.pi * r)
            fila.append(vt)
        filas.append(fila)
    un = Vector((0, 0, 1)); us = Vector((0, 0, -1))
    if deformar:
        un = deformar(un); us = deformar(us)
    polo_n = bm.verts.new(centro + Vector((un.x * rx, un.y * ry, un.z * rz)))
    polo_s = bm.verts.new(centro + Vector((us.x * rx, us.y * ry, us.z * rz)))
    pz.uv(polo_n, 0.0, 0.0)
    pz.uv(polo_s, 0.0, math.pi * (rx + rz) * 0.5)
    for i in range(len(filas) - 1):
        for j in range(segs):
            j2 = (j + 1) % segs
            f = bm.faces.new((filas[i][j], filas[i + 1][j], filas[i + 1][j2], filas[i][j2]))
            f.material_index = mat
    for j in range(segs):
        j2 = (j + 1) % segs
        f = bm.faces.new((filas[0][j2], polo_n, filas[0][j]) if False else (polo_n, filas[0][j], filas[0][j2]))
        f.material_index = mat
        f = bm.faces.new((filas[-1][j], polo_s, filas[-1][j2]))
        f.material_index = mat


def caja(pz, centro, ejes, medidas, mat=0, bisel=0.0):
    """Caja orientada (ejes: tres vectores unitarios; medidas: medio ancho por eje)."""
    bm = pz.bm
    ex, ey, ez = [Vector(e).normalized() for e in ejes]
    vs = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                vs.append(bm.verts.new(centro + ex * sx * medidas[0] + ey * sy * medidas[1] + ez * sz * medidas[2]))
    idx = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    caras = []
    for q in idx:
        f = bm.faces.new([vs[i] for i in q])
        f.material_index = mat
        caras.append(f)
    return caras


def gema(pz, centro, eje, frente, r, largo, mat=0, lados=4):
    """Cristal romboidal (bipirámide) orientado: eje largo y cara hacia «frente»."""
    bm = pz.bm
    t, n, b = marco(eje, frente)
    a1 = bm.verts.new(centro + t * largo * 0.5)
    a2 = bm.verts.new(centro - t * largo * 0.5)
    anillo = []
    for j in range(lados):
        ang = 2 * math.pi * j / lados + math.pi / lados
        anillo.append(bm.verts.new(centro + (n * math.cos(ang) + b * math.sin(ang)) * r))
    for j in range(lados):
        j2 = (j + 1) % lados
        f = bm.faces.new((anillo[j], anillo[j2], a1)); f.material_index = mat
        f = bm.faces.new((anillo[j2], anillo[j], a2)); f.material_index = mat


# ------------------------------------------------------------------ de piezas a objetos
def a_objeto(pz, coleccion, paleta_mats):
    me = bpy.data.meshes.new(pz.nombre)
    bm = pz.bm
    uvl = bm.loops.layers.uv.verify()
    for f in bm.faces:
        us = [l.vert[pz.lu] for l in f.loops]
        cs = [l.vert[pz.lc] for l in f.loops]
        circ = max(cs)
        cos = (circ > 0 and max(us) - min(us) > circ * 0.5)
        for l in f.loops:
            u = l.vert[pz.lu]
            if cos and u < circ * 0.5:
                u += circ
            l[uvl].uv = (u, l.vert[pz.lv])
    bmesh.ops.remove_doubles(pz.bm, verts=pz.bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(pz.bm, faces=pz.bm.faces)
    pz.bm.to_mesh(me)
    pz.bm.free()
    ob = bpy.data.objects.new(pz.nombre, me)
    coleccion.objects.link(ob)
    for n in pz.materiales:
        me.materials.append(paleta_mats[n])
    for p in me.polygons:
        p.use_smooth = True
    if pz.grosor > 0:
        mod = ob.modifiers.new("grosor", 'SOLIDIFY')
        mod.thickness = pz.grosor
        mod.offset = -1.0
        mod.use_even_offset = True
        mod.use_quality_normals = True
        if pz.interior is not None:
            mod.material_offset = pz.materiales.index(pz.interior)     # las caras interiores: el forro
            mod.material_offset_rim = 0
        bpy.context.view_layer.objects.active = ob
        for o in bpy.context.selected_objects:
            o.select_set(False)
        ob.select_set(True)
        bpy.ops.object.modifier_apply(modifier=mod.name)
        # el desplazamiento de material solo vale si el interior es el último: se recoloca
        if pz.interior is not None:
            k = pz.materiales.index(pz.interior)
            n = len(pz.materiales)
            for p in me.polygons:
                if p.material_index >= n:
                    p.material_index = k
    ob["huesos"] = [h for h, _ in pz.huesos]
    ob["factores"] = [f for _, f in pz.huesos]
    ob["potencia"] = pz.p
    return ob


def dist_segmento(p, a, b):
    ab = b - a
    L2 = ab.length_squared
    if L2 < 1e-12:
        return (p - a).length, 0.0
    t = max(0.0, min(1.0, (p - a).dot(ab) / L2))
    return (p - (a + ab * t)).length, t


def pesar(ob, H, suavizar=2):
    """Pesos por distancia a los huesos permitidos de la pieza (ob['huesos'], ob['factores'], ob['potencia'])."""
    huesos = list(ob["huesos"])
    factores = list(ob["factores"])
    p = float(ob["potencia"])
    me = ob.data
    segs = []
    for n in huesos:
        a, b = H.seg(n)
        segs.append((a, b))
    W = []
    for v in me.vertices:
        co = ob.matrix_world @ v.co
        ws = []
        for (a, b), f in zip(segs, factores):
            d, _ = dist_segmento(co, a, b)
            ws.append(f / (d + 0.004) ** p)
        s = sum(ws)
        W.append([w / s for w in ws])
    # suavizado por vecinos (uniones sin pliegues bruscos)
    if suavizar and len(huesos) > 1:
        vec = [[] for _ in me.vertices]
        for e in me.edges:
            a, b = e.vertices
            vec[a].append(b); vec[b].append(a)
        for _ in range(suavizar):
            W2 = []
            for i, w in enumerate(W):
                if not vec[i]:
                    W2.append(w); continue
                acc = [x * 0.5 for x in w]
                k = 0.5 / len(vec[i])
                for j in vec[i]:
                    for h in range(len(w)):
                        acc[h] += W[j][h] * k
                W2.append(acc)
            W = W2
    for i, n in enumerate(huesos):
        nombre = n if n in H.h else P + n
        g = ob.vertex_groups.get(nombre) or ob.vertex_groups.new(name=nombre)
        for vi, w in enumerate(W):
            # como mucho 4 influencias: se quitan las pequeñas
            orden = sorted(range(len(w)), key=lambda h: -w[h])[:4]
            if i in orden and w[i] > 0.01:
                tot = sum(w[h] for h in orden if w[h] > 0.01)
                g.add([vi], w[i] / tot, 'REPLACE')


# ------------------------------------------------------------------ color por vértice y oclusión
def colorear(ob, paleta, ao=None):
    """paleta[nombre] = {"color": (r,g,b) sRGB o función(pos)->(r,g,b), "tipo": nombre de TIPOS}.
    ao: lista por vértice (0..1) para oscurecer los huecos."""
    me = ob.data
    if "Col" in me.color_attributes:
        me.color_attributes.remove(me.color_attributes["Col"])
    ca = me.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
    nombres = [m.name.replace("pal_", "") for m in me.materials]
    for p in me.polygons:
        ent = paleta[nombres[p.material_index]]
        tipo = TIPOS[ent.get("tipo", "tela")] / 7.0
        for li in p.loop_indices:
            vi = me.loops[li].vertex_index
            co = ob.matrix_world @ me.vertices[vi].co
            c = ent["color"]
            if callable(c):
                c = c(co)
            # se guarda en sRGB (más precisión en los oscuros con 8 bits); el sombreador lo pasa a lineal
            k = 1.0
            if ao is not None:
                k = ao[vi]
            ca.data[li].color = (c[0] * k, c[1] * k, c[2] * k, tipo)
    me.color_attributes.active_color = ca
    try:
        me.color_attributes.render_color_index = me.color_attributes.active_color_index
    except Exception:
        pass


def srgb_a_lineal(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def oclusion(obs, rayos=24, distancia=0.06, fuerza=0.45, seed=3):
    """Oclusión ambiental por vértice con rayos contra TODAS las piezas (huecos entre pelo, cuello del abrigo,
    cinturón…). Devuelve {objeto: [factor 0..1]}."""
    random.seed(seed)
    deps = bpy.context.evaluated_depsgraph_get()
    verts = []
    tris = []
    for ob in obs:
        me = ob.data
        base = len(verts)
        verts += [ob.matrix_world @ v.co for v in me.vertices]
        for p in me.polygons:
            vs = list(p.vertices)
            for k in range(1, len(vs) - 1):
                tris.append((base + vs[0], base + vs[k], base + vs[k + 1]))
    bvh = BVHTree.FromPolygons(verts, tris)
    dirs = []
    for i in range(rayos):          # hemisferio de Fibonacci
        z = (i + 0.5) / rayos
        r = math.sqrt(1 - z * z)
        a = i * 2.399963
        dirs.append(Vector((math.cos(a) * r, math.sin(a) * r, z)))
    res = {}
    for ob in obs:
        me = ob.data
        me.calc_loop_triangles() if hasattr(me, "calc_loop_triangles") else None
        out = []
        m3 = ob.matrix_world.to_3x3()
        for v in me.vertices:
            co = ob.matrix_world @ v.co
            n = (m3 @ v.normal).normalized()
            q = Vector((0, 0, 1)).rotation_difference(n)
            libre = 0.0
            for d in dirs:
                dd = q @ d
                hit = bvh.ray_cast(co + n * 0.0015, dd, distancia)
                if hit[0] is None:
                    libre += d.z
                else:
                    libre += d.z * min(1.0, hit[3] / distancia) * 0.6
            tot = sum(d.z for d in dirs)
            a = libre / tot
            out.append(1.0 - fuerza * (1.0 - a))
        res[ob.name] = out
    return res


def mechon_pts(pz, pts, normales, ancho, grueso, lados=6, mat=0, perfil=None):
    """Mechón por una lista de puntos con su normal «hacia fuera» en cada uno. perfil(s) -> factor del ancho
    (por defecto: estrecho en la raíz, ancho hacia el 35 % y en punta al final)."""
    bm = pz.bm
    n = len(pts) - 1
    if perfil is None:
        perfil = lambda s: (0.45 + 0.55 * math.sin(min(1.0, s / 0.35) * math.pi / 2)) * (1.0 - max(0.0, s - 0.35) / 0.65) ** 0.9
    filas = []
    for i, c in enumerate(pts):
        s = i / n
        if i == n:
            filas.append([bm.verts.new(c)])
            continue
        t = (pts[min(i + 1, n)] - pts[max(i - 1, 0)])
        t, nn, b = marco(t, normales[i])
        k = perfil(s)
        fila = []
        for j in range(lados):
            a = 2 * math.pi * j / lados
            gx = math.sin(a) * ancho * k
            gy = math.cos(a) * grueso * max(k, 0.25) * (1.0 if math.cos(a) > 0 else 0.55)
            fila.append(bm.verts.new(c + b * gx + nn * gy))
        filas.append(fila)
    _uv_mechon(pz, filas, pts, lados)
    for i in range(n - 1):
        for j in range(lados):
            j2 = (j + 1) % lados
            f = bm.faces.new((filas[i][j], filas[i][j2], filas[i + 1][j2], filas[i + 1][j]))
            f.material_index = mat
    for j in range(lados):
        j2 = (j + 1) % lados
        f = bm.faces.new((filas[-2][j], filas[-2][j2], filas[-1][0]))
        f.material_index = mat
    c0 = bm.verts.new(pts[0] - (pts[1] - pts[0]).normalized() * 0.002)
    pz.uv(c0, 0.0, 0.0)
    for j in range(lados):
        j2 = (j + 1) % lados
        f = bm.faces.new((filas[0][j2], filas[0][j], c0))
        f.material_index = mat
