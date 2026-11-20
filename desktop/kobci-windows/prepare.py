"""Validate the separately built Windows server and generate the NSIS uninstall list."""

import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parent
RUNTIME = "c48ba24de230a3a59f1d490fbd77eb3a016fdbc7"
ARCHIVE_SHA256 = "2afceb1a954cacf7f56ee330daa7755308f3eed03d6e65d51fece23710968985"


def main() -> None:
    archive = ROOT / "sidecar.zip"
    with archive.open("rb") as stream:
        if hashlib.file_digest(stream, "sha256").hexdigest() != ARCHIVE_SHA256:
            raise ValueError("Windows sidecar archive differs from the tested artifact")
    payload = ROOT / "payload"
    payload.mkdir()
    with ZipFile(archive) as package:
        names = [entry.filename.rstrip("/") for entry in package.infolist()]
        if "server/openconstructionerp-server.exe" not in names:
            raise ValueError("The Windows server is absent")
        for name in names:
            parts = name.split("/")
            if parts[0] != "server" or any(p in ("", ".", "..") for p in parts):
                raise ValueError(f"Unexpected sidecar entry {name!r}")
            if (
                any(c in name for c in '\\:$"\r\n')
                or "ifc_windows" in parts
                or "ddc-ifc-to-excel" in name.lower()
            ):
                raise ValueError(f"Unexpected file in the free package: {name!r}")
        package.extractall(payload)
    files = sorted((payload / "server").rglob("*"), reverse=True)
    with (ROOT / "remove-server.nsh").open("w", encoding="utf-8-sig") as script:
        for item in files:
            path = item.relative_to(payload).as_posix().replace("/", chr(92))
            command = "RMDir" if item.is_dir() else "Delete"
            print(f'{command} "$INSTDIR\\{path}"', file=script)
        print('RMDir "$INSTDIR\\server"', file=script)
    print(
        json.dumps(
            {
                "runtime_commit": RUNTIME,
                "sidecar_sha256": ARCHIVE_SHA256,
                "entries": len(files),
            }
        )
    )


if __name__ == "__main__":
    main()
