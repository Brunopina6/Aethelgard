# Héroes v2: renders de comprobación (hojas de contacto) con cámara y luz fijas, para revisar poses y clips.
import os, sys, math
import bpy
from mathutils import Vector
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "dialogos", "retratos",
                                "fuentes_blender"))
import escena as E          # cámara ortográfica y luz de los retratos (dialogos/retratos/fuentes_blender)
import imgutil as U
import numpy as np


def preparar(res=360):
    sc = E.config_render(res, res)
    try:
        sc.eevee.taa_render_samples = 8
    except Exception:
        pass
    return sc


def camara_vista(rig, yaw, pitch=8.0, margen=1.35):
    centro = Vector((rig.cadera0.x, rig.cadera0.y, rig.suelo + rig.altura * 0.5))
    cam = E.camara(centro, yaw, pitch, rig.altura * margen)
    if bpy.context.scene.world is None:
        E.luces(cam)
    return cam


def hoja(rutas, salida, columnas, etiqueta=None):
    ims = [U.cargar(r) for r in rutas]
    h, w = ims[0].shape[:2]
    filas = (len(ims) + columnas - 1) // columnas
    lz = np.ones((filas * h, columnas * w, 4), dtype=np.float32)
    lz[:, :, :3] = 0.86
    for i, im in enumerate(ims):
        y, x = (i // columnas) * h, (i % columnas) * w
        U.pegar(lz, im, x, y)
    lz[:, :, 3] = 1.0
    U.guardar(lz, salida)
