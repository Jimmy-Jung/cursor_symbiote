# LSP - Liskov Substitution Principle

## 정의

> "Subtypes must be substitutable for their base types."
> "서브타입은 항상 기반 타입으로 대체 가능해야 한다."

### 핵심 개념

- 서브타입이 기반 타입의 계약(contract)을 위반하면 안 됨
- 클라이언트는 구체 타입을 몰라도 동작해야 함
- LSP 위반 시 OCP도 위반됨

## 계약(Contract) 구성 요소

### 1. 사전조건 (Precondition)

서브타입은 사전조건을 강화할 수 있지만 약화시키면 안 됨.

```swift
class Calculator {
    // 사전조건: b != 0
    func divide(_ a: Double, by b: Double) -> Double {
        guard b != 0 else { fatalError("0으로 나눌 수 없습니다") }
        return a / b
    }
}

// ✅ 올바른 서브타입: 더 강한 조건 (b > 0)
class SafeCalculator: Calculator {
    override func divide(_ a: Double, by b: Double) -> Double {
        guard b > 0 else { fatalError("양수만 가능") }
        return super.divide(a, by: b)
    }
}
```

### 2. 사후조건 (Postcondition)

서브타입은 사후조건을 약화할 수 있지만 강화시키면 안 됨.

### 3. 불변식 (Invariant)

서브타입은 불변식을 항상 유지해야 함.

```swift
class Account {
    var balance: Double = 0
    // 불변식: balance >= 0
    
    func withdraw(_ amount: Double) {
        guard balance >= amount else { fatalError("잔액 부족") }
        balance -= amount
    }
}

// ❌ LSP 위반: 불변식 위반
class OverdraftAccount: Account {
    override func withdraw(_ amount: Double) {
        balance -= amount  // balance < 0 허용!
    }
}
```

## 유명한 LSP 위반: Rectangle과 Square

```swift
class Rectangle {
    var width: Double
    var height: Double
    
    func setWidth(_ w: Double) { width = w }
    func setHeight(_ h: Double) { height = h }
    func area() -> Double { return width * height }
}

// ❌ LSP 위반
class Square: Rectangle {
    override func setWidth(_ w: Double) {
        width = w
        height = w  // 높이도 함께 변경!
    }
}

// 테스트 실패
func testRectangle(rect: Rectangle) {
    rect.setWidth(5)
    rect.setHeight(4)
    assert(rect.area() == 20)  // Square면 실패! (16이 됨)
}
```

### 해결: 상속 관계 제거

```swift
protocol Shape {
    func area() -> Double
}

class Rectangle: Shape {
    let width: Double
    let height: Double
    func area() -> Double { return width * height }
}

class Square: Shape {
    let side: Double
    func area() -> Double { return side * side }
}
```

## iOS에서 LSP 적용

```swift
// ❌ LSP 위반
class BaseViewController: UIViewController {
    func loadData() { }
}

class UserViewController: BaseViewController {
    override func loadData() {
        fatalError("사용하지 않습니다") // 계약 위반!
    }
}

// ✅ LSP 준수
protocol DataLoadable {
    func loadData()
}

class BaseViewController: UIViewController { }

class UserViewController: BaseViewController, DataLoadable {
    func loadData() { /* 제대로 구현 */ }
}

class StaticViewController: BaseViewController {
    // DataLoadable 채택 안 함
}
```

## 리팩토링 방법

### 상속 → Composition

```swift
// ❌ 상속
class Bird { func fly() { } }
class Penguin: Bird {
    override func fly() { fatalError("Can't fly") } // LSP 위반!
}

// ✅ Composition
protocol Movable { func move() }
class FlyingBehavior: Movable { func move() { print("Flying") } }
class SwimmingBehavior: Movable { func move() { print("Swimming") } }

class Bird {
    let moveBehavior: Movable
    init(moveBehavior: Movable) { self.moveBehavior = moveBehavior }
    func move() { moveBehavior.move() }
}
```

## LSP 위반 감지 체크리스트

```
□ instanceof 체크나 타입 캐스팅(as?, is)을 사용하는가?
□ 서브타입에서 메서드가 fatalError()를 던지는가?
□ 서브타입 추가 시 클라이언트 코드 수정이 필요한가?
□ 서브타입이 기반 타입의 예상 동작과 다른가?
□ 클라이언트가 구체 타입을 알아야 하는가?
```

## Representative Rule

> "대리인은 자신이 대리하는 것들의 관계까지 대리하지 않는다"

기하학적으로 Square IS-A Rectangle이지만, 소프트웨어에서는 그렇지 않을 수 있다.
IS-A 관계 ≠ 상속 관계. protocol로 공통점만 추출하라.
