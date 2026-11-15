# Redmi, 15/11 (tarde): resultados REALES con la APK `cbc0536` (versionCode 801)

Probado por USB en el Redmi del usuario (REDMI A7 Pro, Android 16, 1600×720), con la app de Auditoría. Capturas,
grabaciones de pantalla (sin audio) y volcados de `timestats` en `D:\REBELUM_diagnostico\redmi_15_11\`.

## Antes y después (datos del teléfono)
- Respaldo nuevo verificado: `D:\REBELUM_respaldos\2026-11-15_redmi_auditoria_antes_consolidada` (693 archivos, SHA-256 igual).
- `ajustes.cfg` restaurado al del 14/11 ANTES y DESPUÉS de las pruebas (el banco había guardado «Híbrida» y «Nix desde
  el FBX»); `banco_pruebas.save` borrado; `partida_exp.save` sin cambios (SHA `567c7323…` antes y después; el juego la
  reescribió al entrar con el mismo contenido).
- Instalación: `adb install` lo bloquea MIUI («Install canceled by user»); la APK se copió a Descargas (SHA igual) y la
  instaló el usuario. Las dos grabaciones de pantalla quedan también en Descargas del teléfono (copiadas al PC).

## Resultados
| Prueba | Resultado |
|---|---|
| Arranque en frío | 14,0 s hasta la portada (979 archivos, 0 fallos); `am start` 1,97 s hasta la primera imagen |
| Continuar | Carga la partida de siempre en Pastos Verdes (Kael y Lya, objetivo del centinela); el validador nuevo la acepta |
| Érebo híbrida (Slime, éxito) | Secuencia completa: señalado, escenario, acercamiento, mano en el cuerpo, corazón en la mano, ritual del vídeo, vuelta con el Slime eliminado, Armonía a 0 y control a Kael. 51,5 FPS de media en el tramo (banco + combate + invocación), 0 perdidos de 5464 (casi todos a 16-17 ms; picos sueltos de 50-100 ms); PSS 859 MB (431 de gráficos); 31,5 °C |
| Sunken City 3D (bajo) | Entra desde el banco; el grupo sigue a Kael y comentan Lya y Garon; 29,85 FPS (objetivo 30), 0 perdidos de 2152 (2008 a 33 ms, 28 a 50 ms, 1 de 300 ms y 1 de 1 s al cargar); PSS 879 MB (438 de gráficos); 32,3 °C |
| Custodio: rotación (×8) | Aparece con 1288 PV; se ve la franja del Avance del Portón; en 3 minutos de ataques automáticos su contador llegó a «Sello en 3»: el Sello NO se llegó a ver |
| Nix desde el FBX en combate | Entra con Kael y Garon; sostiene el cetro con la mano cerrada (arreglo del 15/11); 62,4 FPS, 0 perdidos; PSS 802 MB; 33,8 °C |

## Pendiente en el Redmi
- Ver el Sello de Clausura (más tiempo de combate o el caso ×8 con defensa).
- Érebo híbrida: una invocación resistida, un jefe y saltar a mitad; sonido (las grabaciones de pantalla no llevan audio).
- Oakhaven: paso entre vecinos a la hora de más gente (mañana) y el cantero con la losa primero.
- Medidas de Sunken en medio y alto, y la primera entrada frente a las siguientes en el teléfono.

## Sesión 15/11, 14:30-14:50 (APK `cbc0536`, v801)

Estado previo guardado en `D:\REBELUM_respaldos\2026-11-15_redmi_antes_sesion_1430` (ajustes, SHA de la raíz de
`files/`, versión). No se restaura ningún estado antiguo: al terminar se vuelve a ESTE estado. Partida real verificada
por SHA-256 (`567c7323…`) en cada paso; nunca cambió.

### Cómo se mide (para leer bien las cifras)
- **Herramienta:** `dumpsys SurfaceFlinger --timestats` de Android sobre la capa del juego (SurfaceView de la app):
  `totalFrames`, `averageFPS` (fotogramas presentados ÷ duración del tramo) e histograma `present2present` (tiempo
  entre dos fotogramas presentados). `droppedFrames` cuenta solo los fotogramas que descarta el compositor; un «0
  perdidos» NO significa «sin tirones»: los tirones del juego son las barras de 50-100 ms o más del histograma.
- **Límite de FPS:** el perfil limita la exploración a 30 FPS en bajo y medio (y 60 en alto); el combate y los menús van
  a la frecuencia de la pantalla. La pantalla admite 60, 90 y 120 Hz (ajuste de frecuencia máxima en 90; en reposo, 60):
  por eso un tramo de combate o menú puede dar una media de más de 60 FPS (el sistema subió a 90 Hz).
- **Tramos separados:** «transición» = los 9 s desde que se toca entrar (incluye la carga); «sostenido» = 28 s andando
  después, con timestats puesto a cero al empezar. Las medias de la sesión anterior (13:55) mezclaban banco, carga y
  juego: valen solo como orientación.
- **Memoria:** `dumpsys meminfo` TOTAL PSS de la app, antes (en el banco), dentro y después (de vuelta en el banco).

### Sunken City (desde el banco; bajo, medio y alto)
| Ciclo | Transición (9 s) | Sostenido (28 s andando) | PSS antes · dentro · después |
|---|---|---|---|
| bajo 1 | 243 fot.; 1 de 1 s y 1 de 150 ms (carga) | 30,37 FPS; 861/915 a 33 ms, 9 a 50 ms | 785 · 827 · 801 MB |
| bajo 2 | 257 fot.; 1 de 1 s, 5 de 50 ms, 1 de 66 ms | 30,36 FPS; 868/915 a 33 ms, 7 a 50 ms | 786 · 786 · 786 |
| bajo 3 (CAL → medio a mitad) | 256 fot.; 1 de 1 s | 30,32 FPS; 25 a 50 ms, 1 de 86 ms | 775 · 798 · 805 |
| medio 1 | 248 fot.; 1 de 1 s, 3 de 50, 1 de 66 | 30,36 FPS; 874/913 a 33 ms, 6 a 50 ms | 801 · 833 · 804 |
| medio 2 (CAL → alto a mitad) | 256 fot.; 1 de 1 s | **ALTO: 16,77 FPS; 247 a 50 ms, 195 a 66, 28 a 70, 34 a 86, 2 a 102** | 815 · **1028** · 927 |
| alto 1 (CAL → bajo a mitad) | **ALTO: 18,1 FPS; 146 de 164 a 50 ms**, 1 de 1 s | (ya en bajo) 30,36 FPS | 925 · 936 · 917 |
| bajo 4 | 254 fot.; 1 de 1 s | 30,37 FPS; 867/912 a 33 ms, 8 a 50 ms | 917 · 942 · 914 |
- **Bajo y medio** sostienen 30 FPS (≈95 % de los fotogramas a 33 ms; ≈1 % a 50 ms; ninguno peor andando). Cada
  entrada tiene UN fotograma de ≈1 s: la carga de la escena (transición, no juego sostenido).
- **Alto** no es jugable en el Redmi (17-18 FPS, fotogramas de 50-100 ms). No se fuerza por defecto: bajo es la
  referencia.
- **PSS:** con bajo y medio vuelve a una base estable (775-815 MB) en cada ciclo, sin crecer. Tras usar ALTO, la base
  sube a ≈915-925 MB y se queda ahí en los ciclos siguientes en bajo (917 → 914), sin seguir creciendo: recursos de alto
  retenidos, no una fuga por repetición. Pendiente: confirmar que vuelve a ≈790 tras reiniciar la app.
- Temperatura 31,2-31,8 °C.

### Oakhaven (banco, «Oakhaven con Kael, Lya y Garon»; era de noche)
- Kael cruza de la Puerta del Sur a la plaza por la Calle Mayor con toques, sin atascarse, con vecinos y voces.
- 30,0 FPS (2067/2186 a 33 ms, 18 a 50 ms, 1 de 86, 1 de 102 y 1 de 1 s de la carga); PSS 1004 MB.
- Pendiente en el Redmi: la mañana (hay que dormir en la posada) con el mundo vivo. En el PC: 24/24 travesías.

### Cantero con la losa primero (PC, controles normales; no en el Redmi)
- `fotos_cantero_losa_primero`: 0 fallos en 2 pasadas (aviso de misión, premio una vez, Diario con «volver», arcón
  cerrado, sin pistas no vistas, guardar y cargar con la losa abierta, aprendiz y polvo una vez, cargar al final).
- Hallado al revisar sus capturas y arreglado (`ee6a02e`): el Diario marcaba como hechos el arcón y las marcas.

### Sonido
- El juego entrega su mezcla a Android (reproductor OpenSL ES de la app «started», 44,1 kHz estéreo).
- **El volumen multimedia del teléfono está a 0 y silenciado en el altavoz** (`dumpsys audio`): NO se ha podido oír
  nada. No se cambia el volumen del sistema. Sincronía, volumen, música y su vuelta tras saltar o terminar quedan
  PENDIENTES de escucha en el teléfono; en el PC se comprueban con las grabaciones del Movie Maker (que sí llevan audio).

### Incidencia de la sesión
Al reiniciar la app, un toque cayó antes de que cargara la portada y otro acertó en «Probar el prólogo (partida
nueva)»: tres ciclos se midieron en el prólogo y se descartaron. Usó su ranura de prueba (`partida_exp_prueba.save`,
creada a las 14:23); la partida real no cambió. Desde entonces se espera a «Carga terminada» y se comprueba la pantalla.
