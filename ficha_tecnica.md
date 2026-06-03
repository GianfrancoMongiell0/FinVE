# FinVe — Ficha Técnica Completa

> Documento de referencia para desarrollo. Actualizado desde el repositorio: https://github.com/GianfrancoMongiell0/FinVE

---

## 1. Identidad del proyecto

| Campo | Valor |
|---|---|
| Nombre de la app | FinVe |
| Descripción | App de finanzas personales para usuarios venezolanos con soporte multi-moneda |
| Versión | 1.0.0+1 |
| applicationId / namespace | `com.finve.finve_new` |
| Ruta local | `C:\Users\gianf\OneDrive\Desktop\finve_new` |
| Repositorio | https://github.com/GianfrancoMongiell0/FinVE.git |
| Dispositivo de prueba | Xiaomi 23117RA68G (Android físico) |

---

## 2. Stack tecnológico

### Flutter / Dart
| Campo | Valor |
|---|---|
| Flutter | 3.44.0 (mínimo >=3.22.0) |
| Dart | 3.12.0 (SDK >=3.3.0 <4.0.0) |
| Java / Kotlin target | JVM 17 |
| Material Design | Material 3 (`useMaterial3: true`) |

### Dependencias de producción
| Categoría | Paquete | Versión |
|---|---|---|
| State management | flutter_riverpod | ^2.5.1 |
| State management | riverpod_annotation | ^2.3.5 |
| Base de datos local | sqflite | ^2.3.3+1 |
| Rutas de archivos | path_provider | ^2.1.3 |
| Rutas de archivos | path | ^1.9.0 |
| Almacenamiento seguro | flutter_secure_storage | ^9.2.2 |
| Biometría / PIN | local_auth | ^2.3.0 |
| Notificaciones locales | flutter_local_notifications | ^18.0.1 |
| Home screen widgets | home_widget | ^0.6.0 |
| HTTP / networking | http | ^1.2.1 |
| Internacionalización | intl | ^0.19.0 |
| Gráficas | fl_chart | ^0.68.0 |
| Íconos UI | cupertino_icons | ^1.0.8 |

### Dependencias de desarrollo
| Paquete | Versión |
|---|---|
| flutter_lints | ^4.0.0 |
| build_runner | ^2.4.11 |
| riverpod_generator | ^2.4.3 |

### Android Build
- `isCoreLibraryDesugaringEnabled = true`
- `desugar_jdk_libs:2.1.4`
- Release firma con debug keys (pendiente configurar signing real)
- Permisos declarados: `USE_BIOMETRIC`, `USE_FINGERPRINT`

---

## 3. Arquitectura

```
lib/
├── main.dart                    # Punto de entrada
├── app.dart                     # MaterialApp + _AuthGate + _SplashScreen
├── core/
│   ├── database/
│   │   ├── database_helper.dart # SQLite singleton, schema v3, migraciones
│   │   └── daos/                # budget, category, priority, rate_cache,
│   │                            # recurring_expense, transaction, wallet
│   ├── models/                  # budget, category, currency_rates, priority,
│   │                            # rate, recurring_expense, transaction, wallet
│   ├── providers/               # balance_visibility, logo, rate, theme
│   ├── services/                # auth, launcher_icon, notification,
│   │                            # rate, recurring, widget
│   └── utils/                   # constants, extensions, formatters
├── features/
│   ├── auth/                    # auth_screen, pin_setup_screen, widgets/
│   ├── budget/                  # budget_screen, budget_provider, widgets/
│   ├── calculator/              # calculator_screen, calculator_provider
│   ├── calendar/                # calendar_screen
│   ├── dashboard/               # dashboard_screen, dashboard_provider, widgets/
│   ├── priorities/              # priorities_screen, priority_form_screen,
│   │                            # priorities_provider, widgets/
│   ├── settings/                # settings_screen, screens/
│   ├── shell/                   # main_shell.dart (NavigationBar + IndexedStack)
│   ├── transactions/            # transactions_screen, transaction_form_screen,
│   │                            # transactions_provider, widgets/
│   └── wallets/                 # wallets_screen, wallet_detail_screen,
│                                # wallet_form_screen, wallets_provider
└── shared/
    ├── mixins/                  # unsaved_changes_mixin
    ├── theme/                   # app_colors, app_text_styles, app_theme
    └── widgets/                 # amount_display, confirm_dialog, currency_badge,
                                 # empty_state, finve_logo, payment_method_badge,
                                 # save_button, skeleton_box
```

