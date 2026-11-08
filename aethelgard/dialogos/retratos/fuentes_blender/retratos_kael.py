# Retratos de Kael para los diálogos (T-084), hechos con Blender 5.2 desde su modelo 3D (kael.fbx, de Meshy, con
# esqueleto Mixamo): el mismo modelo, cámara y luz que el retrato original dialogos/retratos/kael.png, con poses nuevas.
#
# De dónde sale el original: kael.png es un render de este mismo modelo en el fotograma 5 de su reposo «_01a19b86»
# (el reposo con el sable al hombro; sin el sable, la mano queda junto a la cabeza). La silueta coincide en un 98,9 %
# con la cámara girada -13,5° y 6° hacia abajo (buscar_camara.py y comparar_original.py).
#
# Pasos (desde la carpeta aethelgard/, con «blender» = "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"):
#   1. Renders a 3 veces el tamaño final (crudo_<pose>.png):
#        blender -b -P dialogos/retratos/fuentes_blender/retratos_kael.py -- kael.fbx <tmp> control,reposo,broma,brazalete,decidido,sorpresa
#   2. Color igualado con el original, reducción por área y el mismo lienzo para todas (254 × 624):
#        blender -b -P dialogos/retratos/fuentes_blender/finalizar.py -- dialogos/retratos/kael.png <tmp> control,reposo,broma,brazalete,decidido,sorpresa dialogos/retratos kael broma=mano_cadera,decidido=puno
#      («control» es el reposo original re-renderizado: sirve para el ajuste de color y no se guarda en el juego).
# Las poses están en poses_kael.py.
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy
from mathutils import Vector
import escena as E, poses_kael as PK

argv = sys.argv[sys.argv.index("--") + 1:]
FBX, SALIDA = argv[0], argv[1]
POSES = argv[2].split(",")
RES = int(argv[3]) if len(argv) > 3 else 2202     # 3 veces la escala final (el alto del reposo original: 620 px)
YAW, PITCH, ORTO = -13.5, 6.0, 2.0                # cámara del retrato original
os.makedirs(SALIDA, exist_ok=True)

arm, mallas = E.importar(FBX)
E.sin_metal(mallas)
E.config_render(RES, RES)
PK.base(arm)
pts = E.bbox_mundo(mallas)
centro = sum(pts, Vector()) / len(pts)            # centrada en la caja del reposo original
cam = E.camara(centro, YAW, PITCH, ORTO)
E.luces(cam)
for n in POSES:
    PK.POSES[n](arm)
    E.render(os.path.join(SALIDA, "crudo_%s.png" % n))
    print("RENDER", n)
