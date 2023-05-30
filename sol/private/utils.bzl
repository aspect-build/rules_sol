"""Utilities"""

def normalize_version_string(str):
    return str.replace(".", "_")

def semver_cmp(a, b):
    """Compares semantic version strings.

    Args:
      a: left-hand-side semantic version string for comparison.
      b: right-hand-side semantic version string for comparison.

    Returns:
      -1 if a < b; 1 if a > b; and 0 if a == b
    """
    a = a.split(".")
    b = b.split(".")
    for i, v in enumerate(a):
        if v < b[i]:
            return -1
        if v > b[i]:
            return 1
    return 0
