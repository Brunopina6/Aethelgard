# Arreglo de la cara de Nix (14/11). Sobre una COPIA de p8_v4.blend (el origen exacto del GLB del juego).
#   NIX_P4=<posiciones de p4 .npy (p10_posiciones_p4.py)> blender -b --factory-startup -P p10_cara.py -- <p8_v4.blend>
#       <p2_horneada.blend> <carpeta con las texturas del FBX> x <salida texturas> <blend salida> [ext_a ray_a ext_b ray_b]
#   Lo usado el 14/11: NIX_NORMALES=1, NIX_PESO_BORDE=1.0, NIX_PRESUPUESTO=0 (los valores por defecto). Después
#   p10_cetro.py y p10_exportar.py. Informe: D:/REBELUM_diagnostico/v12/nix_arreglo_14_11/INFORME.md
# CAUSAS (comprobadas, informe del 14/11):
#  (1) p8_vestuario.py «pelo recogido» decidía qué era pelo por «claro y poco saturado» y la piel pálida de la barbilla,
#      la mandíbula y la boca lo es: comprimió esa piel hacia el elipsoide del cráneo (904 vértices de piel, hasta 9 mm)
#      -> barbilla abollada y boca torcida (la textura, horneada para la forma de p4, ya no encajaba).
#  (2) p8 pasaba a «gris ceniza» (x0,70/0,715/0,755, azulado) todo texel de la cabeza poco saturado que no fuera «piel»
#      (R-B > 0,035): la piel pálida de barbilla, mandíbula y comisuras quedaba gris (manchas).
#  (3) el rehorneado de p2 (rayos desde 8 mm fuera hasta 3 cm) tomaba, en el borde del cuello alto, el mechón o la parte
#      de abajo de la barbilla (franja clara y dentada); con las normales de la malla reducida la luz marcaba facetas.
# ARREGLO (solo piel de la cara, cuello y borde del cuello alto; pelo, ropa y resto del cuerpo NO cambian; mismos
# triángulos, mismo esqueleto, mismos clips): la piel vuelve a su sitio de p4; normales de la alta copiadas a esa piel
# (Data Transfer); rehorneado con Cycles con rayos CORTOS (2 mm fuera, 6 mm; si no hay impacto 4/12 mm) a 2048 y
# reducido a 1024; recoloreado con máscaras suavizadas (piel intacta; pelo -> ceniza; mono del cuello alto -> negro,
# con el borde del cuello alto medido en la alta); mezcla suave con la textura anterior en el borde de la región.
import bpy, sys, os
import numpy as np
from mathutils import Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import p8_pintura as PT
import p10_comun as C

a = sys.argv[sys.argv.index("--") + 1:]
BLEND_IN, BLEND_ALTA, FBXDIR, TEXPIL, TEXOUT, BLEND_OUT = a[:6]
EXT_A, RAY_A, EXT_B, RAY_B = [float(x) for x in (a[6:10] if len(a) >= 10 else ["0.002", "0.006", "0.004", "0.012"])]
os.makedirs(TEXOUT, exist_ok=True)
S = 2048

bpy.ops.wm.open_mainfile(filepath=BLEND_IN)
cuerpo = bpy.data.objects["cuerpo_nix"]
arm = bpy.data.objects["nix_esqueleto"]
if arm.animation_data:
    arm.animation_data.action = None
arm.data.pose_position = 'REST'
bpy.context.view_layer.update()
with bpy.data.libraries.load(BLEND_ALTA) as (src, dst):
    dst.objects = ["nix_alta"]
