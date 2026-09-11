# Documento de Diseño - Pelotitas

## Visión General

Juego **mobile-first** online 2D top-down de batallas entre pelotitas elementales. Arquitectura modular y escalable pensada para agregar nuevos modos, habilidades y mecánicas sin reescribir código existente.

**Plataforma primaria**: **Android** con controles táctiles  
**Plataforma futura**: iOS (posterior a Android)  
**Plataformas secundarias**: Desktop y web para desarrollo y testing

**Estado actual**: Scaffolding inicial - solo estructura base y stubs, no gameplay completo.

---

## ✅ Decisiones Cerradas

Estas decisiones están **bloqueadas** y no deben cambiarse sin aprobación explícita del usuario.

### Confirmación de Decisiones Core

Las siguientes decisiones están **firmemente locked** para MVP:
- ✅ **XP se gana por victorias** (fuente primaria)
- ✅ **Level cap inicial: 10** (Tier 1), luego +10 por tier con expansiones de contenido
- ✅ **Roster gratuito: 3 pelotitas** máximo en MVP

### Género y Mecánica Core

- **Género**: Batallas de pelotitas elementales (Fuego, Agua, Tierra, Aire/Viento)
- **Habilidades spawnen pelotitas coloreadas** según elemento
- **Tipos de habilidades**:
  - Disparos simples hacia adelante
  - Invocaciones (summons) que atacan automáticamente
  - Muros para cobertura y defensa

### Vista y Plataforma

- **Vista**: 2D top-down estilizado
  - Física completamente 2D
  - Esferas renderizadas con sombreado pseudo-3D (apariencia volumétrica)
  - Orientación landscape (horizontal)
- **Plataforma primaria**: Android móvil
- **Plataforma secundaria**: PC standalone para testing (editor embebido come input)

### Multijugador MVP

- **Red**: ENet host/join en misma WiFi local
- **NO cuentas de usuario** en MVP
- **Nickname local** solamente
- **Servidor autoritativo** para combate y física

### Modos de Juego

- **Arquitectura modular**: Modos plug-in con núcleo de combate compartido
- **Primer modo MVP**: **Duelo por Vida** (1v1)
  - Victoria: reducir HP enemigo a 0
  - Mapa: "Arena de Pilares" (locked)
- Futuros modos fáciles de agregar (CTF, King of the Hill, etc.)

### Mapa MVP (Locked)

**Primer mapa**: "Arena de Pilares"
- Arena rectangular 1920×1080 con paredes perimetrales
- **4-6 obstáculos fijos** (pilares/bloqueadores) distribuidos simétricamente
- **Obstáculos bloquean**: jugadores Y proyectiles (cover efectivo)
- **Obstáculos son indestructibles** (no pueden ser destruidos)
- **Colisión jugador-obstáculo**: daña (misma fórmula que paredes: velocidad × masa)
- **Proyectil en obstáculo**: explota (VFX elemental) y desaparece, sin daño AoE
- Propósito: cover táctico y líneas de sight interesantes

### Sistema de Cooldowns (Locked)

- **Solo cooldowns fijos** por habilidad (NO hay mana/energía)
- **Disparo básico**: 1.0s cooldown (provisional, tunable)
- Habilidades avanzadas: cooldowns más largos (TBD exactos)

### Controles Móviles

**Layout definitivo** (twin-stick-ish):
- **Palanca virtual** (izquierda inferior): movimiento 360° con deadzone
- **3 botones de habilidades usables** (derecha inferior): press-hold-drag-release para apuntar
- **Habilidad pasiva**: sin botón, siempre activa automáticamente (diferida)
- **HUD superior**: barra de vida

⚠️ **Este layout es definitivo** y no debe cambiarse sin aprobación del usuario.

### Stats de Jugador

Cada pelotita tiene **4 stats principales**:
- **Ataque** (`ataque`): daño infligido
- **Defensa** (`defensa`): reducción de daño recibido
- **Velocidad** (`velocidad`): multiplicador de velocidad de movimiento
- **Masa** (`masa`): peso en colisiones elásticas
  - ✅ **Locked MVP**: Masa = 1.0 fija (sin random, sin scaling)
  - Futuro: pasivas pueden modificar masa temporalmente

**Fórmula de daño**:
```
Daño Final = max(1, Ataque_atacante - Defensa_víctima × 0.5)
```

### Sistema de Velocidad

- **Relativo a la media geométrica** de velocidades de participantes
- **SPD = 1.0** (cuando velocidad stat = media geométrica) equivale a **1.0 m/s virtual**
- **Conversión**: `speed_px_s = speed_m_s × 200` (PIXELS_PER_METER = 200)
- **Aceleración**: fracción de `vmax` (inercia con aceleración ~900 px/s²)
- **Fricción**: desaceleración gradual (~700 px/s²) cuando no hay input

### Progresión y Level-Up

**Curva de XP** (Locked):
- **Fórmula exponencial**: `round(100 × 1.5^(n-1))`
  - Nivel 1: 100 XP, Nivel 2: 150 XP, Nivel 3: 225 XP, Nivel 4: 338 XP
  - Nivel 10: 3849 XP (total acumulado: 11347 XP)
- **Derrota**: 0 XP en MVP

**XP por Victoria** (Locked - provisional, sujeto a balance):
- **Fórmula**: Basada en diferencia de niveles
  ```
  diff = opponent_level - your_level
  if diff >= 0: xp = min(25 + 5*diff, 65)  # Cap en +40 bonus
  if diff < 0: xp = max(5, 25 + 5*diff)   # Mínimo 5 XP
  ```
- **Base**: 25 XP (mismo nivel)
- **Bonus**: +5 XP por cada nivel que el oponente esté arriba (cap en 65 XP)
- **Penalización**: -5 XP por cada nivel que el oponente esté abajo (mínimo 5 XP)
- **Estimación**: ~400-450 victorias para nivel 10 con matchmaking balanceado

**Level Cap**:
- **Tier 1 (MVP)**: nivel 0-10
- **Expansiones futuras**: +10 niveles por tier (20, 30, 40, etc.) con nuevo contenido
- XP ganada al alcanzar cap se guarda para el próximo tier

**Al subir de nivel, se otorgan**:
1. **+10 puntos de stats** distribuidos aleatoriamente entre ATK/DEF/Speed
   - Distribución aleatoria (enteros no negativos que suman exactamente 10)
2. **+1 punto de habilidad elemental** según **afinidad secreta** (estilo DinoRPG)
   - Cada pelotita tiene pesos elementales permanentes generados al crearla (ej: Fuego 40%, Agua 20%, Tierra 10%, Aire 30%)
   - Pesos son **secretos** y nunca se muestran al jugador
   - El elemento del punto otorgado se determina por sorteo aleatorio según estos pesos

### Loadout

- **3 habilidades usables** (activables con botones)
- **1 habilidad pasiva** (efecto automático permanente)

### Roster de Pelotitas

- **MVP**: **3 pelotitas gratis** (máximo)
- **Out of MVP**: Slots adicionales pagos (monetización futura, muy largo plazo)

**Selección antes de duelo** (Locked):
- Antes de iniciar un duelo, jugador **selecciona 1 pelotita** de su roster
- Pantalla de selección muestra: nombre, color, nivel, stats, récord (victorias/derrotas)
- La pelotita seleccionada determina: stats del match, habilidades disponibles, XP ganada

