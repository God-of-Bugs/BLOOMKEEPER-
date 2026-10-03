# BLOOMKEEPER — PROJECT LOG

## Project Identity
- **Name**: BLOOMKEEPER
- **Engine**: Godot Engine 4.7.1
- **Genre**: 3D Low-Poly Pacifist Exploration
- **Theme**: PACIFIST
- **Target Platform**: Web (HTML5) / Windows
- **Target Playtime**: 7–10 minutes

## Original Development Roadmap (pre-forest redesign; historical)
The checklist below records the original courtyard/action build. Its chase, combat-damage, pulse-pacification, and end-to-end verification entries describe that earlier design and should not be read as verification of the current forest redesign.
- [x] **TODO 1: Project Foundation**: Godot 4.7.1 setup, renderer GL compatibility, canvas_items stretch, git setup.

## Forest Redesign (current)
- [x] Expanded arena to one 64 × 64 forest clearing with a procedural tree ring, inner groves, ground cover, mushrooms and moving fireflies.
- [x] Added original primitive-mesh low-poly adventurer and bark/root Prowler models, with walk cycles and a longer third-person camera.
- [x] Replaced chase and contact damage with five independently roaming Prowlers, each assigned a distinct local territory.
- [x] Added hold-F close-range shadow absorption, HUD progress, safe nonlethal calming pulses, and individual clearing/light restoration on each Bloom.
- [x] Deferred global environment/canopy brightening until the fifth Prowler blooms.
- [x] No external art assets were introduced; inventory and licensing are documented in `docs/ASSET_LICENSES.md`.
- [ ] Full close-range absorption progression and fifth-bloom victory require a dedicated live playtest before any commit/push or completion claim.
- [ ] Diagnose the installed Ziva GDExtension's web export library issue and complete a browser test; no unsupported-extension exclusion has been made.

- [x] **TODO 2: 3D World Foundation**: Arena floor, 4 boundary walls, DirectionalLight3D, WorldEnvironment fog/lighting.
- [x] **TODO 3: Player Movement & Camera**: CharacterBody3D, WASD movement, gravity, rotation, camera pivot, mouse-look.
- [x] **TODO 4: Dash Ability**: Shift dash, displacement (~1.8m), duration (0.22s), 1.2s cooldown, wall collision, grounding.
- [x] **TODO 5: Prowler Creature & Collision**: Prowler scene, capsule mesh/collision shape, layers/masks, player-creature collision.
- [x] **TODO 6: Prowler Chase AI & State Machine**: AGGRESSIVE state, chase movement towards player, stopping distance (1.05m), CALMING/PACIFIED states.
- [x] **TODO 7: Bloom Pulse Mechanic**: E / RMB tap (3m) & charged pulse (7.5m) wave expansion, creature pacification broadcast.
- [x] **TODO 8: Bloom Energy System**: Energy pool (100.0), pulse cost scaling (20.0 - 45.0), passive regeneration (+12.0/s).
- [x] **TODO 9: Creature -> Shrine Transformation**: Visual material transformation (light green/gold glow), OmniLight3D illumination, group re-assignment.
- [x] **TODO 10: Player Health & Failure System**: 3 HP health, creature contact damage, 1.5s invulnerability i-frames, defeat signal.
- [x] **TODO 11: Area 1 Corrupted Courtyard Setup**: GameManager 5 Prowler spawns, victory condition, game over, R key restart flow.
- [x] **TODO 12: Pause & Resume System**: ESC key toggle, Pause Menu overlay with Resume & Restart options, PROCESS_MODE_ALWAYS.
- [x] **TODO 13: Title Screen & Onboarding Tutorial**: Title overlay with game branding, tagline, objective & controls guide, Space/Click to Start prompt.
- [x] **TODO 14: HUD & Status UI Polish**: Spirits pacified counter, Health hearts, Energy progress bar, Victory & Game Over overlays.
- [x] **TODO 15: Environmental & Visual Polish**: Corrupted vs Restored visual transformation, dynamic lighting/fog environment shifts.
- [x] **TODO 16: Audio Feedback System**: AudioManager with procedural 44.1kHz audio chimes for pulse, pacify, damage, victory, defeat.
- [x] **TODO 17: Input & Gameplay Focus Safety**: Mouse capture mode toggles, UI focus protection, key/mouse event safety.
- [x] **TODO 18: Web/HTML5 Export Configuration**: export_presets.cfg Web configuration, canvas resize policy.
- [x] **TODO 19: Credits & AI Disclosure Documentation**: CREDITS.md and AI_DISCLOSURE.md documentation.
- [x] **TODO 20: Asset Licensing & Documentation Audit**: docs/ASSET_LICENSES.md, README.md, PROJECT_LOG.md updates.
- [x] **TODO 21: Full Automated & Edge-Case Physics Testing**: Headless test verification suite covering movement, collision, pulse, energy, defeat, victory, pause, restart.
- [x] **TODO 22 (original build only)**: The former courtyard version was playtested and committed at the original checkpoint; this does not verify the current forest redesign. Current redesign verification remains tracked in the section above.
