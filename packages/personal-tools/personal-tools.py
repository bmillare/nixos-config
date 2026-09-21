"""Personal file launchers. Menu values are indices, never shell commands."""

import os
from pathlib import Path
import subprocess
import sys


def choose(menu, prompt, rows, description):
    # Keep the line-oriented menu protocol separate from actual filenames.
    labels = [label.replace("\n", " ↵ ").replace("\r", " ").replace("\t", " ")
              for label in rows]
    result = subprocess.run(
        [menu, "-p", prompt, "-d", description],
        input="".join(f"{label}\t{i}\n" for i, label in enumerate(labels)),
        text=True, capture_output=True, check=False,
    )
    if result.returncode == 1:
        return None
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "File menu failed")
    return int(result.stdout.strip())


def main():
    menu, client, editor = sys.argv[1:4]
    action = choose(menu, "Personal tools", ["Find Org file", "Find Markdown file"],
                    "Search ~/projects · newest files first")
    if action is None:
        return

    root = Path.home() / "projects"
    extensions = {".org"} if action == 0 else {".md", ".markdown"}
    files = []

    def report_error(error):
        print(f"personal-tools: {error}", file=sys.stderr)

    # No depth limit or ignore rules; do not descend through directory symlinks.
    for directory, _, names in os.walk(root, onerror=report_error):
        for name in names:
            path = Path(directory) / name
            if path.suffix.lower() in extensions:
                try:
                    if path.is_file():
                        files.append((path.stat().st_mtime_ns, path))
                except OSError as error:
                    report_error(error)

    files.sort(key=lambda item: (-item[0], str(item[1])))
    labels = [str(path.relative_to(root)) for _, path in files]
    if not files:
        choose(menu, "No files found", ["Close"], f"No matching files in {root}")
        return
    selected = choose(menu, "Org files" if action == 0 else "Markdown files",
                      labels, f"{root} · newest files first")
    if selected is not None:
        subprocess.run([client, "--no-wait", "--reuse-frame",
                        f"--alternate-editor={editor}", "--", str(files[selected][1])],
                       check=True)


if __name__ == "__main__":
    main()
