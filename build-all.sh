#!/bin/bash
# Builds all Docker images this project provides
# Arguments:
#   BUILD:     The release to build.
#              Allowed: release, prerelease, branches, special
#              Default: undefined

echo "▶️ $0 $*"

ALL_BUILDS=("release" "prerelease" "branches" "special")
BUILDS=("${BUILD:-"${ALL_BUILDS[@]}"}")

echo "⚙️ Configured builds: ${BUILDS[*]}"

VARIANTS=("main" "ldap")

if [ -n "${DEBUG}" ]; then
  export DEBUG
fi

ERROR=0

# Don't build if not on `master` and don't build if on a pull request,
# but build when DEBUG is not empty
for VARIANT in "${VARIANTS[@]}"; do
  export VARIANT

  # Checking which VARIANT to build
  if [ "${VARIANT}" == "main" ]; then
    DOCKERFILE="${DOCKERFILE_PATH-Dockerfile}"
  else
    DOCKERFILE="${DOCKERFILE_PATH-Dockerfile}.${VARIANT}"

    # Fail fast
    if [ ! -f "${DOCKERFILE}" ]; then
      echo "🚨 The Dockerfile '${DOCKERFILE}' for variant '${VARIANT}' doesn't exist."
      ERROR=1

      if [ -z "$DEBUG" ]; then
        continue
      else
        echo "⚠️ Would skip this, but DEBUG is enabled."
      fi
    fi
  fi

  for BUILD in "${BUILDS[@]}"; do
    echo "🛠 Building '$BUILD' from '$DOCKERFILE'"
    case $BUILD in
      release)
        # build the latest release
        # shellcheck disable=SC2068
        ./build-latest.sh $@ || ERROR=1
        ;;
      prerelease)
        # build the latest pre-release
        # shellcheck disable=SC2068
        PRERELEASE=true ./build-latest.sh $@ || ERROR=1
        ;;
      branches)
        # build all branches
        # shellcheck disable=SC2068
        ./build-branches.sh $@ || ERROR=1
        ;;
      special)
        # special build
        # shellcheck disable=SC2068
        #SRC_ORG=lampwins TAG=webhooks-backend ./build.sh "feature/webhooks-backend" $@ || ERROR=1
        echo "✅ No special builds today."
        ;;
      *)
        echo "🚨 Unrecognized build '$BUILD'."

        if [ -z "$DEBUG" ]; then
          exit 1
        else
          echo "⚠️ Would exit here with code '1', but DEBUG is enabled."
        fi
        ;;
    esac
  done
done

exit $ERROR
