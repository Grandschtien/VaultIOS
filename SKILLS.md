# Vault iOS Context

## Product
- Working title: `LLM Expense Tracker`
- Platform: iPhone-first iOS application
- Goal: users add expenses in free-form text, the LLM parses them into structured entries, and the user confirms or corrects the result before saving

## Technical Rules
- Architecture: `VIPER`
- Primary UI framework: `UIKit`
- Primary layout framework: `SnapKit`
- All modules must be created through factories built with `Nivelir`
- All navigation must go through `Nivelir`
- Network calls must go through `NetworkService`
- Every service must be abstracted behind a protocol
- Every new service must include tests
- Prefer Swift Concurrency for async work
- Do not introduce `GCD` or `Operation`-based concurrency for new code

## Client Domain Models

`ErrorResponse`
- `error: string`

`TokensResponse`
- `access_token: string`
- `refresh_token: string`
- `token_type: string`
- `expires_in: int64`

`ProfileResponse`
- `id: string`
- `email?: string`
- `name: string`
- `currency: string`
- `preferred_language: string`
- `tier: string`
- `tier_valid_until?: time.Time`

`AuthResponse`
- `access_token: string`
- `refresh_token: string`
- `token_type: string`
- `expires_in: int64`
- `user: ProfileResponse`

`Category`
- `id: string`
- `name: string`
- `icon: string`
- `color: string`

`RateResponse`
- `currency: string`
- `rate_to_usd: float64`
- `as_of: string`

`ExpenseResponse`
- `id: string`
- `title: string`
- `description?: string`
- `amount: float64`
- `currency: string`
- `category: string`
- `time_of_add: string`

`ExpenseCreateResponse`
- `expenses: ExpenseResponse[]`

`ExpenseListResponse`
- `expenses: ExpenseResponse[]`
- `next_cursor?: string`
- `has_more: bool`

`ExpenseSummaryByCategory`
- `category: string`
- `total: float64`

`ExpenseSummaryResponse`
- `category?: string`
- `total: float64`
- `currency: string`
- `by_category?: ExpenseSummaryByCategory[]`

`ParsedExpenseResponse`
- `title: string`
- `amount: float64`
- `currency: string`
- `category: string`
- `suggested_category?: string`
- `confidence: float64`

`UsageResponse`
- `entries_used: int32`
- `entries_limit: int32`
- `resets_at: time.Time`

`ParseResponse`
- `expenses: ParsedExpenseResponse[]`
- `usage: UsageResponse`
- `error?: string`

`LimitReachedResponse`
- `error: string`
- `resets_at: time.Time`
- `usage: UsageResponse`

`CreateCategoryResponse`
- `category: Category`

`ListCategoriesResponse`
- `categories: Category[]`

**Health Responses**

Healthy response:
- `status: "ok"`
- `service: "vault-backend"`

Unhealthy response:
- `status: "error"`
- `service: "vault-backend"`
- `error: string`

## Engineering Guardrails
- Never auto-save AI parsed data without user confirmation
- Never bypass `Nivelir` for screen transitions
- Never call networking directly from presentation or view layers
- Never introduce a concrete service dependency where a protocol should be injected
- Never add a new service without tests
- Never hand-write mocks when `Sourcery` generation is the intended path
- Never use `GCD` or `OperationQueue` in new code when Swift Concurrency can express the flow
