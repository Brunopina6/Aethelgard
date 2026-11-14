# Guion de pruebas en el Redmi (mañana del 14/11) — APK de Auditoría

> Escrito durante la noche del 13 al 14/11. Esta noche NO se ha instalado nada ni se han tocado datos del teléfono.

**APK MÁS RECIENTE (14/11, 23:30): validada `720d193` (batería 175 · 0 · 92 · 0), AÚN EN EL PC**
- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-720d193-local.apk` (419,1 MB).
  SHA-256: `2c3e5eb13fafd1303b1f29c604b74474d994690a1979f8ff48f2b69b32d392f9`.
- **Respecto a la de `5e5458d`:**
  - la misión «Las tres marcas del cantero» completa: PROPUESTA, en Ajustes o en el banco de pruebas
    (`CANTERO_V12.md`);
  - talleres más claros;
  - el Custodio con el Avance del Portón, el golpe y la derrota (con su interruptor, desde el banco);
  - 8 arreglos del recorrido de Oakhaven y Pastos Verdes (`PULIDO_RECORRIDO_14_11.md`).
  - Lleva también la invocación de Érebo en vídeo (sigue apagada).
- **Qué probar, además de lo de abajo:**
  1. **El cantero** (banco → «Misión del cantero: Activa» → Oakhaven):
     - ¿se leen las tres placas a la distancia de juego?
     - ¿el aprendiz anima bien en el perfil bajo?
     - abrir y abandonar la losa con el dedo;
     - el Diario con sus cuatro pasos;
     - el polvo en la Alquimia (en la botica de Mirta).
  2. **Custodio** (banco → Custodio): la franja del Avance, la embestida y la derrota de rodillas.
  3. **Ferro:** la tienda no ofrece vender el Hierro de la Falla mientras él lo espera.
  4. **Gorthor:** su prueba del PC falló una vez en batería y pasó 4 de 4 sola. Observar si en el teléfono hay algo raro.

**APK anterior (14/11, 19:40): validada `5e5458d` (batería 175 · 0 · 91 · 0), AÚN EN EL PC**
- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-5e5458d-local.apk` (419,0 MB).
  SHA-256: `95489910bee7dfe0529ea14b29880308952f8a51966c8709737d735f88f3eb6d`.
- **Respecto a la v725:** la invocación cinematográfica de Érebo en vídeo (`docs/v12/EREBO_CINEMATICA_V12.md`), APAGADA por defecto.
- **Qué probar** (en Ajustes → «Érebo: invocación cinematográfica»; con Lya y la Armonía llena, usando el banco de pruebas):
  1. Con «Abreviada» y con «Completa»:
     - ¿se ve fluido, sin tirones, cortes ni bandas?
     - ¿el sonido va sincronizado (agarre a 9,85 s y estallido a 17,0 s en la completa)?
     - ¿cuánto tarda en empezar?
     - ¿se cierra la app por memoria?
  2. Tocar para saltar, incluso nada más empezar.
  3. El daño debe aplicarse una sola vez y el combate seguir con normalidad.
  4. Medir los FPS y el tiempo de fotograma con `dumpsys SurfaceFlinger --timestats`, y compararlos con los primeros planos de la invocación 3D (bajaban a unos 15 FPS).
  5. Volver a dejar la opción en «No».

