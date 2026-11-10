# Oakhaven 3D (T-103): la versión ligera de un modelo de la ciudad, para los perfiles medio y bajo (presupuesto del
# Mali-G57: ~200-300 k triángulos en pantalla). Abre el glb de gráficos, reduce las mallas con muchas caras (Decimate,
# colapso de aristas) y lo guarda como <id>_ligero.glb. Las piezas pequeñas (marcos, tejas, faroles) se quedan como están.
# Uso: blender -b --factory-startup -P aligerar.py -- <entrada.glb> <salida.glb> <proporción> [<caras mínimas>]
import sys
import bpy

args = sys.argv[sys.argv.index("--") + 1:]
ENTRADA, SALIDA, PROPORCION = args[0], args[1], float(args[2])
MINIMO = int(args[3]) if len(args) > 3 else 80

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=ENTRADA)
antes = despues = 0
for o in bpy.context.scene.objects:
    if o.type != 'MESH':
        continue
    caras = len(o.data.polygons)
    antes += caras
    if caras >= MINIMO:
        m = o.modifiers.new("ligero", 'DECIMATE')
        m.decimate_type = 'COLLAPSE'
        m.ratio = PROPORCION
        m.use_collapse_triangulate = True
bpy.context.view_layer.update()
deps = bpy.context.evaluated_depsgraph_get()
for o in bpy.context.scene.objects:
    if o.type == 'MESH':
        despues += len(o.evaluated_get(deps).data.polygons)
bpy.ops.export_scene.gltf(filepath=SALIDA, export_format='GLB', export_apply=True)
print("ALIGERADO %s: %d → %d caras" % (SALIDA, antes, despues))
