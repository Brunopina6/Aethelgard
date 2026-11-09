# Zarzalín (T-097): crea en Blender los clips nuevos y exporta el GLB completo para el juego.
#
#   blender -b <copia de zarzalin.blend> --factory-startup -P crear_clips.py -- <salida.blend> <salida.glb>
#
# Fuente: zarzalin.blend del bestiario del usuario (D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\, D-075). Se
# trabaja SIEMPRE sobre una copia: este guion guarda el resultado en <salida.blend> y no toca el archivo abierto.
#
# Los cuatro clips del usuario (reposo, embestida_espinosa, colmillo_lateral y recibir_golpe) no se tocan. Se añaden:
#   derrota          cae de lado (hacia su izquierda: patas y vientre hacia la cámara del combate) y se queda quieto
#   entrada          salta a su sitio desde 0,85 m por detrás, sacude la cabeza, da un pisotón y queda en reposo
#   aviso_embestida  baja el hocico (la pose de carga) y da dos golpes de pezuña con la pata delantera derecha
#   aviso_espera     en bucle: la pose de carga respirando, mientras espera su turno para embestir
#   correr           en bucle: galope en el sitio, para acercarse al objetivo y volver
# La pose de carga es la del fotograma 13 de embestida_espinosa (retrocede y se agacha) con el hocico 22° más bajo:
# desde ella el combate puede seguir la embestida en su segundo 0,4 sin un salto de pose.
#
# Ejes (Blender): el jabalí mira a -Y, Z arriba, su izquierda es +X (huesos .L). En Godot mira a +Z.
# Cada pose se escribe como giros alrededor de ejes del esqueleto aplicados sobre una pose base (el reposo o un
# fotograma de un clip del usuario). La altura de la raíz se calcula para que lo más bajo de la malla toque el suelo
# (más un despegue en las poses en el aire): los pies quedan apoyados sin hundirse.
# Exporta con export_anim_slide_to_zero: el fotograma 1 es el segundo 0, como en las fichas (impacto de la embestida
# en el fotograma 18 = 0,567 s; del colmillo, en el 15 = 0,467 s). El GLB del usuario empezaba cada clip en 1/30 s.
import bpy, sys, math
from mathutils import Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SALIDA_BLEND, SALIDA_GLB = argv[0], argv[1]

arm = bpy.data.objects["zarzalin"]
malla = bpy.data.objects["zarzalin_malla"]
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


def patas(delante=0.0, delante_bajo=0.0, detras=0.0, detras_bajo=0.0, lados=("L", "R"), dif=0.0):
    """Giros de las patas alrededor de X (positivo: la punta va hacia atrás)."""
    res = []
    for i, s in enumerate(lados):
        k = dif if i == 1 else 0.0
        if delante:
            res.append(("front_upper." + s, X, delante + k))
        if delante_bajo:
            res.append(("front_lower." + s, X, delante_bajo + k))
        if detras:
            res.append(("hind_upper." + s, X, detras + k))
        if detras_bajo:
            res.append(("hind_lower." + s, X, detras_bajo + k))
    return res


# ---------------------------------------------------------------- poses base
for t in ad.nla_tracks:
    t.mute = True
REPOSO = pose_de("reposo", 1)
F13 = pose_de("embestida_espinosa", 13)        # el jabalí ya ha retrocedido y se ha agachado
CARGA = con(F13, [("head", X, 22), ("body", X, 4), ("tail", X, -25)])           # hocico bajo, cola alzada
CARGA_ALTA = con(CARGA, [("mover", "root", (0, 0, 0.004)), ("head", X, -2)])   # inspira (inicio del bucle)
CARGA_BAJA = con(CARGA, [("mover", "root", (0, 0, -0.012)), ("head", X, 2.5), ("tail", X, -6)])  # espira

clips = {}

# ---------------------------------------------------------------- aviso de la embestida (2 golpes de pezuña)
LEVANTA = [("front_upper.R", X, -32), ("front_lower.R", X, 66)]
clips["aviso_embestida"] = [
    (1, REPOSO),
    (9, CARGA),
    (12, con(CARGA, LEVANTA + [("head", X, 2)])),
    (15, con(CARGA, [("mover", "root", (0, 0, -0.012)), ("head", X, 3)])),      # 1.er golpe (0,467 s)
    (17, CARGA),
    (20, con(CARGA, LEVANTA + [("head", X, 2)])),
    (23, con(CARGA, [("mover", "root", (0, 0, -0.012)), ("head", X, 3)])),      # 2.º golpe (0,733 s)
    (26, con(CARGA, [("head", X, -3)])),
    (30, CARGA_ALTA),
]
clips["aviso_espera"] = [(1, CARGA_ALTA), (16, CARGA_BAJA), (31, CARGA_ALTA)]

