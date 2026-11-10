# PENDIENTES DE REDMI — Fase 3, «El bosque que no recuerda»

El Redmi no estaba: el usuario se lo llevó. **Nada de esta lista se ha comprobado en el teléfono.** Todo lo que sigue
queda pendiente de hacer con la APK de auditoría (app aparte, `com.aethelgard.auditoria`), sin tocar las demás apps.

## Recorrido completo, con toques

1. Partida con la misión del corte alfa terminada (hito `pv_14`). Si la partida de la app de pruebas no llega, usar
   «Probar la misión desde el principio» y jugarla.
2. Hablar con Tilo: empieza la aventura y el objetivo cambia.
3. Examinar el árbol marcado (junto al puesto de Tilo): aparece el botón ALQUIMIA (arriba del de acción).
4. Las tres pistas:
   - los lirios, junto al barranco, cerca de la entrada;
   - los surcos, al este, pasado el puente;
   - la inscripción, en las ruinas a las que lleva la senda.
5. Las ramas, al noroeste del puente:
   - sin la pista de los surcos, no se apartan;
   - con ella y con Garon, se abre la senda.
6. Recoger los nueve materiales; beber del manantial dos veces; abrir el cofre de la senda.
7. **Alquimia en pantalla pequeña:**
   - que los textos quepan y se lean;
   - que los botones (FABRICAR, ESTUDIAR, INVESTIGAR y CERRAR) se pulsen bien con el dedo;
   - que la lista se desplace.
8. Investigar «La savia que recuerda», ganar dos combates y fabricar el Elixir.
9. El claro del noreste: el Guardián dormido, su diálogo y el combate.

## Combate contra el Guardián

- **Las dos fases:**
  - el cambio verde se ve y se lee («¡CORAZA DE RAÍCES!», «Débil al fuego»);
  - los avisos «⚠ ¡Raíces!» y «⚠ ¡Juicio del bosque!» se leen a tiempo.
- **Desenlace A:** usar el Elixir en la fase 1 (resbala y no se gasta) y en la fase 2 (lo purifica).
- **Desenlace B:** derrotarlo sin Elixir.
- **Derrota:** perder adrede, volver y reintentar.
- **FPS en combate:** medir con `fps.sh`. Referencia: 59,9 con la v387.

## Desenlaces y persistencia

- Tras cada desenlace:
  - el diálogo final;
  - el claro (en flor o el tocón);
  - el árbol;
  - lo que dice Tilo.
- **Cerrar la app a mitad** de la aventura y reabrirla: lo hecho sigue.
- **Oakhaven:**
  - Doña Encina dice su frase la primera vez;
  - la tienda vende Hierba lunar (y Savia clara si se purificó).

## Rendimiento (perfil bajo, Automática)

- Pastos Verdes 3D con la aventura activa: debe seguir a 30 FPS estables (referencia 30,0-30,1, p95 33,7-33,9 ms).
  Los objetos nuevos son formas sencillas: unas 150 mallas pequeñas en toda la región.
- Arranque y entrada en Pastos Verdes 3D (referencia v420: 20,9 s de arranque).
- Registros de errores y cierres (logcat, búfer de cierres).

## Para compilar e instalar (cuando vuelva el Redmi)

- `compilar_apk_experimental.ps1 -Preset "Android auditoría"` desde `D:\Aethelgard_fase3`.
- Copiar la APK a Descargas con su nombre de fecha y versión e instalarla desde Archivos. MIUI cancela las
  instalaciones por USB si nadie pulsa «Instalar».
