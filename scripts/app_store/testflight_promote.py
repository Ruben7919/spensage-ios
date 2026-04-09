#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from app_store_connect_iris_sync import ChromeIrisClient, CookieIrisClient, load_config, upsert_beta_build_localizations, upsert_version_build


ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "AppStoreAssets" / "app_store_connect_config.json"


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


def try_attach_internal_group(
    client: CookieIrisClient,
    build_id: str,
    group_id: str,
) -> str:
    try:
        attach_build_to_group(client, build_id, group_id)
        return "attached"
    except RuntimeError as exc:
        message = str(exc)
        if "Cannot add internal group to a build" in message or "internal group" in message:
            return "automatic"
        raise


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


def wait_for_build_ready(
    client: CookieIrisClient,
    app_id: str,
    build_number: str,
    *,
    timeout_seconds: int = 1800,
) -> dict[str, Any]:
    import time

    deadline = time.time() + timeout_seconds
    last_state = ""
    while time.time() < deadline:
        builds = list_builds_for_version(client, app_id, build_number)
        if builds:
            build = builds[0]
            last_state = build["attributes"].get("processingState") or ""
            if last_state == "VALID":
                return build
            if last_state in {"FAILED", "INVALID"}:
                raise RuntimeError(f"Build {build_number} entered terminal processingState={last_state}")
        time.sleep(20)
    raise TimeoutError(f"Timed out waiting for build {build_number} to reach VALID. Last state={last_state!r}")


def persist_build_id(build_id: str) -> dict[str, Any]:
    config = load_config()
    config.setdefault("build", {})["id"] = build_id
    CONFIG_PATH.write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n")
    return config


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True, help="Build number to promote, for example 22.")
    parser.add_argument("--wait", action="store_true", help="Wait until App Store Connect marks the build VALID.")
    parser.add_argument(
        "--transport",
        choices=["cookies", "chrome"],
        default="cookies",
        help="Use App Store Connect session cookies from Chrome or the active App Store Connect Chrome tab.",
    )
    args = parser.parse_args()

    config = load_config()
    if args.transport == "chrome":
        client = ChromeIrisClient(config["appId"])
    else:
        client = CookieIrisClient(config["appId"])
    if args.wait:
        build = wait_for_build_ready(client, config["appId"], args.version)
    else:
        builds = list_builds_for_version(client, config["appId"], args.version)
        if not builds:
            raise SystemExit(f"Build {args.version} is not visible in App Store Connect yet.")
        build = builds[0]
    build_id = build["id"]
    config = persist_build_id(build_id)
    upsert_version_build(config, client)
    upsert_beta_build_localizations(config, client)
    internal_group_id = config["testflight"]["internalGroupId"]
    external_group_id = config["testflight"]["externalGroupId"]
    internal_distribution = try_attach_internal_group(client, build_id, internal_group_id)
    attach_build_to_group(client, build_id, external_group_id)

    submission = fetch_beta_review_submission(client, build_id)
    if submission is None:
        submission = create_beta_review_submission(client, build_id)

    result = {
        "buildId": build_id,
        "buildVersion": build["attributes"]["version"],
        "processingState": build["attributes"]["processingState"],
        "buildAudienceType": build["attributes"]["buildAudienceType"],
        "internalGroupId": internal_group_id,
        "internalDistribution": internal_distribution,
        "externalGroupId": external_group_id,
        "betaReviewState": submission["attributes"]["betaReviewState"],
        "submittedDate": submission["attributes"].get("submittedDate"),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
