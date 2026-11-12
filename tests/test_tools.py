import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("prices", ROOT / "scripts/import_prices.py")
prices = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prices)


class ImportTests(unittest.TestCase):
    def data(self):
        return {"schemaVersion": 1, "priceType": "minimumBuyout", "sourceName": "synthetic-test-only", "sourceVersion": "1",
                "scope": {"gameFlavor": "forever", "region": "EU", "realm": "Normal", "faction": "Alliance"},
                "items": {"1688": {"unitPriceCopper": 100, "observedAt": 1000}}}

    def test_scoped_contract_and_secret_exclusion(self):
        data = self.data(); data["apiKey"] = "must-never-be-exported"
        value = prices.validate(data, now=2000)
        self.assertNotIn("apiKey", value); self.assertEqual(value["items"]["1688"]["unitPriceCopper"], 100)

    def test_wrong_flavor_future_and_stack_ambiguity(self):
        data = self.data(); data["scope"]["gameFlavor"] = "retail"
        with self.assertRaises(ValueError): prices.validate(data, 2000)
        data = self.data(); data["items"]["1688"]["observedAt"] = 2001
        with self.assertRaises(ValueError): prices.validate(data, 2000)
        data = self.data(); data["items"]["1688"] = {"stackPrice": 2000, "observedAt": 1000}
        with self.assertRaises(ValueError): prices.validate(data, 2000)

    def test_lua_safe_escaping(self):
        encoded = prices.lua('Åsa "quoted"\n\\path')
        self.assertIn("\\195\\133", encoded); self.assertIn("\\010", encoded); self.assertIn('\\"', encoded)
        with self.assertRaises(ValueError): prices.lua(float("nan"))


if __name__ == "__main__":
    unittest.main()
