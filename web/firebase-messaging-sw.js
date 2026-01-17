importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyAcjD6ICGEugChS4IO-guj-N3SE7mhWrIo", // Pega aquí tu API Key de firebase_options.dart
    projectId: "proveedor-servicly", // Tu Project ID
    messagingSenderId: "1024356789012",
    appId: "1:1024356789012:web:abcdef1234567890"
});

const messaging = firebase.messaging();