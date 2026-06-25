# TAKO — Math RPG

---

## Project Overview

TAKO is a mobile-first math RPG built in Godot 4 (GDScript). Players navigate dungeon levels, encounter enemies, and defeat them by answering AI-generated math questions. Every enemy encounter triggers a battle scene: the on-device Gemini Nano model produces a question matched to that enemy's skill domain, the player types an answer, and the AI diagnoses mistakes and returns targeted feedback — entirely offline, no internet required.

The core loop mirrors a classic dungeon crawler — players must defeat every enemy in a level before the exit unlocks, then progress to the next level. Math replaces combat: correct answers defeat enemies, wrong answers earn an explanation and another attempt.

---

## Features

- **On-device AI questions** — Gemini Nano (built into Android) generates a unique math question each battle, scoped to the enemy's assigned skill domain (arithmetic, fractions, algebra, geometry, word problems, or statistics)
- **AI misconception feedback** — wrong answers trigger a short, encouraging explanation that nudges the player toward correct thinking without giving away the answer
- **Fully offline** — Gemini Nano runs on-device; no internet connection required to play
- **Dungeon RPG format** — multiple levels with enemy encounters; all enemies must be defeated to unlock the exit
- **Character selection** — players choose their character before starting
- **Dialogue system** — NPCs and enemies deliver narrative dialogue and hints
- **Hint system** — players can request a hint mid-battle surfaced from the AI-generated question
- **Progress persistence** — save data tracks defeated enemies, completed levels, triggered dialogues, and last position
- **Achievements** — milestone unlocks for completing each level
- **Settings menu** — music/SFX volume sliders, fullscreen toggle, clear save data
- **Touch controls** — virtual joystick and interact button auto-shown on Android; WASD + keyboard on desktop

---

## Setup Instructions

### Prerequisites

- [Godot 4.6](https://godotengine.org/download)
- Android SDK + export templates
- An Android device running Android 10+ with [Google Play Services for AR](https://play.google.com/store/apps/details?id=com.google.ar.core) (Gemini Nano ships with supported Pixel and Samsung devices; availability depends on device)

### Running on desktop (development)

Gemini Nano is Android-only. For desktop testing, the game falls back to [Ollama](https://ollama.com):

1. Clone the repository
   ```bash
   git clone https://github.com/russellmagdaong/tako-game.git
   ```
2. Install and start Ollama
   ```bash
   ollama serve
   ollama pull gemma3
   ```
3. Open `project.godot` in Godot 4.6 and press **Run (F5)**

### Android build (production)

1. In Godot: **Project → Export → Android**
2. Set your Android SDK path and debug keystore
3. Click **Export Project**
4. Install the APK on a supported Android device — Gemini Nano activates automatically; the virtual joystick appears on-screen

### Clearing save data

Open the in-game menu → **Settings** → **Clear Save Data** (tap twice to confirm).

---

## Technologies Used

| Layer | Technology | Purpose |
|---|---|---|
| **Game engine** | Godot 4.6 (GDScript) | Rendering, scenes, animation, Android export |
| **On-device AI** | Gemini Nano (Android built-in) | Question generation and misconception feedback — runs fully offline on-device |
| **Dev AI fallback** | Ollama (local, desktop only) | Stands in for Gemini Nano during desktop development |
| **Math correctness** | Deterministic GDScript logic | Answer validation — AI is never trusted to grade math answers |
| **Networking** | Godot `HTTPRequest` node | Calls Ollama during dev; Supabase REST API for cloud sync |
| **Cloud backend** *(planned)* | Supabase (Postgres + Auth) | Login, cross-device progress sync, mastery tracking |
| **Local storage** | Godot `FileAccess` (JSON) | Offline-first save data |
| **Platform target** | Android (Godot native export) | Primary deployment target |

---

## Team Members and Rules

**Team Name:** Billiard Boys

| Name | Role |
|---|---|
| Balajadia, Vin Tristan E. | Database Administrator |
| Gilo, Eric Jonhson H. | AI.... basta AI |
| Guillermo, Christian P. | UI/UX Designer |
| Magdaong, Russell D. | Game Developer |

---

## Project Structure

```
TAKO/
├── scenes/
│   ├── core/          # GameManager, SceneManager, MainMenu, CharacterSelect
│   ├── gameplay/      # BattleScene, DialogueTrigger, Interactable
│   ├── levels/        # Billiards, Level0–Level31 dungeon scenes
│   └── ui/            # DialogueBox, PauseMenu, HintsPopup, HintButton
├── scripts/
│   ├── core/          # Autoloads: ApiClient, GameManager, SceneManager,
│   │                  #   PlayerDataManager, DialogueManager, AudioManager, Globals
│   ├── gameplay/      # BattleScene, Characters, Levels, UI
│   │   └── characters/# Player, Enemy, Input, Movement, Animation, States
│   ├── ui/            # VirtualControls (Android touch joystick)
│   └── utilities/     # StateMachine, State
├── resources/         # Themes, fonts, tilesets, styleboxes
├── assets/            # Audio, sprites (characters, enemies, backgrounds, UI)
└── export_presets.cfg # Android + Web export configurations
```

---

## Battle Flow

```
Overworld → walk into enemy → BattleScene loads
  │
  ├─ Gemini Nano generates question for enemy's math SkillType
  ├─ Question shown in Problem Panel
  │
  ├─ Player types answer → Submit or Enter
  │     ├─ Correct   → "Correct!" → 2 s delay → enemy defeated, return to level
  │     └─ Incorrect → Gemini Nano generates feedback → player retries (unlimited)
  │
  └─ All enemies defeated → exit trigger unlocks → next level
```

---

## Math Skill Domains

| SkillType | Coverage |
|---|---|
| `BasicArithmetic` | Addition, subtraction, multiplication, division |
| `Fractions` | Simplifying, comparing, operating on fractions |
| `Algebra` | Solving for unknowns, expressions, linear equations |
| `Geometry` | Area, perimeter, angles, coordinate geometry |
| `WordProblems` | Applied multi-step reasoning |
| `Statistics` | Mean, median, mode, basic probability |
