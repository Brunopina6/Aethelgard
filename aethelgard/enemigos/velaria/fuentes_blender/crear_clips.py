# Velaria (T-097, bestiario 01): crea en Blender los clips nuevos y exporta el GLB completo para el juego.
#
#   blender -b <copia de velaria.blend> --factory-startup -P crear_clips.py -- <salida.blend> <salida.glb>
#
# Fuente: velaria.blend del bestiario del usuario (D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\, D-075). Se
# trabaja SIEMPRE sobre una copia: este guion guarda el resultado en <salida.blend> y no toca el archivo abierto.
# Es el mismo método que el de Zarzalín y el de Cencerrante (enemigos/*/fuentes_blender/crear_clips.py).
#
# Los cuatro clips del usuario (reposo, destello_de_velo, corte_de_ala y recibir_golpe) no se tocan. Se añaden:
#   aviso_espera  en bucle: las alas replegadas concentrando la luz (la pose del destello en su fotograma 17), mientras
#                 espera su turno para soltarla; desde ella el combate sigue el destello en su segundo 0,533
#   derrota       las alas dejan de batir, cae al suelo de lado y se queda con las alas caídas
#   entrada       llega volando desde atrás y desde arriba, batiendo las alas, y queda flotando en su reposo
#   correr        en bucle: aleteo rápido inclinada hacia delante (para acercarse al objetivo y volver)
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X (huesos .L). En Godot mira a +Z. Vuela: en el reposo la raíz
# está 0,23 m por encima del suelo. Signos medidos: ala .L girada +Y baja la punta (en .R, -Y); raíz +X la inclina hacia
# delante; raíz +Y la tumba sobre su costado izquierdo (+X).
# Exporta con export_anim_slide_to_zero: el fotograma 1 es el segundo 0 (el destello sale en el fotograma 22 = 0,70 s;
# el corte de ala golpea en el 16 = 0,50 s, los valores de la ficha).
import bpy, sys, math
from mathutils import Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SALIDA_BLEND, SALIDA_GLB = argv[0], argv[1]

arm = bpy.data.objects["velaria"]
malla = bpy.data.objects["velaria_malla"]
ad = arm.animation_data
sc = bpy.context.scene
HUESOS = [b.name for b in arm.data.bones]
REPOSO_ROT = {b.name: b.matrix_local.to_quaternion() for b in arm.data.bones}
X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)


def curvas(accion):
    """F-curves de una acción (Blender 5: capas, tiras y bolsas de canales por ranura)."""
    res = []
    for capa in accion.layers:
        for tira in capa.strips:
            for bolsa in tira.channelbags:
                res += list(bolsa.fcurves)
    return res


def pose_de(nombre, frame):
    """Pose (hueso -> [loc, quat]) de una acción del usuario en un fotograma."""
    p = {h: [Vector((0, 0, 0)), Quaternion((1, 0, 0, 0))] for h in HUESOS}
    for fc in curvas(bpy.data.actions[nombre]):
        if '"' not in fc.data_path:
            continue
        h = fc.data_path.split('"')[1]
        v = fc.evaluate(frame)
        if fc.data_path.endswith("rotation_quaternion"):
            p[h][1][fc.array_index] = v
        elif fc.data_path.endswith("location"):
            p[h][0][fc.array_index] = v
    for h in HUESOS:
        p[h][1].normalize()
    return p


def copia(p):
    return {h: [l.copy(), q.copy()] for h, (l, q) in p.items()}


def girar(p, hueso, eje, grados):
    """Gira un hueso alrededor de un eje del esqueleto (en el marco de su padre)."""
    r = REPOSO_ROT[hueso]
    d = r.inverted() @ Quaternion(Vector(eje), math.radians(grados)) @ r
    p[hueso][1] = d @ p[hueso][1]
    return p


def mover(p, hueso, v):
    """Desplaza un hueso (en metros, ejes del esqueleto)."""
    p[hueso][0] = p[hueso][0] + REPOSO_ROT[hueso].inverted() @ Vector(v)
    return p


