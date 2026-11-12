# Utilidades de Blender de los enemigos de la fase C de la V12 (12/11/2026, especialista de animaciones): el Guardián
# de piedra, el Gólem de ámbar y Gorthor. Se apoya en personajes/desierto/fuentes_blender/desierto_comun.py (malla por
# partes, esqueleto, poses en ejes de armadura, exportación y Kael a escala) y añade:
#   - AtlasV12: un atlas de 1024 en 4×4 celdas de 256 px, cada una un material pintado por código (ruido, vetas,
#     grietas, motas) y proyectado en planta, alzado o perfil según la cara (proyectar()): textura de verdad en 2D,
#     no una tira de color. Se guarda en WebP de 1024 (alto) y de 512 (bajo).
#   - bloques redondeados con ruido (piedra, ámbar) y oclusión ambiental horneada en el color de vértice;
#   - clips muestreados en cada fotograma (Catmull-Rom entre claves, con tramos que aceleran o frenan) con IK de dos
#     huesos para los pies (apoyados donde se diga: sin patinar) y las manos (la segunda mano agarra el arma);
#   - el JSON de clips con los instantes de impacto, la lámina de concepto y las hojas de poses.
# Nada descargado: obra propia del proyecto.
#
# Ejes (Blender): el enemigo mira a -Y, Z arriba, su izquierda es +X. En Godot mira a +Z.
# Giros (como en desierto_comun): (ax, ay, az) en grados alrededor de los ejes de la armadura, sobre el reposo del hueso
# y dentro del marco ya girado de su padre. Hueso hacia arriba: +ax lo inclina hacia delante, +az lo gira hacia su
# izquierda. Hueso hacia abajo (brazo, pierna): -ax lo lleva hacia delante; -ay lo abre hacia +X (su izquierda).
# sim() refleja una pose de los huesos .L en los .R.
import bpy, bmesh, math, os, json, random
import numpy as np
from mathutils import Vector, Matrix, Quaternion, Euler
from mathutils.bvhtree import BVHTree
import desierto_comun as C

FPS = 30


# ================================================================== ruido y pintura (numpy)

def ruido(h, celdas, rng):
    """Ruido de valor suave de h×h con «celdas» cuadros (no se repite)."""
    g = rng.random((celdas + 2, celdas + 2))
    x = np.linspace(0, celdas, h, endpoint=False)
    i = x.astype(int)
    f = x - i
    f = f * f * (3 - 2 * f)
    a, b = g[np.ix_(i, i)], g[np.ix_(i, i + 1)]
    c, d = g[np.ix_(i + 1, i)], g[np.ix_(i + 1, i + 1)]
    fx, fy = f[None, :], f[:, None]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(h, rng, base=4, octavas=4, ganancia=0.5):
    tot, amp, s = np.zeros((h, h)), 1.0, 0.0
    for k in range(octavas):
        tot += ruido(h, base * 2 ** k, rng) * amp
        s += amp
        amp *= ganancia
    return tot / s


def celdas_voronoi(h, rng, n=20):
    """(F1, F2): distancia al punto más cercano y al segundo (0..1 de la celda)."""
    pts = rng.random((n, 2))
    yy, xx = np.mgrid[0:h, 0:h]
    X, Y = (xx + 0.5) / h, (yy + 0.5) / h
    d = np.sqrt((X[..., None] - pts[None, None, :, 0]) ** 2 + (Y[..., None] - pts[None, None, :, 1]) ** 2)
    d.sort(axis=2)
    return d[..., 0], d[..., 1]


def grietas(h, rng, n=20, ancho=0.010):
    f1, f2 = celdas_voronoi(h, rng, n)
    return np.clip(1.0 - (f2 - f1) / ancho, 0, 1)


def color(c):
    return np.array(c, dtype=np.float32)[None, None, :]


def mezclar(base, rgb, m):
    m = np.clip(m, 0, 1)[..., None]
    return base * (1 - m) + color(rgb) * m


