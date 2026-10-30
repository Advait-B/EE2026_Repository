"""Generate cube_layout.mem and rotation_stickers.mem from the decode table.

Run from any working directory with:
    python path/to/python/generate_cube_projection_roms.py

camera_angle_decode.mem is a reviewed input table and is not generated here.
"""

from pathlib import Path

from cube_projection_geometry import (
    CAMERA_ANGLE_COUNT,
    PROJECTION_COUNT,
    VISIBLE_STICKER_SLOT_COUNT,
    camera_angle_matrix,
    matrices_match,
    projection_slot_records,
)
from cube_rotation_helpers import (
    CUBE_STICKER_COUNT,
    FACES,
    TILE_UV,
    cube_rotation_sticker_maps,
    cube_rotations,
    mat_mul,
)
from cube_slope_encoding import pack_corner_coords, pack_edge_slopes


ROOT = Path(__file__).resolve().parents[1]
RENDER_MEM_DIR = (
    ROOT / "rubiks" / "rubiks.srcs" / "sources_1" / "imports" / "src" / "render" / "mem"
)
CUBE_ROTATION_COUNT = 24
GEOMETRY_RECORD_WIDTH = 193
GEOMETRY_RECORD_HEX_WIDTH = (GEOMETRY_RECORD_WIDTH + 3) // 4


def read_decode_table(path):
    """Read the 256 packed {projection_id[4:0], rotation_id[4:0]} entries."""
    values = []
    for line_number, raw_line in enumerate(path.read_text(encoding="ascii").splitlines(), 1):
        line = raw_line.split("#", 1)[0].strip()
        if not line:
            continue
        try:
            value = int(line, 16)
        except ValueError as error:
            raise ValueError(f"Invalid hex value on line {line_number}: {line!r}.") from error
        if not 0 <= value < (1 << 10):
            raise ValueError(f"Decoder value on line {line_number} exceeds 10 bits.")
        values.append(value)

    if len(values) != CAMERA_ANGLE_COUNT:
        raise ValueError(
            f"Expected {CAMERA_ANGLE_COUNT} decoder values, got {len(values)}."
        )
    return values


def validate_decode_table(decode_values, rotations):
    """Validate IDs, required coverage, and projection/rotation factorization."""
    if len(decode_values) != CAMERA_ANGLE_COUNT:
        raise ValueError(
            f"Expected {CAMERA_ANGLE_COUNT} decoder values, got {len(decode_values)}."
        )
    if len(rotations) != CUBE_ROTATION_COUNT:
        raise ValueError(f"Expected {CUBE_ROTATION_COUNT} cube rotations, got {len(rotations)}.")

    projection_ids = set()
    rotation_ids = set()
    representatives = {}
    for camera_angle_id, packed in enumerate(decode_values):
        projection_id = (packed >> 5) & 0x1F
        rotation_id = packed & 0x1F
        if projection_id >= PROJECTION_COUNT:
            raise ValueError(
                f"Invalid projection ID {projection_id} at camera angle {camera_angle_id}."
            )
        if rotation_id >= CUBE_ROTATION_COUNT:
            raise ValueError(
                f"Invalid cube rotation ID {rotation_id} at camera angle {camera_angle_id}."
            )
        projection_ids.add(projection_id)
        rotation_ids.add(rotation_id)
        representatives.setdefault(projection_id, camera_angle_id)

    if projection_ids != set(range(PROJECTION_COUNT)):
        missing = sorted(set(range(PROJECTION_COUNT)) - projection_ids)
        raise ValueError(f"Decoder table does not reference every projection; missing {missing}.")
    if rotation_ids != set(range(CUBE_ROTATION_COUNT)):
        missing = sorted(set(range(CUBE_ROTATION_COUNT)) - rotation_ids)
        raise ValueError(f"Decoder table does not reference every rotation; missing {missing}.")

    angle_matrices = [camera_angle_matrix(angle_id) for angle_id in range(CAMERA_ANGLE_COUNT)]
    for camera_angle_id, packed in enumerate(decode_values):
        projection_id = (packed >> 5) & 0x1F
        rotation_id = packed & 0x1F
        expected = mat_mul(
            angle_matrices[representatives[projection_id]],
            rotations[rotation_id],
        )
        if not matrices_match(angle_matrices[camera_angle_id], expected):
            raise ValueError(
                f"Projection/rotation factorization mismatch at camera angle {camera_angle_id}."
            )
    return representatives


def geometry_records_for_projection(camera_angle_id):
    records = projection_slot_records(camera_angle_id, FACES, TILE_UV)
    if len(records) != VISIBLE_STICKER_SLOT_COUNT:
        raise ValueError(
            f"Projection {camera_angle_id} returned {len(records)} slots instead of 12."
        )
    return records


def pack_geometry_record(sticker_id, corners):
    if not 0 <= sticker_id < 32:
        raise ValueError(f"Sticker ID {sticker_id} does not fit in five bits.")
    corner_bits = pack_corner_coords(corners)
    slope_bits = pack_edge_slopes(corners)
    return (sticker_id << 188) | (slope_bits << 80) | corner_bits


def write_hex_lines(path, values):
    path.write_bytes(("\n".join(values) + "\n").encode("ascii"))


def generate_tables(decode_values, output_dir=RENDER_MEM_DIR):
    rotations = cube_rotations()
    representatives = validate_decode_table(decode_values, rotations)

    layout_lines = []
    for projection_id in range(PROJECTION_COUNT):
        camera_angle_id = representatives[projection_id]
        for sticker_id, corners in geometry_records_for_projection(camera_angle_id):
            packed = pack_geometry_record(sticker_id, corners)
            layout_lines.append(f"{packed:0{GEOMETRY_RECORD_HEX_WIDTH}X}")

    sticker_maps = cube_rotation_sticker_maps(rotations)
    rotation_lines = [
        f"{sticker_id:02X}"
        for mapping in sticker_maps
        for sticker_id in mapping
    ]

    expected_layout_records = PROJECTION_COUNT * VISIBLE_STICKER_SLOT_COUNT
    expected_rotation_records = CUBE_ROTATION_COUNT * CUBE_STICKER_COUNT
    if len(layout_lines) != expected_layout_records:
        raise ValueError(f"Expected {expected_layout_records} layout records.")
    if len(rotation_lines) != expected_rotation_records:
        raise ValueError(f"Expected {expected_rotation_records} rotation records.")

    output_dir.mkdir(parents=True, exist_ok=True)
    write_hex_lines(output_dir / "cube_layout.mem", layout_lines)
    write_hex_lines(output_dir / "rotation_stickers.mem", rotation_lines)
    return len(layout_lines), len(rotation_lines)


def main():
    decode_path = RENDER_MEM_DIR / "camera_angle_decode.mem"
    try:
        decode_values = read_decode_table(decode_path)
        layout_count, rotation_count = generate_tables(decode_values)
    except (OSError, ValueError, OverflowError) as error:
        raise SystemExit(f"error: {error}") from error
    print(
        f"Wrote {layout_count} projection slots and "
        f"{rotation_count} sticker mappings to {RENDER_MEM_DIR}."
    )


if __name__ == "__main__":
    main()