**Borrado de pelotita** (Locked):
- Cuando roster lleno (3/3), jugador puede **borrar** una pelotita para liberar espacio
- **Doble confirmación requerida**: Modal + input manual del nombre
- **Sin undo en MVP**: Borrado es permanente (archivo eliminado del disco)

### Creación de Pelotita (Locked)

**Flujo de creación**:
- Jugador ingresa **solo el nombre** (3-16 caracteres)
- Sistema genera automáticamente:
  - Stats: 50/50/50 base + roll aleatorio +10 entre ATK/DEF/SPD
  - Afinidades secretas (4 pesos elementales, suma = 1.0)
  - Color visual derivado del elemento dominante en afinidad
- **Jugador NO elige**: stats, color, elemento, apariencia
- **Filosofía**: Descubrir la identidad de la pelotita durante el juego, no elegirla

### Disparo Básico Elemental

Cada elemento tiene un disparo básico con:
- **Velocidad**: configurada por habilidad (ej: 400 px/s)
- **Masa**: propiedad del proyectil
- **Radio**: tamaño de colisión
- **Daño bruto**: calculado según ATK vs DEF
- **Al impactar**: 
  - VFX de explosión (placeholder: círculo coloreado)
  - Aplicar daño vs DEF enemigo
  - Knockback proporcional a masa × velocidad (~150 px/s inicial)
  - Proyectil desaparece (despawn)

### Física y Colisiones

**Entre jugadores (pelotita vs pelotita)**:
- Colisiones elásticas perfectas (conservación de momento y energía)
- **NO causan daño** por sí mismas
- Masa determina quién empuja más

**Con paredes**:
- **SÍ causan daño** basado en velocidad de impacto
- Fórmula: `wall_damage = (impact_speed - 100.0) × 0.02 × masa`
- Umbral mínimo: 100 px/s

**Futuro: Antimatter entre proyectiles rivales**
- Colisión entre proyectiles enemigos cancela masas (ver sección de visión a largo plazo)

### Dummy para Testing

- **Player 2 dummy**: estacionario con trayectoria que busca centro (aceleración más débil que Player 1)
- NO persigue al jugador activo
- Solo sirve como target de prueba

### Flujo de la Aplicación

```
Boot → Menú Principal → Duelo → Resultado (Otra vez / Menú)
```

- **NO auto-start** en duelo
- Usuario siempre elige desde menú

### Orden de Desarrollo

1. **Core hasta que matches multiplayer funcionen**
2. Definir valores de stats y niveles
3. Implementar habilidades elementales concretas
4. UI beta touch-friendly
5. Balance, modos adicionales, y escalabilidad

---

## ❓ Pendientes de Definir

Estas son **preguntas abiertas** que aún no tienen respuesta definitiva. **NO inventar respuestas**.

### Distribución de Puntos de Stats

- ¿Los 10 puntos de stats pueden asignarse todos a un solo stat, o hay mínimos/máximos por stat?

### Stats Iniciales

- ¿Valores iniciales de ATK/DEF/Speed/masa en nivel 1?

### Sistema de XP y Progresión

- ¿La curva exponencial 1.5x se siente adecuada en playtesting?
- ¿Los valores de XP (base 25, ±5 por diff, cap 5-65) necesitan ajustes?
- ¿La fórmula incentiva correctamente enfrentar oponentes más fuertes?
- ¿Considerar XP por derrota post-MVP para mejorar retención?

### Flujo de Creación

- ¿Cómo es el flujo exacto de creación de pelotita? (UI, pasos, confirmación)

### Moneda Soft

- ¿Habrá moneda soft (coins, gems, etc.) o no?

### Configuración de Mapa

- ¿Tamaño de mapa para duelo?
- ¿Obstáculos en el mapa?

### Sistema de Recursos

- ¿Cooldowns por defecto para habilidades?
- ¿Sistema de mana/energía o solo cooldowns?

### Reglas de Multijugador

- ¿Qué pasa si un jugador se desconecta?
- ¿Hay opción de rejoin/reconnect?

### Mecánica de "Explotar"

- ¿La explosión de proyectiles tiene área de efecto (AoE)?
- ¿O es solo daño directo single-target + VFX?

---

## Detalle Técnico: Decisiones de Diseño Bloqueadas

Esta sección expande las decisiones cerradas con detalles de implementación.

### 1. Género y Temática

**Batallas de pelotitas elementales**: Fuego, Agua, Tierra, Aire/Viento.

- Cada elemento tiene habilidades únicas que spawnen más pelotitas de diferentes colores
- Tipos de habilidades:
  - **Disparos simples hacia adelante**
  - **Invocaciones (summons)** que atacan automáticamente
  - **Muros** para cobertura y defensa

### 2. Vista y Gráficos

**2D top-down con apariencia pseudo-3D**:

- La física y las escenas son **completamente 2D**
- Las esferas se renderizan con **sombreado y highlights** para dar sensación de volumen 3D
- Estilo visual estilizado (no realista)
- **Orientación landscape** (horizontal) para combate en arena

### 3. Multijugador y Plataforma

**Android-first con PvP online**:

- **Plataforma primaria**: **Android** con controles táctiles (gama media/alta target)
- **Plataforma futura**: iOS (mismo código base, requiere Mac para build)
- **Plataformas secundarias**: Desktop/web para desarrollo y testing
- Sistema de autoridad de red (Godot High-Level Multiplayer API)
- **Servidor autoritativo** para combate y física
- **Path local/bots** para testing e iteración sin oponente remoto
- Optimización de red para WiFi/4G/5G móvil

#### MVP Networking (Implementado)

**Alcance del MVP de red:**
- **Sin backend ni cuentas**: Solo host/join directo por IP en misma WiFi
- **ENet peer-to-peer**: Un jugador hostea, otro se une por IP
- **Nickname local**: Almacenado en `user://user_prefs.cfg` (ConfigFile), sin login
- **Sincronización básica**: Posiciones de jugadores y proyectiles via MultiplayerSynchronizer y RPCs

**Flujo de conexión:**
1. **Host crea servidor**:
   - Botón "Crear Servidor" en menú principal
   - Servidor ENet en puerto 7777 (configurable)
   - Muestra IP local (ej: 192.168.1.100) para que otros jugadores se conecten
   - Espera a que se una 1 cliente (mínimo 2 jugadores para duelo)
   - Botón "Iniciar Duelo" se habilita cuando hay suficientes jugadores
   
2. **Cliente se une**:
   - Botón "Unirse a Partida" → diálogo con inputs:
     - Nickname (cargado desde preferencias locales)
     - IP del servidor (default: 127.0.0.1)
     - Puerto (default: 7777)
   - Al conectar exitosamente, envía nickname al servidor via RPC
   - Automáticamente entra a la arena cuando el host inicia duelo

3. **En duelo**:
   - Servidor tiene autoridad sobre jugadores y proyectiles
   - Posiciones de jugadores sincronizadas con MultiplayerSynchronizer
   - Proyectiles spawneados via RPC (`_spawn_projectile_networked`)
   - Solo el authority (dueño) del jugador procesa input y física de ese jugador

