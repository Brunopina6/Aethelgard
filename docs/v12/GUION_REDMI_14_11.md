# Guion de pruebas en el Redmi (mañana del 14/11) — APK de Auditoría

> Escrito durante la noche del 13 al 14/11. Esta noche NO se ha instalado nada ni se han tocado datos del teléfono.

**APK que hay que usar (la más reciente), compilada el 14/11 a las 05:30, SIN INSTALAR:**
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
