# Arreglo de la capa corta de Nix (14/11, tarde). Sobre una COPIA de p8_final.blend (lo instalado tras p10).
#   blender -b --factory-startup -P p11_capa.py -- <blend entrada> <blend salida>
#   Después p10_exportar.py, copiar el GLB e importar.
# CAUSA (comprobada en render de Blender con la ropa en falso color, hoja «capa_ids»): el «vuelo» de p8_vestuario.py
# (extra_capa) tenía dos defectos de construcción, no de diseño:
#  (1) la orientación de cada cara del vuelo se decidía comparándola con una cara vecina de la capa; en el borde cortado
#      por el plano (caras finas, normales al azar) acertaba solo a ratos. Donde fallaba, la cara negra miraba hacia
#      dentro (Godot la descarta: cull_back) y su copia de forro, desplazada 4 mm «hacia dentro» según SU normal, quedaba
#      4 mm por FUERA, de cara a la cámara: los RECTÁNGULOS PÚRPURA de la espalda alta y del borde de los puños. El
#      dentado azul de debajo de la espalda (dientes que cuelgan) era el mismo vuelo con direcciones horizontales por
#      vértice sin suavizar (de normales casi verticales en el corte).
#  (2) el «puño» del brazo era un cono que se abría 2,6 cm hacia fuera del brazo (más 1,6 cm a lo largo) sobre una capa
#      que ya va a 2 cm de la manga: al bajar o doblar el brazo quedaba como una ALETA plana que sobresale.
# El canon (Nix_TPose_Vestida_Frente/Espalda_Emblema) es una capa corta con el borde dorado continuo que cae sobre el
# hombro y el brazo y el forro púrpura solo asoma por debajo del borde; no tiene placas sueltas ni rectángulos.
# ARREGLO (mismos vértices, caras, UV, pesos y esqueleto; solo posiciones y orientación de esas caras):
#  - borde de abajo: el vuelo conserva su medida (2 cm hacia fuera y 4,5 cm hacia abajo) con la dirección hacia fuera
#    SUAVIZADA a lo largo del borde; caras del vuelo hacia fuera y su forro 4 mm por DENTRO, mirando hacia dentro;
#  - puños: el vuelo deja de abrirse; sigue el brazo (1,8 cm a lo largo) y se cierra un poco hacia él (6 mm), como un
#    dobladillo que cae; el forro, 4 mm por dentro;
#  - normales: las de esas caras se recalculan (suaves); el resto de la ropa conserva las suyas.
import bpy, bmesh, sys, math
import numpy as np
from mathutils import Vector

a = sys.argv[sys.argv.index("--") + 1:]
BLEND_IN, BLEND_OUT = a[:2]
bpy.ops.wm.open_mainfile(filepath=BLEND_IN)
ropa = bpy.data.objects["ropa_nix"]
me = ropa.data
Z_CAPA, X_CAPA = 1.40, 0.33                 # cortes de la capa en p8 (abajo, brazo)
EJE_BRAZO = Vector((0.0, 0.004, 1.463))     # eje (y, z) del brazo en la pose T, el de p8_dibujos (p_capa)
VUELO_BAJO = (0.020, 0.045)                 # hacia fuera, hacia abajo (lo de p8)
PUNO = (0.018, -0.006)                      # a lo largo del brazo, radial (negativo: hacia el brazo)
FORRO = 0.004

# normales finales de todas las esquinas (se conservan salvo en las caras tocadas)
me.calc_loop_triangles() if hasattr(me, "calc_loop_triangles") else None
cn_ant = np.array([n.vector[:] for n in me.corner_normals], np.float32) if hasattr(me, "corner_normals") else None
print("CUSTOM normales", me.has_custom_normals, "esquinas", len(me.loops))

bm = bmesh.new(); bm.from_mesh(me)
bm.verts.ensure_lookup_table(); bm.faces.ensure_lookup_table()
uvl = bm.loops.layers.uv["UVMap"]


