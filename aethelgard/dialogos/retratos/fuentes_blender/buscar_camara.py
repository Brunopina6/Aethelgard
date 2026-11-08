# Busca la orientación de la cámara (y el fotograma del reposo) que reproduce la silueta del retrato kael.png.
# Silueta (IoU) del render del modelo con cada fotograma, giro y inclinación frente a la del retrato; imprime las mejores.
#   blender -b -P buscar_camara.py -- <kael.fbx> <dialogos/retratos/kael.png> <carpeta_temporal>
# Resultado (2026-11-08): fotograma 5 a 10, giro -13 a -15°, inclinación 6-7° (IoU 0,97 aquí; 0,98 afinando a 1°).
import bpy, sys, math, mathutils, os
import numpy as np
argv = sys.argv[sys.argv.index("--")+1:]
fbx, retrato, tmp = argv[0], argv[1], argv[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=fbx)
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
mesh = [o for o in bpy.data.objects if o.type == 'MESH'][0]
sc = bpy.context.scene
sc.render.engine = 'BLENDER_WORKBENCH'
sc.render.film_transparent = True
sc.render.resolution_x = 160
sc.render.resolution_y = 320
sc.render.image_settings.color_mode = 'RGBA'
idle = [a for a in bpy.data.actions if '_01a19b86' in a.name][0]
arm.animation_data_create()
arm.animation_data.action = idle
try:
    arm.animation_data.action_slot = idle.slots[0]
except Exception:
    pass
cam_data = bpy.data.cameras.new("cam"); cam_data.type = 'ORTHO'
cam = bpy.data.objects.new("cam", cam_data); sc.collection.objects.link(cam); sc.camera = cam

def mascara(path):
    im = bpy.data.images.load(os.path.abspath(path), check_existing=False)
    w, h = im.size
    px = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(im)
    return px[:, :, 3] > 0.5

def recorta_y_escala(m, W, H):
    ys, xs = np.nonzero(m)
    if len(xs) == 0:
        return None, 0
    m = m[ys.min():ys.max()+1, xs.min():xs.max()+1]
    h, w = m.shape
    yi = (np.arange(H) * h / H).astype(int)
    xi = (np.arange(W) * w / W).astype(int)
    return m[yi][:, xi], w / h

orig = mascara(retrato)
H0, W0 = orig.shape
o_small, o_aspect = recorta_y_escala(orig, 120, 310)
print("ORIG", W0, H0, "aspect", round(o_aspect, 3))

def bbox_world():
    deps = bpy.context.evaluated_depsgraph_get()
    me = mesh.evaluated_get(deps)
    return [me.matrix_world @ mathutils.Vector(c) for c in me.bound_box]

def render_mask(yaw, pitch):
    pts = bbox_world()
    c = sum(pts, mathutils.Vector()) / 8
    d = mathutils.Vector((math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)), -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)), math.sin(math.radians(pitch))))
    cam.location = c + d * 6
    cam.rotation_euler = (d * -1).to_track_quat('-Z', 'Y').to_euler()
    cam_data.ortho_scale = 2.2
    p = os.path.join(tmp, "m.png")
    sc.render.filepath = p
    bpy.ops.render.render(write_still=True)
    return mascara(p)

mejores = []
for frame in [1, 2, 5, 10, 20, 40, 60, 80, 100, 150, 200, 250, 300]:
    sc.frame_set(frame)
    for yaw in range(-50, 51, 5):
        for pitch in [0, 8]:
            m = render_mask(yaw, pitch)
            s, asp = recorta_y_escala(m, 120, 310)
            if s is None:
                continue
            iou = (s & o_small).sum() / max(1, (s | o_small).sum())
            mejores.append((iou, frame, yaw, pitch, asp))
mejores.sort(reverse=True)
for r in mejores[:12]:
    print("CAND iou=%.3f frame=%d yaw=%d pitch=%d aspect=%.3f" % r)