class AtlasV12:
    """Atlas de tam×tam en n×n celdas. celda(nombre, f): f(h, rng) -> imagen h×h×3 (sRGB 0..1; fila 0 abajo)."""

    def __init__(self, tam=1024, n=4, semilla=5):
        self.tam, self.n = tam, n
        self.c = tam // n
        self.img = np.zeros((tam, tam, 3), dtype=np.float32)
        self.pos = {}
        self.rng = np.random.default_rng(semilla)

    def celda(self, nombre, f):
        i = len(self.pos)
        col, fila = i % self.n, i // self.n
        assert fila < self.n, "atlas lleno"
        x0, y0 = col * self.c, self.tam - (fila + 1) * self.c
        self.img[y0:y0 + self.c, x0:x0 + self.c] = np.clip(f(self.c, self.rng), 0, 1)
        self.pos[nombre] = (x0, y0)
        return nombre

    def uv(self, nombre, u, v, margen=0.035):
        x0, y0 = self.pos[nombre]
        u = margen + (1 - 2 * margen) * min(max(u, 0.0), 1.0)
        v = margen + (1 - 2 * margen) * min(max(v, 0.0), 1.0)
        return ((x0 + u * self.c) / self.tam, (y0 + v * self.c) / self.tam)

    def guardar(self, ruta_png=None, rutas_webp=()):
        """rutas_webp: [(ruta, tamaño)]. Guarda el PNG de trabajo (opcional) y los WebP."""
        rgba = np.concatenate([self.img, np.ones((self.tam, self.tam, 1), np.float32)], axis=2)
        im = bpy.data.images.new("atlas_v12", self.tam, self.tam, alpha=False)
        im.pixels.foreach_set(rgba.ravel())
        if ruta_png:
            im.filepath_raw = ruta_png
            im.file_format = 'PNG'
            im.save()
        for ruta, t in rutas_webp:
            k = self.tam // t
            px = rgba.reshape(t, k, t, k, 4).mean(axis=(1, 3)) if k > 1 else rgba
            c = bpy.data.images.new("atlas_v12_%d" % t, t, t, alpha=False)
            c.pixels.foreach_set(px.ravel())
            c.filepath_raw = ruta
            c.file_format = 'WEBP'
            try:
                c.save(quality=92)
            except TypeError:
                c.save()
        return im


# ================================================================== geometría

def caja_redonda(m, centro, tam, giro=None, redondez=0.35, cortes=2, ruido_amp=0.0, semilla=0.0, afinar=None):
    """Caja de medidas «tam» con las aristas redondeadas (tiende a la esfera) y algo de ruido. afinar(p) -> factor
    de escala en x e y según la altura relativa (-0.5..0.5), para troncos de cono."""
    for v in m.bm.verts:                 # (los BMVert no sirven en un set: se marca lo que ya había)
        v.tag = True
    r = bmesh.ops.create_cube(m.bm, size=1.0)
    vs = r["verts"]
    caras = {f for v in vs for f in v.link_faces}
    aristas = {e for f in caras for e in f.edges}
    if cortes:
        bmesh.ops.subdivide_edges(m.bm, edges=list(aristas), cuts=cortes, use_grid_fill=True)
        vs = [v for v in m.bm.verts if not v.tag]
    rnd = random.Random(semilla)
    fase = Vector((rnd.random() * 10, rnd.random() * 10, rnd.random() * 10))
    for v in vs:
        p = v.co * 2.0
        q = p.normalized() * p.length / max(abs(p.x), abs(p.y), abs(p.z), 1e-6)
        p = p.lerp(p.normalized() * max(abs(p.x), abs(p.y), abs(p.z)), redondez)
        _ = q
        if afinar:
            k = afinar(v.co.z)
            p = Vector((p.x * k, p.y * k, p.z))
        if ruido_amp:
            from mathutils import noise
            p += p.normalized() * noise.noise(p * 1.7 + fase) * ruido_amp
        v.co = p * 0.5
    M = Matrix.Translation(Vector(centro)) @ (giro.to_matrix().to_4x4() if giro else Matrix()) @ \
        Matrix.Diagonal((tam[0], tam[1], tam[2], 1.0))
    bmesh.ops.transform(m.bm, matrix=M, verts=vs)
    return vs


