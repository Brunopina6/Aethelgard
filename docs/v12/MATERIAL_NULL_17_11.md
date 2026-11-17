# Los 12 «Parameter "material" is null» de la carga (17/11)

Rama `area-material-null` (desde `70b5f82`). Godot 4.7.2, Compatibility. Todo medido en el PC con ventana
(NVIDIA RTX 3050, OpenGL 3.3 y también ANGLE/GLES 3.0). **El Redmi no estaba conectado: nada de lo de abajo está
comprobado en el teléfono.**

## 1. Lo que se vio en el Redmi (16/11, APK `2afc6ed`)

`D:\REBELUM_diagnostico\redmi_16_11\logcat_arranque1.txt` (ver `REDMI_16_11.md`, «Arranque»): justo después de
`[carga] fase de sombreadores: 1788 ms`, una sola vez, 12 errores en tres tandas de 4 (13:48:47.066, .068 y .069):
`material_casts_shadows`, `material_is_animated`, `material_get_instance_shader_parameters` y
`material_update_dependency` (`drivers/gles3/storage/material_storage.cpp`). Es UNA superficie de UNA malla por tanda
(esas cuatro funciones son el recorrido de un material en `RendererSceneCull::_update_dirty_instance`): tres mallas.

## 2. Reproducción en el PC

| Arranque (con ventana, carpeta de datos nueva cada vez, `-- movil`) | Errores |
|---|---|
| Juego normal hasta la portada (Protagonistas: originales, lo de una carpeta nueva) | 0 |
| Igual, perfil alto; igual con ANGLE (GLES 3.0) | 0 |
| Precalentado liberado a 1 fotograma (sin dibujar casi nada) | 0 |
| **`heroes_v2`** (Protagonistas v2) | 0 |
| **`heroes_v3`** (Protagonistas v3) | **12**, las mismas 4 funciones, en un solo fotograma, al liberar `vista_3d` |
| `heroes_v3` + `sin_precalentar_barrio` | **12** |
| `heroes_v3` + `sin_precalentar_muestra` (sin muestra ni barrio) | **12** |
| `heroes_v3` con el arreglo (§4) | 0 |

**La muestra y el barrio NO son la causa** (sin ellos salen los mismos 12). La sospecha de `REDMI_16_11.md` («algo del
precalentado de la muestra + barrio») queda descartada en el PC.

Las 4 listas de clips que el Redmi imprime antes del precalentado (`["andar", "andar_pesado", …, "derribo_original",
…]`) son las de los protagonistas v2/v3, no las de los originales (en el PC, con los originales, salen
`["Face_Punch_Reaction", "Running", …]`): el Redmi tenía elegidos en Ajustes los v2 o los v3. Con v2 salen 0 errores y
con v3 exactamente 12; **lo más probable es que el Redmi tuviera «Protagonistas: v3 (prueba)»**, pero no está comprobado
(ver §6).

