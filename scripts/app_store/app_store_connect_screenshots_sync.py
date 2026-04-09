#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import mimetypes
import os
import time
from pathlib import Path

from app_store_connect_iris_sync import CookieIrisClient, load_config


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCREENSHOT_ROOT = ROOT / "AppStoreAssets" / "external-release" / "iphone-6.9"
DISPLAY_TYPE = "APP_IPHONE_67"
LOCALE_DIRS = {
    "en-US": "en",
    "es-ES": "es",
}


def list_version_localizations(client: CookieIrisClient, version_id: str) -> dict[str, str]:
    payload = client.get(f"/iris/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    return {
        item["attributes"]["locale"]: item["id"]
        for item in payload.get("data", [])
    }


def list_screenshot_sets(client: CookieIrisClient, localization_id: str) -> list[dict]:
    payload = client.get(f"/iris/v1/appStoreVersionLocalizations/{localization_id}/appScreenshotSets")
    return payload.get("data", [])


def list_screenshots(client: CookieIrisClient, screenshot_set_id: str) -> list[dict]:
    payload = client.get(f"/iris/v1/appScreenshotSets/{screenshot_set_id}/appScreenshots")
    return payload.get("data", [])


def get_or_create_screenshot_set(
    client: CookieIrisClient,
    localization_id: str,
    *,
    replace: bool,
) -> str:
    screenshot_sets = list_screenshot_sets(client, localization_id)
    current = next(
        (
            item
            for item in screenshot_sets
            if item.get("attributes", {}).get("screenshotDisplayType") == DISPLAY_TYPE
        ),
        None,
    )
    if current is None:
        created = client.post(
            "/iris/v1/appScreenshotSets",
            {
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {
                                "type": "appStoreVersionLocalizations",
                                "id": localization_id,
                            }
                        }
                    },
                }
            },
        )
        return created["data"]["id"]

    screenshot_set_id = current["id"]
    if replace:
        for screenshot in list_screenshots(client, screenshot_set_id):
            client.request(
                "DELETE",
                f"/iris/v1/appScreenshots/{screenshot['id']}",
                accept_statuses={200, 202, 204},
            )
    return screenshot_set_id


def upload_screenshot(
    client: CookieIrisClient,
    screenshot_set_id: str,
    image_path: Path,
) -> str:
    data = image_path.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    mime_type = mimetypes.guess_type(image_path.name)[0] or "application/octet-stream"
    created = client.post(
        "/iris/v1/appScreenshots",
        {
            "data": {
                "type": "appScreenshots",
                "attributes": {
                    "fileName": image_path.name,
                    "fileSize": len(data),
                },
                "relationships": {
                    "appScreenshotSet": {
                        "data": {"type": "appScreenshotSets", "id": screenshot_set_id}
                    }
                },
            }
        },
    )
    screenshot_id = created["data"]["id"]
    attributes = created["data"]["attributes"]
    for operation in attributes.get("uploadOperations") or []:
        headers = {item["name"]: item["value"] for item in operation.get("requestHeaders", [])}
        headers.setdefault("Content-Type", mime_type)
        offset = int(operation.get("offset") or 0)
        length = int(operation.get("length") or len(data))
        chunk = data[offset : offset + length]
        response = client.session.request(
            operation["method"],
            operation["url"],
            headers=headers,
            data=chunk,
            timeout=120,
        )
        response.raise_for_status()

    client.patch(
        f"/iris/v1/appScreenshots/{screenshot_id}",
        {
            "data": {
                "type": "appScreenshots",
                "id": screenshot_id,
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": checksum,
                },
            }
        },
    )

    deadline = time.time() + 180
    while time.time() < deadline:
        current = client.get(f"/iris/v1/appScreenshots/{screenshot_id}")
        state = (
            current.get("data", {})
            .get("attributes", {})
            .get("assetDeliveryState", {})
            .get("state")
        )
        if state == "COMPLETE":
            return screenshot_id
        if state and state not in {"UPLOAD_COMPLETE", "AWAITING_UPLOAD", "PROCESSING"}:
            raise RuntimeError(f"{image_path.name} failed with assetDeliveryState={state}")
        time.sleep(2)
    raise TimeoutError(f"Timed out waiting for screenshot processing: {image_path.name}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--screenshot-root",
        default=str(DEFAULT_SCREENSHOT_ROOT),
        help="Root folder that contains locale subfolders like es/ or en/.",
    )
    parser.add_argument(
        "--locales",
        default="es-ES,en-US",
        help="Comma-separated locales to sync.",
    )
    parser.add_argument(
        "--replace",
        action="store_true",
        help="Delete existing screenshots in the matching display type before uploading.",
    )
    args = parser.parse_args()

    config = load_config()
    client = CookieIrisClient(config["appId"])
    localization_ids = list_version_localizations(client, config["version"]["id"])
    screenshot_root = Path(args.screenshot_root)

    for locale in [item.strip() for item in args.locales.split(",") if item.strip()]:
        localization_id = localization_ids.get(locale)
        if localization_id is None:
            raise RuntimeError(f"Locale {locale} is missing from the current App Store version")
        locale_dir = screenshot_root / LOCALE_DIRS.get(locale, locale)
        if not locale_dir.exists() and locale != "es-ES":
            locale_dir = screenshot_root / LOCALE_DIRS["es-ES"]
        if not locale_dir.exists():
            raise RuntimeError(f"Screenshot directory not found for {locale}: {locale_dir}")
        image_paths = sorted(path for path in locale_dir.glob("*.png") if path.is_file())
        if not image_paths:
            raise RuntimeError(f"No PNG screenshots found for {locale} in {locale_dir}")

        screenshot_set_id = get_or_create_screenshot_set(
            client,
            localization_id,
            replace=args.replace,
        )
        existing = {
            item.get("attributes", {}).get("fileName")
            for item in list_screenshots(client, screenshot_set_id)
        }
        for image_path in image_paths:
            if image_path.name in existing and not args.replace:
                continue
            upload_screenshot(client, screenshot_set_id, image_path)
            print(f"{locale}: uploaded {image_path.name}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
