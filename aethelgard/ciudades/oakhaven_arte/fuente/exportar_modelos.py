# Guarda el modelo 3D de cada pieza de Oakhaven (T-089) para el Oakhaven 3D de la fase siguiente:
#   modelos/<id>.blend  la pieza tal cual se hornea: mallas con sus modificadores, materiales de procedimiento
#                       (piedra, teja, madera…), luces prácticas (ventanas, faroles, velas), el cielo de la hora azul
#                       y la cámara de 3/4. Se abre en Blender 5.2.
#   modelos/<id>.glb    la misma geometría con los modificadores aplicados y colores planos (glTF no entiende los
#                       nodos de textura de procedimiento), más las imágenes del tapiz, el sello y los anillos.
# Las piezas están en su sitio de la ciudad: 1 casilla = 1 m; Blender (x, −y, z) → glTF/Godot 3D (x, z arriba, y al
# sur). Las casas de relleno (casa_*) y las piezas sueltas (farol, ropa_tendida) están en el origen.
# Uso: blender -b --factory-startup -P exportar_modelos.py -- <ids separados por comas> <carpeta .blend> [<carpeta .glb>]
# En el repositorio van los .blend (las fuentes completas, pocos KB); los .glb se rehacen con este script cuando hagan
# falta (el Oakhaven 3D), fuera del repositorio o donde diga la fase 3D.
import sys, os
sys.dont_write_bytecode = True          # sin __pycache__ en la carpeta del proyecto
AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import bpy
import kit as K
import piezas as P

args = sys.argv[sys.argv.index("--") + 1:]
IDS = args[0].split(",")
SALIDA = os.path.abspath(args[1])
SALIDA_GLB = os.path.abspath(args[2]) if len(args) > 2 else SALIDA
os.makedirs(SALIDA, exist_ok=True)
os.makedirs(SALIDA_GLB, exist_ok=True)


def simplificar_materiales():
    """Cada material de procedimiento pasa a un Principled liso con su color de referencia (color_base)."""
    for m in bpy.data.materials:
        if not m.use_nodes or "color_base" not in m:
            continue
        nt = m.node_tree
        if any(n.type == 'TEX_IMAGE' for n in nt.nodes):
            continue
        for n in list(nt.nodes):
            nt.nodes.remove(n)
        out = nt.nodes.new('ShaderNodeOutputMaterial')
        b = nt.nodes.new('ShaderNodeBsdfPrincipled')
        nt.links.new(b.outputs['BSDF'], out.inputs['Surface'])
        c = list(m["color_base"])
        b.inputs['Base Color'].default_value = c
        b.inputs['Roughness'].default_value = float(m.get("rugosidad", 0.85))
        b.inputs['Metallic'].default_value = float(m.get("metal", 0.0))
        if float(m.get("emision", 0.0)) > 0.0:
            b.inputs['Emission Color'].default_value = c
            b.inputs['Emission Strength'].default_value = float(m["emision"])


for pid in IDS:
    K.escena_nueva()
    K.LUCES_CIELO.clear()
    K.LUCES_PRACTICAS.clear()
    K._MATS.clear()
    ficha = P.PIEZAS[pid]()
    r = ficha["rect"]
    K.cielo_hora_azul(centro=(r[0] + r[2] * 0.5, r[1] + r[3] * 0.5))
    objs = [o for c in ficha["capas"] for o in c["objetos"] if o.type == 'MESH' and not o.hide_render]
    K.poner_camara(K.marco_pantalla(objs, 8))
    for c in ficha["capas"]:                       # cada capa, en su colección (cuerpo, letrero, copa…)
        col = bpy.data.collections.new("%s_%s" % (pid, c["nombre"]))
        bpy.context.scene.collection.children.link(col)
        for o in c["objetos"]:
            for u in list(o.users_collection):
                u.objects.unlink(o)
            col.objects.link(o)
    bpy.context.scene["oakhaven_pieza"] = pid
    bpy.context.scene["oakhaven_rect"] = list(r)
    ruta_blend = os.path.join(SALIDA, pid + ".blend")
    bpy.context.preferences.filepaths.save_version = 0      # sin copias .blend1 al volver a exportar
    bpy.ops.wm.save_as_mainfile(filepath=ruta_blend, compress=True, copy=True)
    simplificar_materiales()
    for o in bpy.context.scene.objects:            # las hojas sueltas de la copa (partículas) no van al GLB: serían
        for md in [md for md in o.modifiers if md.type == 'PARTICLE_SYSTEM']:   # cientos de miles de nodos; en el
            o.modifiers.remove(md)                 # .blend sí están
    for o in bpy.context.scene.objects:            # al GLB solo lo que es de la pieza (sin cámara ni cielo)
        o.select_set(o.type == 'MESH' and not o.hide_render)
    ruta_glb = os.path.join(SALIDA_GLB, pid + ".glb")
    opciones = dict(filepath=ruta_glb, export_format='GLB', use_selection=True, export_apply=True)
    try:
        bpy.ops.export_scene.gltf(**opciones, export_lights=False)
    except TypeError:
        bpy.ops.export_scene.gltf(**opciones)
    print("MODELO %s: %s (%d KB), %s (%d KB)" % (pid, os.path.basename(ruta_blend), os.path.getsize(ruta_blend) // 1024,
                                                 os.path.basename(ruta_glb), os.path.getsize(ruta_glb) // 1024))
