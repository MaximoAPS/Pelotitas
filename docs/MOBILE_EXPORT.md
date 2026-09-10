# Guía de Export Mobile

## Android (Plataforma Primaria)

**Este proyecto está optimizado para Android como plataforma principal.** iOS es un target futuro pero no requerido en esta fase.

### Requisitos Previos

1. **Android SDK** instalado y configurado en Godot
   - Editor → Editor Settings → Export → Android
   - Configurar rutas de SDK, JDK
   - Instalar build tools 34+

2. **Export templates de Godot 4.3**
   - Editor → Manage Export Templates
   - Download e instalar templates oficiales

3. **Keystore para firma** (release builds)
   ```bash
   keytool -genkey -v -keystore pelotitas.keystore -alias pelotitas -keyalg RSA -keysize 2048 -validity 10000
   ```

### Testing Rápido (Debug)

1. Conectar dispositivo Android via USB
2. Habilitar "USB Debugging" en el dispositivo
3. Project → Export → Android (APK)
4. Configurar:
   - Package name: `com.maximoaps.pelotitas`
   - Min SDK: 24 (Android 7.0)
   - Target SDK: 34+
5. One-click deploy: botón "play" en export preset

### Permisos Necesarios

- `INTERNET`: Multiplayer online
- `ACCESS_NETWORK_STATE`: Verificar conectividad
- `VIBRATE`: Feedback háptico (opcional)

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

_(No aplicable en esta fase - Android es la prioridad)_

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