alta = dst.objects[0]
bpy.context.scene.collection.objects.link(alta)
alta.hide_render = False
alta.hide_set(False)
# texturas de la alta: las copias del FBX
base = os.path.join(FBXDIR, "Meshy_AI_Silver_Sentinel_20261113_texture")
mat_a = alta.data.materials[0]
bsa = [n for n in mat_a.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'][0]


def _img_de(sock):
    n = sock.links[0].from_node if sock.links else None
    while n is not None and n.type != 'TEX_IMAGE':
        ins = [i for i in n.inputs if i.links]
        n = ins[0].links[0].from_node if ins else None
    return n


for sock, suf, cs in [(bsa.inputs["Base Color"], ".png", "sRGB"), (bsa.inputs["Normal"], "_normal.png", "Non-Color"),
                      (bsa.inputs["Roughness"], "_roughness.png", "Non-Color"), (bsa.inputs["Metallic"], "_metallic.png", "Non-Color")]:
    n = _img_de(sock)
    if n is not None:
        n.image = bpy.data.images.load(base + suf)
        n.image.colorspace_settings.name = cs
        print("ALTA textura", sock.name, "->", n.image.filepath)

# ------------------------------------------------------------------ datos por vértice de la baja
me = cuerpo.data
V = np.zeros((len(me.vertices), 3), np.float32); me.vertices.foreach_get("co", V.ravel())
GI = {g.name: g.index for g in cuerpo.vertex_groups}
W = np.zeros((len(me.vertices), len(GI)), np.float32)
for v in me.vertices:
    for g in v.groups:
        W[v.index, g.group] = g.weight
w_cab = W[:, GI["mixamorig:Head"]]
w_mech = sum(W[:, GI[n]] for n in GI if n.startswith("mechon"))
lo_v = np.zeros(len(me.loops), np.int32); me.loops.foreach_get("vertex_index", lo_v)
lo_uv = np.zeros((len(me.loops), 2), np.float32); me.uv_layers.active.data.foreach_get("uv", lo_uv.ravel())
# Posiciones de p4 (ANTES del «pelo recogido» de p8). p8 decidía qué era pelo con «claro y poco saturado» y la piel
# pálida de la barbilla, la mandíbula y la boca lo es: la comprimió hacia el elipsoide del cráneo (hasta 9 mm; 268
# vértices de piel movidos más de 1 mm, i5_movidos.py). Aquí la piel se reconoce por la textura ORIGINAL de Meshy en
# el punto más cercano de la alta (R-B > 0,03: cálida) y vuelve a su sitio de p4 (la malla del FBX reducida).
V4 = np.load(os.environ["NIX_P4"])         # posiciones de cuerpo_nix en p4_rig.blend (i6_v4.py)
assert len(V4) == len(V)
from mathutils.bvhtree import BVHTree
ma = alta.data; ma.calc_loop_triangles()
TA = np.zeros((len(ma.loop_triangles), 3), np.int32); ma.loop_triangles.foreach_get("vertices", TA.ravel())
LA = np.zeros((len(ma.loop_triangles), 3), np.int32); ma.loop_triangles.foreach_get("loops", LA.ravel())
UA = np.zeros((len(ma.loops), 2), np.float32); ma.uv_layers.active.data.foreach_get("uv", UA.ravel())
VA = np.zeros((len(ma.vertices), 3), np.float32); ma.vertices.foreach_get("co", VA.ravel())
arbol = BVHTree.FromPolygons(VA.tolist(), TA.tolist(), all_triangles=True)
MESHY = C.leer_img(base + ".png")
# zona: el cuello (por debajo de 1,60 m, sin hombros) y la cabeza (1,60-1,80 m, hasta 0,20 m del centro del cráneo)
zona_v = (V4[:, 2] > 1.47) & (((V4[:, 2] < 1.60) & (np.hypot(V4[:, 0], V4[:, 1] - 0.01) < 0.11)) |
                              ((V4[:, 2] >= 1.60) & (V4[:, 2] < 1.80) & (np.hypot(V4[:, 0], V4[:, 1] - 0.02) < 0.20)))
col_v = np.zeros((len(V), 3), np.float32)
for i in np.nonzero(zona_v)[0]:
    loc, nor, fi, d = arbol.find_nearest(Vector(V4[i].tolist()))
    A, Bv, Cv = VA[TA[fi]]
    v0, v1, v2 = Bv - A, Cv - A, np.array(loc, np.float32) - A
    d00, d01, d11, d20, d21 = v0 @ v0, v0 @ v1, v1 @ v1, v2 @ v0, v2 @ v1
    den = d00 * d11 - d01 * d01
    w1 = (d11 * d20 - d01 * d21) / den; w2 = (d00 * d21 - d01 * d20) / den
    u = UA[LA[fi]].T @ np.array([1 - w1 - w2, w1, w2], np.float32)
    col_v[i] = MESHY[min(int(u[1] * MESHY.shape[0]), MESHY.shape[0] - 1), min(int(u[0] * MESHY.shape[1]), MESHY.shape[1] - 1), :3]
warm_v = col_v[:, 0] - col_v[:, 2]; lum_v = col_v.mean(1)
piel_v = zona_v & (warm_v > 0.03) & (w_mech < 0.05)
# delante de la cara, por debajo de los ojos (boca, labios, barbilla) no hay pelo, aunque no sea piel cálida
frente_baja = (V4[:, 2] < 1.665) & (V4[:, 2] >= 1.60) & (np.abs(V4[:, 0]) < 0.05) & (V4[:, 1] < -0.06) & (w_mech < 0.05)
piel_v = piel_v | (zona_v & frente_baja)
cuello_v = (V4[:, 2] < 1.60) & (np.hypot(V4[:, 0], V4[:, 1] - 0.01) < 0.068) & (w_mech < 0.05)   # cuello y cuello alto: ahí no hay pelo
es_pelo = zona_v & ~piel_v & ~cuello_v & ((lum_v > 0.55) | (w_mech > 0.05) | (V4[:, 2] > 1.62))
# rellenar huecos: un vértice «pelo» o «no piel» rodeado de piel es piel (la piel pálida de las mejillas no es cálida en
# todos sus puntos); dos pasadas por las aristas de la malla
ED = np.zeros((len(me.edges), 2), np.int32); me.edges.foreach_get("vertices", ED.ravel())
for _ in range(2):
    for clase in ("piel", "nopelo"):
        x = piel_v if clase == "piel" else ~es_pelo
        n_tot = np.zeros(len(V), np.float32); n_si = np.zeros(len(V), np.float32)
        for i0, i1 in ((0, 1), (1, 0)):
            np.add.at(n_tot, ED[:, i0], zona_v[ED[:, i1]]); np.add.at(n_si, ED[:, i0], (x & zona_v)[ED[:, i1]])
        lleno = zona_v & ~x & (n_tot > 0) & (n_si / np.maximum(n_tot, 1) >= 0.6) & (w_mech < 0.05)
        if clase == "piel":
            piel_v = piel_v | lleno
        else:
            es_pelo = es_pelo & ~lleno
es_pelo = es_pelo & ~piel_v
ok_v = zona_v & ~es_pelo                    # piel y cuello alto
np.save(BLEND_OUT + ".clases.npy", np.stack([piel_v, es_pelo, ok_v, zona_v], -1))
mov = np.linalg.norm(V - V4, axis=1)
rest = piel_v & (mov > 1e-5)
if os.environ.get("NIX_RESTAURAR", "1") == "1":
    for i in np.nonzero(rest)[0]:
        me.vertices[int(i)].co = Vector(V4[i].tolist())
    me.update()
    print("PIEL devuelta a p4:", int(rest.sum()), "vértices; desplazamiento medio %.4f máx %.4f m" % (mov[rest].mean(), mov[rest].max()))
    V[rest] = V4[rest]

# ------------------------------------------------------------------ refinado de la cara y el cuello (geometría)
# Debajo de la barbilla la malla reducida tendía un triángulo grande de la barbilla al cuello alto (un «puente» que en
# la alta no existe: de frente se veía como una franja de cuello clara y dentada); la boca y la barbilla, con pocas
# aristas. Se parten las aristas de la región cuya mitad queda más lejos de la alta (> 1,2 mm) y el vértice nuevo va a
# la superficie de la alta, hasta NIX_PRESUPUESTO triángulos más (cuerpo + ropa <= 20.000).
PRESUP = int(os.environ.get("NIX_PRESUPUESTO", "0"))   # 14/11: probado (+304 tri), no mejoraba lo visible: apagado
if PRESUP > 0:
    import p10_refinar as f_refinar
    am = np.array(alta.matrix_world)
    assert np.allclose(am, np.eye(4), atol=1e-5), am
    n0 = len(me.vertices); t0 = sum(len(p.vertices) - 2 for p in me.polygons)
    añad, nreg, d0, d1, rondas = f_refinar.refinar(me, arbol, ok_v, PRESUP)
    t1 = sum(len(p.vertices) - 2 for p in me.polygons)
    print("REFINADO: +%d triángulos (%d -> %d), %d vértices nuevos, desviación máx. %.4f -> %.4f m, %d rondas" % (
        t1 - t0, t0, t1, len(me.vertices) - n0, d0, d1, rondas))
    nv = len(me.vertices) - n0
    ext = lambda x, val: np.concatenate([x, np.full(nv, val, x.dtype)])
    ok_v = nreg.copy(); zona_v = ext(zona_v, True); piel_v = ext(piel_v, True); es_pelo = ext(es_pelo, False)
    V = np.zeros((len(me.vertices), 3), np.float32); me.vertices.foreach_get("co", V.ravel())
    W = np.zeros((len(me.vertices), len(GI)), np.float32)
    for v in me.vertices:
        for g in v.groups:
            W[v.index, g.group] = g.weight
    w_cab = W[:, GI["mixamorig:Head"]]
    w_mech = sum(W[:, GI[n]] for n in GI if n.startswith("mechon"))
    lo_v = np.zeros(len(me.loops), np.int32); me.loops.foreach_get("vertex_index", lo_v)
    lo_uv = np.zeros((len(me.loops), 2), np.float32); me.uv_layers.active.data.foreach_get("uv", lo_uv.ravel())
    malw = sum(1 for v in me.vertices if len(v.groups) > 4 or (v.groups and abs(sum(g.weight for g in v.groups) - 1) > 1e-3))
    print("PESOS: vértices con más de 4 huesos o sin normalizar:", malw)
    np.save(BLEND_OUT + ".clases.npy", np.stack([piel_v, es_pelo, ok_v, zona_v], -1))
me.calc_loop_triangles()
NT = len(me.loop_triangles)
lt = np.zeros(NT * 3, np.int32); me.loop_triangles.foreach_get("loops", lt); lt = lt.reshape(-1, 3)
tv = lo_v[lt]
reg_t = ok_v[tv].all(1)
# borde: vértices de la región que tocan un triángulo de fuera -> peso 0 (mezcla suave hacia la textura de antes)
fuera_v = np.zeros(len(V), bool)
fuera_v[tv[~reg_t].ravel()] = True
# peso de mezcla por vértice: la fracción de sus triángulos que son de la región (x1,6, hasta 1): un vértice de la
# barbilla que toca un triángulo de mechón no se queda con la textura vieja (antes eran «agujeros» con manchas)
n_t = np.zeros(len(V), np.float32); n_r = np.zeros(len(V), np.float32)
np.add.at(n_t, tv.ravel(), 1.0); np.add.at(n_r, tv.ravel(), np.repeat(reg_t, 3).astype(np.float32))
r_v = np.where(ok_v, np.clip(n_r / np.maximum(n_t, 1) * 1.6, 0, 1), 0.0).astype(np.float32)
print("REGION triángulos", int(reg_t.sum()), "vértices", int(ok_v.sum()), "interiores", int(r_v.sum()), "pelo", int(es_pelo.sum()))

# ------------------------------------------------------------------ normales de la alta en la piel de la cara y el cuello
# La malla reducida tiene la cara con facetas (la boca y la barbilla «abolladas»): con sus normales, la luz dibuja
# manchas y una sonrisa torcida. Se copian las normales de la alta (interpoladas en su superficie) a los vértices de
# la región (1 dentro, 0,5 en el borde que toca el pelo), con el modificador Data Transfer; la malla no cambia.
NORMALES = os.environ.get("NIX_NORMALES", "1") == "1"
if NORMALES:
    g = cuerpo.vertex_groups.new(name="_normales_cara")
    for i in np.nonzero(ok_v)[0]:
        g.add([int(i)], 1.0 if r_v[i] > 0.5 else float(os.environ.get("NIX_PESO_BORDE", "1.0")), "REPLACE")
    md = cuerpo.modifiers.new("_normales", 'DATA_TRANSFER')
    md.object = alta
    md.use_loop_data = True
    md.data_types_loops = {'CUSTOM_NORMAL'}
    md.loop_mapping = 'POLYINTERP_NEAREST'
    md.vertex_group = g.name
    md.mix_mode = 'REPLACE'
    md.mix_factor = 1.0
    # el modificador de esqueleto va primero: ponerlo delante para aplicarlo en reposo sin tocar el esqueleto
    bpy.context.view_layer.objects.active = cuerpo
    while cuerpo.modifiers.find(md.name) > 0:
        bpy.ops.object.modifier_move_up(modifier=md.name)
    bpy.ops.object.modifier_apply(modifier=md.name)
    cuerpo.vertex_groups.remove(cuerpo.vertex_groups["_normales_cara"])
    print("NORMALES de la alta copiadas en", int(ok_v.sum()), "vértices; modificadores", [m.name for m in cuerpo.modifiers])

# ------------------------------------------------------------------ horneado con rayos cortos
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
try:
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'OPTIX'
    prefs.get_devices()
    for d in prefs.devices:
        d.use = True
    sc.cycles.device = 'GPU'
    print("CYCLES GPU", [d.name for d in prefs.devices])
except Exception as e:
    print("CYCLES CPU", e)
sc.cycles.samples = 8
bk = sc.render.bake
bk.use_selected_to_active = True
bk.use_cage = False
bk.margin = 4
mat = cuerpo.active_material
nt = mat.node_tree
SENT = (1.0, 0.0, 1.0, 1.0)


def destino(nombre):
    im = bpy.data.images.new(nombre, S, S, alpha=False, float_buffer=True)
    im.colorspace_settings.name = 'Non-Color'
    im.generated_color = SENT
    tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = im; tn.name = "d_" + nombre
    return im, tn


def hornear(tipo, im, tn, ext, ray, **kw):
    bk.cage_extrusion = ext
    bk.max_ray_distance = ray
    for n in nt.nodes:
        n.select = False
    tn.select = True
    nt.nodes.active = tn
    for o in bpy.context.selected_objects:
        o.select_set(False)
    alta.select_set(True); cuerpo.select_set(True)
    bpy.context.view_layer.objects.active = cuerpo
    bpy.ops.object.bake(type=tipo, **kw)
    return np.array(im.pixels[:], np.float32).reshape(S, S, 4)


res = {}
for paso, ext, ray in [("a", EXT_A, RAY_A), ("b", EXT_B, RAY_B)]:
    for nombre, tipo, kw in [("color", 'DIFFUSE', dict(pass_filter={'COLOR'})),
                             ("normal", 'NORMAL', dict(normal_space='TANGENT')),
                             ("rugosidad", 'ROUGHNESS', {})]:
        im, tn = destino("h_%s_%s" % (nombre, paso))
        res[(nombre, paso)] = hornear(tipo, im, tn, ext, ray, **kw)
        nt.nodes.remove(tn)
        print("HORNEADO", nombre, paso, ext, ray)


def es_sent(x):
    return (x[..., 0] > 0.99) & (x[..., 1] < 0.01) & (x[..., 2] > 0.99)


def a_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)