def roca(m, centro, radio, semilla, sub=1, amp=0.25, escala=(1, 1, 1), giro=None):
    """Icosfera facetada con ruido (lascas, ámbar, piedras sueltas)."""
    from mathutils import noise
    r = bmesh.ops.create_icosphere(m.bm, subdivisions=sub, radius=1.0)
    vs = r["verts"]
    fase = Vector((semilla * 1.3, semilla * 2.1, semilla * 0.7))
    for v in vs:
        v.co = v.co * (1.0 + noise.noise(v.co * 1.9 + fase) * amp)
    M = Matrix.Translation(Vector(centro)) @ (giro.to_matrix().to_4x4() if giro else Matrix()) @ \
        Matrix.Diagonal((radio * escala[0], radio * escala[1], radio * escala[2], 1.0))
    bmesh.ops.transform(m.bm, matrix=M, verts=vs)
    return vs


def proyectar(m, atlas, vs, celda, escala=1.0, pesos=None, mat=0, liso=True, desfase=(0.0, 0.0)):
    """UV de las caras de «vs» en la celda del atlas, por la cara dominante de la normal (planta, alzado o perfil),
    a «escala» metros por celda; cada cara se desplaza para no salirse de la celda (costuras invisibles con ruido)."""
    vs = [v for v in vs if v.is_valid]
    caras = {f for v in vs for f in v.link_faces}
    rnd = random.Random(len(vs))
    for f in caras:
        f.normal_update()
        f.smooth = liso
        f.material_index = mat
        n = f.normal
        ax = max(range(3), key=lambda k: abs(n[k]))
        ejes = {0: (1, 2), 1: (0, 2), 2: (0, 1)}[ax]
        us = [(lp.vert.co[ejes[0]] / escala + desfase[0], lp.vert.co[ejes[1]] / escala + desfase[1]) for lp in f.loops]
        u0, v0 = min(u for u, _ in us), min(v for _, v in us)
        du, dv = math.floor(u0), math.floor(v0)
        su = max(0.0, max(u for u, _ in us) - du - 1.0)
        sv = max(0.0, max(v for _, v in us) - dv - 1.0)
        for lp, (u, v) in zip(f.loops, us):
            lp[m.uv].uv = atlas.uv(celda, u - du - su, v - dv - sv)
    m.pesar(vs, pesos)
    return vs


def plano_uv(m, atlas, vs, celda, origen, eje_u, eje_v, tam_u, tam_v, pesos=None, mat=0, liso=True):
    """UV de un plano propio (estandartes, tela): u a lo largo de eje_u, v de eje_v, sin costuras."""
    vs = [v for v in vs if v.is_valid]
    caras = {f for v in vs for f in v.link_faces}
    o, eu, ev = Vector(origen), Vector(eje_u).normalized(), Vector(eje_v).normalized()
    for f in caras:
        f.smooth = liso
        f.material_index = mat
        for lp in f.loops:
            d = lp.vert.co - o
            lp[m.uv].uv = atlas.uv(celda, d.dot(eu) / tam_u, d.dot(ev) / tam_v, margen=0.01)
    m.pesar(vs, pesos)
    return vs


def oclusion(ob, rayos=20, dist=0.55, minimo=0.38, potencia=1.0, semilla=2):
    """Oclusión ambiental por vértice (rayos en el hemisferio de la normal, en la pose de reposo) guardada como
    color de vértice «oclusion» (sRGB, por esquina). Godot la multiplica por el albedo (vertex_color_use_as_albedo)."""
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.normal_update()
    arbol = BVHTree.FromBMesh(bm)
    rnd = random.Random(semilla)
    dirs = []
    while len(dirs) < rayos:
        d = Vector((rnd.uniform(-1, 1), rnd.uniform(-1, 1), rnd.uniform(-1, 1)))
        if 0.05 < d.length <= 1.0:
            dirs.append(d.normalized())
    valores = []
    for v in bm.verts:
        n = v.normal
        o = v.co + n * 0.004
        tapados = 0.0
        usados = 0
        for d in dirs:
            if d.dot(n) < 0:
                d = -d
            usados += 1
            hit = arbol.ray_cast(o, d, dist)
            if hit[0] is not None:
                tapados += 1.0 - (hit[3] / dist) * 0.5
        a = 1.0 - tapados / max(usados, 1)
        valores.append(minimo + (1 - minimo) * (a ** potencia))
    bm.free()
    capa = me.color_attributes.new("oclusion", 'BYTE_COLOR', 'CORNER')
    for poly in me.polygons:
        for li in poly.loop_indices:
            a = valores[me.loops[li].vertex_index]
            capa.data[li].color = (a, a, a, 1.0)
    me.color_attributes.active_color = capa
    try:
        me.color_attributes.render_color_index = me.color_attributes.find("oclusion")
    except Exception:
        pass
    return valores


