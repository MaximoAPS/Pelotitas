# Testing Guide: MVP Networking

This guide explains how to test the MVP networking implementation for Pelotitas.

## Prerequisites

- Godot 4.3+ installed
- Project opened in Godot Editor

## Test Scenarios

### 1. Local Testing (No Network)

**Purpose**: Verify the game still works without networking

**Steps**:
1. Open the project in Godot Editor
2. Press F5 (Run Project) or click Play button
3. Click "Prueba Local (vs IA)" button
4. **Expected**:
   - Arena loads with 2 players
   - Player 1 (blue) is controllable via WASD/arrows
   - Player 2 (orange) is a dummy target
   - Pressing 1/2/3 shoots projectiles that damage the dummy
   - Health bars update correctly
   - Game runs smoothly without network errors

### 2. Desktop Multiplayer Testing (2 Editor Instances)

**Purpose**: Test networking on same machine

**Steps**:

#### Setup Instance 1 (Server/Host):
1. Open project in Godot Editor
2. Run the project (F5)
3. In the main menu, click "Crear Servidor"
4. **Note the IP address shown** (e.g., "IP Local: 192.168.1.100")
5. Wait for connection (do NOT click "Iniciar Duelo" yet)

#### Setup Instance 2 (Client):
1. Open a SECOND Godot Editor instance
2. Open the same project
3. Run the project (F5)
4. Click "Unirse a Partida"
5. In the dialog:
   - Nickname: Enter any name (e.g., "Jugador2")
   - IP: Enter `127.0.0.1` (localhost for same machine)
   - Puerto: Leave as `7777`
6. Click "OK"

#### Start the Match:
7. On Instance 1 (host), the counter should now show "(1/2)"
8. Click "Iniciar Duelo" button on Instance 1
9. **Both instances should load the arena**

#### Verify Gameplay:
10. On each instance, test:
    - Movement (WASD/arrows) - each player controls their own character
    - Shooting (1/2/3 keys) - projectiles spawn and damage opponents
    - Both players should see each other moving
    - Damage and health sync correctly
    - Projectiles appear on both screens

**Expected Results**:
- ✅ Both players spawn in different positions
- ✅ Movement is smooth on owning client, synced on remote
- ✅ Projectiles spawn and hit correctly on both screens
- ✅ Health depletion is visible on both instances
- ✅ No errors in Godot console (Output panel)

**Common Issues**:
- If connection fails: Check firewall settings
- If players don't move: Authority issue - check console for errors
- If projectiles don't spawn: Check RPC configuration

### 3. WiFi LAN Testing (Android + Desktop or 2 Android Devices)

**Purpose**: Test on actual target platform over WiFi

**Prerequisites**:
- Export Android APK (see `docs/MOBILE_EXPORT.md`)
- Both devices on same WiFi network
- Firewall allows port 7777

**Steps**:

#### Host on Desktop:
1. Run project in Godot Editor
2. Click "Crear Servidor"
3. Note the **actual LAN IP** (e.g., 192.168.1.50)
4. Wait for client to connect

#### Join from Android:
1. Install and launch APK on Android device
2. Tap "Unirse a Partida"
3. Enter:
   - Nickname: your name
   - IP: The LAN IP from host (e.g., 192.168.1.50)
   - Puerto: 7777
4. Tap OK

#### Or Host on Android:
1. Launch APK on Android device
2. Tap "Crear Servidor"
3. **Note the IP shown** (write it down)
4. From desktop, join using that IP

#### Verify:
- Both players see each other in the arena
- Touch controls work on Android (joystick + ability buttons)
- Latency is acceptable over WiFi (< 100ms typical)
- Game remains stable during match

**Expected WiFi Performance**:
- Smooth movement with minimal lag
- Projectiles appear in sync
- No disconnections during gameplay

### 4. Edge Cases to Test

#### Disconnection Handling:
1. Start a match with 2 players
2. Close one client mid-game
3. **Expected**: The remaining player's console logs disconnection
4. **Known limitation**: Match doesn't handle reconnection (MVP scope)

#### Invalid IP:
1. Click "Unirse a Partida"
2. Enter invalid IP (e.g., "999.999.999.999")
3. **Expected**: Connection fails gracefully with console error

#### Port in Use:
1. Start server on port 7777
2. Try to start another server on same port
3. **Expected**: Error logged, server creation fails

## Debugging Tips

### Console Output to Look For:

**Successful Server Creation**:
```
[Net] Servidor creado en 192.168.1.50:7777, peer_id: 1
[UserPrefs] Preferencias cargadas: nickname='YourName'
```

**Successful Client Connection**:
```
[Net] Conectando a 192.168.1.50:7777...
[Net] Conectado al servidor exitosamente
[MainMenu] Conexión exitosa, iniciando duelo...
```

**Projectile Spawn (Both Sides)**:
```
[ArenaDuelo] Proyectil spawneado en red: owner=1, pos=(x, y)
[ElementalShot] player_1 disparó Disparo de Fuego hacia (x, y)
```

### Common Errors:

**"Error al crear servidor: 48"**
- Port already in use
- Solution: Change port or close other instance

**"Error al conectar: 1"**
- Cannot reach server (wrong IP, firewall, different network)
- Solution: Verify IP, check firewall, ensure same WiFi

**"No se encontró ArenaDuelo en la escena"**
- Scene structure issue
- Solution: Verify arena_duelo.tscn is loaded correctly

## Performance Metrics

Target performance for MVP:
- **Framerate**: 60 FPS stable on both host and client
- **Latency**: < 50ms on same WiFi (localhost), < 100ms on LAN
- **Bandwidth**: < 50 KB/s per client (position + projectile RPCs)

Monitor in Godot Editor:
- Debugger → Monitors → Network
- Check "RPC calls" and "Bytes sent/received"

## Next Steps After Testing

If all tests pass:
1. Document any bugs found in GitHub issues
2. Test on actual Android devices over WiFi
3. Consider implementing:
   - Reconnection handling
   - Better latency compensation
   - NAT traversal for cross-network play
   - Dedicated server option

## MVP Limitations (By Design)

These are known limitations of the MVP scope and are NOT bugs:
- ❌ No reconnection after disconnect
- ❌ Only works on same WiFi (no internet/WAN)
- ❌ Max 2 players only
- ❌ No matchmaking or lobby system
- ❌ No persistent accounts or stats
- ❌ Manual IP entry required (no discovery)
