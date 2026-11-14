# Nix piloto FBX: compara la textura de color que va dentro del GLB con la PNG horneada (¿cambió el brillo al exportar?).
#   blender -b --factory-startup -P p7_medir_glb_textura.py -- <glb> <png horneada> <carpeta temporal>
import sys, os, json, struct, bpy
import numpy as np
argv = sys.argv[sys.argv.index("--") + 1:]
GLB, PNG, TMP = argv[:3]
os.makedirs(TMP, exist_ok=True)
d = open(GLB, "rb").read()
L = struct.unpack("<I", d[12:16])[0]
j = json.loads(d[20:20 + L])
bin0 = 20 + L + 8
for im in j["images"]:
    if "color" in im.get("name", ""):
        bv = j["bufferViews"][im["bufferView"]]
        datos = d[bin0 + bv.get("byteOffset", 0): bin0 + bv.get("byteOffset", 0) + bv["byteLength"]]
        ruta = os.path.join(TMP, "glb_color.webp")
        open(ruta, "wb").write(datos)


def media(r):
    im = bpy.data.images.load(r)
    im.colorspace_settings.name = 'sRGB'
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[:, :, :3]
    # sin la parte vacía (negra) del atlas
    m = a.mean(axis=2)
    return w, float(np.median(m[m > 0.02])), float(a.mean())


print("PNG horneada", media(PNG))
print("GLB (webp)", media(os.path.join(TMP, "glb_color.webp")))