**Limitaciones del MVP:**
- Solo WiFi local (misma red)
- Sin matchmaking ni lobby público
- Máximo 2 jugadores (1v1)
- Sin reconexión automática
- Sin NAT traversal (no funciona entre redes diferentes)
- Sin persistencia de partidas (si se desconecta, se pierde el duelo)

**Para Android WiFi testing:**
- Ambos dispositivos deben estar en la misma red WiFi
- Host necesita saber su IP local (mostrada en el diálogo)
- Cliente ingresa la IP del host manualmente
- Permisos requeridos: `INTERNET`, `ACCESS_NETWORK_STATE`

**Controles táctiles (Android-optimized) - Layout y mecánicas bloqueadas**:

Layout estilo **twin-stick-ish** (stick izquierda, botones derecha):

```
┌──────────────────────────────────────────────┐
│ [███ HP 100/100 ██████████████]              │  ← Barra de vida
│                                              │
│                         →                    │  ← Indicador de apuntado
│                    ARENA        (hold+drag)  │     (visual feedback)
│                                              │
│                                              │
│                                              │
│  [  ◉  ]                        [ 1 ]        │  ← Izquierda: Palanca
│   PALANCA                       [ 2 ]        │  ← Derecha: 3 botones
│                                 [ 3 ]        │     (press-hold-drag-release)
└──────────────────────────────────────────────┘
```

### Mecánicas de Control

**Movimiento (Palanca / Joystick virtual - izquierda inferior)**:
- Movimiento 360° con deadzone
- Drag dentro del área de la palanca
- Independiente del sistema de habilidades

**Habilidades usables (3 botones - derecha inferior)**:

Sistema **press-and-hold-drag-release** para apuntado preciso:

1. **Press y hold** en botón de habilidad (1, 2, o 3)
   - Inicia modo de apuntado
   - Habilidad no se activa todavía
   - Visual feedback: botón resaltado

2. **Drag** en la dirección deseada
   - Mientras mantienes presionado, arrastra el dedo
   - La dirección del arrastre determina hacia dónde se lanzará la habilidad
   - Visual feedback: flecha/línea de apuntado desde el jugador (TODO)

3. **Release** para disparar
   - Suelta el dedo para activar la habilidad
   - La habilidad se lanza en la dirección que arrastraste
   - Si no hay arrastre significativo (< 30px), usa dirección por defecto (derecha)

**Habilidad pasiva**: 
- NO tiene botón - siempre está activa automáticamente en segundo plano
- Sin interacción del jugador requerida

**HUD superior**: 
- Barra de vida
- **Cooldowns visuales**: Radial/overlay circular progress en botones (✅ locked - ver GDD §17)

**Feedback**: 
- Visual al presionar y durante drag
- Vibración háptica Android al disparar (futuro)

⚠️ **Este layout y mecánica de control son definitivos** y no deben cambiarse sin aprobación del usuario.

### 4. Sistema de Modos Modular

**Arquitectura plug-in** para modos de juego:

- **Núcleo de combate compartido**: jugador, movimiento, habilidades, daño
- **Cada modo solo define**:
  - Condiciones de victoria
  - Reglas de spawn (jugadores, objetos)
  - Configuración de mapa
  - Lógica específica de eventos

**Primer modo shippable**: **Duelo por Vida** (1v1)
- Gana el primero en reducir la vida del rival a 0
- Mapa: "Arena de Pilares" con 4-6 obstáculos fijos

**Futuros modos fáciles de agregar** (solo requieren nueva clase de `Mode`):
- Captura la Bandera
- Destruye la Estructura
- Team Deathmatch
- King of the Hill
- Knockout (empujar rivales fuera del mapa)

### 5. Progresión y Skill Tree

**Subir de nivel otorga puntos de habilidad elementales**:

- Al subir de nivel, recibes **1 punto de habilidad** de un elemento
- Los puntos se usan para **comprar o mejorar habilidades**
- Las habilidades pueden **desbloquear otras habilidades** (árbol de dependencias)

**Sistema de Afinidad (estilo DinoRPG)**:

- Al **crear una pelotita**, se generan pesos elementales aleatorios **permanentes**
  - Ejemplo: Fuego 15%, Aire 15%, Agua 35%, Tierra 35%
  - Suma total: 100%
- Estos pesos son **secretos** y nunca se muestran al jugador
- Al subir de nivel, el **elemento del punto otorgado** se tira aleatoriamente según estos pesos
- Cada pelotita tiene sus propios pesos únicos **para toda la vida**

**Ejemplo**:
```
Pelotita "Chispa":
  Afinidad secreta: Fuego 40%, Agua 20%, Tierra 10%, Aire 30%
  
  Level up 1: tira 40% → Fuego (+1 punto Fuego)
  Level up 2: tira 85% → Aire (+1 punto Aire)
  Level up 3: tira 15% → Agua (+1 punto Agua)
```

**Distribución de puntos de stats**:

Al subir de nivel, se otorgan **+10 puntos de stats** distribuidos aleatoriamente entre ATK/DEF/Speed:
- Son enteros no negativos que suman exactamente 10
- Distribución es aleatoria (cada stat puede recibir entre 0 y 10 puntos en un level-up)

⚠️ **Pendiente de definir**: ¿Hay mínimos/máximos por stat? (ver sección "Pendientes de Definir")

### 6. Loadout por Duelo

Cada pelotita equipa **3 habilidades usables + 1 pasiva** antes de entrar al duelo.

- **Habilidades usables**: se activan con botones táctiles (1, 2, 3) o teclas en desktop
  - Tienen cooldown
  - Requieren presionar botón para ejecutar
  - Cada una tiene su propio slot en el HUD (derecha inferior)
- **Habilidad pasiva**: efecto permanente automático (ej: +10% velocidad, regeneración)
  - NO tiene botón en el HUD
  - Siempre está activa durante el duelo
  - Efecto aplicado automáticamente al jugador

### 7. Stats de Combate

Cada pelotita tiene cuatro estadísticas base que afectan su desempeño en combate:

#### Stats Principales

- **Ataque** (`ataque`): Determina el daño que inflige la pelotita con sus habilidades
- **Defensa** (`defensa`): Reduce el daño recibido de ataques enemigos
- **Velocidad** (`velocidad`): Multiplicador de la velocidad de movimiento de la pelotita
- **Masa** (`masa`): Determina la respuesta en colisiones elásticas con otras pelotitas (valores mayores empujan más)

#### Fórmula de Daño

El daño final aplicado cuando un proyectil impacta a un enemigo se calcula como:

```
Daño Final = max(1, Ataque_atacante - Defensa_víctima × 0.5)
```

**Explicación**:
- El ataque del atacante se reduce por la mitad de la defensa de la víctima
- El daño mínimo es siempre 1 (no puede ser 0 o negativo)
- Valores típicos iniciales: Ataque 10, Defensa 5 → Daño = max(1, 10 - 5×0.5) = 7.5 ≈ 8

**Ejemplo de cálculo**:
```
Pelotita A (Ataque: 15) ataca a Pelotita B (Defensa: 8)
Daño = max(1, 15 - 8 × 0.5) = max(1, 15 - 4) = 11
```

#### Velocidad de Movimiento (Sistema Relativo con Inercia)

La velocidad de movimiento usa un sistema **relativo** basado en la media geométrica de todos los participantes del match, con física de **inercia** para movimiento fluido.