---

## 4. Flujo de navegación

### Arranque de la app (`app.dart`)
```
main() → FinVeApp → _AuthGate
    ├── [loading 1500ms] → _SplashScreen
    ├── [sin PIN] → PinSetupScreen
    └── [con PIN] → AuthScreen → MainShell
```

### Rutas nombradas
| Ruta | Pantalla |
|---|---|
| `/main` | MainShell |
| `/auth` | AuthScreen |
| `/pin-setup` | PinSetupScreen |
| `/pin-change` | PinSetupScreen (isChange: true) |
| `/settings` | SettingsScreen |
| `/settings/recurring` | RecurringSettingsScreen |
| `/budget` | BudgetScreen |
| `/calendar` | CalendarScreen |

### Tabs principales (NavigationBar — `main_shell.dart`)
| Index | Tab | Ícono |
|---|---|---|
| 0 | Inicio | `home_outlined` / `home_rounded` |
| 1 | Billeteras | `account_balance_wallet_outlined` |
| 2 | Movimientos | `receipt_long_outlined` |
| 3 | Metas | `flag_outlined` |
| 4 | Calculadora | (oculta en nav, accesible por FAB) |

### Sub-rutas (push por Navigator)
- `TransactionFormScreen` — nueva o editar transacción (fullscreenDialog)
- `WalletDetailScreen` — detalle de billetera
- `WalletFormScreen` — crear / editar billetera
- `PriorityFormScreen` — crear / editar meta
- `SecuritySettingsScreen` — PIN y biométrico
- `NotificationSettingsScreen` — recordatorios
- `RateSettingsScreen` — tasas manuales
- `RecurringSettingsScreen` — gastos recurrentes
- `CategorySettingsScreen` — categorías

---

## 5. Base de datos SQLite

**Nombre del archivo:** `finve.db` | **Versión actual:** 3

### Tablas

#### `wallets`
| Campo | Tipo | Notas |
|---|---|---|
| id | INTEGER PK | autoincrement |
| name | TEXT | requerido |
| currency_code | TEXT | DEFAULT 'USD' |
| balance | REAL | DEFAULT 0.0 |
| icon | TEXT | DEFAULT 'wallet' |
| created_at | TEXT | ISO 8601 |

#### `categories`
| Campo | Tipo | Notas |
|---|---|---|
| id | INTEGER PK | autoincrement |
| name | TEXT | requerido |
| icon | TEXT | emoji |
| color | TEXT | hex '#RRGGBB' |
| type | TEXT | CHECK: 'income' \| 'expense' \| 'both' |

#### `transactions`
| Campo | Tipo | Notas |
|---|---|---|
| id | INTEGER PK | autoincrement |
| wallet_id | INTEGER FK | → wallets ON DELETE CASCADE |
| amount | REAL | requerido |
| type | TEXT | CHECK: 'income' \| 'expense' |
| category_id | INTEGER FK | → categories ON DELETE SET NULL |
| payment_method | TEXT | CHECK: cash, pago_movil, transfer, zelle, other |
| note | TEXT | nullable |
| date | TEXT | ISO 8601 |
| created_at | TEXT | ISO 8601 |
| rate_snapshot | REAL | tasa BCV al momento (solo VES). Añadido en v3 |

#### `priorities`
| Campo | Tipo | Notas |
|---|---|---|
| id | INTEGER PK | autoincrement |
| name | TEXT | requerido |
| target_amount | REAL | requerido |
| currency_code | TEXT | DEFAULT 'USD' |
| priority_level | TEXT | CHECK: 'high' \| 'medium' \| 'low' |
| is_completed | INTEGER | 0/1 |
| notes | TEXT | nullable |
| created_at | TEXT | ISO 8601 |

#### `recurring_expenses`
| Campo | Tipo | Notas |
|---|---|---|
| id | INTEGER PK | autoincrement |
| name | TEXT | requerido |
| amount | REAL | requerido |
| currency_code | TEXT | DEFAULT 'USD' |
| wallet_id | INTEGER FK | → wallets ON DELETE CASCADE |
| category_id | INTEGER FK | → categories ON DELETE SET NULL |
| payment_method | TEXT | igual a transactions |
| day_of_month | INTEGER | CHECK: 1–31 |
| auto_register | INTEGER | 0/1 |
| last_triggered_at | TEXT | nullable |
| created_at | TEXT | ISO 8601 |

