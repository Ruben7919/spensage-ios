#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import mimetypes
import time
from pathlib import Path
from typing import Any

import browser_cookie3
import requests

from chrome_apple_events import exec_js, select_tab_by_url


ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "AppStoreAssets" / "app_store_connect_config.json"
DEFAULT_AGE_RATING_ATTRIBUTES = {
    "advertising": False,
    "ageAssurance": False,
    "gambling": False,
    "healthOrWellnessTopics": False,
    "lootBox": False,
    "messagingAndChat": False,
    "parentalControls": False,
    "unrestrictedWebAccess": False,
    "userGeneratedContent": False,
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gamblingSimulated": "NONE",
    "gunsOrOtherWeapons": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "ageRatingOverrideV2": "NONE",
    "koreaAgeRatingOverride": "NONE",
}


def load_config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text())


def compact_json(payload: Any) -> str:
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def resolve_repo_path(raw_path: str) -> Path:
    path = Path(raw_path)
    return path if path.is_absolute() else ROOT / path


def focus_app_store_tab(app_id: str) -> None:
    try:
        select_tab_by_url(f"appstoreconnect.apple.com/apps/{app_id}")
    except RuntimeError:
        select_tab_by_url("appstoreconnect.apple.com")


class ChromeIrisClient:
    def __init__(self, app_id: str) -> None:
        self.app_id = app_id

    def request(
        self,
        method: str,
        path: str,
        payload: Any | None = None,
        *,
        accept_statuses: set[int] | None = None,
    ) -> dict[str, Any]:
        focus_app_store_tab(self.app_id)
        body_b64 = ""
        if payload is not None:
            body_b64 = base64.b64encode(compact_json(payload).encode("utf-8")).decode("ascii")
        js = f"""
(() => {{
  const xhr = new XMLHttpRequest();
  xhr.open({json.dumps(method.upper())}, {json.dumps(path)}, false);
  xhr.setRequestHeader("Accept", "application/json");
  const bodyB64 = {json.dumps(body_b64)};
  if (bodyB64) {{
    xhr.setRequestHeader("Content-Type", "application/json");
  }}
  const body = bodyB64 ? decodeURIComponent(escape(atob(bodyB64))) : null;
  xhr.send(body);
  return JSON.stringify({{ status: xhr.status, text: xhr.responseText || "" }});
}})()
"""
        raw = exec_js(js)
        response = json.loads(raw or "{}")
        status = int(response.get("status") or 0)
        text = response.get("text") or ""
        if accept_statuses is None:
            accept_statuses = {200, 201}
        if status not in accept_statuses:
            raise RuntimeError(f"{method.upper()} {path} failed with {status}: {text[:1200]}")
        if not text:
            return {}
        return json.loads(text)

    def get(self, path: str, *, accept_statuses: set[int] | None = None) -> dict[str, Any]:
        return self.request("GET", path, None, accept_statuses=accept_statuses)

    def post(self, path: str, payload: Any) -> dict[str, Any]:
        return self.request("POST", path, payload)

    def patch(self, path: str, payload: Any) -> dict[str, Any]:
        return self.request("PATCH", path, payload)


class CookieIrisClient:
    def __init__(self, app_id: str) -> None:
        self.app_id = app_id
        self.base_url = "https://appstoreconnect.apple.com"
        self.session = requests.Session()
        self.session.cookies.update(browser_cookie3.chrome())
        self.session.headers.update(
            {
                "Accept": "application/json",
                "Origin": self.base_url,
                "Referer": f"{self.base_url}/apps/{app_id}",
            }
        )
        # Warm the session once so ASC refreshes short-lived cookies like `dqsid`.
        response = self.session.get(f"{self.base_url}/olympus/v1/session", timeout=30)
        response.raise_for_status()

    def request(
        self,
        method: str,
        path: str,
        payload: Any | None = None,
        *,
        accept_statuses: set[int] | None = None,
    ) -> dict[str, Any]:
        url = path if path.startswith("http") else f"{self.base_url}{path}"
        headers: dict[str, str] = {}
        if payload is not None:
            headers["Content-Type"] = "application/json"
        response = self.session.request(
            method.upper(),
            url,
            headers=headers,
            json=payload,
            timeout=60,
        )
        if accept_statuses is None:
            accept_statuses = {200, 201}
        if response.status_code not in accept_statuses:
            raise RuntimeError(
                f"{method.upper()} {path} failed with {response.status_code}: {response.text[:1200]}"
            )
        if not response.text:
            return {}
        return response.json()

    def get(self, path: str, *, accept_statuses: set[int] | None = None) -> dict[str, Any]:
        return self.request("GET", path, None, accept_statuses=accept_statuses)

    def post(self, path: str, payload: Any) -> dict[str, Any]:
        return self.request("POST", path, payload)

    def patch(self, path: str, payload: Any) -> dict[str, Any]:
        return self.request("PATCH", path, payload)


