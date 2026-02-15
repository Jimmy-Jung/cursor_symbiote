# DIP - Dependency Inversion Principle

## 정의

> "High-level modules should not depend on low-level modules. Both should depend on abstractions."
> "고수준 정책은 저수준 세부사항에 의존하면 안 된다. 둘은 추상 타입에 의존해야 한다."

### 핵심 개념

- High Level Policy: 비즈니스 로직, 알고리즘, UseCase
- Low Level Details: 데이터베이스, UI, 네트워크, 하드웨어
- Abstract Type: protocol (Swift), @protocol (Objective-C)
- 의존성 역전: 소스 코드 의존성이 런타임과 반대 방향

## 객체지향의 본질

"객체지향 설계 = 의존성 관리"

DIP는 객체지향의 가장 핵심적인 원칙이다.
- 상속, 캡슐화, 다형성은 메카니즘일 뿐
- 진짜 목적은 고수준 정책을 저수준 세부사항으로부터 보호하는 것

### 의존성 방향

```
Runtime 흐름:        고수준 → 저수준 (정상)
Source Code 의존성:  저수준 → 고수준 (역전!)
```

## DIP 위반 예제

### iOS: Massive View Controller

```swift
// ❌ ViewController가 저수준에 직접 의존
class UserListViewController: UIViewController {
    private func fetchUsers() {
        let url = URL(string: "https://api.example.com/users")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else { return }
            let users = try? JSONDecoder().decode([User].self, from: data)
            UserDefaults.standard.set(users?.count, forKey: "userCount")
            DispatchQueue.main.async { self.tableView.reloadData() }
        }.resume()
    }
}
```

문제: 테스트 불가능, API 변경 시 ViewController 수정 필요, Mock 사용 불가

## DIP 준수: 의존성 역전

### Clean Architecture 적용

```swift
// 1. Domain Layer (고수준): protocol 정의
protocol UserRepository {
    func fetchUsers() async throws -> [User]
}

protocol UserStorage {
    func saveUserCount(_ count: Int)
}

// 2. Domain Layer (고수준): UseCase
class FetchUsersUseCase {
    private let repository: UserRepository
    private let storage: UserStorage
    
    init(repository: UserRepository, storage: UserStorage) {
        self.repository = repository
        self.storage = storage
    }
    
    func execute() async throws -> [User] {
        let users = try await repository.fetchUsers()
        storage.saveUserCount(users.count)
        return users
    }
}

// 3. Data Layer (저수준): protocol 구현
class NetworkUserRepository: UserRepository {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func fetchUsers() async throws -> [User] {
        try await apiClient.request(.getUsers)
    }
}

class UserDefaultsStorage: UserStorage {
    func saveUserCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: "userCount")
    }
}

// 4. Main에서 조립 (의존성 주입)
class AppDependencyContainer {
    func makeUserListViewController() -> UserListViewController {
        let apiClient = APIClient()
        let repository = NetworkUserRepository(apiClient: apiClient)
        let storage = UserDefaultsStorage()
        let useCase = FetchUsersUseCase(repository: repository, storage: storage)
        let viewModel = UserListViewModel(fetchUsersUseCase: useCase)
        return UserListViewController(viewModel: viewModel)
    }
}
```

## 레이어 아키텍처와 DIP

```
┌─────────────────────────────────┐
│   Presentation Layer (UI)       │
│   - ViewController, ViewModel   │
└────────────┬────────────────────┘
             │ 의존 (protocol)
             ↓
┌─────────────────────────────────┐
│   Domain Layer (비즈니스 로직)    │
│   - UseCase, Entity             │
│   - Repository Protocol         │
└────────────┬────────────────────┘
             ↑ 구현 (implements)
             │
┌─────────────────────────────────┐
│   Data Layer (세부사항)          │
│   - Repository Impl, API, DB    │
└─────────────────────────────────┘
```

화살표가 위를 향함 (의존성 역전!)

## DIP 적용 패턴

### Plugin 아키텍처

```swift
protocol StoragePlugin {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
}

class UserProfileUseCase {
    private let storage: StoragePlugin
    
    func saveProfile(_ profile: UserProfile) throws {
        try storage.save(profile, forKey: "profile")
    }
}

// Plugin 교체 가능
class UserDefaultsPlugin: StoragePlugin { ... }
class KeychainPlugin: StoragePlugin { ... }

#if DEBUG
let storage: StoragePlugin = UserDefaultsPlugin()
#else
let storage: StoragePlugin = KeychainPlugin()
#endif
```

## DIP 위반 감지 체크리스트

```
□ 클래스가 구체 클래스를 직접 생성하는가? (new, init)
□ import 문에 저수준 모듈이 있는가? (비즈니스 로직에서 Alamofire 등)
□ 고수준 모듈이 저수준 모듈을 직접 참조하는가?
□ 테스트 시 실제 네트워크/DB가 필요한가? → Mock 불가능 = DIP 위반
□ 라이브러리 교체 시 비즈니스 로직 수정이 필요한가?
```

## Protocol 소유권

```
protocol은 고수준 모듈에 위치해야 한다!

✅ 올바른 위치:
Domain/Repositories/UserRepository.swift      ← protocol
Data/Repositories/NetworkUserRepository.swift  ← 구현

❌ 잘못된 위치:
Data/Repositories/UserRepository.swift      ← protocol이 저수준에!
```

## 테스트 용이성

```swift
class MockUserRepository: UserRepository {
    var mockUsers: [User] = []
    
    func fetchUsers() async throws -> [User] {
        return mockUsers
    }
}

func testFetchUsers() async {
    let mockRepo = MockUserRepository()
    mockRepo.mockUsers = [User(name: "Test")]
    
    let useCase = FetchUsersUseCase(repository: mockRepo)
    let users = try? await useCase.execute()
    
    XCTAssertEqual(users?.count, 1)
}
```

## 주의사항

### protocol ≠ 항상 필요

```
필요한 경우:
- 여러 구현체가 예상되는 경우
- 테스트를 위한 Mock이 필요한 경우
- 저수준 세부사항을 숨겨야 하는 경우

불필요한 경우:
- 단일 구현체만 있고 변경 가능성이 없는 경우
- 단순 Value Object (struct)
- Utility 함수
```
