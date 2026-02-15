# ISP - Interface Segregation Principle

## 정의

> "Clients should not be forced to depend on interfaces they do not use."
> "클라이언트는 자신이 사용하지 않는 인터페이스에 의존하면 안 된다."

### 핵심 개념

- Fat Interface (비대한 인터페이스) 분리
- 클라이언트별로 필요한 인터페이스만 제공
- 인터페이스는 클라이언트 관점에서 설계
- 사용하지 않는 메서드 변경 시에도 재컴파일 방지

## ISP 위반 예제

### Fat Interface

```swift
// ❌ 비대한 인터페이스
protocol Worker {
    func work()
    func eat()
    func sleep()
    func reportWork()
    func takeBreak()
}

// Robot은 eat, sleep이 필요없음!
class Robot: Worker {
    func work() { print("Working") }
    func eat() { fatalError("Robots don't eat") }      // 불필요
    func sleep() { fatalError("Robots don't sleep") }  // 불필요
    func reportWork() { print("Reporting") }
    func takeBreak() { fatalError("No breaks") }       // 불필요
}
```

## ISP 준수: 인터페이스 분리

```swift
protocol Workable { func work() }
protocol Eatable { func eat() }
protocol Sleepable { func sleep() }
protocol Reportable { func reportWork() }

// Robot은 필요한 것만 채택
class Robot: Workable, Reportable {
    func work() { print("Working") }
    func reportWork() { print("Reporting") }
}

// Human은 모두 채택
class Human: Workable, Eatable, Sleepable, Reportable {
    func work() { print("Working") }
    func eat() { print("Eating") }
    func sleep() { print("Sleeping") }
    func reportWork() { print("Reporting") }
}
```

## 인터페이스 설계 원칙

### 클라이언트 관점에서 설계

```swift
// ❌ 구현체 관점
protocol Light {
    func lightOn()
    func lightOff()
    func fanOn()
    func fanOff()
}

// ✅ 클라이언트(Switch) 관점
protocol Switchable {
    func turnOn()
    func turnOff()
}

class Switch {
    private let device: Switchable
    func activate() { device.turnOn() }
}

class Light: Switchable {
    func turnOn() { print("Light on") }
    func turnOff() { print("Light off") }
}

class Fan: Switchable {
    func turnOn() { print("Fan on") }
    func turnOff() { print("Fan off") }
}
```

인터페이스 이름은 구현체가 아닌 클라이언트 관점!

### Fat Class 발견 시

```swift
// ❌ Fat Class
class Job {
    func calculateExpense() { }     // ExpenseSystem만 사용
    func generateInvoice() { }      // InvoiceSystem만 사용
    func calculateTax() { }         // TaxSystem만 사용
}

// ✅ 인터페이스 분리
protocol ExpenseCalculator { func calculateExpense() }
protocol InvoiceGenerator { func generateInvoice() }
protocol TaxCalculator { func calculateTax() }

class Job: ExpenseCalculator, InvoiceGenerator, TaxCalculator {
    func calculateExpense() { }
    func generateInvoice() { }
    func calculateTax() { }
}

// 각 시스템은 필요한 protocol만 의존
class ExpenseSystem {
    private let calculator: ExpenseCalculator
}
```

## iOS 실전 적용

### Delegate 분리

```swift
protocol UserFetchDelegate: AnyObject {
    func didFetchUser(_ user: User)
    func didFailToFetchUser(_ error: Error)
}

protocol UserSaveDelegate: AnyObject {
    func didSaveUser(_ user: User)
    func didFailToSaveUser(_ error: Error)
}

// 클라이언트는 필요한 것만 채택
class UserListViewController: UIViewController, UserFetchDelegate {
    func didFetchUser(_ user: User) { }
    func didFailToFetchUser(_ error: Error) { }
}

class UserEditorViewController: UIViewController, UserSaveDelegate {
    func didSaveUser(_ user: User) { }
    func didFailToSaveUser(_ error: Error) { }
}
```

### Combine Input/Output 분리

```swift
protocol LoginViewModelInput {
    func login(email: String, password: String)
    func forgotPassword()
}

protocol LoginViewModelOutput {
    var isLoading: AnyPublisher<Bool, Never> { get }
    var loginResult: AnyPublisher<Result<User, Error>, Never> { get }
}

class LoginViewModel: LoginViewModelInput, LoginViewModelOutput {
    func login(email: String, password: String) { }
    func forgotPassword() { }
    var isLoading: AnyPublisher<Bool, Never> { ... }
    var loginResult: AnyPublisher<Result<User, Error>, Never> { ... }
}
```

## ISP 위반 감지 체크리스트

```
□ protocol에 10개 이상의 메서드가 있는가?
□ protocol 구현 시 fatalError()나 빈 구현이 있는가?
□ 클라이언트가 protocol의 일부 메서드만 사용하는가?
□ protocol 변경 시 관련 없는 클라이언트도 영향받는가?
□ protocol 이름이 구체 클래스를 나타내는가?
```

## 네이밍 컨벤션

```swift
// ✅ 클라이언트 이름 기반
protocol Switchable { }      // Switch가 사용
protocol Printable { }       // Printer가 사용
protocol Readable { }        // Reader가 사용

// ❌ 구현체 이름 기반
protocol LightInterface { }  // 잘못된 네이밍
```