# ================================================================== esqueleto bípedo

def sim(pose):
    """Copia los valores .L en .R reflejados (ay, az y x de loc cambian de signo). Lo que ya esté en .R se respeta."""
    out = dict(pose)
    for k, v in pose.items():
        base, _, suf = k.partition("@")
        if not base.endswith(".L"):
            continue
        kr = base[:-2] + ".R" + ("@" + suf if suf else "")
        if kr in pose:
            continue
        if suf in ("loc", "ik"):
            out[kr] = (-v[0], v[1], v[2])
        elif suf in ("esc", "agarre", "ikw", "roll", "suelta"):
            out[kr] = v
        else:
            out[kr] = (v[0], -v[1], -v[2])
    return out


def L(**kw):
    """Atajo: L(brazo=(..), mano=(..)) -> {'brazo.L': .., 'mano.L': ..}."""
    return {k + ".L": v for k, v in kw.items()}


def R(**kw):
    return {k + ".R": v for k, v in kw.items()}


# ================================================================== IK de dos huesos

def _poner_direccion(pb, cabeza, hacia, giro_extra=0.0):
    """Gira el hueso (en espacio de armadura) para que su eje Y apunte de «cabeza» a «hacia»."""
    M = pb.matrix.copy()
    y = (M.to_3x3() @ Vector((0, 1, 0))).normalized()
    nuevo = (Vector(hacia) - Vector(cabeza)).normalized()
    q = y.rotation_difference(nuevo)
    if giro_extra:
        q = Quaternion(nuevo, giro_extra) @ q
    R3 = q.to_matrix() @ M.to_3x3()
    pb.matrix = Matrix.Translation(Vector(cabeza)) @ R3.to_4x4()


def ik_dos(arm, h1, h2, h3, objetivo, polo, orient3=None):
    """Cadena h1→h2 (h3 su extremo: pie o mano). «polo»: hacia dónde dobla la articulación (espacio de armadura).
    orient3: matriz 3×3 de armadura para h3 (None: deja la que traiga)."""
    vl = bpy.context.view_layer
    p1, p2, p3 = arm.pose.bones[h1], arm.pose.bones[h2], arm.pose.bones[h3]
    vl.update()
    H = p1.head.copy()
    a, b = p1.length, p2.length
    F = Vector(objetivo)
    d = F - H
    Ld = min(max(d.length, abs(a - b) + 1e-3), a + b - 1e-4)
    dn = d.normalized()
    x = (a * a - b * b + Ld * Ld) / (2 * Ld)
    hh = math.sqrt(max(a * a - x * x, 0.0))
    pv = Vector(polo) - dn * Vector(polo).dot(dn)
    if pv.length < 1e-5:
        pv = dn.orthogonal()
    pv.normalize()
    K = H + dn * x + pv * hh
    F2 = H + dn * Ld
    _poner_direccion(p1, H, K)
    vl.update()
    _poner_direccion(p2, K, F2)
    vl.update()
    if orient3 is not None:
        p3.matrix = Matrix.Translation(F2) @ orient3.to_4x4()
        vl.update()
    return F2


# ================================================================== clips muestreados

def _val_defecto(k):
    if k.endswith(("@agarre", "@roll", "@ikw", "@suelta")):
        return 0.0
    return (1, 1, 1) if k.endswith("@esc") else (0, 0, 0)


