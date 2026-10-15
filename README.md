# Zafiro Clean 💎

**Zafiro Clean** es una suite de optimización y utilidad nativa para macOS desarrollada en **Swift** y **SwiftUI**. Diseñada con un enfoque de alto rendimiento, estética de cristal (*glassmorphism*) inspirada en la pureza y brillo del zafiro, y un compañero integrado en la barra de menú.

---

## ✨ Características Principales

- **Cuidado Inteligente (Smart Care)**: Análisis integral con un solo clic que revisa archivos innecesarios, memoria y rendimiento general.
- **Archivos Basura**: Escaneo seguro y detallado de cachés de usuario, cachés de desarrollo (`DerivedData`, `.npm`) y registros temporales.
- **Desinstalador Inteligente**: Detecta aplicaciones instaladas en `/Applications` y localiza residuos huérfanos en `~/Library` (Application Support, Caches, Preferences, Saved Application State).
- **Archivos Grandes y Antiguos**: Localización rápida de descargas, videos y archivos comprimidos de gran tamaño con filtros por categoría.
- **Monitor del Sistema**: 
  - Monitoreo en tiempo real de CPU y temperaturas.
  - Consumo y distribución de memoria RAM.
  - Estado del almacenamiento interno y disco.
  - Lista de procesos pesados con opción de finalización rápida.
- **Compañero en Menu Bar**: Tarjetas informativas de batería, estado de Wi-Fi, dispositivos Bluetooth conectados, disco y memoria en tiempo real.
- **Arranque Automático**: Integración opcional mediante `LaunchAgent` para iniciar junto con el sistema.

---

## 🛠️ Tecnologías

- **Lenguaje**: Swift 6 / SwiftUI
- **Frameworks**: Combine, AppKit, SystemConfiguration, IOKit
- **Compatibilidad**: macOS Ventura (13.0) o superior

---

## 🚀 Compilación e Instalación

### Compilación rápida
```bash
./build.sh
```

El script compila en modo release, genera los íconos oficiales de Zafiro y empaqueta la aplicación en `MacCleaner.app`.

---

## 📄 Licencia

MIT License.
