# meshy_e01 · paso 2: escala de juego, esqueleto bípedo ligero y pesos limpios (≤ 2 influencias, rígidos en las placas).
#   blender -b --factory-startup -P p1_rig.py -- <fbx copia> <blend salida> <carpeta render> [sin_render]
#
# Orientación medida en p0 (no supuesta): el FBX importado mira a -Y, su izquierda es +X y arriba +Z; mide 0,951 de alto
# y está centrado en el origen. Aquí se escala a ALTO_JUEGO (1,85 m) con los pies en z = 0 y se APLICA la transformación
# (rotación y escala aplicadas antes del skin).
#
# Pesos (método propio, sin pesos automáticos, que doblan las placas rígidas):
#   1. Región de cadena por distancia GEODÉSICA sobre la malla (Dijkstra desde semillas en cada hueso): la mano solo
#      llega al muslo pasando por el hombro, así que no se mezclan aunque estén cerca en el espacio.
#   2. Dentro de cada cadena (tronco, brazo, pierna), el hueso lo decide el PLANO de cada junta (perpendicular a la
#      dirección media de los dos huesos); solo a ±r de la junta se mezclan los dos (smoothstep). Lejos de las juntas, una
#      sola influencia de peso 1: las placas no se doblan.
#   3. Hombreras: las placas de los hombros van a su propio hueso (hijo de la clavícula), no al brazo.
#   4. Piezas sueltas (las dos rodilleras, separadas de la malla): rígidas a la pierna de su lado.
#   La llave del pecho queda rígida al pecho (dentro de su placa). No hay arma ni dedos que añadir.
import sys, os, json, math, heapq
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
FBX, BLEND, REND = argv[:3]
SIN_RENDER = "sin_render" in argv
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector, Matrix
import e01_comun as C

ALTO_FBX = 0.951172
Z0_FBX = -0.47583
ALTO_JUEGO = 1.85
K = ALTO_JUEGO / ALTO_FBX


def g(x, y, z):
    """De las medidas del FBX (las de la rejilla de p0) al espacio del juego."""
    return Vector((x * K, y * K, (z - Z0_FBX) * K))


# Juntas medidas sobre la rejilla de 2,5 cm (frente y perfil) de p0, en unidades del FBX. Izquierda del personaje = +X.
J = {
    "raiz": g(0, 0.0, Z0_FBX), "cadera": g(0, 0.005, -0.035), "columna": g(0, 0.005, 0.095), "pecho": g(0, 0.0, 0.125),
    "cuello": g(0, 0.012, 0.32), "cabeza": g(0, 0.0, 0.355), "cabeza_fin": g(0, -0.005, 0.475),
}
LADO = {
    "clavicula": (0.035, 0.03, 0.285), "hombro": (0.19, 0.045, 0.265), "hombrera_fin": (0.25, 0.04, 0.31),
    "codo": (0.215, 0.058, 0.122), "muneca": (0.258, 0.022, -0.045), "mano_fin": (0.27, -0.045, -0.205),
    "cadera": (0.098, 0.005, -0.045), "rodilla": (0.15, -0.006, -0.218), "tobillo": (0.16, 0.036, -0.395),
    "bola": (0.172, -0.07, -0.452), "punta": (0.176, -0.125, -0.455),
}
for s, sx in (("L", 1), ("R", -1)):
    for k, (x, y, z) in LADO.items():
        J["%s.%s" % (k, s)] = g(x * sx, y, z)

# huesos: nombre, cabeza, cola, padre, deforma
HUESOS = [
    ("raiz", J["raiz"], J["raiz"] + Vector((0, 0.25, 0)), None, False),
    ("cadera", J["cadera"], J["columna"], "raiz", True),
    ("columna", J["columna"], J["pecho"], "cadera", True),
    ("pecho", J["pecho"], J["cuello"], "columna", True),
    ("cuello", J["cuello"], J["cabeza"], "pecho", True),
    ("cabeza", J["cabeza"], J["cabeza_fin"], "cuello", True),
]
for s in ("L", "R"):
    HUESOS += [
        ("clavicula." + s, J["clavicula." + s], J["hombro." + s], "pecho", False),
        ("hombrera." + s, J["hombro." + s] + Vector((0, 0, 0.06)), J["hombrera_fin." + s], "clavicula." + s, True),
        ("brazo." + s, J["hombro." + s], J["codo." + s], "clavicula." + s, True),
        ("antebrazo." + s, J["codo." + s], J["muneca." + s], "brazo." + s, True),
        ("mano." + s, J["muneca." + s], J["mano_fin." + s], "antebrazo." + s, True),
        ("muslo." + s, J["cadera." + s], J["rodilla." + s], "cadera", True),
        ("pierna." + s, J["rodilla." + s], J["tobillo." + s], "muslo." + s, True),
        ("pie." + s, J["tobillo." + s], J["bola." + s], "pierna." + s, True),
        ("punta." + s, J["bola." + s], J["punta." + s], "pie." + s, True),
    ]
