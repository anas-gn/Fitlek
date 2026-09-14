// Native platforms: the workout module opens inside the WebView, so there is nothing
// to hand off to an external browser. Kept as a no-op so the conditional export has
// a valid target on io builds.
void openExternal(String url) {}
