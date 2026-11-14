extends SceneTree
# Sonda (piloto Nix FBX, 14/11): ¿por qué el cuerpo sale tan claro en Godot? Imprime el material importado del GLB y
# el color de la textura en un punto del pecho, y compara con Lya v2.

func _initialize() -> void:
	for ruta in ["res://personajes/nix/fbx/nix_fbx.glb", "res://personajes/heroes_v2/lya/lya_v2.glb"]:
		var n: Node = load(ruta).instantiate()
		root.add_child(n)
		for mi: MeshInstance3D in n.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var m = mi.mesh.surface_get_material(s)
				print("SONDA ", ruta, " ", mi.name, " sup ", s, " ", m)
				if m is BaseMaterial3D:
					for k in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture"]:
						var t: Texture2D = m.get(k)
						print("   ", k, " ", t.resource_name if t else "-", " ", t.get_size() if t else "", " ", t.get_format() if t and t.get_image() else "")
					print("   albedo_color ", m.albedo_color, " metallic ", m.metallic, " rough ", m.roughness, " normal_scale ", m.normal_scale,
						" vertex_color_use_as_albedo ", m.vertex_color_use_as_albedo, " shading ", m.shading_mode, " cull ", m.cull_mode)
					var img: Image = m.albedo_texture.get_image() if m.albedo_texture else null
					if img:
						if img.is_compressed():
							img.decompress()
						var suma := Color(0, 0, 0)
						var c := 0
						for y in range(0, img.get_height(), 16):
							for x in range(0, img.get_width(), 16):
								var p := img.get_pixel(x, y)
								if p.v > 0.02:
									suma += p
									c += 1
						print("   media textura color ", suma / maxf(c, 1))
				var arr: Array = mi.mesh.surface_get_arrays(s)
				print("   formato ", mi.mesh.surface_get_format(s), " color por vértice ", arr[Mesh.ARRAY_COLOR] != null and arr[Mesh.ARRAY_COLOR].size() > 0)
		n.queue_free()
	quit(0)