falla_a = es_sent(res[("color", "a")])
falla_b = es_sent(res[("color", "b")])
nuevo = {}
for nombre in ("color", "normal", "rugosidad"):
    x = res[(nombre, "a")].copy()
    x[falla_a] = res[(nombre, "b")][falla_a]
    nuevo[nombre] = x
falla = falla_a & falla_b

# ------------------------------------------------------------------ región en el espacio UV (2048) y datos por texel
tri_map, bary = PT.rasterizar(lo_uv[lt] * S, S)
occ = tri_map >= 0
dat = np.stack([V[:, 0], V[:, 1], V[:, 2], r_v, w_mech], -1)
tvd = PT.interpolar(tri_map, bary, tv, dat)
treg = np.zeros((S, S), bool); treg[occ] = reg_t[tri_map[occ]]
peso = np.zeros((S, S), np.float32); peso[occ] = np.where(reg_t[tri_map[occ]], tvd[:, 3], 0.0)
Z = np.zeros((S, S), np.float32); Z[occ] = tvd[:, 2]
X = np.zeros((S, S), np.float32); X[occ] = tvd[:, 0]
Y = np.zeros((S, S), np.float32); Y[occ] = tvd[:, 1]
print("FALLOS en la región: rayo corto", int((falla_a & treg).sum()), "y largo", int((falla & treg).sum()), "de", int(treg.sum()))
peso[falla] = 0.0
print("TEXELES región", int(treg.sum()), "peso>0.5", int((peso > 0.5).sum()))

