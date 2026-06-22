#!/usr/bin/env bash
# Run all SparkRentals backend tests
#
# Per constitution §21: testing strategy — unit, integration, contract, e2e

set -e

cd "$(dirname "$0")/.."

echo "============================================================"
echo "  SparkRentals Test Suite"
echo "============================================================"
echo ""

declare -i TOTAL_PASS=0
declare -i TOTAL_FAIL=0
declare -a FAILED_TESTS=()

run_test() {
    local name="$1"
    local file="$2"
    echo "▶ $name"
    if output=$(node "$file" 2>&1); then
        local summary=$(echo "$output" | grep "=== " | tail -1)
        echo "  $summary"
        # Parse "=== N passed, M failed ===" format
        local pass=$(echo "$summary" | sed -nE 's/=== ([0-9]+) passed.*/\1/p')
        local fail=$(echo "$summary" | sed -nE 's/.*([0-9]+) failed ===/\1/p')
        pass=${pass:-0}
        fail=${fail:-0}
        TOTAL_PASS=$((TOTAL_PASS + pass))
        TOTAL_FAIL=$((TOTAL_FAIL + fail))
        if [ "$fail" -gt 0 ]; then
            FAILED_TESTS+=("$name")
        fi
    else
        echo "  ✗ FAILED TO RUN"
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        FAILED_TESTS+=("$name")
    fi
    echo ""
}

run_test "Trip Entity (domain rules)" \
    "src/modules/trips/tests/trip.entity.test.js"

run_test "Auth Entity (User, TokenPair, OtpCode)" \
    "src/modules/auth/tests/auth.entity.test.js"

run_test "Scooter Entity (state machine)" \
    "src/modules/scooters/tests/scooter.entity.test.js"

run_test "Validation helpers" \
    "src/shared/tests/validation.test.js"

run_test "Trip Controller Contract" \
    "src/modules/trips/tests/trip.controller.test.js"

run_test "Trip Repository (integration with MongoDB)" \
    "src/modules/trips/tests/trip.repository.test.js"

echo "============================================================"
echo "  SUMMARY"
echo "============================================================"
echo "  Total passed: $TOTAL_PASS"
echo "  Total failed: $TOTAL_FAIL"
if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo ""
    echo "  Failed test suites:"
    for t in "${FAILED_TESTS[@]}"; do
        echo "    ✗ $t"
    done
fi
echo "============================================================"

exit $TOTAL_FAIL
