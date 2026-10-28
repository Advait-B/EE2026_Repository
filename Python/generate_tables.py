#!/usr/bin/env python3
"""Generate 2x2 corner orientation and permutation distance tables.

The transition model here is self-contained. It uses corner coordinates and
the project's move numbering/direction convention; it does not parse or
compile any Verilog source.
"""

from collections import deque
from pathlib import Path


# Corner order: URF, UFL, ULB, UBR, DFR, DLF, DBL, DRB.
# The face order at each corner defines the cyclic orientation convention.
CORNER_FACES = (
    ("U", "R", "F"),
    ("U", "F", "L"),
    ("U", "L", "B"),
    ("U", "B", "R"),
    ("D", "F", "R"),
    ("D", "L", "F"),
    ("D", "B", "L"),
    ("D", "R", "B"),
)

# Coordinates use R=+x, U=+y, F=+z, matching cube_defs.vh.
CORNER_COORDS = (
    (1, 1, 1),    # URF
    (-1, 1, 1),   # UFL
    (-1, 1, -1),  # ULB
    (1, 1, -1),   # UBR
    (1, -1, 1),   # DFR
    (-1, -1, 1),  # DLF
    (-1, -1, -1), # DBL
    (1, -1, -1),  # DRB
)

FACE_NORMALS = {
    "U": (0, 1, 0),
    "R": (1, 0, 0),
    "F": (0, 0, 1),
    "D": (0, -1, 0),
    "L": (-1, 0, 0),
    "B": (0, 0, -1),
}
NORMAL_FACES = {normal: face for face, normal in FACE_NORMALS.items()}
COORD_TO_CORNER = {coord: index for index, coord in enumerate(CORNER_COORDS)}

# Move codes match cube_defs.vh: face*3 + {clockwise, counter-clockwise, half}.
MOVE_FACES = ("U", "R", "F", "D", "L", "B")
MOVE_TYPES = ("clockwise", "counter_clockwise", "half")
N_MOVES = len(MOVE_FACES) * len(MOVE_TYPES)
N_ORIENTATION_COORDS = 3**7
N_PERMUTATION_COORDS = 40320


def dot(left, right):
    return sum(a * b for a, b in zip(left, right))


def cross(left, right):
    return (
        left[1] * right[2] - left[2] * right[1],
        left[2] * right[0] - left[0] * right[2],
        left[0] * right[1] - left[1] * right[0],
    )


def turn_vector(vector, axis, turn_type):
    """Rotate a vector using the clockwise convention in cube_defs.vh."""
    axial = dot(vector, axis)
    perpendicular_cross = cross(axis, vector)
    if turn_type == 0:  # clockwise: -90 degrees about outward normal
        return tuple(axis[i] * axial - perpendicular_cross[i] for i in range(3))
    if turn_type == 1:  # counter-clockwise: +90 degrees
        return tuple(axis[i] * axial + perpendicular_cross[i] for i in range(3))
    return tuple(2 * axis[i] * axial - vector[i] for i in range(3))


