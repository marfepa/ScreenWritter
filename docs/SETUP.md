# Setup y Signing

## Abrir el proyecto

Abre:

```text
ScreenWritter.xcodeproj
```

Selecciona el scheme:

```text
ScreenWritter
```

## Configurar Team

En Xcode, configura `Signing & Capabilities` para:

- `ScreenWritter`
- `ScreenWritterShareExtension`

Ambos targets deben usar el mismo Team.

## Bundle identifiers

Valores actuales:

- App: `com.screenwritter.app`
- Share Extension: `com.screenwritter.app.ShareExtension`
- Unit tests: `com.screenwritter.app.tests`
- UI tests: `com.screenwritter.app.uitests`

Si el bundle ID ya esta usado en tu cuenta, cambialo en `project.yml` y ejecuta:

```bash
xcodegen generate
```

## App Group

Para que la app y la extension compartan el inbox de importacion, activa App Groups en ambos targets y usa:

```text
group.com.screenwritter.shared
```

El mismo valor esta definido en:

- `ScreenWritter/ScreenWritter.entitlements`
- `ScreenWritterShareExtension/ScreenWritterShareExtension.entitlements`
- `ScreenWritter/Services/AppLocations.swift`
- `ScreenWritterShareExtension/ShareViewController.swift`

Si cambias el App Group, actualiza esos cuatro puntos.

## Error: app is not a valid bundle

Si Xcode muestra:

```text
The item at ScreenWritter.app is not a valid bundle.
Failed to get the identifier for the app to be installed.
```

Verifica que `Info.plist` contiene:

```text
CFBundleIdentifier = $(PRODUCT_BUNDLE_IDENTIFIER)
CFBundleExecutable = $(EXECUTABLE_NAME)
CFBundlePackageType = $(PRODUCT_BUNDLE_PACKAGE_TYPE)
```

Despues ejecuta:

1. `Product > Clean Build Folder`
2. Borra DerivedData de ScreenWritter si persiste.
3. Vuelve a instalar.

## Error: Choose an app to run

Ese dialogo aparece al ejecutar el scheme de la Share Extension. Es normal.

Para ejecutar la app, usa el scheme `ScreenWritter`.

Para probar la extension, elige una app host como Safari, Photos o Files.