**APK anterior (14/11, 16:15): v725, validada `eee2e36` (batería 174 · 0 · 90 · 0, sola), AÚN EN EL PC**
- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-eee2e36-local.apk`.
  SHA-256: `3c9bd521c0ed15dc6cc1964958121259add34cbcef9f116160d5f05238731c8e`.
- **Respecto a la v717 trae:**
  - en el banco nadie huye, y el botón y la etiqueta ya no tapan nada;
  - la capa con la media vuelta corregida;
  - el rendimiento de la invocación de Érebo;
  - el iris y la capa corta de Nix.
- **Al reconectar el Redmi:**
  1. Restaurar `ajustes.cfg` y borrar `banco_pruebas.save` (ver RETOMAR, «Redmi, 14/11»).
  2. Copiar la v725 a Descargas. La instala el usuario.
  3. Repetir lo que quedó sin probar:
     - Agua mejorada;
     - Nix en combate y en exploración, con el iris en movimiento;
     - Érebo de cerca (si la caída a unos 15 FPS desaparece);
     - cerradura y misión del cantero;
     - ciclos exploración → combate → exploración;
     - Kael a la hora de más gente.

**APK anterior (14/11, 13:05): v717, validada `687dbe7` (batería 174 · 0 · 88 · 0, sola)**
- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-687dbe7-local.apk`. Ya está en Descargas
  del Redmi, verificada por SHA-256 `a9db4078149bbc7a253e24488c86c2382d925f08d7cc1bab49e4bc4bcba488a7`.
  - El sufijo «-local» solo se debe a la carpeta sin versionar `personajes/nix/fbx/anterior_14_11/`, que no va dentro.
  - MIUI rechaza `adb install`: **la instala el usuario** desde Descargas, conservando los datos.
- **Respaldo previo verificado:** `D:\REBELUM_respaldos\2026-11-14_redmi_auditoria_antes_v694_a_nueva`.
- **Cómo probar sin comandos:** en la portada, «Banco de pruebas (Auditoría)».
  - Sus selectores: protagonistas, Érebo, Agua, Nix, capa y misión del cantero.
  - Sus casos: cinco combates (Érebo, Agua, Garon, Nix y Custodio) y Oakhaven con o sin Nix.
  - Partida aislada: al volver al banco, todo empieza de nuevo.
  - Desde la exploración se vuelve con el botón «Volver al banco».
- La v713 (`8200909`) quedó obsoleta, porque en la portada que sale por defecto no se llegaba al banco, y se retiró de Descargas.

