#!/usr/bin/env bash
# Create a Markdown snapshot of a Spring Boot project.
# Usage:
#   ./snapshot.sh [project-root] [output-file]
# Examples:
#   ./snapshot.sh
#   ./snapshot.sh /path/to/my-spring-project
#   ./snapshot.sh . docs/project-snapshot.md

set -Eeuo pipefail

PROJECT_ROOT="${1:-.}"
OUTPUT_FILE="${2:-project-snapshot.md}"

if [[ ! -d "$PROJECT_ROOT" ]]; then
  printf 'Error: project directory does not exist: %s\n' "$PROJECT_ROOT" >&2
  exit 1
fi

# Resolve the project root before changing directories.
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

# If output is relative, place it relative to the current working directory.
if [[ "$OUTPUT_FILE" != /* ]]; then
  OUTPUT_FILE="$(pwd)/$OUTPUT_FILE"
fi

# Avoid accidentally including the output snapshot if it lives inside the project.
OUTPUT_FILE="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$OUTPUT_FILE")"
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Files/directories to skip. These commonly contain generated files, dependencies,
# VCS metadata, IDE state, or local secrets.
should_skip_path() {
  local rel="$1"
  case "/$rel/" in
    */.git/*|*/.idea/*|*/.vscode/*|*/.gradle/*|*/.mvn/wrapper/*|*/target/*|*/build/*|*/out/*|*/node_modules/*|*/dist/*|*/coverage/*|*/.next/*|*/vendor/*|*/logs/*|*/tmp/*|*/temp/*)
      return 0 ;;
  esac

  local base
  base="${rel##*/}"

  # Skip environment files and common secret/key/certificate files.
  case "$base" in
    .env|.env.*|application-local.*|application-secret.*|secrets.*|*.pem|*.key|*.p12|*.pfx|*.jks|id_rsa|id_ed25519)
      return 0 ;;
  esac

  # Skip common binary/archive/image/media files.
  case "${base,,}" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.pdf|*.zip|*.jar|*.war|*.class|*.so|*.dylib|*.dll|*.exe|*.bin|*.dat|*.mp4|*.mov|*.mp3|*.wav|*.woff|*.woff2|*.ttf|*.otf)
      return 0 ;;
  esac

  return 1
}

# Prefer Python for reliable Markdown escaping and file handling, while keeping
# this as a shell script that can be run directly.
python3 - "$PROJECT_ROOT" "$OUTPUT_FILE" <<'PY'
import os
import sys
from datetime import datetime
from pathlib import Path

root = Path(sys.argv[1]).resolve()
output = Path(sys.argv[2]).resolve()

skip_dirs = {
    ".git", ".idea", ".vscode", ".gradle", "target", "build", "out",
    "node_modules", "dist", "coverage", ".next", "vendor", "logs", "tmp", "temp",
}
skip_names = {
    ".env", ".env.local", ".env.development", ".env.production",
    "application-local.properties", "application-local.yml", "application-local.yaml",
    "application-secret.properties", "application-secret.yml", "application-secret.yaml",
    "secrets.properties", "secrets.yml", "secrets.yaml",
}
skip_suffixes = {
    ".pem", ".key", ".p12", ".pfx", ".jks", ".class", ".jar", ".war",
    ".so", ".dylib", ".dll", ".exe", ".bin", ".dat", ".png", ".jpg",
    ".jpeg", ".gif", ".webp", ".ico", ".pdf", ".zip", ".mp4", ".mov",
    ".mp3", ".wav", ".woff", ".woff2", ".ttf", ".otf",
}
text_suffixes = {
    ".java", ".kt", ".groovy", ".xml", ".yml", ".yaml", ".properties",
    ".json", ".sql", ".md", ".txt", ".gradle", ".kts", ".sh", ".bash",
    ".bat", ".cmd", ".ps1", ".html", ".htm", ".css", ".js", ".ts",
    ".tsx", ".jsx", ".properties", ".conf", ".config", ".gitignore",
    ".dockerignore", ".editorconfig", ".toml", ".graphql", ".gql",
    ".http", ".feature", ".mustache", ".ftl", ".jsp", ".tag",
}
special_names = {
    "pom.xml", "mvnw", "gradlew", "Dockerfile", "Makefile",
    "Procfile", "Jenkinsfile", ".gitignore", ".dockerignore",
    ".editorconfig", "README", "README.md",
}

