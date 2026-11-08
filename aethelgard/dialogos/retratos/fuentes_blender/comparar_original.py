# Prueba de origen del retrato original (T-084): renderiza el modelo 3D de Kael en el fotograma 5 de su reposo
# «_01a19b86» con la cámara de buscar_camara.py y lo compara píxel a píxel con dialogos/retratos/kael.png: coincidencia
# de silueta (IoU) y diferencia de color. Guarda una lámina: original | render | diferencia.
#   blender -b -P comparar_original.py -- <kael.fbx> <kael.png> <lamina.png>
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
from mathutils import Vector
import escena as E, poses_kael as PK, imgutil as U

argv = sys.argv[sys.argv.index("--") + 1:]
FBX, ORIGINAL, LAMINA = argv[0], argv[1], argv[2]
arm, mallas = E.importar(FBX)
E.sin_metal(mallas)
E.config_render(1400, 1400)
PK.base(arm)
pts = E.bbox_mundo(mallas)
cam = E.camara(sum(pts, Vector()) / len(pts), -13.5, 6.0, 2.0)
E.luces(cam)
tmp = LAMINA + ".render.png"
E.render(tmp)
orig = U.cargar(ORIGINAL); rend = U.cargar(tmp)
x0, y0, x1, y1 = U.bbox(rend, 0.5)
r = U.reescalar(rend[y0:y1, x0:x1], orig.shape[1], orig.shape[0])
mo = orig[:, :, 3] > 0.5; mr = r[:, :, 3] > 0.5
iou = (mo & mr).sum() / (mo | mr).sum()
dif = np.abs(orig[:, :, :3] - r[:, :, :3])[mo & mr]
print("ORIGEN: silueta IoU %.3f · diferencia media de color %.3f (0-1) sin igualar el color" % (iou, dif.mean()))
H, W = orig.shape[:2]
L = U.lienzo(W * 3 + 40, H); L[:, :, :3] = 0.12; L[:, :, 3] = 1
U.pegar(L, orig, 0, 0)
U.pegar(L, r, W + 20, 0)
d = np.zeros_like(orig)
d[:, :, :3] = np.abs(orig[:, :, :3] * orig[:, :, 3:4] - r[:, :, :3] * r[:, :, 3:4]) * 2
d[:, :, 3] = 1
U.pegar(L, d, 2 * W + 40, 0)
U.guardar(L, LAMINA)
os.remove(tmp)
print("LAMINA", LAMINA)