#### `rate_cache`
| Campo | Tipo | Notas |
|---|---|---|
| id | INTEGER PK | autoincrement |
| currency_pair | TEXT | UNIQUE |
| rate | REAL | requerido |
| fetched_at | TEXT | ISO 8601 |

#### `budgets`
| Campo | Tipo | Notas |
|---|---|---|
| id | INTEGER PK | autoincrement |
| category_id | INTEGER FK | → categories ON DELETE CASCADE |
| amount | REAL | requerido |
| currency_code | TEXT | DEFAULT 'USD' |
| month | INTEGER | 1–12 |
| year | INTEGER | |
| created_at | TEXT | ISO 8601 |
| — | — | UNIQUE(category_id, month, year) |

### Migraciones
- **v1 → v2:** crea tabla `budgets`
- **v2 → v3:** añade columna `rate_snapshot REAL` a `transactions`

### Categorías seed (14 por defecto)
**Gastos:** Comida 🍔, Transporte 🚗, Servicios 💡, Salud 💊, Entretenimiento 🎮, Hogar 🏠, Ropa 👕, Educación 📚, Otros gastos 📦

**Ingresos:** Trabajo 💼, Freelance 💻, Inversión 📈, Regalo 🎁, Otros ingresos 💰

---

## 6. Modelos de datos

### `Transaction`
- `id`, `walletId`, `amount`, `type` (TransactionType), `categoryId`, `paymentMethod` (PaymentMethod), `note`, `date`, `createdAt`, `rateSnapshot`
- Joined: `category` (Category?), `wallet` (Wallet?)
- Helpers: `isIncome`, `isExpense`, `signedAmount`

### `Wallet`
- `id`, `name`, `currencyCode`, `balance`, `icon`, `createdAt`
- Helpers: `isCrypto`, `isFiat`

### `Category`
- `id`, `name`, `icon` (emoji), `color` (hex), `type` ('income' | 'expense' | 'both')
- Helpers: `isIncome`, `isExpense`

### `Budget`
- `id`, `categoryId`, `amount`, `currencyCode`, `month`, `year`, `createdAt`, `spent`
- Computed: `percentage`, `remaining`, `isOverBudget`, `isWarning`, `isOk`

### `Priority`
- `id`, `name`, `targetAmount`, `currencyCode`, `priorityLevel` (PriorityLevel), `isCompleted`, `notes`, `createdAt`
- Helpers: `isHigh`, `isMedium`, `isLow`

### `RecurringExpense`
- `id`, `name`, `amount`, `currencyCode`, `walletId`, `categoryId`, `paymentMethod`, `dayOfMonth`, `autoRegister`, `lastTriggeredAt`, `createdAt`
- Computed: `wasTriggeredThisMonth`, `nextDueDate`, `daysUntilDue`

### `CurrencyRates`
- `bcvRate`, `parallelRate`, `btcUsd`, `ethUsd`, `solUsd`, `fetchedAt`, `isManualOverride`, `isCached`
- Helpers: `toUsd()`, `fromUsd()`, `convert()`, `toVesParallel()`, `isStale`, `minutesAgo`

---

## 7. Enums y constantes

### `TransactionType`
| Valor | key | Label |
|---|---|---|
| income | 'income' | Ingreso |
| expense | 'expense' | Gasto |

### `PaymentMethod`
| Valor | key | Label | Emoji |
|---|---|---|---|
| cash | 'cash' | Efectivo | 💵 |
| pagoMovil | 'pago_movil' | Pago Móvil | 📱 |
| transfer | 'transfer' | Transferencia | 🏦 |
| zelle | 'zelle' | Zelle | 💸 |
| other | 'other' | Otro | 📦 |

### `PriorityLevel`
| Valor | key | Label | Emoji |
|---|---|---|---|
| high | 'high' | Alta | 🔴 |
| medium | 'medium' | Media | 🟡 |
| low | 'low' | Baja | 🟢 |