def find_included(payload: dict[str, Any], resource_type: str) -> list[dict[str, Any]]:
    return [item for item in payload.get("included", []) if item.get("type") == resource_type]


def upload_asset_operations(
    client: CookieIrisClient,
    *,
    image_path: Path,
    operations: list[dict[str, Any]],
) -> str:
    data = image_path.read_bytes()
    checksum = hashlib.md5(data).hexdigest()
    mime_type = mimetypes.guess_type(image_path.name)[0] or "application/octet-stream"
    for operation in operations:
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
    return checksum


def wait_for_asset_processing(
    fetch_current: Any,
    *,
    label: str,
    timeout_seconds: int = 180,
) -> None:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        current = fetch_current()
        state = (
            current.get("data", {})
            .get("attributes", {})
            .get("assetDeliveryState", {})
            .get("state")
        )
        if state == "COMPLETE":
            return
        if state and state not in {"UPLOAD_COMPLETE", "AWAITING_UPLOAD", "PROCESSING"}:
            raise RuntimeError(f"{label} failed with assetDeliveryState={state}")
        time.sleep(2)
    raise TimeoutError(f"Timed out waiting for asset processing: {label}")


def wait_for_subscription_image_ready(
    client: Any,
    *,
    image_id: str,
    timeout_seconds: int = 180,
) -> None:
    terminal_states = {"PREPARE_FOR_SUBMISSION", "READY_TO_SUBMIT", "APPROVED"}
    pending_states = {"AWAITING_UPLOAD", "PROCESSING", "WAITING_FOR_UPLOAD", "UPLOAD_COMPLETE"}
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        current = client.get(f"/iris/v1/subscriptionImages/{image_id}")
        state = current.get("data", {}).get("attributes", {}).get("state")
        if state in terminal_states:
            return
        if state and state not in pending_states:
            raise RuntimeError(f"subscription image {image_id} failed with state={state}")
        time.sleep(2)
    raise TimeoutError(f"Timed out waiting for subscription image processing: {image_id}")


def list_all_territory_refs(client: Any) -> list[dict[str, str]]:
    payload = client.get("/iris/v1/territories?limit=400")
    return [{"type": "territories", "id": item["id"]} for item in payload.get("data", [])]


def upsert_app_info(config: dict[str, Any], client: ChromeIrisClient) -> None:
    app_info_cfg = config["appInfo"]
    app_info_id = config["appInfoId"]
    current = client.get(
        f"/iris/v1/apps/{config['appId']}/appInfos"
        "?include=appInfoLocalizations,primaryCategory,secondaryCategory"
        "&limit[appInfoLocalizations]=50"
    )
    existing = {
        item["attributes"]["locale"]: item
        for item in find_included(current, "appInfoLocalizations")
    }
    current_info = current["data"][0]
    primary = current_info["relationships"].get("primaryCategory", {}).get("data", {}).get("id")
    secondary = current_info["relationships"].get("secondaryCategory", {}).get("data", {}).get("id")
    if primary != app_info_cfg["primaryCategory"] or secondary != app_info_cfg["secondaryCategory"]:
        client.patch(
            f"/iris/v1/appInfos/{app_info_id}",
            {
                "data": {
                    "type": "appInfos",
                    "id": app_info_id,
                    "relationships": {
                        "primaryCategory": {
                            "data": {"type": "appCategories", "id": app_info_cfg["primaryCategory"]}
                        },
                        "secondaryCategory": {
                            "data": {"type": "appCategories", "id": app_info_cfg["secondaryCategory"]}
                        },
                    },
                }
            },
        )
    for locale, payload in app_info_cfg["localizations"].items():
        attributes = {
            "name": payload["name"],
            "subtitle": payload["subtitle"],
            "privacyPolicyUrl": payload["privacyPolicyUrl"],
        }
        if locale in existing:
            client.patch(
                f"/iris/v1/appInfoLocalizations/{existing[locale]['id']}",
                {
                    "data": {
                        "type": "appInfoLocalizations",
                        "id": existing[locale]["id"],
                        "attributes": attributes,
                    }
                },
            )
            continue
        client.post(
            "/iris/v1/appInfoLocalizations",
            {
                "data": {
                    "type": "appInfoLocalizations",
                    "attributes": {"locale": locale, **attributes},
                    "relationships": {
                        "appInfo": {"data": {"type": "appInfos", "id": app_info_id}}
                    },
                }
            },
        )


def patch_age_rating_declaration(config: dict[str, Any], client: Any) -> None:
    age_rating_cfg = config.get("ageRating")
    if not age_rating_cfg:
        return
    declaration_id = age_rating_cfg.get("declarationId") or config["appInfoId"]
    attributes = dict(DEFAULT_AGE_RATING_ATTRIBUTES)
    developer_url = age_rating_cfg.get("developerAgeRatingInfoUrl")
    if developer_url:
        attributes["developerAgeRatingInfoUrl"] = developer_url
    client.patch(
        f"/iris/v1/ageRatingDeclarations/{declaration_id}",
        {
            "data": {
                "type": "ageRatingDeclarations",
                "id": declaration_id,
                "attributes": attributes,
            }
        },
    )