def componentes():
    comp = [-1] * len(bm.verts); n = 0
    for v0 in bm.verts:
        if comp[v0.index] >= 0:
            continue
        pila = [v0]; comp[v0.index] = n
        while pila:
            v = pila.pop()
            for e in v.link_edges:
                w = e.other_vert(v)
                if comp[w.index] < 0:
                    comp[w.index] = n; pila.append(w)
        n += 1
    return comp, n


def es_forro(f):
    u, v = f.loops[0][uvl].uv
    return u < 0.04 and v < 0.04


comp, nc = componentes()
caras_de = {k: [] for k in range(nc)}
for f in bm.faces:
    caras_de[comp[f.verts[0].index]].append(f)


def caja(k):
    P = np.array([v.co[:] for f in caras_de[k] for v in f.verts])
    return P.min(0), P.max(0)


capa_k = forro_bajo_k = None
forro_puno_k = []
for k in range(nc):
    mn, mx = caja(k)
    todo_forro = all(es_forro(f) for f in caras_de[k])
    if not todo_forro and mn[2] > 1.34 and mx[2] < 1.56 and 0.34 < mx[0] < 0.36 and -0.36 < mn[0] < -0.34:
        capa_k = k
    elif todo_forro and mn[2] > 1.34 and mx[2] < 1.42 and mx[0] < 0.2:
        forro_bajo_k = k
    elif todo_forro and mn[2] > 1.38 and mx[2] < 1.57 and 0.32 < max(abs(mn[0]), abs(mx[0])) < 0.36 \
            and min(abs(mn[0]), abs(mx[0])) > 0.31:
        forro_puno_k.append(k)
assert capa_k is not None and forro_bajo_k is not None and len(forro_puno_k) == 2, (capa_k, forro_bajo_k, forro_puno_k)
print("CAPA componente", capa_k, "caras", len(caras_de[capa_k]), "| forro abajo", forro_bajo_k,
      len(caras_de[forro_bajo_k]), "| forro puños", forro_puno_k, [len(caras_de[k]) for k in forro_puno_k])

# vuelo: vértices exteriores (borde libre) y su vértice interior (el borde de la capa antes del vuelo)
capa_v = {v for f in caras_de[capa_k] for v in f.verts}
ext_bajo, ext_puno = [], []
for v in capa_v:
    if not v.is_boundary:
        continue
    if v.co.z < Z_CAPA - 0.02 and abs(v.co.x) < X_CAPA - 0.01:
        ext_bajo.append(v)
    elif abs(v.co.x) > X_CAPA + 0.008:
        ext_puno.append(v)
ext_set = set(ext_bajo) | set(ext_puno)


def interior(v):
    cand = [e.other_vert(v) for e in v.link_edges]          # (los vuelos son quads: el único vecino que no es
    cand = [w for w in cand if w not in ext_set]             # del borde libre es su vértice interior)
    assert len(cand) == 1, (v.index, v.co[:], len(cand))
    return cand[0]


par = {v: interior(v) for v in ext_set}
vuelo = {f for v in ext_set for f in v.link_faces}
print("VUELO abajo", len(ext_bajo), "puños", len(ext_puno), "caras", len(vuelo))

# posiciones de antes (para emparejar el forro, que es una copia desplazada 4 mm del vuelo)
ant = {v: v.co.copy() for f in vuelo for v in f.verts}


def fuera_capa(w):
    """Normal de la capa (sin el vuelo) en un vértice interior."""
    n = Vector()
    for f in w.link_faces:
        if f not in vuelo:
            n += f.normal * f.calc_area()
    return n.normalized() if n.length > 1e-9 else Vector((0, 0, 0))


# ---- borde de abajo: dirección hacia fuera horizontal, suavizada a lo largo del borde
orden = sorted(ext_bajo, key=lambda v: math.atan2(par[v].co.x, par[v].co.y))
dirs = []
for v in orden:
    w = par[v]
    n = fuera_capa(w)
    nh = Vector((n.x, n.y, 0.0))
    # respaldo (y comprobación): desde el eje vertical del cuerpo hacia el vértice
    r = Vector((w.co.x, w.co.y - 0.0, 0.0))
    if nh.length < 0.3 or nh.normalized().dot(r.normalized()) < 0.2:
        nh = r
    dirs.append(nh.normalized())
