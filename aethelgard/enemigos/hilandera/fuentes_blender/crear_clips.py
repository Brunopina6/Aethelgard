# Hilandera del Eco (T-097, bestiario 01; D-075): crea en Blender los clips nuevos y exporta el GLB completo para el juego.
#
#   blender -b <copia de hilandera_eco.blend> --factory-startup -P crear_clips.py -- <salida.blend> <salida.glb>
#
# Fuente: hilandera_eco.blend del bestiario del usuario (D:\REBELUM_diagnostico\entradas\2026-11-09_bestiario\, D-075).
# Se trabaja SIEMPRE sobre una copia: este guion guarda el resultado en <salida.blend> y no toca el archivo abierto.
# Es el mismo método que el de Zarzalín, Cencerrante y Velaria (enemigos/*/fuentes_blender/crear_clips.py).
#
# El esqueleto del usuario ya sirve (raíz, cuerpo, abdomen, cabeza y seis patas de tres huesos): no se toca. Sus cuatro
# clips (reposo, mordida_resonante, trama_de_eco y recibir_golpe) tampoco. Se añaden:
#   aviso_mordida  el turno en que MARCA a su presa: alza el frente y abre las patas delanteras (la postura de aviso de la
#                  mordida, su fotograma 12), orienta las placas del lomo, tiembla y vuelve al reposo
#   derrota        se encoge, las patas ceden hacia fuera y cae sobre el vientre; un estertor de las delanteras
#   entrada        llega correteando desde 1,0 m por detrás (marcha de trípode) y se asienta en su reposo
#   correr         en bucle: corretea en el sitio (marcha de trípode), para acercarse a su presa y volver
#
# Ejes (Blender): mira a -Y, Z arriba, su izquierda es +X (huesos .L). En Godot mira a +Z. Signos (rotación alrededor de
# ejes del esqueleto, sobre la pose base): pata .L alrededor de -Y la levanta (en .R, +Y); pata .L alrededor de -Z la
# lleva adelante (en .R, +Z); tramo medio .L alrededor de +Y recoge la punta bajo el cuerpo (en .R, -Y); raíz -X alza el
# frente; raíz +Y la ladea hacia su derecha.
# Cada pose se apoya: la raíz sube o baja para que lo más bajo de la malla toque el suelo (más un despegue). Exporta con
# export_anim_slide_to_zero: el fotograma 1 es el segundo 0 (mordida en el 23 = 0,733 s; trama en el 26 = 0,833 s;
# el aviso de la marca en el 13 = 0,40 s).
import bpy, sys, math
from mathutils import Quaternion, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
SALIDA_BLEND, SALIDA_GLB = argv[0], argv[1]

arm = bpy.data.objects["hilandera_eco"]
malla = bpy.data.objects["hilandera_eco_malla"]
ad = arm.animation_data
HUESOS = [b.name for b in arm.data.bones]
REPOSO_ROT = {b.name: b.matrix_local.to_quaternion() for b in arm.data.bones}
X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)
MX, MY, MZ = (-1, 0, 0), (0, -1, 0), (0, 0, -1)


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
    r = REPOSO_ROT[hueso]
    d = r.inverted() @ Quaternion(Vector(eje), math.radians(grados)) @ r
    p[hueso][1] = d @ p[hueso][1]
    return p


def mover(p, hueso, v):
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
    poner(p)
    dg = bpy.context.evaluated_depsgraph_get()
    ev = malla.evaluated_get(dg)
    me = ev.to_mesh()
    mw = ev.matrix_world
    bajo = min((mw @ v.co).z for v in me.vertices)
    ev.to_mesh_clear()
    return bajo


def apoyar(p, despegue=0.0):
    b = suelo(p)
    return mover(p, "root", (0, 0, -b + despegue))


def con(p, cambios, despegue=None):
    q = copia(p)
    for c in cambios:
        if c[0] == "mover":
            mover(q, c[1], c[2])
        else:
            girar(q, c[0], c[1], c[2])
    if despegue is not None:
        apoyar(q, despegue)
    return q


def levantar(pata, lado, grados):
    """Levanta la pata (n = 1 delantera, 2 media, 3 trasera) girando su tramo alto hacia arriba."""
    return [("leg%d_upper.%s" % (pata, lado), MY if lado == "L" else Y, grados)]


def adelante(pata, lado, grados):
    """Lleva la pata hacia delante (-Y); negativo, hacia atrás."""
    return [("leg%d_upper.%s" % (pata, lado), MZ if lado == "L" else Z, grados)]


def recoger(pata, lado, grados):
    """Recoge la punta bajo el cuerpo (tramo medio hacia dentro)."""
    return [("leg%d_middle.%s" % (pata, lado), Y if lado == "L" else MY, grados)]


TRIPODE_A = [(1, "L"), (2, "R"), (3, "L")]
TRIPODE_B = [(1, "R"), (2, "L"), (3, "R")]


def zancada(alzado, apoyado, alto=1.0):
    """Marcha de trípode: el trípode «alzado» se levanta y avanza; el «apoyado» empuja hacia atrás."""
    res = []
    for n, s in alzado:
        res += levantar(n, s, 16 * alto) + adelante(n, s, 12 * alto)
    for n, s in apoyado:
        res += adelante(n, s, -8 * alto)
    return res


def asentar(alto=1.0):
    """Las seis patas con el pie en el suelo, a medio paso."""
    res = []
    for n, s in TRIPODE_A + TRIPODE_B:
        res += levantar(n, s, 3 * alto)
    return res


# ---------------------------------------------------------------- poses base
for t in ad.nla_tracks:
    t.mute = True