def upsert_version_localizations(config: dict[str, Any], client: ChromeIrisClient) -> None:
    version_cfg = config["version"]
    version_id = version_cfg["id"]
    current = client.get(
        f"/iris/v1/appStoreVersions/{version_id}"
        "?include=appStoreVersionLocalizations,appStoreReviewDetail"
        "&limit[appStoreVersionLocalizations]=50"
    )
    existing = {
        item["attributes"]["locale"]: item
        for item in find_included(current, "appStoreVersionLocalizations")
    }
    client.patch(
        f"/iris/v1/appStoreVersions/{version_id}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "attributes": {
                    "copyright": version_cfg["copyright"],
                    "usesIdfa": bool(version_cfg["usesIdfa"]),
                },
            }
        },
    )
    for locale, payload in version_cfg["localizations"].items():
        attributes = {
            "promotionalText": payload["promotionalText"],
            "description": payload["description"],
            "keywords": payload["keywords"],
            "supportUrl": payload["supportUrl"],
            "marketingUrl": payload["marketingUrl"],
            "whatsNew": payload["whatsNew"],
        }
        if locale in existing:
            try:
                client.patch(
                    f"/iris/v1/appStoreVersionLocalizations/{existing[locale]['id']}",
                    {
                        "data": {
                            "type": "appStoreVersionLocalizations",
                            "id": existing[locale]["id"],
                            "attributes": attributes,
                        }
                    },
                )
            except RuntimeError as exc:
                if "whatsNew" not in str(exc):
                    raise
                retry_attributes = dict(attributes)
                retry_attributes.pop("whatsNew", None)
                client.patch(
                    f"/iris/v1/appStoreVersionLocalizations/{existing[locale]['id']}",
                    {
                        "data": {
                            "type": "appStoreVersionLocalizations",
                            "id": existing[locale]["id"],
                            "attributes": retry_attributes,
                        }
                    },
                )
            continue
        try:
            client.post(
                "/iris/v1/appStoreVersionLocalizations",
                {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "attributes": {"locale": locale, **attributes},
                        "relationships": {
                            "appStoreVersion": {
                                "data": {"type": "appStoreVersions", "id": version_id}
                            }
                        },
                    }
                },
            )
        except RuntimeError as exc:
            if "whatsNew" not in str(exc):
                raise
            retry_attributes = dict(attributes)
            retry_attributes.pop("whatsNew", None)
            client.post(
                "/iris/v1/appStoreVersionLocalizations",
                {
                    "data": {
                        "type": "appStoreVersionLocalizations",
                        "attributes": {"locale": locale, **retry_attributes},
                        "relationships": {
                            "appStoreVersion": {
                                "data": {"type": "appStoreVersions", "id": version_id}
                            }
                        },
                    }
                },
            )


def patch_review_detail(config: dict[str, Any], client: ChromeIrisClient) -> None:
    review_cfg = config["version"]["review"]
    attributes: dict[str, Any] = {
        "demoAccountRequired": bool(review_cfg["demoAccountRequired"]),
        "notes": review_cfg["notes"],
    }
    for key in ("contactFirstName", "contactLastName", "contactPhone", "contactEmail"):
        value = str(review_cfg.get(key, "")).strip()
        if value:
            attributes[key] = value
    client.patch(
        f"/iris/v1/appStoreReviewDetails/{config['version']['reviewDetailId']}",
        {
            "data": {
                "type": "appStoreReviewDetails",
                "id": config["version"]["reviewDetailId"],
                "attributes": attributes,
            }
        },
    )


def upsert_version_build(config: dict[str, Any], client: Any) -> None:
    build_id = config.get("build", {}).get("id")
    if not build_id:
        return
    version_id = config["version"]["id"]
    current = client.get(f"/iris/v1/appStoreVersions/{version_id}?include=build")
    current_build = (
        current.get("data", {})
        .get("relationships", {})
        .get("build", {})
        .get("data", {})
        .get("id")
    )
    if current_build == build_id:
        return
    client.request(
        "PATCH",
        f"/iris/v1/appStoreVersions/{version_id}/relationships/build",
        {"data": {"type": "builds", "id": build_id}},
        accept_statuses={204},
    )


