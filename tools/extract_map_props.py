from __future__ import annotations

import json
from collections import deque
from pathlib import Path

from PIL import Image


SOURCE_DIR = Path("assets/maps/stitched_demo/props")
OUTPUT_DIR = Path("assets/maps/stitched_demo/generated_props")
MANIFEST_PATH = OUTPUT_DIR / "manifest.json"

ALPHA_THRESHOLD = 20
MIN_AREA = 1800
PADDING = 2


def _component_bounds(alpha, width: int, height: int) -> list[tuple[int, tuple[int, int, int, int]]]:
    pixels = alpha.load()
    seen = bytearray(width * height)
    components: list[tuple[int, tuple[int, int, int, int]]] = []

    for y in range(height):
        for x in range(width):
            index = y * width + x
            if seen[index] or pixels[x, y] <= ALPHA_THRESHOLD:
                continue

            seen[index] = 1
            queue: list[tuple[int, int]] = [(x, y)]
            min_x = max_x = x
            min_y = max_y = y
            area = 0

            while queue:
                current_x, current_y = queue.pop()
                area += 1
                min_x = min(min_x, current_x)
                min_y = min(min_y, current_y)
                max_x = max(max_x, current_x)
                max_y = max(max_y, current_y)

                for next_x, next_y in (
                    (current_x + 1, current_y),
                    (current_x - 1, current_y),
                    (current_x, current_y + 1),
                    (current_x, current_y - 1),
                ):
                    if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
                        continue
                    next_index = next_y * width + next_x
                    if seen[next_index] or pixels[next_x, next_y] <= ALPHA_THRESHOLD:
                        continue
                    seen[next_index] = 1
                    queue.append((next_x, next_y))

            if area >= MIN_AREA:
                components.append((area, (min_x, min_y, max_x + 1, max_y + 1)))

    components.sort(key=lambda item: (item[1][1], item[1][0]))
    return components


def _room_number(path: Path) -> int:
    return int(path.stem.split("_")[1])


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for stale in OUTPUT_DIR.glob("room_*_prop_*.png"):
        stale.unlink()

    manifest: dict[str, list[dict[str, object]]] = {"rooms": []}

    for source_path in sorted(SOURCE_DIR.glob("room_*_props.png")):
        room_number = _room_number(source_path)
        image = Image.open(source_path).convert("RGBA")
        width, height = image.size
        components = _component_bounds(image.getchannel("A"), width, height)
        room_entries: list[dict[str, object]] = []

        for prop_index, (area, bounds) in enumerate(components, start=1):
            min_x, min_y, max_x, max_y = bounds
            crop_box = (
                max(0, min_x - PADDING),
                max(0, min_y - PADDING),
                min(width, max_x + PADDING),
                min(height, max_y + PADDING),
            )
            crop = image.crop(crop_box)
            output_name = f"room_{room_number:02d}_prop_{prop_index:02d}.png"
            output_path = OUTPUT_DIR / output_name
            crop.save(output_path)
            crop_width, crop_height = crop.size
            room_entries.append(
                {
                    "name": f"Room{room_number:02d}Prop{prop_index:02d}",
                    "path": f"res://assets/maps/stitched_demo/generated_props/{output_name}",
                    "source": source_path.name,
                    "source_rect": [crop_box[0], crop_box[1], crop_width, crop_height],
                    "size": [crop_width, crop_height],
                    "opaque_area": area,
                }
            )

        manifest["rooms"].append(
            {
                "room": room_number - 1,
                "source": source_path.name,
                "source_size": [width, height],
                "props": room_entries,
            }
        )
        print(f"{source_path.name}: extracted {len(room_entries)} props")

    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