### `CurrencyCodes`
| Código | Símbolo | Label | Flag |
|---|---|---|---|
| USD | $ | Dólar estadounidense | 🇺🇸 |
| VES | Bs. | Bolívar venezolano | 🇻🇪 |
| BTC | ₿ | Bitcoin | 🟠 |
| ETH | Ξ | Ethereum | 🔷 |
| SOL | ◎ | Solana | 🟣 |

### APIs externas
| Endpoint | URL |
|---|---|
| BCV oficial | `https://ve.dolarapi.com/v1/dolares/oficial` |
| Paralelo | `https://ve.dolarapi.com/v1/dolares/paralelo` |
| Crypto (BTC/ETH/SOL) | `https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd` |

### Rate cache keys (`RatePairs`)
`USD_VES_BCV` · `USD_VES_PARALLEL` · `BTC_USD` · `ETH_USD` · `SOL_USD`

### Storage keys (`StorageKeys`)
`user_pin` · `biometric_enabled` · `selected_theme_id` · `daily_reminder_time` · `daily_reminder_enabled` · `onboarding_complete`

### Intervalos
- Refresh de tasas: 30 minutos
- Tasas consideradas stale: 2 horas

---

## 8. Providers (Riverpod)

### `rateProvider` — `AsyncNotifierProvider<RateNotifier, RateState>`
Estado completo de tasas: `rates`, `status` (idle/loading/success/error/offline), `errorMessage`

Derivados:
- `currencyRatesProvider` — solo el objeto `CurrencyRates`
- `ratesLoadingProvider` — bool
- `ratesOfflineProvider` — bool
- `ratesStaleProvider` — bool
- `ratesLastUpdatedProvider` — String "hace X min"
- `bcvRateProvider` — double
- `parallelRateProvider` — double
- `cryptoRatesProvider` — Map<String, double>

### `themeProvider` — `AsyncNotifierProvider<ThemeNotifier, AppThemeId>`
Persiste en `FlutterSecureStorage`. Default: `oceanBlue`.

### `logoProvider` — `AsyncNotifierProvider<LogoNotifier, AppLogoId>`
Persiste en `FlutterSecureStorage`. Default: `v4`. Al cambiar, llama a `LauncherIconService`.

### `balanceVisibleProvider` — `StateProvider<bool>`
Toggle global para ocultar/mostrar saldos. Default: `true`.

### `shellTabProvider` — `StateProvider<int>`
Navegación programática entre tabs del `MainShell`.

---

## 9. Servicios

### `AuthService`
- `isPinSet()`, `savePin(pin)`, `verifyPin(pin)`, `clearPin()`
- `isBiometricAvailable()`, `isBiometricEnabled()`, `setBiometricEnabled(bool)`
- `authenticateWithBiometric()`, `attemptBiometric()` → `AuthResult`
- Usa `FlutterSecureStorage` con `AndroidOptions(encryptedSharedPreferences: true)`

### `RateService`
- `init()` — carga caché + dispara fetch en background + timer cada 30min
- `fetchAllRates()` — BCV + paralelo + crypto en paralelo (`Future.wait`)
- `forceRefresh()`, `getCachedRates()`
- `setManualOverride(pair, rate)`, `clearManualOverride(pair)`, `clearAllManualOverrides()`
- Persiste en tabla `rate_cache`

### `NotificationService`
Canales Android:
| ID | Nombre | Importancia |
|---|---|---|
| `daily_reminder` | Recordatorio diario | default |
| `recurring_expense` | Gastos recurrentes | high |
| `priority_reminder` | Recordatorios de metas | default |

IDs de notificaciones:
- Daily: 1000
- Recurring: 2000 + expenseId
- Priority: 3000 + priorityId

### `WidgetService`
- Actualiza el widget de pantalla de inicio via `home_widget`
- App group ID: `com.finve.app`
- Widget name: `HomeWidgetProvider`

Claves de datos del widget:
| Clave | Uso |
|---|---|
| `widget_total_usd` | Balance total en USD |
| `widget_last_updated` | Timestamp de última actualización |
| `widget_bcv_rate` | Tasa BCV |
| `widget_parallel_rate` | Tasa paralelo |
| `wallet_{0-3}_name` | Nombre de billetera |
| `wallet_{0-3}_balance` | Balance formateado |
| `wallet_{0-3}_usd` | Balance en USD |
| `wallet_{0-3}_currency` | Código de moneda |
| `wallet_count` | Total de billeteras |
| `tx_{0-2}_icon` | Emoji de categoría |
| `tx_{0-2}_amount` | Monto con signo |
| `tx_{0-2}_category` | Nombre de categoría |

