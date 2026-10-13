"""Check the actual signed archive before retaining or uploading its IPA."""
from datetime import datetime, timezone
import os
from pathlib import Path
import plistlib
import subprocess

apps = list(Path("build/ios/archive").glob("*.xcarchive/Products/Applications/*.app"))
if len(apps) != 1:
    raise SystemExit("Expected exactly one archived iOS app.")
app = apps[0]
with (app / "Info.plist").open("rb") as file:
    info = plistlib.load(file)
assert info["CFBundleIdentifier"] == "com.sirvya.app", "Wrong bundle identifier"
assert info["CFBundleVersion"] == os.environ["BUILD_NUMBER"], "Wrong build number"
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
entitlements = plistlib.loads(subprocess.check_output(
    ["codesign", "--display", "--entitlements", "-", "--xml", str(app)], stderr=subprocess.DEVNULL))
profile = plistlib.loads(subprocess.check_output(
    ["security", "cms", "-D", "-i", str(app / "embedded.mobileprovision")]))
for values in [entitlements, profile["Entitlements"]]:
    assert values.get("aps-environment") == "production", "Push entitlement is missing or not production"
    assert "Default" in values.get("com.apple.developer.applesignin", []), "Apple sign-in entitlement is missing"
    assert values.get("com.apple.developer.team-identifier") == "NBG9FA33WF", "Wrong Apple team"
    assert not values.get("get-task-allow", False), "Development signing is not allowed"
assert profile["ExpirationDate"].replace(tzinfo=timezone.utc) > datetime.now(timezone.utc), "Provisioning profile expired"
print("Verified signed com.sirvya.app archive, production push, Apple sign-in, team and build number.")
