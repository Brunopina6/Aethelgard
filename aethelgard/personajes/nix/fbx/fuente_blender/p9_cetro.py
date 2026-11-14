# Nix (V12, 14/11): su CETRO propio, independiente del cuerpo; el juego lo pone en el socket «arma_d».
#   blender -b --factory-startup -P p9_cetro.py -- <glb salida> <carpeta render>
# Medidas en metros del modelo de Nix (1,81 m en Blender): el puño (origen) está en el agarre; el eje del cetro es +Z en
# Blender (+Y en el glTF = el eje Y del hueso arma_d). Abajo 0,40 m con contera dorada; empuñadura de cuero; arriba un
# aro dorado con la estrella de seis puntas de dos triángulos (el motivo de su emblema) y una amatista en el centro.
# La punta mágica (el centro de la amatista) está a 0,50 m del puño. Un material, textura de 128 con cuatro muestras
# (negro lacado, oro envejecido, cuero y amatista) y la amatista con emisión suave.
import sys, os, math
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
GLB, REND = argv[:2]
import bpy, bmesh
import numpy as np
from mathutils import Vector, Matrix
os.makedirs(REND, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

PUNTA = 0.50
MUESTRA = {"negro": (0.25, 0.75), "oro": (0.75, 0.75), "cuero": (0.25, 0.25), "gema": (0.75, 0.25)}
bm = bmesh.new()
uvl = bm.loops.layers.uv.new("UVMap")


def marcar(caras, zona):
    cu, cv = MUESTRA[zona]
    for f in caras:
        for i, l in enumerate(f.loops):
            l[uvl].uv = (cu + 0.06 * math.cos(i * 2.1), cv + 0.06 * math.sin(i * 2.1))


def cilindro(z0, z1, r0, r1, n, zona):
    r = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=n, radius1=r0, radius2=r1, depth=z1 - z0)
    for v in r["verts"]:
        v.co.z += (z0 + z1) * 0.5
    marcar({f for v in r["verts"] for f in v.link_faces}, zona)


def esfera(c, rad, zona, sub=1, esc=(1, 1, 1)):
    r = bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=rad)
    for v in r["verts"]:
        v.co = Vector((v.co.x * esc[0], v.co.y * esc[1], v.co.z * esc[2])) + Vector(c)
    marcar({f for v in r["verts"] for f in v.link_faces}, zona)


def toro(c, R, r, n, m, zona):
    """Aro vertical (en el plano XZ) centrado en c."""
    vs = []
    for i in range(n):
        a = 2 * math.pi * i / n
        fila = []
        for j in range(m):
            b = 2 * math.pi * j / m
            p = Vector(((R + r * math.cos(b)) * math.cos(a), r * math.sin(b), (R + r * math.cos(b)) * math.sin(a)))
            fila.append(bm.verts.new(p + Vector(c)))
        vs.append(fila)
    caras = []
    for i in range(n):
        for j in range(m):
            caras.append(bm.faces.new((vs[i][j], vs[(i + 1) % n][j], vs[(i + 1) % n][(j + 1) % m], vs[i][(j + 1) % m])))
    marcar(caras, zona)


def barra(a, b, g, zona):
    """Prisma de 4 caras de a a b (en el plano XZ), de grosor g."""
    a, b = Vector(a), Vector(b)
    d = (b - a).normalized()
    n1 = Vector((0, 1, 0)) * g
    n2 = d.cross(Vector((0, 1, 0))).normalized() * g
    vs = [bm.verts.new(p) for p in (a + n1 + n2, a - n1 + n2, a - n1 - n2, a + n1 - n2,
                                     b + n1 + n2, b - n1 + n2, b - n1 - n2, b + n1 - n2)]
    caras = [bm.faces.new((vs[i], vs[(i + 1) % 4], vs[4 + (i + 1) % 4], vs[4 + i])) for i in range(4)]
    caras.append(bm.faces.new(vs[3::-1])); caras.append(bm.faces.new(vs[4:]))
    marcar(caras, zona)


# asta
cilindro(-0.38, 0.40, 0.012, 0.013, 8, "negro")
cilindro(-0.07, 0.07, 0.0145, 0.0145, 8, "cuero")                  # empuñadura
for z in (-0.075, 0.075, 0.25, 0.38):
    cilindro(z - 0.006, z + 0.006, 0.0175, 0.0175, 8, "oro")      # anillos
