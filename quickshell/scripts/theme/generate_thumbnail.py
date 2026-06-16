#!/usr/bin/env python3

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

THUMBNAIL_TIMEOUT_SECONDS = 8


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: generate_thumbnail.py INPUT_IMAGE OUTPUT_IMAGE [WIDTH] [HEIGHT]", file=sys.stderr)
        return 1

    input_path = Path(sys.argv[1]).expanduser()
    output_path = Path(sys.argv[2]).expanduser()
    width = sys.argv[3] if len(sys.argv) > 3 else "320"
    height = sys.argv[4] if len(sys.argv) > 4 else "180"

    output_path.parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        "magick",
        str(input_path),
        "-auto-orient",
        "-thumbnail",
        f"{width}x{height}^",
        "-gravity",
        "center",
        "-extent",
        f"{width}x{height}",
        "-strip",
        str(output_path),
    ]

    env = os.environ.copy()
    env.setdefault("MAGICK_MEMORY_LIMIT", "128MiB")
    env.setdefault("MAGICK_MAP_LIMIT", "256MiB")

    try:
        subprocess.run(cmd, check=True, env=env, timeout=THUMBNAIL_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        print(f"thumbnail timed out after {THUMBNAIL_TIMEOUT_SECONDS}s: {input_path}", file=sys.stderr)
        return 124

    print(output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
