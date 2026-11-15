# Revisión 15/11: mide la MANO del cetro de Nix (solo lee, no guarda nada).
#   blender -b --factory-startup -P p12_mano_medir.py -- <blend>
# - vértices con peso de cada hueso de los dedos (cuerpo y ropa), los de RightHandMiddle1/2 por separado;
# - en cada acción: cuánto se doblan los dedos de cada mano (ángulo medio de las pistas de giro respecto al reposo);
# - dónde queda el socket «arma_d» respecto a la palma (centro entre los nudillos) en «guardia» y «reposo».
import bpy, sys, math
from mathutils import Vector, Quaternion
a = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
arm = bpy.data.objects["nix_esqueleto"]
DEDOS = ["Thumb", "Index", "Middle", "Ring", "Pinky"]


def pesos(obj):
    r = {}
    nombres = {g.index: g.name for g in obj.vertex_groups}
    for v in obj.data.vertices:
        for g in v.groups:
            n = nombres[g.group]
            if "Hand" in n and g.weight > 0.05:
                r[n] = r.get(n, 0) + 1
    return r


for o in ("cuerpo_nix", "ropa_nix"):
    p = pesos(bpy.data.objects[o])
    for lado in ("Left", "Right"):
        print("PESOS", o, lado, {k.split(":")[-1]: v for k, v in sorted(p.items()) if lado + "Hand" in k})

for b in arm.data.bones:
    if "RightHand" in b.name or b.name == "arma_d":
        print("HUESO", b.name, "padre", b.parent.name if b.parent else "-", "cabeza", tuple(round(x, 3) for x in b.head_local),
              "cola", tuple(round(x, 3) for x in b.tail_local), "deforma", b.use_deform)

for act in sorted(bpy.data.actions, key=lambda x: x.name):
    res = {}
    for fc in act.fcurves if hasattr(act, "fcurves") else []:
        pass
    # Blender 5: las curvas están en las capas/ranuras; se evalúa la pose en unos fotogramas
    arm.animation_data_create()
    arm.animation_data.action = act
    if hasattr(arm.animation_data, "action_slot") and act.slots:
        arm.animation_data.action_slot = act.slots[0]
    f0, f1 = act.frame_range
    for lado in ("Left", "Right"):
        angs = []
        for f in (f0, (f0 + f1) / 2, f1):
            bpy.context.scene.frame_set(int(f))
            for d in DEDOS:
                for k in (1, 2, 3):
                    pb = arm.pose.bones.get("mixamorig:%sHand%s%d" % (lado, d, k))
                    if pb is None:
                        continue
                    q = pb.matrix_basis.to_quaternion()
                    angs.append(math.degrees(2 * math.acos(min(1.0, abs(q.w)))))
        res[lado] = round(sum(angs) / max(1, len(angs)), 1)
    print("DEDOS", act.name, res)

for nombre in ("guardia", "reposo"):
    act = bpy.data.actions[nombre]
    arm.animation_data.action = act
    if hasattr(arm.animation_data, "action_slot") and act.slots:
        arm.animation_data.action_slot = act.slots[0]
    bpy.context.scene.frame_set(int(act.frame_range[0]))
    mw = arm.matrix_world
    pb = arm.pose.bones
    nudillos = [mw @ pb["mixamorig:RightHand%s1" % d].head for d in ("Index", "Middle", "Ring", "Pinky") if "mixamorig:RightHand%s1" % d in pb]
    mano = mw @ pb["mixamorig:RightHand"].head
    palma = sum(nudillos, Vector()) / len(nudillos)
    centro = (mano + palma) / 2
    s = pb["arma_d"]
    so = mw @ s.head
    eje = (mw.to_3x3() @ (s.tail - s.head)).normalized()
    # distancia del eje del cetro (línea por el socket) al centro de la palma
    d = (centro - so).cross(eje).length
    print("SOCKET", nombre, "socket", tuple(round(x, 3) for x in so), "centro_palma", tuple(round(x, 3) for x in centro),
          "dist_eje_palma", round(d, 3), "eje", tuple(round(x, 2) for x in eje))
