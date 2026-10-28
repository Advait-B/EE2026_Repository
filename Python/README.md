# 2x2 coordinate distance tables

Run python Python/generate_tables.py from the repository root to generate
orientation.mem and permutation.mem here. The files hold one 4-bit distance
estimate per coordinate, rather than a next-coordinate entry for every
coordinate/move pair. The generator is self-contained Python and does not
parse or compile move_rules.v.

## Coordinate format

The corner order remains:

    URF, UFL, ULB, UBR, DFR, DLF, DBL, DRB

The orientation coordinate encodes the first seven twists in base 3; the
eighth twist is inferred so all eight sum to zero modulo 3. This gives
3^7 = 2,187 legal coordinates.

The permutation coordinate is the Lehmer rank of the corner piece IDs at those
positions. This gives 8! = 40,320 coordinates.

Move IDs and directions are unchanged: U, U', U2, R, R', R2, F, F', F2, D,
D', D2, L, L', L2, B, B', B2, numbered 0 through 17 as face * 3 + turn_type.
The distance generator uses that move set to build each projected coordinate
graph.

Each .mem file has one hexadecimal digit per line for direct readmemh loading
into a 4-bit-wide ROM. orientation.mem has 2,187 words; permutation.mem has
40,320 words.

## Using the distances

orientation.mem[o] is the exact shortest move distance from orientation
coordinate o to zero when only orientation is considered.
permutation.mem[p] is the equivalent distance for permutation coordinate p.

For a complete cube state, use:

    h = max(orientation_distance, permutation_distance)

Each projected distance is a lower bound on the number of moves needed by the
full cube, so their maximum is an admissible and consistent IDA* heuristic.
Do not add the two distances: the same face turn can change both coordinates.
The solver can generate candidate child states with the existing move rules,
then look up the two distances for each child. This removes the large
coordinate-by-move ROM.

Example: after one U move, the orientation coordinate is 0 and the
permutation coordinate is 15,120. The corresponding distance words are
orientation.mem[0] = 0 and permutation.mem[15120] = 1, giving heuristic
max(0, 1) = 1.

## XC7A35T memory estimate

The project targets xc7a35tcpg236-1. The compact distance tables use
(2,187 + 40,320) * 4 = 170,028 bits, about 20.8 KiB. The current view_rom.v
is a stub; budgeting its complete declared interface gives
128 views * 12 slots * 85 bits = 130,560 bits, about 15.9 KiB.

Using 7-series RAMB36 aspect ratios, the distance tables need an estimated six
RAMB36 blocks: five for the 40,320-by-4 permutation ROM and one for the
2,187-by-4 orientation ROM. A full 1,536-by-85 renderer ROM needs about five
more blocks. The estimate is 11 of the XC7A35T's 50 RAMB36 blocks. This is a
capacity estimate; actual inference still depends on synchronous ROM coding
and the final synthesis result.

Resource references: AMD's [7-series product selection guide](https://www.amd.com/content/dam/xilinx/support/documents/selection-guides/7-series-product-selection-guide.pdf)
lists XC7A35T block RAM capacity; the [7-series Memory Resources guide](https://docs.amd.com/api/khub/documents/9gZGbqBxtlKXxBfkBt~lAg/content)
documents RAMB36 width/depth configurations.

## Verification

Run python Python/verify_tables.py. It checks that every coordinate has a
4-bit word, recomputes exact projected distances from the move model, checks
all edge-distance and move-identity conditions, and breadth-first searches
the combined coordinate graph. It also reports the renderer-inclusive BRAM
estimate. NumPy is used to make the full 88,179,840-state search practical.

The move code order matches cube_defs.vh. The Python generator independently
implements the same corner geometry and does not read move_rules.v; update
both definitions together if the cube convention ever changes.
