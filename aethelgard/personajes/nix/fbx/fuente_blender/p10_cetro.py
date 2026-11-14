# Cetro de Nix al andar y al correr (14/11).
#   blender -b --factory-startup -P p10_cetro.py -- <blend entrada> <blend salida> <cetro_nix.glb> <carpeta render> [sin_render]
# CAUSA: los clips «andar» y «correr» son la captura de Lya (p4) y NO tienen pistas del socket «arma_d»: el socket se
# queda en su postura de reposo respecto a la mano, que apunta el eje del cetro (Y del hueso) de lado (+X del
# personaje); con el giro de la muñeca de la captura, el cetro va horizontal, cruza el cuerpo y da vueltas. Los clips
# hechos por IK (reposo, guardia, canalizar, combate...) sí llevan pistas de arma_d y no se tocan.
# ARREGLO: se añaden pistas de arma_d SOLO a «andar» y «correr»: el cetro conserva la orientación que tiene en «reposo»
# (casi vertical, el de la exploración: así no salta al empezar a andar) respecto al personaje, con un balanceo suave
# que sigue el braceo (k), una inclinación hacia delante al correr y el pie del cetro algo hacia fuera al correr (para no
# cruzar las piernas). La empuñadura sigue en la mano (solo cambia el giro del socket; su posición la da la mano).
import bpy, sys, os, math
import numpy as np
from mathutils import Vector, Matrix, Quaternion

a = sys.argv[sys.argv.index("--") + 1:]
BLEND_IN, BLEND_OUT, CETRO, REND = a[:4]
SIN_RENDER = "sin_render" in a
os.makedirs(REND, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND_IN)
sc = bpy.context.scene
arm = bpy.data.objects["nix_esqueleto"]
arm.data.pose_position = 'POSE'
pb = arm.pose.bones["arma_d"]
pb.rotation_mode = 'QUATERNION'
P = "mixamorig:"
A3 = arm.matrix_world.to_3x3()
A3i = A3.inverted()


def poner(act):
    arm.animation_data.action = act
    try:
        if act.slots and arm.animation_data.action_slot is None:
            arm.animation_data.action_slot = act.slots[0]
    except Exception:
        pass


# orientación de referencia: «reposo», fotograma 0 (en el mundo)
poner(bpy.data.actions["reposo"])
sc.frame_set(0)
R_REF = (arm.matrix_world @ pb.matrix).to_3x3().normalized()
print("REFERENCIA reposo: eje del cetro", tuple(round(c, 3) for c in R_REF @ Vector((0, 1, 0))))

# parámetros por clip: k (fracción del braceo), inclinación hacia delante (grados), pie hacia fuera (grados)
PARAM = {"andar": dict(k=0.30, delante=4.0, fuera=6.0), "correr": dict(k=0.25, delante=14.0, fuera=12.0)}


def rot_mundo(eje, grados):
    return Matrix.Rotation(math.radians(grados), 3, eje)


def tiene_pista(act):
    try:
        fcs = list(act.fcurves)
    except Exception:
        fcs = [fc for l in act.layers for s in l.strips for cb in s.channelbags for fc in cb.fcurves]
    return any('arma_d' in fc.data_path for fc in fcs)


