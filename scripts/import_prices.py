"""Validate an external unit-price JSON export and compile a local addon snapshot."""
import argparse
import json
import math
import time
from pathlib import Path


def lua(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        if not math.isfinite(value):
            raise ValueError("Non-finite number")
        return repr(value)
    if isinstance(value, str):
        escaped = []
        for char in value.encode("utf-8"):
            if char in (34, 92):
                escaped.append("\\" + chr(char))
            elif char < 32 or char > 126:
                escaped.append(f"\\{char:03d}")
            else:
                escaped.append(chr(char))
        return '"' + "".join(escaped) + '"'
    if isinstance(value, dict):
        return "{\n" + ",\n".join(f"[{lua(str(k))}] = {lua(v)}" for k, v in value.items()) + "\n}"
    raise ValueError(f"Unsupported value: {type(value).__name__}")


def validate(data, now=None):
    now = int(time.time()) if now is None else now
    if data.get("schemaVersion") != 1 or data.get("priceType") != "minimumBuyout":
        raise ValueError("Expected schemaVersion 1 and priceType minimumBuyout")
    scope = data.get("scope", {})
    if scope.get("gameFlavor") != "forever" or scope.get("region") not in {"EU", "US", "KR", "TW", "CN"}:
        raise ValueError("A precise Forever region is required")
    if not isinstance(scope.get("realm"), str) or not scope["realm"] or scope.get("faction") not in {"Alliance", "Horde"}:
        raise ValueError("A realm and faction are required")
    if not isinstance(data.get("sourceName"), str) or not data["sourceName"] or not isinstance(data.get("sourceVersion"), str):
        raise ValueError("A source name and version are required")
    if not isinstance(data.get("items"), dict) or not data["items"]:
        raise ValueError("No item prices")
    for key, row in data["items"].items():
        if not (key.isdecimal() and int(key) > 0 or key.startswith("item:") and key.split(":")[1].isdecimal()):
            raise ValueError(f"Invalid item ID or full variant key: {key!r}")
        price = row.get("unitPriceCopper")
        observed = row.get("observedAt")
        if isinstance(price, bool) or not isinstance(price, (int, float)) or not math.isfinite(price) or price <= 0:
            raise ValueError(f"Invalid unit price: {key}")
        if isinstance(observed, bool) or not isinstance(observed, int) or observed <= 0 or observed > now:
            raise ValueError(f"Missing or future observation date: {key}")
    # Copy only the provider contract, never arbitrary top-level configuration or credentials.
    return {"schemaVersion": 1, "priceType": "minimumBuyout", "scope": {k: scope[k] for k in ("gameFlavor", "region", "realm", "faction")},
            "sourceName": data["sourceName"], "sourceVersion": data["sourceVersion"], "importedAt": now,
            "items": {key: {"unitPriceCopper": row["unitPriceCopper"], "observedAt": row["observedAt"]} for key, row in data["items"].items()}}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path, help="GrindMeter/Data/ImportedPrices.lua in your addon folder")
    args = parser.parse_args()
    data = validate(json.loads(args.source.read_text(encoding="utf-8")))
    content = "-- Local market snapshot, compiled by GrindMeter. No network calls in game.\nGrindMeterPriceData = " + lua(data) + "\n"
    args.output.write_text(content, encoding="utf-8")
    print(f"Compiled {len(data['items'])} scoped unit prices. Restart WoW or /reload to load them.")


if __name__ == "__main__":
    main()