**APK anterior (14/11, 05:30; sustituida), SIN INSTALAR:**
- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-6da1c74.apk` (410,7 MB).
- **SHA-256:** `794114686382954d3604ceb4e48208856555e81d540a99cb1a60427b19c1259c`.
- **Código:** el validado `c0b199a` (batería 171 · 0 · 78 · 0) más solo documentación.
- **Novedades respecto a la anterior:**
  - **Experimental:** el vestuario de Nix (con «Nix (cuarta heroína)» y «Nix: modelo FBX» en Sí) y el Custodio
    `meshy_e01`. El Custodio solo sale en los grupos 28 y 29 y en el teléfono no se puede forzar: queda para el PC.
  - **ACTIVO por defecto:**
    - el gremio con Oro a 13;
    - el Diario con objetivos y pistas;
    - la caravana en el Diario;
    - el arcón del Concejo con su cerradura rúnica, en Oakhaven, casilla (50,5; 22);
    - Garon v2 y v3 avanzan y retroceden andando.

**APK anterior, compilada el 14/11 a las 03:30, sin instalar (sustituida por la de arriba):**
- **Archivo:** `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261114-e318629.apk` (406,0 MB).
- **Código:** commit `e318629`, que es el validado `84ff2c1` más solo documentación.
- **SHA-256:** `de0475726d731fd30cf65007c3065efb6b48b8f5a0f4f03dadc3d40e7a67d50a`.
- **Comprobaciones:** batería del PC 164 · 0 · 76 · 0. Sin partidas, claves ni ajustes del editor. La carpeta real de
  datos sin cambios.
- **Contenido:** todo lo nuevo va APAGADO por defecto y se enciende en **Ajustes** (solo en Auditoría): «Érebo: orbe
  experimental», «Magia Agua v12», «Nix (cuarta heroína)», «Nix: modelo FBX (piloto, sin ropa)» y «Capa de Garon
  articulada».
- Lleva modelos de Meshy con su plan sin confirmar (`NO_DISTRIBUIR`): **solo para pruebas personales**.

## 0. Preparación (siempre)

1. **Solo REBELUM Auditoría** (`com.rebelum.auditoria`). No toques las demás apps.
2. **Respaldo de su partida antes de instalar:** `run-as … tar` a `D:\REBELUM_respaldos\<fecha>_redmi_auditoria_antes_<commit>`.
   El procedimiento está en `INFORME_REDMI_V12.md`, como en la novena prueba.
3. **Instalación:** MIUI bloquea `adb install`. Se copia la APK a Descargas, se comprueba su SHA-256 en el teléfono y
   la instala el usuario.
4. **Registro:** modelo, Android, renderer (Compatibility), resolución, build y commit.
5. **Medición:** calentar 5 minutos y medir 15 (`dumpsys SurfaceFlinger --timestats`). Una sola app en primer plano.
6. **Al terminar:** restaurar la partida idéntica y comprobarlo por SHA-256.

## 1. Comprobaciones pedidas expresamente

| # | Qué | Cómo | Resultado esperado |
|---|---|---|---|
| 1 | Protagonistas **v2** de pie en reposo | Ajustes → Protagonistas v2; exploración; quieto 30 s | No se tumban (ya visto en la v694; repetir) |
| 2 | Protagonistas **v3** de pie en reposo | Lo mismo con v3 | No se tumban |
| 3 | **NPC de Oakhaven** sin bloquear a Kael | Puerta del Sur y caminos a la hora de más gente; mantener pulsado el destino | Se apartan; Kael pasa en ≤ 1 s de empuje (`1204dd4`) |

## 2. Novedades de esta noche

| # | Qué | Cómo | Esperado / qué medir |
|---|---|---|---|
| 4 | **Orbe experimental de Érebo** (fase 3A) | Ajustes → «Érebo: orbe experimental» Sí. Combate con Lya y Armonía llena → invocar. Repetir con No | Espiral violeta, negra y plateada en el agarre, onda al llegar, sin restos. Medir la **primera invocación en frío** (compilación de sombreadores) y el ms de fotograma con Sí y con No |
| 5 | **Solo Lya invoca** (fase 3B) | Combate con Kael y Lya, Armonía llena | Kael no tiene INVOCACIÓN; Lya sí |
| 6 | Magia **Agua v12** (fase 3C, si se integra) | Ajustes → «Magia Agua v12» Sí/No; Lya lanza Agua y Maremoto | Más legible, sin tapar barras ni números; ms de fotograma |
| 7 | **Capa de Garon** (fase 6, si se integra) | Exploración y combate con Garon (original, v2 y v3): andar, girar, parar, atacar y defender | Bien sujeta a los hombros, sin atravesar; se mueve |
| 8 | **Nix** (fase 5, si se integra) | Solo si el piloto llega a la APK, tras su interruptor | Escala y aspecto. Es un piloto, no la versión final |
| 9 | **Gran Bosque** | Mipmaps y matas siguen APAGADOS por defecto; repetir las cuatro combinaciones si da tiempo | La referencia v694: 24,3 / 26,2 fps |

| 10 | **Cerradura rúnica** (arcón del Concejo) | Oakhaven, casilla (50,5; 22): girar los anillos con el dedo, leer la inscripción, salir a medias con Atrás y volver | Se abre una sola vez, el premio no se repite al cargar y salir nunca bloquea |
| 11 | **Diario y gremio** | Diario con misiones de Oakhaven y la caravana; gremio hasta Oro | Muestra objetivos y pistas vistas, nada futuro; Oro se alcanza con 13 |
| 12 | **Garon v2/v3 en combate** | Protagonistas v2 o v3; atacar con Garon | Se acerca y se aleja andando (al alejarse, hacia atrás) sin deformarse |

## 3. Separar resultados

- Pruebas automáticas del PC; recorrido jugable en el teléfono; revisión visual; escucha; medición en el dispositivo.
- Lo que no se pruebe en el teléfono queda «pendiente en Android», aunque haya pasado en el PC.