**Sistema de inercia** (✅ locked):
- El input del jugador define una **dirección deseada**, no velocidad instantánea
- La pelotita **acelera** hacia la dirección deseada: **aceleracion = vmax / 4** (≈4s de 0 a max speed)
- **Sin fricción**: Al soltar stick, pelotita continúa con velocidad actual (coast con inercia indefinidamente)
- La velocidad se clampea a la **velocidad máxima** calculada del stat (`speed_m_s × PIXELS_PER_METER`)
- Resultado: movimiento con peso e inercia, coasting espacial/ice-like
- **Tunable**: Si aceleración sluggish, reducir factor (ej: vmax/3 = 3s, vmax/2 = 2s)
- **Futuro**: Si coasting muy difícil, agregar fricción muy baja (ej: vmax/20 o menor)

**Fórmula**:

1. **Media geométrica** de velocidades de participantes:
   ```
   G = (∏ V_i)^(1/n)
   ```
   Donde `V_i` es el stat de velocidad de cada participante y `n` es el número de participantes.

2. **Velocidad en metros virtuales por segundo** para cada pelotita:
   ```
   speed_m_s = V_i / G
   ```
   Una pelotita con `velocidad = G` se mueve a exactamente **1.0 m/s**.

3. **Conversión a píxeles**:
   ```
   speed_px_s = speed_m_s × PIXELS_PER_METER
   ```
   **Constante de escala**: `PIXELS_PER_METER = 200 px/m`
   - Elegida para pantallas 1920×1080 landscape (Android)
   - Define la escala visual de la arena

**Ejemplo numérico (Duelo 1v1)**:

```
Participantes:
- Pelotita A: velocidad = 1.5
- Pelotita B: velocidad = 0.75

Media geométrica:
G = (1.5 × 0.75)^(1/2) = (1.125)^0.5 ≈ 1.061

Velocidades normalizadas:
- Pelotita A: speed_m_s = 1.5 / 1.061 ≈ 1.414 m/s
  → speed_px_s = 1.414 × 200 ≈ 283 px/s
  
- Pelotita B: speed_m_s = 0.75 / 1.061 ≈ 0.707 m/s
  → speed_px_s = 0.707 × 200 ≈ 141 px/s

Relación: A es ~2× más rápida que B (1.5 / 0.75 = 2.0)
```

**Ventajas del sistema relativo**:
- Las velocidades son **proporcionales** entre jugadores
- Un jugador con el doble de stat de velocidad se mueve al doble de velocidad
- Independiente de valores absolutos (funciona igual con 1-2 que con 100-200)
- Se recalcula al inicio de cada match según participantes

**Guardas de seguridad**:
- `V_i <= 0` se clampea a `0.01` (epsilon mínimo)
- Previene división por cero y valores inválidos

**Nota importante**: La velocidad de **proyectiles** es independiente del stat de velocidad del personaje. Cada habilidad define su propia velocidad de proyectil (puede usar m/s con la misma constante PIXELS_PER_METER, ej: 2.0 m/s = 400 px/s para disparos básicos elementales).

#### Knockback (Retroceso)

Cuando un proyectil impacta a una pelotita:
- La víctima es empujada en dirección opuesta al impacto
- La fuerza de knockback es fija: **150 píxeles/segundo** inicialmente
- El knockback puede escalarse ligeramente con el ataque en el futuro
- Propósito: Separar combatientes y crear dinámica posicional

### 8. Sistema de Física y Colisiones

El juego implementa física de esferas rígidas para colisiones entre pelotitas y daño por impacto contra paredes.

#### Colisiones entre Jugadores (Pelotita vs Pelotita)

**Mecánica**: Colisiones elásticas perfectas (sin deformación)

- Las pelotitas se comportan como esferas rígidas que rebotan al colisionar
- **NO causan daño** por sí mismas
- La respuesta de colisión depende de la **masa** de cada pelotita:
  - Una pelotita con mayor masa empuja más a una con menor masa
  - Conservación de momento lineal y energía cinética (colisión perfectamente elástica)
- **Fórmula de impulso elástico**:
  ```
  impulse_scalar = -(1 + e) × v_rel · n / (1/m1 + 1/m2)
  ```
  Donde:
  - `e = 1.0` (coeficiente de restitución, perfectamente elástico)
  - `v_rel` = velocidad relativa entre pelotitas
  - `n` = normal de colisión (dirección de separación normalizada)
  - `m1`, `m2` = masas de las pelotitas

**Propósito estratégico**:
- Empujar al rival contra la pared para causar daño indirecto
- Habilidades como dash/empuje permiten knockback direccional
- Diferencias de masa crean asimetrías tácticas (pasivas que aumentan masa vienen en futuro)

#### Colisiones con Paredes (Pelotita vs Arena)

**Mecánica**: Daño por impacto basado en velocidad

- Las paredes de la arena son `StaticBody2D` con colisión
- **SÍ causan daño** al impactar, escalando con velocidad de impacto
- **Fórmula de daño por pared**:
  ```
  if impact_speed > WALL_DAMAGE_THRESHOLD:
      wall_damage = (impact_speed - threshold) × WALL_DAMAGE_MULTIPLIER × masa
  ```
  Donde:
  - `WALL_DAMAGE_THRESHOLD = 100.0 px/s` (velocidad mínima para causar daño)
  - `WALL_DAMAGE_MULTIPLIER = 0.02` (daño por unidad de velocidad)
  - `impact_speed` = velocidad del jugador proyectada sobre la normal de la pared
  - `masa` = stat de masa de la pelotita

**Ejemplo**:
```
Pelotita con masa=1.0 impacta pared a 300 px/s:
wall_damage = (300 - 100) × 0.02 × 1.0 = 4 puntos de daño

Pelotita con masa=1.5 impacta pared a 400 px/s:
wall_damage = (400 - 100) × 0.02 × 1.5 = 9 puntos de daño
```

**Propósito estratégico**:
- Crear zonas de peligro en los bordes del mapa
- Recompensar posicionamiento defensivo central
- Habilidades de empuje/dash se vuelven ofensivas al forzar colisiones de pared
- Mayor masa = mayor daño recibido de paredes (trade-off táctico)

#### Configuración de Arena

- **Dimensiones**: 1920×1080 píxeles (landscape móvil)
- **Paredes**: Rectángulos de 20px de grosor en los 4 bordes
- **Color de paredes**: Rojo oscuro (Color(0.6, 0.2, 0.2, 1)) para indicar peligro
- **Posiciones de spawn**: Alejadas de las paredes (300px desde borde izquierdo, 1620px desde derecho)

### 9. Sistema de Triggers para Habilidades

Las habilidades pueden responder a eventos del juego mediante **triggers** (hooks). Esto permite mecánicas complejas sin hardcodear comportamientos específicos.

#### Triggers Disponibles

Todos los triggers están definidos en la clase base `Ability` y pueden ser sobrescritos en habilidades concretas:

**Triggers de ciclo de vida**:
- `on_equip(player: Player)`: Llamado cuando se equipa la habilidad en el loadout (antes del match)
- `on_match_start(player: Player)`: Llamado al inicio del match (ej: aplicar buff de velocidad)

