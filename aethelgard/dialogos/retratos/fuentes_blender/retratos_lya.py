# Retratos de Lya para los diálogos (T-084, tanda 2), hechos con Blender 5.2 desde su modelo 3D
# (Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx, de Meshy, esqueleto Mixamo): el mismo modelo,
# cámara y luz que su retrato original dialogos/retratos/lya.png, con poses nuevas (poses_lya.py).
#
# De dónde sale el original: lya.png es un render de este mismo modelo en su clip quieto «_01a19663» con los brazos
# bajados como el gesto «reposo» del juego (gestos_3d.gd). La silueta coincide en un 98,4 % (IoU) con la cámara girada
# +14° y 6° hacia abajo: la de Kael está girada -13,5°, así que los dos retratos se miran.
#
# Pasos (desde la carpeta aethelgard/, con «blender» = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"):
#   1. Renders a 3 veces el tamaño final (crudo_<pose>.png):
#        blender -b -P dialogos/retratos/fuentes_blender/retratos_lya.py -- Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx <tmp> control,reposo,preocupada,decidida,duda
#   2. Color igualado con el original, reducción por área y el mismo lienzo para todas:
#        blender -b -P dialogos/retratos/fuentes_blender/finalizar.py -- dialogos/retratos/lya.png <tmp> control,reposo,preocupada,decidida,duda dialogos/retratos lya
#      («control» es el reposo original re-renderizado: sirve para el ajuste de color y no se guarda en el juego).
# RES: con ella, la silueta del control mide a 1/3 lo mismo que el original (335 × 620).
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector
import escena as E, poses_lya as PL

argv = sys.argv[sys.argv.index("--") + 1:]
FBX, SALIDA = argv[0], argv[1]
POSES = argv[2].split(",")
RES = int(argv[3]) if len(argv) > 3 else 2161
YAW, PITCH, ORTO = 14.0, 6.0, 2.0                 # cámara del retrato original (buscar_lya, tanda 2)
os.makedirs(SALIDA, exist_ok=True)

arm, mallas = E.importar(FBX)
E.sin_metal(mallas)
E.config_render(RES, RES)
PL.base(arm)
pts = E.bbox_mundo(mallas)
centro = sum(pts, Vector()) / len(pts)            # centrada en la caja del reposo original
cam = E.camara(centro, YAW, PITCH, ORTO)
E.luces(cam)
for n in POSES:
    PL.POSES[n](arm)
    E.render(os.path.join(SALIDA, "crudo_%s.png" % n))
    print("RENDER", n)
