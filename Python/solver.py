"""Python IDA* reference for the 2x2 solver (task 5.1).

Conventions follow src/pkg/cube_defs.vh. A cube state is a tuple of 24
colours, where index s = face*4 + tile matches cube[s*3 +: 3].

Mirrors the hardware: the same recolour, the same coordinates
(generate_tables.py, as in cube_encode.v), the same distance tables
(orientation.mem, permutation.mem, as in pattern_rom.v) and the same move
order and pruning (solver_search.v, move_prune.v), so it finds the same plan.

Run: python3 solver.py
"""

import random
import time
from pathlib import Path

from generate_tables import encode_orientation, encode_permutation

WHITE, RED, GREEN, YELLOW, ORANGE, BLUE = range(1, 7)

# Every tile on face f has colour f+1 (SOLVED_CUBE)
SOLVED = tuple(f + 1 for f in range(6) for _ in range(4))

# corner_sticker() rows in Kociemba order URF UFL ULB UBR DFR DLF DBL DRB.
# U/D sticker first, then the other two clockwise around the corner.
CORNERS = [(2, 4, 9), (3, 8, 17), (0, 16, 21), (1, 20, 5),
           (13, 10, 7), (12, 18, 11), (15, 22, 19), (14, 6, 23)]
DBL = 6

MAX_DEPTH = 11  # longest 2x2 solution, as in solver_search.v


def corner_with(s):
    """Return the corner that holds sticker s."""
    return next(c for c in CORNERS if s in c)


def quarter_turn(face):
    """Build the sticker permutation for a clockwise turn of one face.

    Tile i moves to tile i+1 on the face, and the corner holding tile i
    moves to the corner holding tile i+1, keeping its sticker order.
    The result src satisfies new[dst] = old[src[dst]].
    """
    src = list(range(24))
    for i in range(4):
        a, b = face*4 + i, face*4 + (i + 1) % 4
        ca, cb = corner_with(a), corner_with(b)
        p, q = ca.index(a), cb.index(b)
        for k in range(3):
            src[cb[(q + k) % 3]] = ca[(p + k) % 3]
    return src


def compose(p1, p2):
    """Return the permutation for p1 followed by p2."""
    return [p1[i] for i in p2]


# MOVES[code] with code = face*3 + type (0 = X, 1 = X', 2 = X2)
MOVES = []
for face in range(6):
    cw = quarter_turn(face)
    half = compose(cw, cw)
    MOVES += [cw, compose(half, cw), half]

# The solver only turns U, R and F, so the DBL corner never moves
SOLVER_MOVES = range(9)


def apply_move(state, m):
    return tuple(state[i] for i in MOVES[m])


def same_face(a, b):
    return a // 3 == b // 3


def move_name(m):
    return "URFDLB"[m // 3] + ["", "'", "2"][m % 3]


def is_solved(state):
    """Return True if every face is one colour."""
    return all(len(set(state[f*4:f*4 + 4])) == 1 for f in range(6))


# (piece, twist) for every legal colour reading of a corner slot. The twist
# is the position of the corner's U/D colour in the slot.
CORNER_READINGS = {}
for piece, c in enumerate(CORNERS):
    home = tuple(SOLVED[s] for s in c)
    for twist in range(3):
        CORNER_READINGS[home[-twist:] + home[:-twist]] = (piece, twist)


def read_corner(state, slot):
    """Return (piece, twist) for the corner in a slot, or (None, None)."""
    cols = tuple(state[s] for s in CORNERS[slot])
    return CORNER_READINGS.get(cols, (None, None))


def check(state):
    """Run the hardware error checks. Return None if the cube is valid."""
    if any(state.count(c) != 4 for c in range(1, 7)):
        return "colour count"
    pieces, twists = zip(*(read_corner(state, s) for s in range(8)))
    if None in pieces or len(set(pieces)) != 8:
        return "bad corner"
    if sum(twists) % 3:
        return "twist"
    return None


def opposite(col):
    """Return the opposite colour: white-yellow, red-orange, green-blue."""
    return col + 3 if col <= 3 else col - 3


def recolour(state):
    """Recolour the cube so the corner in the DBL slot counts as solved.

    That corner's colours define the D, B and L faces, so U, R and F turns
    alone can solve the cube.
    """
    d_col, b_col, l_col = (state[s] for s in CORNERS[DBL])
    lut = {d_col: YELLOW, b_col: BLUE, l_col: ORANGE,
           opposite(d_col): WHITE, opposite(b_col): GREEN, opposite(l_col): RED}
    return tuple(lut[c] for c in state)


def load_table(name):
    """Read one readmemh distance table, one hex digit per line."""
    path = Path(__file__).resolve().parent / name
    return [int(line, 16) for line in path.read_text().split()]


ORI_DIST = load_table("orientation.mem")
PERM_DIST = load_table("permutation.mem")


def coords(state):
    """Return (ori_addr, perm_addr), as cube_encode.v computes them."""
    pieces, twists = zip(*(read_corner(state, s) for s in range(8)))
    return encode_orientation(twists), encode_permutation(pieces)


def h(state):
    """Return the pattern table heuristic, as pattern_rom.v looks it up.

    Neither table overestimates, so their maximum is still admissible.
    """
    ori, perm = coords(state)
    return max(ORI_DIST[ori], PERM_DIST[perm])


def search(state, plan, bound):
    """Depth-first search for a plan of at most `bound` moves.

    Tries moves in code order, skips a turn of the face just turned (5.4),
    and cuts off any child whose depth plus h is over the bound.
    """
    if state == SOLVED:
        return plan
    for m in SOLVER_MOVES:
        if plan and same_face(m, plan[-1]):
            continue
        child = apply_move(state, m)
        if len(plan) + 1 + h(child) <= bound:
            found = search(child, plan + [m], bound)
            if found is not None:
                return found
    return None


def solve(state):
    """Return the shortest solution as a list of move codes.

    IDA*: depth-first searches with a growing bound, so the first plan
    found is a shortest one.
    """
    err = check(state)
    if err:
        raise ValueError(err)
    start = recolour(state)
    for bound in range(MAX_DEPTH + 1):
        plan = search(start, [], bound)
        if plan is not None:
            return plan
    raise ValueError(f"no solution within {MAX_DEPTH} moves")


def scramble(n=25, seed=None):
    """Make n random turns, never the same face twice in a row."""
    rng, state, moves = random.Random(seed), SOLVED, []
    while len(moves) < n:
        m = rng.randrange(18)
        if not moves or not same_face(m, moves[-1]):
            moves.append(m)
            state = apply_move(state, m)
    return state, moves


if __name__ == "__main__":
    for seed in range(5):
        cube, scr = scramble(seed=seed)
        t0 = time.time()
        sol = solve(cube)
        for m in sol:
            cube = apply_move(cube, m)
        assert is_solved(cube)
        print(f"scramble: {' '.join(map(move_name, scr))}")
        print(f"solution: {' '.join(map(move_name, sol))} "
              f"({len(sol)} moves, {time.time() - t0:.2f} s)")
