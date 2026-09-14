// Web: webview_flutter has no implementation here, so the workout module opens in a
// real browser tab. The workout frontend's sirvyaAuth() boot helper lifts the session
// token out of the #sirvya_token= fragment before the app boots.
import 'dart:html' as html;

void openExternal(String url) {
  html.window.open(url, '_blank');
}
