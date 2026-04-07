#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import time
from pathlib import Path

from chrome_apple_events import click_regex, navigate, set_field, set_select, wait_for_text


ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "AppStoreAssets" / "app_store_connect_config.json"


def load_config() -> dict:
    return json.loads(CONFIG_PATH.read_text())


def choose_locale(pattern: str) -> None:
    click_regex(r"Ingl|Espa", selectors='button,[role="button"]')
    time.sleep(0.7)
    click_regex(pattern, selectors='[role="menuitem"],button,[role="button"]')
    time.sleep(1.2)


def save_page() -> None:
    click_regex(r"^Guardar$")
    time.sleep(2.0)


def apply_version_localization(app_id: str, locale: str, payload: dict, review: dict | None = None) -> None:
    navigate(
        f"https://appstoreconnect.apple.com/apps/{app_id}/distribution/ios/version/inflight",
        )
    wait_for_text("Texto promocional")
    choose_locale(r"English|Ingl")
    if locale.startswith("es-"):
        choose_locale(r"Espa.*Espa")
    for field_name in ("promotionalText", "description", "keywords", "supportUrl", "marketingUrl"):
        set_field(field_name, payload[field_name])
    set_field("versionString", "1.0")
    set_field("copyright", "2026 SpendSage AI")
    if review:
        for key in ("contactFirstName", "contactLastName", "contactPhone", "contactEmail", "notes"):
            if key in review and str(review[key]).strip():
                set_field(key, review[key])
    save_page()


def apply_app_info(app_id: str, locale: str, payload: dict, primary_category: str, secondary_category: str) -> None:
    navigate(f"https://appstoreconnect.apple.com/apps/{app_id}/distribution/info")
    wait_for_text("Nombre")
    if locale.startswith("es-"):
        choose_locale(r"Espa.*Espa")
    set_field("name", payload["name"])
    set_field("subtitle", payload["subtitle"])
    set_select("primaryCategory", primary_category)
    set_select("secondaryCategory", secondary_category)
    save_page()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-info", action="store_true")
    parser.add_argument("--version", action="store_true")
    args = parser.parse_args()

    config = load_config()
    app_id = config["appId"]

    if args.app_info:
        app_info = config["appInfo"]
        for locale, payload in app_info["localizations"].items():
            apply_app_info(
                app_id,
                locale,
                payload,
                app_info["primaryCategory"],
                app_info["secondaryCategory"],
            )

    if args.version:
        version = config["version"]
        for locale, payload in version["localizations"].items():
            apply_version_localization(
                app_id,
                locale,
                payload,
                review=version.get("review"),
            )

    if not args.app_info and not args.version:
        parser.error("Pick at least one of --app-info or --version")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
