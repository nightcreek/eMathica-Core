#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/private/tmp/eMathicaDD}"
SCHEME="${SCHEME:-eMathica}"
CHECK_SYNC_SCRIPT="${ROOT_DIR}/Scripts/check_mathcore_package_sync.sh"
CHECK_APP_EXCLUSION_SCRIPT="${ROOT_DIR}/Scripts/check_mathcore_app_target_exclusion.sh"
PACKAGE_DIR="${ROOT_DIR}/Packages/EMathicaMathCore"

echo "[BuildVerification] root=${ROOT_DIR}"
echo "[BuildVerification] scheme=${SCHEME}"
echo "[BuildVerification] derivedData=${DERIVED_DATA_PATH}"

cd "${ROOT_DIR}"

run_step() {
  local title="$1"
  shift
  echo
  echo "== ${title} =="
  echo "+ $*"
  if "$@"; then
    echo "[OK] ${title}"
    return 0
  else
    local code=$?
    echo "[FAIL] ${title} (exit ${code})"
    return ${code}
  fi
}

echo
echo "Step 1/4: app/package MathCore sync check"
if [[ ! -x "${CHECK_SYNC_SCRIPT}" ]]; then
  echo "[FAIL] missing or non-executable script: ${CHECK_SYNC_SCRIPT}"
  exit 1
fi
run_step "check_mathcore_package_sync.sh" "${CHECK_SYNC_SCRIPT}"

echo
echo "Step 2/4: app target exclusion/package linkage check"
if [[ ! -x "${CHECK_APP_EXCLUSION_SCRIPT}" ]]; then
  echo "[FAIL] missing or non-executable script: ${CHECK_APP_EXCLUSION_SCRIPT}"
  exit 1
fi
run_step "check_mathcore_app_target_exclusion.sh" "${CHECK_APP_EXCLUSION_SCRIPT}"

echo
echo "Step 3/4: package logic tests (swift test)"
if [[ ! -d "${PACKAGE_DIR}" ]]; then
  echo "[FAIL] missing package dir: ${PACKAGE_DIR}"
  exit 1
fi
run_step "swift test (EMathicaMathCore)" \
  bash -lc "cd \"${PACKAGE_DIR}\" && swift test"

echo
echo "Step 4/4: app compilation (build + build-for-testing)"
echo "Step 4.1: build"
run_step "xcodebuild build" \
  xcodebuild \
  -scheme "${SCHEME}" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  build

echo
echo "Step 4.2: build-for-testing"
echo "Note: this does NOT execute tests, but still compiles test targets."
set +e
xcodebuild \
  -scheme "${SCHEME}" \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing
BUILD_FOR_TESTING_CODE=$?
set -e

if [[ ${BUILD_FOR_TESTING_CODE} -eq 0 ]]; then
  echo "[OK] build-for-testing succeeded."
  exit 0
fi

echo
echo "[WARN] build-for-testing failed with exit ${BUILD_FOR_TESTING_CODE}."
echo "Common causes in this environment:"
echo "  1) CoreSimulator runtime missing/unavailable (actool/ibtool errors: 'No available simulator runtimes')."
echo "  2) Xcode DerivedData permission issues."
echo "  3) Signing/provisioning issues for non-simulator destinations."
echo
echo "Suggested local checks:"
echo "  - Open Xcode > Settings > Platforms, ensure iOS Simulator runtime is installed."
echo "  - Ensure DerivedData path is writable: ${DERIVED_DATA_PATH}"
echo "  - Re-run this script after simulator runtime is restored."
exit ${BUILD_FOR_TESTING_CODE}