**Triggers de combate** (solo `UsableAbility`):
- `on_activate(caster: Player, aim_direction: Vector2)`: Llamado al usar la habilidad (después de pasar cooldown)
- `on_hit_enemy(caster: Player, target: Player, projectile: Node2D)`: Llamado cuando un proyectil de esta habilidad impacta enemigo

**Triggers de colisión**:
- `on_collide_player(self_player: Player, other_player: Player)`: Llamado cuando el jugador colisiona con otro jugador
- `on_collide_wall(player: Player, impact_point: Vector2, wall_normal: Vector2)`: Llamado cuando el jugador colisiona con pared

#### Flujo de Ejecución de Triggers

```
1. Equipar loadout:
   loadout.trigger_on_equip()
   → ability.on_equip(player)

2. Iniciar match:
   loadout.trigger_on_match_start()
   → ability.on_match_start(player)

3. Usar habilidad:
   ability.try_use(caster, aim_dir)
   → ability.on_activate(caster, aim_dir)
   → ability.execute(caster, aim_dir)  # Lógica principal

4. Proyectil impacta enemigo:
   projectile._on_body_entered(enemy)
   → ability.on_hit_enemy(caster, enemy, projectile)

5. Jugador colisiona con otro jugador:
   player._handle_player_collisions()
   → loadout.trigger_on_collide_player(self, other)
   → ability.on_collide_player(self, other)

6. Jugador colisiona con pared:
   player._handle_wall_collisions()
   → loadout.trigger_on_collide_wall(player, point, normal)
   → ability.on_collide_wall(player, point, normal)
```

#### Ejemplos de Uso de Triggers

**Ejemplo 1: Pasiva de velocidad al inicio de match**
```gdscript
# PassiveSpeedBoost.gd
extends PassiveAbility

func on_match_start(player: Player) -> void:
    player.velocidad *= 1.2  # +20% velocidad
    print("[PassiveSpeedBoost] Velocidad aumentada")
```

**Ejemplo 2: Habilidad que hace daño extra al contacto**
```gdscript
# ContactDamage.gd
extends PassiveAbility

func on_collide_player(self_player: Player, other_player: Player) -> void:
    var damage = self_player.ataque * 0.5
    other_player.take_damage(int(damage))
    print("[ContactDamage] Daño por contacto aplicado")
```

**Ejemplo 3: Dash que empuja al enemigo contra la pared**
```gdscript
# DashAbility.gd
extends UsableAbility

func on_activate(caster: Player, aim_direction: Vector2) -> void:
    # Aplicar velocidad instantánea en dirección del dash
    caster.velocity = aim_direction.normalized() * 800.0
    print("[Dash] Empuje direccional aplicado")
```

**Ejemplo 4: Proyectil que cura al impactar**
```gdscript
# VampireShot.gd
extends UsableAbility

func on_hit_enemy(caster: Player, target: Player, projectile: Node2D) -> void:
    var heal_amount = 5
    caster.heal(heal_amount)
    print("[VampireShot] %d vida recuperada" % heal_amount)
```

#### Implementación Técnica

- **`Loadout`** gestiona los triggers y los propaga a todas las habilidades equipadas
- **`Projectile`** almacena referencias a `source_ability` y `source_player` para invocar `on_hit_enemy`
- **`Player`** detecta colisiones en `_physics_process()` y llama a los triggers del loadout
- Las habilidades **no necesitan implementar todos los triggers**, solo los relevantes (implementación por defecto vacía en `Ability`)

---

## Roadmap de Implementación

### Orden de Prioridad (Bloqueado)

**1. Core (EN PROGRESO)**
- Pulir flujo básico hasta poder jugar múltiples partidas multiplayer seguidas
- Estado actual: Flow local funciona (boot → menu → duel → results → restart)
- Pendiente: Red/multiplayer estable, reconexión, múltiples rondas sin bugs

**2. Stats y Nivel (PRE-habilidades)**
- Definir cómo ATK/DEF/Speed/Masa se modifican al subir de nivel
- Sistema de progresión: XP → Level up → puntos de stat
- Fórmulas de crecimiento de stats por nivel
- **Bloquea habilidades**: las habilidades usarán estos stats, no al revés

**3. Habilidades**
- Implementar skill tree elemental con dependencias
- Habilidades usan stats ya definidos (ATK escala daño, etc.)
- Triggers y mecánicas complejas

**4. UI de Beta**
- HUD elaborado, animaciones, feedback visual rico
- Menús de loadout y skill tree
- Polish visual para primera beta pública

**5. Balance y Modos Adicionales**
- Ajustar stats, habilidades, tiempos
- Captura la Bandera, Team Deathmatch, etc.
- Escalar contenido

⚠️ **NO implementar habilidades antes de definir sistema de stats/nivel**. Las habilidades dependen de stats finales.

---

## Flujo de App v0.1

### Secuencia de Pantallas

El flujo básico de la aplicación para la versión 0.1 local:

```
Boot (1s splash)
    ↓
Main Menu
    ├─→ Prueba Local → Arena Duelo → Results Screen
    │                      ↓              ├─→ Otra vez (restart arena)
    │                   (combate)         └─→ Menú principal
    ├─→ Crear Servidor (stub, no implementado)
    ├─→ Unirse a Partida (stub, no implementado)
    └─→ Salir (cierra app)
```

### Descripción de Pantallas

**1. Boot (`scenes/boot/boot.tscn`)**
- Splash screen de 1 segundo
- Carga recursos globales y autoloads
- Transiciona automáticamente al menú principal
- **NO auto-start** al arena (debug mode removido)

**2. Main Menu (`scenes/menus/main_menu.tscn`)**
- Título: "PELOTITAS" + subtítulo "v0.1 local"
- Botones:
  - **Prueba Local**: Inicia duelo 1v1 local (player vs dummy)
  - **Crear Servidor**: Stub para networking futuro
  - **Unirse a Partida**: Stub para networking futuro
  - **Salir**: Cierra la aplicación
- Layout centrado, botones grandes y mobile-friendly
- Sin auto-start timer que salte al arena

**3. Arena Duelo (`scenes/duel/arena_duelo.tscn`)**
- Duelo 1v1: Player controlable vs Dummy estacionario
- Player 1 (azul): Controlado por joystick/teclado
- Player 2 (rojo/naranja): Dummy que NO se mueve, solo recibe daño
- Física de colisiones y habilidades activas
- HUD móvil con controles táctiles
- **Victory detection**: Cuando un jugador muere (HP = 0), se llama `Game.end_duel()`

**4. Results Screen (`scenes/ui/results_screen.tscn`)**
- Overlay CanvasLayer sobre la arena
- Muestra resultado:
  - **"¡GANASTE!"** si el jugador local ganó
  - **"PERDISTE"** si el jugador local perdió
  - **"¡EMPATE!"** si ambos murieron simultáneamente
- Botones:
  - **Otra vez**: Reinicia el duelo (recarga arena con nuevo modo)
  - **Menú principal**: Vuelve al menú principal
- Aparece automáticamente cuando `Game.duel_ended` signal se emite

### Flujo Técnico

**Inicio de Duelo (Prueba Local)**:
1. Usuario presiona "Prueba Local" en menú
2. `MainMenu._on_local_test_pressed()` crea instancia de `DueloPorVida`
3. Llama `Game.start_duel(mode)` (cambia estado a `IN_DUEL`)
4. Cambia escena a `arena_duelo.tscn`

