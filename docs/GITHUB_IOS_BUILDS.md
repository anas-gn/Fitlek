# iOS builds from Windows using GitHub Actions

Open the sirvya_app repository, then Actions → SIRVYA iOS - Build and TestFlight → Run workflow. Choose main. Leave the build number blank to select a number above existing Apple uploads. Keep upload enabled to send the build to App Store Connect, or disable it to download only the signed IPA.

This workflow runs only on request. Its first job verifies credentials and build numbering on Linux; the Mac starts only after that succeeds. It uses a standard macos-26 runner, Flutter 3.44.6 and the production API https://api.sirvya.com/api. Download the signed IPA under the run's Artifacts section (retained for three days).

Required repository Actions secrets:

| Name | Value |
| --- | --- |
| APP_STORE_CONNECT_KEY_ID | App Store Connect Team API Key ID |
| APP_STORE_CONNECT_ISSUER_ID | App Store Connect Issuer ID (UUID) |
| APP_STORE_CONNECT_PRIVATE_KEY_BASE64 | Base64-encoded App Store Connect .p8 file |
| IOS_CERTIFICATE_PRIVATE_KEY | Persistent RSA distribution signing private key, PEM format |

The API key must have access to Sirvya and to certificates/provisioning profiles. A team key with Admin access supports automatic signing. Apple sign-in and APNs keys are separate and cannot replace this key. Private files must never be committed.

The standalone open-source Codemagic CLI utilities run on GitHub's Mac, not the Codemagic hosted service, so they do not consume Codemagic minutes. Signing reuses resources matching the persistent private key or creates them when necessary. Existing Apple certificates are never revoked automatically; a certificate-limit error requires recovering an existing signing identity or reviewing unused certificates manually.

The repository is private: builds use the account's included GitHub Actions allowance. Check GitHub Settings → Billing and licensing → Usage before running; keep paid overage disabled if builds must remain free. No larger runners are used. The workflow saves only IPA files, not keychains, private signing files or archives. Temporary signing material is removed at the end.

Upload makes a build available in App Store Connect/TestFlight after Apple processing. It does not submit an App Store release for review, distribute to external tester groups, or publish the app publicly. Test the built version on a physical iPhone before requesting App Store review.
