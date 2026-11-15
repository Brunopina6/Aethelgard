# Revisión 15/11: la MANO DERECHA (la del cetro) cierra sus dedos.
#   blender -b --factory-startup -P p12_mano.py -- <blend entrada> <blend salida> <carpeta de renders>
#
# Causa (medida con p12_mano_medir.py): el esqueleto común de los héroes v2 solo tiene, en los dedos, la cadena del
# corazón (RightHandMiddle1/2) y la del pulgar; el calor de p4_rig.py dejó RightHandMiddle1 SIN vértices y los cuatro
# dedos de la mano (s = 11-19 cm desde la muñeca) casi todos en RightHand (rígidos con la palma) y unos pocos en la
# punta (Middle2). Los clips cierran esa mano unos 48° (agarre del cetro), pero la malla no los sigue: en el juego la
# mano queda abierta con el asta atravesándola (fotos_nix_fbx.gd, 30-34_mano_derecha_*).
# Arreglo (solo pesos, solo la mano derecha del cuerpo; malla, esqueleto, clips, texturas y ropa sin tocar): los
# vértices de los cuatro dedos (no los del pulgar) reparten su peso a lo largo del dedo, como hace la mano izquierda:
#   s < 10,8 cm: igual que antes (palma);
#   10,8-13,2 cm: RightHand -> RightHandMiddle1 (alrededor del nudillo, 12 cm);
#   13,5-15,9 cm: RightHandMiddle1 -> RightHandMiddle2 (alrededor de la segunda falange, 14,7 cm);
#   más allá: RightHandMiddle2.
# Se renderiza la mano en guardia, reposo y ataque antes y después (mismo encuadre, Workbench con la textura).
import bpy, sys, os, math
from mathutils import Vector
a = sys.argv[sys.argv.index("--") + 1:]
ENTRADA, SALIDA, RENDER = a[:3]
bpy.ops.wm.open_mainfile(filepath=ENTRADA)
os.makedirs(RENDER, exist_ok=True)
arm = bpy.data.objects["nix_esqueleto"]
cuerpo = bpy.data.objects["cuerpo_nix"]
B = arm.data.bones
W0 = B["mixamorig:RightHand"].head_local.copy()
EJE = (B["mixamorig:RightHandMiddle1"].head_local - W0).normalized()


def suave(a0, a1, x):
    t = min(1.0, max(0.0, (x - a0) / (a1 - a0)))
    return t * t * (3 - 2 * t)


def poner_accion(nombre, f):
    act = bpy.data.actions[nombre]
    arm.animation_data_create()
    arm.animation_data.action = act
    if hasattr(arm.animation_data, "action_slot") and act.slots:
        arm.animation_data.action_slot = act.slots[0]
    f0, f1 = act.frame_range
    bpy.context.scene.frame_set(int(f0 + (f1 - f0) * f))


def preparar_render():
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'
    sc.display.shading.color_type = 'TEXTURE'
    sc.render.resolution_x = 640
    sc.render.resolution_y = 640
    sc.render.film_transparent = False
    sc.world = sc.world or bpy.data.worlds.new("mundo")
    cam = bpy.data.objects.get("cam_mano")
    if cam is None:
        cam = bpy.data.objects.new("cam_mano", bpy.data.cameras.new("cam_mano"))
        sc.collection.objects.link(cam)
    cam.data.lens = 50
    sc.camera = cam
    for o in sc.objects:                  # la ropa y el cuerpo, nada más (el cetro no está en este .blend)
        o.hide_render = o.type == 'MESH' and o not in (cuerpo, bpy.data.objects["ropa_nix"])
    return cam


def render(nombre_fase):
    cam = preparar_render()
    for clip, f in (("guardia", 0.0), ("reposo", 0.0), ("ataque", 0.5)):
        poner_accion(clip, f)
        mano = arm.matrix_world @ arm.pose.bones["mixamorig:RightHand"].tail
        for vista, d in (("frente", Vector((0.0, -0.45, 0.04))), ("lado", Vector((-0.45, -0.05, 0.04))),
                         ("dentro", Vector((0.35, -0.25, 0.05)))):
            cam.location = mano + d
            cam.rotation_euler = (mano - cam.location).to_track_quat('-Z', 'Y').to_euler()
            bpy.context.scene.render.filepath = os.path.join(RENDER, "%s_%s_%s.png" % (nombre_fase, clip, vista))
            bpy.ops.render.render(write_still=True)


