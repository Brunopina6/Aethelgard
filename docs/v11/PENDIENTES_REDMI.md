# V11 · Pendiente de probar en el Redmi

Esta noche el Redmi estaba desconectado (lo dijo el usuario). **Nada de la V11 se ha probado en el teléfono.** Las
pruebas del PC encuentran fallos, pero no demuestran los FPS ni el tacto en Android.

Para probarlo hace falta una APK de auditoría de la rama `claude/rebelum-v11`. Esta noche no se ha compilado ninguna:
la directiva permitía compilar en el PC, pero se dio prioridad a construir y probar. Lleva recursos con licencia
pendiente, así que no va a GitHub.

## Qué mirar, por orden

1. **Combate, panel de objetivos:**
   - ¿se lee bien la lista de la derecha?
   - ¿se toca bien cada fila con el dedo, con soltar para elegir?
   - FPS con la lista abierta.
2. **Interrupción:**
   - ¿se entiende «⚠ Prepara un golpe: dale fuerte y lo cortas»?
   - ¿es justo el 25 % de la vida para cortar el golpe?
   - ¿se ve «¡Interrumpido!»?
3. **Técnicas DÚO:** la pestaña DÚO de Kael y de Lya, y si los motivos de por qué no se puede caben en la fila.
4. **INVOCACIÓN:** la lista con Érebo, su emblema y la descripción.
5. **Élites:** el «★» dorado y el cartel. Salen en el sexto encuentro al azar con dos o más héroes.
6. **Gremio:**
   - leer el tablón con el dedo, desplazar la lista, aceptar y cobrar;
   - Atrás cierra;
   - los braseros de la plaza (luz de noche) y sus FPS.
7. **«Las parejas del Cuervo»:**
   - el tamaño de las cartas con el dedo;
   - el texto de la derecha en una pantalla pequeña.

## APK de la V11 (11/11, por la mañana)

- **v542**, del commit `c2b5feb`:
  - en el PC: `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261111-c2b5feb.apk` (281,5 MB);
  - SHA-256 `5b053fe3ad4658948272db6c3dbf194e8374a02b7630dd1bcfb9b9a10f54d389`.
- **En el Redmi:** copiada por USB a Descargas como `Aethelgard_Auditoria_2026-11-11_v542.apk`, con el mismo SHA-256.
- **Instalar por USB no se pudo:** MIUI la canceló (`INSTALL_FAILED_USER_RESTRICTED`) porque nadie pulsó en la
  pantalla. Se probó una sola vez y no se repite. **La instala el usuario desde Descargas**, encima de la v524.
- La partida de la app de pruebas está respaldada en `D:\REBELUM_respaldos\2026-11-11_redmi_auditoria_antes_v11`.
- Lleva recursos con licencia pendiente: **no va a GitHub**.