def _interp(claves, f, bucle, total):
    """claves: [(fotograma, pose, tramo)] — «tramo» es cómo se va DESDE esa clave a la siguiente:
    'cr' (Catmull-Rom), 'acel' (acelera), 'fren' (frena), 'lin', 'corte' (salto seco). Devuelve la pose en f."""
    n = len(claves)
    if bucle:
        ext = [(claves[-2][0] - total, claves[-2][1], claves[-2][2])] + claves + [(claves[1][0] + total, claves[1][1], claves[1][2])]
    else:
        ext = [claves[0]] + claves + [claves[-1]]
    for i in range(1, len(ext) - 2):
        f0, f1 = ext[i][0], ext[i + 1][0]
        if f0 <= f <= f1 or (i == len(ext) - 3):
            break
    f0, p0, tramo = ext[i]
    f1, p1, _ = ext[i + 1]
    fa, pa = ext[i - 1][0], ext[i - 1][1]
    fb, pb = ext[i + 2][0], ext[i + 2][1]
    t = 0.0 if f1 == f0 else min(max((f - f0) / (f1 - f0), 0.0), 1.0)
    claves_todas = set(p0) | set(p1) | set(pa) | set(pb)
    out = {}
    for k in claves_todas:
        d = _val_defecto(k)
        v0, v1 = p0.get(k, d), p1.get(k, d)
        if isinstance(v0, (int, float)):
            v0, v1, va, vb = (v0,), (v1,), (pa.get(k, d),), (pb.get(k, d),)
        else:
            va, vb = pa.get(k, d), pb.get(k, d)
        res = []
        for c in range(len(v0)):
            x0, x1 = v0[c], v1[c]
            if tramo == "corte":
                y = x0 if t < 1.0 else x1
            elif tramo == "lin":
                y = x0 + (x1 - x0) * t
            elif tramo == "acel":
                y = x0 + (x1 - x0) * (t ** 2.2)
            elif tramo == "fren":
                y = x0 + (x1 - x0) * (1 - (1 - t) ** 2.2)
            else:
                dt = max(f1 - f0, 1e-6)
                m0 = 0.0 if (fa == f0 or claves_paran(ext, i)) else (x1 - va[c]) / max(f1 - fa, 1e-6) * dt
                m1 = 0.0 if (fb == f1 or claves_paran(ext, i + 1)) else (vb[c] - x0) / max(fb - f0, 1e-6) * dt
                t2, t3 = t * t, t * t * t
                y = (2 * t3 - 3 * t2 + 1) * x0 + (t3 - 2 * t2 + t) * m0 + (-2 * t3 + 3 * t2) * x1 + (t3 - t2) * m1
            res.append(y)
        out[k] = res[0] if isinstance(p0.get(k, d), (int, float)) else tuple(res)
    return out


def claves_paran(ext, i):
    """Una clave cuyo tramo de llegada fue 'acel' o 'corte' (un impacto) para en seco: tangente cero al salir."""
    return i > 0 and ext[i - 1][2] in ("acel", "corte") or ext[i][2] == "parar"


