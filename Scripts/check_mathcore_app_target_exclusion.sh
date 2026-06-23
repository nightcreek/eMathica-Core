#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PBXPROJ_PATH="${ROOT_DIR}/eMathica.xcodeproj/project.pbxproj"

if [[ ! -f "${PBXPROJ_PATH}" ]]; then
  echo "[app-exclusion-check] missing project file: ${PBXPROJ_PATH}"
  exit 1
fi

echo "[app-exclusion-check] validating package linkage and app exclusion guards..."

assert_contains() {
  local pattern="$1"
  local label="$2"
  if ! grep -Fq "$pattern" "${PBXPROJ_PATH}"; then
    echo "[app-exclusion-check] missing ${label}: ${pattern}"
    exit 1
  fi
}

# 1) local package dependency + product linkage should exist.
assert_contains 'relativePath = Packages/EMathicaMathCore;' "local package reference"
assert_contains 'productName = EMathicaMathCore;' "package product dependency"

# 2) app target exclusion should guard old local pure-logic MathCore directories.
assert_contains 'EXCLUDED_SOURCE_FILE_NAMES = (' "EXCLUDED_SOURCE_FILE_NAMES block"
assert_contains '"MathCore/SemanticCore/*"' "SemanticCore exclusion"
assert_contains '"MathCore/CASCore/*"' "CASCore exclusion"
assert_contains '"MathCore/EvaluationCore/*"' "EvaluationCore exclusion"
assert_contains '"MathCore/GraphCore/*"' "GraphCore exclusion"
assert_contains '"MathCore/SamplingCore/*"' "SamplingCore exclusion"

echo "[app-exclusion-check] passed"
