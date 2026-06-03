<div align="center">

<br/>

```
  ██████╗ ██╗ ███╗   ██╗ ██╗   ██╗ ███████╗
  ██╔════╝ ██║ ████╗  ██║ ██║   ██║ ██╔════╝
  █████╗   ██║ ██╔██╗ ██║ ██║   ██║ █████╗
  ██╔══╝   ██║ ██║╚██╗██║ ╚██╗ ██╔╝ ██╔══╝
  ██║      ██║ ██║ ╚████║  ╚████╔╝  ███████╗
  ╚═╝      ╚═╝ ╚═╝  ╚═══╝   ╚═══╝   ╚══════╝
```

**Finanzas personales para venezolanos. Multi-moneda, offline-first, sin complicaciones.**

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.44.0-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12.0-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2021+-3DDC84?style=flat-square&logo=android&logoColor=white)](https://developer.android.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-EB001B?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-0099DF?style=flat-square)](https://github.com/GianfrancoMongiell0/FinVE/releases)

<br/>

</div>

---

## ¿Qué es FinVe?

FinVe es una app Android de finanzas personales diseñada específicamente para el contexto venezolano: soporte nativo para **bolívares (VES)**, **dólares (USD)** y **criptomonedas**, tasas BCV y paralelo en tiempo real, y métodos de pago locales como Pago Móvil y Zelle.

Funciona **completamente offline** — todos tus datos viven en tu teléfono.

---

## Características

### 💰 Multi-moneda real
- Billeteras en USD, VES, BTC, ETH y SOL
- Tasas BCV y paralelo actualizadas automáticamente cada 30 minutos
- Conversión instantánea entre cualquier par de monedas
- Override manual de tasas para trabajar offline

### 📊 Dashboard completo
- Balance total en USD con vista por billetera
- Gráfica de evolución del balance
- Resumen mensual ingresos vs gastos
- Gastos por categoría (pie chart)
- Próximos gastos recurrentes

### 🔒 Seguro por diseño
- PIN de 4 dígitos cifrado en `EncryptedSharedPreferences`
- Autenticación biométrica (huella / face unlock)
- Sin servidores externos — tus datos nunca salen del dispositivo

### 🔁 Gastos recurrentes
- Define gastos fijos con su día del mes
- Registro automático o recordatorio con acción directa en la notificación

### 🎯 Metas financieras
- Prioridades alta / media / baja
- Calculadora integrada de cuánto tiempo te falta para alcanzar cada meta
- Widget de pantalla de inicio con tu balance total

### 🎨 5 temas visuales
Ocean Blue · Slate & Amber · Emerald & Gold · Rose Night · Violet Sunset

---

## Stack técnico

```
Flutter 3.44.0 + Dart 3.12.0
├── Estado          flutter_riverpod ^2.5.1
├── Base de datos   sqflite ^2.3.3+1  (SQLite local, schema v3)
├── Seguridad       flutter_secure_storage ^9.2.2
│                   local_auth ^2.3.0
├── Notificaciones  flutter_local_notifications ^18.0.1
├── Widget nativo   home_widget ^0.6.0
├── Red             http ^1.2.1
├── Gráficas        fl_chart ^0.68.0
└── i18n            intl ^0.19.0
```

---

## Estructura del proyecto

```
lib/
├── main.dart
├── app.dart                        # AuthGate + SplashScreen
├── core/
│   ├── database/                   # SQLite helper + 7 DAOs
│   ├── models/                     # Transaction, Wallet, Budget...
│   ├── providers/                  # Riverpod providers
│   ├── services/                   # Auth, Rate, Notification, Widget
│   └── utils/                      # Constants, Extensions, Formatters
├── features/
│   ├── dashboard/                  # Pantalla principal
│   ├── transactions/               # Movimientos + formulario
│   ├── wallets/                    # Billeteras
│   ├── priorities/                 # Metas financieras
│   ├── budget/                     # Presupuesto mensual
│   ├── calculator/                 # Calculadora de conversión
│   ├── calendar/                   # Vista por fecha
│   ├── auth/                       # PIN + biometría
│   ├── settings/                   # Ajustes
│   └── shell/                      # NavigationBar
└── shared/
    ├── theme/                      # 5 temas + tipografía
    └── widgets/                    # Componentes reutilizables
```

---

## APIs externas

| Fuente | Endpoint | Uso |
|--------|----------|-----|
| dolarapi.com | `/v1/dolares/oficial` | Tasa BCV |
| dolarapi.com | `/v1/dolares/paralelo` | Tasa paralelo |
| CoinGecko | `/api/v3/simple/price` | BTC / ETH / SOL |

> Sin API keys requeridas. Todo es público y gratuito.

---

## Instalación y desarrollo

### Requisitos
- Flutter 3.22.0 o superior
- Android Studio / VS Code
- Dispositivo Android o emulador (API 21+)

### Clonar y correr

```bash
git clone https://github.com/GianfrancoMongiell0/FinVE.git
cd FinVE
flutter pub get
flutter run
```

### Build release

```bash
flutter build apk --release
# El APK queda en: build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ El build release actualmente firma con debug keys. Configura tu propio `signingConfig` antes de publicar en Play Store.

---

## Base de datos

SQLite local — archivo `finve.db` en el directorio de documentos del app.

| Tabla | Descripción |
|-------|-------------|
| `wallets` | Billeteras del usuario |
| `transactions` | Movimientos de ingresos y gastos |
| `categories` | Categorías personalizables (14 por defecto) |
| `budgets` | Presupuestos mensuales por categoría |
| `priorities` | Metas financieras |
| `recurring_expenses` | Gastos recurrentes programados |
| `rate_cache` | Caché local de tasas de cambio |

**Versión actual del schema:** v3 — [ver migraciones](lib/core/database/database_helper.dart)

---

## Monedas soportadas

| Código | Símbolo | Descripción |
|--------|---------|-------------|
| USD | $ | Dólar estadounidense |
| VES | Bs. | Bolívar venezolano |
| BTC | ₿ | Bitcoin |
| ETH | Ξ | Ethereum |
| SOL | ◎ | Solana |

---

## Métodos de pago

`Efectivo` · `Pago Móvil` · `Transferencia` · `Zelle` · `Otro`

---

## Roadmap

- [x] Autenticación PIN + biométrico
- [x] Multi-billetera multi-moneda
- [x] Tasas BCV y paralelo en tiempo real
- [x] Gastos recurrentes con auto-registro
- [x] Presupuesto mensual por categoría
- [x] Widget de pantalla de inicio
- [x] 5 temas visuales personalizables
- [ ] Proyección de balance futuro
- [ ] Dashboard personalizable (widgets reordenables)
- [ ] Racha de días con registros
- [ ] Exportar datos a CSV

---

## Contribuir

Pull requests bienvenidos. Para cambios grandes, abre un issue primero para discutir qué quieres cambiar.

---

## Licencia y derechos de autor

Copyright (c) 2026 **Gianfranco Mongiello**

Este proyecto está licenciado bajo la **MIT License** — consulta el archivo [LICENSE](LICENSE) para más detalles.

En resumen: puedes usar, copiar, modificar y distribuir este código libremente, siempre que incluyas el aviso de copyright original.

---

<div align="center">

Hecho con ❤️ en Venezuela

</div>