#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

set -x

sum=$(
  echo '```text'
  cut -c -71 < stdout.txt
  echo '```'
  echo
  echo "The results were calculated in [this GHA job][benchmark-gha]"
  echo "on $(date +'%Y-%m-%d') at $(date +'%H:%M'),"
  echo "on $(uname) with $(nproc --all) CPUs."
)

export sum

perl -i -0777 -pe 's/(?<=<!-- benchmark_begin -->).*(?=<!-- benchmark_end -->)/\n$ENV{sum}\n/gs;' README.md
url=${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}

export url
perl -i -0777 -pe 's/(?<=\[benchmark-gha\]: )[^\n]+(?=\n)/$ENV{url}/gs;' README.md
rm stdout.txt
