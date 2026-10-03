# BLOOMKEEPER

> *"The only weapon is light. The only victory is peace."*

A stylized 3D low-poly pacifist exploration game built in Godot 4 for the **Godot India Community Mini Jam 2026**.

---

## 🌟 Game Overview

You are a light-bearer lost in a dim forest. Five bark-bound Prowlers wander their own small territories. They do not hunt or hurt you: approach one and hold **F** to draw out the corruption and help it Bloom. Each Bloom restores a small clearing around that Prowler. Only when all five have bloomed does warm light return across the entire forest.

The optional **Bloom Pulse** (E or right mouse) sends out a calming wave and can soften a nearby Prowler's resistance, but it cannot complete a Bloom on its own. This is a pacifist restoration journey, not a combat arena.

---

## 🎮 Controls

- **WASD**: Move
- **Mouse**: Look around
- **F (hold within about 3 m of a Prowler)**: Absorb its shadow and Bloom it (about 2 seconds)
- **E / Right Mouse Button**: Optional Bloom Pulse (tap or hold to expand to 7.5m)
- **Shift**: Dash
- **ESC**: Pause Game / Resume
- **R**: Restart after Victory or Game Over. Prowlers no longer attack, so the legacy health/game-over system is not part of the intended play loop.

---

## 🍃 Core Gameplay Loop

1. **Explore** the single, larger forest arena and locate five wandering Prowlers.
2. **Approach** an unbloomed Prowler; hold **F** within about 3 m to absorb its shadow. Prowlers roam but never attack.
3. **Restore a clearing** around each Prowler when it Blooms. The rest of the forest remains dim while any Prowler remains.
4. **Restore the forest**: Bloom all five Prowlers to trigger the global lighting and canopy transformation and win.
5. Use **Bloom Pulse** as optional, nonlethal aid; pulses calm and partially soften nearby Prowlers, but do not replace the close-range absorption.

---

## 🛠 Tech Stack & Build

- **Engine**: Godot Engine 4.7.1
- **Renderer**: GL Compatibility (Optimized for Web/HTML5 browser play)
- **Platform**: Web (HTML5) & Desktop Windows

---

## 📜 Credits & License

Created by **Mayank Kumar (God-of-Bugs)** with assistant tools for Godot India Community Mini Jam 2026.
See [CREDITS.md](CREDITS.md), [AI_DISCLOSURE.md](AI_DISCLOSURE.md), and [docs/ASSET_LICENSES.md](docs/ASSET_LICENSES.md) for full licensing details.
