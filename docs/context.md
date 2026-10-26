# Project context

Background for anyone (or any AI assistant) working in this repo. Full sources: `docs/project_manual.pdf` and `docs/gpt6_proposal.pdf`.

## Course

* EE2026 Digital Design, NUS, AY2026/27 Sem 1. The project (I-FDP) is 30% of the course grade.
* Board: Basys3 (Artix-7). Compulsory devices: Basys3 and Pmod OLED (96x64, RGB 5:6:5). Mouse and VGA are optional.
* Everything must run from ONE bitstream. Demonstrating in a separate bitstream is not accepted.
* Must fit the FPGA. Check Project Summary > Utilization > Post-Implementation and integrate early.

## Marks

* GPT-6 proposal: 2% (group), submitted week 9.
* Each member's component: 9% (individual).
* Integration of all components in one bitstream: 9% (group).
* Execution, Q&A, report, peer feedback: 9% + 1% (individual).
* Each member needs a reasonable amount of their own Verilog with little overlap. Python tools do not count as Verilog work.

## Key dates

* Week 13 (from 9 Nov 2026): project assessment, 2 to 5 minute demo plus questions.
* Week 12 / 13: Vivado archive (one per team, max 500 MB), report and peer feedback. Exact deadline is announced on Canvas.

## Report rules

* Sheet A: group theme + one section per member, max 500 words total for a team of 4. Real OLED photos, in colour.
* Section colours: team pastel pink, A pastel red, B pastel blue, C pastel yellow, D pastel green.
* Only claim features that work in the single bitstream. Claiming unimplemented features is penalised.
* Sheet B: course feedback and references. All open-source code and AI use must be referenced and documented, or full penalties apply.
* Bring two colour printed copies to the assessment.

## Theme

Interactive 2x2 Rubik's cube on the Basys3: 3D view on VGA rotated by mouse drag, turns via buttons or mouse, 25-move scramble (no face twice in a row), and an on-FPGA IDA* solver with BRAM pattern tables that plays the solution back move by move. OLED shows mode, status and errors; 7-segment shows move count; LEDs show solve progress.

## Team

| Member | Owns |
| --- | --- |
| Lim Zi Jing | 3D rendering: view ROM (Python-generated), camera, per-pixel sticker fill |
| Advait Bagri | Solver: IDA* core, pattern tables in BRAM, cube_encode, playback |
| Yew Su Yi | Board IO and integration: ticks, buttons, switches, mouse, VGA, OLED, LEDs, 7-seg, game FSM, top |
| Louisa Chung Yu | Cube model: cube engine, 18 move rules, scrambler, move controller, Python table generator and reference solver |

## Design decisions

* One clock domain (100 MHz). Slower rates are 1-cycle enable pulses from `tick_gen`. The OLED gets a real 6.25 MHz clock because `Oled_Display` needs one.
* `cube_engine` is the only module that writes `cube[71:0]`. Everyone else reads it as an input (no `inout`).
* `game_fsm` decides the stage; it never moves the cube, only enables the module that should.
* `move_controller` is the single path for moves (manual, scrambler, solver) into the engine.
* The renderer uses preset camera views from `view_rom`, so the hardware does no trig. It snapshots the visible quads during vblank.
* The solver fixes the DBL corner, so it only needs U, R and F turns. `cube_encode` re-orients the cube first.
* Shared constants and helpers live in `src/pkg/cube_defs.vh`; port lists live in `docs/module_ports.txt`.