### `LauncherIconService`
- MethodChannel: `com.finve.app/launcher_icon`
- `setIcon(logoId)` — activa el activity-alias correspondiente
- `getCurrentIcon()` — lee qué alias está activo

### `RecurringService`
- `checkDueExpenses()` — se llama en `main()` al arrancar. Registra automáticamente los gastos con `autoRegister: true` que vencen hoy.

---

## 10. Logos del lanzador (`AppLogoId`)

| ID | Alias Android | Label | Descripción |
|---|---|---|---|
| v4 | `.LauncherV4` | Claro + wordmark | **Default.** Fondo claro con nombre |
| v1 | `.LauncherV1` | Clásico claro | Fondo claro, rojo y azul |
| v6 | `.LauncherV6` | Navy suave | Azul marino con rojo y dorado |
| v7 | `.LauncherV7` | Navy + wordmark | Navy oscuro con nombre |
| v8 | `.LauncherV8` | Híbrido cálido | Fondo cálido con rojo y dorado |

**Logo actual (rediseño 2025):**
- Círculo izquierdo: `#EB001B` (rojo Maestro) = Bs (bolívares)
- Círculo derecho: `#0099DF` (azul) = $ (dólares)
- Fondo: `#1A1A1A` (negro)
- Overlap: intersección real con `clipPath` (sin morado artificial)

**Archivos PNG generados:**
| Carpeta | Tamaño |
|---|---|
| mipmap-mdpi | 48×48 |
| mipmap-hdpi | 72×72 |
| mipmap-xhdpi | 96×96 |
| mipmap-xxhdpi | 144×144 |
| mipmap-xxxhdpi | 192×192 |

---

## 11. Sistema de temas (`AppThemeId`)

| ID | Nombre | Primary | Accent |
|---|---|---|---|
| oceanBlue | Ocean Blue | `#185FA5` | `#1D9E75` |
| slateAmber | Slate & Amber | `#444441` | `#EF9F27` |
| emeraldGold | Emerald & Gold | `#059669` | `#F59E0B` |
| roseNight | Rose Night | `#9F1239` | `#44403C` |
| violetSunset | Violet Sunset | `#7C3AED` | `#EA580C` |

Cada tema tiene: paleta light + dark, gradientes para tarjetas USD/VES/Wallets, colores de monedas y métodos de pago.

Persiste en `FlutterSecureStorage` con key `selected_theme_id`. Default: `oceanBlue`.

---

## 12. Tipografía (`AppTextStyles`)

| Estilo | Tamaño | Peso | Uso |
|---|---|---|---|
| displayLarge | 32px | 700 | Balances principales |
| displayMedium | 26px | 700 | Pantalla splash |
| headingLarge | 22px | 600 | Títulos de sección |
| headingMedium | 18px | 600 | AppBar, cards |
| headingSmall | 15px | 600 | Subtítulos |
| bodyLarge | 16px | 400 | Texto principal |
| bodyMedium | 14px | 400 | Listas, descripciones |
| bodySmall | 12px | 400 | Texto secundario |
| amountLarge | 28px | 700 | Montos destacados (tabular) |
| amountMedium | 20px | 600 | Montos en tarjetas (tabular) |
| amountSmall | 14px | 500 | Montos pequeños (tabular) |
| labelLarge | 13px | 500 | Botones, chips |
| labelMedium | 11px | 500 | Etiquetas, badges |
| labelSmall | 10px | 500 | Micro-etiquetas |
| caption | 11px | 400 | Fechas, metadatos |

---

## 13. Formatters

| Método | Ejemplo output |
|---|---|
| `Formatters.usd(1250.5)` | `$1,250.50` |
| `Formatters.ves(45600)` | `Bs. 45,600.00` |
| `Formatters.btc(0.002341)` | `0.002341 BTC` |
| `Formatters.rate(36.5)` | `36.50 Bs/USD` |
| `Formatters.compactUsd(1250000)` | `$1.25M` |
| `Formatters.transactionDate(today)` | `Hoy` / `Ayer` / `15 ene` |
| `Formatters.timeAgo(dt)` | `hace 5 min` / `hace 2 h` |