D = np.array([d[:] for d in dirs])
for _ in range(4):
    Dp = np.pad(D, ((1, 1), (0, 0)), mode='edge')
    D = (Dp[:-2] + 2 * Dp[1:-1] + Dp[2:]) / 4
    D /= np.linalg.norm(D, axis=1, keepdims=True)
cambio_max = 0.0
REF = {}                                   # vértice del vuelo -> dirección «hacia fuera» de su cara
for v, d in zip(orden, D):
    d = Vector(d.tolist())
    nuevo = par[v].co + d * VUELO_BAJO[0] + Vector((0, 0, -VUELO_BAJO[1]))
    cambio_max = max(cambio_max, (nuevo - v.co).length)
    v.co = nuevo
    REF[v] = d; REF[par[v]] = d
print("ABAJO movido máx %.4f m" % cambio_max)

# ---- puños: siguen el brazo y se cierran un poco hacia él
cambio_max = 0.0
for v in ext_puno:
    w = par[v]
    rad = Vector((0.0, w.co.y - EJE_BRAZO.y, w.co.z - EJE_BRAZO.z)).normalized()
    nuevo = w.co + Vector((math.copysign(PUNO[0], w.co.x), 0, 0)) + rad * PUNO[1]
    cambio_max = max(cambio_max, (nuevo - v.co).length)
    v.co = nuevo
    REF[v] = rad; REF[w] = rad
print("PUÑOS movido máx %.4f m" % cambio_max)

# ---- orientación del vuelo: la cara negra, hacia fuera
bm.normal_update()
giradas = 0
for f in vuelo:
    ref = sum((REF[v] for v in f.verts if v in REF), Vector())
    if f.normal.dot(ref) < 0:
        f.normal_flip(); giradas += 1
bm.normal_update()
print("VUELO caras giradas", giradas, "de", len(vuelo))

# ---- forro: cada vértice es la copia de un vértice del vuelo (a 4 mm); va 4 mm por DENTRO y mira hacia dentro
forro_f = [f for k in [forro_bajo_k] + forro_puno_k for f in caras_de[k]]
forro_v = {v for f in forro_f for v in f.verts}
vuelo_v = list(ant.keys())
VA = np.array([ant[v][:] for v in vuelo_v])
dist_max = 0.0
for v in forro_v:
    d = np.linalg.norm(VA - np.array(v.co[:]), axis=1)
    i = int(np.argmin(d)); dist_max = max(dist_max, float(d[i]))
    o = vuelo_v[i]
    v.co = o.co - REF[o] * FORRO
bm.normal_update()
giradas_f = 0
for f in forro_f:
    ref = sum((REF[o] for o in [vuelo_v[int(np.argmin(np.linalg.norm(VA - np.array(v.co[:]), axis=1)))] for v in f.verts]), Vector())
    if f.normal.dot(ref) > 0:
        f.normal_flip(); giradas_f += 1
bm.normal_update()
print("FORRO vértices", len(forro_v), "distancia al vuelo antes máx %.4f" % dist_max, "caras giradas", giradas_f, "de", len(forro_f))

tocadas = {f.index for f in vuelo} | {f.index for f in forro_f}
bm.to_mesh(me); bm.free()
me.update()

# normales: las de antes en lo no tocado; en lo tocado, las suaves de la malla nueva (por vértice, solo entre caras tocadas)
if cn_ant is not None and me.has_custom_normals:
    nuevas = cn_ant.copy()
    pos = np.array([v.co[:] for v in me.vertices])
    acc = {}
    for p in me.polygons:
        if p.index in tocadas:
            for vi in p.vertices:
                acc[vi] = acc.get(vi, Vector()) + p.normal * p.area
    for p in me.polygons:
        if p.index in tocadas:
            for li, vi in zip(p.loop_indices, p.vertices):
                nuevas[li] = acc[vi].normalized()[:]
    me.normals_split_custom_set([tuple(n) for n in nuevas])
    print("NORMALES personalizadas: tocadas", len(tocadas), "caras")
tri = sum(len(p.vertices) - 2 for p in me.polygons)
print("ROPA triángulos", tri, "vértices", len(me.vertices))
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
print("FIN p11_capa", BLEND_OUT)
