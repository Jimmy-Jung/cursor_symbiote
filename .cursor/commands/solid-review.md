<!-- source: origin -->

# SOLID 원칙 분석

> tracking: `bash .cursor/hooks/usage-tracker.sh commands solid-review`

대상 코드에 SOLID 원칙을 적용하여 설계 품질을 분석하고 리팩토링을 제안합니다:

1. `.cursor/skills/solid/SKILL.md`를 읽어 SOLID 원칙 워크플로우를 로드합니다.
2. 대상 코드(선택된 파일 또는 @멘션된 파일)를 읽고 각 원칙별 위반 여부를 검사합니다:
   - DIP: 구체 클래스 직접 의존, protocol 미사용, 고수준→저수준 의존
   - SRP: 여러 Actor를 섬기는 클래스, 300줄 이상 파일, Mock 3개 이상 필요
   - OCP: switch/if-else 증가 패턴, enum case 추가 시 다수 파일 수정
   - ISP: Fat Interface, fatalError 구현, 미사용 메서드 의존
   - LSP: fatalError override, 타입 캐스팅(as?, is) 사용, 계약 위반
3. 상세 분석이 필요한 원칙은 `.cursor/skills/solid/references/` 하위 파일을 참조합니다.
4. 결과를 다음 형식으로 보고합니다:

```
## SOLID 분석 결과

### 위반 사항
| 원칙 | 심각도 | 위치 | 설명 |
|------|--------|------|------|

### 리팩토링 제안
(우선순위순: DIP → SRP → OCP → ISP → LSP)

### 준수 사항
(잘 지켜지고 있는 원칙과 근거)
```

5. 리팩토링 제안 시 Before/After 코드를 함께 제시합니다.
