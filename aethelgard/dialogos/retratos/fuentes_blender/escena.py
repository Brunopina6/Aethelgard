# Escena de render de los retratos (T-084): el modelo de Meshy del juego, la cámara del retrato original y su luz.
# - Cámara ortográfica girada YAW grados alrededor del personaje y PITCH hacia abajo (los del retrato original,
#   hallados por silueta con buscar_camara.py).
# - Luz como la de pruebas/herramientas/foto_3d.gd: sol cálido FFE2B0 desde arriba a la izquierda y por delante
#   (rotación de Godot -35°, -40°, en el sistema de la cámara) y ambiente blanco. Sin metal (el original no lo tiene).
import bpy, math, mathutils


def importar(fbx):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=fbx)
    arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
    mallas = [o for o in bpy.data.objects if o.type == 'MESH']
    return arm, mallas


def sin_metal(mallas):
    for mesh in mallas:
        for m in mesh.data.materials:
            nt = m.node_tree
            for bsdf in [n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED']:
                for l in list(nt.links):
                    if l.to_node == bsdf and l.to_socket.name == 'Metallic':
                        nt.links.remove(l)
                bsdf.inputs['Metallic'].default_value = 0.0


def config_render(res_x, res_y):
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.film_transparent = True
    sc.view_settings.view_transform = 'Standard'
    sc.view_settings.look = 'None'
    sc.render.image_settings.color_mode = 'RGBA'
    sc.render.image_settings.color_depth = '8'
    sc.render.resolution_x = res_x
    sc.render.resolution_y = res_y
    sc.render.resolution_percentage = 100
    sc.render.filter_size = 1.2
    try:
        sc.eevee.taa_render_samples = 32
    except Exception:
        pass
    return sc


def camara(centro, yaw, pitch, escala_orto):
    sc = bpy.context.scene
    cd = bpy.data.cameras.new("cam"); cd.type = 'ORTHO'; cd.ortho_scale = escala_orto
    cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam); sc.camera = cam
    d = mathutils.Vector((math.sin(math.radians(yaw)) * math.cos(math.radians(pitch)),
                          -math.cos(math.radians(yaw)) * math.cos(math.radians(pitch)),
                          math.sin(math.radians(pitch))))
    cam.location = centro + d * 6
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    cd.clip_start = 0.1; cd.clip_end = 20
    return cam


def luces(cam, sol=2.5, ambiente=0.75, color_sol=(1.0, 0.886, 0.69), color_amb=(1.0, 1.0, 1.0)):
    sc = bpy.context.scene
    w = bpy.data.worlds.new("mundo"); sc.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value = (*color_amb, 1)
    bg.inputs['Strength'].default_value = ambiente
    ld = bpy.data.lights.new("sol", 'SUN'); ld.energy = sol; ld.color = color_sol
    ld.angle = math.radians(2)
    s = bpy.data.objects.new("sol", ld); sc.collection.objects.link(s)
    bpy.context.view_layer.update()                       # sin esto, matrix_world de la cámara aún no vale
    m = cam.matrix_world.to_3x3()
    derecha, arriba, adelante = m.col[0], m.col[1], -m.col[2]
    viaje = (derecha * 0.526 - arriba * 0.574 + adelante * 0.627).normalized()   # como foto_3d.gd (-35°, -40°)
    s.rotation_euler = viaje.to_track_quat('-Z', 'Y').to_euler()
    return s


def bbox_mundo(mallas):
    deps = bpy.context.evaluated_depsgraph_get()
    pts = []
    for mesh in mallas:
        me = mesh.evaluated_get(deps)
        pts += [me.matrix_world @ mathutils.Vector(c) for c in me.bound_box]
    return pts


def poner_clip(arm, nombre_parcial, frame):
    act = [a for a in bpy.data.actions if nombre_parcial in a.name][0]
    if arm.animation_data is None:
        arm.animation_data_create()
    arm.animation_data.action = act
    try:
        arm.animation_data.action_slot = act.slots[0]       # Blender 4.4+: la acción va por «ranuras»
    except Exception:
        pass
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()


def congelar(arm):
    # deja la pose del fotograma actual como pose fija (sin la acción), para poder retocar huesos
    bases = {pb.name: pb.matrix_basis.copy() for pb in arm.pose.bones}
    arm.animation_data.action = None
    for pb in arm.pose.bones:
        pb.matrix_basis = bases[pb.name]
    bpy.context.view_layer.update()


def render(ruta):
    sc = bpy.context.scene
    sc.render.filepath = ruta
    bpy.ops.render.render(write_still=True)
