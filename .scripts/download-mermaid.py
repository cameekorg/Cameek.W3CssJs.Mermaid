#!/usr/bin/env python3
"""Refresh the pinned Mermaid browser distribution from its verified npm archive."""

from collections import deque
from pathlib import Path, PurePosixPath
import base64
import hashlib
import io
import json
import posixpath
import re
import shutil
import tarfile
import tempfile
import urllib.request

VERSION = "11.17.2"
PROJECT = Path(__file__).resolve().parent.parent
ENTRYPOINTS = ("mermaid.min.js", "mermaid.esm.min.mjs", "mermaid.core.mjs")
IMPORTS = re.compile(r'''(?:\b(?:from|import)\s*|\bimport\s*\(\s*)["'](\.{1,2}/[^"'\\\s]+)["']''')
SOURCE_MAP = re.compile(r"(?://[#@]|/\*[#@])\s*sourceMappingURL=([^\s*]+)")


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "Cameek.W3CssJs.Mermaid asset updater"})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def main():
    metadata = json.loads(fetch(f"https://registry.npmjs.org/mermaid/{VERSION}"))
    if metadata["name"] != "mermaid" or metadata["version"] != VERSION:
        raise RuntimeError("The npm registry returned an unexpected package/version.")
    archive_url = metadata["dist"]["tarball"]
    if not archive_url.startswith("https://registry.npmjs.org/mermaid/-/"):
        raise RuntimeError("Unexpected Mermaid archive origin.")
    archive_bytes = fetch(archive_url)
    integrity = "sha512-" + base64.b64encode(hashlib.sha512(archive_bytes).digest()).decode("ascii")
    if integrity not in metadata["dist"]["integrity"].split():
        raise RuntimeError("Mermaid npm archive failed SHA-512 integrity verification.")

    # Stage the complete archive before changing packaged files. Never extract links or
    # arbitrary archive paths, and copy only the browser entrypoints' dependency closure.
    with tempfile.TemporaryDirectory(prefix="cameek-mermaid-") as directory:
        temporary = Path(directory)
        distribution = temporary / "distribution"
        distribution.mkdir()
        license_bytes = None
        with tarfile.open(fileobj=io.BytesIO(archive_bytes), mode="r|gz") as archive:
            for member in archive:
                if not member.isfile():
                    continue
                if member.name == "package/LICENSE":
                    license_bytes = archive.extractfile(member).read()
                if not member.name.startswith("package/dist/"):
                    continue
                relative = PurePosixPath(member.name.removeprefix("package/dist/"))
                if relative.is_absolute() or ".." in relative.parts:
                    raise RuntimeError("Unsafe path in the Mermaid archive.")
                if relative.suffix not in {".js", ".mjs", ".map", ".css", ".wasm", ".woff", ".woff2", ".ttf", ".otf"}:
                    continue
                destination = distribution.joinpath(*relative.parts)
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(archive.extractfile(member).read())
        if not license_bytes or b"MIT" not in license_bytes:
            raise RuntimeError("Mermaid's MIT license was not found in the package.")

        pending = deque(ENTRYPOINTS)
        selected = set()
        while pending:
            relative = pending.popleft()
            if relative in selected:
                continue
            source = distribution / relative
            if not source.is_file():
                raise RuntimeError(f"Missing Mermaid runtime dependency: {relative}")
            selected.add(relative)
            if source.suffix not in {".js", ".mjs", ".css"}:
                continue
            content = source.read_text(encoding="utf-8")
            references = IMPORTS.findall(content) + SOURCE_MAP.findall(content)
            for reference in references:
                if reference.startswith("data:"):
                    continue
                dependency = posixpath.normpath(posixpath.join(posixpath.dirname(relative), reference))
                if dependency.startswith("../") or dependency.startswith("/"):
                    raise RuntimeError(f"Dependency escapes the distribution: {reference}")
                pending.append(dependency)

        staged = temporary / "js"
        staged.mkdir()
        for relative in sorted(selected):
            destination = staged / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(distribution / relative, destination)

        target = PROJECT / "wwwroot" / "js"
        target.mkdir(parents=True, exist_ok=True)
        # Only these upstream-owned paths are refreshed; application files are preserved.
        if (target / "chunks").exists():
            shutil.rmtree(target / "chunks")
        for child in staged.iterdir():
            destination = target / child.name
            if child.is_dir():
                shutil.copytree(child, destination)
            else:
                shutil.copyfile(child, destination)
        (PROJECT / "wwwroot" / "LICENSE-mermaid.txt").write_bytes(license_bytes)

    print(f"Downloaded Mermaid {VERSION}: {len(selected)} runtime files plus the MIT license.")
    print(f"Source: {archive_url}")
    print(f"Verified integrity: {integrity}")


if __name__ == "__main__":
    main()