# estado que los renders cambian y se deja como estaba antes de guardar
ad = arm.animation_data
ESTADO = {"accion": ad.action if ad else None, "ranura": getattr(ad, "action_slot", None) if ad else None,
          "fotograma": bpy.context.scene.frame_current,
          "ocultos": {o.name: o.hide_render for o in bpy.context.scene.objects},
          "camara": bpy.context.scene.camera, "mundo": bpy.context.scene.world}
render("antes")

# ---- pesos de los dedos de la mano derecha
grupos = {g.name: g for g in cuerpo.vertex_groups}
H = grupos["mixamorig:RightHand"]
M1 = grupos.get("mixamorig:RightHandMiddle1") or cuerpo.vertex_groups.new(name="mixamorig:RightHandMiddle1")
M2 = grupos["mixamorig:RightHandMiddle2"]
nombres = {g.index: g.name for g in cuerpo.vertex_groups}
inv = arm.matrix_world.inverted() @ cuerpo.matrix_world
tocados = 0
for v in cuerpo.data.vertices:
    gs = {nombres[g.group]: g.weight for g in v.groups}
    mano = sum(w for n, w in gs.items() if "RightHand" in n)
    if mano < 0.5:
        continue
    pulgar = sum(w for n, w in gs.items() if "RightHandThumb" in n)
    p = inv @ v.co
    s = (p - W0).dot(EJE)
    if pulgar >= 0.2 or p.z > 0.05 or s < 0.108:
        continue
    w1 = suave(0.108, 0.132, s)
    w2 = suave(0.135, 0.159, s)
    pesos = {H: 1.0 - w1, M1: w1 * (1.0 - w2), M2: w1 * w2}
    for n in list(gs):                       # fuera de los demás grupos de la mano (y de lo que hubiera)
        cuerpo.vertex_groups[n].remove([v.index])
    for g, w in pesos.items():
        if w > 1e-4:
            g.add([v.index], w, 'REPLACE')
    tocados += 1
print("DEDOS tocados", tocados)

# comprobaciones: <= 4 pesos, normalizados, ninguno sin peso
mal = sin = mas4 = 0
for v in cuerpo.data.vertices:
    ws = [g.weight for g in v.groups if g.weight > 1e-4]
    if not ws:
        sin += 1
    elif abs(sum(ws) - 1.0) > 1e-3:
        mal += 1
    if len(ws) > 4:
        mas4 += 1
cuenta = {}
for v in cuerpo.data.vertices:
    for g in v.groups:
        n = nombres.get(g.group, cuerpo.vertex_groups[g.group].name)
        if "RightHand" in n and g.weight > 0.05:
            cuenta[n] = cuenta.get(n, 0) + 1
print("PESOS mano derecha", {k.split(":")[-1]: c for k, c in sorted(cuenta.items())})
print("COMPROBAR sin peso", sin, "no normalizados", mal, "más de 4", mas4)

render("despues")
arm.animation_data.action = ESTADO["accion"]
if ESTADO["ranura"] is not None and hasattr(arm.animation_data, "action_slot"):
    arm.animation_data.action_slot = ESTADO["ranura"]
bpy.context.scene.frame_set(ESTADO["fotograma"])
bpy.context.scene.camera = ESTADO["camara"]
bpy.context.scene.world = ESTADO["mundo"]
c = bpy.data.objects.get("cam_mano")
if c is not None:
    datos = c.data
    bpy.data.objects.remove(c, do_unlink=True)
    bpy.data.cameras.remove(datos)
for o in bpy.context.scene.objects:
    o.hide_render = ESTADO["ocultos"].get(o.name, o.hide_render)
bpy.ops.wm.save_as_mainfile(filepath=SALIDA)
print("GUARDADO", SALIDA)
