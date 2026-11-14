# Nix vestuario canónico (V12, 14/11, segunda pasada): ropa como PIEZAS SEPARADAS sobre el cuerpo y el esqueleto del
# piloto (p4_rig.blend), sin tocar la cara ni la identidad.
#   blender -b -P p8_vestuario.py -- <p4_rig.blend> <carpeta texturas> <carpeta render> <blend salida> <glb salida>
#                                     [sin_render] [hasta=<etapa>]
#
# Piezas (todas en UNA malla «ropa_nix» con UN material «nix_ropa», atlas de 1024: color y metal/rugosidad):
#   capucha amplia (exterior negra, forro púrpura, ribete dorado; rostro visible, sin sombrero) con el pelo RECOGIDO
#   dentro (el pelo de los lados y de detrás se comprime hacia el cráneo; el flequillo, el mechón superior y los dos
#   delanteros quedan como estaban); capa corta sobre los hombros con vuelo y forro; cuerpo (corpiño) con cinturón,
#   cierres, amatista y el EMBLEMA DORADO de la espalda (Ojo de Horus en estrella de seis puntas de dos triángulos);
#   mangas con bordado y puños; faldón corto (peplo) y dos faldones largos abiertos por delante, forro púrpura y
#   bordados; tabardo delantero; medias asimétricas (hojas y ramas en la derecha, geometría en la izquierda, como la
#   referencia de frente); botas; bolsas del cinturón y colgantes de los faldones.
# Las piezas ceñidas son copias desplazadas de las caras del cuerpo (heredan sus pesos: no atraviesan al doblarse); las
# sueltas se construyen por guion y sus pesos se copian del punto más cercano del cuerpo o van a sus huesos propios:
#   faldon_i_1/2, faldon_d_1/2 (2 por lado), capucha (1) y capa (1). Su movimiento va HORNEADO en todos los clips
#   (los faldones siguen el balanceo de los muslos con retraso; en «canalizar» y «magia_concentrar» se abren con
#   oscilación desfasada; la capa y la capucha responden un poco). Sin física por hueso.
# El mono gris del FBX pasa a negro (guantes incluidos) y el pelo, de casi blanco a gris ceniza, en la textura del cuerpo
# (por texel, según el triángulo al que pertenece: así desaparece también la franja clara del pecho bajo los mechones).
import sys, os, math, json
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
BLEND_IN, TEXDIR, REND, BLEND_OUT, GLB = argv[:5]
SIN_RENDER = "sin_render" in argv
HASTA = ([a.split("=", 1)[1] for a in argv if a.startswith("hasta=")] or ["todo"])[0]
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix, Quaternion
from mathutils.bvhtree import BVHTree
from mathutils.interpolate import poly_3d_calc
import nix_comun as C
import p8_pintura as PT
os.makedirs(TEXDIR, exist_ok=True)
os.makedirs(REND, exist_ok=True)

P = "mixamorig:"
FPS = 30
bpy.ops.wm.open_mainfile(filepath=BLEND_IN)
for o in list(bpy.data.objects):
    if o.type in ('LIGHT', 'CAMERA'):
        bpy.data.objects.remove(o, do_unlink=True)
cuerpo = bpy.data.objects["cuerpo_nix"]
arm = bpy.data.objects["nix_esqueleto"]
if arm.animation_data:
    arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
bpy.context.view_layer.update()
me = cuerpo.data
# Las texturas de 1024 del piloto (el .blend apunta a una carpeta de trabajo que ya no las tiene)
TEX_PILOTO = ([a.split("=", 1)[1] for a in argv if a.startswith("tex_piloto=")]
              or ["D:/REBELUM_diagnostico/v12/expansion/nix/piloto_fbx/texturas_1024"])[0]
for _nm in ("nix_color", "nix_normal", "nix_rugosidad"):
    _im = bpy.data.images[_nm]
    _im.filepath = os.path.join(TEX_PILOTO, _nm + "_1024.png")
    _im.reload()
    assert tuple(_im.size) == (1024, 1024), _nm


