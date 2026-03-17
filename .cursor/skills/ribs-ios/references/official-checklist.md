# RIBs-iOS Official Checklist

## 1) Root Bootstrap
- Root router is `LaunchRouter<...>`.
- App entry calls `launchRouter.launch(from: window)`.
- Root interactor activation is not manually forced outside router lifecycle.

## 2) Responsibility Boundaries
- Interactor focuses on business logic and state decisions.
- Router owns child builders and controls attach/detach.
- Builder wires dependencies and internal objects only.
- View/Presenter only forwards user intents and renders state.

## 3) Dependency Injection
- Parent dependency protocol exists (`XDependency: Dependency`).
- Builder type is `Builder<XDependency>`.
- Component exists when child RIBs need scoped/shared deps.
- Child builders consume only child dependency protocol, not app-level concrete types.

## 4) Communication
- View -> Interactor uses `PresentableListener`.
- Child -> Parent uses `Listener` protocol.
- Cross-RIB direct references are avoided.

## 5) Lifecycle and Routing
- Child RIB is attached exactly once per active route.
- Route change detaches previous child before attaching next child.
- No detached interactor is used for business actions.

## 6) Review Red Flags
- Interactor has properties like `loggedOutBuilder`, `loggedInBuilder`.
- App builds child RIBs directly instead of through root router.
- Root view is mounted directly without `LaunchRouter` flow.
- ViewModel directly holds interactor concrete type.