# ------------------------------------------------------------------ recoloreado (en sRGB, como p8)
c = a_srgb(nuevo["color"][..., :3])


def borrar(img, m, r=2):
    """media de caja de radio r (en texeles) restringida a la máscara m (no mezcla con lo de fuera)."""
    acc = np.zeros_like(img); n = np.zeros(m.shape, np.float32)
    mf = m.astype(np.float32)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            acc += np.roll(img * mf[..., None], (dy, dx), (0, 1)); n += np.roll(mf, (dy, dx), (0, 1))
    return acc / np.maximum(n, 1e-6)[..., None]


lum = c.mean(-1); warm = c[..., 0] - c[..., 2]; sat = c.max(-1) - c.min(-1)
feat = borrar(np.stack([lum, warm, sat], -1), treg & ~falla, 3)
blum, bwarm, bsat = feat[..., 0], feat[..., 1], feat[..., 2]
ojo = (c[..., 2] - c[..., 1] > 0.08)


def sm(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# pelo: claro y neutro en una zona amplia (la piel pálida es cálida en su entorno; ojos y líneas oscuras no)
p_pelo = sm(0.50, 0.60, blum) * sm(0.030, 0.005, bwarm) * sm(0.14, 0.08, bsat) * (~ojo)
# cuello alto: por debajo de la barbilla, lo que no es piel cálida
p_piel_local = sm(0.015, 0.045, warm) * sm(0.25, 0.35, lum)
# el borde del cuello alto en la ALTA (i3_cuello.py: primera piel por encima del mono, por sectores de 30°, 0 = delante)
ZC_AZ = np.array([-165, -135, -105, -75, -45, -15, 15, 45, 75, 105, 135, 165], np.float32)
ZC = np.array([1.585, 1.575, 1.572, 1.581, 1.584, 1.574, 1.575, 1.583, 1.585, 1.567, 1.570, 1.574], np.float32)
az = np.degrees(np.arctan2(X, -(Y - 0.010)))
zc = np.interp(az, np.concatenate([ZC_AZ - 360, ZC_AZ, ZC_AZ + 360]), np.concatenate([ZC, ZC, ZC]))
en_cuello = sm(0.080, 0.070, np.hypot(X, Y - 0.010))
p_cuello = np.maximum(sm(zc + 0.001, zc - 0.003, Z) * en_cuello, sm(1.615, 1.595, Z) * (1.0 - p_piel_local))
p_pelo = p_pelo * (1.0 - p_cuello)
CENIZA = np.array([0.70, 0.715, 0.755], np.float32)
NEGRO_MONO = np.array([0.072, 0.060, 0.082], np.float32)
c_pelo = c * CENIZA
c_mono = NEGRO_MONO * np.clip((lum / 0.45) ** 0.9, 0.35, 1.8)[..., None]
cf = c * (1 - p_pelo - p_cuello)[..., None] + c_pelo * p_pelo[..., None] + c_mono * p_cuello[..., None]
rug = nuevo["rugosidad"][..., 0]
rug = np.where(p_cuello > 0.5, np.maximum(rug, 0.80), rug)
print("RECOLOR pelo %.0f cuello %.0f texeles (ponderados)" % ((p_pelo * treg).sum(), (p_cuello * treg).sum()))


# ------------------------------------------------------------------ mezcla con las texturas de antes (1024)
def cargar(nombre):
    im = bpy.data.images[nombre]
    return im, np.array(im.pixels[:], np.float32).reshape(1024, 1024, 4)


mreg = (treg & ~falla)
den = np.maximum(PT.reducir(mreg[..., None].astype(np.float32)), 1e-6)


def a_1024(x):
    return PT.reducir(np.where(mreg[..., None], x, 0.0)) / den


# peso relativo a la parte CUBIERTA del texel de 1024 (en el borde de una isla no se mezcla con el margen viejo) y
# relleno de los márgenes (texeles sin triángulo) con lo nuevo, 4 texeles: el filtrado no trae colores de antes
cub = PT.reducir(occ[..., None].astype(np.float32))[..., 0]
w1024 = PT.reducir(np.where(mreg, peso, 0.0)[..., None])[..., 0] / np.maximum(cub, 1e-6)
w1024 = np.clip(w1024, 0, 1)
cf1024 = a_1024(cf)
nn1024 = a_1024(nuevo["normal"][..., :3])
rr1024 = a_1024(rug[..., None])[..., 0]
ocup = PT.reducir(mreg[..., None].astype(np.float32))[..., 0] > 0
vacio = cub <= 0
pack = PT.dilatar(np.concatenate([cf1024, nn1024, rr1024[..., None], w1024[..., None]], -1) * ocup[..., None], ocup, 4)
rell = vacio & ~ocup
cf1024[rell] = pack[rell][:, 0:3]; nn1024[rell] = pack[rell][:, 3:6]; rr1024[rell] = pack[rell][:, 6]; w1024[rell] = pack[rell][:, 7]


def escribir(nombre, nuevo_rgb):
    im, old = cargar(nombre)
    out = old.copy()
    out[..., :3] = old[..., :3] * (1 - w1024[..., None]) + nuevo_rgb * w1024[..., None]
    im.pixels.foreach_set(out.ravel())
    im.filepath_raw = os.path.join(TEXOUT, nombre + "_1024.png"); im.file_format = 'PNG'; im.save()
    print("ESCRITA", im.filepath_raw, im.colorspace_settings.name)


# nix_color es sRGB: im.pixels da los valores tal cual se guardan (sRGB) en imágenes de 8 bits
escribir("nix_color", cf1024)
escribir("nix_normal", nn1024)
escribir("nix_rugosidad", np.repeat(rr1024[..., None], 3, -1))
C.guardar_img(np.repeat(w1024[..., None], 3, -1), os.path.join(TEXOUT, "mascara_region_1024.png"))
for nm in ("nix_color", "nix_normal", "nix_rugosidad"):
    bpy.data.images[nm].filepath = os.path.join(TEXOUT, nm + "_1024.png")
    bpy.data.images[nm].reload()
bpy.data.objects.remove(alta, do_unlink=True)
sc.render.engine = 'BLENDER_EEVEE'
arm.data.pose_position = 'POSE'
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
print("FIN", BLEND_OUT)
