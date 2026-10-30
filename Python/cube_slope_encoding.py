"""Pack projected sticker corners and signed Q16 edge slopes."""


SLOPE_WIDTH = 27
SLOPE_FRACTION_BITS = 16
CORNER_WIDTH = 10
SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480


def _validate_corners(corners):
    if len(corners) != 4:
        raise ValueError(f"Expected four corners, got {len(corners)}.")
    for index, point in enumerate(corners):
        if len(point) != 2:
            raise ValueError(f"Corner {index} must be an (x, y) pair.")
        x, y = point
        if not (isinstance(x, int) and isinstance(y, int)):
            raise ValueError(f"Corner {index} coordinates must be integers.")
        if not (0 <= x < SCREEN_WIDTH and 0 <= y < SCREEN_HEIGHT):
            raise ValueError(f"Corner {index} ({x}, {y}) is outside the screen.")
        if x >= (1 << CORNER_WIDTH) or y >= (1 << CORNER_WIDTH):
            raise ValueError(f"Corner {index} does not fit in 10-bit coordinates.")


def pack_corner_coords(corners):
    """Pack four corners as {x3,y3,...,x0,y0}, with 10 bits per value."""
    _validate_corners(corners)
    packed = 0
    for corner, (x, y) in enumerate(corners):
        packed |= x << (10 + 20 * corner)
        packed |= y << (20 * corner)
    return packed


def _round_ratio_away_from_zero(numerator, denominator):
    if denominator <= 0:
        raise ValueError("The slope denominator must be positive.")
    sign = -1 if numerator < 0 else 1
    magnitude = abs(numerator)
    rounded = (magnitude + denominator // 2) // denominator
    return sign * rounded


def edge_slope_q16(point_a, point_b):
    """Return dx/dy in signed Q16, orienting the edge from top to bottom."""
    x0, y0 = point_a
    x1, y1 = point_b
    if y0 == y1:
        return 0
    if y0 < y1:
        dx, dy = x1 - x0, y1 - y0
    else:
        dx, dy = x0 - x1, y0 - y1

    numerator = dx << SLOPE_FRACTION_BITS
    return _round_ratio_away_from_zero(numerator, dy)


def pack_edge_slopes(corners):
    """Pack four signed 27-bit Q16 slopes in edge order 0->1, 1->2, 2->3, 3->0."""
    _validate_corners(corners)
    minimum = -(1 << (SLOPE_WIDTH - 1))
    maximum = (1 << (SLOPE_WIDTH - 1)) - 1
    mask = (1 << SLOPE_WIDTH) - 1
    packed = 0

    for edge in range(4):
        slope = edge_slope_q16(corners[edge], corners[(edge + 1) % 4])
        if not minimum <= slope <= maximum:
            raise OverflowError(
                f"Edge {edge} Q16 slope {slope} does not fit signed {SLOPE_WIDTH}-bit storage."
            )
        packed |= (slope & mask) << (SLOPE_WIDTH * edge)
    return packed