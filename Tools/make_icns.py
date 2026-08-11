#!/usr/bin/env python3
"""Package PNG icon representations into a modern macOS ICNS container."""

from pathlib import Path
import struct
import sys


CHUNKS = (
    (b"ic04", "icon_16x16.png"),
    (b"ic11", "icon_16x16@2x.png"),
    (b"ic05", "icon_32x32.png"),
    (b"ic12", "icon_32x32@2x.png"),
    (b"ic07", "icon_128x128.png"),
    (b"ic13", "icon_128x128@2x.png"),
    (b"ic08", "icon_256x256.png"),
    (b"ic14", "icon_256x256@2x.png"),
    (b"ic09", "icon_512x512.png"),
    (b"ic10", "icon_512x512@2x.png"),
)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: make_icns.py <iconset-directory> <output.icns>")

    iconset = Path(sys.argv[1])
    output = Path(sys.argv[2])
    payload = bytearray()

    for chunk_type, filename in CHUNKS:
        data = (iconset / filename).read_bytes()
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise ValueError(f"{filename} is not a PNG file")
        payload.extend(chunk_type)
        payload.extend(struct.pack(">I", len(data) + 8))
        payload.extend(data)

    output.write_bytes(b"icns" + struct.pack(">I", len(payload) + 8) + payload)
    print(f"Created: {output}")


if __name__ == "__main__":
    main()
