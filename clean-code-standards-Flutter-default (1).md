# 🤖 AI Instructions — Flutter (Existing Project)

> **Purpose**: Guidelines for AI assistants when modifying an existing Flutter project. Follow the current project structure. Do NOT reorganize folders or rename files unless explicitly asked.

---

## 🔍 Project Discovery — Read Before You Code

> **CRITICAL**: Before writing ANY code, you MUST inspect the following files to understand the project's architecture, patterns, and conventions.

### Step 1: Understand the Foundation
| File / Directory | What to Learn |
|---|---|
| `pubspec.yaml` | Dependencies, Flutter/Dart SDK version, assets, fonts, dev dependencies |
| `pubspec.lock` | Exact dependency versions to avoid conflicts |
| `analysis_options.yaml` | Lint rules, custom analysis, strictness level |
| `README.md` | Project overview, setup instructions, architecture notes |
| `.env` / `lib/config/` | Environment configuration, API URLs, feature flags |

### Step 2: Understand the Architecture
| File / Directory | What to Learn |
|---|---|
| `lib/` (top-level structure) | Folder pattern (feature-first, layer-first, clean architecture) |
| `lib/main.dart` | Entry point, providers/injectors, app initialization, global setup |
| `lib/app.dart` / `lib/app/` | MaterialApp/CupertinoApp config, theme, locale, navigation |
| `lib/routes/` / `lib/navigation/` | Routing approach (GoRouter, auto_route, Navigator 2.0, named routes) |
| `lib/features/` / `lib/screens/` / `lib/pages/` | Screen organization pattern |
| `lib/widgets/` / `lib/components/` | Shared/reusable widget library |

### Step 3: Understand State Management
| File / Directory | What to Learn |
|---|---|
| `lib/providers/` / `lib/blocs/` / `lib/controllers/` | State management (Riverpod, BLoC, Provider, GetX, MobX) |
| `lib/models/` / `lib/entities/` | Data model approach (freezed, json_serializable, manual, built_value) |
| `lib/repositories/` / `lib/services/` | Data layer patterns, API abstraction |
| `lib/di/` / `lib/injection/` | Dependency injection setup (get_it, injectable, riverpod) |

### Step 4: Understand Data & API Layer
| File / Directory | What to Learn |
|---|---|
| `lib/api/` / `lib/data/` / `lib/network/` | HTTP client (Dio, http, Chopper, Retrofit), interceptors, base config |
| `lib/models/` | Model serialization approach, JSON handling |
| `lib/utils/` / `lib/helpers/` / `lib/extensions/` | Utility functions, extension methods, constants |
| `lib/l10n/` / `lib/localization/` | Internationalization setup (intl, easy_localization, etc.) |

### Step 5: Understand Styling & Theming
| File / Directory | What to Learn |
|---|---|
| `lib/theme/` / `lib/styles/` | ThemeData definition, color scheme, text styles, custom themes |
| `lib/constants/` | Colors, dimensions, spacing constants |
| `assets/` | Image/font assets organization |

### Step 6: Understand Testing
| File / Directory | What to Learn |
|---|---|
| `test/` (structure) | Test organization, unit vs widget vs integration |
| `test/helpers/` / `test/mocks/` | Test utilities, mock setup (mockito, mocktail) |
| `integration_test/` | Integration/E2E test patterns |

### 🧠 Discovery Summary Template
After inspecting, mentally note:
- **Flutter Version**: 3.x
- **Dart Version**: 3.x
- **State Management**: Riverpod / BLoC / Provider / GetX / MobX
- **Navigation**: GoRouter / auto_route / Navigator 2.0 / named routes
- **DI**: get_it / injectable / riverpod / manual
- **HTTP Client**: Dio / http / Chopper / Retrofit
- **Serialization**: freezed / json_serializable / manual / built_value
- **Architecture**: Clean Architecture / MVVM / MVC / feature-first
- **Testing**: mockito / mocktail / bloc_test
- **Null Safety**: Sound null safety (yes/no)

---

## 📌 General Rules

