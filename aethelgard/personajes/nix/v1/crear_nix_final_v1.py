# Nix (V12): segunda mitad de crear_nix.py (cara, una malla, texturas, LOD, clips, hojas y exportación).
# crear_nix.py la llama con su estado: ejecutar(ctx), ctx = {"arm", "obs", "D", "RAIZ", "EVID", "CARPETA",
# "SIN_RENDER", "SIN_GLB"}.
import os, json
import bpy
import numpy as np
import rig_comun as RC


def _forma_almendra_de(CV):
    orig = CV._forma_ojo

    def forma(estilo):
        """Ojo almendrado de Nix: grande, el rabillo algo levantado (mirada serena y precisa)."""
        if estilo != "almendra":
            return orig(estilo)
        xa, xb, xm, w = -0.86, 0.80, -0.05, 0.86
        top0, top_h, incl, bot0, bot_h = 0.03, 0.58, -0.08, -0.06, 0.50

        def e(x):
            return np.clip(1 - ((x - xm) / w) ** 2, 0, 1)

        U = lambda x: top0 + top_h * e(x) ** 0.6 + incl * x
        L = lambda x: bot0 - bot_h * e(x) ** 0.9 + 0.05 * x
        return xa, xb, U, L
    return forma


def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def ejecutar(ctx):
    arm, obs, D = ctx["arm"], ctx["obs"], ctx["D"]
    RAIZ, EVID, CARPETA = ctx["RAIZ"], ctx["EVID"], ctx["CARPETA"]
    sc = bpy.context.scene

    # ------------------------------------------------------------------ la cara (atlas propio y malla con cejas)
    import cara_v3 as CV
    CV._forma_ojo = _forma_almendra_de(CV)
    cabeza = [o for o in obs if o.name == "nix_cabeza"][0]
    img_cara, _ = CV.atlas(D.CARA, os.path.join(EVID, "nix_cara_atlas.png"))
    img_cara.name = "nix_cara_atlas"
    cara = CV.crear(D.CARA, cabeza, arm, nombre="cara_nix")
    mc = bpy.data.materials.new("nix_cara")
    mc.use_nodes = True
    nt = mc.node_tree
    bs = nt.nodes["Principled BSDF"]
    ti = nt.nodes.new("ShaderNodeTexImage")
    ti.image = img_cara
    nt.links.new(ti.outputs["Color"], bs.inputs["Base Color"])
    nt.links.new(ti.outputs["Alpha"], bs.inputs["Alpha"])
    bs.inputs["Roughness"].default_value = 0.8
    try:
        mc.surface_render_method = 'BLENDED'
    except Exception:
        mc.blend_method = 'BLEND'
    cara.data.materials.append(mc)
    cara.parent = arm
    cara.matrix_parent_inverse = arm.matrix_world.inverted()
    g = cara.vertex_groups.new(name=RC.P + "Head")
    g.add(list(range(len(cara.data.vertices))), 1.0, 'REPLACE')
    md = cara.modifiers.new("Armature", 'ARMATURE')
    md.object = arm
    print("CARA", len(cara.data.vertices), "vértices", tris(cara), "triángulos")

    # ------------------------------------------------------------------ una malla, UV y texturas
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.join()
    cuerpo = bpy.context.view_layer.objects.active
    cuerpo.name = "cuerpo_nix"
    cuerpo.data.name = "cuerpo_nix"
    import crear_nix_texturas as T
    T.uv_atlas(cuerpo)
    rutas = T.hornear(cuerpo, D, D.CRANEO["c"].copy(), EVID)
    img_c = T.reducir(rutas["color"], os.path.join(EVID, "nix_color.png"), True)
    img_o = T.reducir(rutas["orm"], os.path.join(EVID, "nix_orm.png"), False)
    img_n = T.reducir(rutas["normal"], os.path.join(EVID, "nix_normal.png"), False)
    img_c.name, img_o.name, img_n.name = "nix_color", "nix_orm", "nix_normal"
    T.material_final(cuerpo, img_c, img_o, img_n)
    tri0 = tris(cuerpo)
    print("CUERPO LOD0", len(cuerpo.data.vertices), "vértices", tri0, "triángulos")

    # ------------------------------------------------------------------ LOD (en el mismo GLB; el juego elige)
    lods = []
    for nombre, ratio in (("cuerpo_nix_lod1", 0.45), ("cuerpo_nix_lod2", 0.20)):
        c2 = cuerpo.copy()
        c2.data = cuerpo.data.copy()
        c2.name = nombre
        c2.data.name = nombre
        sc.collection.objects.link(c2)
        for m2 in list(c2.modifiers):
            c2.modifiers.remove(m2)
        dm = c2.modifiers.new("dec", 'DECIMATE')
        dm.decimate_type = 'COLLAPSE'
        dm.ratio = ratio
        dm.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = c2
        for o in bpy.context.selected_objects:
            o.select_set(False)
        c2.select_set(True)
        bpy.ops.object.modifier_apply(modifier="dec")
        ma = c2.modifiers.new("Armature", 'ARMATURE')
        ma.object = arm
        lods.append(c2)
        print("LOD", nombre, tris(c2), "triángulos")

    # ------------------------------------------------------------------ clips
    import crear_nix_clips as NC
    import biblioteca_clips as BC
    rig = RC.Rig(arm)
    print("ALTURA", "%.3f" % rig.altura)
    info = {}
    clips = NC.clips_de()
    if arm.animation_data is None:
        arm.animation_data_create()
    for c in clips:
        act = bpy.data.actions.new(c["nombre"])
        act.use_fake_user = True
        arm.animation_data.action = act
        previo = {}
        for t, d in c["claves"]:
            rig.aplicar(d)
            for pb in rig.pb:
                q = pb.rotation_quaternion.copy()
                if pb.name in previo and q.dot(previo[pb.name]) < 0:
                    pb.rotation_quaternion = -q
                previo[pb.name] = pb.rotation_quaternion.copy()
            rig.clave(t * BC.FPS)
        info[c["nombre"]] = {"duracion": round(c["dur"], 4), "bucle": c["bucle"],
                             "eventos": {k: round(v, 4) for k, v in c["eventos"].items()}}
    arm.animation_data.action = None
    rig.reset()
    for act in bpy.data.actions:
        if act.name not in info:
            f0, f1 = act.frame_range
            info[act.name] = {"duracion": round((f1 - f0) / BC.FPS, 4), "bucle": act.name in ("andar", "correr"),
                              "eventos": {}, "captura": True}
    print("CLIPS", len(info), sorted(info))

    # ------------------------------------------------------------------ hojas
    import crear_nix_hojas as HJ
    visibles = [cuerpo, cara]
    for l in lods:
        l.hide_render = True

    def poner_clip(nombre, t):
        act = bpy.data.actions[nombre]
        arm.animation_data.action = act
        try:
            arm.animation_data.action_slot = act.slots[0]
        except Exception:
            pass
        sc.frame_set(int(round(t * BC.FPS)))
        bpy.context.view_layer.update()

    HJ.vistas_modelo(arm, visibles, EVID, "nix_vistas_reposo", lambda: poner_clip("reposo", 0.0))
    HJ.vistas_modelo(arm, visibles, EVID, "nix_vistas_guardia", lambda: poner_clip("guardia", 0.0))
    HJ.vistas_fpe(arm, visibles, EVID, "nix_fpe", lambda: poner_clip("reposo", 0.0))
    ref = os.path.join(EVID, "referencia_usuario.png")
    if os.path.exists(ref):
        HJ.lamina_referencia(ref, os.path.join(EVID, "nix_fpe.png"), os.path.join(EVID, "nix_lamina_referencia.png"))
    HJ.junto_al_grupo(arm, visibles, RAIZ, EVID, "nix_junto_al_grupo", float(os.environ.get("NIX_ESC", "0.56")),
                      lambda: poner_clip("reposo", 0.0))
    HJ.lods(arm, [cuerpo] + lods, cara, EVID, "nix_lod", lambda: poner_clip("guardia", 0.0))
    if not ctx["SIN_RENDER"]:
        HJ.hojas_clips(arm, visibles, clips, EVID, poner_clip)
    arm.animation_data.action = None
    rig.reset()

    # ------------------------------------------------------------------ exportar
    json.dump({"heroe": "Nix", "fps": BC.FPS, "altura_blender": round(rig.altura, 4), "version": "prototipo",
               "triangulos": {"lod0": tri0, "lod1": tris(lods[0]), "lod2": tris(lods[1]), "cara": tris(cara)},
               "huesos_deformantes": sum(1 for b in arm.data.bones if b.use_deform),
               "clips": info},
              open(os.path.join(CARPETA, "nix_clips.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    ajenas = [a.name for a in bpy.data.actions if a.name not in info]
    assert not ajenas, "acciones que no son de Nix: %s" % ajenas
    if not ctx["SIN_GLB"]:
        for o in bpy.data.objects:
            o.select_set(o.type == 'ARMATURE' or o in [cuerpo, cara] + lods)
        ruta = os.path.join(CARPETA, "nix.glb")
        props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
        op = dict(filepath=ruta, export_format='GLB', use_selection=True, export_animations=True,
                  export_animation_mode='ACTIONS', export_force_sampling=True, export_apply=False)
        for k, v in (("export_frame_range", False), ("export_anim_slide_to_zero", True), ("export_morph", True),
                     ("export_morph_normal", False), ("export_vertex_color", 'ACTIVE'),
                     ("export_all_vertex_colors", True), ("export_active_vertex_color_when_no_material", True),
                     ("export_image_format", 'AUTO'), ("export_skins", True), ("export_tangents", True)):
            if k in props:
                op[k] = v
        bpy.ops.export_scene.gltf(**op)
        print("GLB", ruta, os.path.getsize(ruta))
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(EVID, "nix.blend"))
    print("FIN_OK")
