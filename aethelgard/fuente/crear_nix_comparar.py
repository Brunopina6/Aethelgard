# Nix (V12): vistas de comparación con CÁMARAS FIJAS (las mismas para la v1 y la v2): frente, perfil y espalda en su
# reposo, con la luz de los retratos. Para la hoja v1 / v2 / referencia.
#
#   blender -b <nix.blend de la versión> -P fuente/crear_nix_comparar.py -- <raíz aethelgard> <png de salida>
import sys, os
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
RAIZ, SALIDA = argv[0], argv[1]
sys.path.insert(0, os.path.join(RAIZ, "dialogos", "retratos", "fuentes_blender"))
sys.path.insert(0, os.path.join(RAIZ, "fuente"))
import bpy
from mathutils import Vector
import escena as E
import crear_nix_hojas as HJ

arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
for o in bpy.data.objects:
    if o.type == 'MESH' and "lod" in o.name:
        o.hide_render = True
if "reposo" not in bpy.data.actions:                 # (un .blend del modelo sin clips: se crean)
    sys.path.insert(1, os.path.join(RAIZ, "personajes", "heroes_v3", "fuentes_blender"))
    sys.path.insert(2, os.path.join(RAIZ, "personajes", "heroes_v2", "fuentes_blender"))
    import rig_comun as RC
    import biblioteca_clips as BC
    import crear_nix_clips as NC
    import crear_nix_verificar as VF
    VF.crear_acciones(arm, NC.clips_de(), RC, BC)
act = bpy.data.actions["reposo"]
if arm.animation_data is None:
    arm.animation_data_create()
arm.animation_data.action = act
try:
    arm.animation_data.action_slot = act.slots[0]
except Exception:
    pass
bpy.context.scene.frame_set(0)
CENTRO = Vector((0.0, -0.05, 1.06))
ESCALA = 2.3
rutas = []
for yaw in (0, 90, 180):
    r = SALIDA.replace(".png", "_%d.png" % yaw)
    HJ._render(CENTRO, yaw, 0, ESCALA, r, res=(560, 640))
    rutas.append(r)
HJ.hoja(rutas, SALIDA, 3)
for r in rutas:
    os.remove(r)
print("COMPARAR", SALIDA)