1. **Preserve existing architecture** — Do not change folder structure, state management approach, or navigation setup
2. **Follow existing patterns** — Match the coding style, naming conventions, and patterns already used in the project
3. **Minimal changes** — Only modify what's necessary to implement the requested feature or fix
4. **No breaking changes** — Ensure existing features continue working after modifications
5. **Respect dependencies** — Use packages already in `pubspec.yaml` before suggesting new ones

---

## 🧩 Adding New Features

### Widgets
- Create new widgets in the same directory pattern as existing ones
- Extend existing base classes if the project uses them
- Follow the project's widget composition style (StatelessWidget vs StatefulWidget vs hooks)
- Reuse existing theme data, colors, and text styles from the project's theme

```dart
// ✅ Follow existing patterns
class NewFeatureWidget extends StatelessWidget {
  const NewFeatureWidget({super.key, required this.data});
  final FeatureData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Use project's theme
    return Container(
      padding: const EdgeInsets.all(16), // Match existing spacing
      child: Text(data.title, style: theme.textTheme.titleMedium),
    );
  }
}
```

### State Management
- Use the **same state management** the project already uses (Riverpod, BLoC, Provider, GetX, etc.)
- Create new state classes following existing patterns
- Place state files in the same locations as existing ones

```dart
// If project uses Riverpod:
final newFeatureProvider = StateNotifierProvider<NewFeatureNotifier, NewFeatureState>((ref) {
  return NewFeatureNotifier(ref.read(existingServiceProvider));
});

// If project uses BLoC:
class NewFeatureBloc extends Bloc<NewFeatureEvent, NewFeatureState> {
  NewFeatureBloc(this._repository) : super(NewFeatureInitial());
  final ExistingRepository _repository;
}
```

---

## 🔧 Modifying Existing Code

### Rules
- **Read the entire file** before making changes
- **Understand dependencies** — Check what other files import/use the code you're changing
- **Preserve null safety** — Maintain existing null handling patterns
- **Keep existing tests passing** — Run tests after changes
- **Add backward compatibility** — Use optional parameters with defaults for new functionality

```dart
// ✅ Adding new parameter with default value
class ExistingWidget extends StatelessWidget {
  const ExistingWidget({
    super.key,
    required this.title,
    this.subtitle,           // existing
    this.showNewFeature = false, // ✅ New param with default — no breaking change
  });
  final String title;
  final String? subtitle;
  final bool showNewFeature;
}
```

---

## 🗄️ Data & Models

- Follow existing model patterns (json_serializable, freezed, manual fromJson, etc.)
- Place new models alongside existing ones
- Reuse existing API client/service classes
- Match error handling patterns already in the project

```dart
// Match existing serialization approach
@freezed // only if project uses freezed
class NewModel with _$NewModel {
  const factory NewModel({
    required String id,
    required String name,
    @Default('') String description,
  }) = _NewModel;

  factory NewModel.fromJson(Map<String, dynamic> json) => _$NewModelFromJson(json);
}
```

---

## 🎨 UI & Styling

- Use the project's existing **ThemeData**, color scheme, and text styles
- Follow existing responsive design patterns
- Reuse existing common widgets (buttons, cards, inputs, etc.)
- Match existing animation patterns and durations
- Follow existing padding/margin conventions

---

## 🧪 Testing

- Add tests for new code following existing test patterns
- Use existing test helpers and mocks
- Place test files matching the source file structure
- Don't modify existing tests unless fixing them is part of the task

---

## 🚫 Don'ts

- ❌ Don't reorganize imports or file structure
- ❌ Don't change existing theme or design system
- ❌ Don't upgrade or add packages without asking
- ❌ Don't refactor working code unless asked
- ❌ Don't change state management approach
- ❌ Don't modify build configuration files
- ❌ Don't change existing navigation/routing setup
- ❌ Don't add linting rules or formatting changes

---

## ✅ Checklist Before Submitting Changes

- [ ] ✅ Project discovery completed — inspected core files
- [ ] Existing tests still pass
- [ ] New code follows project's existing patterns
- [ ] No folder structure changes
- [ ] No unnecessary package additions
- [ ] Backward compatible — no breaking changes
- [ ] Theme and styling consistent with existing UI
- [ ] State management matches project's approach
- [ ] Error handling follows existing patterns

---

*Generated by CodeStandards AI — AI Instructions for Existing Projects*