def upsert_beta_app_localizations(config: dict[str, Any], client: ChromeIrisClient) -> None:
    current = client.get(f"/iris/v1/apps/{config['appId']}/betaAppLocalizations?limit=50")
    existing = {item["attributes"]["locale"]: item for item in current.get("data", [])}
    for locale, payload in config["beta"]["localizations"].items():
        attributes = {
            "description": payload["description"],
            "feedbackEmail": payload["feedbackEmail"],
            "marketingUrl": payload["marketingUrl"],
            "privacyPolicyUrl": payload["privacyPolicyUrl"],
        }
        if locale in existing:
            client.patch(
                f"/iris/v1/betaAppLocalizations/{existing[locale]['id']}",
                {
                    "data": {
                        "type": "betaAppLocalizations",
                        "id": existing[locale]["id"],
                        "attributes": attributes,
                    }
                },
            )
            continue
        client.post(
            "/iris/v1/betaAppLocalizations",
            {
                "data": {
                    "type": "betaAppLocalizations",
                    "attributes": {"locale": locale, **attributes},
                    "relationships": {
                        "app": {"data": {"type": "apps", "id": config["appId"]}}
                    },
                }
            },
        )


def upsert_beta_build_localizations(config: dict[str, Any], client: Any) -> None:
    build_cfg = config.get("build", {})
    build_id = build_cfg.get("id")
    localizations = build_cfg.get("betaLocalizations", {})
    if not build_id or not localizations:
        return
    current = client.get(f"/iris/v1/builds/{build_id}/betaBuildLocalizations")
    existing = {item["attributes"]["locale"]: item for item in current.get("data", [])}
    for locale, payload in localizations.items():
        attributes = {"whatsNew": payload["whatsNew"]}
        if locale in existing:
            client.patch(
                f"/iris/v1/betaBuildLocalizations/{existing[locale]['id']}",
                {
                    "data": {
                        "type": "betaBuildLocalizations",
                        "id": existing[locale]["id"],
                        "attributes": attributes,
                    }
                },
            )
            continue
        client.post(
            "/iris/v1/betaBuildLocalizations",
            {
                "data": {
                    "type": "betaBuildLocalizations",
                    "attributes": {"locale": locale, **attributes},
                    "relationships": {
                        "build": {"data": {"type": "builds", "id": build_id}}
                    },
                }
            },
        )


def upsert_subscription_group_localizations(config: dict[str, Any], client: ChromeIrisClient) -> None:
    group_id = config["pricing"]["subscriptions"]["groupId"]
    current = client.get(f"/iris/v1/subscriptionGroups/{group_id}/subscriptionGroupLocalizations")
    existing = {item["attributes"]["locale"]: item for item in current.get("data", [])}
    for locale, payload in config["pricing"]["subscriptions"]["groupLocalizations"].items():
        if locale in existing:
            client.patch(
                f"/iris/v1/subscriptionGroupLocalizations/{existing[locale]['id']}",
                {
                    "data": {
                        "type": "subscriptionGroupLocalizations",
                        "id": existing[locale]["id"],
                        "attributes": {"name": payload["name"]},
                    }
                },
            )
            continue
        client.post(
            "/iris/v1/subscriptionGroupLocalizations",
            {
                "data": {
                    "type": "subscriptionGroupLocalizations",
                    "attributes": {"locale": locale, "name": payload["name"]},
                    "relationships": {
                        "subscriptionGroup": {
                            "data": {"type": "subscriptionGroups", "id": group_id}
                        }
                    },
                }
            },
        )


def upsert_subscription_localizations(
    client: ChromeIrisClient,
    resource_id: str,
    localizations: dict[str, dict[str, str]],
) -> None:
    current = client.get(f"/iris/v1/subscriptions/{resource_id}/subscriptionLocalizations")
    existing = {item["attributes"]["locale"]: item for item in current.get("data", [])}
    for locale, payload in localizations.items():
        attributes = {"name": payload["name"], "description": payload["description"]}
        if locale in existing:
            client.patch(
                f"/iris/v1/subscriptionLocalizations/{existing[locale]['id']}",
                {
                    "data": {
                        "type": "subscriptionLocalizations",
                        "id": existing[locale]["id"],
                        "attributes": attributes,
                    }
                },
            )
            continue
        client.post(
            "/iris/v1/subscriptionLocalizations",
            {
                "data": {
                    "type": "subscriptionLocalizations",
                    "attributes": {"locale": locale, **attributes},
                    "relationships": {
                        "subscription": {"data": {"type": "subscriptions", "id": resource_id}}
                    },
                }
            },
        )


def upsert_iap_localizations(
    client: ChromeIrisClient,
    resource_id: str,
    localizations: dict[str, dict[str, str]],
) -> None:
    current = client.get(f"/iris/v2/inAppPurchases/{resource_id}/inAppPurchaseLocalizations")
    existing = {item["attributes"]["locale"]: item for item in current.get("data", [])}
    for locale, payload in localizations.items():
        attributes = {"name": payload["name"], "description": payload["description"]}
        if locale in existing:
            client.patch(
                f"/iris/v1/inAppPurchaseLocalizations/{existing[locale]['id']}",
                {
                    "data": {
                        "type": "inAppPurchaseLocalizations",
                        "id": existing[locale]["id"],
                        "attributes": attributes,
                    }
                },
            )
            continue
        client.post(
            "/iris/v1/inAppPurchaseLocalizations",
            {
                "data": {
                    "type": "inAppPurchaseLocalizations",
                    "attributes": {"locale": locale, **attributes},
                    "relationships": {
                        "inAppPurchaseV2": {
                            "data": {"type": "inAppPurchases", "id": resource_id}
                        }
                    },
                }
            },
        )


