# p10 (14/11): guarda en .npy las posiciones de cuerpo_nix de p4_rig.blend (antes del «pelo recogido» de p8).
a = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=a[0])
o = bpy.data.objects["cuerpo_nix"]
V = np.zeros((len(o.data.vertices), 3), np.float32); o.data.vertices.foreach_get("co", V.ravel())
np.save(a[1], V); print("V4", V.shape)
