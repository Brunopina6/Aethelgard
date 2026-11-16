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
  sola vez. Sin efecto visible; NO aparecen en los registros del 15/11. Sospecha (sin comprobar): algo del precalentado
  de la carga (muestra + barrio, o la ciudad que ahora va en la APK) se suelta mientras una instancia aún lo usa.
  PENDIENTE de reproducir en el PC.

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

## Sin probar hoy en el Redmi
Muestra de la calle, barrio, Sunken con la Quilla, Arboleda (guion `GUION_REDMI_15_11.md`, «PARA EL 16/11»), y la
optimización del perfil bajo de la ciudad (en marcha en el PC: no va en esta APK).
