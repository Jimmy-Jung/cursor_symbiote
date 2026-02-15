# OCP - Open-Closed Principle

## 정의

> "Software entities should be open for extension, but closed for modification."
> "소프트웨어 엔티티는 확장에는 열려있어야 하고, 수정에는 닫혀있어야 한다."

### 핵심 개념

- Open for extension: 새로운 기능을 추가할 수 있어야 함
- Closed for modification: 기존 코드를 수정하지 않고도 확장 가능해야 함
- 구현 방법: Abstraction + Inversion (protocol + 의존성 역전)

## OCP 위반 예제

### if-else/switch 증가 패턴

```swift
// ❌ 새로운 결제 수단 추가 시 기존 코드 수정 필요
class CheckOut {
    func processPayment(amount: Double, type: String) {
        if type == "Cash" {
            print("Processing cash payment")
        } else if type == "CreditCard" {
            print("Processing credit card")
        } else if type == "MobilePayment" {
            print("Processing mobile payment") // 수정 발생!
        }
    }
}
```

## OCP 준수: Abstraction 적용

### Strategy 패턴

```swift
// 1. 추상화 정의
protocol PaymentMethod {
    func pay(amount: Double) async throws -> PaymentResult
}

// 2. 기존 코드는 추상화에만 의존
class CheckOut {
    func processPayment(amount: Double, method: PaymentMethod) async throws {
        try await method.pay(amount: amount)
        // 새 결제 수단 추가 시 이 코드는 수정 불필요!
    }
}

// 3. 구현체 추가로 확장
class CashPayment: PaymentMethod {
    func pay(amount: Double) async throws -> PaymentResult {
        return PaymentResult(success: true)
    }
}

// 4. 확장: 새로운 결제 수단 추가 (CheckOut 수정 불필요!)
class MobilePayment: PaymentMethod {
    func pay(amount: Double) async throws -> PaymentResult {
        return PaymentResult(success: true)
    }
}
```

## OCP 적용 시점

### Agile Design (권장)

```
첫 번째 변경: 직접 수정
두 번째 유사한 변경: 패턴 발견
세 번째 유사한 변경: 추상화 도입 (OCP 적용)
```

"변화에 대한 가장 좋은 예측은 변화를 경험하는 것이다"

### BDUF 피하기

처음부터 모든 것을 추상화하지 말 것. YAGNI 위반.

## Design Smell (OCP 위반 징조)

1. Rigidity (경직성): 작은 변경이 큰 영향 → 전체 시스템 재컴파일
2. Fragility (취약성): 한 곳 수정이 예상치 못한 곳에 영향
3. Immobility (이동 불가능성): 컴포넌트 분리/재사용 불가

## OCP 적용 패턴

### Plugin Architecture

```swift
protocol NotificationPlugin {
    func send(message: String)
}

class NotificationService {
    private var plugins: [NotificationPlugin] = []
    
    func register(plugin: NotificationPlugin) {
        plugins.append(plugin)
    }
    
    func notify(message: String) {
        for plugin in plugins {
            plugin.send(message: message)
        }
    }
}

// 확장: 새 플러그인 추가 (기존 코드 수정 불필요)
class PushNotificationPlugin: NotificationPlugin {
    func send(message: String) { /* APNs 푸시 */ }
}

class EmailNotificationPlugin: NotificationPlugin {
    func send(message: String) { /* 이메일 발송 */ }
}
```

## OCP 위반 감지 체크리스트

```
□ 새 기능 추가 시 기존 클래스를 수정하는가?
□ switch/if-else가 여러 곳에 중복되는가?
□ enum에 case 추가 시 여러 파일을 수정하는가?
□ 타입 체크 (is, as?)를 사용하는가?
□ 새 타입 추가 시 컴파일 에러가 여러 곳에서 발생하는가?
```

## iOS 실무 적용

- Repository: 데이터 소스 교체 가능
- Coordinator: 화면 전환 로직 확장
- Strategy: 알고리즘 교체 가능
- Observer: 이벤트 핸들러 추가