def skip_file(path: Path) -> bool:
    rel = path.relative_to(root)
    parts = rel.parts
    if any(part in skip_dirs for part in parts):
        return True
    name = path.name
    lower = name.lower()
    if name in skip_names or lower == ".env" or lower.startswith(".env."):
        return True
    if lower in {"application-local.properties", "application-local.yml", "application-local.yaml",
                 "application-secret.properties", "application-secret.yml", "application-secret.yaml"}:
        return True
    if path.suffix.lower() in skip_suffixes:
        return True
    if name in {"id_rsa", "id_ed25519"}:
        return True
    # Exclude the output file itself if it is inside the project.
    try:
        if path.resolve() == output:
            return True
    except OSError:
        pass
    return False

files = []
for current, dirs, filenames in os.walk(root):
    current_path = Path(current)
    dirs[:] = sorted(d for d in dirs if d not in skip_dirs and not d.startswith("."))
    for filename in sorted(filenames):
        path = current_path / filename
        if skip_file(path):
            continue
        # Snapshot likely source/config/documentation files only, avoiding huge
        # or opaque assets and arbitrary local data.
        if path.name not in special_names and path.suffix.lower() not in text_suffixes:
            continue
        try:
            if not path.is_file() or path.stat().st_size > 1_000_000:
                continue
        except OSError:
            continue
        files.append(path)

files.sort(key=lambda p: p.relative_to(root).as_posix().lower())

with output.open("w", encoding="utf-8") as out:
    out.write("# Spring Boot Project Snapshot\n\n")
    out.write(f"- **Project root:** `{root}`\n")
    out.write(f"- **Generated at:** {datetime.now().astimezone().isoformat(timespec='seconds')}\n")
    out.write(f"- **Files included:** {len(files)}\n\n")
    out.write("> Generated by `snapshot.sh`. Build output, dependencies, VCS/IDE folders, binary files, ")
    out.write("and common local secret files are excluded. Review the result before sharing it.\n\n")

    out.write("## Project file tree\n\n```text\n")
    for path in files:
        rel = path.relative_to(root).as_posix()
        out.write(rel + "\n")
    out.write("```\n\n")

    for path in files:
        rel = path.relative_to(root).as_posix()
        try:
            content = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue

        # Use a longer fence than any backtick run in the file so content stays intact.
        longest = 0
        run = 0
        for char in content:
            if char == "`":
                run += 1
                longest = max(longest, run)
            else:
                run = 0
        fence = "`" * max(3, longest + 1)

        suffix = path.suffix.lower()
        lang = {
            ".java": "java", ".kt": "kotlin", ".xml": "xml",
            ".yml": "yaml", ".yaml": "yaml", ".properties": "properties",
            ".json": "json", ".sql": "sql", ".md": "markdown",
            ".gradle": "groovy", ".kts": "kotlin", ".sh": "bash",
            ".bash": "bash", ".html": "html", ".htm": "html",
            ".css": "css", ".js": "javascript", ".ts": "typescript",
            ".tsx": "tsx", ".jsx": "jsx", ".toml": "toml",
            ".http": "http", ".graphql": "graphql", ".gql": "graphql",
        }.get(suffix, "")
        if path.name == "Dockerfile":
            lang = "dockerfile"
        elif path.name in {"mvnw", "gradlew"}:
            lang = "bash"

        out.write(f"## `{rel}`\n\n")
        out.write(f"{fence}{lang}\n")
        out.write(content)
        if content and not content.endswith("\n"):
            out.write("\n")
        out.write(f"{fence}\n\n")

print(f"Snapshot created: {output}")
print(f"Files included: {len(files)}")
PY
