#!/usr/bin/env python3
"""Read-only verification for the compact 2x2 distance tables."""

from math import ceil
from pathlib import Path
import re
import sys

import numpy as np

from generate_tables import (
    N_MOVES,
    N_ORIENTATION_COORDS,
    N_PERMUTATION_COORDS,
    apply_move,
    decode_orientation,
    decode_permutation,
    encode_orientation,
    encode_permutation,
)


MAX_ALLOWED_DISTANCE = 15
N_COMBINED_STATES = N_ORIENTATION_COORDS * N_PERMUTATION_COORDS
MOVE_INVERSES = tuple(
    move + 1 if move % 3 == 0 else
    move - 1 if move % 3 == 1 else move
    for move in range(N_MOVES)
)


def load_distances(path, state_count):
    """Read one hexadecimal nibble per coordinate."""
    distances = np.empty(state_count, dtype=np.uint8)
    errors = []
    count = 0
    try:
        source = path.open("r", encoding="ascii")
    except OSError as exc:
        return None, [f"cannot read {path.name}: {exc}"]

    with source:
        for line_number, line in enumerate(source, start=1):
            word = line.strip()
            if count >= state_count:
                if len(errors) < 5:
                    errors.append(f"{path.name}:{line_number}: extra word {word!r}")
                count += 1
                continue
            if len(word) != 1 or word not in "0123456789abcdefABCDEF":
                if len(errors) < 5:
                    errors.append(f"{path.name}:{line_number}: expected one hex digit, got {word!r}")
                count += 1
                continue
            distances[count] = int(word, 16)
            count += 1

    if count != state_count:
        errors.append(f"{path.name}: expected {state_count:,} words, found {count:,}")
    if errors:
        return None, errors
    return distances, []


def build_orientation_moves():
    transitions = np.empty((N_ORIENTATION_COORDS, N_MOVES), dtype=np.uint16)
    identity_permutation = list(range(8))
    for coordinate in range(N_ORIENTATION_COORDS):
        orientation = decode_orientation(coordinate)
        for move in range(N_MOVES):
            next_orientation, _ = apply_move(orientation, identity_permutation, move)
            transitions[coordinate, move] = encode_orientation(next_orientation)
    return transitions


def build_permutation_moves():
    transitions = np.empty((N_PERMUTATION_COORDS, N_MOVES), dtype=np.uint16)
    zero_orientation = [0] * 8
    for coordinate in range(N_PERMUTATION_COORDS):
        permutation = decode_permutation(coordinate)
        for move in range(N_MOVES):
            _, next_permutation = apply_move(zero_orientation, permutation, move)
            transitions[coordinate, move] = encode_permutation(next_permutation)
    return transitions


def breadth_first_distances(transitions):
    """Compute exact shortest distances from coordinate zero."""
    state_count = transitions.shape[0]
    unseen = np.uint8(255)
    distances = np.full(state_count, unseen, dtype=np.uint8)
    distances[0] = 0
    frontier = [0]
    while frontier:
        next_frontier = []
        for state in frontier:
            next_distance = int(distances[state]) + 1
            for next_state in transitions[state]:
                next_state = int(next_state)
                if distances[next_state] == unseen:
                    distances[next_state] = next_distance
                    next_frontier.append(next_state)
        frontier = next_frontier
    return distances


def check_distance_table(name, stored, transitions):
    """Check exact values, legal range, and edge consistency."""
    expected = breadth_first_distances(transitions)
    unreachable = int(np.count_nonzero(expected == 255))
    mismatches = int(np.count_nonzero(stored != expected))
    maximum = int(stored.max())
    if unreachable:
        return False, f"{unreachable:,} coordinates are unreachable", maximum
    if maximum > MAX_ALLOWED_DISTANCE:
        return False, f"maximum {maximum} exceeds {MAX_ALLOWED_DISTANCE}", maximum
    if mismatches:
        first = np.flatnonzero(stored != expected)[:5]
        details = [(int(index), int(stored[index]), int(expected[index])) for index in first]
        return False, f"{mismatches:,} distances differ from BFS; first (coord, stored, expected): {details}", maximum

    # A shortest-distance table changes by at most one across an edge, and
    # every non-solved coordinate has at least one edge toward distance - 1.
    neighbor_distances = stored[transitions]
    difference = np.abs(stored.astype(np.int16)[:, None] - neighbor_distances.astype(np.int16))
    edge_consistent = bool(np.all(difference <= 1))
    descends = np.any(neighbor_distances + 1 == stored[:, None], axis=1)
    all_descend = bool(np.all(descends[1:]))
    if not edge_consistent or not all_descend:
        return False, "edge consistency or a descending path check failed", maximum
    if int(stored[0]) != 0:
        return False, f"solved coordinate has distance {int(stored[0])}, expected 0", maximum
    return True, f"{len(stored):,} exact distances; maximum {maximum}; all edges consistent", maximum


