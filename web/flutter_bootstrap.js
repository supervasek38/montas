{{flutter_js}}
{{flutter_build_config}}

(async function startPrototype() {
  // Retire Flutter's earlier offline cache without touching other app data.
  if ('serviceWorker' in navigator) {
    const isFlutterWorker = worker => worker &&
      new URL(worker.scriptURL).pathname.endsWith('/flutter_service_worker.js');
    const controlled = isFlutterWorker(navigator.serviceWorker.controller);
    const registrations = await navigator.serviceWorker.getRegistrations();
    for (const registration of registrations) {
      if ([registration.active, registration.waiting, registration.installing]
          .some(isFlutterWorker)) {
        await registration.unregister();
      }
    }
    if ('caches' in window) {
      await Promise.all(['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']
        .map(name => caches.delete(name)));
    }
    if (controlled) {
      window.location.reload();
      return;
    }
  }
  // Also bypass any main.dart.js retained by an older HTTP-cache policy.
  for (const build of _flutter.buildConfig.builds) {
    if (build.mainJsPath) {
      build.mainJsPath += '?v=' + Date.now();
    }
  }
  _flutter.loader.load();
})();
