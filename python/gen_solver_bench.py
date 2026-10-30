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

Run from the repository root: python3 python/gen_solver_bench.py
"""

import os
import random
import sys
import time
from array import array

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import solver as ref  # noqa: E402

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tests")
MV_NONE = 31
MAX_DEPTH = 11
N_ORI = 729


def cube_hex(state):
    """Pack a 24-colour state into the 72-bit cube bus, as 18 hex digits."""
    v = 0
    for s, col in enumerate(state):
        v |= col << (3 * s)
    return f"{v:018x}"


def plan_hex(moves):
    """Pack a move list into the 55-bit plan bus, as 14 hex digits."""
    v = 0
    for k in range(MAX_DEPTH):
        v |= (moves[k] if k < len(moves) else MV_NONE) << (5 * k)
    return f"{v:014x}"


def coord_tables():
    """Return per-move transition tables for the perm and ori coordinates."""
    tables = []
    for coord, size in ((ref.perm_index, 5040), (ref.ori_index, N_ORI)):
        rep = {coord(ref.SOLVED): ref.SOLVED}
        todo = [ref.SOLVED]
        while todo:
            state = todo.pop()
            for m in ref.SOLVER_MOVES:
                child = ref.apply_move(state, m)
                if coord(child) not in rep:
                    rep[coord(child)] = child
                    todo.append(child)
        assert len(rep) == size
        tables.append([[coord(ref.apply_move(rep[c], m)) for m in ref.SOLVER_MOVES]
                       for c in range(size)])
    return tables


def far_cubes(depths, count, seed):
    """Return `count` cubes at each exact distance in `depths`.

    Breadth-first search over every position reachable with U, R, F
    (the DBL corner stays fixed), then walk back from random positions at
    the wanted distance to recover a scramble that reaches them.
    """
    perm_mv, ori_mv = coord_tables()
    size = 5040 * N_ORI
    dist = bytearray([255]) * size
    start = ref.perm_index(ref.SOLVED) * N_ORI + ref.ori_index(ref.SOLVED)
    dist[start] = 0
    frontier = array("i", [start])
    d = 0
    while frontier:
        nxt = array("i")
        for idx in frontier:
            pm, om = perm_mv[idx // N_ORI], ori_mv[idx % N_ORI]
            for m in range(9):
                child = pm[m] * N_ORI + om[m]
                if dist[child] == 255:
                    dist[child] = d + 1
                    nxt.append(child)
        frontier = nxt
        d += 1

    rng = random.Random(seed)
    out = []
    for want in depths:
        pool = [i for i in range(size) if dist[i] == want]
        for idx in rng.sample(pool, count):
            # walk to solved, always to a neighbour one move closer
            path = []
            while dist[idx] != 0:
                for m in range(9):
                    child = perm_mv[idx // N_ORI][m] * N_ORI + ori_mv[idx % N_ORI][m]
                    if dist[child] == dist[idx] - 1:
                        path.append(m)
                        idx = child
                        break
            # the cube is the inverse of that path applied to solved
            state = ref.SOLVED
            for m in reversed(path):
                state = ref.apply_move(state, m - (m % 3) + (1, 0, 2)[m % 3])
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
        sol, _ = ref.solve(state)
        check = state
        for m in sol:
            check = ref.apply_move(check, m)
        assert ref.is_solved(check), label
        assert len(sol) <= MAX_DEPTH, label
        cubes.append(cube_hex(state))
        plans.append(plan_hex(sol))
        lengths.append(f"{len(sol):x}")
        print(f"{k:3} {label:18} {len(sol):2} moves  {time.time() - t0:5.2f} s  "
              f"{' '.join(map(ref.move_name, sol))}")

    for name, rows in (("cubes", cubes), ("plans", plans), ("lengths", lengths)):
        with open(os.path.join(OUT_DIR, f"solver_bench_{name}.mem"), "w") as f:
            f.write("\n".join(rows) + "\n")


if __name__ == "__main__":
    main()