# controles de autoría (no se exportan): objetivos de IK de manos y pies
CONTROLES = []
for s in ("L", "R"):
    CONTROLES += [("ik_mano." + s, "mano." + s), ("ik_pie." + s, "pie." + s)]

CADENAS = {
    "tronco": ["cadera", "columna", "pecho", "cuello", "cabeza"],
    "brazo.L": ["brazo.L", "antebrazo.L", "mano.L"], "brazo.R": ["brazo.R", "antebrazo.R", "mano.R"],
    "pierna.L": ["muslo.L", "pierna.L", "pie.L", "punta.L"], "pierna.R": ["muslo.R", "pierna.R", "pie.R", "punta.R"],
}
# radio de mezcla de cada junta (m de juego) y desplazamiento del plano a lo largo del hueso hijo (m)
RADIO = {"columna": 0.025, "pecho": 0.025, "cuello": 0.03, "cabeza": 0.02,
         "antebrazo": 0.04, "mano": 0.025, "pierna": 0.05, "pie": 0.03, "punta": 0.015, "muslo": 0.025}
# el plano de la cadera va 4 cm POR ENCIMA de la junta: el borde de abajo del cinturón; la placa del muslo entera, al muslo
DESPL = {"muslo": -0.04, "cuello": 0.0, "cabeza": 0.0}
# cuello y cabeza solo dentro de la columna del cuello y el casco (|x| < 7,5 cm del FBX): las placas del cuello del
# peto (más anchas) se quedan en el pecho, rígidas
ANCHO_CUELLO_FBX = 0.075
# por debajo del cinturón (z del FBX < -0,01), lo que no es brazo: |x| < 6 cm es la pieza de la entrepierna (cadera); el
# resto, la pierna de su lado (la distancia geodésica deja la parte alta de las placas del muslo en el tronco)
Z_CINTURON_FBX = -0.01
ANCHO_ENTREPIERNA_FBX = 0.06

# ------------------------------------------------------------------ 1. importar, escalar y aplicar
nuevos = C.importar_fbx(FBX)
cuerpo = [o for o in nuevos if o.type == 'MESH'][0]
cuerpo.name = "e01_cuerpo"
cuerpo.data.name = "e01_cuerpo"
cuerpo.matrix_world = Matrix.Translation((0, 0, -Z0_FBX * K)) @ Matrix.Scale(K, 4) @ cuerpo.matrix_world
bpy.context.view_layer.objects.active = cuerpo
for o in bpy.data.objects:
    o.select_set(o == cuerpo)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for o in list(bpy.data.objects):
    if o != cuerpo:
        bpy.data.objects.remove(o, do_unlink=True)
me = cuerpo.data
P = [v.co.copy() for v in me.vertices]
zmin = min(p.z for p in P); zmax = max(p.z for p in P)
print("ALTO %.4f m  zmin %.4f" % (zmax - zmin, zmin))
mat = me.materials[0]
mat.name = "e01_porcelana"
# texturas con nombre propio (las del FBX vienen empaquetadas como Image_0/Image_2…)
NOMBRES_IMG = {"Base Color": "e01_color", "Color": "e01_normal", "Roughness": "e01_rugosidad", "Metallic": "e01_metalico"}
for n in mat.node_tree.nodes:
    if n.bl_idname == 'ShaderNodeTexImage' and n.image:
        for l in n.outputs[0].links:
            if l.to_socket.name in NOMBRES_IMG:
                n.image.name = NOMBRES_IMG[l.to_socket.name]

# ------------------------------------------------------------------ 2. esqueleto
ad = bpy.data.armatures.new("e01_esqueleto")
arm = bpy.data.objects.new("e01_esqueleto", ad)
bpy.context.scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
for o in bpy.data.objects:
    o.select_set(o == arm)
bpy.ops.object.mode_set(mode='EDIT')
eb = ad.edit_bones
for nombre, h, t, padre, deforma in HUESOS:
    b = eb.new(nombre)
    b.head = h; b.tail = t
    d = (t - h).normalized()
    b.align_roll(Vector((0, 0, 1)) if abs(d.z) < 0.7 else Vector((0, -1, 0)))
    b.use_deform = deforma
    if padre:
        b.parent = eb[padre]
        b.use_connect = False
