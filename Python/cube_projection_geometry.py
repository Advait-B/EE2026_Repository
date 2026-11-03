"""Project the 12 front-to-back sticker slots for a camera angle."""

import math

from cube_rotation_helpers import add, dot, mat_mul, mat_vec, scale


CAMERA_ANGLE_COUNT = 256
PROJECTION_COUNT = 28
VISIBLE_STICKER_SLOT_COUNT = 12
SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480
SCREEN_CENTER_X = 320
SCREEN_CENTER_Y = 220
PIXELS_PER_UNIT = 100
FACELET_GAP_PIXELS = 8
FACELET_INSET_UNITS = FACELET_GAP_PIXELS / (2 * PIXELS_PER_UNIT)
CORNER_EXTENT = 0.5 - FACELET_INSET_UNITS

CORNER_UV = (
    (-CORNER_EXTENT, CORNER_EXTENT),
    (CORNER_EXTENT, CORNER_EXTENT),
    (CORNER_EXTENT, -CORNER_EXTENT),
    (-CORNER_EXTENT, -CORNER_EXTENT),
)


def camera_angle_matrix(camera_angle_id):
    """Return Ry(yaw) * Rx(pitch) for one packed camera angle ID."""
    if not 0 <= camera_angle_id < CAMERA_ANGLE_COUNT:
        raise ValueError(f"Invalid camera angle ID {camera_angle_id}.")

    pitch = (camera_angle_id >> 4) * math.pi / 8
    yaw = (camera_angle_id & 0xF) * math.pi / 8
    cp, sp = math.cos(pitch), math.sin(pitch)
    cy, sy = math.cos(yaw), math.sin(yaw)
    rotate_x = ((1, 0, 0), (0, cp, -sp), (0, sp, cp))
    rotate_y = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))
    return mat_mul(rotate_y, rotate_x)


def matrices_match(a, b, tolerance=1e-8):
    return max(
        abs(a[row][col] - b[row][col])
        for row in range(3)
        for col in range(3)
    ) < tolerance


def _project_point(point, matrix):
    camera_x, camera_y, _ = mat_vec(matrix, point)
    pixel_x = math.floor(SCREEN_CENTER_X + camera_x * PIXELS_PER_UNIT + 0.5)
    pixel_y = math.floor(SCREEN_CENTER_Y - camera_y * PIXELS_PER_UNIT + 0.5)
    if not (0 <= pixel_x < SCREEN_WIDTH and 0 <= pixel_y < SCREEN_HEIGHT):
        raise ValueError(f"Projected point ({pixel_x}, {pixel_y}) is outside the screen.")
    return pixel_x, pixel_y


def projection_slot_records(camera_angle_id, faces, tile_uv):
    """Return 12 (reference sticker ID, four corners) front-to-back records.

    Empty slots have ID 31 and four zero-valued corners. The face bases and
    tile coordinates come from cube_rotation_helpers and match cube_defs.vh.
    """
    matrix = camera_angle_matrix(camera_angle_id)
    visible = []

    for face, (normal, right, up) in enumerate(faces):
        camera_normal = mat_vec(matrix, normal)
        if camera_normal[2] <= 1e-8:
            continue

        for tile, (u, v) in enumerate(tile_uv):
            center = add(normal, add(scale(right, u), scale(up, v)))
            camera_center = mat_vec(matrix, center)
            corners = []
            for du, dv in CORNER_UV:
                point = add(center, add(scale(right, du), scale(up, dv)))
                corners.append(_project_point(point, matrix))
            reference_sticker_id = face * 4 + tile
            visible.append((
                -camera_center[2], reference_sticker_id, tuple(corners)
            ))

    visible.sort(key=lambda record: (record[0], record[1]))
    if len(visible) > VISIBLE_STICKER_SLOT_COUNT:
        raise ValueError(
            f"Camera angle {camera_angle_id} has more than "
            f"{VISIBLE_STICKER_SLOT_COUNT} visible stickers."
        )

    records = [
        (reference_sticker_id, corners)
        for _, reference_sticker_id, corners in visible
    ]
    empty_corners = ((0, 0), (0, 0), (0, 0), (0, 0))
    records.extend(
        (31, empty_corners)
        for _ in range(VISIBLE_STICKER_SLOT_COUNT - len(records))
    )
    return records
