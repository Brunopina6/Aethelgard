# Pendiente de validar en el Redmi (V10)

Durante la V10 el Redmi (REDMI A7 Pro, Mali-G57) no estuvo disponible. **El 11/11, de 00:00 a 01:10, se probó por USB**
con permiso del usuario («gestiónalo tú, conéctate a mi móvil y hazlo tú»). Los resultados están abajo.

## Resultado en el teléfono (11/11)

- **Cómo se probó:**
  - solo en la app de pruebas «REBELUM Auditoría»; la app estable no se tocó;
  - la partida de esa app se respaldó en `D:\REBELUM_respaldos\2026-11-10_redmi_auditoria_antes_v520` y se restauró al
    acabar (mismo SHA-256);
  - para llegar a cada sitio se usaron copias editadas de la partida;
  - capturas en `D:\REBELUM_diagnostico\redmi_v520`.
- **v520 (`c2eb155`):**
  1. Arranque y carga de la partida: **bien**.
  2. Ferro (forja), Hilda (taller) y Mirta: **bien**. Los botones y el desplazamiento de las listas funcionan con el
     dedo, y «CERRAR» cierra. **Mal:** el botón Atrás de Android no cerraba la ventana.
  3. Encargo B entero: **bien**, con 168 → 208 monedas y 2 Bálsamos. **Mal:** «Recoger la página» no hacía nada con el
     dedo; con Intro, sí.
  4. Encargo A: **no probado** (pide PV-05).
  5. Mejoras: **no probadas** (faltan el hierro y las investigaciones).
  6. Bálsamo en combate: **no probado** (no salió ningún encuentro). En el PC lo cubre `prueba_oakhaven_v10`.
  7. Oakhaven 3D:
     - el distrito se ve (fragua con fuego, Ferro en el yunque, el taller de Hilda, los puestos y el pozo con
       luciérnagas) e Hilda abre su taller;
     - FPS en el distrito, según el contador del juego: **30 en bajo, 30 en medio** (los dos con tope de 30) y **9-14 en
       alto**;
     - el tejado de la casa de al lado tapa a Kael en el paso al pozo.
  8. Rendimiento 2D: 30 FPS (el tope) y sin tirones al abrir los menús; un momento a 29.
- **Otras cosas vistas:**
  - Mirta y Selene usan el mismo muñeco y casi no se distinguen;
  - la posadera está junto a la primera página y el botón la nombra a ella hasta que Kael se aparta;
  - una partida de la 2D junto a la botica, abierta en 3D, pareció dejar a Kael encerrado. En el PC, en los tres
    perfiles, la casilla está libre y Kael anda (`prueba_toque_oakhaven`). Hay que volver a mirarlo en el móvil.
- **v524 (`f2b3ff4`), con los arreglos de `822927a`:**
  - el usuario autorizó instalarla: se instaló por USB encima de la v520, con `adb install -r` (versionCode 524);
  - copia en Descargas: `Aethelgard_Auditoria_2026-11-11_v524.apk`, SHA-256 `de87d6e3…eb86`, 295 169 279 bytes;
  - comprobado en el teléfono:
    - **«Recoger la página» funciona con el dedo;**
    - **Atrás cierra el taller de Hilda** y el juego sigue abierto.

## La APK que hay que probar

- **No vale la v499** (de la V9, commit `56dfb9c`): no lleva nada de la V10.
- La APK de la V10 es **`D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-c2eb155.apk`**:
  - versionCode 520, 281,5 MB;
  - SHA-256 `9bfe81297b5837f222047f77f9467ed4875d6cc13f42661b125b1e8cc6a2d0ff`;
  - preset «Android auditoría», paquete `com.aethelgard.auditoria`, «REBELUM Auditoría».
- Se instala junto a las demás y no toca la app estable ni sus datos. Se instala a mano desde Descargas.
- **10/11, hacia las 22:10:** copiada por USB a Descargas del Redmi como `Aethelgard_Auditoria_2026-11-10_v520.apk`.
  El tamaño (295 169 279 bytes) y el SHA-256 coinciden en el teléfono. Falta que el usuario la instale.

## Qué mirar, por orden

1. **Que arranque y cargue** una partida guardada de antes (la V9 o anterior), sin perder nada.
2. **Oakhaven 2D:** hablar con Maese Ferro, Hilda y Mirta. Al acabar cada diálogo debe abrirse su servicio:
   - Ferro, la forja de Kael;
   - Hilda, el taller de armaduras de Garon;
   - Mirta, «¿Qué necesitáis?».
   Comprobar que los botones se pulsan bien con el dedo y que **Atrás** o «Nada, gracias» cierran.
3. **Encargo B** (tras PV-03): Mirta → Pip → las tres páginas (Calle Mayor, junto a las raíces y la del oeste) → Mirta
   con Lya. ¿Se ven los botones «Recoger la página»? ¿Llegan los 2 Bálsamos y las 40 monedas?
4. **Encargo A** (tras PV-05):
   - Ferro;
   - en la Garganta 3D, examinar el pilar del peregrino (aviso de Garon);
   - picar la veta (diálogo `gg_veta` si van Lya y Garon);
   - volver con Ferro y decidir.
   Probar las dos decisiones con dos partidas, o anotar cuál se probó.
5. **Mejoras:** Frostfang +4 en la forja y la cota en el taller. ¿Se ve «+» en el nombre al equiparlas?
6. **Bálsamo de Mirta en combate:** cura a todo el grupo.
7. **Oakhaven 3D** (Ajustes → en pruebas), si el distrito nuevo está integrado: ver `OAKHAVEN_CIUDAD_VIVA.md`. Medir
   los FPS al recorrer la plaza y la herrería en los tres perfiles.
8. **Rendimiento:** Oakhaven 2D con los vecinos nuevos y sus frases al pasar, y que no haya tirones al abrir los menús.

## Cómo anotarlo

Para cada punto: bien, mal (qué pasó) o no probado. Mejor con una captura. Así se distingue lo comprobado en el
teléfono de lo que solo pasó las pruebas del PC.
