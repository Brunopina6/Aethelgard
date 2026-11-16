# BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11, EN PRUEBAS): LOS UTENSILIOS (agente B) para las rutinas de C y los
# sitios de los interiores. Geometría procedural propia con el kit de fuente/crear_interiores.py (sin horneado: se
# mueven, así que su luz la pone Godot).
#
#   blender -b --factory-startup -P crear_utensilios_barrio.py -- <carpeta zonas3d/barrio>
#
# Escribe:
#   modelos/utensilios.glb         un objeto por utensilio, con su ORIGEN EN EL PUNTO DE AGARRE (el pivote):
#                                    bandeja, cesta_pan, caja, saco_harina, cepillo, cubo, galga, pasador, pasador_roto
#                                  Ejes (Godot): +Y arriba, −Z hacia delante (lejos del cuerpo de quien lo lleva). Lo
#                                  que se lleva con dos manos al pecho (bandeja, caja, saco_harina) tiene el agarre en el
#                                  borde que toca el cuerpo; lo de una mano (cesta_pan, cubo: el asa; cepillo, galga,
#                                  pasador, pasador_roto: el mango o el medio) lo tiene donde cierra la mano.
#                                  Cada uno ≤ 300 triángulos, UN material opaco «utensilio» (COLOR_0 = tinte lineal,
#                                  UV0 = el atlas).
#   modelos/utensilios_atlas.png   el atlas (256², gris: el color lo pone el tinte): madera, mimbre, tela, metal.
#   modelos/utensilios.json        triángulos y caja de cada uno (para las pruebas y C).
import bpy, bmesh, sys, os, math, json
from mathutils import Vector
import numpy as np

sys.dont_write_bytecode = True                                        # (sin __pycache__ en la carpeta)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crear_interiores as K                                         # el kit (main() no corre al importar)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
CARPETA = argv[0] if argv else ""
NOMBRES = ["bandeja", "cesta_pan", "caja", "saco_harina", "cepillo", "cubo", "galga", "pasador", "pasador_roto"]
CUADRANTE = {"madera": (0, 0), "barro": (0, 0), "tela": (1, 0), "mimbre": (0, 1), "hierro": (1, 1)}
LADO = 256