def move_corner_transform(move):
    """Return source->destination corner indices and twist deltas."""
    face = MOVE_FACES[move // 3]
    turn_type = move % 3
    axis = FACE_NORMALS[face]
    destinations = []
    twist_deltas = []

    for source, position in enumerate(CORNER_COORDS):
        if dot(position, axis) == 1:
            destination_position = turn_vector(position, axis, turn_type)
            destination = COORD_TO_CORNER[destination_position]
            deltas = []
            for source_slot, sticker_face in enumerate(CORNER_FACES[source]):
                normal = FACE_NORMALS[sticker_face]
                destination_face = NORMAL_FACES[turn_vector(normal, axis, turn_type)]
                destination_slot = CORNER_FACES[destination].index(destination_face)
                deltas.append((destination_slot - source_slot) % 3)
            if len(set(deltas)) != 1:
                raise ValueError(f"Move {move} gives inconsistent twist at corner {source}: {deltas}")
            twist_delta = deltas[0]
        else:
            destination = source
            twist_delta = 0
        destinations.append(destination)
        twist_deltas.append(twist_delta)

    if sorted(destinations) != list(range(8)):
        raise ValueError(f"Move {move} is not a corner permutation")
    if sum(twist_deltas) % 3 != 0:
        raise ValueError(f"Move {move} violates the corner twist-sum constraint")
    return destinations, twist_deltas


MOVE_TRANSFORMS = tuple(move_corner_transform(move) for move in range(N_MOVES))


def encode_orientation(orientation):
    """Encode the first seven corner twists as a base-3 coordinate."""
    if len(orientation) != 8 or sum(orientation) % 3 != 0:
        raise ValueError("Corner twists must contain eight values summing to 0 modulo 3")
    coordinate = 0
    for twist in orientation[:7]:
        if twist not in (0, 1, 2):
            raise ValueError("Corner twists must be in the range 0..2")
        coordinate = coordinate * 3 + twist
    return coordinate


def decode_orientation(coordinate):
    """Decode a base-3 coordinate and infer the eighth corner twist."""
    if not 0 <= coordinate < N_ORIENTATION_COORDS:
        raise ValueError(f"Invalid orientation coordinate: {coordinate}")
    orientation = [0] * 8
    for index in range(6, -1, -1):
        orientation[index] = coordinate % 3
        coordinate //= 3
    orientation[7] = (-sum(orientation[:7])) % 3
    return orientation


def encode_permutation(permutation):
    """Return the Lehmer rank of a permutation of corner IDs 0..7."""
    if sorted(permutation) != list(range(8)):
        raise ValueError("Corner permutation must contain each ID from 0 through 7 once")
    rank = 0
    for index, value in enumerate(permutation):
        smaller_to_right = sum(other < value for other in permutation[index + 1 :])
        rank = rank * (8 - index) + smaller_to_right
    return rank


def decode_permutation(rank):
    """Decode a Lehmer rank into a corner permutation."""
    if not 0 <= rank < N_PERMUTATION_COORDS:
        raise ValueError(f"Invalid permutation coordinate: {rank}")
    available = list(range(8))
    permutation = []
    for index in range(8):
        factorial = 1
        for factor in range(1, 8 - index):
            factorial *= factor
        digit, rank = divmod(rank, factorial)
        permutation.append(available.pop(digit))
    return permutation


def apply_move(orientation, permutation, move):
    destinations, twist_deltas = MOVE_TRANSFORMS[move]
    next_orientation = [0] * 8
    next_permutation = [0] * 8
    for source, destination in enumerate(destinations):
        next_orientation[destination] = (orientation[source] + twist_deltas[source]) % 3
        next_permutation[destination] = permutation[source]
    return next_orientation, next_permutation


def orientation_successors(coordinate):
    orientation = decode_orientation(coordinate)
    successors = []
    for move in range(N_MOVES):
        next_orientation, _ = apply_move(orientation, list(range(8)), move)
        successors.append(encode_orientation(next_orientation))
    return successors


def permutation_successors(coordinate):
    permutation = decode_permutation(coordinate)
    successors = []
    for move in range(N_MOVES):
        _, next_permutation = apply_move([0] * 8, permutation, move)
        successors.append(encode_permutation(next_permutation))
    return successors


def build_distance_table(state_count, successors):
    """BFS one projected coordinate graph from its solved coordinate."""
    distances = [-1] * state_count
    distances[0] = 0
    frontier = deque([0])
    while frontier:
        state = frontier.popleft()
        next_distance = distances[state] + 1
        for next_state in successors(state):
            if distances[next_state] == -1:
                distances[next_state] = next_distance
                frontier.append(next_state)
    if any(distance < 0 for distance in distances):
        raise ValueError("The move graph did not reach every coordinate")
    if max(distances) > 15:
        raise ValueError(f"4-bit distance table cannot hold maximum distance {max(distances)}")
    return distances


def write_distance_table(path, distances):
    """Write one 4-bit hexadecimal distance per coordinate."""
    with path.open("w", encoding="ascii", newline="\n") as output:
        for distance in distances:
            output.write(f"{distance:x}\n")


def main():
    output_dir = Path(__file__).resolve().parent
    orientation_path = output_dir / "orientation.mem"
    permutation_path = output_dir / "permutation.mem"
    orientation_distances = build_distance_table(
        N_ORIENTATION_COORDS, orientation_successors
    )
    permutation_distances = build_distance_table(
        N_PERMUTATION_COORDS, permutation_successors
    )
    write_distance_table(orientation_path, orientation_distances)
    write_distance_table(permutation_path, permutation_distances)
    print(
        f"Wrote {len(orientation_distances):,} 4-bit orientation distances "
        f"(maximum {max(orientation_distances)}) to {orientation_path.name}"
    )
    print(
        f"Wrote {len(permutation_distances):,} 4-bit permutation distances "
        f"(maximum {max(permutation_distances)}) to {permutation_path.name}"
    )
    print("Distances are exact in each projected coordinate graph.")
    print("Move model is self-contained; no move_rules.v dependency.")


if __name__ == "__main__":
    main()
