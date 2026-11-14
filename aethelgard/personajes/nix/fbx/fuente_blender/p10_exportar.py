# Exporta el GLB de Nix con las MISMAS opciones que p8_vestuario.py (apartado 12).
#   blender -b --factory-startup -P p10_exportar.py -- <blend> <glb salida>
import bpy, sys, os
a = sys.argv[sys.argv.index("--") + 1:]
BLEND, GLB = a[:2]
bpy.ops.wm.open_mainfile(filepath=BLEND)
arm = bpy.data.objects["nix_esqueleto"]
cuerpo = bpy.data.objects["cuerpo_nix"]
ropa = bpy.data.objects["ropa_nix"]
arm.data.pose_position = 'POSE'
for im in bpy.data.images:
    if im.filepath:
        print("IMAGEN", im.name, im.filepath, tuple(im.size))
print("ACCIONES", len(bpy.data.actions), sorted(a_.name for a_ in bpy.data.actions))
os.makedirs(os.path.dirname(GLB), exist_ok=True)
for o in bpy.data.objects:
    o.select_set(o in (arm, cuerpo, ropa))
bpy.context.view_layer.objects.active = arm
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
op = dict(filepath=GLB, export_format='GLB', use_selection=True, export_animations=True,
          export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
for k, v in [("export_image_format", 'WEBP'), ("export_image_quality", 90), ("export_frame_range", False),
             ("export_anim_slide_to_zero", True), ("export_def_bones", False)]:
    if k in props:
        op[k] = v
bpy.ops.export_scene.gltf(**op)
tri_c = sum(len(p.vertices) - 2 for p in cuerpo.data.polygons)
tri_r = sum(len(p.vertices) - 2 for p in ropa.data.polygons)
print("TOTAL triángulos cuerpo", tri_c, "ropa", tri_r, "total", tri_c + tri_r)
print("GLB", GLB, os.path.getsize(GLB))
