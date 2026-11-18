# Redmi, 16/11 (13:44-14:00): APK `2afc6ed` (v975) con la maqueta de la ciudad de Oakhaven

Redmi 25128RN17Y (Mali-G57), pantalla 1600×720 (el juego dibuja 1280×720 en 16:9 con bandas). APK de Auditoría
`Aethelgard_androidauditora-20261116-2afc6ed-local.apk` (478,3 MB, SHA-256 `61e47e2e…ed70da0`, «TODO CORRECTO»), copiada
por USB a Descargas (SHA comprobado en el teléfono) e instalada por el usuario sobre la v849 (`4eb4f9b`).

- **Respaldo previo:** `D:\REBELUM_respaldos\2026-11-16_redmi_antes_apk_ciudad_b\` (9 archivos de `files/` byte a byte con
  `adb exec-out run-as … cat`, iguales a los del teléfono; SHA de los 710 archivos de `files/`). Un primer intento
  (`…_antes_apk_ciudad`) quedó INCOMPLETO: el Redmi se desconectó durante la compilación de la APK (se reinició `adb`).
- **Al terminar** (salir del banco): `partida_exp.save` y su `.bak` (`567c7323…`), `ajustes.cfg` (`002a6989…`) y
  `calidad.log` IGUALES al respaldo; `banco_pruebas.save` ya no existe (la app estaba dentro del banco desde el 15/11 y
  ahora ha salido, que es el final previsto). La calidad elegida en el banco no tocó los ajustes: el aislamiento funciona
  en el teléfono. No se restauró nada antiguo.
- **Método:** `dumpsys SurfaceFlinger --timestats` de la capa del juego (puesto a cero en cada tramo; histograma
  `present2present`), `dumpsys meminfo` (TOTAL PSS), temperatura de la batería; toques reales con `adb shell input tap`.
  Registros y capturas: `D:\REBELUM_diagnostico\redmi_16_11\` (`ciudad\` por tramo).

## Arranque
- `[carga]` muestra montada en 19 ms, barrio 7 modelos en 701 ms, **fase de sombreadores 1 788 ms** (primer arranque tras
  instalar). No se imprimió el total de la carga en el registro capturado.
- **12 errores `Parameter "material" is null`** (`material_casts_shadows`, `material_is_animated`,
  `material_get_instance_shader_parameters`, `material_update_dependency`) justo al acabar la fase de sombreadores, una
  sola vez. Sin efecto visible. (El 15/11 no se puede comparar: ningún registro de ese día tiene el arranque.)
  **Diagnosticado y arreglado en el PC el 17/11** (`docs/v12/MATERIAL_NULL_17_11.md`): salen solo con los «Protagonistas v3»
  (la cara v3 llevaba override y un material por superficie sobrante; fallo abierto de Godot #85817); el precalentado de
  muestra y barrio NO era la causa. Falta comprobarlo en el Redmi con una APK nueva.

## Ciudad de Oakhaven (maqueta), perfil BAJO, escala FIJA ×0,75 (1200×540) salvo donde se dice
| Tramo | Fotogramas | FPS | Histograma (ms=nº) | PSS |
|---|---|---|---|---|
| Entrada desde el banco (12 s) | 351 | 28,5 | 33=328, 50=3, **300=1, 550=1** (la carga) | 898 MB |
| Puerta del Sur → Plaza (Calle Mayor) | 662 | 30,4 | 33=611, 50=9, 86=1 | 874 |
| Plaza (rodear la fuente, lonja) | 171-500 | 29,3-30,4 | 33 ≈ 92-96 %, 50=1-10, 66-102 ms=1-2, **250=1** (t06) | 846-881 |
| Escalinata de la Calle del Árbol → Barrio Alto | 830 | 30,4 | 33=781, 50=8, 66=1 | 884 |
| Barrio Alto (hacia el Árbol) | 833 | 30,4 | 33=790, 50=4, 86=1 | 862 |
| **MEDIO** ×0,80 (1280×576), Barrio Alto | 667 | 30,4 | 33=635, 50=3 | 900 |
| **ALTO** ×1,0 (1600×720), Barrio Alto | 709 | **32,4** (objetivo 60) | 16=102, 33=577, 50=15 | **954** |
| Bajo otra vez | 502 | 30,4 | 33=474, 50=4 | 917 |
| Entradas 2.ª-4.ª (banco → ciudad) | 345-353 | — | 1 fotograma de 250-300 ms (la carga), 50=2-3 | 902 |

- **Bajo y medio sostienen 30 FPS** en los 3 sectores andados (Puerta del Sur, Plaza del Tapiz, Barrio Alto), ≈ 95 % de
  los fotogramas a 33 ms y ≈ 1 % a 50 ms; picos sueltos de 86-102 ms y uno de 250 ms andando (probablemente el montaje de
  un sector: en el PC cuesta 5-8 ms en el hilo principal; aquí no se ha separado la causa).
- **Alto no llega a 60** (32 FPS de media, la mayoría a 33 ms) y su PSS (954 MB) pasa del tope del plan (950).
- **Memoria estable**: 3 ciclos banco → ciudad → banco: 900-902 MB en el banco y dentro (sin crecer).
- «Guardar y recargar» en el Barrio Alto: Kael reaparece en su sitio; PSS 899 MB después.
- Calor: batería 33,1 → 34,1 °C en 15 minutos.
- NO andado en el Redmi: Oficios, Ribera, Terrazas, Pasajes, Cuervo (los toques reales sin ruta son lentos: la fuente y
  las casas cortan el camino directo). La memoria y la fluidez de esos sectores siguen SIN MEDIR en el teléfono.

## Lo que se ve en la pantalla real (maqueta)
- Luz provisional muy clara (fachadas casi blancas), ya documentado.
- **Un pilar fino delante de Kael lo tapa casi entero** en la lonja de la plaza (`ciudad\t07_norte.png`): la regla «lo de
  ≤ 0,6 m no tapa» falla cuando Kael está justo detrás (su figura mide ≈ 0,5 m de ancho en pantalla). Propuesta: aclarar
  también los pilares finos cuando el rayo los cruza, o no contarlos como finos si están a menos de ~2 m de Kael.
- **Medio Kael tapado de lado** por el canto de un parterre o pretil del Barrio Alto (`ciudad\t10_escalinata.png`) y por un
  pilar del pórtico (`t13_alto_norte.png`, `antes_recarga.png`).
- **El rótulo del sector se ve enorme** («Barrio Alto de las Raíces (maqueta)», «Plaza del Tapiz…» cortado a la izquierda)
  en el Barrio Alto y al pie de la escalinata, en bajo y en alto: el arreglo del PC (ocultarlos a menos de 10 m de la
  cámara) no basta con esta cámara y estas cotas.
- La fuente de la plaza (pilón ancho) corta el camino directo de la Calle Mayor a la escalinata: con toques hay que
  rodearla (el juego no busca camino; la herramienta del PC usaba A*). Es diseño de la maqueta: valorar mover la fuente
  o abrir el paso.

## El resto del guion de la noche (14:00-14:15), perfil BAJO, escala FIJA ×0,75
Cada caso: entrada desde el banco (12 s, con la carga) y un tramo de 24 s con 8 toques (norte, oeste, este, sur).
Registros y capturas en `D:\REBELUM_diagnostico\redmi_16_11\casos\`. 0 errores en el registro de cada caso.

| Caso | Entrada (12 s) | Tramo (24 s) | PSS banco → dentro → banco |
|---|---|---|---|
| Barrio de Oakhaven (6 tramos horneados) | 341 fot.; **1 de 1 s** (carga), 50=9 | 30,36 FPS; 33=753, 50=5, 66=2 | 889 → **953** (917 andando) → 913 |
| Muestra de la calle | 366 fot.; 1 de 300 ms, 50=1 | 30,37 FPS; 33=726, 50=14, 86=1, 102=1 | 913 → 916 (921) → 920 |
| Arboleda (Hospedería) | 352 fot.; 1 de 750 ms | 29,85 FPS; 33=780, **50=44**, 66-250 ms=9 | 916 → **957** (913) → 935 |
| Sunken City con la Quilla horneada (muelle → popa) | 323 fot.; **1 de 1 s**, 102=1 | 30,37 FPS; 33=751, 50=5 | 930 → **979** (957) → 951 |

- **Los cuatro sostienen 30 FPS** andando. La Arboleda es la que más fotogramas de 50 ms tiene (5 %) y picos de hasta
  250 ms (sin línea base de antes de la Hospedería en el Redmi: no se puede atribuir).
- La entrada del barrio y la de Sunken tienen un fotograma de ≈ 1 s (la carga de la escena, como las demás regiones).
- **La memoria del banco SUBE de un caso al siguiente**: 888 → 913 → 916 → 935 → 951 MB tras ciudad ×4, barrio,
  muestra, Arboleda y Sunken. Dentro de Sunken con la Quilla, 979 MB (por encima de 950). En la ciudad sola, 3 ciclos
  seguidos NO crecieron (900-902). Puede ser caché de recursos que se queda tras cada escena distinta (no una fuga por
  ciclo); PENDIENTE de medir en el PC con el mismo orden (`D:\REBELUM_diagnostico\pruebas` no tiene esa prueba).
- **No se llegó a la Quilla** dentro de Sunken (el tramo quedó en el muelle y la popa), ni se entró en los interiores del
  barrio ni se subió la escalera de la Arboleda: esas partes del guion siguen SIN PROBAR en el teléfono.
- Un toque cayó por error en un combate de prueba del banco (Custodio): se salió con «Huir»; partida aislada, sin efecto.

## Al terminar (14:15)
Calidad del banco vuelta a «Regulador normal», Quilla a «No», «Salir del banco». `partida_exp.save` (`567c7323…`),
`ajustes.cfg`, `calidad.log`: IGUALES al respaldo; sin `banco_pruebas.save`.

## Sin probar hoy en el Redmi
Interiores del barrio y su misión, la Quilla por dentro, la escalera y la Hospedería de la Arboleda, los sectores de la
ciudad no andados, el regulador normal (todo se midió con escala fija) y la optimización del perfil bajo de la ciudad (en
marcha en el PC: no va en esta APK).