# ---------------------------------------------------------------- derrota
GIRO_LADO = Y          # alrededor del eje largo: positivo, cae sobre su costado izquierdo (+X)
clips["derrota"] = [
    (1, REPOSO),
    (4, con(REPOSO, [("head", X, -12), ("body", X, -4), ("mover", "root", (0, 0.03, 0))], 0.0)),
    (9, con(REPOSO, [("body", X, 14), ("head", X, 10)] + patas(-10, 80, 0, -10), 0.0)),
    (14, con(REPOSO, [("root", GIRO_LADO, 30), ("mover", "root", (-0.08, 0, 0)), ("body", X, 10), ("head", X, 8)]
             + patas(-6, 70, -15, 25), 0.0)),
    (19, con(REPOSO, [("root", GIRO_LADO, 86), ("mover", "root", (-0.27, 0, 0)), ("body", X, 2), ("head", Z, 10)]
             + patas(-25, 20, -30, 15, dif=6), 0.0)),
    (22, con(REPOSO, [("root", GIRO_LADO, 80), ("mover", "root", (-0.25, 0, 0)), ("body", X, 2), ("head", Z, 6)]
             + patas(-28, 16, -33, 12, dif=6), 0.035)),
    (26, con(REPOSO, [("root", GIRO_LADO, 88), ("mover", "root", (-0.27, 0, 0)), ("body", X, 2), ("head", Z, 12)]
             + patas(-22, 24, -28, 18, dif=6) + [("tail", X, 10)], 0.0)),
    (31, con(REPOSO, [("root", GIRO_LADO, 88), ("mover", "root", (-0.27, 0, 0)), ("body", X, 0), ("head", Z, 11),
                      ("head", X, -3)] + patas(-22, 24, -28, 18, dif=6) + [("tail", X, 8)], 0.008)),
    (36, con(REPOSO, [("root", GIRO_LADO, 89), ("mover", "root", (-0.27, 0, 0)), ("body", X, 2), ("head", Z, 13)]
             + patas(-20, 32, -26, 22, dif=6) + [("tail", X, 16)], 0.0)),
]

# ---------------------------------------------------------------- entrada (salta a su sitio desde atrás)
clips["entrada"] = [
    (1, con(REPOSO, [("mover", "root", (0, 0.85, 0)), ("body", X, -6), ("head", X, -10)] + patas(-10, 30, -15, 25), 0.0)),
    (6, con(REPOSO, [("mover", "root", (0, 0.72, 0)), ("body", X, -10), ("head", X, -6)] + patas(-30, 60, 25, 5), 0.0)),
    (11, con(REPOSO, [("mover", "root", (0, 0.38, 0)), ("body", X, 0)] + patas(-40, 10, 35, -5), 0.20)),
    (15, con(REPOSO, [("mover", "root", (0, 0.04, 0)), ("body", X, 8), ("head", X, 4)] + patas(-12, 0, 20, 0), 0.0)),
    (18, con(REPOSO, [("mover", "root", (0, -0.01, 0)), ("body", X, 3), ("head", X, 6)] + patas(-8, 15, -5, 10), 0.0)),
    (22, con(REPOSO, [("body", X, -2), ("head", X, -14), ("head", Z, -18)], 0.0)),
    (25, con(REPOSO, [("head", X, -6), ("head", Z, 16)], 0.0)),
    (28, con(REPOSO, [("head", Z, -6)] + LEVANTA, 0.0)),
    (31, con(REPOSO, [("head", X, 4), ("front_upper.R", X, 3)], 0.0)),
    (36, REPOSO),
]

# ---------------------------------------------------------------- correr (galope en el sitio, en bucle)
GALOPE_1 = con(REPOSO, [("head", X, -3)] + patas(-35, -5, 38, 8, dif=4), 0.05)
clips["correr"] = [
    (1, GALOPE_1),
    (5, con(REPOSO, [("body", X, 5), ("head", X, 5)] + patas(-8, 5, 5, 40, dif=6), 0.0)),
    (9, con(REPOSO, [("body", X, -4)] + patas(30, 30, -32, 20, dif=6), 0.0)),
    (13, con(REPOSO, [("body", X, -6), ("head", X, -4)] + patas(-10, 70, 18, 5, dif=5), 0.03)),
    (16, GALOPE_1),
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
