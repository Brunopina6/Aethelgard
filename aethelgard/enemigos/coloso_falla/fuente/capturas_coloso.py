# Capturas de comprobación del Coloso de la Falla: renderiza cada clip en varios momentos desde la vista del combate
# (cámara ortográfica a 12° por encima, el Coloso girado hacia los héroes como en combate.gd: su lado derecho hacia la
# cámara) y compone una hoja por clip, más vistas de frente, perfil y espalda, la fase 2 y el dormido.
# La luz de las runas sigue a la escala del hueso «nucleo» de cada fotograma (como hace coloso_falla_3d.gd), y en la
# fase 1 el brillo de las grietas vulnerables está escondido (como en el combate, salvo que se señalen).
#
#   blender -b <coloso_falla.blend de crear_coloso.py> -P capturas_coloso.py -- <carpeta de salida>
import bpy, sys, math, os
import numpy as np
from mathutils import Vector

SALIDA = sys.argv[sys.argv.index("--") + 1]
os.makedirs(SALIDA, exist_ok=True)
sc = bpy.context.scene
arm = bpy.data.objects["Coloso"]
ad = arm.animation_data
for t in ad.nla_tracks:
    t.mute = True

motores = [i.identifier for i in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in motores else ("BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in motores else "BLENDER_WORKBENCH")
print("MOTOR", sc.render.engine)
ANCHO, ALTO = 560, 600
sc.render.resolution_x, sc.render.resolution_y = ANCHO, ALTO
sc.render.resolution_percentage = 100
sc.render.film_transparent = False
sc.render.image_settings.file_format = "PNG"
mundo = bpy.data.worlds.new("fondo")
sc.world = mundo
mundo.use_nodes = True
fondo = mundo.node_tree.nodes.get("Background")
fondo.inputs["Color"].default_value = (0.24, 0.25, 0.34, 1)        # la niebla fría de la Garganta
fondo.inputs["Strength"].default_value = 0.6
try:
    sc.view_settings.view_transform = "Standard"
except Exception:
    pass

bpy.ops.mesh.primitive_plane_add(size=14, location=(0, 0, 0))
suelo = bpy.context.active_object
ms = bpy.data.materials.new("suelo")
ms.use_nodes = True
ms.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.16, 0.14, 0.13, 1)
ms.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
suelo.data.materials.append(ms)


def sol(nombre, color, energia, rot):
    l = bpy.data.lights.new(nombre, "SUN")
    l.color = color
    l.energy = energia
    o = bpy.data.objects.new(nombre, l)
    o.rotation_euler = [math.radians(a) for a in rot]
    sc.collection.objects.link(o)
    return o


sol("principal", (1.0, 0.92, 0.80), 3.0, (50, 0, -35))         # biblia de arte: dorada arriba a la izquierda
sol("relleno", (0.52, 0.60, 0.90), 1.0, (70, 0, 150))           # relleno frío

cam_d = bpy.data.cameras.new("camara")
cam_d.type = "ORTHO"
cam = bpy.data.objects.new("camara", cam_d)
sc.collection.objects.link(cam)
sc.camera = cam

txt_d = bpy.data.curves.new("rotulo", "FONT")
txt = bpy.data.objects.new("rotulo", txt_d)
sc.collection.objects.link(txt)
mt = bpy.data.materials.new("rotulo")
mt.use_nodes = True
nodos = mt.node_tree.nodes
nodos["Principled BSDF"].inputs["Base Color"].default_value = (1, 1, 1, 1)
nodos["Principled BSDF"].inputs["Emission Color"].default_value = (1, 1, 0.8, 1)
nodos["Principled BSDF"].inputs["Emission Strength"].default_value = 2.0
txt_d.materials.append(mt)
txt.parent = cam

RUNAS = bpy.data.materials["runas"].node_tree.nodes["Principled BSDF"]


def encuadre(dir_xy, alto=5.6, centro=2.25, elev=12.0):
    """Cámara ortográfica mirando al punto (0, 0, centro) desde la dirección horizontal dir_xy."""
    d = Vector((dir_xy[0], dir_xy[1], 0)).normalized()
    e = math.radians(elev)
    pos = Vector((0, 0, centro)) + (d * math.cos(e) + Vector((0, 0, math.sin(e)))) * 14.0
    cam.location = pos
    cam.rotation_euler = (Vector((0, 0, centro)) - pos).to_track_quat("-Z", "Y").to_euler()
    cam_d.ortho_scale = alto * ANCHO / ALTO if ANCHO > ALTO else alto
    alto_v = cam_d.ortho_scale * min(1.0, ALTO / ANCHO)
    ancho_v = alto_v * ANCHO / ALTO
    txt.location = (-ancho_v * 0.47, alto_v * 0.42, -2)
    txt.scale = (0.19, 0.19, 0.19)


COMBATE = (-0.8, -0.6)       # en Godot mira a (0,8; 0; 0,6) y la cámara está en +Z


def curvas(accion):
    res = []
    for capa in accion.layers:
        for tira in capa.strips:
            for bolsa in tira.channelbags:
                res += list(bolsa.fcurves)
    return res


def accion(nombre, fase=1):
    """Pone el clip. En la fase 1 el brillo de las grietas vulnerables está escondido, como lo esconde
    coloso_falla_3d.gd en el combate (aquí: se silencian sus curvas de escala y se deja a 0,01)."""
    a = bpy.data.actions[nombre]
    ad.action = a
    if hasattr(ad, "action_slot") and len(a.slots) > 0:
        ad.action_slot = a.slots[0]
    esconder = fase == 1 and nombre != "fase2"
    for fc in curvas(a):
        if fc.data_path.endswith(".scale") and '"grietas"' in fc.data_path:
            fc.mute = esconder
    if esconder:
        arm.pose.bones["grietas"].scale = (0.01, 0.01, 0.01)
    return a


def luz():
    """Brillo de las runas según la escala del hueso «nucleo» (la misma cuenta que coloso_falla_3d.gd)."""
    s = arm.pose.bones["nucleo"].scale.x
    RUNAS.inputs["Emission Strength"].default_value = max(0.0, min(2.6, 1.0 + (s - 1.0) * 2.6)) * 1.6


def render(nombre_archivo, rotulo):
    luz()
    txt_d.body = rotulo
    ruta = os.path.join(SALIDA, nombre_archivo)
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
    return ruta


def hoja(rutas, salida, columnas=4):
    imgs = []
    for r in rutas:
        im = bpy.data.images.load(r)
        a = np.array(im.pixels[:], dtype=np.float32).reshape(im.size[1], im.size[0], 4)
        imgs.append(a)
        bpy.data.images.remove(im)
    h, w = imgs[0].shape[:2]
    columnas = min(columnas, len(imgs))
    filas = (len(imgs) + columnas - 1) // columnas
    lienzo = np.zeros((filas * h, columnas * w, 4), dtype=np.float32)
    lienzo[..., 3] = 1
    for i, a in enumerate(imgs):
        f, c = i // columnas, i % columnas
        y0 = (filas - 1 - f) * h
        lienzo[y0:y0 + h, c * w:(c + 1) * w] = a
    out = bpy.data.images.new("hoja", columnas * w, filas * h, alpha=True)
    out.pixels[:] = lienzo.ravel()
    out.filepath_raw = salida
    out.file_format = "PNG"
    out.save()
    bpy.data.images.remove(out)


# (clip, [(fotograma de Blender, rótulo)])
MOMENTOS = {
    "reposo": [(1, "inicio"), (22, "se mece"), (43, "respira"), (85, "fin = inicio")],
    "ataque": [(1, "reposo"), (11, "echa el brazo"), (16, "puñetazo"), (19, "IMPACTO 0,60 s"), (26, "sigue"), (46, "reposo")],
    "carga": [(1, "brazo atrás"), (6, "las runas laten"), (16, "laten"), (37, "fin = inicio")],
    "golpe_fuerte": [(1, "desde la carga"), (7, "vuelta"), (12, "en alto"), (18, "cae"), (21, "IMPACTO 0,67 s"),
                     (24, "lascas y rocas"), (28, "rocas en el aire"), (38, "caen"), (63, "reposo")],
    "herido": [(1, "reposo"), (4, "golpe 0,10 s"), (10, "rebote"), (24, "reposo")],
    "fase2": [(1, "reposo"), (14, "se recoge"), (24, "las runas arden"), (32, "PLACAS 1,03 s"), (38, "placas abiertas"),
              (78, "reposo fase 2")],
    "derrota": [(1, "reposo"), (10, "se agrieta"), (18, "tiembla"), (28, "cede"), (40, "de rodillas"), (76, "final")],
    "dormido": [(1, "estatua"), (46, "las runas apenas respiran"), (91, "fin = inicio")],
}

for clip, momentos in MOMENTOS.items():
    accion(clip)
    encuadre(COMBATE)
    rutas = []
    for f, rot in momentos:
        sc.frame_set(f)
        t = (f - 1) / 30.0
        rutas.append(render("%s_f%02d.png" % (clip, f), "%s  %.2f s\n%s" % (clip, t, rot)))
    hoja(rutas, os.path.join(SALIDA, "hoja_%s.png" % clip))
    print("HOJA", clip)

# vistas del modelo en reposo: combate, frente, perfil y espalda; la fase 2 (placas y grietas) y el dormido
accion("reposo")
sc.frame_set(1)
vistas = []
for nombre, d in [("combate", COMBATE), ("frente", (0, -1)), ("perfil", (-1, 0)), ("espalda", (0.5, 1))]:
    encuadre(d)
    vistas.append(render("vista_%s.png" % nombre, "reposo · %s" % nombre))
accion("reposo", fase=2)
sc.frame_set(1)
encuadre((0.5, 1))
vistas.append(render("vista_grieta_espalda.png", "grietas señaladas · espalda"))
accion("fase2")
sc.frame_set(78)
encuadre(COMBATE)
vistas.append(render("vista_fase2_placas.png", "fase 2 · placas y grietas"))
encuadre((0, -1))
vistas.append(render("vista_fase2_frente.png", "fase 2 · frente"))
accion("dormido")
sc.frame_set(1)
encuadre((-0.5, -1))
vistas.append(render("vista_dormido.png", "dormido · estatua"))
hoja(vistas, os.path.join(SALIDA, "hoja_vistas.png"))
print("FIN")
