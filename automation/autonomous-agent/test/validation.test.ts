import { describe, expect, it } from "vitest";
import { assertSafeChangedPath } from "../src/validation.js";

describe("changed-path safety", () => {
  it.each([
    "app/android/app/google-services.json",
    "app/ios/Runner/GoogleService-Info.plist",
    "app/android/key.properties",
    "signing/release.jks",
  ])("rejects private configuration or signing material at %s", (file) => {
    expect(() => assertSafeChangedPath(file)).toThrow("Forbidden changed path");
  });

  it.each([
    "app/lib/main.dart",
    "app/test/widget_test.dart",
    "docs/development.md",
  ])("allows normal repository path %s", (file) => {
    expect(() => assertSafeChangedPath(file)).not.toThrow();
  });
});