def vista(prefijo, centro, escala, vistas=(("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0), ("tres_cuartos", 35, 6)), res=700):
    for nombre, yaw, pitch in vistas:
        C._limpiar(); C.config_render(res, res, 32); C.escena_luz()
        C.camara(centro, yaw, pitch, escala)
        bpy.context.scene.render.filepath = prefijo + "_" + nombre + ".png"
        bpy.ops.render.render(write_still=True)


def smooth(a, b, x):
    t = np.clip((np.asarray(x, np.float64) - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def sm(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def pesos_cuerpo():
    """Matriz densa de pesos del cuerpo (vértices x grupos) y nombres de grupo."""
    nombres = [g.name for g in cuerpo.vertex_groups]
    W = np.zeros((len(me.vertices), len(nombres)), np.float32)
    for v in me.vertices:
        for g in v.groups:
            W[v.index, g.group] = g.weight
    return W, nombres


W, GN = pesos_cuerpo()
GI = {n: i for i, n in enumerate(GN)}
V0 = np.array([v.co[:] for v in me.vertices], np.float32)
w_cabeza = W[:, GI[P + "Head"]]
w_mech = sum(W[:, GI[n]] for n in GN if n.startswith("mechon"))

# ------------------------------------------------------------------ 1. pelo: clasificación por el color horneado
tex = bpy.data.images["nix_color"]
TW, TH = tex.size
px = np.array(tex.pixels[:], np.float32).reshape(TH, TW, 4)
uvl = me.uv_layers.active.data
lo_v = np.zeros(len(me.loops), np.int32); me.loops.foreach_get("vertex_index", lo_v)
lo_uv = np.zeros(len(me.loops) * 2, np.float32); uvl.foreach_get("uv", lo_uv); lo_uv = lo_uv.reshape(-1, 2)
col_v = np.zeros((len(me.vertices), 3), np.float32); n_v = np.zeros(len(me.vertices), np.float32)
ix = np.clip((lo_uv[:, 0] * TW).astype(int), 0, TW - 1); iy = np.clip((lo_uv[:, 1] * TH).astype(int), 0, TH - 1)
np.add.at(col_v, lo_v, px[iy, ix, :3]); np.add.at(n_v, lo_v, 1)
col_v /= np.maximum(n_v, 1)[:, None]
lum_v = col_v.mean(1); sat_v = col_v.max(1) - col_v.min(1)
es_pelo = (lum_v > 0.5) & (sat_v < 0.10) & (V0[:, 2] > 1.53) & (w_cabeza + w_mech > 0.5)
print("PELO vértices", int(es_pelo.sum()))

# ------------------------------------------------------------------ 2. pelo recogido dentro de la capucha
# Elipsoide del pelo recogido (dentro del forro de la capucha con 1,5 cm de holgura). Solo el pelo de los lados y de
# detrás; el de delante de la cara (flequillo y mechones laterales del rostro) apenas se toca.
C_PELO = np.array([0.0, 0.03, 1.72], np.float32)
R_PELO = np.array([0.148, 0.168, 0.172], np.float32)
q = (V0 - C_PELO) / R_PELO
e = np.linalg.norm(q, axis=1)
E0 = 0.80
e_nuevo = np.where(e > E0, E0 + (1 - E0) * np.tanh((e - E0) / (1 - E0)), e)
delante = smooth(-0.035, -0.095, V0[:, 1]) * smooth(0.15, 0.075, np.abs(V0[:, 0]))   # 1 delante de la cara
k_comp = es_pelo & (w_mech < 0.05) & (V0[:, 2] > 1.56)
f = np.where(k_comp, 1.0 - delante * 0.85, 0.0)
escala = 1.0 + (e_nuevo / np.maximum(e, 1e-6) - 1.0) * f
V1 = V0.copy()
V1 = C_PELO + (V0 - C_PELO) * escala[:, None]
mov = np.linalg.norm(V1 - V0, axis=1)
print("RECOGIDO vértices movidos", int((mov > 0.002).sum()), "máximo %.3f m" % mov.max())
# Los mechones delanteros, un poco por delante de la ropa (estaban apoyados en el pecho): la raíz no se mueve.
w12 = w_mech * (V0[:, 2] < 1.80)
V1[:, 1] -= 0.020 * np.clip(w12, 0, 1) * smooth(1.62, 1.50, V0[:, 2])
for v in me.vertices:
    v.co = Vector(V1[v.index].tolist())
me.update()
V0 = V1.astype(np.float32)

# ------------------------------------------------------------------ 3. textura del cuerpo: mono negro y pelo ceniza
me.calc_loop_triangles()
NT = len(me.loop_triangles)
lt_loops = np.zeros(NT * 3, np.int32); me.loop_triangles.foreach_get("loops", lt_loops); lt_loops = lt_loops.reshape(-1, 3)
lt_vert = lo_v[lt_loops]
tri_map, bary_map = PT.rasterizar(lo_uv[lt_loops] * np.array([TW, TH], np.float32), TW)
occ = tri_map >= 0
dat = np.stack([w_cabeza + w_mech, w_mech, V0[:, 2]], -1)
tv = PT.interpolar(tri_map, bary_map, lt_vert, dat)
clase = np.zeros((TH, TW), np.int8)            # 0 sin tocar, 1 mono -> negro, 2 pelo -> ceniza
c = px[occ][:, :3]
lum = c.mean(1); sat = c.max(1) - c.min(1)
mech_t = tv[:, 1] > 0.1
cab = ((tv[:, 0] > 0.5) & (tv[:, 2] > 1.545)) | mech_t
piel = (c[:, 0] - c[:, 2] > 0.035) & (lum > 0.33)
ojo = (c[:, 2] - c[:, 1] > 0.08)
# pelo: gris poco saturado y no cálido (la piel pálida también es poco saturada, pero rojiza)
pelo_c = (sat < 0.12) & ~piel & ~ojo & ((lum > 0.5) | (tv[:, 2] > 1.62) | mech_t)
cl = np.zeros(len(c), np.int8)
cl[~cab & ~piel & ~ojo] = 1
cl[cab & pelo_c] = 2
# el cuello alto del mono (pesos de la cabeza, por debajo de la barbilla): negro
cl[cab & ~mech_t & ~pelo_c & ~piel & ~ojo & (sat < 0.09) & (lum < 0.5) & (tv[:, 2] < 1.62)] = 1
clase[occ] = cl
uno = np.eye(3, dtype=np.float32)[clase]                     # en los márgenes, la clase vecina más frecuente
clase = np.where(occ, clase, np.argmax(PT.dilatar(uno, occ, 6), -1)).astype(np.int8)
nuevo = px.copy()
m1 = clase == 1
l1 = px[..., :3].mean(-1)
NEGRO_MONO = np.array([0.072, 0.060, 0.082], np.float32)
nuevo[m1, :3] = NEGRO_MONO * np.clip((l1[m1] / 0.45) ** 0.9, 0.35, 1.8)[:, None]
m2 = clase == 2
CENIZA = np.array([0.70, 0.715, 0.755], np.float32)
nuevo[m2, :3] = px[m2, :3] * CENIZA
print("TEXTURA cuerpo: mono", int(m1.sum()), "pelo", int(m2.sum()), "texeles")
tex.pixels.foreach_set(nuevo.ravel())
tex.filepath_raw = os.path.join(TEXDIR, "nix_color_%d.png" % TW)
tex.file_format = 'PNG'
tex.save()
# rugosidad del mono: tela mate (el mapa del FBX la dejaba en 0,5-0,6 y brillaba como látex con luz de frente)
rug = bpy.data.images["nix_rugosidad"]
rp = np.array(rug.pixels[:], np.float32).reshape(TH, TW, 4)
rp[m1, :3] = np.maximum(rp[m1, :3], 0.80)
rug.pixels.foreach_set(rp.ravel())
rug.filepath_raw = os.path.join(TEXDIR, "nix_rugosidad_%d.png" % TW)
rug.file_format = 'PNG'
rug.save()
for nm in ("nix_normal",):
    im = bpy.data.images[nm]
    im.filepath_raw = os.path.join(TEXDIR, "%s_%d.png" % (nm, TW))
    im.file_format = 'PNG'
    im.save()

if HASTA == "cuerpo":
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
    if not SIN_RENDER:
        C.render_vistas(os.path.join(REND, "cuerpo"), 1.9, cara=Vector((0, -0.148, 1.728)))
        vista(os.path.join(REND, "cuerpo_cabeza"), Vector((0, 0, 1.70)), 0.62)
    print("FIN cuerpo")
    sys.exit(0)

# ------------------------------------------------------------------ 4. huesos nuevos
HUESOS = {
    # nombre: (cabeza, cola, padre)
    "faldon_i_1": ((0.095, -0.005, 1.03), (0.15, 0.02, 0.60), P + "Hips"),
    "faldon_i_2": ((0.15, 0.02, 0.60), (0.20, 0.05, 0.18), "faldon_i_1"),
    "faldon_d_1": ((-0.095, -0.005, 1.03), (-0.15, 0.02, 0.60), P + "Hips"),
    "faldon_d_2": ((-0.15, 0.02, 0.60), (-0.20, 0.05, 0.18), "faldon_d_1"),
    "capucha": ((0.0, 0.10, 1.76), (0.0, 0.14, 1.98), P + "Head"),
    "capa": ((0.0, 0.06, 1.50), (0.0, 0.13, 1.36), P + "Spine2"),
}
bpy.context.view_layer.objects.active = arm
for o in bpy.context.selected_objects:
    o.select_set(False)
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb = arm.data.edit_bones
mwi = arm.matrix_world.inverted()
for n, (h, t, padre) in HUESOS.items():
    b = eb.new(n)
    b.head = mwi @ Vector(h); b.tail = mwi @ Vector(t)
    b.parent = eb[padre]
    b.use_connect = False
    b.align_roll(mwi.to_3x3() @ Vector((0, -1, 0)))
    b.use_deform = True
bpy.ops.object.mode_set(mode='OBJECT')
print("HUESOS total", len(arm.data.bones), "deforman", sum(1 for b in arm.data.bones if b.use_deform))

# ------------------------------------------------------------------ 5. piezas
# Identificadores de pieza (atributo de cara «pieza»): las únicas tienen su sitio en el atlas; forro, oro y cuero van a
# muestras pequeñas del atlas (color liso).
ID = {"cuerpo": 1, "mangas": 2, "media_i": 3, "media_d": 4, "botas": 5, "capa": 6, "capucha": 8, "faldon_i": 11,
      "faldon_d": 12, "peplo": 14, "tabardo": 17, "bolsas": 20,
      "forro": 90, "oro": 91, "cuero": 92}
piezas = []                                  # objetos creados


def nuevo_obj(nombre, bm):
    m = bpy.data.meshes.new(nombre)
    bm.to_mesh(m); bm.free()
    o = bpy.data.objects.new(nombre, m)
    bpy.context.scene.collection.objects.link(o)
    piezas.append(o)
    return o


# --- 5a. ceñidas: copias desplazadas de caras del cuerpo (con sus pesos). Los bordes que se ven se cortan con planos
# (bisect) para que queden rectos y limpios, no en dientes de sierra siguiendo los triángulos.
vn = np.array([v.normal[:] for v in me.vertices], np.float32)
GI_HEAD = GI[P + "Head"]
GI_MECH = [GI[n] for n in GN if n.startswith("mechon")]
EJE_X, EJE_Z = Vector((1, 0, 0)), Vector((0, 0, 1))


def cenida(nombre, filtro, desplazar, pieza, extra=None, cortes=()):
    o = cuerpo.copy(); o.data = cuerpo.data.copy(); o.name = nombre; o.data.name = nombre
    o.modifiers.clear()
    o.parent = None
    bpy.context.scene.collection.objects.link(o)
    bm = bmesh.new(); bm.from_mesh(o.data)
    bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
    for v in bm.verts:
        d = desplazar(V0[v.index], vn[v.index]) if callable(desplazar) else desplazar
        v.co = v.co + Vector(vn[v.index].tolist()) * d
    for co, no in cortes:
        bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=Vector(co), plane_no=no,
                               dist=1e-5)
    dl = bm.verts.layers.deform.active
    quitar = []
    for f in bm.faces:
        c = f.calc_center_median()
        cab = max(v[dl].get(GI_HEAD, 0.0) for v in f.verts)
        mech = max(sum(v[dl].get(g, 0.0) for g in GI_MECH) for v in f.verts)
        if not filtro(c, f.normal, cab, mech):
            quitar.append(f)
    bmesh.ops.delete(bm, geom=quitar, context='FACES')
    lay = bm.faces.layers.int.new("pieza")
    for f in bm.faces:
        f[lay] = pieza(f) if callable(pieza) else pieza
    bm.normal_update()
    if extra:
        extra(bm)
    bm.to_mesh(o.data); bm.free()
    while o.data.uv_layers:
        o.data.uv_layers.remove(o.data.uv_layers[0])
    o.data.materials.clear()
    piezas.append(o)
    print("PIEZA", nombre, sum(len(p.vertices) - 2 for p in o.data.polygons), "triángulos")
    return o


def es_cuerpo(c, n, cab, mech):
    return 0.935 < c.z < 1.548 and abs(c.x) < 0.195 and cab < 0.5 and mech < 0.01


def es_manga(c, n, cab, mech):
    return c.z > 1.36 and 0.185 < abs(c.x) < 0.632 and mech < 0.01


def es_media(c, n, cab, mech):
    return 0.20 < c.z < 0.99 and mech < 0.01 and not (c.z > 0.935 and abs(c.x) < 0.06 and c.y > 0.0)


def es_bota(c, n, cab, mech):
    return c.z < 0.275


cenida("ropa_cuerpo", es_cuerpo, 0.0065, ID["cuerpo"], cortes=[((0, 0, 1.548), EJE_Z)])
cenida("ropa_mangas", es_manga, 0.004, ID["mangas"],
       cortes=[((0.632, 0, 0), EJE_X), ((-0.632, 0, 0), EJE_X), ((0.185, 0, 0), EJE_X), ((-0.185, 0, 0), EJE_X)])
cenida("ropa_medias", es_media, 0.0035, lambda f: ID["media_i"] if f.calc_center_median().x > 0 else ID["media_d"])
cenida("ropa_botas", es_bota, lambda p, n: 0.0085 + 0.010 * sm(0.20, 0.275, p[2]) + 0.002 * (p[2] < 0.02), ID["botas"],
       cortes=[((0, 0, 0.275), EJE_Z)])


# --- 5b. capa corta: copia desplazada de hombros, parte alta de la espalda, los lados del pecho y el brazo hasta medio
# bíceps (todo alrededor), cortada con planos (abajo z 1,40; brazo |x| 0,33; delante |x| 0,125; cuello z 1,53), con un
# vuelo en el borde de abajo y en el del brazo, y forro púrpura en el vuelo.
Z_CAPA, X_CAPA, X_PECHO, Z_CUELLO = 1.40, 0.33, 0.125, 1.53


def es_capa(c, n, cab, mech):
    if cab > 0.5 or mech > 0.01 or c.z > Z_CUELLO or abs(c.x) > X_CAPA or c.z < Z_CAPA:
        return False
    if abs(c.x) >= 0.175:
        return True
    return c.y > 0.0 or abs(c.x) > X_PECHO


def extra_capa(bm):
    lay_p = bm.faces.layers.int["pieza"]
    dl = bm.verts.layers.deform.active
    bordes = [e for e in bm.edges if e.is_boundary]
    vs = set()
    for e in bordes:
        for v in e.verts:
            if abs(v.co.z - Z_CAPA) < 0.004 or abs(abs(v.co.x) - X_CAPA) < 0.004:
                vs.add(v)
    nuevos = {}
    for v in vs:
        n = v.normal
        if abs(abs(v.co.x) - X_CAPA) < 0.004:       # puño de la capa en el brazo: hacia fuera del brazo
            rad = Vector((0, v.co.y, v.co.z - 1.463))
            rad = rad.normalized() if rad.length > 1e-4 else n
            d = rad * 0.026 + Vector((math.copysign(0.016, v.co.x), 0, 0))
        else:                                        # borde de abajo: hacia fuera y abajo
            nh = Vector((n.x, n.y, 0))
            d = (nh.normalized() * 0.020 if nh.length > 1e-4 else Vector()) + Vector((0, 0, -0.045))
        nv = bm.verts.new(v.co + d)
        for g, w in v[dl].items():
            nv[dl][g] = w
        nuevos[v] = nv
    vuelo = []
    for e in bordes:
        a, b = e.verts
        if a in nuevos and b in nuevos:
            f = bm.faces.new((a, b, nuevos[b], nuevos[a]))
            f[lay_p] = ID["capa"]
            f.normal_update()
            if f.normal.dot(e.link_faces[0].normal if e.link_faces else f.normal) < 0:
                f.normal_flip()
            vuelo.append(f)
    bm.normal_update()
    copia = bmesh.ops.duplicate(bm, geom=vuelo)
    caras_c = [g for g in copia["geom"] if isinstance(g, bmesh.types.BMFace)]
    for f in caras_c:
        f.normal_flip()
        f[lay_p] = ID["forro"]
    bm.normal_update()
    for v in {v for f in caras_c for v in f.verts}:
        v.co = v.co + v.normal * 0.004            # (normal ya invertida: hacia dentro, detrás del vuelo)


capa = cenida("ropa_capa", es_capa, lambda p, n: 0.016 + 0.004 * sm(0.20, 0.30, abs(p[0])), ID["capa"], extra_capa,
              cortes=[((0, 0, Z_CAPA), EJE_Z), ((0, 0, Z_CUELLO), EJE_Z), ((X_CAPA, 0, 0), EJE_X),
                      ((-X_CAPA, 0, 0), EJE_X), ((X_PECHO, 0, 0), EJE_X), ((-X_PECHO, 0, 0), EJE_X)])


# --- 5c. piezas construidas (rejillas de dos capas con ribete: superficies cerradas)
def anillo(z, rx, ry, cy, phi, M, cx=0.0):
    """Anillo horizontal abierto por delante: θ de phi a 360-phi (θ = 0 delante, -Y; 90 a la izquierda, +X)."""
    out = []
    for j in range(M + 1):
        th = math.radians(phi + (360.0 - 2 * phi) * j / M)
        out.append(Vector((cx + rx * math.sin(th), cy - ry * math.cos(th), z)))
    return out


def catmull(filas, n):
    """Interpola una lista de tuplas (z, ...) a n filas (Catmull-Rom uniforme)."""
    A = np.array(filas, np.float64)
    res = []
    for i in range(n):
        s = i / (n - 1) * (len(A) - 1)
        k = min(int(s), len(A) - 2)
        u = s - k
        p0 = A[max(k - 1, 0)]; p1 = A[k]; p2 = A[k + 1]; p3 = A[min(k + 2, len(A) - 1)]
        r = 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3)
        res.append(r)
    return res


# Objetivo de colisión en reposo: el cuerpo (sin cabeza ni pelo) y las piezas ya hechas (solo sus caras exteriores).
# Las piezas construidas se empujan hacia fuera de él con un margen (como un «shrinkwrap» por fuera), con el MISMO
# desplazamiento para la capa exterior y el forro (así no se cruzan) y suavizado por la rejilla.
BVH = None


def objetivo(objs):
    global BVH
    vs, ps = [], []
    for v in V0:
        vs.append(Vector(v.tolist()))
    for pol in me.polygons:
        if max(w_cabeza[list(pol.vertices)]) < 0.5 and max(w_mech[list(pol.vertices)]) < 0.01:
            ps.append(list(pol.vertices))
    for o in objs:
        base = len(vs)
        vs.extend(v.co.copy() for v in o.data.vertices)
        lay = o.data.attributes.get("pieza")
        for pol in o.data.polygons:
            if lay is None or lay.data[pol.index].value not in (ID["forro"],):
                ps.append([base + i for i in pol.vertices])
    BVH = BVHTree.FromPolygons(vs, ps)


def empujar(p, margen=0.004):
    loc, n, idx, d = BVH.find_nearest(p, 0.06)
    if loc is None:
        return Vector()
    s = (p - loc).dot(n)
    if s < margen:
        return n * min(margen - s, 0.04)
    return Vector()


def empujar_rejillas(ext, inte, margen=0.004):
    nf, nc = len(ext), len(ext[0])
    D = np.zeros((nf, nc, 3))
    for i in range(nf):
        for j in range(nc):
            a = empujar(inte[i][j], margen); b = empujar(ext[i][j], margen + 0.002)
            D[i, j] = (a if a.length > b.length else b)[:]
    Ds = D.copy()
    for _ in range(2):
        P = np.pad(Ds, ((1, 1), (1, 1), (0, 0)), mode='edge')
        Ds = (P[1:-1, 1:-1] * 2 + P[:-2, 1:-1] + P[2:, 1:-1] + P[1:-1, :-2] + P[1:-1, 2:]) / 6
    F = np.where(np.linalg.norm(D, axis=2, keepdims=True) > np.linalg.norm(Ds, axis=2, keepdims=True), D, Ds)
    n = int((np.linalg.norm(D, axis=2) > 1e-5).sum())
    for i in range(nf):
        for j in range(nc):
            dv = Vector(F[i, j].tolist())
            ext[i][j] = ext[i][j] + dv
            inte[i][j] = inte[i][j] + dv
    print("EMPUJE puntos", n, "máximo %.3f m" % float(np.linalg.norm(D, axis=2).max()))
    return ext, inte


def doble_capa(bm, ext, inte, lay_p, id_ext, lay_par, par, cerrar=("abajo", "arriba", "izq", "der"), sin_borde_filas=()):
    """Dos rejillas (filas x columnas de Vector) emparejadas -> caras exterior, interior (invertida) y ribetes en los
    bordes. Devuelve las matrices de BMVerts."""
    if BVH is not None:
        ext, inte = empujar_rejillas(ext, inte)
    def rejilla(G, inv, pid, pr):
        V = [[bm.verts.new(p) for p in fila] for fila in G]
        for i in range(len(G)):
            for j in range(len(G[0])):
                V[i][j][lay_par] = pr(i, j)
        for i in range(len(G) - 1):
            for j in range(len(G[0]) - 1):
                q = (V[i][j], V[i][j + 1], V[i + 1][j + 1], V[i + 1][j])
                f = bm.faces.new(q[::-1] if inv else q)
                f[lay_p] = pid
        return V
    A = rejilla(ext, False, id_ext, par)
    B = rejilla(inte, True, ID["forro"], par)
    nf, nc = len(ext), len(ext[0])

    def tira(a, b):
        for k in range(len(a) - 1):
            if a[k] is a[k + 1] and b[k] is b[k + 1]:
                continue
            try:
                f = bm.faces.new((a[k], a[k + 1], b[k + 1], b[k]))
                f[lay_p] = ID["oro"]
            except ValueError:
                pass
    if "abajo" in cerrar:
        tira(A[0], B[0])
    if "arriba" in cerrar:
        tira(A[-1], B[-1])
    if "izq" in cerrar:
        tira([A[i][0] for i in range(nf) if i not in sin_borde_filas], [B[i][0] for i in range(nf) if i not in sin_borde_filas])
    if "der" in cerrar:
        tira([A[i][-1] for i in range(nf) if i not in sin_borde_filas], [B[i][-1] for i in range(nf) if i not in sin_borde_filas])
    return A, B


# Capucha: filas (z, rx, ry, cy, phi) del exterior. phi: medio ángulo de la abertura de la cara (0 = cerrada).
FILAS_CAPUCHA = [
    (1.505, 0.150, 0.150, 0.025, 30.0),
    (1.560, 0.160, 0.170, 0.030, 44.0),
    (1.620, 0.172, 0.188, 0.034, 53.0),
    (1.700, 0.178, 0.199, 0.036, 57.0),
    (1.775, 0.175, 0.199, 0.040, 55.0),
    (1.840, 0.158, 0.186, 0.046, 48.0),
    (1.892, 0.126, 0.160, 0.056, 34.0),
    (1.930, 0.082, 0.114, 0.070, 10.0),
    (1.958, 0.038, 0.060, 0.088, 0.0),
    (1.975, 0.0, 0.0, 0.106, 0.0),
]
GROSOR_CAPUCHA = 0.012


def capucha_obj():
    bm = bmesh.new()
    lay_p = bm.faces.layers.int.new("pieza")
    lay_par = bm.verts.layers.float_vector.new("param")
    filas = catmull(FILAS_CAPUCHA, 15)
    M = 22
    ext, inte = [], []
    for z, rx, ry, cy, phi in filas:
        phi = max(0.0, phi if phi > 1.0 else 0.0)
        ext.append(anillo(z, max(rx, 0.0), max(ry, 0.0), cy, phi, M))
        g = GROSOR_CAPUCHA
        inte.append(anillo(z - (g if z > 1.95 else 0.0), max(rx - g, 0.0), max(ry - g, 0.0), cy, phi, M))
    abiertas = [i for i, f in enumerate(filas) if f[4] > 1.0]
    cerradas = [i for i in range(len(filas)) if i not in abiertas]
    A, B = doble_capa(bm, ext, inte, lay_p, ID["capucha"], lay_par,
                      lambda i, j: Vector((j / M, i / (len(filas) - 1), filas[i][4])),
                      cerrar=("abajo", "izq", "der"), sin_borde_filas=cerradas[1:])
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges[:], dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    # normales hacia fuera: el exterior debe mirar lejos del centro de la cabeza
    cen = Vector((0, 0.03, 1.72))
    ext_f = [f for f in bm.faces if f[lay_p] == ID["capucha"]]
    if sum(f.normal.dot(f.calc_center_median() - cen) for f in ext_f) < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    o = nuevo_obj("ropa_capucha", bm)
    return o


CENIDAS = [o for o in piezas]
objetivo(CENIDAS)
capucha = capucha_obj()


def faldon_obj(lado):
    """Faldón largo de un lado (lado 1 izquierda +X, -1 derecha): de la cintura al tobillo, abierto por delante."""
    bm = bmesh.new()
    lay_p = bm.faces.layers.int.new("pieza")
    lay_par = bm.verts.layers.float_vector.new("param")
    NR, NC = 13, 10
    T0, T1 = 48.0, 174.0
    ext, inte = [], []
    for i in range(NR + 1):
        t = i / NR
        fe, fi = [], []
        for j in range(NC + 1):
            u = j / NC
            th = math.radians(T0 + (T1 - T0) * u)
            # bajo: más largo en la esquina de fuera (u≈0,32), más corto hacia la espalda
            if u < 0.32:
                zb = 0.215 - 0.065 * (u / 0.32)
            else:
                zb = 0.15 + 0.20 * ((u - 0.32) / 0.68) ** 1.3
            z = 1.04 + (zb - 1.04) * t
            s = t ** 0.85
            rx = 0.212 + (0.300 - 0.212) * s
            ry = 0.142 + (0.255 - 0.142) * s
            cy = 0.004 + 0.03 * s
            p = Vector((lado * rx * math.sin(th), cy - ry * math.cos(th), z))
            fe.append(p)
            ctr = Vector((0, cy, z))
            fi.append(ctr + (p - ctr) * (1.0 - 0.0065 / max(rx, ry)))
        ext.append(fe); inte.append(fi)
    # filas de arriba a abajo; columnas de delante a atrás
    A, B = doble_capa(bm, ext, inte, lay_p, ID["faldon_i" if lado > 0 else "faldon_d"], lay_par,
                      lambda i, j: Vector((j / NC, i / NR, lado)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    ext_f = [f for f in bm.faces if f[lay_p] in (ID["faldon_i"], ID["faldon_d"])]
    if sum(f.normal.dot(Vector((f.calc_center_median().x, f.calc_center_median().y, 0))) for f in ext_f) < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    # colgante dorado en la esquina de fuera del bajo
    jc = round(0.32 * NC)
    base = A[NR][jc].co.copy()
    out = Vector((base.x, base.y - 0.02, 0)).normalized()
    pts = [base + Vector((0, 0, -0.005)), base + Vector((0, 0, -0.030)) + out * 0.004, base + Vector((0, 0, -0.058))]
    r = 0.008
    anillo_c = [pts[1] + Vector((r * math.cos(a), r * math.sin(a), 0)) for a in np.linspace(0, 2 * math.pi, 5)[:-1]]
    va = bm.verts.new(pts[0]); vb = bm.verts.new(pts[2]); vr = [bm.verts.new(p) for p in anillo_c]
    for k in range(4):
        f1 = bm.faces.new((va, vr[k], vr[(k + 1) % 4])); f1[lay_p] = ID["oro"]
        f2 = bm.faces.new((vb, vr[(k + 1) % 4], vr[k])); f2[lay_p] = ID["oro"]
    for v in [va, vb] + vr:
        v[lay_par] = Vector((0.32, 1.0, lado))
    bm.normal_update()
    o = nuevo_obj("ropa_faldon_" + ("i" if lado > 0 else "d"), bm)
    return o


faldones = [faldon_obj(1), faldon_obj(-1)]


def peplo_obj():
    """Faldón corto alrededor de la cadera, abierto por delante."""
    bm = bmesh.new()
    lay_p = bm.faces.layers.int.new("pieza")
    lay_par = bm.verts.layers.float_vector.new("param")
    NR, NC = 4, 22
    ext, inte = [], []
    for i in range(NR + 1):
        t = i / NR
        fe, fi = [], []
        for j in range(NC + 1):
            u = j / NC
            th = math.radians(24 + 312 * u)
            zb = 0.875 - 0.02 * math.sin(math.pi * u)
            z = 1.045 + (zb - 1.045) * t
            rx = 0.206 + 0.034 * t ** 1.3
            ry = 0.140 + 0.044 * t ** 1.3
            p = Vector((rx * math.sin(th), 0.004 - ry * math.cos(th), z))
            fe.append(p)
            ctr = Vector((0, 0.004, z))
            fi.append(ctr + (p - ctr) * (1.0 - 0.005 / max(rx, ry)))
        ext.append(fe); inte.append(fi)
    doble_capa(bm, ext, inte, lay_p, ID["peplo"], lay_par, lambda i, j: Vector((j / NC, i / NR, 0)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    ext_f = [f for f in bm.faces if f[lay_p] == ID["peplo"]]
    if sum(f.normal.dot(Vector((f.calc_center_median().x, f.calc_center_median().y, 0))) for f in ext_f) < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    return nuevo_obj("ropa_peplo", bm)


objetivo(CENIDAS + faldones)
peplo = peplo_obj()
print("PIEZAS construidas", [(o.name, sum(len(p.vertices) - 2 for p in o.data.polygons)) for o in (capucha, peplo) + tuple(faldones)])

if HASTA == "piezas":
    for o in piezas:
        o.data.shade_smooth()
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
    if not SIN_RENDER:
        C.render_vistas(os.path.join(REND, "piezas"), 1.9, vistas=[("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0), ("tres_cuartos", 35, 6)])
        vista(os.path.join(REND, "piezas_cabeza"), Vector((0, 0, 1.70)), 0.62)
    print("FIN piezas")
    sys.exit(0)


# --- 5d. tabardo delantero (punta bajo el cinturón) y bolsas del cinturón
def tabardo_obj():
    bm = bmesh.new()
    lay_p = bm.faces.layers.int.new("pieza")
    lay_par = bm.verts.layers.float_vector.new("param")
    NR, NC = 6, 6
    ext, inte = [], []
    for i in range(NR + 1):
        t = i / NR
        z = 1.045 + (0.845 - 1.045) * t
        half = 0.078 * (1.0 - t ** 1.6) + 0.0005
        fe, fi = [], []
        # cuelga plano delante de lo que haya (cuerpo, medias y corpiño): el punto más adelantado de la fila (rayos de
        # -Y hacia +Y que no pasen de y = 0: entre los muslos el rayo llegaba a la espalda de los faldones)
        ys = []
        for j in range(NC + 1):
            x = -max(half, 0.03) + 2 * max(half, 0.03) * j / NC
            hit, nrm, idx, d = BVH.ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)), 0.6)
            if hit is not None:
                ys.append(hit.y)
        y = (min(ys) if ys else -0.10) - 0.010
        for j in range(NC + 1):
            x = -half + 2 * half * j / NC
            fe.append(Vector((x, y, z)))
            fi.append(Vector((x, y + 0.004, z)))
        ext.append(fe); inte.append(fi)
    doble_capa(bm, ext, inte, lay_p, ID["tabardo"], lay_par, lambda i, j: Vector((j / NC, i / NR, 0)))
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.normal_update()
    ext_f = [f for f in bm.faces if f[lay_p] == ID["tabardo"]]
    if sum(f.normal.y for f in ext_f) > 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
    return nuevo_obj("ropa_tabardo", bm)


def bolsas_obj():
    bm = bmesh.new()
    lay_p = bm.faces.layers.int.new("pieza")
    lay_par = bm.verts.layers.float_vector.new("param")
    for lado in (1, -1):
        th = math.radians(62)
        cen = Vector((lado * 0.215 * math.sin(th), 0.004 - 0.150 * math.cos(th), 0.985))
        fuera = Vector((cen.x, cen.y - 0.004, 0)).normalized()
        lado_v = Vector((0, 0, 1)).cross(fuera).normalized()
        hit, nrm, idx, d = BVH.ray_cast(cen + fuera * 0.3, -fuera, 1.0)
        base = (hit if hit is not None else cen) + fuera * 0.001       # apoyada en el peplo
        a, b, h = 0.030, 0.015, 0.046
        c = base + fuera * b + Vector((0, 0, -0.012))
        r = bmesh.ops.create_cube(bm, size=1.0)
        vs = r["verts"]
        for v in vs:
            p = v.co.copy()
            v.co = c + lado_v * (p.x * 2 * a) + fuera * (p.y * 2 * b) + Vector((0, 0, p.z * h))
        for f in {f for v in vs for f in v.link_faces}:
            f[lay_p] = ID["bolsas"]
        for v in vs:
            v[lay_par] = Vector((0, 0, lado))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    return nuevo_obj("ropa_bolsas", bm)


objetivo(CENIDAS + faldones + [peplo])
tabardo = tabardo_obj()
bolsas = bolsas_obj()

# ------------------------------------------------------------------ 6. pesos de las piezas construidas
POL_CUERPO = [list(p.vertices) for p in me.polygons
              if max(w_cabeza[list(p.vertices)]) < 0.5 and max(w_mech[list(p.vertices)]) < 0.01]
BVH_CUERPO = BVHTree.FromPolygons([Vector(v.tolist()) for v in V0], POL_CUERPO)


def pesos_cercanos(p):
    loc, n, idx, d = BVH_CUERPO.find_nearest(p)
    vs = POL_CUERPO[idx]
    ws = poly_3d_calc([Vector(V0[i].tolist()) for i in vs], loc)
    acc = np.zeros(len(GN), np.float32)
    for i, w in zip(vs, ws):
        acc += W[i] * w
    return {GN[k]: float(acc[k]) for k in np.nonzero(acc > 1e-4)[0]}


def poner_pesos(o, f):
    """f(i, v, param) -> dict hueso: peso; se dejan los 4 mayores, normalizados."""
    o.vertex_groups.clear()
    grupos = {}
    par = o.data.attributes.get("param")
    for v in o.data.vertices:
        pr = Vector(par.data[v.index].vector) if par is not None else Vector()
        d = f(v.index, v.co.copy(), pr)
        top = sorted(d.items(), key=lambda kv: -kv[1])[:4]
        s = sum(w for _, w in top)
        for n, w in top:
            if w / s < 1e-3:
                continue
            if n not in grupos:
                grupos[n] = o.vertex_groups.new(name=n)
            grupos[n].add([v.index], w / s, 'REPLACE')


def mezclar(a, b, t):
    r = {k: w * (1 - t) for k, w in a.items()}
    for k, w in b.items():
        r[k] = r.get(k, 0.0) + w * t
    return r


def w_capucha(i, p, pr):
    wh = sm(1.53, 1.66, p.z)
    wn = (1 - wh) * sm(1.47, 1.56, p.z)
    d = {P + "Head": wh, P + "Neck": wn, P + "Spine2": max(0.0, 1 - wh - wn)}
    wc = 0.55 * sm(1.80, 1.96, p.z) * sm(0.0, 0.10, p.y)
    if wc > 0:
        d = mezclar(d, {"capucha": 1.0}, wc)
    return d


def w_faldon(lado):
    s = "i" if lado > 0 else "d"

    def f(i, p, pr):
        t = pr.y
        wh = 1 - sm(0.0, 0.30, t)
        w2 = sm(0.45, 0.90, t)
        w1 = max(0.0, 1 - wh - w2)
        d = {k: w * wh for k, w in pesos_cercanos(p).items()} if wh > 1e-3 else {}
        d["faldon_%s_1" % s] = d.get("faldon_%s_1" % s, 0) + w1
        d["faldon_%s_2" % s] = d.get("faldon_%s_2" % s, 0) + w2
        return d
    return f


poner_pesos(capucha, w_capucha)
for o, lado in zip(faldones, (1, -1)):
    poner_pesos(o, w_faldon(lado))
for o in (peplo, tabardo, bolsas):
    poner_pesos(o, lambda i, p, pr: pesos_cercanos(p))


def w_capa_extra(o):
    """La espalda de la capa corta responde también al hueso «capa» (vuelo en la canalización y al correr)."""
    g = o.vertex_groups.get("capa") or o.vertex_groups.new(name="capa")
    for v in o.data.vertices:
        p = v.co
        wc = 0.6 * sm(1.47, 1.37, p.z) * sm(0.0, 0.05, p.y) * (1.0 - sm(0.15, 0.20, abs(p.x)))
        if wc < 1e-3:
            continue
        for ge in v.groups:
            ge.weight *= (1 - wc)
        g.add([v.index], wc, 'ADD')


w_capa_extra(capa)

# ------------------------------------------------------------------ 7. una sola malla «ropa_nix»
for o in bpy.context.selected_objects:
    o.select_set(False)
for o in piezas:
    o.select_set(True)
bpy.context.view_layer.objects.active = piezas[0]
bpy.ops.object.join()
ropa = bpy.context.view_layer.objects.active
ropa.name = "ropa_nix"; ropa.data.name = "ropa_nix"
mr = ropa.data
mr.shade_smooth()
try:
    mr.set_sharp_from_angle(angle=math.radians(55))
except Exception as ex:
    print("AVISO sharp", ex)
bpy.context.view_layer.objects.active = ropa
bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
bpy.ops.object.vertex_group_normalize_all(group_select_mode='ALL', lock_active=False)
bpy.ops.object.mode_set(mode='OBJECT')
sin = [v.index for v in mr.vertices if not any(g.weight > 0 for g in v.groups)]
print("ROPA vértices", len(mr.vertices), "triángulos", sum(len(p.vertices) - 2 for p in mr.polygons), "sin peso", len(sin))
huesos = {b.name for b in arm.data.bones}
for g in list(ropa.vertex_groups):
    assert g.name in huesos, g.name
ropa.parent = arm
ropa.matrix_parent_inverse = arm.matrix_world.inverted()
mod = ropa.modifiers.new("Armature", 'ARMATURE'); mod.object = arm

# ------------------------------------------------------------------ 8. UV: islas únicas + muestras (forro, oro, cuero)
LAY = mr.attributes["pieza"]
piez = np.zeros(len(mr.polygons), np.int32); LAY.data.foreach_get("value", piez)
MUESTRAS = {ID["forro"]: (0.022, 0.020), ID["oro"]: (0.060, 0.020), ID["cuero"]: (0.098, 0.020)}
unica = ~np.isin(piez, list(MUESTRAS))
mr.uv_layers.new(name="UVMap")
# solo las caras únicas (si no, los forros ocupaban medio atlas)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_mode(type='FACE')
bme = bmesh.from_edit_mesh(mr)
bme.faces.ensure_lookup_table()
for f in bme.faces:
    f.select_set(False)
for f in bme.faces:
    if unica[f.index]:
        f.select_set(True)
bmesh.update_edit_mesh(mr)
print("UV caras seleccionadas", sum(1 for f in bme.faces if f.select))
bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, area_weight=0.0, correct_aspect=True,
                         scale_to_bounds=False)
if "con_pack" in argv:            # (probado el 14/11: en segundo plano deja las islas degeneradas)
    bpy.ops.uv.select_all(action='SELECT')
    try:
        bpy.ops.uv.pack_islands(udim_source='CLOSEST_UDIM', rotate=True, margin=0.003, shape_method='CONCAVE')
    except Exception as ex:
        print("AVISO pack", ex)
bpy.ops.object.mode_set(mode='OBJECT')
V_MUESTRAS = 0.04
uvd = mr.uv_layers["UVMap"].data
# las islas únicas, ajustadas a [0,1] con la misma escala en u y v (el empaquetado puede dejarlas en otra casilla)
lu = np.array([uvd[li].uv[:] for p in mr.polygons if unica[p.index] for li in p.loop_indices], np.float32)
lo, hi = lu.min(0), lu.max(0)
esc = 1.0 / float(max(hi - lo))
print("UV caja antes de ajustar", lo.round(3), hi.round(3), "escala %.3f" % esc)
for p in mr.polygons:
    if unica[p.index]:
        for li in p.loop_indices:
            u, v = uvd[li].uv
            uvd[li].uv = ((u - lo[0]) * esc, (v - lo[1]) * esc)
for p in mr.polygons:
    for li in p.loop_indices:
        u, v = uvd[li].uv
        if unica[p.index]:
            uvd[li].uv = (u, V_MUESTRAS + v * (1 - V_MUESTRAS))
        else:
            c = MUESTRAS[int(piez[p.index])]
            co = mr.vertices[mr.loops[li].vertex_index].co
            uvd[li].uv = (c[0] + 0.010 * math.sin(co.x * 7 + co.z * 3), c[1] + 0.010 * math.sin(co.y * 5 + co.z * 9))
print("UV islas únicas", int(unica.sum()), "caras; muestras", int((~unica).sum()))

# ------------------------------------------------------------------ 9. textura de la ropa (pintada por posición)
S2 = 2048
S = 1024
mr.calc_loop_triangles()
NT2 = len(mr.loop_triangles)
lt2 = np.zeros(NT2 * 3, np.int32); mr.loop_triangles.foreach_get("loops", lt2); lt2 = lt2.reshape(-1, 3)
ltp = np.zeros(NT2, np.int32); mr.loop_triangles.foreach_get("polygon_index", ltp)
lv2 = np.zeros(len(mr.loops), np.int32); mr.loops.foreach_get("vertex_index", lv2)
luv2 = np.zeros(len(mr.loops) * 2, np.float32); uvd.foreach_get("uv", luv2); luv2 = luv2.reshape(-1, 2)
sel = unica[ltp]
tri_u = lt2[sel]
tmap, bmap = PT.rasterizar(luv2[tri_u] * S2, S2)
occ2 = tmap >= 0
pos_v = np.array([v.co[:] for v in mr.vertices], np.float32)
nor_v = np.array([v.normal[:] for v in mr.vertices], np.float32)
par_v = np.zeros((len(mr.vertices), 3), np.float32)
mr.attributes["param"].data.foreach_get("vector", par_v.ravel())
tv2 = lv2[tri_u]
P3 = PT.interpolar(tmap, bmap, tv2, pos_v)
N3 = PT.interpolar(tmap, bmap, tv2, nor_v)
PR = PT.interpolar(tmap, bmap, tv2, par_v)
PZ = piez[ltp[sel]][tmap[occ2]]
print("TEXTURA ropa texeles", int(occ2.sum()), "de", S2 * S2)

import p8_dibujos as DB
col, rug_r, met = DB.pintar(P3, N3, PR, PZ, ID)
img_c = np.zeros((S2, S2, 3), np.float32); img_c[occ2] = col
img_m = np.zeros((S2, S2, 3), np.float32); img_m[occ2] = np.stack([np.ones_like(rug_r), rug_r, met], -1)
# muestras lisas (en el espacio de 2048)
for pid, (cu, cv) in MUESTRAS.items():
    x0, x1 = int((cu - 0.016) * S2), int((cu + 0.016) * S2)
    y0, y1 = int((cv - 0.016) * S2), int((cv + 0.016) * S2)
    c_, r_, m_ = DB.muestra(pid, ID, (y1 - y0, x1 - x0))
    img_c[y0:y1, x0:x1] = c_; img_m[y0:y1, x0:x1, 0] = 1; img_m[y0:y1, x0:x1, 1] = r_; img_m[y0:y1, x0:x1, 2] = m_
    occ2[y0:y1, x0:x1] = True
img_c = PT.reducir(PT.dilatar(img_c, occ2, 10))
img_m = PT.reducir(PT.dilatar(img_m, occ2, 10))


def imagen(nombre, arr, no_color=False):
    im = bpy.data.images.get(nombre) or bpy.data.images.new(nombre, S, S, alpha=False)
    rgba = np.ones((S, S, 4), np.float32); rgba[..., :3] = np.clip(arr, 0, 1)
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = os.path.join(TEXDIR, "%s_%d.png" % (nombre, S))
    im.file_format = 'PNG'
    im.save()
    im.reload()
    if no_color:
        im.colorspace_settings.name = 'Non-Color'
    return im


im_col = imagen("nix_ropa_color", img_c)
im_mr = imagen("nix_ropa_mr", img_m, True)
mat = bpy.data.materials.new("nix_ropa")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
t1 = nt.nodes.new("ShaderNodeTexImage"); t1.image = im_col
t2 = nt.nodes.new("ShaderNodeTexImage"); t2.image = im_mr
sep = nt.nodes.new("ShaderNodeSeparateColor")
nt.links.new(t1.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(t2.outputs["Color"], sep.inputs["Color"])
nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
mr.materials.clear()
mr.materials.append(mat)
# atributos de trabajo fuera (no van al GLB)
for nm in ("pieza", "param", "orig"):
    if nm in mr.attributes:
        mr.attributes.remove(mr.attributes[nm])
print("ROPA material", mat.name, "texturas", im_col.size[:], im_mr.size[:])

if HASTA == "textura":
    bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
    if not SIN_RENDER:
        C.render_vistas(os.path.join(REND, "tex"), 1.9)
        vista(os.path.join(REND, "tex_cabeza"), Vector((0, 0, 1.70)), 0.62)
        vista(os.path.join(REND, "tex_espalda"), Vector((0, 0, 1.25)), 0.55, vistas=(("espalda", 180, 0),))
    print("FIN textura")
    sys.exit(0)

# ------------------------------------------------------------------ 10. movimiento horneado de los huesos nuevos
# En TODOS los clips (así ningún clip deja los faldones donde los dejó el anterior):
#   faldones: siguen el balanceo de su muslo (adelante/atrás y hacia fuera) con retraso, la punta más tarde; si el muslo
#   sube mucho (de rodillas), la parte de abajo cuelga; en «canalizar» y «magia_concentrar» se ABREN hacia fuera y
#   atrás con oscilación desfasada (izquierda y derecha, raíz y punta con fases distintas);
#   capa: se levanta un poco al correr y en la canalización; capucha: un leve vaivén en la canalización.
NUEVOS = ["faldon_i_1", "faldon_i_2", "faldon_d_1", "faldon_d_2", "capa", "capucha"]
mw = arm.matrix_world
for n in NUEVOS:
    arm.pose.bones[n].rotation_mode = 'QUATERNION'
R_HIPS0 = (mw @ arm.data.bones[P + "Hips"].matrix_local).to_3x3().normalized()


def dir_muslo_rest(lado):
    b = arm.data.bones[P + ("Left" if lado > 0 else "Right") + "UpLeg"]
    return ((mw @ b.tail_local) - (mw @ b.head_local)).normalized()


def angulos(d, lado):
    """Balanceo (adelante +) y apertura (hacia fuera +) de una dirección de muslo en el marco del cuerpo."""
    return math.atan2(-d.y, -d.z), math.atan2(lado * d.x, -d.z)


SW0 = {l: angulos(dir_muslo_rest(l), l) for l in (1, -1)}


def marco_cuerpo():
    return (mw @ arm.pose.bones[P + "Hips"].matrix).to_3x3().normalized() @ R_HIPS0.inverted()


def girar(nombre, q_cuerpo, B):
    pb = arm.pose.bones[nombre]
    pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()
    M0 = mw @ pb.matrix
    R = (B @ q_cuerpo.to_matrix() @ B.inverted()) @ M0.to_3x3().normalized()
    pb.matrix = mw.inverted() @ (Matrix.Translation(M0.to_translation()) @ R.to_4x4())
    bpy.context.view_layer.update()


def poner_accion(nombre):
    act = bpy.data.actions[nombre]
    arm.animation_data.action = act
    try:
        arm.animation_data.action_slot = act.slots[0]
    except Exception:
        pass
    return act


VIENTO_F = {"canalizar": "entrada", "magia_concentrar": "bucle"}
if arm.animation_data is None:
    arm.animation_data_create()
info_hornear = {}
for act in list(bpy.data.actions):
    poner_accion(act.name)
    f0, f1 = int(round(act.frame_range[0])), int(round(act.frame_range[1]))
    frames = list(range(f0, f1 + 1))
    bucle = act.name in ("andar", "correr", "reposo", "guardia", "magia_concentrar", "defensa", "derrota")
    for n in NUEVOS:
        arm.pose.bones[n].matrix_basis = Matrix.Identity(4)
    # 1. balanceo de los muslos en cada fotograma
    SW = {1: [], -1: []}
    for f in frames:
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        B = marco_cuerpo()
        for l in (1, -1):
            pb = arm.pose.bones[P + ("Left" if l > 0 else "Right") + "UpLeg"]
            d = (B.inverted() @ ((mw @ pb.tail) - (mw @ pb.head))).normalized()
            s, a = angulos(d, l)
            SW[l].append((s - SW0[l][0], a - SW0[l][1]))
    n = len(frames)

    def en(l, i, lag):
        k = i - int(round(lag * FPS))
        if bucle:
            k %= n
        else:
            k = max(0, k)
        return SW[l][k]
    max_ang = 0.0
    for i, f in enumerate(frames):
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        B = marco_cuerpo()
        t = (f - f0) / FPS
        dur = max((f1 - f0) / FPS, 1e-3)
        z_cad = (mw @ arm.pose.bones[P + "Hips"].head).z
        baja = min(1.0, max(0.0, (1.0 - z_cad) / 0.40))
        for l in (1, -1):
            s = "i" if l > 0 else "d"
            sw1, ab1 = en(l, i, 0.06)
            sw2, ab2 = en(l, i, 0.16)
            # hacia delante el muslo sale por la abertura del faldón (sigue poco); hacia atrás lo empuja (sigue más)
            p1 = max(-0.95, min(0.80, (0.45 if sw1 > 0 else 0.90) * sw1))
            o1 = 0.7 * max(0.0, ab1)
            p2 = 0.35 * (sw2 - sw1)
            p2 -= 0.45 * max(0.0, p1 - 0.40)            # muslo muy arriba: lo de abajo cuelga
            o1 += 0.55 * baja                            # de rodillas o agachada: se abre un poco y se queda atrás
            p1 -= 0.40 * baja
            o2 = 0.0
            modo = VIENTO_F.get(act.name)
            if modo:
                fase = 0.0 if l > 0 else 1.7
                if modo == "entrada":
                    sube = sm(0.08, 0.70, t)
                    w = 2 * math.pi * 1.25
                    o1 += sube * (0.30 + 0.05 * math.sin(w * t + fase))
                    o2 += sube * (0.10 + 0.10 * math.sin(w * t + fase - 1.1))
                    p1 += sube * (0.10 + 0.04 * math.sin(w * t + fase + 0.6))
                    p2 += sube * 0.06 * math.sin(w * t + fase - 0.4)
                else:                                     # bucle: dos ondas por vuelta (cierra el bucle)
                    w = 2 * math.pi * 2.0 / dur
                    o1 += 0.30 + 0.05 * math.sin(w * t + fase)
                    o2 += 0.10 + 0.10 * math.sin(w * t + fase - 1.1)
                    p1 += 0.10 + 0.04 * math.sin(w * t + fase + 0.6)
                    p2 += 0.06 * math.sin(w * t + fase - 0.4)
            q1 = Quaternion(Vector((1, 0, 0)), -p1) @ Quaternion(Vector((0, 1, 0)), -l * o1)
            q2 = Quaternion(Vector((1, 0, 0)), -p2) @ Quaternion(Vector((0, 1, 0)), -l * o2)
            girar("faldon_%s_1" % s, q1, B)
            girar("faldon_%s_2" % s, q2, B)
            max_ang = max(max_ang, abs(p1), abs(o1))
        # capa y capucha
        a_capa = 0.0; a_cap = 0.0; b_cap = 0.0
        if act.name == "correr":
            a_capa = 0.14 + 0.04 * math.sin(2 * math.pi * 2.0 * t / dur)
        elif act.name == "andar":
            a_capa = 0.03 + 0.02 * math.sin(2 * math.pi * 2.0 * t / dur)
        modo = VIENTO_F.get(act.name)
        if modo == "entrada":
            sube = sm(0.08, 0.70, t)
            a_capa = sube * (0.16 + 0.05 * math.sin(2 * math.pi * 1.25 * t + 0.8))
            a_cap = sube * 0.05 * math.sin(2 * math.pi * 1.25 * t + 1.6)
            b_cap = sube * 0.04 * math.sin(2 * math.pi * 0.9 * t)
        elif modo == "bucle":
            w = 2 * math.pi * 2.0 / dur
            a_capa = 0.16 + 0.05 * math.sin(w * t + 0.8)
            a_cap = 0.05 * math.sin(w * t + 1.6)
            b_cap = 0.04 * math.sin(w * 0.5 * t)
        girar("capa", Quaternion(Vector((1, 0, 0)), a_capa), B)
        girar("capucha", Quaternion(Vector((1, 0, 0)), a_cap) @ Quaternion(Vector((0, 1, 0)), b_cap), B)
        for nb in NUEVOS:
            arm.pose.bones[nb].keyframe_insert("rotation_quaternion", frame=f, group=nb)
    info_hornear[act.name] = (n, round(math.degrees(max_ang), 1))
    for nb in NUEVOS:
        arm.pose.bones[nb].matrix_basis = Matrix.Identity(4)
print("HORNEADO", info_hornear)
arm.animation_data.action = None
for pb in arm.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
bpy.context.view_layer.update()


# ------------------------------------------------------------------ 11. renders de comprobación
def en_pose(nombre, t):
    act = poner_accion(nombre)
    bpy.context.scene.frame_set(int(round(act.frame_range[0] + t * FPS)))
    bpy.context.view_layer.update()


if not SIN_RENDER:
    C.render_vistas(os.path.join(REND, "T"), 1.9)
    vista(os.path.join(REND, "T_cadera"), Vector((0, 0, 0.95)), 0.55, vistas=(("frente", 0, 0), ("tres_cuartos", 35, 6), ("abajo", 0, -25)))
    vista(os.path.join(REND, "T_cabeza"), Vector((0, 0, 1.70)), 0.62)
    vista(os.path.join(REND, "T_espalda"), Vector((0, 0, 1.25)), 0.55, vistas=(("espalda", 180, 0),))
    for nombre, ts in [("guardia", [0.0]), ("reposo", [0.0, 3.0]), ("andar", [0.0, 0.25, 0.5]), ("correr", [0.1, 0.3]),
                       ("canalizar", [0.0, 0.3, 0.6, 0.9]), ("magia_concentrar", [0.5, 1.6]),
                       ("magia_culminante", [0.85, 1.6]), ("ataque", [0.3, 0.45]), ("defensa", [0.0]),
                       ("recibir_golpe", [0.15]), ("derribo", [1.0]), ("derrota", [0.0, 2.0]), ("victoria", [1.4]),
                       ("saltar", [0.4]), ("girar", [0.35]), ("hablar", [1.0]), ("levantarse", [0.6])]:
        for t in ts:
            en_pose(nombre, t)
            C.render_vistas(os.path.join(REND, "clip_%s_%03d" % (nombre, int(t * 100))), 1.9,
                            vistas=[("frente", 0, 0), ("perfil", 90, 0), ("espalda", 180, 0), ("tres_cuartos", 35, 6)], res=500)
    for t in [0.0, 0.3, 0.6, 0.9]:
        en_pose("canalizar", t)
        C.render_vistas(os.path.join(REND, "canalizar_cerca_%03d" % int(t * 100)), 1.9, vistas=[("cerca", 25, 5)],
                        extra_esc=0.8)
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    bpy.context.view_layer.update()

# ------------------------------------------------------------------ 12. exportar
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
os.makedirs(os.path.dirname(GLB), exist_ok=True)
for o in bpy.data.objects:
    o.select_set(o in (arm, cuerpo, ropa))
bpy.context.view_layer.objects.active = arm
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
op = dict(filepath=GLB, export_format='GLB', use_selection=True, export_animations=True,
          export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
for k, v in [("export_image_format", 'WEBP'), ("export_image_quality", 90), ("export_frame_range", False),
             ("export_anim_slide_to_zero", True), ("export_def_bones", False)]:
    if k in props:
        op[k] = v
bpy.ops.export_scene.gltf(**op)
tri_c = sum(len(p.vertices) - 2 for p in cuerpo.data.polygons)
tri_r = sum(len(p.vertices) - 2 for p in ropa.data.polygons)
print("TOTAL triángulos cuerpo", tri_c, "ropa", tri_r, "total", tri_c + tri_r)
print("GLB", GLB, os.path.getsize(GLB))
print("FIN")