REPOSO = pose_de("reposo", 1)
AVISO = pose_de("mordida_resonante", 12)       # la postura de aviso de la mordida del usuario
clips = {}

# ---------------------------------------------------------------- aviso_mordida (marca a su presa; 0,40 s el aviso)
clips["aviso_mordida"] = [
    (1, REPOSO),
    (8, con(AVISO, [("abdomen", X, -6)], None)),
    (13, con(AVISO, [("abdomen", X, -14), ("head", MX, 6)] + levantar(1, "L", 6) + levantar(1, "R", 6), None)),
    (17, con(AVISO, [("abdomen", X, -12), ("head", X, 4)] + levantar(1, "L", 2) + levantar(1, "R", 2), None)),
    (21, con(AVISO, [("abdomen", X, -14), ("head", MX, 5)] + levantar(1, "L", 6) + levantar(1, "R", 6), None)),
    (25, con(AVISO, [("abdomen", X, -12), ("head", X, 2)], None)),
    (32, con(REPOSO, [("abdomen", X, -4)], None)),
    (38, REPOSO),
]

# ---------------------------------------------------------------- correr (marcha de trípode en el sitio, en bucle)
clips["correr"] = [
    (1, con(REPOSO, zancada(TRIPODE_A, TRIPODE_B) + [("body", Y, 2)], 0.0)),
    (4, con(REPOSO, asentar(), 0.0)),
    (7, con(REPOSO, zancada(TRIPODE_B, TRIPODE_A) + [("body", Y, -2)], 0.0)),
    (10, con(REPOSO, asentar(), 0.0)),
    (13, con(REPOSO, zancada(TRIPODE_A, TRIPODE_B) + [("body", Y, 2)], 0.0)),
]

# ---------------------------------------------------------------- entrada (corretea desde 1,0 m por detrás)
def en(y, pose_cambios, despegue=0.0):
    return con(REPOSO, [("mover", "root", (0, y, 0))] + pose_cambios, despegue)


clips["entrada"] = [
    (1, en(1.0, zancada(TRIPODE_A, TRIPODE_B))),
    (4, en(0.88, asentar())),
    (7, en(0.76, zancada(TRIPODE_B, TRIPODE_A))),
    (10, en(0.64, asentar())),
    (13, en(0.52, zancada(TRIPODE_A, TRIPODE_B))),
    (16, en(0.40, asentar())),
    (19, en(0.28, zancada(TRIPODE_B, TRIPODE_A))),
    (22, en(0.17, asentar())),
    (25, en(0.08, zancada(TRIPODE_A, TRIPODE_B, 0.7))),
    (28, en(0.02, asentar(0.5))),
    (32, con(REPOSO, [("root", MX, 4), ("abdomen", X, -8)], 0.0)),     # se asienta y alza un poco las placas
    (38, con(REPOSO, [("abdomen", X, 2)], 0.0)),
    (44, REPOSO),
]

# ---------------------------------------------------------------- derrota (cae sobre el vientre y recoge las patas)
def todas(f):
    res = []
    for n, s in TRIPODE_A + TRIPODE_B:
        res += f(n, s)
    return res


def tendida(n, s, alza, abre, punta):
    """Pata vencida hacia fuera: el tramo alto baja («alza» negativo), el medio se abre hacia fuera y la punta también."""
    return levantar(n, s, alza) + recoger(n, s, -abre) + [("leg%d_tip.%s" % (n, s), MY if s == "L" else Y, punta)]


def caida(alza, abre, punta, extra=None):
    res = []
    for n, s in TRIPODE_A + TRIPODE_B:
        e = (extra or {}).get((n, s), (0, 0, 0))
        res += tendida(n, s, alza + e[0], abre + e[1], punta + e[2])
    return res


# las patas delanteras se recogen un poco en el estertor
ESTERTOR = {(1, "L"): (14, -40, -20), (1, "R"): (14, -40, -20)}
clips["derrota"] = [
    (1, REPOSO),
    (4, con(REPOSO, [("root", MX, 8), ("abdomen", X, -10), ("head", MX, 8)] + todas(lambda n, s: levantar(n, s, 4)),
        0.0)),
    (9, con(REPOSO, [("root", MX, 3), ("abdomen", X, -4)] + caida(-4, 30, 15), 0.0)),
    (14, con(REPOSO, [("root", Y, 2), ("abdomen", X, 4), ("head", X, 10)] + caida(-8, 62, 30), 0.0)),
    (18, con(REPOSO, [("root", Y, 3), ("abdomen", X, 6), ("head", X, 16)] + caida(-10, 72, 38), 0.0)),
    (22, con(REPOSO, [("root", Y, 3), ("abdomen", X, 5), ("head", X, 14)] + caida(-10, 70, 36, ESTERTOR), 0.0)),
    (27, con(REPOSO, [("root", Y, 3), ("abdomen", X, 6), ("head", X, 16)] + caida(-10, 72, 38), 0.0)),
    (36, con(REPOSO, [("root", Y, 3), ("abdomen", X, 6), ("head", X, 17)] + caida(-10, 73, 39), 0.0)),
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
            if h in previo and previo[h].dot(q) < 0:
                q.negate()
            previo[h] = q
            pb.rotation_quaternion = q
            pb.keyframe_insert("rotation_quaternion", frame=f, group=h)
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
    print("CLIP", nombre, "fotogramas", [c[0] for c in claves], "curvas", len(curvas(a)))

for n in ["reposo", "mordida_resonante", "trama_de_eco", "recibir_golpe"]:
    bpy.data.actions[n].use_fake_user = True

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