def patch_subscription_review_note(client: Any, resource_id: str, review_note: str | None) -> None:
    if not review_note:
        return
    client.patch(
        f"/iris/v1/subscriptions/{resource_id}",
        {
            "data": {
                "type": "subscriptions",
                "id": resource_id,
                "attributes": {"reviewNote": review_note},
            }
        },
    )


def patch_iap_review_note(client: Any, resource_id: str, review_note: str | None) -> None:
    if not review_note:
        return
    client.patch(
        f"/iris/v2/inAppPurchases/{resource_id}",
        {
            "data": {
                "type": "inAppPurchases",
                "id": resource_id,
                "attributes": {"reviewNote": review_note},
            }
        },
    )


def ensure_subscription_availability(
    client: Any,
    resource_id: str,
    territory_refs: list[dict[str, str]],
) -> None:
    current = client.get(
        f"/iris/v1/subscriptions/{resource_id}/subscriptionAvailability",
        accept_statuses={200, 404},
    )
    if current.get("data"):
        return
    client.post(
        "/iris/v1/subscriptionAvailabilities",
        {
            "data": {
                "type": "subscriptionAvailabilities",
                "attributes": {"availableInNewTerritories": True},
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": resource_id}},
                    "availableTerritories": {"data": territory_refs},
                },
            }
        },
    )


def ensure_iap_availability(
    client: Any,
    resource_id: str,
    territory_refs: list[dict[str, str]],
) -> None:
    current = client.get(
        f"/iris/v2/inAppPurchases/{resource_id}/inAppPurchaseAvailability",
        accept_statuses={200, 404},
    )
    if current.get("data"):
        return
    client.post(
        "/iris/v1/inAppPurchaseAvailabilities",
        {
            "data": {
                "type": "inAppPurchaseAvailabilities",
                "attributes": {"availableInNewTerritories": True},
                "relationships": {
                    "inAppPurchase": {"data": {"type": "inAppPurchases", "id": resource_id}},
                    "availableTerritories": {"data": territory_refs},
                },
            }
        },
    )


def upsert_subscription_tax_category(
    client: Any,
    resource_id: str,
    tax_category_id: str,
) -> None:
    current = client.get(
        f"/iris/v1/subscriptions/{resource_id}/subscriptionTaxCategoryInfo",
        accept_statuses={200, 404},
    )
    if current.get("data"):
        current_id = current["data"]["id"]
        current_full = client.get(
            f"/iris/v1/subscriptionTaxCategoryInfos/{current_id}?include=category"
        )
        current_category_id = (
            current_full.get("data", {})
            .get("relationships", {})
            .get("category", {})
            .get("data", {})
            .get("id")
        )
        if current_category_id == tax_category_id:
            return
        client.patch(
            f"/iris/v1/subscriptionTaxCategoryInfos/{current_id}",
            {
                "data": {
                    "type": "subscriptionTaxCategoryInfos",
                    "id": current_id,
                    "relationships": {
                        "category": {
                            "data": {"type": "taxCategories", "id": tax_category_id}
                        }
                    },
                }
            },
        )
        return
    client.post(
        "/iris/v1/subscriptionTaxCategoryInfos",
        {
            "data": {
                "type": "subscriptionTaxCategoryInfos",
                "relationships": {
                    "subscription": {"data": {"type": "subscriptions", "id": resource_id}},
                    "category": {"data": {"type": "taxCategories", "id": tax_category_id}},
                },
            }
        },
    )


def upsert_iap_tax_category(
    client: Any,
    resource_id: str,
    tax_category_id: str,
) -> None:
    current = client.get(
        f"/iris/v2/inAppPurchases/{resource_id}/inAppPurchaseTaxCategoryInfo",
        accept_statuses={200, 404},
    )
    if current.get("data"):
        current_id = current["data"]["id"]
        current_full = client.get(
            f"/iris/v1/inAppPurchaseTaxCategoryInfos/{current_id}?include=category"
        )
        current_category_id = (
            current_full.get("data", {})
            .get("relationships", {})
            .get("category", {})
            .get("data", {})
            .get("id")
        )
        if current_category_id == tax_category_id:
            return
        client.patch(
            f"/iris/v1/inAppPurchaseTaxCategoryInfos/{current_id}",
            {
                "data": {
                    "type": "inAppPurchaseTaxCategoryInfos",
                    "id": current_id,
                    "relationships": {
                        "category": {
                            "data": {"type": "taxCategories", "id": tax_category_id}
                        }
                    },
                }
            },
        )
        return
    client.post(
        "/iris/v1/inAppPurchaseTaxCategoryInfos",
        {
            "data": {
                "type": "inAppPurchaseTaxCategoryInfos",
                "relationships": {
                    "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": resource_id}},
                    "category": {"data": {"type": "taxCategories", "id": tax_category_id}},
                },
            }
        },
    )