class Rig:
    """Esqueleto bípedo con IK de pies y manos. Las claves de pose admiten, además de giros, «@loc» y «@esc»:
      pie.L@ik / pie.R@ik      dónde va el tobillo (armadura); por defecto, donde está en reposo (apoyado)
      pie.L@rot                giro del pie en ejes de armadura (por defecto, plano como en reposo)
      mano.L@agarre            0..1: la mano izquierda va al agarre del arma (self.agarre_izq = (hueso, punto local))
      mano.R@agarre            igual con la derecha (self.agarre_der)
    """

    def __init__(self, arm, polo_rodilla=Vector((0, -1, 0.0)), polo_codo=None):
        self.arm = arm
        self.polo_rodilla = polo_rodilla
        self.polo_codo = polo_codo or {".L": Vector((0.6, 0.6, -0.4)), ".R": Vector((-0.6, 0.6, -0.4))}
        self.agarre_izq = None
        self.agarre_der = None
        b = arm.data.bones
        self.tobillo = {s: b["pie" + s].head_local.copy() for s in (".L", ".R") if ("pie" + s) in b}
        self.rest3 = {n: b[n].matrix_local.to_3x3() for n in b.keys()}
        self.extra = None              # extra(arm, pose, f): lo propio de cada criatura tras el IK
        self.piernas = True
        self.arma = None               # hueso del arma (hijo de mano.R) si se coloca en el mundo (arma@pos/@dir)
        self.mano_en_arma = {}
        self.clip_actual = ""
        self.procedural = None         # procedural(segundos) -> claves que sustituyen a las interpoladas
        self.defecto = {}              # claves que lleva toda pose que no las diga (piezas escondidas, etc.)

    def poner_arma(self, hueso, atras=0.15):
        """El arma se coloca con «<hueso>@pos» (dónde la empuña la mano derecha, en el espacio de la raíz) y
        «<hueso>@dir» (giro sobre su reposo, ejes de armadura); las manos van a la empuñadura por IK (la izquierda
        con mano.L@agarre, «atras» metros más cerca del pomo). «codo.L@polo»: hacia dónde dobla ese codo."""
        b = self.arm.data.bones
        self.arma = hueso
        inv = b[hueso].matrix_local.inverted()
        mr = inv @ b["mano.R"].head_local
        self.mano_en_arma = {".R": mr, ".L": mr + Vector((0, -atras, 0))}

    def matriz_arma(self, pose):
        arm = self.arm
        rb = arm.pose.bones["raiz"]
        delta = rb.matrix @ arm.data.bones["raiz"].matrix_local.inverted()
        rot = Euler([math.radians(a) for a in pose.get(self.arma + "@dir", (0, 0, 0))], 'XYZ').to_matrix() @ \
            Matrix.Rotation(math.radians(pose.get(self.arma + "@roll", 0.0)), 3, "Y") @ self.rest3[self.arma]
        return delta @ (Matrix.Translation(Vector(pose[self.arma + "@pos"])) @ rot.to_4x4())

    def aplicar(self, pose, f=0):
        arm = self.arm
        C.poner_pose(arm, {k: v for k, v in pose.items() if "@" not in k or k.endswith("@loc") or k.endswith("@esc")})
        vl = bpy.context.view_layer
        vl.update()
        if self.piernas:
            for s in (".L", ".R"):
                if ("pie" + s) not in arm.pose.bones:
                    continue
                obj = pose.get("pie" + s + "@ik", tuple(self.tobillo[s]))
                rot = pose.get("pie" + s + "@rot", (0, 0, 0))
                o3 = Euler([math.radians(a) for a in rot], 'XYZ').to_matrix() @ self.rest3["pie" + s]
                polo = self.polo_rodilla + Vector((0.25 if s == ".L" else -0.25, 0, 0))
                ik_dos(arm, "muslo" + s, "pierna" + s, "pie" + s, obj, polo, o3)
        # manos libres por IK: «mano.L@ik» (muñeca, en el espacio de la raíz) con peso «mano.L@ikw» (0: el FK).
        # Para mezclar sin saltos, el objetivo va en todas las claves del clip (también con peso 0).
        for s in (".L", ".R"):
            w = pose.get("mano" + s + "@ikw", 0.0)
            if w <= 1e-3 or ("mano" + s + "@ik") not in pose:
                continue
            vl.update()
            rb = arm.pose.bones["raiz"]
            delta = rb.matrix @ arm.data.bones["raiz"].matrix_local.inverted()
            obj = arm.pose.bones["mano" + s].head.copy().lerp(delta @ Vector(pose["mano" + s + "@ik"]), w)
            polo = Vector(pose.get("codo" + s + "@polo", tuple(self.polo_codo[s])))
            ik_dos(arm, "brazo" + s, "antebrazo" + s, "mano" + s, obj, polo, None)
        if self.arma and (self.arma + "@pos") in pose:
            vl.update()
            Mw = self.matriz_arma(pose)
            R3 = Mw.to_3x3().normalized()
            for s in (".R", ".L"):
                w = 1.0 - pose.get("mano.R@suelta", 0.0) if s == ".R" else pose.get("mano.L@agarre", 0.0)   # suelta: la mano derecha deja el arma (va a su @ik)
                if w <= 1e-3:
                    continue
                pm = arm.pose.bones["mano" + s]
                obj = Mw @ self.mano_en_arma[s]
                o3 = R3 @ self.rest3[self.arma].inverted() @ self.rest3["mano.R"]
                if w < 0.999:
                    obj = pm.head.copy().lerp(obj, w)
                    o3 = o3 if w > 0.5 else None
                polo = Vector(pose.get("codo" + s + "@polo", tuple(self.polo_codo[s])))
                ik_dos(arm, "brazo" + s, "antebrazo" + s, "mano" + s, obj, polo, o3)
            vl.update()
            arm.pose.bones[self.arma].matrix = Mw
        if self.extra:
            self.extra(arm, pose, f)
        vl.update()

    def clip(self, nombre, claves, bucle=False, interp='LINEAR', proc=None):
        """claves: [(segundos, pose[, tramo])]. Muestrea cada fotograma (1 = segundo 0) y crea la acción.
        proc(segundos) -> claves que sustituyen a las interpoladas (ciclos de pasos, temblores)."""
        arm = self.arm
        self.clip_actual = nombre
        cl = []
        for c in claves:
            seg, pose = c[0], c[1]
            tramo = c[2] if len(c) > 2 else "cr"
            cl.append((round(seg * FPS) + 1, {**self.defecto, **pose}, tramo))
        total = cl[-1][0] - cl[0][0]
        if arm.animation_data is None:
            arm.animation_data_create()
        act = bpy.data.actions.new(nombre)
        act.use_fake_user = True
        arm.animation_data.action = act
        previo = {}
        for f in range(cl[0][0], cl[-1][0] + 1):
            pose = _interp(cl, f, bucle, total)
            if proc:
                pose.update(proc((f - cl[0][0]) / FPS))
            self.aplicar(pose, (f - cl[0][0]) / FPS)
            for pb in arm.pose.bones:
                q = pb.rotation_quaternion.copy()
                if pb.name in previo and previo[pb.name].dot(q) < 0:
                    q.negate()
                    pb.rotation_quaternion = q
                previo[pb.name] = q.copy()
                pb.keyframe_insert("rotation_quaternion", frame=f, group=pb.name)
                pb.keyframe_insert("location", frame=f, group=pb.name)
                pb.keyframe_insert("scale", frame=f, group=pb.name)
        try:
            curvas = act.fcurves
        except AttributeError:
            curvas = [fc for capa in act.layers for tira in capa.strips for cb in tira.channelbags for fc in cb.fcurves]
        for fc in curvas:
            for k in fc.keyframe_points:
                k.interpolation = interp
        arm.animation_data.action = None
        pista = arm.animation_data.nla_tracks.new()
        pista.name = nombre
        pista.strips.new(nombre, cl[0][0], act)
        pista.mute = True
        return act, (cl[-1][0] - cl[0][0]) / FPS


