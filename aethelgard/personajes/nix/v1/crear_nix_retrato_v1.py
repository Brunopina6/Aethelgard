# Nix (V12): retrato del menú (Formación) renderizado de su modelo, con la cámara ortográfica y la luz de los retratos
# (dialogos/retratos/fuentes_blender/escena.py). PROVISIONAL, como el de Naira: 350 × 640, fondo transparente.
#
#   blender -b <evidencias>/nix.blend -P fuente/crear_nix_retrato.py -- <raíz aethelgard>
import sys, os
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ = argv[0]
sys.path.insert(0, os.path.join(RAIZ, "dialogos", "retratos", "fuentes_blender"))
import bpy
from mathutils import Vector
import escena as E

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
for o in bpy.data.objects:
    if o.type == 'MESH' and "lod" in o.name:
        o.hide_render = True
act = bpy.data.actions["reposo"]
if arm.animation_data is None:
    arm.animation_data_create()
arm.animation_data.action = act
try:
    arm.animation_data.action_slot = act.slots[0]
except Exception:
    pass
sc = bpy.context.scene
sc.frame_set(0)
for o in list(bpy.data.objects):
    if o.type in ('LIGHT', 'CAMERA'):
        bpy.data.objects.remove(o, do_unlink=True)
E.config_render(350, 640)
cam = E.camara(Vector((0.0, -0.05, 1.05)), 18, 4, 1.28)
E.luces(cam)
ruta = os.path.join(RAIZ, "personajes", "nix", "nix_retrato.png")
E.render(ruta)
print("RETRATO", ruta)
