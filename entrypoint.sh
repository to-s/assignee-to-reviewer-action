#!/bin/bash
set -eu

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_NAME" ]]; then
  echo "Set the GITHUB_EVENT_NAME env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

API_HEADER="Accept: application/vnd.github.v3+json; application/vnd.github.antiope-preview+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
assignee=$(jq --raw-output .assignee.login "$GITHUB_EVENT_PATH")

set_comment() {
  curl -sSL \
    -H "Content-Type: application/json" \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X POST \
    -d "{\"body\":\"$1\"}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/comments"
}

update_review_request() {
  echo -sSL \
    -H "Content-Type: application/json" \
    -H "${AUTH_HEADER}" \
    -H "${API_HEADER}" \
    -X $1 \
    -d "{\"reviewers\":[\"${assignee}\"]}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${number}/requested_reviewers"
}

if [[ "$action" == "assigned" ]]; then
  update_review_request 'POST'
  set_comment "assigned ${assignee}"
elif [[ "$action" == "unassigned" ]]; then
  update_review_request 'DELETE'
  set_comment "unassigned ${assignee}"
else
  echo "Ignoring action ${action}"
  exit 0
fi
