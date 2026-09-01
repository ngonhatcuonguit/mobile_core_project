#!/usr/bin/env bash

# Shared Flutter/Gradle environment for this machine. Keeping generated data on
# the project volume prevents macOS system-temp failures when the root disk is
# nearly full.
FLUTTER_PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p \
  "$FLUTTER_PROJECT_ROOT/.tmp/gradle" \
  "$FLUTTER_PROJECT_ROOT/.project_pub_cache" \
  "$FLUTTER_PROJECT_ROOT/.project_gradle" \
  "$FLUTTER_PROJECT_ROOT/.project_cocoapods" \
  "$FLUTTER_PROJECT_ROOT/.project_user_home"

export TMPDIR="$FLUTTER_PROJECT_ROOT/.tmp"
export PUB_CACHE="$FLUTTER_PROJECT_ROOT/.project_pub_cache"
export GRADLE_USER_HOME="$FLUTTER_PROJECT_ROOT/.project_gradle"
export CP_HOME_DIR="$FLUTTER_PROJECT_ROOT/.project_cocoapods"
export COCOAPODS_DISABLE_STATS=true
export JAVA_TOOL_OPTIONS="-Xshare:off -Duser.home=$FLUTTER_PROJECT_ROOT/.project_user_home -Djava.io.tmpdir=$FLUTTER_PROJECT_ROOT/.tmp/gradle -Dkotlin.compiler.execution.strategy=in-process ${JAVA_TOOL_OPTIONS:-}"