def punto_hueso(arm, rig, accion, segundos, hueso, local=(0, 0, 0)):
    """Dónde está un punto local de un hueso (armadura) en el segundo dado de un clip (para medir alcances)."""
    C.accion(arm, accion)
    bpy.context.scene.frame_set(round(segundos * FPS) + 1)
    bpy.context.view_layer.update()
    p = arm.pose.bones[hueso].matrix @ Vector(local)
    return p


# ================================================================== materiales, exportación y JSON

def materiales(ob, nombres):
    """Materiales (vacíos: Godot pone los suyos por nombre) en el orden de los índices de la malla."""
    for n in nombres:
        m = bpy.data.materials.get(n) or bpy.data.materials.new(n)
        ob.data.materials.append(m)


def exportar(ruta):
    bpy.ops.export_scene.gltf(
        filepath=ruta, export_format='GLB', use_selection=False,
        export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
        export_anim_slide_to_zero=True, export_def_bones=False, export_reset_pose_bones=True,
        export_optimize_animation_size=False, export_skins=True, export_yup=True, export_influence_nb=4,
        export_vertex_color='ACTIVE', export_cameras=False, export_lights=False, export_materials='EXPORT',
        export_image_format='NONE')


def guardar_json(ruta, datos):
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(datos, f, indent=1, ensure_ascii=False)


# ================================================================== láminas y hojas

