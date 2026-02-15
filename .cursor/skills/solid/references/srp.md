# SRP - Single Responsibility Principle

## 정의

> "A module should be responsible to one, and only one, actor."
> "모듈은 단 하나의 Actor에게만 책임을 져야 한다."

### 핵심 개념

- Responsibility ≠ Function (책임 ≠ 함수)
- Responsibility = Reason to Change = Actor (책임 = 변경의 이유 = 액터)
- Actor: 변경을 요청하는 사람이나 역할

## 잘못된 이해 vs 올바른 이해

```
❌ "클래스는 한 가지 일만 해야 한다"
❌ "함수를 작게 만들면 SRP를 지킨다"

✅ "하나의 클래스는 한 종류의 클라이언트만 섬겨야 한다"
✅ "서로 다른 Actor가 호출하는 것은 다른 모듈에 분리해야 한다"
```

## Actor 식별 방법

### "누가 이 코드를 변경하려고 하는가?"

```swift
class Employee {
    // Actor 1: CFO (재무 담당)
    func calculatePay() -> Money { }
    
    // Actor 2: COO (운영 담당)
    func reportHours() -> String { }
    
    // Actor 3: CTO (기술 담당)
    func save() { }
}
```

3가지 Actor → 3가지 책임 → SRP 위반!

### iOS에서의 Actor 예시

```
- Design Team: UI 레이아웃, 색상, 폰트
- Business Team: 할인 로직, 가격 계산
- Backend Team: API 엔드포인트, 데이터 구조
- QA Team: 로깅, 에러 리포팅
```

## iOS에서 SRP 적용

### Massive View Controller 문제

```swift
// ❌ SRP 위반: 여러 Actor를 섬김
class ProductListViewController: UIViewController {
    // Actor 1: Design Team (UI)
    private func setupUI() { }
    
    // Actor 2: Backend Team (네트워크)
    private func fetchProducts() {
        URLSession.shared.dataTask(with: url) { ... }
    }
    
    // Actor 3: Business Team (비즈니스 로직)
    private func calculateDiscount(for product: Product) -> Double { }
    
    // Actor 4: Navigation Team (화면 전환)
    private func navigateToDetail(product: Product) { }
}
```

### SRP 준수: 책임 분리

```swift
// Actor 1: Design Team - UI만 담당
class ProductListViewController: UIViewController {
    private let viewModel: ProductListViewModel
    
    init(viewModel: ProductListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

// Actor 2: Backend Team - 네트워크만 담당
protocol ProductRepository {
    func fetchProducts() async throws -> [Product]
}

class NetworkProductRepository: ProductRepository {
    private let apiClient: APIClient
    
    func fetchProducts() async throws -> [Product] {
        try await apiClient.request(.getProducts)
    }
}

// Actor 3: Business Team - 비즈니스 로직만 담당
class PriceCalculator {
    func calculateDiscount(for product: Product) -> Double {
        switch product.category {
        case "Electronics": return product.price * 0.9
        case "Fashion": return product.price * 0.8
        default: return product.price
        }
    }
}

// Actor 4: Navigation Team - 화면 전환만 담당
protocol ProductCoordinator {
    func showProductDetail(product: Product)
}

// ViewModel: 로직 조정만 담당
class ProductListViewModel {
    private let repository: ProductRepository
    private let priceCalculator: PriceCalculator
    private let coordinator: ProductCoordinator
    
    init(
        repository: ProductRepository,
        priceCalculator: PriceCalculator,
        coordinator: ProductCoordinator
    ) {
        self.repository = repository
        self.priceCalculator = priceCalculator
        self.coordinator = coordinator
    }
}
```

## SRP 위반 감지 체크리스트

### 코드 레벨

```
□ 클래스를 설명할 때 "그리고(and)"를 사용하는가?
□ 클래스가 변경되는 이유가 2가지 이상인가?
□ 클래스를 테스트할 때 Mock이 3개 이상 필요한가?
□ 파일이 300줄 이상인가?
□ 두 개발자가 동시에 같은 클래스를 수정하려 하는가?
```

### 팀 레벨

```
□ 디자이너가 비즈니스 로직 파일을 건드리는가?
□ 백엔드 개발자가 UI 파일을 수정하는가?
□ 한 기능 변경이 여러 팀의 코드 리뷰를 필요로 하는가?
```

## 리팩토링 방법

### 방법 1: 클래스 분리

```swift
// Before: Fat Class
class UserManager {
    func validateEmail() { }
    func saveToDatabase() { }
    func sendWelcomeEmail() { }
}

// After: 책임별 분리
class UserValidator { func validateEmail(_ email: String) -> Bool { } }
class UserRepository { func save(_ user: User) { } }
class WelcomeEmailSender { func send(to user: User) { } }
```

### 방법 2: Facade 패턴

```swift
class UserFacade {
    private let validator: UserValidator
    private let repository: UserRepository
    private let emailSender: WelcomeEmailSender
    
    init(validator: UserValidator, repository: UserRepository, emailSender: WelcomeEmailSender) {
        self.validator = validator
        self.repository = repository
        self.emailSender = emailSender
    }
}
```

## 주의사항

### Extension ≠ SRP

```swift
// ❌ Extension으로 나누는 것은 SRP가 아님
extension ProductViewController {
    // 네트워크 관련 ← 여전히 SRP 위반!
}

// ✅ 진짜 SRP: 다른 클래스로 분리
class ProductViewController: UIViewController {
    private let repository: ProductRepository
}
```

## 네이밍 가이드

```swift
// ✅ 책임이 명확한 이름
UserRepository, PriceCalculator, OrderCoordinator, EmailSender

// ❌ 책임이 불명확한 이름
UserManager, Helper, Utility
```
