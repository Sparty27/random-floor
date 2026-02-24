# Random Floor

Roblox гра типу "Last One Standing". Гравці стоять на арені з плиток, які поступово зникають. Останній гравець, що залишився на ногах — перемагає.

## Структура проєкту

```
src/
├── ServerScriptService/          -- Серверна логіка
│   ├── GameManager.server.luau   -- Головний цикл гри (лобі → раунд → кінець)
│   ├── PlayerManager.luau        -- Спавн, елімінація, спостереження
│   ├── TileManager.luau          -- Генерація арени, видалення плиток
│   ├── LeaderboardManager.luau   -- DataStore перемог, топ-20
│   ├── LeaderboardUpdater.server.luau -- Оновлення фізичного лідерборду
│   ├── PlayerEliminated.rbxm     -- BindableEvent: сигнал елімінації
│   └── RefreshLeaderboard.rbxm   -- BindableEvent: оновлення лідерборду
│
├── StarterGui/
│   ├── GameGui.rbxm              -- UI: TopBar (InfoText) + WinScreen
│   ├── GuiController.client.luau -- Оновлення HUD та екран переможця
│   └── SpectatorController.client.luau -- UI та камера для вибулих гравців
│
├── ReplicatedStorage/
│   └── GameEvents/
│       ├── UpdateGui.rbxm        -- RemoteEvent: оновлення тексту HUD
│       └── ShowWinner.rbxm       -- RemoteEvent: показ переможця
│
└── Workspace/
    ├── TilesFolder/              -- Динамічно генерована арена (плитки)
    ├── ObsSpawn.rbxm             -- Точка спавну для лобі/спостереження
    ├── LeaderboardFolder/        -- Фізичний лідерборд у світі
    └── LeaderboardScreen.rbxm    -- SurfaceGui лідерборду
```

## Ігровий цикл

```
LOBBY (10с) → GENERATING → PLAYING → ENDING → LOBBY
```

### 1. LOBBY
- Відлік 10 секунд до старту
- Гравці знаходяться біля ObsSpawn

### 2. GENERATING
- Генерація сітки плиток (розмір залежить від кількості гравців)
- Встановлення висоти арени для детекції падіння

### 3. PLAYING
- Гравці телепортуються на випадкові **стабільні** плитки
- 3 секунди затримки перед початком видалення плиток
- Кожні 3 секунди видаляються 10 випадкових плиток
- `watchPlayer` моніторить Y-координату кожного гравця

### 4. ENDING
Настає коли:
- Залишився 1 гравець → **Winner** (перемога записується в DataStore)
- Залишилось 0 гравців → **Draw** (всі впали)
- Плитки закінчились, але 2+ гравці живі → **Draw** (вижили)

## Модулі

### GameManager.server.luau
Головний оркестратор. Керує станами гри, ігровим циклом, з'єднує всі модулі.

**Налаштування:**
| Константа | Значення | Опис |
|---|---|---|
| `LOBBY_WAIT` | 10 | Час очікування в лобі (сек) |
| `REMOVE_INTERVAL` | 3 | Інтервал між видаленнями плиток (сек) |
| `REMOVE_COUNT` | 10 | Кількість плиток, що видаляються за раз |

### PlayerManager.luau
Управління гравцями: спавн, елімінація, спостереження, від'єднання.

**Ключові функції:**
- `spawnOnArena(player)` — телепортує на випадкову стабільну плитку
- `watchPlayer(player)` — моніторить падіння (Y < arenaHeight - 10)
- `sendToObservation(player)` — елімінація + телепорт в observation room
- `sendAllToLobby()` — повертає всіх в лобі після раунду

**Захисти:**
- Таймаут 15с на очікування спавну в `watchPlayer`
- `Players.PlayerRemoving` обробляє від'єднання під час раунду
- `playerEliminated:Fire()` викликається завжди, навіть якщо персонаж знищений

### TileManager.luau
Генерація та управління ареною з плиток.

**Динамічний розмір арени:**
| Гравці | Сітка | Плиток |
|---|---|---|
| 1–4 | 8x8 | 64 |
| 5–10 | 10x10 | 100 |
| 11–20 | 14x14 | 196 |
| 21+ | 18x18 | 324 |

**Типи плиток:**
- `Tile_Normal` (80%) — сіра, стабільна
- `Tile_Unstable` (20%) — жовта, руйнується при доторканні (тремтіння → червоний → зникнення)

**Налаштування:**
| Константа | Значення | Опис |
|---|---|---|
| `TILE_SIZE` | 6 | Розмір плитки |
| `TILE_GAP` | 1 | Проміжок між плитками |
| `ARENA_HEIGHT` | 20 | Висота арени (Y) |

### LeaderboardManager.luau
Зберігає перемоги в `OrderedDataStore("PlayerWins_v1")`.

- `addWin(player)` — інкрементує лічильник перемог
- `getTopPlayers()` — повертає топ-20 гравців

### GuiController.client.luau
Клієнтський HUD. Отримує повідомлення через `UpdateGui` RemoteEvent та показує екран переможця через `ShowWinner`.

### SpectatorController.client.luau
UI для вибулих гравців. Показує статус "You were eliminated" та кнопку перемикання між:
- **Walk Around** — стандартна камера, гравець ходить в observation room
- **Watch Arena** — фіксована камера з видом зверху на арену

## Логування

Всі модулі використовують структуровані логи з префіксами:

```
[GameManager]  — стани гри, раунди, переможці
[PlayerManager] — спавн, падіння, від'єднання
[TileManager]  — генерація, видалення плиток
[Leaderboard]  — DataStore операції
[GuiController] — клієнтський GUI
[Spectator]    — режим спостереження
```

**Приклад Output:**
```
[GameManager] === STATE: LOBBY === Players online: 2
[GameManager] === STATE: GENERATING === Players: 2
[TileManager] Generated 64 tiles (8x8) | 13 unstable
[PlayerManager] Player1 placed on tile: Tile_Normal at 7, 20, 14
[PlayerManager] Player1 fell! Y = 4.1
[GameManager] === STATE: ENDING (via elimination) ===
[GameManager] Winner: Player2
```

Помилки логуються через `warn()` з тим самим префіксом — легко фільтрувати в Output.

## Розробка

### Rojo

Збірка:
```bash
rojo build -o "random-floor.rbxl"
```

Синхронізація з Roblox Studio:
```bash
rojo serve
```

### Лінтер

Проєкт використовує [Selene](https://kampfkarren.github.io/selene/) для лінтування Luau коду:
```bash
selene src/
```
