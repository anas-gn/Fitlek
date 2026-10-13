// Register before Firebase's default click handler.
self.addEventListener('notificationclick', (event) => {
  event.stopImmediatePropagation();
  event.notification.close();
  const data = event.notification.data?.FCM_MSG?.data || event.notification.data || {};
  const url = new URL(self.registration.scope);
  url.searchParams.set('notification', JSON.stringify(data));
  event.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(async (windows) => {
    const existing = windows.find((client) => new URL(client.url).origin === url.origin);
    if (existing) { await existing.navigate(url.href); return existing.focus(); }
    return clients.openWindow(url.href);
  }));
});
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');
firebase.initializeApp({apiKey:'AIzaSyAMFk_cDAOFAYCY90XWwiapyjBUIdP16q4',appId:'1:256158398727:web:71d758851fb56c4ad32da2',messagingSenderId:'256158398727',projectId:'sirvya-app'});
firebase.messaging();