def ensure_review_screenshot(
    client: Any,
    *,
    image_path: Path,
    resource_id: str,
    relation_path: str,
    create_path: str,
    resource_type: str,
    relationship_name: str,
    relationship_type: str,
    resource_path_prefix: str,
) -> None:
    if not hasattr(client, "session"):
        raise RuntimeError("Review screenshot upload requires --transport cookies")
    current = client.get(relation_path, accept_statuses={200, 404})
    current_data = current.get("data")
    checksum = hashlib.md5(image_path.read_bytes()).hexdigest()
    if current_data:
        current_checksum = current_data.get("attributes", {}).get("sourceFileChecksum")
        current_state = (
            current_data.get("attributes", {})
            .get("assetDeliveryState", {})
            .get("state")
        )
        if current_checksum == checksum and current_state in {"PREPARE_FOR_SUBMISSION", "READY_TO_SUBMIT", "APPROVED"}:
            return
        client.request(
            "DELETE",
            f"{resource_path_prefix}/{current_data['id']}",
            accept_statuses={200, 202, 204},
        )
    created = client.post(
        create_path,
        {
            "data": {
                "type": resource_type,
                "attributes": {
                    "fileName": image_path.name,
                    "fileSize": image_path.stat().st_size,
                },
                "relationships": {
                    relationship_name: {
                        "data": {"type": relationship_type, "id": resource_id}
                    }
                },
            }
        },
    )
    screenshot_id = created["data"]["id"]
    upload_ops = created["data"].get("attributes", {}).get("uploadOperations") or []
    uploaded_checksum = upload_asset_operations(client, image_path=image_path, operations=upload_ops)
    client.patch(
        f"{resource_path_prefix}/{screenshot_id}",
        {
            "data": {
                "type": resource_type,
                "id": screenshot_id,
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": uploaded_checksum,
                },
            }
        },
    )
    wait_for_asset_processing(
        lambda: client.get(f"{resource_path_prefix}/{screenshot_id}"),
        label=f"{resource_type}:{resource_id}",
    )


def ensure_subscription_image(
    client: Any,
    *,
    image_path: Path,
    resource_id: str,
) -> None:
    if not hasattr(client, "session"):
        raise RuntimeError("Subscription image upload requires --transport cookies")

    current = client.get(f"/iris/v1/subscriptions/{resource_id}/images", accept_statuses={200, 404})
    current_data = current.get("data") or []
    checksum = hashlib.md5(image_path.read_bytes()).hexdigest()
    for item in current_data:
        image_id = item["id"]
        image = client.get(f"/iris/v1/subscriptionImages/{image_id}", accept_statuses={200, 404}).get("data", {})
        attrs = image.get("attributes", {})
        current_checksum = attrs.get("sourceFileChecksum")
        current_state = attrs.get("state")
        if current_checksum == checksum and current_state == "COMPLETE":
            return
        client.request(
            "DELETE",
            f"/iris/v1/subscriptionImages/{image_id}",
            accept_statuses={200, 202, 204},
        )

    created = client.post(
        "/iris/v1/subscriptionImages",
        {
            "data": {
                "type": "subscriptionImages",
                "attributes": {
                    "fileName": image_path.name,
                    "fileSize": image_path.stat().st_size,
                },
                "relationships": {
                    "subscription": {
                        "data": {"type": "subscriptions", "id": resource_id}
                    }
                },
            }
        },
    )
    image_id = created["data"]["id"]
    upload_ops = created["data"].get("attributes", {}).get("uploadOperations") or []
    uploaded_checksum = upload_asset_operations(client, image_path=image_path, operations=upload_ops)
    client.patch(
        f"/iris/v1/subscriptionImages/{image_id}",
        {
            "data": {
                "type": "subscriptionImages",
                "id": image_id,
                "attributes": {
                    "uploaded": True,
                    "sourceFileChecksum": uploaded_checksum,
                },
            }
        },
    )
    wait_for_subscription_image_ready(
        client,
        image_id=image_id,
    )


def find_price_point_id(
    client: ChromeIrisClient,
    path: str,
    territory: str,
    target_price: str,
) -> str:
    cursor: str | None = None
    target = f"{float(target_price):.2f}"
    for _ in range(30):
        query = f"{path}?filter[territory]={territory}&limit=200"
        if cursor:
            query += f"&cursor={cursor}"
        data = client.get(query)
        for item in data.get("data", []):
            attrs = item.get("attributes", {})
            if attrs.get("currency") == "USD" and attrs.get("customerPrice") == target:
                return item["id"]
        cursor = data.get("meta", {}).get("paging", {}).get("nextCursor")
        if not cursor:
            break
    raise RuntimeError(f"Could not find USD price point {target} for {path}")


