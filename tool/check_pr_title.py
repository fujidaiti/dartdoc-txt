#!/usr/bin/env python3
import re, sys

SCOPES = {"pub", "ddb", "skill", "misc"}


def check(title: str) -> bool:
    """Check if a PR title follows the required format.

    The title must start with one or more comma-separated scopes in brackets,
    followed by a space and a sentence-case description. Valid scopes are:
    pub, ddb, skill, misc. No whitespace is allowed within the bracket section.

    Examples of valid titles:
        [pub] Add new feature
        [ddb,pub] Fix cross-references

    Returns True if the title is valid, False otherwise.
    """
    m = re.match(r"^\[([a-z,]+)\] ([A-Z])", title)
    if not m:
        return False
    scopes = m.group(1).split(",")
    return all(s in SCOPES for s in scopes)


title = sys.argv[1]
if check(title):
    sys.exit(0)

valid_scopes = ", ".join(sorted(SCOPES))
print("PR title does not follow the required format.")
print("Expected: [<scope>] Sentence case title")
print(f"Where <scope> is one or more of: {valid_scopes}, comma-separated.")
print("Example: '[pub] Add feature' or '[ddb,pub] Fix something'")
print(f"Got: {title}")
sys.exit(1)
