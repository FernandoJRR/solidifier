# SOLID — backend reference

Five principles for object-oriented (and broadly, modular) design. They are heuristics, not laws. Each entry below gives: the principle, the backend smell that signals a *real* violation, the concrete pain it causes, the fix, and — equally important — the **over-application smell** that signals you've gone too far.

Read the relevant section when applying or explaining a principle. Apply the prime directive from SKILL.md throughout: a principle is not "violated" just because code is small and direct.

---

## S — Single Responsibility Principle

**A module should have one reason to change.** Group together what changes together; separate what changes for different reasons and at different rates.

**Violation smell (backend):** A class or function that mixes axes of change — e.g., an `OrderService.placeOrder()` that validates input, computes pricing/tax, writes to the database, sends a confirmation email, and emits an analytics event all inline. Each of those changes for a different reason (business rules, schema, email provider, analytics vendor) and forces edits to the same unit.

**Pain it causes:** Every unrelated change touches the same file; merge conflicts; you cannot test pricing without a live DB and mail server; a mail-provider swap risks breaking order placement.

**Fix:** Separate the concerns by reason-to-change. Pricing logic → a pricing component; persistence → a repository; notification → a notifier behind an interface; the service orchestrates them. Each is independently testable.

**Over-application smell:** "One class per method" / anemic objects. Shattering logic that *always changes together* into a swarm of tiny classes (`OrderValidator`, `OrderValidatorFactory`, `OrderValidationResultBuilder`) creates navigation overhead and hides the actual flow. Cohesion is the other half of SRP: things that change together should live together. If two "responsibilities" have never changed independently and plausibly never will, they are one responsibility.

**Test:** Can you name *two distinct stakeholders or reasons* that would force this unit to change? If only one, splitting it is probably premature.

---

## O — Open/Closed Principle

**Software entities should be open for extension but closed for modification.** You should be able to add new behavior without editing existing, tested, stable code — typically by adding a new type that satisfies an existing abstraction.

**Violation smell (backend):** A growing `switch`/`if-else` on a type tag that you must edit every time a new variant appears — `switch (payment.provider) { case "stripe": … case "paypal": … }` — and the same switch is duplicated in several places (charge, refund, webhook handling). Each new provider means editing every switch.

**Pain it causes:** Adding a provider means touching multiple stable files and re-testing all of them; high regression risk; the switches drift out of sync.

**Fix:** Define a `PaymentProvider` abstraction with the needed operations; each provider is a class implementing it; resolve the right one via a registry/map. Adding a provider = adding one class, registering it. Existing code is untouched.

**Over-application smell:** Building extension points for variation that does not exist. A single, stable implementation wrapped in an abstract base "in case we need more later" is speculative generality (YAGNI). OCP earns its keep when you have *two or more* real variants, or a concrete near-term requirement for one. The first time you have one variant, write it directly; introduce the abstraction when the second arrives (rule of three is a fine default).

---

## L — Liskov Substitution Principle

**Subtypes must be substitutable for their base type** without breaking correctness. A caller written against the base type must work with any subtype: no strengthened preconditions, no weakened postconditions, no new exceptions the contract didn't promise, no silently-ignored operations.

**Violation smell (backend):**
- A `ReadOnlyRepository` that extends `Repository` but throws on `save()` — callers holding a `Repository` reference break.
- A subclass that tightens input requirements (base accepts any positive amount; subclass rejects amounts over a limit) so substituting it changes behavior.
- The classic `Square extends Rectangle` where setting width mutates height, violating a caller's assumption.

**Pain it causes:** Polymorphism becomes a trap — code that looks generic fails for specific subtypes, often only in production. Forces defensive `instanceof`/type checks, which themselves violate OCP.

**Fix:** Model the real contract. If read-only and read-write are genuinely different capabilities, they are different interfaces (see ISP), not a subtype relationship. Subtypes may weaken preconditions and strengthen postconditions, never the reverse.

**Over-application smell:** LSP rarely gets *over*-applied, but it gets *misread* as "never use inheritance." Inheritance is fine when the subtype truly *is* a behavioral substitute. The lesson is "prefer composition when the relationship isn't true substitutability," not "ban inheritance."

---

## I — Interface Segregation Principle

**Clients should not be forced to depend on methods they do not use.** Prefer several focused interfaces over one fat general-purpose one.

**Violation smell (backend):** A `God` service interface — `IUserService` with 30 methods covering auth, profile, billing, notifications — that every consumer depends on even though each uses three methods. A change to the billing methods forces recompilation/redeployment of, and re-testing of trust in, the auth consumers. Also: implementers forced to stub methods they don't support (often by throwing — which then trips LSP).

**Pain it causes:** Wide, fragile coupling; test doubles must mock far more than the test needs; unclear which consumer actually relies on what.

**Fix:** Split by consumer need: `Authenticator`, `ProfileReader`, `BillingOperations`. A class may implement several; each client depends only on the slice it uses.

**Over-application smell:** Interface explosion — one interface per method, or an interface for every class reflexively. This multiplies types, dilutes meaning, and makes the codebase harder to navigate than the fat interface did. Segregate along *real consumer boundaries* that exist in the code, not along every conceivable axis.

---

## D — Dependency Inversion Principle

**High-level modules should not depend on low-level modules; both should depend on abstractions.** Business policy should not import the Postgres driver, the AWS SDK, or the HTTP client directly. Define the abstraction the policy needs (e.g., `OrderRepository`, `Clock`, `EmailSender`); implement it with the concrete detail at the system's edge; inject it.

**Violation smell (backend):** Domain/service code that `new`s up or imports concrete infrastructure — `new PostgresClient()`, `new StripeClient()`, `Date.now()`, `fetch(...)` — directly inside business logic. You cannot test the logic without the real database/network/clock; swapping infrastructure means editing core logic.

**Pain it causes:** Untestable units (need real I/O), vendor lock-in scattered through the core, time-dependent tests that flake.

**Fix:** Depend on an interface owned by the high-level module; pass the concrete implementation in via the constructor/parameters (dependency injection — see patterns reference). Wire everything together once, at the composition root (`main`, the DI container, the app factory).

**Over-application smell:** This is the *most* over-applied principle. Symptoms: an interface for every single class regardless of need; interfaces named `IThing` with exactly one implementation `Thing` that will never have a second; a DI container configuring 200 bindings where plain constructor calls would do. An abstraction is justified when it enables (a) substitution you actually need — a test double counts, or (b) a second real implementation, or (c) an architectural boundary you're deliberately enforcing. "It's more SOLID" is not a justification. A concrete dependency on a stable, owned, side-effect-free utility usually needs no interface at all.

**Practical bar:** Introduce an interface when you can name what sits on the other side of it besides the production class — most often "a fake/stub for testing this unit's logic in isolation." If you can't, the concrete class is fine.

---

## Applying SOLID together — the order of operations

1. Get **SRP** right first (clear responsibilities) — most other improvements follow from it.
2. Use **DIP** to make the unit testable by inverting its I/O dependencies (this is usually where the biggest, cheapest win is).
3. Reach for **OCP**/**Strategy**-style abstraction only when a real second variant or a concrete switch-duplication smell appears.
4. Apply **ISP** when an interface has grown fat and consumers depend on slices.
5. Treat **LSP** as a constraint you must never break whenever you do use subtyping/polymorphism.

If a change can't be justified by a concrete present pain or a named, likely-near-term change, the SOLID-correct move is to leave the code alone.