def decode_price_point_territory(price_point_id: str) -> str:
    raw = base64.urlsafe_b64decode(price_point_id + "=" * (-len(price_point_id) % 4)).decode()
    return json.loads(raw)["t"]


def apply_subscription_price(client: ChromeIrisClient, resource_id: str, price_usd: str) -> None:
    base_price_point_id = find_price_point_id(
        client,
        f"/iris/v1/subscriptions/{resource_id}/pricePoints",
        "USA",
        price_usd,
    )
    equalized_price_points = client.get(
        f"/iris/v1/subscriptionPricePoints/{base_price_point_id}/equalizations?limit=400"
    ).get("data", [])
    price_points = [base_price_point_id] + [item["id"] for item in equalized_price_points]
    local_ids = []
    included = []
    for price_point_id in price_points:
        territory_id = decode_price_point_territory(price_point_id)
        local_id = f"${{subscription-price-{territory_id}}}"
        local_ids.append({"type": "subscriptionPrices", "id": local_id})
        included.append(
            {
                "type": "subscriptionPrices",
                "id": local_id,
                "attributes": {"preserveCurrentPrice": False},
                "relationships": {
                    "subscription": {
                        "data": {"type": "subscriptions", "id": resource_id}
                    },
                    "territory": {"data": {"type": "territories", "id": territory_id}},
                    "subscriptionPricePoint": {
                        "data": {
                            "type": "subscriptionPricePoints",
                            "id": price_point_id,
                        }
                    },
                },
            }
        )
    client.patch(
        f"/iris/v1/subscriptions/{resource_id}",
        {
            "data": {
                "type": "subscriptions",
                "id": resource_id,
                "relationships": {
                    "prices": {"data": local_ids}
                },
            },
            "included": included,
        }
    )


def apply_iap_price_schedule(client: ChromeIrisClient, resource_id: str, price_usd: str) -> None:
    price_point_id = find_price_point_id(
        client,
        f"/iris/v2/inAppPurchases/{resource_id}/pricePoints",
        "USA",
        price_usd,
    )
    local_id = "${manual-price-usa}"
    payload = {
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "id": resource_id,
            "relationships": {
                "inAppPurchase": {
                    "data": {"type": "inAppPurchases", "id": resource_id}
                },
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                "manualPrices": {
                    "data": [{"type": "inAppPurchasePrices", "id": local_id}]
                }
            }
        },
        "included": [
            {
                "type": "inAppPurchasePrices",
                "id": local_id,
                "relationships": {
                    "inAppPurchasePricePoint": {
                        "data": {
                            "type": "inAppPurchasePricePoints",
                            "id": price_point_id
                        }
                    }
                }
            }
        ]
    }
    existing = client.get(
        f"/iris/v1/inAppPurchasePriceSchedules/{resource_id}",
        accept_statuses={200, 404}
    )
    if existing.get("errors"):
        payload["data"].pop("id", None)
        client.post("/iris/v1/inAppPurchasePriceSchedules", payload)
        return
    try:
        client.patch(f"/iris/v1/inAppPurchasePriceSchedules/{resource_id}", payload)
    except RuntimeError as exc:
        if "does not allow 'UPDATE'" not in str(exc):
            raise
        payload["data"].pop("id", None)
        client.post("/iris/v1/inAppPurchasePriceSchedules", payload)


def sync_pricing(config: dict[str, Any], client: ChromeIrisClient) -> None:
    territory_refs = list_all_territory_refs(client)
    review_screenshot_path = resolve_repo_path(config["pricing"]["reviewScreenshotPath"])
    subscription_image_path = resolve_repo_path(
        config["pricing"].get(
            "subscriptionImagePath",
            "SpendSage/Resources/Assets.xcassets/AppIcon.appiconset/icon-any-1024.png",
        )
    )
    tax_category_id = config["pricing"].get("taxCategoryId", "C003")
    upsert_subscription_group_localizations(config, client)
    for payload in config["pricing"]["subscriptions"]["products"].values():
        resource_id = payload["resourceId"]
        upsert_subscription_localizations(client, resource_id, payload["localizations"])
        apply_subscription_price(client, resource_id, payload["priceUsd"])
        patch_subscription_review_note(client, resource_id, payload.get("reviewNote"))
        ensure_subscription_availability(client, resource_id, territory_refs)
        upsert_subscription_tax_category(client, resource_id, tax_category_id)
        ensure_subscription_image(
            client,
            image_path=subscription_image_path,
            resource_id=resource_id,
        )
        ensure_review_screenshot(
            client,
            image_path=review_screenshot_path,
            resource_id=resource_id,
            relation_path=f"/iris/v1/subscriptions/{resource_id}/appStoreReviewScreenshot",
            create_path="/iris/v1/subscriptionAppStoreReviewScreenshots",
            resource_type="subscriptionAppStoreReviewScreenshots",
            relationship_name="subscription",
            relationship_type="subscriptions",
            resource_path_prefix="/iris/v1/subscriptionAppStoreReviewScreenshots",
        )
    for payload in config["pricing"]["iaps"].values():
        resource_id = payload["resourceId"]
        upsert_iap_localizations(client, resource_id, payload["localizations"])
        apply_iap_price_schedule(client, resource_id, payload["priceUsd"])
        patch_iap_review_note(client, resource_id, payload.get("reviewNote"))
        ensure_iap_availability(client, resource_id, territory_refs)
        upsert_iap_tax_category(client, resource_id, tax_category_id)
        ensure_review_screenshot(
            client,
            image_path=review_screenshot_path,
            resource_id=resource_id,
            relation_path=f"/iris/v2/inAppPurchases/{resource_id}/appStoreReviewScreenshot",
            create_path="/iris/v1/inAppPurchaseAppStoreReviewScreenshots",
            resource_type="inAppPurchaseAppStoreReviewScreenshots",
            relationship_name="inAppPurchaseV2",
            relationship_type="inAppPurchases",
            resource_path_prefix="/iris/v1/inAppPurchaseAppStoreReviewScreenshots",
        )


