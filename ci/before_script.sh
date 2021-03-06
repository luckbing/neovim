#!/usr/bin/env bash

set -e
set -o pipefail

CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CI_DIR}/common/build.sh"

# Enable ipv6 on Travis. ref: a39c8b7ce30d
if ! test "${TRAVIS_OS_NAME}" = osx ; then
  echo "before_script.sh: enable ipv6"
  sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=0
fi

# Test some of the configuration variables.
if [[ -n "${GCOV}" ]] && [[ ! $(type -P "${GCOV}") ]]; then
  echo "\$GCOV: '${GCOV}' is not executable."
  exit 1
fi
if [[ -n "${LLVM_SYMBOLIZER}" ]] && [[ ! $(type -P "${LLVM_SYMBOLIZER}") ]]; then
  echo "\$LLVM_SYMBOLIZER: '${LLVM_SYMBOLIZER}' is not executable."
  exit 1
fi

echo "before_script.sh: ccache stats (will be cleared)"
ccache -s
# Reset ccache stats for real results in before_cache.
ccache --zero-stats

if [[ "${TRAVIS_OS_NAME}" == osx ]]; then
  # Adds user to a dummy group.
  # That allows to test changing the group of the file by `os_fchown`.
  sudo dscl . -create /Groups/chown_test
  sudo dscl . -append /Groups/chown_test GroupMembership "${USER}"
fi

# Compile dependencies.
build_deps

# Install cluacov for Lua coverage.
if [[ "$USE_LUACOV" == 1 ]]; then
  "${DEPS_BUILD_DIR}/usr/bin/luarocks" install cluacov
fi

rm -rf "${LOG_DIR}"
mkdir -p "${LOG_DIR}"
