// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: 'AIzaSyC9r2JizgginJLH3T9WQG5sBst3Zd4ajTA',
  authDomain: 'fir-flutter-codelab-d7f01.firebaseapp.com',
  projectId: 'fir-flutter-codelab-d7f01',
  storageBucket: 'fir-flutter-codelab-d7f01.appspot.com',
  messagingSenderId: '501853676549',
  appId: '1:501853676549:web:c950b33a0a5a94150e286c',
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    data: {
      click_action: 'http://localhost:51005/#/shop',
    },
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
self.addEventListener('notificationclick', function (event) {
  console.log('[firebase-messaging-sw.js] Notification click Received.');

  event.notification.close();

  // Navigate to the app or focus if it's already open
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(function (clientList) {
      for (const client of clientList) {
        if (client.url === event.notification.data.click_action && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(event.notification.data.click_action);
      }
    })
  );
});