for nombre, copia in CONTROLES:
    o = eb[copia]
    b = eb.new(nombre)
    b.head = o.head.copy(); b.tail = o.tail.copy(); b.roll = o.roll
    b.parent = eb["raiz"]
    b.use_deform = False
bpy.ops.object.mode_set(mode='OBJECT')

# restricciones de autoría: IK de 2 huesos (sin estirar) y la rotación de manos y pies copiada de su objetivo
for s in ("L", "R"):
    for punta, cadena_fin, obj in (("mano." + s, "antebrazo." + s, "ik_mano." + s), ("pie." + s, "pierna." + s, "ik_pie." + s)):
        c = arm.pose.bones[cadena_fin].constraints.new('IK')
        c.target = arm; c.subtarget = obj; c.chain_count = 2; c.use_stretch = False; c.name = "IK"
        c2 = arm.pose.bones[punta].constraints.new('COPY_ROTATION')
        c2.target = arm; c2.subtarget = obj; c2.target_space = 'POSE'; c2.owner_space = 'POSE'; c2.name = "rot"
for pb in arm.pose.bones:
    pb.rotation_mode = 'QUATERNION'
    pb.ik_stretch = 0.0

# ------------------------------------------------------------------ 3. pesos
bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
N = len(P)
vecinos = [[] for _ in range(N)]
for e in bm.edges:
    a, b = e.verts[0].index, e.verts[1].index
    d = (P[a] - P[b]).length
    vecinos[a].append((b, d)); vecinos[b].append((a, d))
piezas = C.componentes(cuerpo)
principal = set(piezas[0][3])
seg = {n: (h, t) for n, h, t, _, _ in HUESOS}


def dist_seg(p, h, t):
    ab = t - h
    u = max(0.0, min(1.0, (p - h).dot(ab) / ab.length_squared))
    return (p - (h + ab * u)).length, u


cadena_de = {}
for cad, hs in CADENAS.items():
    for h in hs:
        cadena_de[h] = cad
# semillas: para muestras a lo largo de cada hueso de cadena, los vértices más cercanos (a ≤ 1 cm del más cercano)
fuentes = []
idx_principal = sorted(principal)
for cad, hs in CADENAS.items():
    for hnom in hs:
        h, t = seg[hnom]
        for k in range(1, 10):
            q = h.lerp(t, k / 10.0)
            ds = [((P[i] - q).length, i) for i in idx_principal]
            dmin = min(ds)[0]
            for d, i in ds:
                if d <= dmin + 0.01:
                    fuentes.append((0.0, i, cad))
etiqueta = [None] * N
dist = [1e9] * N
heap = []
for d, i, cad in fuentes:
    if d < dist[i]:
        dist[i] = d; etiqueta[i] = cad
        heapq.heappush(heap, (d, i, cad))
while heap:
    d, i, cad = heapq.heappop(heap)
    if d > dist[i] or etiqueta[i] != cad:
        continue
    for j, w in vecinos[i]:
        nd = d + w
        if nd < dist[j]:
            dist[j] = nd; etiqueta[j] = cad
            heapq.heappush(heap, (nd, j, cad))
# piezas sueltas: las rodilleras, a la pierna de su lado
sueltas = []
for pz in piezas[1:]:
    cx = sum(P[i].x for i in pz[3]) / len(pz[3])
    s = "L" if cx > 0 else "R"
    sueltas.append({"vertices": len(pz[3]), "lado": s})
    for i in pz[3]:
        etiqueta[i] = "suelta_" + s