**Durante Duelo**:
1. `ArenaDuelo._ready()` spawns jugadores y registra en modo
2. `Mode.register_player()` conecta signal `player.died` a `_on_player_died`
3. Jugadores combaten usando habilidades y movimiento
4. `Mode.process(delta)` actualiza lógica del modo cada frame

**Fin de Duelo**:
1. Jugador muere → `Player.take_damage()` detecta `current_health <= 0`
2. `Player._die()` emite signal `died`
3. `Mode._on_player_died()` → `DueloPorVida.on_player_death()`
4. `DueloPorVida.check_victory_conditions()` verifica jugadores vivos
5. `DueloPorVida._declare_victory(winner_id)` → `Game.end_duel(winner_id)`
6. `Game.end_duel()` emite signal `duel_ended` y cambia estado a `POST_DUEL`
7. `ArenaDuelo._on_duel_ended()` llama `results_screen.show_results(winner_id)`
8. Results screen overlay aparece con botones de reinicio o menú

**Restart o Return**:
- **Otra vez**: `ResultsScreen._on_restart_pressed()` recrea modo y recarga escena actual
- **Menú principal**: `ResultsScreen._on_main_menu_pressed()` cambia estado a `MAIN_MENU` y carga `main_menu.tscn`

### Decisiones de Diseño

**¿Por qué no auto-start al arena?**
- Testing y debugging requieren acceso al menú
- Usuario debe elegir explícitamente el modo de juego
- Facilita testing de networking cuando se implemente

**¿Por qué overlay en lugar de cambio de escena?**
- Permite ver el estado final del duelo (posiciones, HP)
- Más rápido que recargar toda la escena
- Mejor UX para mobile (sin flash de carga)

**¿Por qué reload_current_scene() para restart?**
- Limpia todo el estado del duelo anterior
- Garantiza spawn fresco de jugadores y proyectiles
- Evita bugs de estado persistente

---

## Visión: pelotas, masa y trayectorias

⚠️ **FUTURO / NO REQUERIDO PARA MVP APK ACTUAL**

Esta sección documenta la visión a largo plazo del sistema de combate basado en **pelotas elementales con masa**, **colisiones de antimateria** y **trayectorias pluggables**. El modelo descrito aquí NO es parte del MVP actual, pero define la arquitectura hacia la que evolucionará el sistema de habilidades y proyectiles.

### 1. Modelo de Pelotas Elementales

Cada habilidad usable recibe:
- **Jugador actual** (`Player`)
- **Dirección de apuntado** (`Vector2`) originando desde la posición del jugador

Al activarse, la habilidad **spawnea una o más pelotas elementales** con las siguientes propiedades configuradas:

```gdscript
# Propiedades de cada pelota elemental:
- masa: float             # Masa física de la pelota
- elemento: Elemento      # Fuego, Agua, Tierra, Aire
- owner_team: int         # Equipo/peer_id del dueño
- trajectory_behavior: TrajectoryBehavior  # Script de comportamiento de movimiento
- velocidad_inicial: Vector2  # Velocidad inicial (aplicada como fuerza/impulso)
```

**Diseño clave**: Las pelotas son entidades físicas independientes del jugador que las lanzó. Pueden continuar existiendo, cambiar de tamaño, duplicarse, o interactuar con otras pelotas según su configuración.

### 2. Colisiones de Antimateria

Cuando dos pelotas elementales **de equipos rivales** colisionan:

**Mecánica central**: Las pelotas rivales actúan como **antimateria** — sus masas se cancelan mutuamente.

#### Resolución de Colisión:

1. **Calcular masas efectivas** (aplicar modificadores elementales primero)
2. **Cancelar masas**: La pelota con mayor masa efectiva sobrevive
3. **Masa restante**: La pelota superviviente continúa con `masa_restante = masa_mayor - masa_menor`
4. **Trayectoria**: La pelota superviviente continúa en su trayectoria original con la masa reducida
5. **Aniquilación**: Si ambas masas son iguales, ambas pelotas se destruyen

#### Ejemplo Básico:

```
Pelota A (Fuego, masa=5.0) colisiona con Pelota B (Agua, masa=3.0)

Sin modificadores:
→ Pelota A sobrevive con masa=2.0 (5.0 - 3.0)
→ Pelota B se destruye
→ Pelota A continúa su trayectoria original
```

### 3. Modificadores Elementales

Los elementos pueden tener **ventajas de masa** en la resolución de colisiones:

**Ejemplo: Agua vs Fuego**
- Masa de agua cuenta como **×1.5** durante la cancelación
- Después de resolver la colisión, la masa vuelve a su factor normal

#### Ejemplo con Modificador:

```
Pelota Agua (masa=3.0) vs Pelota Fuego (masa=4.0)

Paso 1: Aplicar modificador elemental
  masa_efectiva_agua = 3.0 × 1.5 = 4.5

Paso 2: Cancelar masas
  masa_restante = 4.5 - 4.0 = 0.5

Paso 3: Volver a factor normal
  masa_final_agua = 0.5 / 1.5 ≈ 0.33

Resultado:
→ Pelota Agua sobrevive con masa≈0.33
→ Pelota Fuego se destruye
```

**Matriz de ventajas elementales** (a definir):
```
Agua vs Fuego:   ×1.5
Fuego vs Tierra: ×1.5
Tierra vs Aire:  ×1.5
Aire vs Agua:    ×1.5
```

### 4. Comportamientos de Trayectoria (Pluggable)

Las pelotas NO tienen una física fija — su movimiento está determinado por **scripts de comportamiento intercambiables**:

**Clase base**: `TrajectoryBehavior` (Resource o script adjunto)

```gdscript
class_name TrajectoryBehavior extends Resource

## Llamado cada frame para actualizar movimiento de la pelota
func update_movement(ball: BallBody, delta: float) -> void:
    pass
```

#### Comportamientos Concretos (stubs para futuro):

**1. `RectilinearTrajectory`**: Movimiento rectilíneo uniforme
```gdscript
# Pelota se mueve en línea recta a velocidad constante
# Usado por: Disparos elementales básicos
```

**2. `ChaseTargetTrajectory`**: Perseguir jugador rival
```gdscript
# Pelota persigue al jugador enemigo más cercano
# Velocidad basada en masa (más masa = más lenta)
# Usado por: Invocaciones (summons), proyectiles teledirigidos
```

**3. `StationaryWallTrajectory`**: Estático (muro)
```gdscript
# Pelota permanece inmóvil en su posición de spawn
# Bloquea/aniquila proyectiles enemigos que la impactan
# Usado por: Muros de tierra, barreras defensivas
```

**Extensibilidad futura**:
- `OrbitalTrajectory`: Orbita alrededor del jugador
- `BoomerangTrajectory`: Va y vuelve
- `SpiralTrajectory`: Espiral expandente
- `ZigZagTrajectory`: Movimiento en zigzag

### 5. Cambios Dinámicos de Pelotas (Futuro)

Las pelotas pueden evolucionar durante su existencia:

**Escalado de tamaño**:
- Masa determina tamaño visual (radio ∝ sqrt(masa))
- A medida que la pelota pierde masa en colisiones, se hace visualmente más pequeña

**Duplicación temporal**:
- Algunas habilidades pueden hacer que pelotas se dupliquen después de X segundos
- Cada copia hereda porcentaje de la masa original

