#!/usr/bin/env bash
set -euo pipefail
REPO_DIR=/srv/cha-repo/x86_64
mkdir -p "$REPO_DIR"
cp ./*.pkg.tar.zst "$REPO_DIR/"
repo-add -R "$REPO_DIR/cha-repo.db.tar.gz" "$REPO_DIR"/*.pkg.tar.zst
echo "repo updated: $REPO_DIR"