def smooth(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


pesos = [dict() for _ in range(N)]
for i in range(N):
    p = P[i]
    cad = etiqueta[i]
    if cad is None:
        pesos[i] = {"pecho": 1.0}
        continue
    if cad.startswith("suelta_"):
        pesos[i] = {"pierna." + cad[-1]: 1.0}
        continue
    xf = p.x / K; zf = p.z / K + Z0_FBX
    if cad == "tronco" or cad.startswith("pierna."):
        if zf < Z_CINTURON_FBX and abs(xf) >= ANCHO_ENTREPIERNA_FBX:
            cad = "pierna." + ("L" if xf > 0 else "R")
        elif zf < Z_CINTURON_FBX and cad.startswith("pierna.") and zf > -0.13 and abs(xf) < ANCHO_ENTREPIERNA_FBX:
            cad = "tronco"
        etiqueta[i] = cad
    hs = CADENAS[cad]
    if cad == "tronco" and abs(xf) >= ANCHO_CUELLO_FBX:
        hs = hs[:3]
    actual = hs[0]
    w = {actual: 1.0}
    for k in range(1, len(hs)):
        hijo = hs[k]; padre = hs[k - 1]
        base = hijo.split(".")[0]
        h0, t0 = seg[padre]; h1, t1 = seg[hijo]
        n = ((t0 - h0).normalized() + (t1 - h1).normalized()).normalized()
        J0 = h1 + (t1 - h1).normalized() * DESPL.get(base, 0.0)
        s = (p - J0).dot(n)
        r = RADIO.get(base, 0.03)
        if s > -r:
            f = smooth(-r, r, s)
            w = {padre: 1.0 - f, hijo: f}
        else:
            break
    # cadera / muslo: los vértices de la pierna por encima del plano de la cadera van a la cadera (con mezcla)
    if cad.startswith("pierna."):
        hm, tm = seg[hs[0]]
        n = (tm - hm).normalized()
        s = (p - (hm + n * DESPL["muslo"])).dot(n)
        r = RADIO["muslo"]
        if s < r and list(w.keys())[0] == hs[0] and len(w) == 1:
            f = smooth(-r, r, s)
            w = {"cadera": 1.0 - f, hs[0]: f}
    pesos[i] = {k: v for k, v in w.items() if v > 1e-4}

# hombreras: la placa sobre cada hombro (dentro de una caja medida en p0), rígida a su hueso
for i in range(N):
    p = P[i]
    for s, sx in (("L", 1), ("R", -1)):
        x = p.x * sx / K; y = p.y / K; z = p.z / K + Z0_FBX
        if 0.12 <= x <= 0.27 and -0.06 <= y <= 0.13 and z >= 0.235 and etiqueta[i] in ("tronco", "brazo." + s):
            # por encima de la bola del brazo: la placa (y no el bíceps)
            if z >= 0.235 + max(0.0, (x - 0.21)) * 0.6:
                pesos[i] = {"hombrera." + s: 1.0}

# grupos de vértices
for n, _, _, _, deforma in HUESOS:
    if deforma:
        cuerpo.vertex_groups.new(name=n)
maxinf = 0
for i in range(N):
    tot = sum(pesos[i].values())
    maxinf = max(maxinf, len(pesos[i]))
    for b, v in pesos[i].items():
        cuerpo.vertex_groups[b].add([i], v / tot, 'REPLACE')
mod = cuerpo.modifiers.new("esqueleto", 'ARMATURE')
mod.object = arm
cuerpo.parent = arm
cuerpo.matrix_parent_inverse = Matrix.Identity(4)
bm.free()
cuenta = {}
for i in range(N):
    for b in pesos[i]:
        cuenta[b] = cuenta.get(b, 0) + 1
deformantes = [n for n, _, _, _, d in HUESOS if d]
info = {"alto_m": round(zmax - zmin, 4), "escala_desde_fbx": round(K, 5), "vertices": N, "triangulos": C.tris(cuerpo),
        "huesos_exportables": len(HUESOS), "deformantes": len(deformantes), "controles_autoria": [c[0] for c in CONTROLES],
        "max_influencias": maxinf, "vertices_por_hueso": cuenta, "piezas_sueltas": sueltas,
        "sin_region": sum(1 for e in etiqueta if e is None)}
print("RIG", json.dumps(info, ensure_ascii=False))
json.dump(info, open(os.path.splitext(BLEND)[0] + "_rig.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
bpy.ops.wm.save_as_mainfile(filepath=BLEND)

# ------------------------------------------------------------------ 4. renders: pesos por color y poses de esfuerzo
if SIN_RENDER:
    print("FIN"); sys.exit(0)
os.makedirs(REND, exist_ok=True)
BASE = {"cadera": (0.9, 0.15, 0.15), "columna": (0.95, 0.85, 0.1), "pecho": (0.2, 0.35, 0.95), "cuello": (0.1, 0.85, 0.85),
        "cabeza": (0.85, 0.2, 0.85), "hombrera": (1.0, 0.55, 0.0), "brazo": (0.15, 0.75, 0.2), "antebrazo": (0.55, 0.3, 0.1),
        "mano": (0.95, 0.95, 0.95), "muslo": (0.15, 0.75, 0.2), "pierna": (0.55, 0.3, 0.1), "pie": (0.95, 0.95, 0.95),
        "punta": (0.1, 0.1, 0.1)}
COLORES = {}
for n in deformantes:
    c = BASE[n.split(".")[0]]
    COLORES[n] = tuple(x * 0.6 for x in c) if n.endswith(".R") else c   # la derecha, más oscura
ca = me.color_attributes.new("pesos_vista", 'FLOAT_COLOR', 'POINT')
for i in range(N):
    c = Vector((0, 0, 0))
    tot = sum(pesos[i].values())
    for b, v in pesos[i].items():
        c += Vector(COLORES[b]) * (v / tot)
    ca.data[i].color = (c.x, c.y, c.z, 1)
mv = bpy.data.materials.new("vista_pesos"); mv.use_nodes = True
nt = mv.node_tree
bsdf = nt.nodes["Principled BSDF"]
atr = nt.nodes.new('ShaderNodeAttribute'); atr.attribute_name = "pesos_vista"
nt.links.new(atr.outputs["Color"], bsdf.inputs["Base Color"])
me.materials[0] = mv
C.render_vistas(os.path.join(REND, "p2_pesos"), 1.95, res=700)
me.materials[0] = mat
C.suelo(0.0)


def rot_mundo(pb, ejes_grados):
    """Rotación (grados, ejes del mundo XYZ) convertida al espacio local del hueso en reposo."""
    from mathutils import Euler
    q = Euler([math.radians(a) for a in ejes_grados], 'XYZ').to_quaternion()
    R = pb.bone.matrix_local.to_quaternion()
    return R.inverted() @ q @ R


def mover(pb, delta):
    R = pb.bone.matrix_local.to_3x3()
    return R.inverted() @ Vector(delta)


# pose de esfuerzo: la de la Prensa (puños arriba) y la de la descarga (agachado, brazos al suelo, rodillas flexionadas)
pbs = arm.pose.bones
for nombre, pose in [
    ("p2_estres_arriba", {"cadera": ((0, 0, -0.08), (-6, 0, 0)), "pecho": (-8, 0, 0), "clav": 18,
                           "mano": ((0.12, 0.25, 0.95), (0, 0, 0)), "hombrera": 25}),
    ("p2_estres_abajo", {"cadera": ((0, 0.1, -0.24), (25, 0, 0)), "columna": (18, 0, 0), "pecho": (18, 0, 0), "clav": -5,
                          "mano": ((-0.02, -0.55, -0.62), (60, 0, 0)), "hombrera": 0}),
    ("p2_estres_paso", {"cadera": ((0.03, 0, -0.04), (0, 0, 6)), "pie": ((0, -0.32, 0.0), (0, 0, 0)),
                         "pie2": ((0, 0.25, 0.14), (-25, 0, 0)), "mano": ((0, 0.12, 0), (0, 0, 0))}),
]:
    for pb in pbs:
        pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
    loc, rot = pose["cadera"]
    pbs["cadera"].location = mover(pbs["cadera"], loc)
    pbs["cadera"].rotation_quaternion = rot_mundo(pbs["cadera"], rot)
    for b in ("columna", "pecho"):
        if b in pose:
            pbs[b].rotation_quaternion = rot_mundo(pbs[b], pose[b])
    for s, sx in (("L", 1), ("R", -1)):
        if "clav" in pose:
            pbs["clavicula." + s].rotation_quaternion = rot_mundo(pbs["clavicula." + s], (0, -pose["clav"] * sx, 0))
        if "hombrera" in pose:
            pbs["hombrera." + s].rotation_quaternion = rot_mundo(pbs["hombrera." + s], (0, -pose["hombrera"] * sx, 0))
        if "mano" in pose:
            (dx, dy, dz), r = pose["mano"]
            pbs["ik_mano." + s].location = mover(pbs["ik_mano." + s], (dx * sx, dy, dz))
            pbs["ik_mano." + s].rotation_quaternion = rot_mundo(pbs["ik_mano." + s], r)
        if "pie" in pose:
            (dx, dy, dz), r = pose["pie"] if s == "L" else pose["pie2"]
            pbs["ik_pie." + s].location = mover(pbs["ik_pie." + s], (dx * sx, dy, dz))
            pbs["ik_pie." + s].rotation_quaternion = rot_mundo(pbs["ik_pie." + s], r)
    bpy.context.view_layer.update()
    C.render_vistas(os.path.join(REND, nombre), 1.95, res=600)
for pb in pbs:
    pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0)
C.render_vistas(os.path.join(REND, "p2_reposo"), 1.95, res=600)
print("FIN")
