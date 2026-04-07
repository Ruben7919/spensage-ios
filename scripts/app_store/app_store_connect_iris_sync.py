#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import json
from pathlib import Path
from typing import Any

import browser_cookie3
import requests

from chrome_apple_events import exec_js, select_tab_by_url


ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "AppStoreAssets" / "app_store_connect_config.json"


def load_config() -> dict[str, Any]:
    return json.loads(CONFIG_PATH.read_text())


def compact_json(payload: Any) -> str:
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


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


def apply_subscription_price(client: ChromeIrisClient, resource_id: str, price_usd: str) -> None:
    price_point_id = find_price_point_id(
        client,
        f"/iris/v1/subscriptions/{resource_id}/pricePoints",
        "USA",
        price_usd,
    )
    local_id = "${manual-price-usa}"
    client.patch(
        f"/iris/v1/subscriptions/{resource_id}",
        {
            "data": {
                "type": "subscriptions",
                "id": resource_id,
                "relationships": {
                    "prices": {
                        "data": [{"type": "subscriptionPrices", "id": local_id}]
                    }
                },
            },
            "included": [
                {
                    "type": "subscriptionPrices",
                    "id": local_id,
                    "attributes": {"preserveCurrentPrice": False},
                    "relationships": {
                        "subscription": {
                            "data": {"type": "subscriptions", "id": resource_id}
                        },
                        "territory": {"data": {"type": "territories", "id": "USA"}},
                        "subscriptionPricePoint": {
                            "data": {
                                "type": "subscriptionPricePoints",
                                "id": price_point_id
                            }
                        }
                    }
                }
            ]
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
    upsert_subscription_group_localizations(config, client)
    for payload in config["pricing"]["subscriptions"]["products"].values():
        resource_id = payload["resourceId"]
        upsert_subscription_localizations(client, resource_id, payload["localizations"])
        apply_subscription_price(client, resource_id, payload["priceUsd"])
    for payload in config["pricing"]["iaps"].values():
        resource_id = payload["resourceId"]
        upsert_iap_localizations(client, resource_id, payload["localizations"])
        apply_iap_price_schedule(client, resource_id, payload["priceUsd"])


def summarize_product_states(config: dict[str, Any], client: ChromeIrisClient) -> dict[str, Any]:
    subscription_states = client.get(
        f"/iris/v1/apps/{config['appId']}/subscriptionGroups"
        "?include=subscriptions&limit=300&limit[subscriptions]=1000"
    )
    iap_states = client.get(f"/iris/v1/apps/{config['appId']}/inAppPurchasesV2?limit=1000")
    return {
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-info", action="store_true")
    parser.add_argument("--version", action="store_true")
    parser.add_argument("--pricing", action="store_true")
    parser.add_argument("--status", action="store_true")
    parser.add_argument(
        "--transport",
        choices=("cookies", "chrome"),
        default="cookies",
        help="Use App Store Connect session cookies from Chrome (default) or Chrome Apple Events JS.",
    )
    args = parser.parse_args()

    if not any((args.app_info, args.version, args.pricing, args.status)):
        parser.error("Pick at least one of --app-info, --version, --pricing, or --status")

    config = load_config()
    if args.transport == "chrome":
        client = ChromeIrisClient(config["appId"])
    else:
        client = CookieIrisClient(config["appId"])

    if args.app_info:
        upsert_app_info(config, client)
    if args.version:
        upsert_version_localizations(config, client)
        patch_review_detail(config, client)
    if args.pricing:
        sync_pricing(config, client)
    if args.status:
        print(json.dumps(summarize_product_states(config, client), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