**Absorción de aliados**:
- Pelotas del mismo equipo pueden fusionarse, sumando sus masas

### 6. Filosofía de Diseño: Fuerzas sobre Masas

⚠️ **PRINCIPIO ARQUITECTÓNICO FUNDAMENTAL**

El sistema debe preferir **aplicar fuerzas a masas** (con inercia física significativa) en lugar de **setear velocidades directamente**.

**Razones**:
1. **Inercia hace el juego táctil**: Jugadores y pelotas tienen peso, no se detienen instantáneamente
2. **Consistencia física**: Todas las entidades responden a fuerzas de manera uniforme
3. **Emergencia táctica**: Masas diferentes responden diferente a la misma fuerza (pelotitas pesadas son lentas pero estables)

**Aplicable a**:
- **Movimiento de pelotitas jugadoras**: Palanca aplica fuerza continua, no setea velocidad
- **Habilidades de empuje**: Aplican impulso/fuerza, no teleport o velocidad fija
- **Knockback**: Fuerza de retroceso escalada por masa
- **Pelotas elementales lanzadas**: Impulso inicial, luego comportamiento de trayectoria

**Ejemplo conceptual** (futuro):
```gdscript
# MAL (actual): Setear velocidad directamente
player.velocity = input_direction * max_speed

# BIEN (futuro): Aplicar fuerza según input
var force = input_direction * acceleration_force
player.apply_force(force)  # Godot integra con masa automáticamente
```

**Nota**: La transición a este modelo requiere cambios profundos en `Player` y `Projectile`. El MVP actual usa `velocity` directa por simplicidad.

### 7. Integración con Sistema Actual

El sistema de **ElementalShot** y **Projectile** actual es un **prototipo funcional** que será reemplazado gradualmente por el modelo de pelotas-antimateria.

**Path de migración** (no implementado aún):
1. Crear `BallBody` como reemplazo de `Projectile`
2. Implementar resolución de colisiones antimateria en `BallBody`
3. Refactorizar habilidades para spawnnear `BallBody` en lugar de `Projectile`
4. Migrar física de `Player` a modelo basado en fuerzas
5. Deprecar `Projectile` una vez que todas las habilidades usen `BallBody`

**Compatibilidad durante transición**:
- Sistema actual (`Projectile`) coexiste con sistema nuevo (`BallBody`)
- Habilidades pueden elegir cuál usar según complejidad
- `BallBody` puede emular comportamiento de `Projectile` con `RectilinearTrajectory` + masa fija

---

## Arquitectura del Proyecto

### Estructura de Carpetas

```
pelotitas/
├── project.godot
├── README.md
├── icon.svg
├── scenes/
│   ├── boot/
│   │   ├── boot.tscn
│   │   └── boot.gd
│   ├── menus/
│   │   ├── main_menu.tscn
│   │   └── main_menu.gd
│   ├── duel/
│   │   ├── arena_duelo.tscn
│   │   ├── arena_duelo.gd
│   │   └── player_prefab.tscn
│   └── ui/
│       ├── mobile_hud.tscn
│       └── mobile_hud.gd
├── scripts/
│   ├── core/
│   │   ├── game.gd          (Autoload: estado global)
│   │   ├── net.gd           (Autoload: multiplayer)
│   │   └── progression.gd   (Autoload: niveles y afinidad)
│   ├── combat/
│   │   ├── player.gd        (Jugador/pelotita en duelo)
│   │   └── projectile.gd    (Proyectiles base)
│   ├── abilities/
│   │   ├── ability.gd       (Clase base abstracta)
│   │   ├── usable_ability.gd
│   │   ├── passive_ability.gd
│   │   └── loadout.gd       (Contenedor 3+1)
│   ├── modes/
│   │   ├── mode.gd          (Clase base abstracta)
│   │   ├── duelo_por_vida.gd
│   │   └── mode_registry.gd
│   ├── progression/
│   │   └── (futuros: skill tree editor, unlock logic)
│   └── net/
│       └── (futuros: lobby, matchmaking)
├── assets/
│   ├── sprites/
│   ├── audio/
│   └── fonts/
└── docs/
    └── DESIGN.md (este documento)
```

### Autoloads (Singletons)

1. **Game** (`scripts/core/game.gd`)
   - Gestiona estado global (menú, lobby, duelo)
   - Mantiene referencia al modo activo
   - Coordina transiciones de escenas

2. **Net** (`scripts/core/net.gd`)
   - Maneja conexiones multiplayer (ENet)
   - Provee helpers para autoridad de red y RPCs
   - Emite señales de conexión/desconexión

3. **Progression** (`scripts/core/progression.gd`)
   - Sistema de nivel y experiencia
   - Gestiona afinidades elementales secretas
   - Otorga puntos de habilidad en level-ups
   - Maneja aprendizaje de skills

4. **TouchInput** (`scripts/core/touch_input.gd`)
   - Manejo de controles táctiles móviles
   - Joystick virtual con deadzone
   - Emite señales para movimiento y habilidades
   - Fallback a teclado para testing en desktop

### Sistema de Modos

**Clase base**: `Mode` (`scripts/modes/mode.gd`)

Métodos abstractos:
- `on_match_start()`: inicializa el modo
- `check_victory_conditions()`: verifica ganador
- `on_player_death(player)`: maneja muerte
- `get_spawn_positions()`: posiciones de spawn
- `process(delta)`: lógica por frame

**Modo concreto**: `DueloPorVida` (`scripts/modes/duelo_por_vida.gd`)

- Victoria: último jugador vivo
- Spawn: 2 posiciones fijas (izq/der)

**Agregar nuevo modo** (futuro):
1. Crear clase heredando de `Mode`
2. Implementar métodos abstractos
3. Registrar en `ModeRegistry`

### Sistema de Habilidades

**Jerarquía**:
```
Ability (Resource base)
├── UsableAbility (activables)
└── PassiveAbility (efectos permanentes)
```

**Loadout** (`scripts/abilities/loadout.gd`):
- 3 slots para `UsableAbility`
- 1 slot para `PassiveAbility`

**Crear nueva habilidad** (futuro):
1. Heredar de `UsableAbility` o `PassiveAbility`
2. Implementar `execute(caster)` o `apply(player)`
3. Definir cooldown, costo, elemento
4. Agregar a skill tree

#### Habilidades Elementales Básicas

Cada elemento tiene un **disparo básico** que funciona con la misma mecánica:

**Disparos Elementales** (Fuego, Agua, Tierra, Viento):
- Mecánica unificada: proyectil direccional activado con press-hold-drag-release
- Diferenciados por elemento y color visual:
  - **Fuego**: Rojo/naranja (Color(1, 0.2, 0, 1))
  - **Agua**: Azul (Color(0, 0.4, 1, 1))
  - **Tierra**: Marrón (Color(0.6, 0.4, 0.2, 1))
  - **Viento**: Verde claro (Color(0.7, 1, 0.7, 1))
- Al impactar enemigo:
  - Aplica daño según fórmula de stats (Ataque vs Defensa)
  - Produce knockback pequeño alejando a la víctima
  - Trigger `on_hit_enemy` disponible para efectos adicionales
- Propiedades:
  - Velocidad: 400 px/s
  - Duración: 3 segundos
  - Cooldown: 1 segundo
