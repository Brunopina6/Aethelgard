# Guion del Redmi, 18/11 (APK de Auditoría `65e6f58`)

Lo que hay que comprobar en el teléfono de lo hecho en el PC el 17-18/11. **Nada de esto está validado en Android**:
en el PC se midió con escala fija 0,75 (bajo), 0,80 (medio) y resolución completa (alto); en el Redmi hay que medir con el
regulador normal y decirlo así.

## APK

- `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261118-65e6f58-local.apk`, 478,3 MB, SHA-256
  `f34771a3fa96f00cc1727bf802339febe473e5a1268338594e8b18f05639f8da`, certificado `3413edcd…7785f3` (el de siempre).
  El sufijo «-local» es solo por carpetas sin seguimiento del usuario (`personajes/nix/fbx/anterior_14_11/`), que no son
  de código. Solo para pruebas locales: NO distribuir (licencias pendientes, ver su `.NO_DISTRIBUIR.txt`).
- La anterior de hoy (`f7bdd69`, sin la línea del índice) se conserva al lado.

## Orden (con el usuario delante; MIUI bloquea `adb install`)

1. **Antes de nada:** identificar el Redmi y la Auditoría instalada (`dumpsys package com.aethelgard.auditoria`).
   Respaldo byte a byte con `adb exec-out run-as com.aethelgard.auditoria cat …` de `files/` en una carpeta NUEVA
   `D:\REBELUM_respaldos\2026-11-18_redmi_auditoria_antes_65e6f58` (nunca sobrescribir otra) y SHA de cada archivo.
2. Copiar la APK por USB a Descargas, comprobar su SHA en el teléfono y que **el usuario la instale**. No borrar las
   grabaciones ni las APK que ya hay en Descargas.
3. Tras instalar: los mismos SHA de `files/` (la partida no debe cambiar por instalar).

## Qué comprobar (logcat con `[carga]`, `[calidad]`, `[tirones]`, `[ciudad]`)

1. **Tirón del índice espacial:** al entrar por primera vez en la ciudad desde el banco, logcat
   `[ciudad] índice del plano: N casillas en X ms` (en el PC, 9 689 casillas en ~37 ms). Si en el Redmi pasa de ~100 ms
   y se nota, la opción ya estudiada es crearlo en un hilo desde `cargador.preparar()` (MEDIDAS_PC.md §7.7).
2. **Recorrido con el dedo** por los 8 sectores: rótulos (los de puerta a 10 m), pilares finos aclarados, Kael con su
   cuerpo de 0,3 m sin atascarse, el rodeo de la fuente con toques, el grupo en las esquinas (ya no corta: arreglo de
   `grupo_3d._despejado`), «Guardar y recargar». Anotar cualquier sitio donde un toque no lleve a donde se esperaba.
3. **Tacto:** toques cerca de la fuente, de los pilares y de las puertas; botones de acción que aparecen y desaparecen
   con un vecino que anda (en el PC la prueba del barrio perdía la pulsación justo al borde del radio de 1,9 m: ver si
   en el dedo se nota).
4. **Memoria:** dos ciclos banco → ciudad → banco con `dumpsys meminfo com.aethelgard.auditoria` (PSS total) en cada
   paso. En el PC no hay fuga (MEMORIA_ESCENAS_17_11.md); en el Redmi está sin medir.
5. **Rendimiento con el regulador normal** en bajo y medio, en la plaza (59 ocultables) y en un sector cualquiera: FPS
   y `[tirones]`. El aclarado lanza ahora 21 rayos en vez de 13 (+30 µs en el PC).
6. Pendientes antiguos si da tiempo: material null con v3, los 5 sectores sin andar, interiores del barrio y la Quilla.

## Al terminar

- Mismos SHA de `files/` que tras instalar, SIN restaurar nada automáticamente. Si algo cambió, decirlo.
- Resultados en `docs/v12/REDMI_18_11.md`, separando lo medido en el Redmi de lo del PC.