def check_move_identities(orientation_moves, permutation_moves):
    """Check move inverses and turn orders for every projected coordinate."""
    problems = []
    for name, transitions in (
        ("orientation", orientation_moves),
        ("permutation", permutation_moves),
    ):
        coordinates = np.arange(transitions.shape[0], dtype=np.uint16)
        for move, inverse in enumerate(MOVE_INVERSES):
            restored = transitions[transitions[:, move], inverse]
            failures = int(np.count_nonzero(restored != coordinates))
            if failures:
                problems.append(f"{name} move {move}/inverse {inverse}: {failures:,} failures")
        for face in range(6):
            clockwise = face * 3
            twice = transitions[transitions[:, clockwise], clockwise]
            three_times = transitions[twice, clockwise]
            four_times = transitions[three_times, clockwise]
            half = clockwise + 2
            half_twice = transitions[transitions[:, half], half]
            if np.any(four_times != coordinates):
                problems.append(f"{name} face {face}: clockwise^4 is not identity")
            if np.any(half_twice != coordinates):
                problems.append(f"{name} face {face}: half-turn^2 is not identity")
    if problems:
        return False, "; ".join(problems[:8])
    return True, "inverse and turn-order identities hold for every coordinate"


def combined_state_distances(orientation_moves, permutation_moves):
    """BFS all combined coordinates to check the full 2x2 state diameter."""
    visited = np.full(N_COMBINED_STATES, 255, dtype=np.uint8)
    visited[0] = 0
    frontier = np.array([0], dtype=np.uint32)
    depth = 0
    discovered = 1

    while frontier.size:
        orientation_ids = frontier // N_PERMUTATION_COORDS
        permutation_ids = frontier - orientation_ids * N_PERMUTATION_COORDS
        next_parts = []
        next_depth = depth + 1
        for move in range(N_MOVES):
            next_orientation = orientation_moves[orientation_ids, move].astype(np.uint32)
            next_permutation = permutation_moves[permutation_ids, move].astype(np.uint32)
            neighbors = next_orientation * N_PERMUTATION_COORDS + next_permutation
            new_states = neighbors[visited[neighbors] == 255]
            if new_states.size:
                visited[new_states] = next_depth
                next_parts.append(new_states)
        if not next_parts:
            break
        frontier = np.concatenate(next_parts)
        depth = next_depth
        discovered += int(frontier.size)
        print(f"  BFS depth {depth:2d}: {frontier.size:>10,} states (total {discovered:,})", flush=True)
    return discovered, int(visited.max())


def bram_budget(project_root):
    """Estimate 36-Kb BRAM blocks for the distance tables and full view ROM."""
    xpr = project_root / "rubiks" / "rubiks.xpr"
    part = ""
    if xpr.exists():
        match = re.search(r'<Option Name="Part" Val="([^"]+)"', xpr.read_text(encoding="utf-8"))
        if match:
            part = match.group(1)

    if not part.lower().startswith("xc7a35t"):
        return False, f"project target is {part or 'unknown'}; the 50-RAMB36 estimate is XC7A35T-specific"

    permutation_blocks = ceil(N_PERMUTATION_COORDS / 8192)  # RAMB36 x4 mode
    orientation_blocks = ceil(N_ORIENTATION_COORDS / 8192)
    renderer_depth = 128 * 12
    renderer_blocks = ceil(renderer_depth / 2048) * ceil(85 / 18)  # RAMB36 x18 mode
    total_blocks = permutation_blocks + orientation_blocks + renderer_blocks
    distance_bits = 4 * (N_PERMUTATION_COORDS + N_ORIENTATION_COORDS)
    renderer_bits = renderer_depth * 85
    if total_blocks > 50:
        return False, (
            f"{permutation_blocks}+{orientation_blocks}+{renderer_blocks}={total_blocks} "
            "RAMB36 blocks exceeds the XC7A35T's 50"
        )
    return True, (
        f"{distance_bits:,} distance bits + {renderer_bits:,} full-range renderer bits; "
        f"estimated {permutation_blocks} permutation + {orientation_blocks} orientation + "
        f"{renderer_blocks} renderer = {total_blocks}/50 RAMB36 blocks"
    )


