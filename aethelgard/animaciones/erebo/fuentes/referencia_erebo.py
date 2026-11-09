# T-101: vídeo de referencia de la invocación nueva de Érebo (≈11,8 s; fallo ≈8,8 s), en Blender 5.2.3 por script.
#   blender -b -P animaciones/erebo/fuentes/referencia_erebo.py -- <carpeta del proyecto> <salida.mp4> [fallo] [rapido]
# Es una «previsualización»: los modelos del juego (Érebo con sus clips de Mixamo, Lya, Kael y Grimfang), la cámara y
# los tiempos de cada plano de docs/erebo/invocacion_erebo_cinematica.md (P1-P11) con las recomendaciones D1-D12 que
# siguen abiertas tomadas como variante: pose quieta al emerger (D7), se acerca flotando 0,3 m (D6), levita 5 cm (D8),
# contacto por detrás del hombro derecho de Érebo (D4). Érebo se coloca POR LA MANO: en el fotograma del contacto, la
# punta de su mano derecha llega al pecho del enemigo (el arreglo medido en la Fase 1, que se conserva).
# Nada del acto III: el orbe no lleva nada dentro, no hay hilos cálidos ni reverencia; el título es «Ladrón de Corazones».
import sys, os, math
sys.dont_write_bytecode = True
import bpy
from mathutils import Vector, Matrix, Euler

a = sys.argv[sys.argv.index("--") + 1:]
P, SALIDA = a[0], a[1]
FALLO = "fallo" in a
RAPIDO = "rapido" in a
FPS = 30


def f(s):
    return int(round(s * FPS)) + 1


bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.fps = FPS


def importar(fbx):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=os.path.join(P, fbx))
    nuevos = [o for o in bpy.data.objects if o not in antes]
    arm = [o for o in nuevos if o.type == 'ARMATURE'][0]
    return arm, [o for o in nuevos if o.type == 'MESH']


def altura(arm):
    bpy.context.view_layer.update()
    zs = [(arm.matrix_world @ b.head_local).z for b in arm.data.bones] + \
         [(arm.matrix_world @ b.tail_local).z for b in arm.data.bones]
    return max(zs) - min(zs), min(zs)


def normalizar(arm, alto):
    h, z0 = altura(arm)
    arm.scale = arm.scale * (alto / h)
    bpy.context.view_layer.update()
    h, z0 = altura(arm)
    arm.location.z -= z0


def accion(fbx, nombre):
    antes = set(bpy.data.objects)
    acts = set(bpy.data.actions)
    bpy.ops.import_scene.fbx(filepath=os.path.join(P, fbx))
    nueva = [x for x in bpy.data.actions if x not in acts][0]
    nueva.name = nombre
    nueva.use_fake_user = True
    for o in [o for o in bpy.data.objects if o not in antes]:
        bpy.data.objects.remove(o, do_unlink=True)
    return nueva


def textura(mallas, ruta):
    img = bpy.data.images.load(os.path.join(P, ruta))
    for m in mallas:
        mat = bpy.data.materials.new("mat_" + m.name)
        nt = mat.node_tree
        bsdf = nt.nodes.get("Principled BSDF")
        tx = nt.nodes.new("ShaderNodeTexImage")
        tx.image = img
        nt.links.new(tx.outputs["Color"], bsdf.inputs["Base Color"])
        m.data.materials.clear()
        m.data.materials.append(mat)


# ---------------------------------------------------------------- personajes (como en el teatro del combate)
U = Vector((1, 0, 0))                    # del enemigo hacia Lya
N = Vector((-1.8, 0.0, 0.0))             # enemigo
L = Vector((1.7, -0.5, 0.0))             # Lya (la cámara del combate está hacia -Y)
K = Vector((2.5, 0.35, 0.0))             # Kael, detrás de Lya

ere, ere_m = importar("erebo_idle.fbx")
textura(ere_m, "erebo_color.png")
normalizar(ere, 1.7 * 1.3)                  # D8: presencia, al menos ×1 (×1,3 frente a un enemigo de 1,7 m)
reposo = ere.animation_data.action
reposo.name = "Reposo"; reposo.use_fake_user = True
ACC = {"Reposo": reposo,
       "Penetrar": accion("erebo_mano_2.fbx", "Penetrar"),
       "Extraer": accion("erebo_coger.fbx", "Extraer"),
       "Alzar": accion("erebo_conjuro.fbx", "Alzar")}

