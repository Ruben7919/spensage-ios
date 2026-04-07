#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from typing import Any

from app_store_connect_iris_sync import CookieIrisClient, load_config


def list_builds_for_version(client: CookieIrisClient, app_id: str, version: str) -> list[dict[str, Any]]:
    payload = client.get(f"/iris/v1/builds?filter[app]={app_id}&filter[version]={version}")
    return payload.get("data", [])


def attach_build_to_group(client: CookieIrisClient, build_id: str, group_id: str) -> None:
    client.request(
        "POST",
        f"/iris/v1/builds/{build_id}/relationships/betaGroups",
        {"data": [{"type": "betaGroups", "id": group_id}]},
        accept_statuses={204, 409},
    )


def fetch_beta_review_submission(client: CookieIrisClient, build_id: str) -> dict[str, Any] | None:
    payload = client.get(f"/iris/v1/builds/{build_id}/betaAppReviewSubmission")
    return payload.get("data")


def create_beta_review_submission(client: CookieIrisClient, build_id: str) -> dict[str, Any]:
    payload = client.request(
        "POST",
        "/iris/v1/betaAppReviewSubmissions",
        {
            "data": {
                "type": "betaAppReviewSubmissions",
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build_id}}
                },
            }
        },
        accept_statuses={201},
    )
    return payload["data"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True, help="Build number to promote, for example 20.")
    args = parser.parse_args()

    config = load_config()
    client = CookieIrisClient(config["appId"])
    builds = list_builds_for_version(client, config["appId"], args.version)
    if not builds:
        raise SystemExit(f"Build {args.version} is not visible in App Store Connect yet.")

    build = builds[0]
    build_id = build["id"]
    external_group_id = config["testflight"]["externalGroupId"]
    attach_build_to_group(client, build_id, external_group_id)

    submission = fetch_beta_review_submission(client, build_id)
    if submission is None:
        submission = create_beta_review_submission(client, build_id)

    result = {
        "buildId": build_id,
        "buildVersion": build["attributes"]["version"],
        "processingState": build["attributes"]["processingState"],
        "buildAudienceType": build["attributes"]["buildAudienceType"],
        "externalGroupId": external_group_id,
        "betaReviewState": submission["attributes"]["betaReviewState"],
        "submittedDate": submission["attributes"].get("submittedDate"),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
