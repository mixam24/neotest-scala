test:
    ./scripts/test

run-scala2-project-tests:
    #!/usr/bin/env bash
    set -euxo pipefail

    PROJECT_DIR="{{ justfile_directory() }}/tests/data/scalatest/projects/scala2"
    OUTPUT_FILE="{{ justfile_directory() }}/tests/data/scalatest/results/scala2.log"

    cd "${PROJECT_DIR}"
    sbt bloopInstall
    bloop test -p scala2 -- -fJ "${OUTPUT_FILE}" >> /dev/null 2>&1 || [ $? -eq 32 ]
