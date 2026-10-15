# MacCleaner 🚀

**MacCleaner** es una utilidad nativa para macOS desarrollada en **Swift** y **SwiftUI**, diseñada para mantener tu Mac rápida, limpia y optimizada mediante una interfaz moderna con efectos de glassmorphism y un compañero en la barra de menú.

---

## ✨ Características Principales

- **Smart Care**: Análisis integral con un solo clic que revisa archivos innecesarios, memoria y rendimiento.
- **Limpiador del Sistema**: Escaneo seguro y detallado de cachés de usuario, cachés de Xcode (`DerivedData`), dependencias de desarrollo (`.npm`, etc.) y registros del sistema.
- **Desinstalador Inteligente**: Detecta aplicaciones instaladas en `/Applications` y localiza residuos huérfanos en `~/Library` (Application Support, Caches, Preferences, Saved Application State).
- **Archivos Grandes y Antiguos**: Localización rápida de descargas, archivos de video, archivos comprimidos e imágenes de disco que ocupan espacio crítico.
- **Monitor del Sistema**: 
  - Monitoreo en tiempo real de CPU y temperaturas.
  - Consumo de memoria RAM (activa, inactiva, wired y libre).
  - Estado del almacenamiento interno y disco.
  - Lista de procesos pesados con opción para finalizar tareas rápidamente.
- **Compañero en Menu Bar**: Acceso rápido desde la barra de menú con tarjetas informativas de batería, estado de Wi-Fi, dispositivos Bluetooth conectados, disco y memoria.
- **Arranque Automático**: Integración opcional mediante `LaunchAgent` para iniciar junto con el sistema.

---

## 🛠️ Tecnologías

- **Lenguaje**: Swift 6 / SwiftUI
- **Frameworks**: Combine, AppKit, SystemConfiguration, IOKit
- **Compatibilidad**: macOS Ventura (13.0) o superior

---

## 🚀 Compilación e Instalación

### Requisitos
- Xcode Command Line Tools (`xcode-select --install`)
- macOS 13+

### Compilación rápida
```bash
./build.sh
```

El script compila en modo release y genera la aplicación en `MacCleaner.app`.

---

## 📄 Licencia

MIT License.