- Visuales placeholder: círculos coloreados hexagonales

**Implementación**: `ElementalShot` hereda de `UsableAbility`, instancia escena `projectile_elemental.tscn`

**Sistema de Triggers**: Todos los disparos elementales pueden sobrescribir triggers como `on_activate`, `on_hit_enemy`, `on_match_start` para agregar efectos especiales (ver sección 9: Sistema de Triggers)

### Combate y Jugadores

**Player** (`scripts/combat/player.gd`):
- Movimiento con joystick virtual (touch) o WASD (desktop fallback)
- **Stats de combate**: Ataque, Defensa, Velocidad
  - Velocidad afecta directamente la velocidad de movimiento
- Vida y daño
- Usa habilidades del loadout (botones táctiles o teclas 1, 2, 3)
- Recibe knockback al ser impactado
- Sincronización de red (solo owner controla movimiento)

**Mobile HUD** (`scenes/ui/mobile_hud.tscn/.gd`):
- **Layout twin-stick-ish bloqueado**:
  - Palanca/joystick virtual táctil (izquierda inferior)
  - 3 botones de habilidades usables, grandes y touch-friendly (derecha inferior)
  - Barra de vida superior
  - Cooldowns visuales (stub - futuro: overlay en botones)
- **Sin botón para pasiva**: la habilidad pasiva es automática, no requiere UI

**Projectile** (`scripts/combat/projectile.gd`):
- Movimiento en línea recta
- Colisión y daño basado en stats del caster (Ataque) y del target (Defensa)
- Aplica knockback direccional al impactar
- Opciones: pierce, lifetime, velocidad
- Los proyectiles portan el stat de Ataque del caster para calcular daño dinámicamente

---

## TODOs Críticos para Gameplay Completo

### Red y Multiplayer
- [x] Implementar MultiplayerSynchronizer en Player
- [x] Sincronizar spawn de proyectiles (via RPC)
- [x] Host/Join por IP con nickname local
- [x] Mostrar IP local del servidor
- [ ] Lobby mejorado con lista de jugadores conectados
- [ ] Manejo robusto de latencia y desconexiones (crítico en mobile)
- [ ] Optimización de ancho de banda para redes móviles
- [ ] NAT traversal / relay server para jugar entre redes diferentes
- [ ] Reconexión automática en desconexiones temporales

### Android-Specific
- [ ] **Testing en dispositivos Android reales** (gama media: Samsung Galaxy A, Xiaomi Redmi)
- [ ] Optimización de rendimiento para Android gama media/baja
- [ ] Configuración de export templates Android (APK + AAB para Play Store)
- [ ] Vibración háptica en habilidades y daño (Android Vibrator API)
- [ ] Ajuste de tamaños de botones según DPI Android
- [ ] Manejo de diferentes aspect ratios Android (18:9, 19:9, 20:9, etc.)
- [ ] Pausa automática al perder foco (llamada entrante, home button)
- [ ] Testing en diferentes versiones Android (7.0 - 14+)
- [ ] Permisos Android: INTERNET, ACCESS_NETWORK_STATE, VIBRATE

### iOS (Futuro)
- [ ] Configuración de export templates iOS (requiere macOS + Xcode)
- [ ] Provisioning profiles y certificados Apple Developer
- [ ] Adaptaciones específicas de iOS (notch, dynamic island, gestures)

### Habilidades
- [ ] Implementar habilidades elementales concretas
  - [ ] Disparo de fuego
  - [ ] Muro de tierra
  - [ ] Invocación de aire
  - [ ] Ola de agua
- [ ] Cooldown visual (UI)
- [ ] Efectos visuales y sonidos

### Progresión
- [ ] UI de skill tree
- [ ] Persistencia de datos (save/load)
- [ ] Balance de experiencia y niveles
- [ ] Definir todas las habilidades y dependencias

### Modos Adicionales
- [ ] Captura la Bandera
- [ ] Destruye la Estructura
- [ ] Team Deathmatch

### UI/UX
- [ ] HUD de vida, cooldowns, puntos
- [ ] Menú de loadout (equipar habilidades)
- [ ] Pantalla de victoria/derrota
- [ ] Lobby con lista de jugadores

### Arte y Audio
- [ ] Sprites de pelotitas elementales
- [ ] Efectos de partículas
- [ ] Música de fondo
- [ ] SFX de habilidades

---

## Convenciones de Código

- **Lenguaje**: GDScript (Godot 4.x)
- **Nombrado**:
  - `snake_case` para variables y funciones
  - `PascalCase` para clases
  - `SCREAMING_SNAKE_CASE` para constantes
- **Comentarios**: usar `##` para doc comments de funciones/clases
- **Señales**: declarar al inicio de la clase con `signal`
- **TODOs**: marcar código incompleto con `# TODO: descripción`

---

## Configuración Android

### project.godot - Settings Clave

- **Orientación**: Landscape (sensor_landscape = 6) - rotación automática izq/der
- **Resolución base**: 1920x1080 (escalado a diferentes dispositivos Android)
- **Stretch mode**: `canvas_items` con aspect `expand`
- **Touch emulation**: Habilitado en editor para testing con mouse en desktop
- **Export template primario**: Android APK/AAB
- **Min SDK**: Android 7.0 (API 24) - compatibilidad amplia
- **Target SDK**: Android 14+ (API 34) - requerido por Google Play

### Configuración de Export Android

Ver `docs/MOBILE_EXPORT.md` para detalles completos.

**Package**: `com.maximoaps.pelotitas`  
**Permisos requeridos**:
- `INTERNET`: Multiplayer online
- `ACCESS_NETWORK_STATE`: Detectar WiFi vs datos móviles
- `VIBRATE`: Feedback háptico (opcional)

**Formato de release**: AAB (Android App Bundle) para Google Play Store

### Controles de Testing Desktop

Para desarrollo en PC/Mac sin touch:
- **Arrow keys / WASD**: Movimiento (fallback automático)
- **1, 2, 3**: Habilidades
- **Mouse click + drag**: Emula joystick virtual

### Testing Local (Sin Red)

Para pruebas sin multiplayer, el juego spawna:
- **Player 1**: Controlable con teclado/touch (azul)
- **Player 2**: Dummy con trayectoria que busca el centro del mapa (rojo/naranja)
  - Aceleración más débil que Player 1
  - Puede recibir daño de proyectiles
  - Participa en colisiones elásticas (puede ser empujado)
  - Recibe daño de paredes si es empujado contra ellas
  - **NO persigue al jugador** - solo se mueve hacia el centro

Este enfoque permite testear física y habilidades sin implementar oponente inteligente completo.

## Notas Finales

Este documento debe **actualizarse** cuando se tomen nuevas decisiones de diseño o se implementen sistemas críticos.

**Prioridad actual (Android-first)**: 
1. **Testing en dispositivo Android real** (Samsung Galaxy A52/A53 o Xiaomi Redmi Note 11 recomendados)
2. Completar red y sincronización multiplayer optimizada para Android (WiFi/4G/5G)
3. Implementar 3-5 habilidades básicas por elemento con feedback visual touch
4. Optimización de rendimiento para Android gama media (target: 60 FPS estable)
5. Vibración háptica en Android para acciones de combate
6. Testing en múltiples aspect ratios Android