lya, _ = importar("Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx")
normalizar(lya, 1.7 * 0.9)
kael, _ = importar("kael.fbx")
normalizar(kael, 1.7)
gob, _ = importar("goblin.fbx")
normalizar(gob, 1.7)
for o, pos, mira in ((lya, L, -U), (kael, K, -U), (gob, N, U)):
    o.location.x, o.location.y = pos.x, pos.y
    o.rotation_euler = (math.radians(90), 0, math.atan2(mira.y, mira.x) - math.atan2(-1, 0))
for o in (lya, kael, gob):
    if o.animation_data and o.animation_data.action:
        o.animation_data.action = o.animation_data.action     # su reposo de Meshy (primer clip)


def nla(arm, tramos):
    # tramos: [(acción, desde_s_clip, hasta_s_clip, empieza_s, dura_s), ...] con mezcla corta
    arm.animation_data_create()
    arm.animation_data.action = None
    pista = arm.animation_data.nla_tracks.new()
    for i, (nombre, d, h, e, dur) in enumerate(tramos):
        tira = pista.strips.new(nombre + str(i), f(e), ACC[nombre])
        tira.action_frame_start = d * FPS + 1
        tira.action_frame_end = max(h * FPS + 1, d * FPS + 1.01)
        tira.scale = max(0.01, (dur * FPS) / max(tira.action_frame_end - tira.action_frame_start, 0.01))
        tira.extrapolation = 'HOLD_FORWARD'
        tira.blend_in = min(4, (tira.frame_end - tira.frame_start) * 0.4) if i else 0


def evaluar_hueso(arm, hueso, frame):
    sc.frame_set(frame)
    bpy.context.view_layer.update()
    return arm.matrix_world @ arm.pose.bones[hueso].head


# ---------------------------------------------------------------- tiempos (cinematica.md §1; fallo §2)
T = dict(P1=0.0, P2=1.0, P3=1.9, P4=2.5, P5=4.4, P6=5.1, P7=5.9, contacto=6.3, P8=6.8, P9=8.2, P10=9.5, P11=10.2, fin=11.8)
if FALLO:
    T.update(P9=None, P10=None, P11=7.9, fin=9.0)

tramos = [("Reposo", 0.0, 0.0, T["P4"], T["P6"] - T["P4"]),                    # pose quieta (D7)
          ("Extraer", 0.15, 0.80, T["P6"], T["contacto"] - T["P6"]),                # anticipación, estocada abierta y llegada lenta
          ("Extraer", 0.80, 2.4, T["contacto"], 1.6)]                               # contacto (0,80 s), agarra y tira
if not FALLO:
    tramos += [("Alzar", 0.3, 1.0, T["P9"], 0.6), ("Alzar", 1.0, 1.0, T["P9"] + 0.6, T["P11"] - T["P9"] - 0.6),
               ("Alzar", 1.4, 2.4, T["P11"] + 0.3, 1.0)]
else:
    tramos += [("Alzar", 1.4, 2.4, T["P11"] + 0.2, 1.0)]
nla(ere, tramos)

# colocación POR LA MANO: con Érebo en el sitio de partida, dónde cae su mano en el contacto, y se corrige
pecho = evaluar_hueso(gob, "mixamorig:Spine2", 1) + U * 0.12
E1 = N + U * 0.95
ere.location = E1
ere.rotation_euler = (math.radians(90), 0, math.atan2(-U.y, -U.x) - math.atan2(-1, 0))
mano = evaluar_hueso(ere, "mixamorig:RightHandMiddle1", f(T["contacto"]))
corr = Vector((pecho.x - mano.x, pecho.y - mano.y, 0.0))
E1 = E1 + corr
print("POS pecho", tuple(round(x,2) for x in pecho), "mano", tuple(round(x,2) for x in mano), "E1", tuple(round(x,2) for x in E1), "alto_erebo", round(altura(ere)[0],2), "alto_gob", round(altura(gob)[0],2))
print("COLOCACION por la mano: corrección %.3f m (antes la mano quedaba a %.3f m del pecho)" %
      (corr.length, (pecho - mano).length))
E0 = E1 + U * 0.3                         # D6: emerge 0,3 m atrás y se acerca flotando
LEVITA = 0.05                             # D8


def clave_loc(o, t, pos, interp='BEZIER'):
    o.location = pos
    o.keyframe_insert("location", frame=f(t))
    for fc in o.animation_data.action.fcurves if hasattr(o.animation_data.action, "fcurves") else []:
        pass


