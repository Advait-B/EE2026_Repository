"""Generate the test vectors for tests/tb_solver_bench.v (task 5.7).

Builds 100 test cubes, solves each with the Python IDA* reference in
solver.py, and writes three readmemh files into tests/:

    solver_bench_cubes.mem    72-bit cube, sticker s at cube[s*3 +: 3]
    solver_bench_plans.mem    55-bit plan, move k at plan[k*5 +: 5], unused = 31
    solver_bench_lengths.mem  solution length

Case mix (fixed seeds, so the files are reproducible):
    1   solved cube
    18  every single move, including D/L/B (exercises the DBL recolour)
    21  short scrambles, 2-6 moves
    40  25-move scrambles, same rule as the scrambler
    10  cubes exactly 10 moves from solved
    10  cubes exactly 11 moves from solved (the hardest 2x2 positions)

Run from the repository root: python3 Python/gen_solver_bench.py
"""

import random
import time
from array import array
from pathlib import Path

import solver as ref
from generate_tables import (N_ORIENTATION_COORDS, N_PERMUTATION_COORDS,
                             orientation_successors, permutation_successors)

OUT_DIR = Path(__file__).resolve().parent.parent / "tests"
MV_NONE = 31


def cube_hex(state):
    """Pack a 24-colour state into the 72-bit cube bus, as 18 hex digits."""
    return f"{sum(col << (3 * s) for s, col in enumerate(state)):018x}"


def plan_hex(moves):
    """Pack a move list into the 55-bit plan bus, as 14 hex digits."""
    slots = moves + [MV_NONE] * (ref.MAX_DEPTH - len(moves))
    return f"{sum(m << (5 * k) for k, m in enumerate(slots)):014x}"


def inverse(m):
    """X <-> X', X2 stays X2."""
    return m - m % 3 + (1, 0, 2)[m % 3]


def far_cubes(depths, count, seed):
    """Return `count` cubes at each exact distance in `depths`.

    Breadth-first search over every position reachable with U, R, F
    (the DBL corner stays fixed), indexed by the hardware coordinates,
    then walk back from random positions at the wanted distance to
    recover a scramble that reaches them.
    """
    ori_mv = [orientation_successors(o)[:9] for o in range(N_ORIENTATION_COORDS)]
    perm_mv = [permutation_successors(p)[:9] for p in range(N_PERMUTATION_COORDS)]

    def neighbours(idx):
        pm, om = perm_mv[idx // N_ORIENTATION_COORDS], ori_mv[idx % N_ORIENTATION_COORDS]
        return [pm[m] * N_ORIENTATION_COORDS + om[m] for m in range(9)]

    dist = bytearray([255]) * (N_PERMUTATION_COORDS * N_ORIENTATION_COORDS)
    dist[0] = 0  # solved is coordinate (0, 0)
    frontier, levels, d = array("i", [0]), {}, 0
    while frontier:
        levels[d] = frontier
        nxt = array("i")
        for idx in frontier:
            for child in neighbours(idx):
                if dist[child] == 255:
                    dist[child] = d + 1
                    nxt.append(child)
        frontier = nxt
        d += 1

    rng = random.Random(seed)
    out = []
    for want in depths:
        for idx in rng.sample(list(levels[want]), count):
            # walk to solved, always to a neighbour one move closer
            path = []
            while dist[idx]:
                m = next(m for m, c in enumerate(neighbours(idx)) if dist[c] == dist[idx] - 1)
                path.append(m)
                idx = neighbours(idx)[m]
            # the cube is the inverse of that path applied to solved
            state = ref.SOLVED
            for m in reversed(path):
                state = ref.apply_move(state, inverse(m))
            out.append(state)
    return out


def main():
    cases = [("solved", ref.SOLVED)]
    for m in range(18):
        cases.append((f"1 move {ref.move_name(m)}", ref.apply_move(ref.SOLVED, m)))
    rng = random.Random(2026)
    for i in range(21):
        n = 2 + i % 5
        cases.append((f"{n}-move scramble", ref.scramble(n, seed=rng.randrange(1 << 30))[0]))
    for i in range(40):
        cases.append(("25-move scramble", ref.scramble(25, seed=1000 + i)[0]))
    far = far_cubes((10, 11), 10, seed=57)
    cases += [("distance 10", s) for s in far[:10]]
    cases += [("distance 11", s) for s in far[10:]]
    assert len(cases) == 100

    cubes, plans, lengths = [], [], []
    for k, (label, state) in enumerate(cases):
        t0 = time.time()
        sol = ref.solve(state)
        check = state
        for m in sol:
            check = ref.apply_move(check, m)
        assert ref.is_solved(check), label
        if label.startswith("distance"):
            assert len(sol) == int(label.split()[1]), label
        cubes.append(cube_hex(state))
        plans.append(plan_hex(sol))
        lengths.append(f"{len(sol):x}")
        print(f"{k:3} {label:18} {len(sol):2} moves  {time.time() - t0:5.2f} s  "
              f"{' '.join(map(ref.move_name, sol))}")

    for name, rows in (("cubes", cubes), ("plans", plans), ("lengths", lengths)):
        (OUT_DIR / f"solver_bench_{name}.mem").write_text("\n".join(rows) + "\n")


if __name__ == "__main__":
    main()