Sobre «el 15/11 no salían»: no hay ningún registro del Redmi del 15/11 que tenga el ARRANQUE (los de
`redmi_15_11\` empiezan en las entradas a la muestra; el último arranque guardado con la carga es del 10/11, sin
precalentado de la muestra). Así que no se puede decir que el 15/11 no salieran: simplemente no se registró la carga.
Los héroes v3 están desde el 12/11 (`c07d761`), también en la APK `4eb4f9b`.

## 3. La causa

**Qué material:** el material por superficie (un `ShaderMaterial` de `heroe_v2.gdshader`) que queda en la malla
`cara_v3` de Kael, Lya y Garon v3. Las tres mallas = las tres tandas de 4.

**Quién lo pone:** el script v3 hereda del v2 (`kael_v3_3d.gd` → `kael_v2_3d.gd`). En el `_ready` del v2 se crea el
ayudante v2, que busca `cara_v2`, no la encuentra (el modelo es el v3) y en `heroe_v2_ayudante._materiales` pone su
`ShaderMaterial` a TODAS las mallas del esqueleto, también a `cara_v3`. Luego `HeroesV3.cambiar_ayudante` cambia al
ayudante v3, que pone a la cara su `material_override` (`mat_cara_v3`) y en `_materiales` se salta la cara. La cara se
queda con los dos: el override (el que se ve) y el de superficie del v2 (que no se ve nunca: el override manda).

**Quién lo suelta y por qué el servidor de render aún lo usa:** es un fallo del motor que sigue abierto
([godotengine/godot#85817](https://github.com/godotengine/godot/issues/85817); el mismo en
[garrettlabs/godot-plus#19](https://github.com/garrettlabs/godot-plus/issues/19)). Con `material_override` puesto,
`_update_dirty_instance` no recorre los materiales por superficie, así que la instancia de render NO se apunta como
dependiente de ellos. Al liberar `vista_3d` (`carga.gd _paso_shaders`, `queue_free`), el material de superficie del v2
muere con su nodo (nadie más lo retiene: `cambiar_ayudante` vacía `materiales` del ayudante viejo) y no avisa a la
instancia, que se queda con su RID. Cuando luego cae también el override, la instancia vuelve a mirar sus materiales
por superficie y `RendererSceneCull::free` (de otra instancia) vacía la cola de actualizaciones: lee el RID muerto →
4 errores por superficie. Sin efecto visible (la malla ya se está borrando).

Prueba aislada del motor (4.7.2, PC): una `BoxMesh` que sobrevive al nodo con override + material por superficie
propios, dibujada y liberada → 4 errores; solo override o solo superficie (dibujados) → 0.

No es exclusivo de la carga: cualquier sitio que libere a un héroe v3 (combate, regiones) puede sacar los mismos
errores según el orden en que se borren los nodos.

## 4. El arreglo (cambio mínimo)

`aethelgard/personajes/heroes_v3/heroe_v3_ayudante.gd`, `_preparar_cara()`: antes de poner `mat_cara_v3` como
`material_override`, quita los materiales por superficie que dejó el ayudante v2 en la cara
(`set_surface_override_material(s, null)` para cada superficie). Nada más.

- **Lo que se ve no cambia:** capturas de cada héroe v3 en su estudio de combate (resolución completa, misma pose,
  proceso parado), con el material sobrante y quitándolo en el mismo fotograma:
  Kael 0 píxeles distintos de 560 000, Lya 0 de 371 200, Garon 7 626 de 602 000, que es su ruido (dos capturas sin
  tocar nada, 4 fotogramas después, ya difieren en 7 761: la capa se mueve con el tiempo).
  En `D:\REBELUM_diagnostico\pendientes_17_11\material_null\` (`*_antes_con_sobrante.png`, `*_despues_sin_sobrante.png`).
- **El precalentado sigue entero:** con v3, carpeta nueva, la caché de sombreadores al acabar la carga tiene 39
  programas con y sin el arreglo, con los mismos nombres (0 diferencias). El material sobrante nunca se dibujaba, así que
  no compilaba nada. La muestra y el barrio siguen montándose igual (no se han tocado `carga.gd`, `muestra_calle.gd`,
  `barrio.gd` ni `npc_chibi.gd`).
- Los v2 y los originales no pasan por ese código.

## 5. Prueba

`aethelgard/pruebas/prueba_material_null.gd`, registrada en `lista_pruebas.txt` en modo **ventana** (sin ventana el
renderizador es ficticio y el error no sale; con `-Manual` sale FALLIDA si cuenta errores y MANUAL si no, porque no hay
capturas que revisar). Cuenta los errores del motor con un `Logger` propio:

- A. el contador funciona (override + superficie liberado: 4 errores provocados a propósito);
- B. Kael, Lya y Garon v3 en su estudio de combate: la cara sigue con su `material_override`, ninguna malla con override
  y material por superficie a la vez, liberados sin errores;
- C. la carga entera (la escena principal) con «Protagonistas: v3» por meta (no toca Ajustes): precalentado del barrio y
  las 3 caras v3 montados, nada con los dos materiales y 0 errores al liberar `vista_3d`.

Resultados (17/11, PC): con el arreglo 19 comprobaciones, 0 fallos (`ejecutar_pruebas.ps1 -Manual -Solo
prueba_material_null`, MANUAL «terminó sin errores»); sin el arreglo, 5 fallos y los mismos 12 errores en C.
`prueba_heroes_v3` SUPERADA con el arreglo.

## 6. Qué medir en el Redmi (cuando se conecte)

1. En Ajustes, mirar qué «Protagonistas» está elegido (originales / v2 / v3). Si es v3, encaja con todo lo de arriba.
2. Con una APK que lleve el arreglo: arrancar con v3, capturar el logcat DESDE el arranque y comprobar 0 «material is
   null» tras `[carga] fase de sombreadores`. Para comparar, un arranque con v2 (debe salir 0 también sin el arreglo).
3. De paso, entrar y salir de un combate con v3 y mirar el logcat (el mismo fallo del motor podía salir al liberar a los
   héroes).
