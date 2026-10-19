# Dependency Injection Setup

> **Status**: Reference document — not yet implemented.

---

## What It Is

Each class receives the objects it needs from outside instead of creating them. One file, the **injection container**, is the only place that knows the concrete classes and how they connect.

---

## Files Involved

```
lib/
├── injection.dart                     # the container: registers everything
├── main.dart                          # calls the container at startup
└── features/
    └── daily_tasks/
        ├── data/
        │   ├── data_sources/          # registered first (lowest level)
        │   └── repositories/impl/     # registered as the domain interface
        ├── domain/
        │   ├── repositories/          # interface only, what gets injected
        │   └── use_cases/             # registered, receive the repository
        └── presentation/
            └── bloc/                  # registered as a factory, receives use cases
```

---

## Setup Steps

1. **Add the package.** Add `get_it` to dependencies. It is the service locator that holds the registrations.

2. **Create the container.** In `lib/injection.dart`, create one global locator and one setup function that registers everything in order:
   - **Data sources first**, since nothing else can exist without them.
   - **Repositories next.** Register each one under its domain interface type, not its implementation type, so the rest of the app only sees the interface.
   - **Use cases next.** Each receives its repository from the locator.
   - **BLoCs last.** Each receives its use cases from the locator.

3. **Choose a registration type for each layer:**
   - Data sources, repositories, and use cases → **singleton** (one shared instance, created when first needed).
   - BLoCs → **factory** (a new instance each time a screen asks for one, so screens don't share state).

4. **Call the setup before the app starts.** In `main.dart`, make `main` async, initialize Flutter's bindings, run the setup function, and only then start the app.

5. **Provide the BLoC to the widget tree.** Inside the app, a page requests its BLoC from the locator and wraps itself in a provider. Widgets below that page read the BLoC from the provider and never call the locator themselves.

6. **Keep the locator out of logic.** Only `injection.dart`, `main.dart`, and the place that creates the provider should reference the locator. BLoCs, use cases, repositories, and widgets receive their dependencies through their constructors.

7. **Swap in fakes for tests.** In test setup, reset the locator, then register fake versions of the repository or data sources. The use cases and BLoC run unchanged, against the fakes.

---

## Checklist

- [ ] Every constructor parameter is a type that is registered, or an abstract type with a registered implementation.
- [ ] No class other than the container and `main` imports the locator.
- [ ] The setup function runs before `runApp`.
- [ ] The BLoC is a **factory**, and everything else is a **singleton**.

