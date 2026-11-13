# ESBOZO del terreno de las Cumbres de Ciclópea 3D (V12, especialista de mundo, 13/11). No es arte del juego: una
# maqueta para decidir el relieve antes de construir la región (docs/v12/INVENTARIO_MUNDO.md §8).
#   blender -b --factory-startup -P fuente/esbozo_ciclopea.py -- <carpeta con relieve.png, plano_2d.png y ciclopea_2d.json>
# Lee lo que escribe pruebas/herramientas/volcar_ciclopea_2d.gd (la disposición de la zona 2D del lugar 3 y el relieve
# propuesto) y renderiza dos vistas: desde la entrada del sur, a la altura de la cámara del juego, y de arriba.
import bpy, sys, os, math, json, random
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
CARPETA = argv[0]
CASILLA = 1.25                      # m por casilla, como el Gran Bosque 3D
datos = json.load(open(os.path.join(CARPETA, "ciclopea_2d.json"), encoding="utf-8"))
K = datos["px_por_casilla"]
ALTO_MAX = datos["alto_max_m"]

bpy.ops.wm.read_factory_settings(use_empty=True)
esc = bpy.context.scene
rel = bpy.data.images.load(os.path.join(CARPETA, "relieve.png"))
pla = bpy.data.images.load(os.path.join(CARPETA, "plano_2d.png"))
w, h = rel.size
R = np.array(rel.pixels[:]).reshape(h, w, 4)[:, :, 0]          # fila 0 = abajo de la imagen (el sur)
paso = 2
xs, ys = list(range(0, w, paso)), list(range(0, h, paso))
verts, caras, uvs = [], [], []
for j, y in enumerate(ys):
    for i, x in enumerate(xs):
        verts.append(((x / K) * CASILLA, (y / K) * CASILLA, float(R[y, x]) * ALTO_MAX))
nx = len(xs)
for j in range(len(ys) - 1):
    for i in range(nx - 1):
        caras.append((j * nx + i, j * nx + i + 1, (j + 1) * nx + i + 1, (j + 1) * nx + i))
me = bpy.data.meshes.new("relieve")
me.from_pydata(verts, [], caras)
uv = me.uv_layers.new()
for p in me.polygons:
    p.use_smooth = True
    for li in p.loop_indices:
        v = me.vertices[me.loops[li].vertex_index].co
        uv.data[li].uv = (v.x / CASILLA * K / w, v.y / CASILLA * K / h)
ob = bpy.data.objects.new("relieve", me)
esc.collection.objects.link(ob)
m = bpy.data.materials.new("plano")
m.use_nodes = True
tex = m.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = pla
bsdf = m.node_tree.nodes["Principled BSDF"]
m.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.9
me.materials.append(m)
# pinos nevados de maqueta (conos) sobre la nieve, lejos del camino y de las paredes
P = np.array(pla.pixels[:]).reshape(h, w, 4)
pino = bpy.data.materials.new("pino")
pino.use_nodes = True
pino.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.16, 0.30, 0.24, 1)
random.seed(datos["semilla"])
puestos = 0
for _ in range(6000):
    x, y = random.randrange(0, w), random.randrange(0, h)
    r, g, b = P[y, x, :3]
    if not (b > 0.7 and r > 0.6 and abs(r - g) < 0.08):           # solo nieve (ni camino, ni roca, ni hielo)
        continue
    alt = float(R[y, x]) * ALTO_MAX
    bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=0.9, depth=random.uniform(3.0, 5.5),
                                    location=((x / K) * CASILLA, (y / K) * CASILLA, alt + 1.6))
    bpy.context.active_object.data.materials.append(pino)
    puestos += 1
    if puestos >= 220:
        break
# luz y cielo de montaña
w_ = bpy.data.worlds.new("cielo")
esc.world = w_
w_.use_nodes = True
w_.node_tree.nodes["Background"].inputs[0].default_value = (0.70, 0.78, 0.90, 1)
w_.node_tree.nodes["Background"].inputs[1].default_value = 0.7
sol = bpy.data.objects.new("sol", bpy.data.lights.new("sol", 'SUN'))
sol.data.energy = 3.5
sol.rotation_euler = (math.radians(50), 0, math.radians(30))
esc.collection.objects.link(sol)
esc.render.engine = 'BLENDER_EEVEE'
esc.render.resolution_x, esc.render.resolution_y = 1600, 900
ancho, largo = w / K * CASILLA, h / K * CASILLA
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
esc.collection.objects.link(cam)
esc.camera = cam
salida_x = datos["salida_x"] * CASILLA


def mirar(pos, objetivo, lente):
    from mathutils import Vector
    cam.location = pos
    cam.rotation_euler = (Vector(objetivo) - Vector(pos)).to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = lente


# desde la entrada (el sur está en y pequeña: fila 0 de la imagen = abajo del plano)
mirar((salida_x, -14.0, 16.0), (ancho * 0.5, largo * 0.45, 4.0), 28)
esc.render.filepath = os.path.join(CARPETA, "esbozo_desde_la_entrada.png")
bpy.ops.render.render(write_still=True)
mirar((ancho * 0.5, largo * 0.45, 120.0), (ancho * 0.5, largo * 0.451, 0.0), 30)
esc.render.filepath = os.path.join(CARPETA, "esbozo_de_arriba.png")
bpy.ops.render.render(write_still=True)
print("ESBOZO", len(verts), "vértices,", puestos, "pinos")
