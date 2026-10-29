"""Python IDA* reference for the 2x2 solver (task 5.1).

Conventions follow src/pkg/cube_defs.vh. A cube state is a tuple of 24
colours, where index s = face*4 + tile matches cube[s*3 +: 3].

Run: python3 solver.py
"""

import math
import random
import time
from collections import deque

U, R, F, D, L, B = range(6)
WHITE, RED, GREEN, YELLOW, ORANGE, BLUE = range(1, 7)

# Every tile on face f has colour f+1 (SOLVED_CUBE)
SOLVED = tuple(f + 1 for f in range(6) for _ in range(4))

# corner_sticker() rows in Kociemba order URF UFL ULB UBR DFR DLF DBL DRB.
# U/D sticker first, then the other two clockwise around the corner.
CORNERS = [(2, 4, 9), (3, 8, 17), (0, 16, 21), (1, 20, 5),
           (13, 10, 7), (12, 18, 11), (15, 22, 19), (14, 6, 23)]
DBL = 6


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


# Each corner's colours in the solved cube
HOME = [tuple(SOLVED[s] for s in c) for c in CORNERS]


def read_corner(state, slot):
    """Return (piece, twist) for the corner in a slot, or (None, None).

    The twist is the position of the corner's U/D colour in the slot.
    """
    cols = tuple(state[s] for s in CORNERS[slot])
    for piece, home in enumerate(HOME):
        for twist in range(3):
            if cols[twist:] + cols[:twist] == home:
                return piece, twist
    return None, None


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


def perm_index(state):
    """Return 0..5039, the Lehmer code of the 7 corners other than DBL."""
    perm = [read_corner(state, s)[0] for s in range(8) if s != DBL]
    perm = [p - (p > DBL) for p in perm]
    idx = 0
    for i, p in enumerate(perm):
        idx = idx * (7 - i) + sum(q < p for q in perm[i + 1:])
    return idx


def ori_index(state):
    """Return 0..728, the twists of slots 0..5 in base 3."""
    idx = 0
    for s in range(6):
        idx = idx * 3 + read_corner(state, s)[1]
    return idx


def bfs_table(coord, size):
    """Return the moves from solved for every value of one coordinate.

    A coordinate's next value depends only on its current value, so one
    cube state per value is enough to expand.
    """
    dist = [None] * size
    dist[coord(SOLVED)] = 0
    queue = deque([SOLVED])
    while queue:
        state = queue.popleft()
        for m in SOLVER_MOVES:
            child = apply_move(state, m)
            if dist[coord(child)] is None:
                dist[coord(child)] = dist[coord(state)] + 1
                queue.append(child)
    return dist


PERM_DIST = bfs_table(perm_index, 5040)
ORI_DIST = bfs_table(ori_index, 729)


def h(state):
    """Return the pattern table heuristic.

    Neither table overestimates, so their maximum is still admissible.
    """
    return max(PERM_DIST[perm_index(state)], ORI_DIST[ori_index(state)])


class Node:
    def __init__(self, state, parent=None, action=None, path_cost=0):
        self.state = state
        self.parent = parent
        self.action = action
        self.path_cost = path_cost


class CubeProblem:
    def __init__(self, initial):
        self.initial = initial

    def actions(self, state):
        return SOLVER_MOVES

    def result(self, state, action):
        return apply_move(state, action)

    def is_goal(self, state):
        return state == SOLVED


def expand(problem, node):
    """Return the children of a node, skipping same-face repeats (5.4)."""
    children = []
    for action in problem.actions(node.state):
        if node.action is not None and same_face(action, node.action):
            continue
        state = problem.result(node.state, action)
        children.append(Node(state, node, action, node.path_cost + 1))
    return children


def solution(node):
    """Return the move codes from the start to this node."""
    moves = []
    while node.parent is not None:
        moves.append(node.action)
        node = node.parent
    return moves[::-1]


def f_cost(node, h):
    """Return A*'s evaluation function f(n) = g(n) + h(n)."""
    return node.path_cost + h(node.state)


def f_limited_search(problem, h, f_limit):
    """Depth-first search that cuts off children with f above f_limit.

    Also returns the smallest f that went over the limit, which is the
    next limit to try.
    """
    next_f_limit = math.inf
    popped = 0
    node = Node(state=problem.initial)
    frontier = [node]
    while len(frontier) > 0:
        node = frontier.pop()
        popped += 1
        if problem.is_goal(node.state):
            return node, "SOLUTION", popped, next_f_limit
        children = expand(problem, node)
        for child in reversed(children):
            f = f_cost(child, h)
            if f > f_limit:
                next_f_limit = min(next_f_limit, f)
                continue
            frontier.append(child)

    outcome = "CUT-OFF" if next_f_limit < math.inf else "FAILURE"
    return None, outcome, popped, next_f_limit


def ida_star_search(problem, h):
    """Run f-limited searches with a growing limit until one finds the goal."""
    ida_measurements = []
    f_limit = h(problem.initial)
    while True:
        result_node, outcome, popped, next_f_limit = f_limited_search(problem, h, f_limit)
        ida_measurements.append((f_limit, popped, outcome))
        if outcome == "SOLUTION":
            return result_node, ida_measurements
        if outcome == "FAILURE":
            return None, ida_measurements
        f_limit = next_f_limit


def scramble(n=25, seed=None):
    """Make n random turns, never the same face twice in a row."""
    rng, state, moves = random.Random(seed), SOLVED, []
    while len(moves) < n:
        m = rng.randrange(18)
        if not moves or not same_face(m, moves[-1]):
            moves.append(m)
            state = apply_move(state, m)
    return state, moves


def solve(state):
    """Return (solution moves, measurements) for a cube state."""
    err = check(state)
    if err:
        raise ValueError(err)
    node, measurements = ida_star_search(CubeProblem(recolour(state)), h)
    return solution(node), measurements


if __name__ == "__main__":
    for seed in range(5):
        cube, scr = scramble(seed=seed)
        start = time.time()
        sol, measurements = solve(cube)
        for m in sol:
            cube = apply_move(cube, m)
        assert is_solved(cube)
        print(f"scramble: {' '.join(map(move_name, scr))}")
        print(f"solution: {' '.join(map(move_name, sol))} "
              f"({len(sol)} moves, {time.time() - start:.2f} s)")
        for f_limit, popped, outcome in measurements:
            print(f"  f_limit={f_limit:2}  popped={popped:6}  {outcome}")
