# Nix piloto FBX: fotogramas de «canalizar» y del bucle «magia_concentrar» de cerca (mechones con retraso).
#   blender -b -P p6_canalizar.py -- <blend con rig> <carpeta render>
import sys, os
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
BLEND, REND = argv[:2]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector
import nix_comun as C
os.makedirs(REND, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
arm = bpy.data.objects["nix_esqueleto"]
sc = bpy.context.scene
for nombre, ts in [("canalizar", [0.0, 0.2, 0.4, 0.6, 0.75, 0.9]), ("magia_concentrar", [0.0, 0.55, 1.1, 1.65])]:
    act = bpy.data.actions[nombre]
    arm.animation_data.action = act
    try:
        arm.animation_data.action_slot = act.slots[0]
    except Exception:
        pass
    for t in ts:
        sc.frame_set(int(round(t * 30)))
        bpy.context.view_layer.update()
        hb = arm.matrix_world @ arm.pose.bones["mixamorig:Head"].head
        C._limpiar(); C.config_render(600, 600, 32); C.escena_luz()
        C.camara(Vector((hb.x, hb.y, hb.z - 0.05)), 30, 5, 0.75)
        sc.render.filepath = os.path.join(REND, "%s_%03d.png" % (nombre, int(t * 100)))
        bpy.ops.render.render(write_still=True)
print("FIN")
