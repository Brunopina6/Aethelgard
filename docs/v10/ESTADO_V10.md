# ESTADO V10 — «Oakhaven, el corazón vivo del reino» (10/11/2026, 21:45)

## Dónde está

- **Rama LOCAL** `claude/rebelum-v10`, copia `D:\Aethelgard_v10`. Último commit de código y pruebas: `c2eb155` (el de
  la APK). Después solo hay documentos.
- **Nace de** `claude/rebelum-v9` @ `3795769`, el último estado local verificado: V9 completa, batería 100/0/43/0. No
  se partió de la v293 ni de una rama remota antigua.
- **Sin fusionar ni subir.** `main`, `desarollo` e `integracion-experimental` no se han tocado. La directiva pide
  autorización expresa del usuario para fusionar o subir.
- **Ramas de los especialistas,** fusionadas en la V10 y conservadas:
  - `claude/v10-narrativa` @ `64bc7c9` (`D:\Aethelgard_v10_narrativa`);
  - `claude/v10-distrito` @ `86deb3c` (`D:\Aethelgard_v10_distrito`).

## Comprobación de la V9 y de la APK v499

- **Comprobado:** la v499 se compiló desde `56dfb9c`. Después de ese commit la V9 solo cambió documentos, así que la
  v499 lleva todo el código de la V9.
- **No vale para probar la V10.**

## APK de la V10 (local, sin instalar)

- `D:\REBELUM_compilaciones\Aethelgard_androidauditora-20261110-c2eb155.apk`
- **versionCode 520**, 281,5 MB.
- SHA-256 `9bfe81297b5837f222047f77f9467ed4875d6cc13f42661b125b1e8cc6a2d0ff`.
- Paquete `com.aethelgard.auditoria` («REBELUM Auditoría»): datos y partidas aparte de la app estable
  (`com.aethelgard.juego`).
- Firma verificada.
- **Lleva recursos con licencia pendiente** (Meshy y los dibujos 2D, como todas las de auditoría). Por eso es **solo
  para pruebas locales**: no se sube a GitHub ni se distribuye.

## Qué hay, y en qué estado

| Hito de la directiva | Estado | Dónde |
|---|---|---|
| 1. Recuperar y verificar la V9 y la v499 | hecho | arriba |
| 2. Rama y copia nuevas desde lo último validado | hecho | `claude/rebelum-v10` |
| 3. Consolidar la V9 con la batería completa | hecho: 100/0/43/0 al empezar | `PRUEBAS_V10.md` |
| 4. Primer distrito funcional de Oakhaven | 2D: implementado y probado. 3D: distrito de los oficios implementado y probado (alto y bajo) | `OAKHAVEN_CIUDAD_VIVA.md` |
| 5. Forja de Kael con mejora real | implementado y probado | `FORJA_KAEL.md` |
| 6. Taller de Garon con mejora y runa | implementado y probado | `TALLER_GARON.md` |
| 7. Botica de Lya (reutiliza la alquimia) | implementado y probado | `BOTICA_LYA.md` |
| 8. Rutinas de 4–6 vecinos | 2D: implementado y probado (tres vecinos nuevos, más los ocho de antes). 3D: **parcial** (Ferro trabaja; Hilda y Mirta quietas) | `OAKHAVEN_CIUDAD_VIVA.md` |
| 9. Encargos A y B | implementado y probado | `ENCARGOS_OAKHAVEN.md` |
| 10. Economía conectada | implementado y probado: compras en la botica; venta del hierro y del Bálsamo; pagos de los encargos | `FORJA_KAEL.md`, `BOTICA_LYA.md` |
| 11. Consecuencias en el mundo | implementado y probado: tiendas, frases y diálogos según las decisiones y el bosque | `OAKHAVEN_CIUDAD_VIVA.md` |
| 12. Pulido visual | distrito 3D nuevo con antes y después; cámara de la calle a 60° (52° probado y descartado) | `OAKHAVEN_CIUDAD_VIVA.md` |
| 13. Pruebas y regresión | hecho: **103/0/43/0**; huella del combate intacta | `PRUEBAS_V10.md` |
| 14. Validación en Android | **pendiente**: Redmi no disponible | `PENDIENTES_REDMI.md` |

## Pendiente de aprobación del usuario (no es canon)

- Los personajes Maese Ferro, Hilda la Armera y Mirta la Boticaria, y sus diálogos.
- Los dos encargos.
- Los textos del pozo viejo del distrito 3D.
- La identidad del Hierro de la Falla.

Nada de esto revela lo que Érebo guarda ni toca Final Fantasy X.

## Problemas conocidos

- **Distrito 3D:**
  - el martillo, la fragua y el pozo no suenan;
  - los pasos de la calle nueva suenan a «hierba»;
  - no se ha comprobado que Lya y Garon respeten los jardines.
- **Sin prueba de combate propia:** el Bálsamo de Mirta en combate y la coraza de la runa. Está observado en el código.
- **Encargo A:** si Kael se queda el Hierro de la Falla, solo hay uno, y hay que elegir entre la Frostfang y la cota
  reforzada. Es intencionado, una decisión con peso.
- **Nada medido en el Redmi.**