def atlas(carpeta):
    rng = np.random.default_rng(11)
    n = LADO // 2
    img = np.zeros((LADO, LADO), np.float32)
    yy, xx = np.mgrid[0:n, 0:n]
    madera = 0.8 + 0.1 * np.sin(xx * 0.9 + 3.0 * np.sin(yy * 0.05)) * 0.6 + 0.06 * (rng.random((n, n)) - 0.5)
    tela = 0.88 + 0.06 * np.sin(xx * 1.6) * np.sin(yy * 1.6) + 0.05 * (rng.random((n, n)) - 0.5)
    mimbre = 0.82 + 0.12 * (((xx // 6) + (yy // 6)) % 2 - 0.5) + 0.05 * (rng.random((n, n)) - 0.5)
    metal = 0.86 + 0.06 * (rng.random((n, n)) - 0.5)
    img[0:n, 0:n] = madera
    img[0:n, n:] = tela
    img[n:, 0:n] = mimbre
    img[n:, n:] = metal
    px = np.ones((LADO, LADO, 4), np.float32)
    px[..., 0] = px[..., 1] = px[..., 2] = np.clip(img[::-1], 0, 1)          # (Blender guarda de abajo arriba)
    im = bpy.data.images.new("utensilios_atlas", LADO, LADO, alpha=False)
    im.pixels.foreach_set(px.ravel())
    im.filepath_raw = os.path.join(carpeta, "utensilios_atlas.png")
    im.file_format = 'PNG'
    im.save()
    return im


def uv_atlas(pts, mat):
    """Proyección plana de la cara, desde su esquina, dentro del cuadrante de su material (0,5 m por cuadrante)."""
    base = K.uv_mundo(pts, "madera")
    u0 = min(u for u, v in base)
    v0 = min(v for u, v in base)
    qx, qy = CUADRANTE.get(mat, (0, 0))
    r = []
    for u, v in base:
        uu = min(0.96, (u - u0) * 1.3 / 0.5)
        vv = min(0.96, (v - v0) * 1.3 / 0.5)
        r.append((qx * 0.5 + 0.01 + uu * 0.48, qy * 0.5 + 0.01 + vv * 0.48))
    return r


def a_blender(nombre, M, mat_b):
    verts, polys, cols, uvs = [], [], [], []
    for pts, mat, cs, uv, suave in M.caras:
        b = len(verts)
        for p in pts:
            verts.append((p.x, -p.z, p.y))
        polys.append(list(range(b, b + len(pts))))
        cols.extend(cs)
        uvs.extend(uv_atlas(pts, mat))
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], polys)
    uvl = me.uv_layers.new(name="UVMap")
    uvl.data.foreach_set("uv", np.array(uvs, np.float32).ravel())
    ca = me.color_attributes.new("Col", 'FLOAT_COLOR', 'CORNER')
    ca.data.foreach_set("color", np.array(cols, np.float32).ravel())
    me.materials.append(mat_b)
    me.validate()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bm.to_mesh(me)
    bm.free()
    me.color_attributes.active_color = me.color_attributes["Col"]
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def utensilios():
    V = Vector
    u = {}
    # bandeja (al pecho, dos manos): tablero de 0,56 × 0,38 con reborde y cuatro panes; agarre en el borde del cuerpo
    M = K.Malla()
    K.caja_mm(M, (-0.28, -0.02, -0.38), (0.28, 0.0, 0.0), "madera", K.MADERA_CLARA, veta="larga")
    for a, b in (((-0.28, 0.0, -0.38), (0.28, 0.05, -0.36)), ((-0.28, 0.0, -0.02), (0.28, 0.05, 0.0)),
                 ((-0.28, 0.0, -0.36), (-0.26, 0.05, -0.02)), ((0.26, 0.0, -0.36), (0.28, 0.05, -0.02))):
        K.caja_mm(M, a, b, "madera", K.MADERA, veta="larga")
    for x, z in ((-0.13, -0.11), (0.13, -0.11), (-0.13, -0.27), (0.13, -0.27)):
        K.hogaza(M, V((x, 0.0, z)), 0.085, 0.07, n=6)
    u["bandeja"] = M
    # cesta_pan (una mano, por el asa): la cesta cuelga bajo la mano
    M = K.Malla()
    K.cesta(M, V((0.0, -0.36, 0.0)), 0.17, 0.15, K.MIMBRE, asa=False)
    for k in range(6):
        a0, a1 = math.pi * k / 6, math.pi * (k + 1) / 6
        K.viga(M, V((math.cos(a0) * 0.15, -0.21 + math.sin(a0) * 0.2, 0)), V((math.cos(a1) * 0.15, -0.21 + math.sin(a1) * 0.2, 0)),
               0.02, "tela", K.MIMBRE)
    for k in range(3):
        K.hogaza(M, V((-0.06 + k * 0.06, -0.23 + (k % 2) * 0.02, (k - 1) * 0.04)), 0.07, 0.06, n=6)
    u["cesta_pan"] = M
    # caja (al pecho): cajón de listones de 0,5 × 0,32 × 0,34; agarre en la cara del cuerpo, a media altura
    M = K.Malla()
    K.caja_mm(M, (-0.25, -0.16, -0.34), (0.25, 0.16, 0.0), "madera", K.MADERA_GRIS, veta="larga")
    for y in (-0.1, 0.06):
        K.caja_mm(M, (-0.255, y, -0.345), (0.255, y + 0.06, 0.005), "madera", K.MADERA, veta="larga")
    for x in (-0.24, 0.24):
        K.caja_mm(M, (x - 0.02, -0.16, -0.345), (x + 0.02, 0.16, 0.005), "madera", K.MADERA_OSC, veta="larga")
    u["caja"] = M
    # saco_harina (al pecho): el saco de pie entre los brazos; agarre en su costado
    M = K.Malla()
    K.saco(M, V((0.0, -0.3, -0.2)), 0.2, 0.55, K.SACO)
    u["saco_harina"] = M
    # cepillo (una mano): la correa y el cuerpo con las cerdas abajo; agarre en la correa
    M = K.Malla()
    K.caja_mm(M, (-0.1, -0.05, -0.045), (0.1, -0.01, 0.045), "madera", K.MADERA_OSC, veta="larga")
    K.caja_mm(M, (-0.095, -0.09, -0.04), (0.095, -0.05, 0.04), "tela", (0.30, 0.22, 0.16))
    K.caja_mm(M, (-0.07, -0.01, -0.015), (0.07, 0.015, 0.015), "tela", (0.42, 0.28, 0.18))
    u["cepillo"] = M
    # cubo (una mano, por el asa): balde de duelas con dos aros de hierro y asa de cuerda
    M = K.Malla()
    K.cilindro(M, V((0.0, -0.62, 0.0)), [(0, 0.13), (0.3, 0.16)], 10, "madera", K.MADERA, tapa_abajo=True, tapa_arriba=False)
    K.cilindro(M, V((0.0, -0.36, 0.0)), [(0, 0.15), (0, 0.0)], 10, "hierro", (0.30, 0.36, 0.40), tapa_arriba=False)
    for y in (-0.58, -0.38):
        K.cilindro(M, V((0.0, y, 0.0)), [(0, 0.142 + (y + 0.58) * 0.1), (0.025, 0.145 + (y + 0.58) * 0.1)], 10, "hierro",
                   K.HIERRO, tapa_arriba=False)
    for k in range(5):
        a0, a1 = math.pi * k / 5, math.pi * (k + 1) / 5
        K.viga(M, V((math.cos(a0) * 0.16, -0.32 + math.sin(a0) * 0.3, 0)), V((math.cos(a1) * 0.16, -0.32 + math.sin(a1) * 0.3, 0)),
               0.015, "tela", (0.70, 0.62, 0.46))
    u["cubo"] = M
    # galga (una mano, por el agujero de colgar): la regla con los escalones de medir hacia delante (−Z), de canto
    M = K.Malla()
    forma = [(z, y) for z, y in K.galga_2d()]
    K.placa(M, list(reversed([(-p[0] + 0.03, p[1] - 0.045) for p in forma])), (0.0075, 0.0, 0.0), (0, 0, 1), (0, 1, 0), 0.015, "madera",
            K.FRESNO)
    K.caja_mm(M, (-0.009, -0.035, -0.33), (0.009, 0.035, -0.31), "hierro", K.LATON)       # la marca de latón
    u["galga"] = M
    # pasador (una mano, por el medio): el pasador nuevo de fresno, 0,22 m, con su cabeza
    M = K.Malla()
    K.cilindro(M, V((0.0, 0.0, 0.0)), [(-0.11, 0.012), (0.06, 0.02), (0.08, 0.03), (0.11, 0.03)], 7, "madera", K.FRESNO,
               rot=K.rot_eje("z"), tapa_abajo=True)
    u["pasador"] = M
    # pasador_roto: el viejo, partido en dos con el corte de desgaste (oscuro, gastado)
    M = K.Malla()
    K.cilindro(M, V((0.0, 0.0, 0.0)), [(-0.11, 0.012), (-0.02, 0.016), (-0.005, 0.012)], 7, "madera", (0.42, 0.32, 0.22),
               rot=K.rot_eje("z"), tapa_abajo=True)
    K.cilindro(M, V((0.015, 0.008, 0.0)), [(0.01, 0.014), (0.06, 0.02), (0.08, 0.03), (0.11, 0.03)], 7, "madera",
               (0.46, 0.35, 0.24), rot=K.R(y=8) @ K.rot_eje("z"), tapa_abajo=True)
    u["pasador_roto"] = M
    return u


def main():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    carpeta = os.path.join(CARPETA, "modelos")
    os.makedirs(carpeta, exist_ok=True)
    im = atlas(carpeta)
    mt = bpy.data.materials.new("utensilio")
    mt.use_nodes = True
    nt = mt.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
    objs, info = [], {}
    for nombre, M in utensilios().items():
        ob = a_blender(nombre, M, mt)
        xs = [p.x for c in M.caras for p in c[0]]
        ys = [p.y for c in M.caras for p in c[0]]
        zs = [p.z for c in M.caras for p in c[0]]
        info[nombre] = {"tris": M.tris(), "min": [min(xs), min(ys), min(zs)], "max": [max(xs), max(ys), max(zs)]}
        objs.append(ob)
        print("[utensilios] %-13s %4d triángulos" % (nombre, M.tris()))
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(carpeta, "utensilios.glb"), export_format='GLB', use_selection=True,
                              export_animations=False, export_yup=True, export_vertex_color='ACTIVE',
                              export_all_vertex_colors=False, export_cameras=False, export_lights=False, export_apply=True,
                              export_texcoords=True, export_normals=True, export_image_format='NONE',
                              export_materials='EXPORT')
    with open(os.path.join(carpeta, "utensilios.json"), "w", encoding="utf-8") as f:
        json.dump(info, f, ensure_ascii=False, indent=1)
    print("[utensilios] HECHO")


main()
