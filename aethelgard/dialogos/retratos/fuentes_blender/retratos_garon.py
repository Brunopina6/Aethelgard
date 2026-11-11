# Retratos de Garon para los diálogos (V12, fase B de los héroes), hechos con Blender 5.2 desde su modelo 3D del juego
# (garon.fbx, Meshy «Crimson Helm Guardian», esqueleto Mixamo), con la MISMA cámara ortográfica y luz que los de Kael y
# Lya (escena.py: sol cálido FFE2B0 desde arriba a la izquierda, ambiente blanco, sin metal), 6° desde arriba y girada
# -12° (como Kael: los de Lya miran al otro lado). Mismo proceso que finalizar.py: render a 3 veces el tamaño final,
# reducción por área con alfa premultiplicado y un lienzo común para todas las poses (los pies abajo, mismo centro),
# para que al cambiar de pose en el diálogo nada se desplace. Alto de la silueta del reposo: 620 px, como Kael y Lya.
# Las poses se escriben con el rig común de los héroes v2 (personajes/heroes_v2/fuentes_blender/rig_comun.py).
#
#   blender -b --factory-startup -P dialogos/retratos/fuentes_blender/retratos_garon.py -- garon.fbx <carpeta_tmp> dialogos/retratos
# Poses: reposo (firme, puños cerrados), espalda (manos a la espalda: en descanso, reservado), saludo (puño al pecho)
# y alto («Quietos»: la mano izquierda adelante, la cabeza girada). Garon lleva yelmo cerrado: su gesto es el cuerpo.
import sys, os
sys.dont_write_bytecode = True
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
sys.path.insert(0, os.path.join(AQUI, "..", "..", "..", "personajes", "heroes_v2", "fuentes_blender"))
import bpy
import numpy as np
from mathutils import Vector
import escena as E, imgutil as U
import rig_comun as RC
import biblioteca_clips as BC

argv = sys.argv[sys.argv.index("--") + 1:]
FBX, TMP, SALIDA = argv[0], argv[1], argv[2]
YAW, PITCH, ORTO = -12.0, 6.0, 2.0
ALTO_FINAL = 620
MARGEN = 4
os.makedirs(TMP, exist_ok=True)

arm, mallas = E.importar(FBX)
E.sin_metal(mallas)
rig = RC.Rig(arm)
e = BC.ESTILOS["Garon"]
base = BC.reposo_pose(e)
puno = {"cierre": 80, "pulgar": 40}
POSES = {
    "reposo": BC.mezclar(base, {"mano_d": dict(BC.ABAJO, **puno), "mano_i": dict(BC.ABAJO, **puno),
                                "mano_d_": None}),
    "espalda": BC.mezclar(base, {"columna": (-7, 0, 0), "cabeza": (2, 0, 0),
                                 "mano_d": {"pos": (-0.4, -0.85, -0.15), "codo": (-1, -0.3, 0.6), "dedos": (-0.3, -1, -0.5),
                                            "palma": (-1, 0, 0), "cierre": 40},
                                 "mano_i": {"pos": (-0.4, -0.85, -0.15), "codo": (-1, -0.3, 0.6), "dedos": (-0.3, -1, -0.5),
                                            "palma": (-1, 0, 0), "cierre": 40}}),
    "saludo": BC.mezclar(base, {"columna": (-6, 0, 0), "cabeza": (4, 0, 0),
                                "mano_d": {"pos": (0.42, -0.3, -0.5), "codo": (0.2, -1, 0.8), "dedos": (0.1, 0.2, -1),
                                           "palma": (-1, 0, -0.2), "cierre": 85, "pulgar": 40},
                                "mano_i": dict(BC.ABAJO, **puno)}),
    "alto": BC.mezclar(base, {"columna": (-2, 0, -6), "cabeza": (6, 0, -14),
                              "mano_i": {"pos": (0.7, -0.15, 0.2), "codo": (-0.3, -1, 0.8), "dedos": (0.15, 1, 0.1),
                                         "palma": (1, 0, 0.1), "cierre": 5, "pulgar": 0},
                              "mano_d": dict(BC.ABAJO, **puno)}),
}
for d in POSES.values():
    d.pop("mano_d_", None)

# resolución: que la silueta del reposo mida ALTO_FINAL px tras reducir a 1/3
rig.aplicar(POSES["reposo"])
pts = E.bbox_mundo(mallas)
alto_mundo = max(p.z for p in pts) - min(p.z for p in pts)
RES = int(round(ALTO_FINAL * 3 * ORTO / (alto_mundo * 1.0)))
E.config_render(RES, RES)
centro = sum(pts, Vector()) / len(pts)
cam = E.camara(centro, YAW, PITCH, ORTO)
E.luces(cam)
crudos = {}
for n, d in POSES.items():
    rig.aplicar(d)
    r = os.path.join(TMP, "crudo_%s.png" % n)
    E.render(r)
    im = U.cargar(r)
    crudos[n] = U.reescalar(im, im.shape[1] // 3, im.shape[0] // 3)
    print("RENDER", n)

# lienzo común: el alto del reposo + MARGEN arriba, los pies abajo, el centro del reposo
x0, y0, x1, y1 = U.bbox(crudos["reposo"], 0.5)
cx = (x0 + x1) / 2.0
media = 0
for n, im in crudos.items():
    bx0, by0, bx1, by1 = U.bbox(im, 0.02)
    media = max(media, cx - bx0, bx1 - cx)
W = int(np.ceil(media)) * 2 + 4
lx0 = int(round(cx - W / 2.0))
print("LIENZO %dx%d (silueta del reposo %d px)" % (W, y1 - y0 + MARGEN, y1 - y0))
for n, im in crudos.items():
    rec = im[y0 - MARGEN:y1, lx0:lx0 + W]
    ruta = os.path.join(SALIDA, "garon_%s.png" % n)
    U.guardar(rec, ruta)
    print("RETRATO", ruta, rec.shape[1], "x", rec.shape[0])