def summarize_product_states(config: dict[str, Any], client: ChromeIrisClient) -> dict[str, Any]:
    subscription_states = client.get(
        f"/iris/v1/apps/{config['appId']}/subscriptionGroups"
        "?include=subscriptions&limit=300&limit[subscriptions]=1000"
    )
    iap_states = client.get(f"/iris/v1/apps/{config['appId']}/inAppPurchasesV2?limit=1000")
    version_state = client.get(f"/iris/v1/appStoreVersions/{config['version']['id']}?include=build")
    app_info_state = client.get(f"/iris/v1/appInfos/{config['appInfoId']}")
    summary = {
        "appVersion": {
            "versionString": version_state.get("data", {}).get("attributes", {}).get("versionString"),
            "buildId": (
                version_state.get("data", {})
                .get("relationships", {})
                .get("build", {})
                .get("data", {})
                .get("id")
            ),
            "hasStoreIcon": bool(
                version_state.get("data", {}).get("attributes", {}).get("storeIcon")
            ),
        },
        "ageRating": {
            "appStoreAgeRating": app_info_state.get("data", {}).get("attributes", {}).get("appStoreAgeRating"),
            "brazilAgeRating": app_info_state.get("data", {}).get("attributes", {}).get("brazilAgeRating"),
        },
        "subscriptions": [
            {
                "productId": item["attributes"]["productId"],
                "state": item["attributes"]["state"]
            }
            for item in find_included(subscription_states, "subscriptions")
        ],
        "iaps": [
            {
                "productId": item["attributes"]["productId"],
                "state": item["attributes"]["state"]
            }
            for item in iap_states.get("data", [])
        ]
    }
    build_id = config.get("build", {}).get("id")
    if build_id:
        beta_build_payload = client.get(
            f"/iris/v1/builds/{build_id}/betaBuildLocalizations",
            accept_statuses={200, 404},
        )
        summary["betaBuildLocalizations"] = [
            {
                "locale": item["attributes"]["locale"],
                "whatsNew": item["attributes"].get("whatsNew"),
            }
            for item in beta_build_payload.get("data", [])
        ]
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--app-info", action="store_true")
    parser.add_argument("--version", action="store_true")
    parser.add_argument("--beta-app", action="store_true")
    parser.add_argument("--beta-build", action="store_true")
    parser.add_argument("--pricing", action="store_true")
    parser.add_argument("--status", action="store_true")
    parser.add_argument(
        "--transport",
        choices=("cookies", "chrome"),
        default="cookies",
        help="Use App Store Connect session cookies from Chrome (default) or Chrome Apple Events JS.",
    )
    args = parser.parse_args()

    if args.all:
        args.app_info = True
        args.version = True
        args.beta_app = True
        args.beta_build = True
        args.pricing = True
        args.status = True

    if not any((args.app_info, args.version, args.beta_app, args.beta_build, args.pricing, args.status)):
        parser.error(
            "Pick at least one of --all, --app-info, --version, --beta-app, --beta-build, --pricing, or --status"
        )

    config = load_config()
    if args.transport == "chrome":
        client = ChromeIrisClient(config["appId"])
    else:
        client = CookieIrisClient(config["appId"])

    if args.app_info:
        upsert_app_info(config, client)
        patch_age_rating_declaration(config, client)
    if args.version:
        upsert_version_localizations(config, client)
        patch_review_detail(config, client)
        upsert_version_build(config, client)
    if args.beta_app:
        upsert_beta_app_localizations(config, client)
    if args.beta_build:
        upsert_beta_build_localizations(config, client)
    if args.pricing:
        sync_pricing(config, client)
    if args.status:
        print(json.dumps(summarize_product_states(config, client), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