z0 = ere.location.z
clave_loc(ere, 0.0, Vector((E0.x, E0.y, z0 - 2.0)))
clave_loc(ere, T["P4"], Vector((E0.x, E0.y, z0 - 2.0)))
clave_loc(ere, T["P5"] - 0.1, Vector((E0.x, E0.y, z0 + LEVITA)))
clave_loc(ere, T["P6"], Vector((E0.x, E0.y, z0 + LEVITA)))
clave_loc(ere, T["P6"] + 0.8, Vector((E1.x, E1.y, z0 + LEVITA)))
fin_hundir = T["P11"] + 1.3
E2 = E1 + U * 0.6 if not FALLO else E1     # con el orbe en la mano se aparta flotando del enemigo y lo presenta (P9)
if not FALLO:
    clave_loc(ere, T["P8"] + 0.9, Vector((E1.x, E1.y, z0 + LEVITA)))
    clave_loc(ere, T["P9"] + 0.3, Vector((E2.x, E2.y, z0 + LEVITA)))
clave_loc(ere, T["P11"] + 0.3, Vector((E2.x, E2.y, z0 + LEVITA)))
clave_loc(ere, fin_hundir, Vector((E2.x, E2.y, z0 - 2.0)))

# ---------------------------------------------------------------- reacciones (por objeto: previsualización)
def clave_rot(o, t, rx=0.0, rz_extra=0.0, base=None):
    b = base if base is not None else o["rot0"]
    o.rotation_euler = (b[0] + math.radians(rx), b[1], b[2] + math.radians(rz_extra))
    o.keyframe_insert("rotation_euler", frame=f(t))


for o in (gob, kael, lya):
    o["rot0"] = tuple(o.rotation_euler)
    o["loc0"] = tuple(o.location)
# Grimfang: alerta (P2-P3), arqueo en el contacto, vacío al arrancar, ceniza al estallar
clave_rot(gob, 0.0)
clave_rot(gob, T["P3"], rx=-4)
clave_rot(gob, T["contacto"] - 0.05, rx=-3)
clave_rot(gob, T["contacto"] + 0.1, rx=-14)
clave_rot(gob, T["P8"] + 0.4, rx=8)
if not FALLO:
    clave_rot(gob, T["P10"], rx=8)
    gob.location = gob["loc0"]; gob.keyframe_insert("location", frame=f(T["P10"]))
    gob.location = (gob["loc0"][0], gob["loc0"][1], -1.9); gob.keyframe_insert("location", frame=f(T["P11"] + 1.2))
else:
    clave_rot(gob, T["P11"], rx=2)
# Kael: da medio paso atrás al surgir Érebo y se gira un poco hacia él; al estallar aparta la cara
clave_rot(kael, 0.0)
kael.location = kael["loc0"]; kael.keyframe_insert("location", frame=f(T["P4"]))
kael.location = (kael["loc0"][0] + 0.25, kael["loc0"][1], 0); kael.keyframe_insert("location", frame=f(T["P4"] + 0.6))
clave_rot(kael, T["P4"] + 0.6, rz_extra=-12)
if not FALLO:
    clave_rot(kael, T["P10"], rz_extra=-12)
    clave_rot(kael, T["P10"] + 0.2, rz_extra=25)
    clave_rot(kael, T["fin"], rz_extra=0)
# Lya: se inclina hacia delante al invocar y se yergue al acabar
clave_rot(lya, 0.0)
clave_rot(lya, 0.9, rx=6)
clave_rot(lya, T["P11"] + 0.4, rx=6)
clave_rot(lya, T["fin"], rx=0)

# ---------------------------------------------------------------- orbe, pozo y estallido
def emisivo(nombre, color, fuerza):
    m = bpy.data.materials.new(nombre)
    nt = m.node_tree
    bs = nt.nodes.get("Principled BSDF")
    bs.inputs["Base Color"].default_value = (*color, 1)
    bs.inputs["Emission Color"].default_value = (*color, 1)
    bs.inputs["Emission Strength"].default_value = fuerza
    return m


