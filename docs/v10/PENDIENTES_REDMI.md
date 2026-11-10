# Pendiente de validar en el Redmi (V10)

El Redmi (REDMI A7 Pro, Mali-G57) **no estuvo disponible** durante la V10. No se usó ADB ni se pidió nada de MIUI.
Todo lo de abajo está **pendiente de validación manual**. Nada se ha medido en el teléfono.

## La APK que hay que probar

- **No vale la v499** (de la V9, commit `56dfb9c`): no lleva nada de la V10.
- La APK de la V10 es **`D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-c2eb155.apk`**:
  - versionCode 520, 281,5 MB;
  - SHA-256 `9bfe81297b5837f222047f77f9467ed4875d6cc13f42661b125b1e8cc6a2d0ff`;
  - preset «Android auditoría», paquete `com.aethelgard.auditoria`, «REBELUM Auditoría».
- Se instala junto a las demás y no toca la app estable ni sus datos. Se instala a mano desde Descargas.

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
