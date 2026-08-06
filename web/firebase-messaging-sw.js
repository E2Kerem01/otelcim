importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCu9zcPmJVvimuqaJKEgxHs5K5v_yFowqI",
  appId: "1:317702297035:web:demo",
  messagingSenderId: "317702297035",
  projectId: "otelcim-7f0ba",
  authDomain: "otelcim-7f0ba.firebaseapp.com",
  storageBucket: "otelcim-7f0ba.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Arka plan FCM mesajı alındı:', payload);
  const notificationTitle = payload.notification?.title || 'Otelcim';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