def material_vista(nombre, imagen, emision=None, vc=True):
    """Material de render (Blender) para las láminas: atlas × oclusión (gamma 2,2) o emisión."""
    m = nombre if not isinstance(nombre, str) else bpy.data.materials.get(nombre)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF") or nt.nodes.new("ShaderNodeBsdfPrincipled")
    out = nt.nodes.get("Material Output") or nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(bsdf.outputs[0], out.inputs[0])
    bsdf.inputs["Roughness"].default_value = 0.75
    if emision is not None:
        bsdf.inputs["Base Color"].default_value = (*emision[:3], 1)
        bsdf.inputs["Emission Color"].default_value = (*emision[:3], 1)
        bsdf.inputs["Emission Strength"].default_value = emision[3]
        return m
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = imagen
    sal = tex.outputs["Color"]
    if vc:
        attr = nt.nodes.new("ShaderNodeVertexColor")
        attr.layer_name = "oclusion"
        gam = nt.nodes.new("ShaderNodeGamma")
        gam.inputs[1].default_value = 2.2
        nt.links.new(attr.outputs["Color"], gam.inputs[0])
        mul = nt.nodes.new("ShaderNodeMix")
        mul.data_type = 'RGBA'
        mul.blend_type = 'MULTIPLY'
        mul.inputs[0].default_value = 1.0
        nt.links.new(sal, mul.inputs[6])
        nt.links.new(gam.outputs[0], mul.inputs[7])
        sal = mul.outputs[2]
    nt.links.new(sal, bsdf.inputs["Base Color"])
    return m


def render(esc, ruta):
    esc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)


def poses_render(esc, arm, instantes, carpeta, prefijo, objetivo=(0, 0, 1.2), distancia=12, azimut=-35, elev=10,
                 orto=3.8):
    """Renderiza el modelo en cada instante [(clip, segundos)] (cámara fija) y devuelve las rutas."""
    cam = C.camara(esc, objetivo, distancia, azimut, elev, orto=orto)
    rutas = []
    for i, (clip, seg) in enumerate(instantes):
        C.accion(arm, clip)
        esc.frame_set(round(seg * FPS) + 1)
        ruta = os.path.join(carpeta, "%s_%02d_%s_%03d.png" % (prefijo, i, clip, round(seg * 100)))
        render(esc, ruta)
        rutas.append(ruta)
    bpy.data.objects.remove(cam)
    return rutas


def componer(rutas, salida, columnas):
    """Junta imágenes del mismo tamaño en una hoja (filas de «columnas»)."""
    ims = [bpy.data.images.load(r) for r in rutas]
    w, h = ims[0].size
    filas = (len(ims) + columnas - 1) // columnas
    hoja = np.ones((filas * h, columnas * w, 4), dtype=np.float32)
    for k, im in enumerate(ims):
        px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)
        fila, col = k // columnas, k % columnas
        y0 = (filas - 1 - fila) * h
        hoja[y0:y0 + h, col * w:(col + 1) * w] = px
    out = bpy.data.images.new("hoja", columnas * w, filas * h)
    out.pixels.foreach_set(hoja.ravel())
    out.filepath_raw = salida
    out.file_format = 'PNG'
    out.save()
    for im in ims:
        bpy.data.images.remove(im)
    bpy.data.images.remove(out)


def camino_grieta(rnd, inicio, angulo, pasos=6, paso=0.06, quiebro=38.0, ramas=1):
    """Grieta o veta quebrada en un plano (x, z): [[(x, z)…], …] (la principal y sus ramas), con quiebros al azar."""
    caminos = []
    pendientes = [(tuple(inicio), angulo, pasos)]
    while pendientes:
        (x, z), a, n = pendientes.pop()
        pts = [(x, z)]
        for k in range(n):
            a += rnd.uniform(-quiebro, quiebro)
            l = paso * rnd.uniform(0.7, 1.3)
            x, z = x + math.cos(math.radians(a)) * l, z + math.sin(math.radians(a)) * l
            pts.append((x, z))
            if ramas and k == n // 2 and len(caminos) < ramas:
                pendientes.append(((x, z), a + rnd.choice((-1, 1)) * rnd.uniform(35, 60), max(2, n // 2)))
        caminos.append(pts)
    return caminos