bpy.ops.mesh.primitive_uv_sphere_add(radius=0.07, segments=24, ring_count=12)
orbe = bpy.context.object
orbe.data.materials.append(emisivo("orbe", (0.55, 0.02, 0.12), 6.0))
bpy.ops.mesh.primitive_circle_add(vertices=48, radius=0.9, fill_type='NGON')
pozo = bpy.context.object
pozo.data.materials.append(emisivo("pozo", (0.06, 0.0, 0.1), 0.5))
pozo.location = (E0.x, E0.y, 0.01)
pozo.keyframe_insert("location", frame=f(T["P9"] or T["P11"]))
if not FALLO:
    pozo.location = (E2.x, E2.y, 0.01); pozo.keyframe_insert("location", frame=f(T["P9"] + 0.3))
pozo.scale = (0.01, 0.01, 1); pozo.keyframe_insert("scale", frame=f(T["P3"]))
pozo.scale = (1, 1, 1); pozo.keyframe_insert("scale", frame=f(T["P4"]))
pozo.keyframe_insert("scale", frame=f(fin_hundir))
pozo.scale = (0.01, 0.01, 1); pozo.keyframe_insert("scale", frame=f(fin_hundir + 0.4))

ojo_mano = "mixamorig:RightHandMiddle1"
if not FALLO:
    # el orbe sale con la mano (agarra a los 1,05 s de «Extraer» = P8) y se lleva ante la máscara en P9
    sc.frame_set(f(T["P8"]))
    # Érebo se vuelve hacia el lado B para presentar el orbe (P9) y el orbe sigue a su mano derecha hasta romperse
    r0 = tuple(ere.rotation_euler)
    ere.keyframe_insert("rotation_euler", frame=f(T["P9"]))
    ere.rotation_euler = (r0[0], r0[1], r0[2] + math.radians(55)); ere.keyframe_insert("rotation_euler", frame=f(T["P9"] + 0.4))
    ere.keyframe_insert("rotation_euler", frame=f(T["P11"] + 0.3))
    for t in [x / FPS for x in range(f(T["P8"]) - 1, f(T["P10"]) + 1)]:
        p = evaluar_hueso(ere, ojo_mano, f(t))
        orbe.location = p; orbe.keyframe_insert("location", frame=f(t))
    ante = evaluar_hueso(ere, ojo_mano, f(T["P10"]))
    orbe.scale = (0.2, 0.2, 0.2); orbe.keyframe_insert("scale", frame=f(T["P8"]))
    orbe.scale = (1, 1, 1); orbe.keyframe_insert("scale", frame=f(T["P8"] + 0.4))
    for k, tb in enumerate((8.55, 8.90, 9.18)):            # tres latidos, cada vez más fuertes
        orbe.scale = (1, 1, 1); orbe.keyframe_insert("scale", frame=f(tb - 0.06))
        s = 1.08 + 0.04 * k
        orbe.scale = (s, s, s); orbe.keyframe_insert("scale", frame=f(tb))
        orbe.scale = (1, 1, 1); orbe.keyframe_insert("scale", frame=f(tb + 0.14))
    orbe.scale = (0.85, 0.85, 0.85); orbe.keyframe_insert("scale", frame=f(T["P10"] - 0.01))
    orbe.scale = (0.0, 0.0, 0.0); orbe.keyframe_insert("scale", frame=f(T["P10"] + 0.09))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.4, minor_radius=0.02)
    onda = bpy.context.object
    onda.data.materials.append(emisivo("onda", (0.7, 0.25, 1.0), 8.0))
    onda.location = ante
    onda.rotation_euler = (0, math.radians(90), 0)
    onda.scale = (0, 0, 0); onda.keyframe_insert("scale", frame=f(T["P10"] + 0.09))
    onda.scale = (0.3, 0.3, 0.3); onda.keyframe_insert("scale", frame=f(T["P10"] + 0.12))
    onda.scale = (4, 4, 4); onda.keyframe_insert("scale", frame=f(T["P10"] + 0.7))
    onda.scale = (0, 0, 0); onda.keyframe_insert("scale", frame=f(T["P10"] + 0.71))
else:
    orbe.scale = (0, 0, 0); orbe.keyframe_insert("scale", frame=1)