cilindro(-0.40, -0.38, 0.008, 0.016, 8, "oro")                      # contera
esfera((0, 0, -0.405), 0.012, "oro")
cilindro(0.40, 0.43, 0.014, 0.022, 8, "oro")                        # cuello del cabezal
# cabezal: aro con la estrella de seis puntas (dos triángulos) y la amatista
C = (0, 0, PUNTA)
toro(C, 0.062, 0.0055, 20, 6, "oro")
R = 0.058
for desfase in (90.0, 270.0):
    pts = [(R * math.cos(math.radians(desfase + k * 120)), 0, PUNTA + R * math.sin(math.radians(desfase + k * 120)))
           for k in range(3)]
    for k in range(3):
        barra(pts[k], pts[(k + 1) % 3], 0.0032, "oro")
esfera(C, 0.020, "gema", 1, (0.75, 0.75, 1.25))                      # amatista (alargada)
for ang in (-35, 0, 35):                                             # tres puntas arriba
    a = math.radians(90 + ang)
    base = Vector((0.062 * math.cos(a), 0, PUNTA + 0.062 * math.sin(a)))
    barra(base, base + Vector((math.cos(a), 0, math.sin(a))) * (0.030 if ang == 0 else 0.020), 0.003, "oro")
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
me = bpy.data.meshes.new("cetro_nix")
bm.to_mesh(me); bm.free()
me.shade_smooth()
try:
    me.set_sharp_from_angle(angle=math.radians(40))
except Exception:
    pass
o = bpy.data.objects.new("cetro_nix", me)
bpy.context.scene.collection.objects.link(o)
print("CETRO triángulos", sum(len(p.vertices) - 2 for p in me.polygons))

# textura de 128: color, metal/rugosidad y emisión
S = 128
col = np.zeros((S, S, 4), np.float32); col[..., 3] = 1
mrt = np.ones((S, S, 4), np.float32)
emi = np.zeros((S, S, 4), np.float32); emi[..., 3] = 1
for zona, (cu, cv) in MUESTRA.items():
    ys, xs = slice(int((cv - 0.25) * S), int((cv + 0.25) * S)), slice(int((cu - 0.25) * S), int((cu + 0.25) * S))
    c, r, m = {"negro": ((0.05, 0.04, 0.06), 0.35, 0.0), "oro": ((0.76, 0.58, 0.30), 0.35, 0.5),
               "cuero": ((0.22, 0.13, 0.08), 0.65, 0.0), "gema": ((0.60, 0.24, 0.92), 0.10, 0.0)}[zona]
    col[ys, xs, :3] = c
    mrt[ys, xs, 1] = r; mrt[ys, xs, 2] = m
    if zona == "gema":
        emi[ys, xs, :3] = (0.55, 0.20, 0.85)


def imagen(nombre, arr, nc=False):
    im = bpy.data.images.new(nombre, S, S, alpha=False)
    im.pixels.foreach_set(arr.ravel())
    im.filepath_raw = os.path.join(os.path.dirname(GLB), nombre + ".png")
    im.file_format = 'PNG'
    im.save(); im.reload()
    if nc:
        im.colorspace_settings.name = 'Non-Color'
    return im


mat = bpy.data.materials.new("cetro_nix")
mat.use_nodes = True
nt = mat.node_tree
b = nt.nodes["Principled BSDF"]
t1 = nt.nodes.new("ShaderNodeTexImage"); t1.image = imagen("cetro_nix_color", col)
t2 = nt.nodes.new("ShaderNodeTexImage"); t2.image = imagen("cetro_nix_mr", mrt, True)
t3 = nt.nodes.new("ShaderNodeTexImage"); t3.image = imagen("cetro_nix_brillo", emi)
sep = nt.nodes.new("ShaderNodeSeparateColor")
nt.links.new(t1.outputs["Color"], b.inputs["Base Color"])
nt.links.new(t2.outputs["Color"], sep.inputs["Color"])
nt.links.new(sep.outputs["Green"], b.inputs["Roughness"])
nt.links.new(sep.outputs["Blue"], b.inputs["Metallic"])
nt.links.new(t3.outputs["Color"], b.inputs["Emission Color"])
b.inputs["Emission Strength"].default_value = 1.0
me.materials.append(mat)

# render de comprobación (de frente y de lado)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nix_comun as Cm
for nombre, yaw in (("frente", 0), ("perfil", 90)):
    Cm._limpiar(); Cm.config_render(500, 700, 32); Cm.escena_luz()
    Cm.camara(Vector((0, 0, 0.06)), yaw, 0, 1.05)
    bpy.context.scene.render.filepath = os.path.join(REND, "cetro_" + nombre + ".png")
    bpy.ops.render.render(write_still=True)
for x in list(bpy.data.objects):
    x.select_set(x is o)
bpy.ops.export_scene.gltf(filepath=GLB, export_format='GLB', use_selection=True, export_animations=False,
                          export_image_format='WEBP', export_image_quality=90)
print("GLB", GLB, os.path.getsize(GLB))
print("FIN")
