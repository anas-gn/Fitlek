#!/usr/bin/env python3
"""Bulk-migrate legacy hardcoded colors to theme-aware tokens."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib"

SKIP = {
    "app_colors.dart",
    "app_theme.dart",
    "fitlek_theme_extension.dart",
    "theme_service.dart",
    "theme_selector.dart",
    "fitlek_logo.dart",
    "colors.dart",
}

COLOR_CONST_PATTERNS = [
    r"^const _lime\s*=.*\n",
    r"^const _limeDark\s*=.*\n",
    r"^const _dark\s*=.*\n",
    r"^const _darkElev2\s*=.*\n",
    r"^const _darkElev3\s*=.*\n",
    r"^const _card\s*=.*\n",
    r"^const _cardBorder\s*=.*\n",
    r"^const _card2\s*=.*\n",
    r"^const _border\s*=.*\n",
    r"^const _textPrimary\s*=.*\n",
    r"^const _textSecondary\s*=.*\n",
    r"^const _textMuted\s*=.*\n",
    r"^const _muted\s*=.*\n",
    r"^const _white\s*=.*\n",
    r"^const _success\s*=.*\n",
    r"^const _errorRed\s*=.*\n",
    r"^const _error\s*=.*\n",
]

REPLACEMENTS = [
    (r"Color\(0xFFC6F135\)", "Theme.of(context).colorScheme.primary"),
    (r"Color\(0xFFA3FF12\)", "Theme.of(context).colorScheme.primary"),
    (r"Color\(0xFF9BC420\)", "Theme.of(context).colorScheme.primary"),
    (r"Color\(0xFFD1F96B\)", "Theme.of(context).colorScheme.primary"),
    (r"\b_lime\b", "Theme.of(context).colorScheme.primary"),
    (r"\b_limeDark\b", "Theme.of(context).colorScheme.primary"),
    (r"\b_darkElev3\b", "context.fitlek.card2"),
    (r"\b_darkElev2\b", "context.fitlek.card"),
    (r"\b_card2\b", "context.fitlek.card2"),
    (r"\b_cardBorder\b", "context.fitlek.border"),
    (r"\b_card\b", "context.fitlek.card"),
    (r"\b_border\b", "context.fitlek.border"),
    (r"\b_textPrimary\b", "Theme.of(context).colorScheme.onSurface"),
    (r"\b_textSecondary\b", "context.fitlek.textSecondary"),
    (r"\b_textMuted\b", "context.fitlek.textMuted"),
    (r"\b_muted\b", "context.fitlek.textMuted"),
    (r"\b_white\b", "Theme.of(context).colorScheme.onPrimary"),
    (r"\b_success\b", "context.fitlek.success"),
    (r"\b_errorRed\b", "context.fitlek.error"),
    (r"\b_error\b", "context.fitlek.error"),
    (r"\b_dark\b", "Theme.of(context).scaffoldBackgroundColor"),
    (r"backgroundColor:\s*Colors\.black", "backgroundColor: Theme.of(context).scaffoldBackgroundColor"),
    (r"const Scaffold\(\s*backgroundColor:\s*Colors\.black", "Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor"),
    (r"CircularProgressIndicator\(color:\s*Color\(0xFFC6F135\)\)", "CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)"),
    (r"CircularProgressIndicator\(color:\s*Color\(0xFFA3FF12\)\)", "CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)"),
]

IMPORT_SNIPPET = "import '{path}theme/fitlek_theme_extension.dart';\n"


def import_path(file_path: Path) -> str:
    rel = file_path.relative_to(ROOT)
    depth = len(rel.parts) - 1
    return "../" * depth


def needs_migration(text: str) -> bool:
    markers = ["const _lime", "Color(0xFFC6F135)", "Color(0xFFA3FF12)", "const _dark", "Colors.black", "class FitlekColors {"]
    return any(m in text for m in markers)


def migrate_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    if not needs_migration(path.name in SKIP and "" or text):
        if path.name in SKIP:
            return False
        if not needs_migration(text):
            return False

    original = text

    for pat in COLOR_CONST_PATTERNS:
        text = re.sub(pat, "", text, flags=re.MULTILINE)

    if "fitlek_theme_extension.dart" not in text:
        imp = IMPORT_SNIPPET.format(path=import_path(path))
        # insert after last import
        imports = list(re.finditer(r"^import .+;\n", text, re.MULTILINE))
        if imports:
            pos = imports[-1].end()
            text = text[:pos] + imp + text[pos:]
        else:
            text = imp + text

    for old, new in REPLACEMENTS:
        text = re.sub(old, new, text)

    # Remove duplicate local FitlekColors class in coachProfile (handled separately)
    if path.name == "coachProfile.dart" and "class FitlekColors {" in text:
        text = re.sub(
            r"class FitlekColors \{[\s\S]*?\}\n\n",
            "",
            text,
            count=1,
        )
        text = text.replace("FitlekColors.", "context.fitlek.")
        text = text.replace("context.fitlek.bg", "Theme.of(context).scaffoldBackgroundColor")
        text = text.replace("context.fitlek.lime", "Theme.of(context).colorScheme.primary")
        text = text.replace("context.fitlek.limeDim", "context.fitlek.primaryDim")
        text = text.replace("context.fitlek.textPrimary", "Theme.of(context).colorScheme.onSurface")

    if text != original:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main():
    changed = []
    for path in sorted(ROOT.rglob("*.dart")):
        if path.name in SKIP:
            continue
        if migrate_file(path):
            changed.append(str(path.relative_to(ROOT.parent)))
    print(f"Migrated {len(changed)} files:")
    for c in changed:
        print(f"  - {c}")


if __name__ == "__main__":
    main()
