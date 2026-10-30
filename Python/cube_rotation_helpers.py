"""Enumerate cube rotations and map reference stickers to live cube slots."""

from itertools import permutations, product


CUBE_STICKER_COUNT = 24

# Face order is U, R, F, D, L, B. Right and up point across each face as
# viewed from outside the cube. This matches cube_defs.vh.
FACES = (
    ((0, 1, 0), (1, 0, 0), (0, 0, -1)),   # U
    ((1, 0, 0), (0, 0, -1), (0, 1, 0)),  # R
    ((0, 0, 1), (1, 0, 0), (0, 1, 0)),   # F
    ((0, -1, 0), (1, 0, 0), (0, 0, 1)), # D
    ((-1, 0, 0), (0, 0, 1), (0, 1, 0)), # L
    ((0, 0, -1), (-1, 0, 0), (0, 1, 0)),# B
)

# Tile order is clockwise from outside the cube: top-left, top-right,
# bottom-right, bottom-left.
TILE_UV = (
    (-0.5, 0.5),
    (0.5, 0.5),
    (0.5, -0.5),
    (-0.5, -0.5),
)


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def scale(vector, amount):
    return tuple(value * amount for value in vector)


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def mat_vec(matrix, vector):
    return tuple(dot(row, vector) for row in matrix)


def mat_mul(a, b):
    return tuple(
        tuple(sum(a[row][k] * b[k][col] for k in range(3)) for col in range(3))
        for row in range(3)
    )


def transpose(matrix):
    return tuple(tuple(matrix[col][row] for col in range(3)) for row in range(3))


def determinant(matrix):
    return (
        matrix[0][0] * (matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])
        - matrix[0][1] * (matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][0])
        + matrix[0][2] * (matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])
    )


def cube_rotations():
    """Return all 24 proper signed permutation matrices in stable ID order.

    The identity is rotation ID 0. The remaining matrices are sorted so
    camera_angle_decode.mem keeps a stable rotation numbering.
    """
    rotations = []
    for columns in permutations(range(3)):
        for signs in product((-1, 1), repeat=3):
            matrix = tuple(
                tuple(signs[row] if col == columns[row] else 0 for col in range(3))
                for row in range(3)
            )
            if determinant(matrix) == 1:
                rotations.append(matrix)

    identity = ((1, 0, 0), (0, 1, 0), (0, 0, 1))
    ordered = [identity] + sorted(matrix for matrix in rotations if matrix != identity)
    if len(ordered) != 24 or len(set(ordered)) != 24:
        raise ValueError("Cube rotation enumeration did not produce 24 unique rotations.")
    return ordered


def sticker_surface(reference_sticker_id):
    """Return a sticker's outward normal and center in cube coordinates."""
    if not 0 <= reference_sticker_id < CUBE_STICKER_COUNT:
        raise ValueError(f"Invalid reference sticker ID {reference_sticker_id}.")

    face, tile = divmod(reference_sticker_id, 4)
    normal, right, up = FACES[face]
    u, v = TILE_UV[tile]
    center = add(normal, add(scale(right, u), scale(up, v)))
    return normal, center


def sticker_id_at_surface(normal, center):
    """Find the cube-state sticker occupying an outward normal and center."""
    face = next(
        (index for index, (face_normal, _, _) in enumerate(FACES)
         if face_normal == normal),
        None,
    )
    if face is None:
        raise ValueError(f"No cube face has normal {normal}.")

    face_normal, right, up = FACES[face]
    relative = tuple(center[index] - face_normal[index] for index in range(3))
    u, v = dot(relative, right), dot(relative, up)
    for tile, (tile_u, tile_v) in enumerate(TILE_UV):
        if abs(u - tile_u) < 1e-8 and abs(v - tile_v) < 1e-8:
            return face * 4 + tile
    raise ValueError(f"No cube tile matches surface center {center} on face {face}.")


def rotation_sticker_map(rotation):
    """Map each reference sticker ID to its live cube-state sticker index."""
    inverse = transpose(rotation)
    mapping = []
    for reference_sticker_id in range(CUBE_STICKER_COUNT):
        normal, center = sticker_surface(reference_sticker_id)
        live_normal = mat_vec(inverse, normal)
        live_center = mat_vec(inverse, center)
        mapping.append(sticker_id_at_surface(live_normal, live_center))

    if sorted(mapping) != list(range(CUBE_STICKER_COUNT)):
        raise ValueError("A cube rotation did not produce a sticker permutation.")
    return mapping


def cube_rotation_sticker_maps(rotations=None):
    """Return the 24 reference-to-live sticker maps in rotation ID order."""
    rotations = cube_rotations() if rotations is None else list(rotations)
    if len(rotations) != 24:
        raise ValueError(f"Expected 24 rotations, got {len(rotations)}.")
    return [rotation_sticker_map(rotation) for rotation in rotations]