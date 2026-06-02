# Design patterns — backend reference

A working catalog for backend code. Each entry: **intent** (one line), **use when**, and **avoid when / sign of misuse**. The "avoid when" is the most important part — patterns applied without a real need are a primary source of over-engineered code. Always name the concrete axis of variation or the specific pain *before* reaching for a pattern.

A pattern is a vocabulary for a solution that recurs, not a checklist to complete. The best code uses few patterns, each clearly earning its place.

## Contents
- [How to choose](#how-to-choose)
- [Creational](#creational): Factory Method, Abstract Factory, Builder, Singleton, Dependency Injection
- [Structural](#structural): Adapter, Facade, Decorator, Proxy, Composite, Bridge
- [Behavioral](#behavioral): Strategy, Observer, Command, Template Method, Chain of Responsibility, State, Mediator
- [Enterprise / backend](#enterprise--backend): Repository, Unit of Work, Service Layer, DTO, Specification, Outbox, CQRS, Circuit Breaker, Retry/Backoff, Saga

---

## How to choose

1. Name the problem precisely: *what varies*, or *what hurts*? ("Three notification channels and we'll add more" / "this 9-arg constructor is unreadable" / "we keep coupling to a vendor SDK".)
2. Pick the lightest tool that addresses exactly that. Often the answer is a plain function, a map/dict lookup, or a language feature — not a named pattern.
3. If no axis of variation and no concrete pain exist, **use no pattern**. Direct code is the correct default.

---

## Creational

### Factory Method / Factory function
**Intent:** Defer the choice of which concrete type to instantiate to a single place, behind a stable creation interface.
**Use when:** Construction is non-trivial or conditional (pick an implementation by config/input), and you want callers to depend on the abstraction, not the concrete type. Centralizes the `switch` that OCP wants closed.
**Avoid when:** It wraps a single constructor with no branching ("`UserFactory.create()` → `new User()`"). That is ceremony. A constructor or a simple function is enough until there's real selection logic.

### Abstract Factory
**Intent:** Create *families* of related objects that must be used together, without binding to their concrete classes.
**Use when:** You have multiple coherent product families (e.g., a full set of cloud primitives for AWS vs. GCP) and a unit must use one consistent family.
**Avoid when:** There's only one family, or the products aren't actually related. This is one of the heaviest patterns; most code never needs it. A single Factory or DI wiring usually suffices.

### Builder
**Intent:** Construct a complex object step by step; separate construction from representation.
**Use when:** An object has many optional/!configurable fields, invariants to validate before it's usable, or you want immutable results without telescoping constructors. Useful for assembling complex requests, query objects, or test fixtures.
**Avoid when:** The object has a few fields — named/keyword args, an options object, or a record/dataclass is simpler. A builder for a 3-field struct is overkill.

### Singleton
**Intent:** Ensure exactly one instance and a global access point.
**Use when:** Rarely. Genuine cases: a single connection pool or a process-wide cache where one instance is a hard requirement.
**Avoid when:** Almost always, prefer a single instance *created at the composition root and injected* (DIP) over the Singleton pattern. Classic Singleton introduces global mutable state, hidden dependencies, and test pain (can't substitute, leaks across tests). Treat it as a smell unless you can defend the global access requirement specifically.

### Dependency Injection (not GoF, central to backend)
**Intent:** A class receives its collaborators from outside rather than constructing them — the runtime concretization of DIP.
**Use when:** Almost always for I/O-bound collaborators (repositories, clients, clocks, mailers). It's what makes units testable and the composition explicit. Constructor injection is the default; a DI container is optional sugar.
**Avoid when:** Injecting stable, pure, owned utilities behind interfaces for no substitution benefit. Don't let a container hide so much wiring that control flow becomes untraceable. Manual constructor injection is perfectly good and often clearer than a container.

---

## Structural

### Adapter
**Intent:** Convert one interface into another a client expects — wrap a third-party/legacy API in the shape your code wants.
**Use when:** Integrating an external SDK or legacy module whose interface you don't control; the adapter is also the natural DIP boundary that keeps vendor types out of your core.
**Avoid when:** You control both sides and could just change one. Don't adapt your own freshly written code to itself.

### Facade
**Intent:** A single simplified entry point over a complex subsystem.
**Use when:** A subsystem has many moving parts and most callers want one coherent high-level operation; the facade reduces coupling to internals.
**Avoid when:** It becomes a God object that grows every method anyone wants, or it just forwards one-to-one to one class (adds nothing).

### Decorator
**Intent:** Add behavior to an object dynamically by wrapping it in an object of the same interface.
**Use when:** You want composable, optional cross-cutting behavior over a core operation — logging, caching, retry, auth checks layered around a repository/client — without subclass explosion. Each decorator does one thing and stacks.
**Avoid when:** There's only ever one combination — just write it inline or in the class. Deep decorator stacks can also obscure where behavior comes from; keep the stack shallow and named.

### Proxy
**Intent:** A stand-in controlling access to another object (lazy init, access control, remote, caching).
**Use when:** You need to interpose on access transparently — lazy-loading an expensive resource, a caching layer, a remote stub.
**Avoid when:** The interposition isn't actually needed, or a Decorator/explicit cache expresses intent more clearly. Distinguish from Decorator by intent: Proxy controls *access*, Decorator adds *behavior*.

### Composite
**Intent:** Treat individual objects and compositions of objects uniformly via a tree.
**Use when:** You have a genuine part-whole hierarchy and want to operate on nodes and subtrees the same way (org charts, nested categories, expression trees).
**Avoid when:** The data isn't really recursive/tree-shaped. Forcing a flat list into Composite adds nothing.

### Bridge
**Intent:** Decouple an abstraction from its implementation so the two vary independently.
**Use when:** You have two independent axes of variation that would otherwise multiply into a class explosion (e.g., shape × rendering backend).
**Avoid when:** There's only one axis — that's just Strategy or plain polymorphism. Bridge is rarely needed; reach for it only when the two-axis explosion is real.

---

## Behavioral

### Strategy
**Intent:** Define a family of interchangeable algorithms behind a common interface; select one at runtime.
**Use when:** The textbook OCP fix — multiple interchangeable behaviors for the same job (pricing rules, sorting policies, payment/notification providers) selected by config or input. Usually the *first* pattern to reach for when a `switch` on behavior keeps growing.
**Avoid when:** There's a single algorithm, or the variants are one-liners better expressed as a passed-in function/lambda. In most languages a higher-order function *is* the lightweight Strategy — don't build a class hierarchy for it.

### Observer / Pub-Sub
**Intent:** Notify interested parties of events without the source knowing the subscribers.
**Use when:** One event has several independent reactions that shouldn't be hardwired into the source (domain events → update read model, send email, emit metric). Decouples producers from consumers.
**Avoid when:** There's exactly one consumer and a direct call is clearer; or when implicit fan-out makes the control flow impossible to follow. Async/event-driven flow trades traceability for decoupling — use it when the decoupling is worth that cost.

### Command
**Intent:** Encapsulate a request as an object (its action + parameters), enabling queuing, logging, undo, and retry.
**Use when:** You need to queue/schedule work, build an audit log of actions, support undo, or hand operations to a worker. Backing pattern for task/job systems and CQRS write commands.
**Avoid when:** A plain function call does the job. Don't objectify every operation reflexively.

### Template Method
**Intent:** Define an algorithm's skeleton in a base method, letting subclasses fill in specific steps.
**Use when:** Several flows share an identical sequence with a few varying steps and the structure is genuinely fixed.
**Avoid when:** Composition (Strategy / injected steps) would be more flexible — Template Method bakes in an inheritance relationship and can lead to fragile base classes. Prefer composition unless the skeleton is truly invariant.

### Chain of Responsibility
**Intent:** Pass a request along a chain of handlers until one handles it.
**Use when:** Pipeline-style processing where each stage may handle, transform, or pass along — middleware stacks, validation pipelines, request filters.
**Avoid when:** The order/handling is fixed and known — a plain sequence of calls is clearer. Don't hide a simple if/else ladder behind a chain.

### State
**Intent:** Let an object alter its behavior when its internal state changes, by delegating to state objects.
**Use when:** An entity has many states with state-specific behavior and complex transitions (order lifecycle, connection state) and the `switch (state)` blocks are sprawling and duplicated.
**Avoid when:** Few states with trivial behavior — an enum plus a small transition map/function is simpler and more transparent than a class per state.

### Mediator
**Intent:** Centralize complex many-to-many communication between objects into one coordinator.
**Use when:** A set of components have tangled mutual references; a mediator turns N×N coupling into N×1.
**Avoid when:** Coupling is mild — a mediator can itself become a God object. Only worth it when the mutual-reference tangle is real.

---

## Enterprise / backend

These appear constantly in services, APIs, and data-heavy systems.

### Repository
**Intent:** Mediate between domain and data mapping, exposing a collection-like interface for aggregates and hiding the persistence mechanism.
**Use when:** You want domain/service logic free of query details, swappable storage, and unit tests against an in-memory fake. The canonical DIP boundary for persistence.
**Avoid when:** It degenerates into a thin pass-through over the ORM with one method per query (`getUserByEmailAndStatusAndRegion`) — at that point it adds indirection without abstraction. Also avoid building a generic `Repository<T>` so abstract it leaks query concerns back to callers. Keep repository methods expressed in domain terms.

### Unit of Work
**Intent:** Track changes across a business transaction and commit/rollback them atomically as one unit.
**Use when:** A single operation mutates several aggregates that must persist atomically; pairs with Repository. Many ORMs/session objects already implement this — often you just use theirs.
**Avoid when:** Single-entity operations, or when your ORM session already gives you transactional consistency. Don't hand-roll one you already have.

### Service Layer / Application Service
**Intent:** Define the application's use-case boundary — orchestration that coordinates domain objects, repositories, and transactions per use case.
**Use when:** You need a clear seam between transport (HTTP/gRPC) and domain logic, so use cases are reusable and testable independent of the framework.
**Avoid when:** It becomes a "transaction script" dumping ground with all logic and an anemic domain beneath it — that's the absence of design wearing a layer's name. Keep real business rules in the domain; the service orchestrates.

### DTO (Data Transfer Object)
**Intent:** A flat object carrying data across a boundary (API ↔ client, layer ↔ layer), decoupling wire/contract shape from internal models.
**Use when:** You must stop internal/domain models from leaking into your API contract, or shape data for transport. Protects the contract from refactors of internals.
**Avoid when:** Mechanically duplicating every entity into an identical DTO with zero divergence and no boundary benefit — that's boilerplate. Introduce a DTO where the external contract and internal model genuinely differ or must evolve independently.

### Specification
**Intent:** Encapsulate a business rule/query predicate as a composable, reusable object.
**Use when:** The same complex selection/validation rule is reused across query, validation, and in-memory checks, and you want to compose rules (and/or/not).
**Avoid when:** A rule is used once — a plain predicate function is clearer. Specification earns its weight only through reuse and composition.

### Outbox
**Intent:** Reliably publish events/messages by writing them to an "outbox" table in the *same* DB transaction as the state change, then relaying them asynchronously — avoids the dual-write problem.
**Use when:** You must update the database and emit an event/message, and losing the event (or emitting it without the DB commit) is unacceptable. The standard fix for "we wrote to the DB but the broker publish failed."
**Avoid when:** You don't actually have a dual-write consistency requirement, or a single transactional resource covers both. It adds a relay process and at-least-once delivery semantics (consumers must be idempotent) — real operational cost; adopt only for the consistency need.

### CQRS (Command Query Responsibility Segregation)
**Intent:** Separate the write model (commands) from the read model (queries), optimizing and scaling each independently.
**Use when:** Read and write workloads diverge sharply in shape/scale, or reads need denormalized projections the write model shouldn't carry.
**Avoid when:** Most CRUD apps — CQRS adds substantial complexity (often eventual consistency between models). Splitting a simple domain into command/query halves with no divergent need is a textbook over-engineering trap. Start with a single model; segregate when the pain is concrete.

### Circuit Breaker
**Intent:** Stop calling a failing downstream dependency after a failure threshold, fail fast, and probe for recovery — prevents cascading failures.
**Use when:** Calling a remote dependency that can fail or slow down, where hammering it worsens an outage (resource exhaustion, thread pileups).
**Avoid when:** Purely local/in-process calls, or one-shot scripts. Use a vetted library rather than hand-rolling the state machine.

### Retry with backoff
**Intent:** Retry transient failures with increasing delays (plus jitter) instead of failing immediately.
**Use when:** Operations against networks/services with *transient* faults (timeouts, throttling, 503s).
**Avoid when:** The failure is non-transient (a 400/validation error — retrying is futile and harmful), or the operation isn't idempotent (retries can double-apply). Always cap attempts and add jitter; pair with a circuit breaker for sustained failures.

### Saga
**Intent:** Manage a long-running transaction across multiple services as a sequence of local transactions, each with a compensating action to undo on failure.
**Use when:** A business process spans several services/databases where a distributed ACID transaction isn't feasible and you need eventual consistency with rollback semantics.
**Avoid when:** The work fits in a single local transaction, or it's a monolith with one database. Sagas are complex (orchestration/choreography, compensation logic, partial-failure handling) — only adopt for genuine cross-service consistency needs.

---

## Final rule

For every pattern you introduce, you should be able to finish this sentence concretely: *"I'm adding this because **\<specific present problem or named, likely-near-term change\>**, and the alternative — \<simpler option\> — falls short because \<reason\>."* If you can't, don't add it. Removing an unjustified pattern is as valid an improvement as adding a justified one.
