# Guía de Export Mobile

## Android (Plataforma Primaria)

**Este proyecto está optimizado para Android como plataforma principal.** iOS es un target futuro pero no requerido en esta fase.

### Primera vez en Windows — guía clic por clic

Hacen falta **3 cosas distintas**. Ninguna viene dentro de `Godot_v4.7.2-stable_win64.exe`:


| Qué                        | Para qué                    | ¿Es Android Studio?                               |
| -------------------------- | --------------------------- | ------------------------------------------------- |
| **Android SDK + Java**     | Compilar y firmar el APK    | Lo más fácil es instalar Android Studio           |
| **Export templates 4.7.2** | El “molde” Android de Godot | **No**. Se bajan en Godot o desde godotengine.org |
| **Este proyecto**          | El juego                    | Ya lo tenés en `C:\dev\Pelotitas`                 |


Usá **Godot 4.7.2** (Help → About). Los templates tienen que ser **exactamente 4.7.2.stable**, no 4.7 ni 4.6.  
Este juego es **GDScript**: templates **normales**, no los que dicen **.NET** / **mono**.

---



#### A. Instalar Android Studio y el SDK

1. Abrí [https://developer.android.com/studio](https://developer.android.com/studio)
2. **Download Android Studio** (Windows).
3. Ejecutá el `.exe`. Next en todo. Tipo de instalación: **Standard**.
4. Aceptá licencias si aparecen. Finish / Restart si lo pide.
5. Abrí **Android Studio** (no hace falta crear un proyecto de Android).
6. En la pantalla de bienvenida: **More Actions** (o el engranaje) → **SDK Manager**.
  Si ya abriste un proyecto: menú **File → Settings** (o **Appearance & Behavior**) → **Languages & Frameworks → Android SDK**.
7. Arriba anotá **Android SDK Location**. En tu PC debería ser:
  `C:\Users\maxim\AppData\Local\Android\Sdk`
8. Pestaña **SDK Platforms** (arriba a la izquierda):
  - Marcá **Show Package Details** (abajo a la derecha).
  - Marcá **Android 15.0 (“VanillaIceCream”) / API 35** → al menos **Android SDK Platform 35**.  
  (Godot 4.7 pide Platform 35. Si no ves 35, marcá la API más nueva que aparezca, 35 o 36.)
9. Pestaña **SDK Tools**:
  - Marcá **Show Package Details**.
  - **Android SDK Build-Tools**: marcá **35.0.1** (o la 35.x más nueva).
  - **Android SDK Command-line Tools (latest)**.
  - **Android SDK Platform-Tools**.
  - **NDK (Side by side)**: marcá **28.1.13356709** si aparece (Godot 4.7 lo recomienda).
  - **CMake**: marcá **3.10.2.4988404** si aparece; si no, la 3.10.x o 3.22.x que esté.
10. **Apply** → aceptá licencias → **OK**. Esperá la descarga (varios GB).
11. Cerrá Android Studio. Ya no lo necesitás abierto para exportar.

**Java (sin instalar otro JDK):** Android Studio trae uno. En el Explorador de archivos comprobá que exista esta carpeta:

`C:\Program Files\Android\Android Studio\jbr`

Adentro tiene que haber `bin\java.exe`. Si `jbr` no está, buscá `C:\Program Files\Android\Android Studio\jre`. Esa ruta es la que vas a pegar en Godot como **Java SDK Path**.

---



#### B. Descargar e instalar los export templates (obligatorio)

Son un archivo aparte (~1 GB). Sin esto, **Project → Export** dice que faltan templates.

**Opción 1 — desde Godot (la más simple)**

1. Abrí Godot 4.7.2 y este proyecto (`C:\dev\Pelotitas\project.godot`).
2. Menú de arriba: **Editor → Manage Export Templates…**
3. Arriba de esa ventana tiene que decir que la versión es **4.7.2.stable**. Si dice otra, cerrá y abrí el `.exe` correcto de 4.7.2.
4. **Solo Android.** Si ves casillas por plataforma, marcá **Android** (y nada más) y clic en **Install Selected Templates**.  
   No hace falta Windows, Linux, iOS, Web, etc.: ocupan ~1 GB extra y este proyecto no los usa.  
   Si **no** hay casillas y solo ves **Download and Install**, ese botón baja **todos** los templates. Evitalo si te falta espacio: usá la Opción 2 o, si igual aparece una lista, instalá solo Android.
5. Esperá a que baje e instale. No cortes internet.
6. Cuando termine, Android tiene que figurar como instalado. Cerrá con Close.

**Opción 2 — a mano, si el download de Godot falla**

1. En el navegador: [https://godotengine.org/download/archive/4.7.2-stable/](https://godotengine.org/download/archive/4.7.2-stable/)
2. Bajá **Export templates** (el archivo `Godot_v4.7.2-stable_export_templates.tpz`).
  **No** bajes “Export templates - .NET”
3. En Godot: **Editor → Manage Export Templates…**
4. Arriba a la derecha: **Install from File** (o el botón de instalar desde archivo).
5. Elegí el `.tpz` que bajaste. Esperá a que lo descomprima.

Quedan instalados en:

`C:\Users\maxim\AppData\Roaming\Godot\export_templates\4.7.2.stable`

Si esa carpeta no existe o está vacía, los templates **no** están.

---



#### C. Conectar Godot con el SDK y Java

1. En Godot, menú **Editor → Editor Settings…**
2. En el buscador de la izquierda escribí `android` o andá a **Export → Android**.
3. Completá (con los `...` de cada campo, no a ojo):
  - **Java SDK Path**: `C:\Program Files\Android\Android Studio\jbr`
  - **Android SDK Path**: `C:\Users\maxim\AppData\Local\Android\Sdk`
4. **Android SDK Path** tiene que contener la carpeta `platform-tools` (adentro está `adb.exe`). Si no, la ruta está mal.
5. **Debug Keystore**: si Godot ya pone
  `C:/Users/maxim/AppData/Roaming/Godot/keystores/debug.keystore`  
   dejalo. User/password de debug suelen ser `androiddebugkey` / `android`.
6. **Close** / Apply.

---



#### D. Crear la carpeta de salida y exportar el APK

1. En el Explorador: creá `C:\dev\Pelotitas\build` si no existe.
2. En Godot: menú **Project → Export…**
3. En la lista de la izquierda:
  - Si ves **Android**, hacé clic ahí.
  - Si la lista está vacía: **Add… → Android**.
4. Si Godot muestra un error rojo, **Export Project…** queda deshabilitado hasta que lo corrijas. Los de SDK/Java/templates se resuelven en B o C.
5. Con **Android** seleccionado, pestaña **Options**:
  - **Gradle Build → Use Gradle Build**: **Off**. No lo actives (pide más SDK y más espacio).
  - **Gradle Build → Min SDK** y **Target SDK**: dejálos **vacíos** (placeholder tipo `24 (default)`). Si escribiste un número, Godot bloquea el export con *“Min SDK can only be overridden when Use Gradle Build is enabled”*.
  - **Package → Unique Name**: `com.maximoaps.pelotitas`
  - **Package → Name**: `Pelotitas`
  - **Permissions**: dejá activos **Internet**, **Access Network State**, **Access Wifi State**.
6. Abajo a la derecha: **Export Project…**
7. En el diálogo de guardar:
  - Carpeta: `C:\dev\Pelotitas\build`
  - Nombre: `pelotitas.apk`
  - Dejá **marcado** **Export With Debug** (es un APK de prueba, no de Play Store).
8. **Save**. Esperá. Si termina bien, existe `C:\dev\Pelotitas\build\pelotitas.apk`.

---



#### E. Instalar el APK en el celular

1. Copiá `pelotitas.apk` al teléfono (USB, Google Drive, Telegram, etc.).
2. En el teléfono abrí el archivo.
3. Si Android bloquea: **Ajustes → Seguridad** (o **Apps**) → permitir **Instalar apps desconocidas** para Files / Drive / Chrome.
4. **Instalar** → **Abrir**.
5. El juego pide landscape; rotá el teléfono.

**Play Store / AAB / keystore de release:** no hace falta para probar LAN.

---



#### Si algo falla


| Mensaje | Qué hacer |
|---|---|
| Min SDK / Target SDK can only be overridden when Use Gradle Build is enabled | En Options, subí a **Gradle Build**. Dejá **Min SDK** y **Target SDK** vacíos. **Use Gradle Build** = Off. |
| Missing export template | Repetí la sección B. Versión = 4.7.2.stable, no .NET. |
| Unable to find Android SDK | Sección C: la ruta debe ser la carpeta que tiene `platform-tools`. |
| Java SDK / JDK | Sección C: `jbr` de Android Studio, no la carpeta `bin`. |
| Could not install to device | Desinstalá del celular cualquier Pelotitas vieja firmada distinto. |
| Download templates falla | Usá la Opción 2 (archivo `.tpz`). |




### Permisos Necesarios

- `INTERNET`: Multiplayer LAN (ENet/UDP)
- `ACCESS_NETWORK_STATE`: Verificar conectividad
- `ACCESS_WIFI_STATE`: Listar IP local al hostear
- `VIBRATE`: Feedback háptico (opcional)

El preset `Android` en `export_presets.cfg` ya marca estos permisos. Exportá a `build/pelotitas.apk`.

### LAN en dos celulares (mismo WiFi)

1. Exportar e instalar el APK en ambos (o host en PC + join en el celular).
2. **Host**: Crear Servidor. Anotar la IP `192.168.x.x` (si hay varias, probar la de WiFi).
3. **Cliente**: Unirse a Partida, escribir esa IP y puerto `7777`.
4. Cuando el host vea 1/1, tocar **Iniciar Duelo**. Los dos entran juntos.
5. WiFi de invitado / “aislamiento de AP” suele bloquear LAN: usar la red normal.

Si el host no muestra IP: WiFi apagado, o el celular está en datos móviles.

### Optimizaciones

- **Compression**: ETC2 textures para Android
- **Audio**: OGG Vorbis comprimido
- **APK size**: Usar filters para excluir assets no usados
- **Performance**: Testing en gama media (ej: Samsung Galaxy A, Xiaomi Redmi)

---



## iOS (Target Futuro - No Requerido Ahora)

⚠️ **iOS es una plataforma futura, NO requerida en esta fase del proyecto.**

El proyecto está estructurado para soportar iOS eventualmente, pero **Android es la prioridad**.

### Requisitos Previos (cuando se implemente)

⚠️ **Requiere macOS** con Xcode instalado

1. **Xcode 14+** con command line tools
2. **Export templates de Godot 4.3** para iOS
3. **Apple Developer Account** ($99/año) para deployment
4. **Provisioning Profile** configurado



### Configuración Básica (Cuando se Implemente)

El proyecto puede ser adaptado para iOS en el futuro. Requerirá:

1. Bundle ID único: `com.maximoaps.pelotitas`
2. Provisioning profile con capabilities:
  - Network (multiplayer)
  - Push Notifications (futuro: matchmaking)
3. Privacy descriptions en Info.plist:
  - Network usage explanation



### Testing

- **iOS Simulator**: Testing básico sin deploy
- **TestFlight**: Beta testing con devices reales
- **Ad-hoc**: Deploy directo a devices registrados



### Diferencias vs Android (Referencia Futura)

Cuando se implemente iOS:

- **Touch**: API similar, pero gestos del sistema (home swipe) requieren ajustes
- **Performance**: Generalmente mejor en iOS por optimización hardware
- **Screen sizes**: Android tiene más variedad, iOS tiene notch/dynamic island
- **Monetization**: In-App Purchases requiere StoreKit (vs Google Play Billing en Android)
- **Testing**: TestFlight (iOS) vs Internal Testing (Android)

---



## Testing Checklist (Android-Focused)



### Pre-Export Testing (Desktop con Touch Emulation)

- [ ] Touch emulation funciona con mouse
- [ ] Joystick virtual responde correctamente
- [ ] Botones de habilidades son suficientemente grandes
- [ ] UI se escala correctamente en diferentes resoluciones
- [ ] Transiciones de escena funcionan



### Post-Export Testing (Android Device Real)

**Dispositivos recomendados para testing**:

- Samsung Galaxy A52/A53 (gama media-alta)
- Xiaomi Redmi Note 11/12 (gama media)
- Motorola Moto G (gama media-baja)

- [ ] Touch input responde sin lag (< 16ms)
- [ ] Movimiento con joystick es preciso
- [ ] Botones tienen feedback visual al presionar
- [ ] UI es legible en pantalla pequeña (5")
- [ ] Performance: 60 FPS estable en combate
- [ ] Multiplayer: latencia aceptable en 4G/WiFi
- [ ] Batería: consumo razonable (<5%/min en duelo)
- [ ] Vibración háptica funciona (si implementada)
- [ ] No hay crashes al pausar/resumir app
- [ ] Rotation lock funciona (landscape only)

---



## Troubleshooting



### Android

**Error: SDK not found**

- Verificar rutas en Editor Settings → Export → Android
- Reinstalar Android SDK via Android Studio

**APK no instala**

- Verificar firma (keystore configurado)
- Limpiar build folder: `rm -rf .godot/`
- Incrementar version code

**Touch no responde**

- Verificar `pointing/emulate_mouse_from_touch=false` en project.godot
- Asegurar que Control nodes tengan `mouse_filter` correcto



### iOS (Futuro)

*(No aplicable en esta fase - Android es la prioridad)*

Cuando se implemente iOS, ver documentación oficial de Godot para iOS troubleshooting.

---



## Performance Tips



### Optimización Mobile

1. **Reducir draw calls**:
  - Batch sprites similares
  - Usar TextureAtlas para UI
2. **Limitar partículas**:
  - Max 50-100 partículas simultáneas
  - Desactivar en devices low-end
3. **Network**:
  - Comprimir mensajes de red
  - Delta compression para posiciones
  - Predición client-side
4. **Audio**:
  - Limitar voces simultáneas (max 8-10)
  - Comprimir OGG a 96kbps para SFX
5. **GC**:
  - Pre-allocar pools de proyectiles
  - Evitar `new` en hot paths



### Profiling

- Godot Profiler: F11 durante ejecución
- Android: `adb logcat | grep Godot`
- iOS: Xcode Instruments (Time Profiler)

---



## Recursos

- [Godot Docs: Exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Godot Docs: Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- [Mobile Performance Guide](https://docs.godotengine.org/en/stable/tutorials/performance/index.html)

