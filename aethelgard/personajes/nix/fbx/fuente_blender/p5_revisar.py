# Nix piloto FBX: primeros planos de revisión (cabeza girada, mechones levantados, axilas, codos y caderas).
#   blender -b -P p5_revisar.py -- <blend con rig> <carpeta render> <raíz aethelgard>
import sys, os, math
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
BLEND, REND, RAIZ = argv[:3]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(1, os.path.join(RAIZ, "personajes", "heroes_v2", "fuentes_blender"))
import bpy
from mathutils import Vector, Quaternion, Matrix
import nix_comun as C
import rig_comun as RC
os.makedirs(REND, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
arm = bpy.data.objects["nix_esqueleto"]
if arm.animation_data:
    arm.animation_data.action = None
rig = RC.Rig(arm)
mw = arm.matrix_world


def girar(n, eje, g):
    pb = arm.pose.bones[n]
    R = (mw @ pb.matrix).to_3x3().normalized()
    cab = mw @ pb.head
    q = Quaternion(Vector(eje), math.radians(g))
    pb.matrix = mw.inverted() @ (Matrix.Translation(cab) @ (q.to_matrix() @ R).to_4x4())
    bpy.context.view_layer.update()


def cerca(nombre, centro, yaw, pitch=0, esc=0.5):
    C._limpiar(); C.config_render(700, 700, 32); C.escena_luz()
    C.camara(Vector(centro), yaw, pitch, esc)
    bpy.context.scene.render.filepath = os.path.join(REND, nombre + ".png")
    bpy.ops.render.render(write_still=True)


# 1. solo los mechones levantados (pose en T)
rig.reset()
for n, eje, g in [("mechon_i_1", (1, 0, 0), -35), ("mechon_i_2", (1, 0, 0), -30), ("mechon_d_1", (1, 0, 0), -35),
                  ("mechon_d_2", (1, 0, 0), -30), ("mechon_sup_1", (1, 0, 0), -12), ("mechon_sup_2", (0, 1, 0), 15)]:
    girar(n, eje, g)
cerca("mechones_arriba_34", (0, -0.05, 1.6), 35, 5, 0.55)
cerca("mechones_arriba_perfil", (0, -0.05, 1.6), 90, 0, 0.55)
rig.reset()
cerca("mechones_reposo_34", (0, -0.05, 1.6), 35, 5, 0.55)
# 2. cabeza girada y agachada
rig.aplicar({"cabeza": (15, 0, 35)})
cerca("cabeza_girada", (0, -0.05, 1.62), 0, 0, 0.5)
cerca("cabeza_girada_34", (0, -0.05, 1.62), 35, 0, 0.5)
# 3. brazos abajo (reposo) y arriba: axilas y hombros
rig.aplicar({"mano_i": {"pos": (0.05, -0.95, 0.12), "dedos": (0, -1, 0), "palma": (-1, 0, 0), "cierre": 20},
             "mano_d": {"pos": (0.05, 0.9, 0.2), "codo": (0, 0, 1), "dedos": (0, 1, 0), "palma": (-1, 0, 0), "cierre": 20}})
cerca("axilas_frente", (0, 0, 1.35), 0, 0, 0.75)
cerca("axilas_espalda", (0, 0, 1.35), 180, 0, 0.75)
# 4. codos y rodillas muy doblados, cadera
rig.aplicar({"cadera": (0, -0.3, 0), "pie_i": {"pos": (0.15, 0, 0.05)}, "pie_d": {"pos": (-0.1, 0, 0.05)},
             "mano_i": {"pos": (0.35, 0.05, -0.1), "codo": (0, -1, 0.8), "dedos": (0, 1, 0), "palma": (-1, 0, 0), "cierre": 80},
             "mano_d": {"pos": (0.35, 0.05, -0.1), "codo": (0, -1, 0.8), "dedos": (0, 1, 0), "palma": (1, 0, 0), "cierre": 80}})
cerca("codos_rodillas_frente", (0, 0, 0.95), 25, 5, 1.6)
cerca("codos_rodillas_perfil", (0, 0, 0.95), 90, 5, 1.6)
cerca("manos_cerca", (0, -0.25, 1.25), 25, 10, 0.6)
print("FIN")
