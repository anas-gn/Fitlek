import base64
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import patch
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature

spec = importlib.util.spec_from_file_location("ios_ci", Path(__file__).parents[1] / "ios_ci.py")
ci = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ci)


class IOSCI(unittest.TestCase):
    def test_initial_build_uses_pubspec_minimum(self):
        self.assertEqual(ci.next_build_number([], 18), 18)

    def test_existing_build_numbers_are_never_reused(self):
        self.assertEqual(ci.next_build_number(["2", "18", "27"], 18), 28)

    def test_dotted_previous_build_requires_higher_major(self):
        self.assertEqual(ci.next_build_number(["28.2.1", "27"], 18), 29)

    def test_invalid_or_reused_override_is_rejected(self):
        for value in ["0", "abc", "17", "18", "-1", "19;echo unsafe"]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                ci.next_build_number(["18"], 18, value)

    def test_explicit_valid_override(self):
        self.assertEqual(ci.next_build_number(["18"], 18, "42"), 42)

    def test_missing_credentials_fail_before_apple_calls(self):
        with patch.dict(ci.os.environ, {}, clear=True), self.assertRaisesRegex(ValueError, "Missing GitHub Actions secrets"):
            ci.credentials()

    def test_apple_jwt_is_valid_es256_with_issuer_and_short_lifetime(self):
        key = ec.generate_private_key(ec.SECP256R1())
        token = ci.apple_token("ABCDEFGHIJ", "00000000-0000-0000-0000-000000000000", key)
        header, payload, signature = token.split(".")
        decode = lambda value: base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))
        claims = json.loads(decode(payload))
        self.assertEqual(claims["aud"], "appstoreconnect-v1")
        self.assertEqual(claims["exp"] - claims["iat"], 600)
        raw = decode(signature)
        key.public_key().verify(encode_dss_signature(int.from_bytes(raw[:32], "big"), int.from_bytes(raw[32:], "big")),
                                f"{header}.{payload}".encode(), ec.ECDSA(hashes.SHA256()))


if __name__ == "__main__":
    unittest.main()
