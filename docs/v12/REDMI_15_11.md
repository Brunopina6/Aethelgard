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
