#! /usr/bin/env sh
SHORT_HASH=$(git rev-parse --short HEAD)
HASH=$(git rev-parse HEAD)

echo "<a href=\"{{ config.extra.repo | safe }}/tree/$HASH\">$SHORT_HASH</a>" > templates/commit.html