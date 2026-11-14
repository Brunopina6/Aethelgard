# Nix piloto FBX: inspección del esqueleto de Lya (rig común de los héroes v2) para reutilizarlo.
#   blender -b --factory-startup -P p3_ver_lya.py -- <fbx de Lya>
import sys, bpy
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=argv[0])
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
print("ARM", arm.name, tuple(round(v, 4) for v in arm.rotation_euler), tuple(round(v, 4) for v in arm.scale))
mw = arm.matrix_world
for b in arm.data.bones:
    h = mw @ b.head_local; t = mw @ b.tail_local
    print("HUESO %-34s padre %-28s def %d  cab (%.3f %.3f %.3f) cola (%.3f %.3f %.3f)" % (
        b.name, b.parent.name if b.parent else "-", b.use_deform, h.x, h.y, h.z, t.x, t.y, t.z))
for a in bpy.data.actions:
    print("ACCION", a.name, tuple(a.frame_range))
for o in bpy.data.objects:
    if o.type == 'MESH':
        print("MALLA", o.name, len(o.data.polygons), [g.name for g in o.vertex_groups][:5], len(o.vertex_groups))
