java-home := "/usr/lib/jvm/java-11-openjdk-amd64/"

test:
    ./scripts/test

run-scalatest-project-tests runner='bloop':
    #!/usr/bin/env bash
    set -euxo pipefail

    PROJECT_DIR="{{ justfile_directory() }}/tests/data/scalatest/projects/scala2"
    OUTPUT_FILE="{{ justfile_directory() }}/tests/data/scalatest/results/scala2.log"

    cd "${PROJECT_DIR}"
    if [ "{{runner}}" == "sbt" ]
    then
      sbt -java-home "{{java-home}}" test -- -fJ "${OUTPUT_FILE}" >> /dev/null 2>&1 || [ $? -eq 1 ]
    else
      sbt -java-home "{{java-home}}" bloopInstall
      bloop test -p scala2 -- -fJ "${OUTPUT_FILE}" >> /dev/null 2>&1 || [ $? -eq 32 ]
    fi

run-munit-project-tests runner='bloop':
    #!/usr/bin/env bash
    set -euxo pipefail

    PROJECT_DIR="{{ justfile_directory() }}/tests/data/munit/projects/scala2"
    OUTPUT_FILE="{{ justfile_directory() }}/tests/data/munit/results/scala2.log"

    cd "${PROJECT_DIR}"
    if [ "{{runner}}" == "sbt" ]
    then
      sbt -java-home "{{java-home}}" test -- -c -F &> "${OUTPUT_FILE}" || [ $? -eq 1 ]
    else
      sbt -java-home "{{java-home}}" bloopInstall
      bloop test -p scala2 -- -c -F &> "${OUTPUT_FILE}" || [ $? -eq 32 ]
    fi