def poner(p):
    ad.action = None
    for h, (l, q) in p.items():
        pb = arm.pose.bones[h]
        pb.location = l
        pb.rotation_quaternion = q
        pb.scale = (1, 1, 1)
    bpy.context.view_layer.update()


def suelo(p):
    """Altura del punto más bajo de la malla deformada con la pose p."""
    poner(p)
    dg = bpy.context.evaluated_depsgraph_get()
    ev = malla.evaluated_get(dg)
    me = ev.to_mesh()
    mw = ev.matrix_world
    bajo = min((mw @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    return bajo


def apoyar(p, despegue=0.0):
    """Sube o baja la raíz para que lo más bajo toque el suelo (+ despegue en el aire)."""
    b = suelo(p)
    return mover(p, "root", (0, 0, -b + despegue))


def con(p, cambios, despegue=None):
    """Copia de p con giros [(hueso, eje, grados)...] y movimientos [('mover', hueso, v)...]; si despegue no es
    None, apoya la raíz en el suelo (+ despegue)."""
    q = copia(p)
    for c in cambios:
        if c[0] == "mover":
            mover(q, c[1], c[2])
        else:
            girar(q, c[0], c[1], c[2])
    if despegue is not None:
        apoyar(q, despegue)
    return q



def alas(arriba=0.0, atras=0.0, abajo_extra=0.0):
    """Las cuatro alas: «arriba» grados hacia arriba (negativo: hacia abajo), «atras» las pliega hacia atrás."""
    res = [("wing_top.L", Y, -arriba), ("wing_top.R", Y, arriba),
           ("wing_bottom.L", Y, -arriba * 0.6 + abajo_extra), ("wing_bottom.R", Y, arriba * 0.6 - abajo_extra)]
    if atras:
        res += [("wing_top.L", Z, atras), ("wing_top.R", Z, -atras),
                ("wing_bottom.L", Z, atras * 0.6), ("wing_bottom.R", Z, -atras * 0.6)]
    return res


# ---------------------------------------------------------------- poses base
for t in ad.nla_tracks:
    t.mute = True
REPOSO = pose_de("reposo", 1)
PLEGADA = pose_de("destello_de_velo", 17)       # las alas replegadas concentrando la luz (antes de soltarla)
clips = {}

# ---------------------------------------------------------------- espera con la luz concentrada (en bucle)
clips["aviso_espera"] = [
    (1, PLEGADA),
    (9, con(PLEGADA, [("mover", "root", (0, 0, 0.015))] + alas(2), None)),
    (16, con(PLEGADA, [("mover", "root", (0, 0, 0.022)), ("head", X, -3)] + alas(-2), None)),
    (24, con(PLEGADA, [("mover", "root", (0, 0, 0.008))] + alas(1.5), None)),
    (31, PLEGADA),
]

# ---------------------------------------------------------------- correr (aleteo rápido, en bucle)
VUELO = con(REPOSO, [("root", X, 12), ("head", X, -8)], None)
clips["correr"] = [
    (1, con(VUELO, alas(28), None)),
    (4, con(VUELO, [("mover", "root", (0, 0, 0.03))] + alas(0), None)),
    (7, con(VUELO, [("mover", "root", (0, 0, 0.02))] + alas(-26, 0, 8), None)),
    (10, con(VUELO, [("mover", "root", (0, 0, -0.01))] + alas(0), None)),
    (13, con(VUELO, alas(28), None)),
]

# ---------------------------------------------------------------- entrada (llega volando desde atrás y arriba)
clips["entrada"] = [
    (1, con(REPOSO, [("mover", "root", (0, 0.85, 0.55)), ("root", X, 15)] + alas(30), None)),
    (6, con(REPOSO, [("mover", "root", (0, 0.68, 0.42)), ("root", X, 14)] + alas(-28, 0, 8), None)),
    (11, con(REPOSO, [("mover", "root", (0, 0.48, 0.30)), ("root", X, 12)] + alas(30), None)),
    (16, con(REPOSO, [("mover", "root", (0, 0.26, 0.18)), ("root", X, 8)] + alas(-28, 0, 8), None)),
    (21, con(REPOSO, [("mover", "root", (0, 0.08, 0.08)), ("root", X, -4)] + alas(26), None)),
    (26, con(REPOSO, [("mover", "root", (0, 0, 0.02)), ("root", X, -6)] + alas(-18, 0, 5), None)),
    (31, con(REPOSO, [("root", X, -2)] + alas(8), None)),
    (37, REPOSO),
]

# ---------------------------------------------------------------- derrota (cae al suelo de lado)
LADO = (0, 1, 0)       # alrededor de Y, positivo: se tumba sobre su costado izquierdo (+X)
clips["derrota"] = [
    (1, REPOSO),
    (4, con(REPOSO, [("root", X, -12), ("head", X, -15), ("mover", "root", (0, 0.04, 0.03))] + alas(35), None)),
    (9, con(REPOSO, [("root", X, -4), ("root", LADO, 20), ("mover", "root", (0, 0.05, -0.08))] + alas(-30, 10, 10), None)),
    (14, con(REPOSO, [("root", LADO, 55), ("root", X, 6), ("mover", "root", (0.08, 0.05, 0))] + alas(-45, 20, 15), 0.0)),
    (17, con(REPOSO, [("root", LADO, 80), ("root", X, 4), ("mover", "root", (0.12, 0.05, 0))] + alas(-20, 25, 10), 0.03)),
    (20, con(REPOSO, [("root", LADO, 84), ("root", X, 4), ("mover", "root", (0.13, 0.05, 0))] + alas(-35, 25, 12), 0.0)),
    (26, con(REPOSO, [("root", LADO, 86), ("root", X, 3), ("head", X, 10), ("mover", "root", (0.13, 0.05, 0))]
             + alas(-30, 28, 12), 0.0)),
    (31, con(REPOSO, [("root", LADO, 86), ("root", X, 3), ("head", X, 12), ("mover", "root", (0.13, 0.05, 0))]
             + alas(-26, 28, 12), 0.0)),
    (36, con(REPOSO, [("root", LADO, 86), ("root", X, 3), ("head", X, 12), ("mover", "root", (0.13, 0.05, 0))]
             + alas(-28, 28, 12), 0.0)),
]

# ---------------------------------------------------------------- crear las acciones
def crear_accion(nombre, claves):
    if nombre in bpy.data.actions:
        bpy.data.actions.remove(bpy.data.actions[nombre])
    act = bpy.data.actions.new(nombre)
    act.use_fake_user = True
    ad.action = act
    previo = {}
    for f, p in claves:
        for h, (l, q) in p.items():
            pb = arm.pose.bones[h]
            q = q.copy()
            if h in previo and previo[h].dot(q) < 0:      # el mismo giro por el camino corto
                q.negate()
            previo[h] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f, group=h)
            if h == "root":
                pb.location = l
                pb.keyframe_insert("location", frame=f, group=h)
    for fc in curvas(act):
        for k in fc.keyframe_points:
            k.interpolation = 'BEZIER'
    ad.action = None
    pista = ad.nla_tracks.new()
    pista.name = nombre
    pista.strips.new(nombre, int(claves[0][0]), act)
    pista.mute = True
    return act


for nombre, claves in clips.items():
    a = crear_accion(nombre, claves)
    print("CLIP", nombre, "fotogramas", [c[0] for c in claves], "ranuras", [s.identifier for s in a.slots],
          "curvas", len(curvas(a)))

# deja el modelo en reposo, sin acción activa, y guarda la copia
ad.action = None
poner(REPOSO)
for t in ad.nla_tracks:
    t.mute = False
bpy.ops.wm.save_as_mainfile(filepath=SALIDA_BLEND, copy=True)
print("GUARDADO", SALIDA_BLEND)

bpy.ops.export_scene.gltf(
    filepath=SALIDA_GLB, export_format='GLB', use_selection=False,
    export_animations=True, export_animation_mode='ACTIONS', export_force_sampling=True,
    export_anim_slide_to_zero=True, export_image_format='AUTO', export_def_bones=False,
    export_reset_pose_bones=True, export_skins=True, export_yup=True)
print("EXPORTADO", SALIDA_GLB)
