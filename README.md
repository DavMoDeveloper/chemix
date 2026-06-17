# Chemix

App Flutter para aprender quimica mediante la tabla periodica y quizzes.

## Firebase Android

La app usa el proyecto Firebase configurado en
`android/app/google-services.json`.

Antes de probar la sincronizacion:

1. En Firebase Authentication, habilita el proveedor **Anonimo**.
2. Crea una base de datos Cloud Firestore.
3. Publica las reglas de `firestore.rules` desde Firebase Console o con:

```powershell
firebase deploy --only firestore:rules
```

El progreso y los errores se conservan primero en el dispositivo. Si Firebase
no esta disponible, la app sigue funcionando offline y reintenta sincronizar
en usos posteriores.
