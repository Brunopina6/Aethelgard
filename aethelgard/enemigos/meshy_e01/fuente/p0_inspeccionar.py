# meshy_e01 · paso 1: inspección real del FBX de Meshy (sin modificarlo; se lee una COPIA).
#   blender -b -P p0_inspeccionar.py -- <fbx> <carpeta render> <json salida>
# Escribe: objetos, transformaciones, cotas, triángulos, piezas sueltas, normales (aristas no múltiples, caras con
# orientación incoherente, normales hacia dentro), UV (capas, fuera de 0-1, solapes aproximados), materiales e imágenes;
# y renders frente / perfil / espalda / tres cuartos de la malla tal cual y junto a un suelo.
import sys, os, json, math
sys.dont_write_bytecode = True
argv = sys.argv[sys.argv.index("--") + 1:]
FBX, REND, SALIDA = argv[:3]
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy, bmesh
from mathutils import Vector
import e01_comun as C

os.makedirs(REND, exist_ok=True)
nuevos = C.importar_fbx(FBX)
info = {"fbx": FBX, "blender": bpy.app.version_string, "objetos": []}
mallas = []
for o in nuevos:
    d = {"nombre": o.name, "tipo": o.type, "loc": list(o.location), "rot_grados": [math.degrees(a) for a in o.rotation_euler],
         "escala": list(o.scale), "padre": o.parent.name if o.parent else None}
    if o.type == 'MESH':
        mallas.append(o)
        me = o.data
        d["vertices"] = len(me.vertices)
        d["caras"] = len(me.polygons)
        d["triangulos"] = C.tris(o)
        d["grupos_vertices"] = len(o.vertex_groups)
        d["shape_keys"] = 0 if me.shape_keys is None else len(me.shape_keys.key_blocks)
        d["uv"] = [uv.name for uv in me.uv_layers]
        d["color_vertice"] = [a.name for a in me.color_attributes]
        d["materiales"] = [m.name if m else None for m in me.materials]
        mw = o.matrix_world
        cos = [mw @ v.co for v in me.vertices]
        mn = Vector((min(c.x for c in cos), min(c.y for c in cos), min(c.z for c in cos)))
        mx = Vector((max(c.x for c in cos), max(c.y for c in cos), max(c.z for c in cos)))
        d["cotas_mundo"] = {"min": list(mn), "max": list(mx), "tam": list(mx - mn)}
        # normales y topología
        bm = bmesh.new(); bm.from_mesh(me)
        no_mult = [e for e in bm.edges if not e.is_manifold]
        bordes = [e for e in bm.edges if e.is_boundary]
        incoh = 0
        for e in bm.edges:
            if len(e.link_faces) == 2:
                f1, f2 = e.link_faces
                # coherente: la arista se recorre en sentidos opuestos en las dos caras
                def sentido(f):
                    vs = list(f.verts)
                    for i in range(len(vs)):
                        if vs[i] == e.verts[0] and vs[(i + 1) % len(vs)] == e.verts[1]:
                            return 1
                        if vs[i] == e.verts[1] and vs[(i + 1) % len(vs)] == e.verts[0]:
                            return -1
                    return 0
                if sentido(f1) == sentido(f2):
                    incoh += 1
        # normales hacia fuera: proporción de caras cuya normal se aleja del centro de su pieza
        centro = (mn + mx) * 0.5
        fuera = sum(1 for f in bm.faces if f.normal.dot((mw @ f.calc_center_median()) - centro) > 0)
        degeneradas = sum(1 for f in bm.faces if f.calc_area() < 1e-10)
        dobles = 0
        bm.verts.ensure_lookup_table()
        d["normales"] = {"aristas_no_multiples": len(no_mult), "aristas_borde": len(bordes),
                         "aristas_orientacion_incoherente": incoh, "caras_hacia_fuera_del_centro": fuera,
                         "caras_total": len(bm.faces), "caras_degeneradas": degeneradas,
                         "suavizado": sum(1 for p in me.polygons if p.use_smooth)}
        # UV
        if me.uv_layers:
            uvl = bm.loops.layers.uv.active
            us = [l[uvl].uv for f in bm.faces for l in f.loops]
            fuera_uv = sum(1 for u in us if u.x < -1e-4 or u.x > 1.0001 or u.y < -1e-4 or u.y > 1.0001)
            # solape aproximado: rejilla de 256² con las caras rasterizadas por su caja
            N = 256
            celdas = {}
            area_uv = 0.0
            for f in bm.faces:
                pts = [l[uvl].uv for l in f.loops]
                a = 0.0
                for i in range(1, len(pts) - 1):
                    a += abs((pts[i] - pts[0]).cross(pts[i + 1] - pts[0])) * 0.5
                area_uv += a
                cx = sum(p.x for p in pts) / len(pts); cy = sum(p.y for p in pts) / len(pts)
                k = (int(cx * N), int(cy * N))
                celdas[k] = celdas.get(k, 0) + 1
            d["uv_info"] = {"loops": len(us), "fuera_0_1": fuera_uv, "area_uv_ocupada": round(area_uv, 4),
                            "celdas_256_con_mas_de_4_caras": sum(1 for v in celdas.values() if v > 4)}
        bm.free()
        piezas = C.componentes(o)
        d["piezas_sueltas"] = len(piezas)
        d["piezas_mayores"] = [{"vertices": p[0], "min": [round(x, 4) for x in p[1]], "max": [round(x, 4) for x in p[2]]}
                               for p in piezas[:25]]
    info["objetos"].append(d)
info["imagenes"] = [{"nombre": im.name, "tam": list(im.size), "ruta": im.filepath, "espacio": im.colorspace_settings.name}
                    for im in bpy.data.images]
mats = []
for m in bpy.data.materials:
    e = {"nombre": m.name, "nodos": []}
    if m.node_tree:
        for n in m.node_tree.nodes:
            nd = {"tipo": n.bl_idname, "nombre": n.name}
            if n.bl_idname == 'ShaderNodeTexImage' and n.image:
                nd["imagen"] = n.image.name
                nd["salidas_a"] = [l.to_socket.name + "@" + l.to_node.name for o2 in n.outputs for l in o2.links]
            e["nodos"].append(nd)
    mats.append(e)
info["materiales"] = mats
info["acciones"] = [a.name for a in bpy.data.actions]
info["armatures"] = [o.name for o in nuevos if o.type == 'ARMATURE']
json.dump(info, open(SALIDA, "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
print(json.dumps({k: v for k, v in info.items() if k != "materiales"}, ensure_ascii=False, indent=1, default=str)[:6000])

# renders tal cual (orientación original: ¿hacia dónde mira?)
o = mallas[0]
cot = info["objetos"][[x["nombre"] for x in info["objetos"]].index(o.name)]["cotas_mundo"]
alto = cot["tam"][2]
zmin = cot["min"][2]
C.suelo(zmin)
C.render_vistas(os.path.join(REND, "p0_original"), alto * 1.05, res=700, centro_z=zmin + alto * 0.5,
                vistas=[("vista_-Y", 0, 0), ("vista_+X", 90, 0), ("vista_+Y", 180, 0), ("vista_-X", 270, 0), ("tres_cuartos", 35, 10)])
print("FIN")