---

## 14. Dashboard — widgets internos

| Widget | Archivo | Función |
|---|---|---|
| `BalanceCards` | `balance_cards.dart` | Tarjeta principal USD + VES + wallets con gradientes del tema |
| `RateStrip` | `rate_strip.dart` | Franja con tasas BCV, paralelo y crypto |
| `BalanceChart` | `balance_chart.dart` | Gráfica de evolución del balance (fl_chart) |
| `BudgetSummaryCard` | `budget_summary.dart` | Resumen del presupuesto del mes actual |
| `MonthlySummaryCard` | `monthly_summary.dart` | Ingresos vs gastos del mes |
| `CategoryChart` | `category_chart.dart` | Gráfica de gastos por categoría (pie chart) |
| `UpcomingRecurring` | `upcoming_recurring.dart` | Próximos gastos recurrentes |
| `RecentTransactions` | `recent_transactions.dart` | Últimas transacciones con acceso directo |

El dashboard usa `_FadeSlide` con delays escalonados (0ms, 80ms, 140ms...) para animaciones de entrada.

---

## 15. Pantallas de ajustes

| Pantalla | Ruta | Función |
|---|---|---|
| `SettingsScreen` | `/settings` | Menú principal de ajustes |
| `SecuritySettingsScreen` | push | PIN + biométrico |
| `NotificationSettingsScreen` | push | Recordatorio diario (hora) |
| `RateSettingsScreen` | push | Override manual de tasas |
| `RecurringSettingsScreen` | `/settings/recurring` | CRUD gastos recurrentes |
| `CategorySettingsScreen` | push | CRUD categorías + paleta de colores |

---

## 16. Widgets de pantalla de inicio (Android)

El `HomeWidgetProvider` soporta 3 tamaños según `minWidth`:

| Tamaño | minWidth | Contenido |
|---|---|---|
| Small | < 130dp | Balance total USD + timestamp |
| Medium | 130–249dp | Balance total + hasta 4 billeteras |
| Large | ≥ 250dp | Balance + tasas BCV/paralelo + últimas 3 transacciones |

Layouts XML: `widget_small`, `widget_medium`, `widget_large`

---

## 17. MethodChannel nativo

**Canal:** `com.finve.app/launcher_icon`

| Método | Parámetros | Retorno |
|---|---|---|
| `setIcon` | `{'logoId': String}` | `bool` |
| `getIcon` | — | `String` (logoId actual o 'default') |

⚠️ **Nota:** El `package` de `MainActivity.kt` declara `com.finve.app` pero el namespace del proyecto es `com.finve.finve_new`. Pendiente unificar.

---

## 18. Pendientes priorizados

### 🔴 P1 — Bloquean funcionalidades
1. **Unificar package name:** `com.finve.app` → `com.finve.finve_new` en `MainActivity.kt` y actualizar MethodChannel a `"com.finve.finve_new/launcher_icon"`
2. **Completar AndroidManifest.xml:** agregar `INTERNET`, los 5 `<activity-alias>` para logos, `<receiver>` para `HomeWidgetProvider`, y `network_security_config.xml` para HTTP
3. **Signing config real** para release builds

### 🟡 P2 — Features de producto
4. Proyección de balance (Fase 3)
5. Dashboard personalizable — widgets reordenables (Fase 4)
6. Racha de registros — streak de días (Fase 5)

### 🟢 P3 — Mejoras UI/UX
7. Dashboard — mejorar layout visual de tarjetas
8. Formulario de transacción — teclado numérico custom
9. Microanimaciones y transiciones entre pantallas
10. Pantalla de ajustes — íconos por opción y mejor organización

---

## 19. Extensiones de código útiles

### `ContextX` (BuildContext)
`context.theme`, `context.colors`, `context.isDark`, `context.screenSize`, `context.showSnackBar(msg)`

### `DateTimeX`
`date.isSameDay(other)`, `date.isToday`, `date.isYesterday`, `date.startOfDay`, `date.startOfMonth`, `date.isoDate`

### `StringX`
`str.capitalized`, `str.isValidAmount`, `str.toAmount`

### `DoubleX`
`amount.roundTo(decimals)`, `amount.isEffectivelyZero`

---

*Generado el 02/06/2026 desde el repositorio completo.*