for nombre, p in PARAM.items():
    act = bpy.data.actions[nombre]
    assert not tiene_pista(act), nombre + " ya tiene pistas de arma_d"
    poner(act)
    f0, f1 = int(round(act.frame_range[0])), int(round(act.frame_range[1]))
    # braceo: ángulo del brazo derecho (hombro -> mano) en el plano sagital; positivo = mano delante (-Y)
    ang = {}
    for f in range(f0, f1 + 1):
        sc.frame_set(f)
        hom = arm.matrix_world @ arm.pose.bones[P + "RightArm"].head
        man = arm.matrix_world @ arm.pose.bones[P + "RightHand"].head
        d = man - hom
        ang[f] = math.atan2(-d.y, -d.z)
    media = sum(ang.values()) / len(ang)
    q_prev = None
    for f in range(f0, f1 + 1):
        sc.frame_set(f)
        pb.matrix_basis = Matrix.Identity(4)
        bpy.context.view_layer.update()
        M = pb.matrix.copy()
        beta = math.radians(p["delante"]) + p["k"] * (ang[f] - media)
        # delante: giro sobre X del mundo (positivo = punta hacia -Y, delante); fuera: sobre Y del mundo (la punta
        # hacia +X = hacia dentro, así el pie del cetro va hacia fuera, -X, el lado de la mano derecha)
        R = rot_mundo('X', math.degrees(beta)) @ rot_mundo('Y', p["fuera"]) @ R_REF
        R_arm = A3i @ R
        q = R_arm.to_quaternion()
        Mdes = Matrix.Translation(M.translation) @ q.to_matrix().to_4x4()
        pb.matrix = Mdes
        bpy.context.view_layer.update()
        qb = pb.rotation_quaternion.copy()
        if q_prev is not None and qb.dot(q_prev) < 0:
            qb.negate()
        pb.rotation_quaternion = qb
        q_prev = qb.copy()
        pb.location = (0.0, 0.0, 0.0)
        pb.keyframe_insert("rotation_quaternion", frame=f)
        pb.keyframe_insert("location", frame=f)
    print("PISTAS arma_d en", nombre, f0, "-", f1, "braceo %.1f..%.1f grados" % (math.degrees(min(ang.values())), math.degrees(max(ang.values()))))

# comprobación: eje del cetro por fotograma
for nombre in ["reposo", "guardia", "andar", "correr", "canalizar"]:
    act = bpy.data.actions[nombre]
    poner(act)
    f0, f1 = act.frame_range
    ejes = []
    for f in np.linspace(f0, f1, 9):
        sc.frame_set(int(round(f)))
        y = (arm.matrix_world @ pb.matrix).to_3x3() @ Vector((0, 1, 0))
        ejes.append(math.degrees(math.acos(max(-1, min(1, y.z)))))
    print("EJE %-10s inclinación respecto a la vertical (grados): %s" % (nombre, " ".join("%.0f" % e for e in ejes)))

arm.animation_data.action = None
for b in arm.pose.bones:
    b.matrix_basis = Matrix.Identity(4)
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
print("GUARDADO", BLEND_OUT)

if not SIN_RENDER:
    # el cetro en el socket para ver la secuencia (no se guarda)
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=CETRO)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    raiz = [o for o in nuevos if o.parent is None][0]
    raiz.parent = arm
    raiz.parent_type = 'BONE'
    raiz.parent_bone = "arma_d"
    # el hijo de hueso se coloca en la COLA; el socket en Godot está en la cabeza: bajarlo el largo del hueso
    raiz.matrix_parent_inverse = Matrix.Identity(4)
    raiz.location = (0, -arm.data.bones["arma_d"].length, 0)
    raiz.rotation_mode = 'QUATERNION'
    raiz.rotation_quaternion = (1, 0, 0, 0)
    # glTF importa con Y arriba -> el cetro ya viene girado a Z arriba; deshacerlo para que su +Y sea el del hueso
    raiz.rotation_quaternion = Quaternion((1, 0, 0), math.radians(-90))
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import p10_comun as C
    for o in list(bpy.data.objects):
        if o.type in ('LIGHT', 'CAMERA'):
            bpy.data.objects.remove(o, do_unlink=True)
    C.luz_y_mundo()
    for nombre in ["reposo", "andar", "correr"]:
        act = bpy.data.actions[nombre]
        poner(act)
        f0, f1 = int(act.frame_range[0]), int(act.frame_range[1])
        paso = 4 if nombre == "andar" else 3
        fs = [f0] if nombre == "reposo" else list(range(f0, f1, paso))
        for f in fs:
            sc.frame_set(f)
            for vista, yaw in [("frente", 0), ("perfil", -90)]:
                C.camara(Vector((0, 0, 0.95)), yaw, 4, 2.2)
                C.render(os.path.join(REND, "%s_%02d_%s.png" % (nombre, f, vista)), 420, 420)
    print("RENDER hecho")