def main():
    python_dir = Path(__file__).resolve().parent
    project_root = python_dir.parent
    orientation_distances, orientation_errors = load_distances(
        python_dir / "orientation.mem", N_ORIENTATION_COORDS
    )
    permutation_distances, permutation_errors = load_distances(
        python_dir / "permutation.mem", N_PERMUTATION_COORDS
    )
    failures = []

    if orientation_errors or permutation_errors:
        print("COVERAGE: FAIL")
        for error in orientation_errors + permutation_errors:
            print(f"  {error}")
        failures.append("table coverage/format")
        print("VERIFICATION FAILED: " + ", ".join(failures))
        return 1

    if np.any(orientation_distances > MAX_ALLOWED_DISTANCE):
        failures.append("orientation values exceed 15")
    if np.any(permutation_distances > MAX_ALLOWED_DISTANCE):
        failures.append("permutation values exceed 15")
    print(
        f"COVERAGE: PASS - {N_ORIENTATION_COORDS:,} orientation and "
        f"{N_PERMUTATION_COORDS:,} permutation coordinates, one 4-bit word each"
    )

    print("Building coordinate move relations from the agreed corner/move convention...", flush=True)
    orientation_moves = build_orientation_moves()
    permutation_moves = build_permutation_moves()

    orientation_ok, orientation_detail, orientation_max = check_distance_table(
        "orientation", orientation_distances, orientation_moves
    )
    permutation_ok, permutation_detail, permutation_max = check_distance_table(
        "permutation", permutation_distances, permutation_moves
    )
    print(f"ORIENTATION DISTANCES: {'PASS' if orientation_ok else 'FAIL'} - {orientation_detail}")
    print(f"PERMUTATION DISTANCES: {'PASS' if permutation_ok else 'FAIL'} - {permutation_detail}")
    if not orientation_ok:
        failures.append("orientation distance table")
    if not permutation_ok:
        failures.append("permutation distance table")

    identities_ok, identities_detail = check_move_identities(orientation_moves, permutation_moves)
    print(f"MOVE MODEL: {'PASS' if identities_ok else 'FAIL'} - {identities_detail}")
    if not identities_ok:
        failures.append("move identities")

    print("FULL CUBE: breadth-first search over combined coordinates (0 is solved)", flush=True)
    discovered, cube_maximum = combined_state_distances(orientation_moves, permutation_moves)
    expected_states = N_COMBINED_STATES
    if discovered != expected_states:
        print(f"FULL CUBE COVERAGE: FAIL - reached {discovered:,} of {expected_states:,} states")
        failures.append("full cube reachability")
    if cube_maximum <= MAX_ALLOWED_DISTANCE:
        print(
            f"MAX FULL-CUBE DISTANCE: PASS - {cube_maximum} moves "
            f"(limit {MAX_ALLOWED_DISTANCE}); {discovered:,} states reached"
        )
    else:
        print(
            f"MAX FULL-CUBE DISTANCE: FAIL - {cube_maximum} moves "
            f"exceeds {MAX_ALLOWED_DISTANCE}"
        )
        failures.append("full cube distance")

    budget_ok, budget_detail = bram_budget(project_root)
    print(f"BRAM ESTIMATE: {'PASS' if budget_ok else 'FAIL'} - {budget_detail}")
    if not budget_ok:
        failures.append("BRAM budget")

    print(
        f"PROJECTED MAXIMA: orientation={orientation_max}, permutation={permutation_max}; "
        f"heuristic is max(orientation, permutation)"
    )
    if failures:
        print("VERIFICATION FAILED: " + ", ".join(failures))
        return 1
    print("VERIFICATION PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
