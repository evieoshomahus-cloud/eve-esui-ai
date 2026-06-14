from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from api.eve_core.knowledge_validation import knowledge_stats, load_knowledge_file, validate_knowledge_file  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Eve ESUI knowledge-base JSON entries.")
    parser.add_argument(
        "path",
        nargs="?",
        default=str(ROOT / "knowledge" / "esui_knowledge.json"),
        help="Path to a knowledge JSON file. Defaults to knowledge/esui_knowledge.json.",
    )
    args = parser.parse_args()

    path = Path(args.path).resolve()
    result = validate_knowledge_file(path)
    entries = load_knowledge_file(path)
    stats = knowledge_stats(entries)

    print(f"Knowledge file: {path}")
    print(f"Entries: {result.entry_count}")
    print(f"Categories: {stats['categories']}")
    print(f"Audiences: {stats['audiences']}")
    print(f"Official ESUI sources: {stats['official_source_count']}")
    print(f"Curated internal entries: {stats['curated_internal_count']}")

    if result.warnings:
        print("\nWarnings:")
        for issue in result.warnings:
            print(f"- [{issue.entry_id}] {issue.field}: {issue.message}")

    if result.errors:
        print("\nErrors:")
        for issue in result.errors:
            print(f"- [{issue.entry_id}] {issue.field}: {issue.message}")
        print("\nValidation failed.")
        return 1

    print("\nValidation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
