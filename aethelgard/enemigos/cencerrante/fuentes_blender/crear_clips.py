# Cencerrante (T-097, bestiario 01): crea en Blender los clips nuevos y exporta el GLB completo para el juego.
#
#   blender -b <copia de cencerrante.blend> --factory-startup -P crear_clips.py -- <salida.blend> <salida.glb>
#
# Fuente: cencerrante.blend del bestiario del usuario (D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\, D-075). Se
# trabaja SIEMPRE sobre una copia: este guion guarda el resultado en <salida.blend> y no toca el archivo abierto.
# Es el mismo método que el de Zarzalín (enemigos/zarzalin/fuentes_blender/crear_clips.py).
#
# Los cuatro clips del usuario (reposo, toque_de_alarma, campanada_baja y recibir_golpe) no se tocan. Se añaden:
#   derrota   las patas ceden, la campana da un último golpe y el marco cae de espaldas (lejos de los héroes)
#   entrada   llega a su sitio en dos saltos desde 0,85 m por detrás, la campana se balancea y queda en reposo
#   correr    en bucle: anda a saltitos en el sitio, una pata y otra, con la campana meciéndose (para acercarse)
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X (huesos .L). En Godot mira a +Z. Signos medidos en el
# esqueleto: muslo +X lleva el pie atrás y arriba; espinilla +X dobla la rodilla hacia atrás; raíz -X lo echa de
# espaldas (+Y); campana +X manda el badajo atrás.
# Cada pose son giros alrededor de ejes del esqueleto sobre una pose base, y la raíz se apoya para que lo más bajo de la
# malla toque el suelo (más un despegue en el aire). Exporta con export_anim_slide_to_zero: el fotograma 1 es el
# segundo 0 (repique del toque en el fotograma 23 = 0,733 s; golpe de la campanada en el 17 = 0,533 s).
import bpy, sys, math
from mathutils import Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SALIDA_BLEND, SALIDA_GLB = argv[0], argv[1]

arm = bpy.data.objects["cencerrante"]
malla = bpy.data.objects["cencerrante_malla"]
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



def paso(lado, alto=1.0):
    """Levanta una pata hacia delante: muslo adelante, rodilla doblada y punta arriba."""
    return [("thigh." + lado, X, -20 * alto), ("shin." + lado, X, 38 * alto), ("foot." + lado, X, -12 * alto)]


def agachar(cuanto=1.0):
    """Dobla las dos patas (las rodillas adelante): para tomar impulso y para caer de un salto."""
    res = []
    for s in ("L", "R"):
        res += [("thigh." + s, X, -16 * cuanto), ("shin." + s, X, 30 * cuanto), ("foot." + s, X, -12 * cuanto)]
    return res


def recoger(cuanto=1.0):
    """Patas recogidas en el aire."""
    res = []
    for s in ("L", "R"):
        res += [("thigh." + s, X, -22 * cuanto), ("shin." + s, X, 50 * cuanto), ("foot." + s, X, 10 * cuanto)]
    return res


# ---------------------------------------------------------------- poses base
for t in ad.nla_tracks:
    t.mute = True
REPOSO = pose_de("reposo", 1)
clips = {}

# ---------------------------------------------------------------- correr (a saltitos en el sitio, en bucle)
clips["correr"] = [
    (1, con(REPOSO, paso("L") + [("bell", X, 8), ("body", Y, 3)], 0.03)),
    (5, con(REPOSO, agachar(0.35) + [("bell", X, 2)], 0.0)),
    (9, con(REPOSO, paso("R") + [("bell", X, -8), ("body", Y, -3)], 0.03)),
    (13, con(REPOSO, agachar(0.35) + [("bell", X, -2)], 0.0)),
    (17, con(REPOSO, paso("L") + [("bell", X, 8), ("body", Y, 3)], 0.03)),
]

# ---------------------------------------------------------------- entrada (dos saltos desde atrás)
clips["entrada"] = [
    (1, con(REPOSO, [("mover", "root", (0, 0.85, 0))] + agachar(1.0) + [("bell", X, -6)], 0.0)),
    (6, con(REPOSO, [("mover", "root", (0, 0.62, 0))] + recoger(1.0) + [("bell", X, 18)], 0.16)),
    (11, con(REPOSO, [("mover", "root", (0, 0.40, 0))] + agachar(1.0) + [("bell", X, -20)], 0.0)),
    (16, con(REPOSO, [("mover", "root", (0, 0.18, 0))] + recoger(0.9) + [("bell", X, 22)], 0.13)),
    (21, con(REPOSO, agachar(1.1) + [("bell", X, -26)], 0.0)),
    (25, con(REPOSO, agachar(0.3) + [("bell", X, 18)], 0.0)),
    (29, con(REPOSO, [("bell", X, -10)], 0.0)),
    (33, con(REPOSO, [("bell", X, 5)], 0.0)),
    (37, REPOSO),
]

# ---------------------------------------------------------------- derrota (cae de espaldas)
ESPALDA = (-1, 0, 0)  # alrededor de -X: el marco se va hacia atrás (+Y), lejos de los héroes
clips["derrota"] = [
    (1, REPOSO),
    (4, con(REPOSO, [("root", ESPALDA, 6), ("bell", X, 24)], 0.0)),
    (9, con(REPOSO, agachar(1.3) + [("root", ESPALDA, 4), ("bell", X, -22)], 0.0)),
    (15, con(REPOSO, agachar(0.8) + [("root", ESPALDA, 40), ("mover", "root", (0, 0.18, 0)), ("bell", X, -35)], 0.0)),
    (20, con(REPOSO, recoger(0.6) + [("root", ESPALDA, 84), ("mover", "root", (0, 0.42, 0)), ("bell", X, 30)], 0.0)),
    (23, con(REPOSO, recoger(0.6) + [("root", ESPALDA, 80), ("mover", "root", (0, 0.42, 0)), ("bell", X, -18)], 0.03)),
    (27, con(REPOSO, recoger(0.5) + [("root", ESPALDA, 87), ("mover", "root", (0, 0.44, 0)), ("bell", X, 12)], 0.0)),
    (31, con(REPOSO, recoger(0.45) + [("root", ESPALDA, 88), ("mover", "root", (0, 0.44, 0)), ("bell", X, -6)], 0.0)),
    (36, con(REPOSO, recoger(0.4) + [("root", ESPALDA, 88), ("mover", "root", (0, 0.44, 0)), ("bell", X, 2)], 0.0)),
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