# ---------------------------------------------------------------- luz y mundo
w = bpy.data.worlds.new("mundo"); sc.world = w
bg = w.node_tree.nodes.get("Background")
bg.inputs["Color"].default_value = (0.07, 0.05, 0.11, 1)
bg.inputs["Strength"].default_value = 1.0
bg.inputs["Strength"].keyframe_insert("default_value", frame=1)
bg.inputs["Strength"].default_value = 0.45
bg.inputs["Strength"].keyframe_insert("default_value", frame=f(0.7))
bpy.ops.mesh.primitive_plane_add(size=30)
suelo = bpy.context.object
ms = bpy.data.materials.new("suelo")
ms.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (0.2, 0.17, 0.22, 1)
ms.node_tree.nodes.get("Principled BSDF").inputs["Roughness"].default_value = 0.95
suelo.data.materials.append(ms)
sol_d = bpy.data.lights.new("sol", 'SUN'); sol_d.color = (1.0, 0.85, 0.6)
sol = bpy.data.objects.new("sol", sol_d); sc.collection.objects.link(sol)
sol.rotation_euler = (math.radians(50), 0, math.radians(-40))
sol_d.energy = 3.0; sol_d.keyframe_insert("energy", frame=1)
sol_d.energy = 1.6; sol_d.keyframe_insert("energy", frame=f(0.7))
sol_d.keyframe_insert("energy", frame=f(T["fin"] - 0.8))
sol_d.energy = 3.0; sol_d.keyframe_insert("energy", frame=f(T["fin"]))
rim_d = bpy.data.lights.new("contra", 'POINT'); rim_d.color = (1.0, 0.1, 0.25); rim_d.shadow_soft_size = 0.4
rim = bpy.data.objects.new("contra", rim_d); sc.collection.objects.link(rim)
rim.location = (E1.x - 1.2, E1.y + 1.0, 2.0)
rim_d.energy = 0.0; rim_d.keyframe_insert("energy", frame=f(T["P4"]))
rim_d.energy = 120.0; rim_d.keyframe_insert("energy", frame=f(T["P4"] + 1.0))
rim_d.keyframe_insert("energy", frame=f(T["fin"] - 1.0))
rim_d.energy = 0.0; rim_d.keyframe_insert("energy", frame=f(T["fin"]))

# ---------------------------------------------------------------- cámara: un plano por paso (cortes secos entre planos)
cam_d = bpy.data.cameras.new("cam"); cam_d.sensor_width = 36
cam = bpy.data.objects.new("cam", cam_d); sc.collection.objects.link(cam); sc.camera = cam
mira = bpy.data.objects.new("mira", None); sc.collection.objects.link(mira)
c = cam.constraints.new('TRACK_TO'); c.target = mira; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
LADO_A = Vector((0, -1, 0)); LADO_B = Vector((0, 1, 0))


def lente(fov):
    return 18.0 / math.tan(math.radians(fov) / 2)


def plano(t0, t1, pos0, pos1, m0, m1, fov0, fov1=None):
    for (t, p, m, fv) in ((t0, pos0, m0, fov0), (t1 - 1.0 / FPS, pos1, m1, fov1 or fov0)):
        cam.location = p; cam.keyframe_insert("location", frame=f(t))
        mira.location = m; mira.keyframe_insert("location", frame=f(t))
        cam_d.lens = lente(fv); cam_d.keyframe_insert("lens", frame=f(t))


ch = Vector((0, 0, 1))
pe = Vector((pecho.x, pecho.y, pecho.z))
plano(T["P1"], T["P2"], L + LADO_A * 2.4 - U * 0.4 + ch * 1.0, L + LADO_A * 2.1 - U * 0.4 + ch * 1.0,
      L + ch * 1.15, L + ch * 1.2, 40, 36)
plano(T["P2"], T["P3"], L + LADO_A * 0.9 + ch * 0.25, N + U * 1.2 + LADO_A * 0.9 + ch * 0.25,
      L - U * 0.6, N + U * 0.6, 50)
plano(T["P3"], T["P4"], N + LADO_A * 0.7 - U * 0.3 + ch * 0.35, N + LADO_A * 0.7 - U * 0.3 + ch * 0.35,
      E0 + ch * 0.1, E0 + ch * 0.1, 46)
plano(T["P4"], T["P5"], E0 + LADO_A * 2.6 + ch * 0.3, E0 + (LADO_B * 1.2 + U * 0.8).normalized() * 2.6 + ch * 1.2,
      E0 + ch * 0.7, E0 + ch * 1.2, 52)
plano(T["P5"], T["P6"], N + LADO_B * 0.9 - U * 1.6 + ch * 0.9, N + LADO_B * 0.85 - U * 1.5 + ch * 0.9,
      E0 + ch * 1.6, E0 + ch * 1.6, 45)
