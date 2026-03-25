#!/bin/bash
case "$1" in
    Username*) echo "x-token-auth" ;;
    Password*) echo "$GIT_WORKSPACE_TOKEN" ;;
esac