hombro = E1 + LADO_B * 0.85 + U * 1.35 + ch * 1.55
plano(T["P6"], T["P7"], hombro + U * 0.2, hombro, pe, pe, 34)
plano(T["P7"], T["P8"], hombro, hombro - U * 0.1, pe, pe, 34, 30)
medio = (pe + E1 + ch * 0.9) * 0.5
plano(T["P8"], (T["P9"] or T["P11"]), medio + LADO_B * 2.4 + ch * 0.1, medio + LADO_B * 2.7 + ch * 0.1,
      medio, medio, 38)
if not FALLO:
    sc.frame_set(f(T["P10"]))
    cara = ere.matrix_world.to_3x3() @ Vector((0, 0, 1))                 # hacia dónde mira Érebo (el FBX mira a +Z local)
    dirc = Vector((cara.x, cara.y, 0)).normalized()
    frente = E2 + LADO_A * 2.0 + U * 0.25 + ch * 1.0        # (de frente a la máscara, que se ha vuelto hacia este lado)
    ante = E2 + ch * 0.85
    plano(T["P9"], T["P10"], frente, frente - dirc * 0.1, ante, ante, 34)
    plano(T["P10"], T["P11"], E1 + LADO_A * 3.8 + U * 0.5 + ch * 1.5, E1 + LADO_A * 3.8 + U * 0.5 + ch * 1.5,
          E1 + ch * 0.9, E1 + ch * 0.9, 42)
teatro = Vector((0.6, -5.2, 2.3))
plano(T["P11"], T["fin"] + 1.0 / FPS, N + LADO_A * 2.0 + U * 0.6 + ch * 1.0, teatro,
      N + ch * 0.8, Vector((-0.2, 0, 0.7)), 40)
for o in (cam, mira, cam_d):
    ad = o.animation_data
    acts = [ad.action] if ad and ad.action else []
    for act in acts:
        fcs = list(act.fcurves) if hasattr(act, "fcurves") and len(act.fcurves) else \
            [fc for capa in act.layers for tira in capa.strips for cb in tira.channelbags for fc in cb.fcurves]
        for fc in fcs:
            kps = fc.keyframe_points
            for i, kp in enumerate(kps):
                kp.interpolation = 'BEZIER' if i % 2 == 0 else 'CONSTANT'   # dentro del plano suave; entre planos, corte

# ---------------------------------------------------------------- render
sc.frame_start = 1
sc.frame_end = f(T["fin"])
sc.render.engine = 'BLENDER_EEVEE'
try:
    sc.eevee.taa_render_samples = 4 if RAPIDO else 12
except Exception:
    pass
sc.render.resolution_x, sc.render.resolution_y = (640, 360)
sc.render.resolution_percentage = 100
sc.render.image_settings.media_type = 'VIDEO'
sc.render.image_settings.file_format = 'FFMPEG'
sc.render.ffmpeg.format = 'MPEG4'
sc.render.ffmpeg.codec = 'H264'
sc.render.ffmpeg.constant_rate_factor = 'MEDIUM'
sc.render.use_stamp = True
sc.render.use_stamp_frame = True
sc.render.use_stamp_time = True
sc.render.use_stamp_date = False
sc.render.use_stamp_render_time = False
sc.render.use_stamp_filename = False
sc.render.use_stamp_note = True
sc.render.stamp_note_text = "Erebo nueva (%s) - referencia de camara y tiempos" % ("fallo" if FALLO else "exito")
sc.render.stamp_font_size = 14
FOTOS = next((x[6:] for x in a if x.startswith("fotos=")), "")
if FOTOS:                                  # un fotograma por plano (a la mitad de cada uno), en PNG
    sc.render.image_settings.media_type = 'IMAGE'
    sc.render.image_settings.file_format = 'PNG'
    os.makedirs(FOTOS, exist_ok=True)
    claves = [k for k in ("P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11") if T.get(k) is not None]
    for i, k in enumerate(claves):
        t1 = T[claves[i + 1]] if i + 1 < len(claves) else T["fin"]
        t = T["contacto"] if k == "P7" else (T[k] + t1) * 0.5
        sc.frame_set(f(t))
        sc.render.filepath = os.path.join(FOTOS, "%s_%s_%04.1fs.png" % ("fallo" if FALLO else "exito", k, t))
        bpy.ops.render.render(write_still=True)
    print("FOTOS", FOTOS)
else:
    sc.render.filepath = SALIDA
    bpy.ops.render.render(animation=True)
    print("REFERENCIA", SALIDA, sc.frame_end, "fotogramas")
