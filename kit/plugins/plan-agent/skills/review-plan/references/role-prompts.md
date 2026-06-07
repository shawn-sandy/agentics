# Reviewer Role Prompts

These prompts are used to brief each teammate reviewer. Substitute `<ABSOLUTE_PATH>` with the resolved plan path.

## Core Reviewers (always spawned)

### Architecture Reviewer

Read the implementation plan at `<ABSOLUTE_PATH>` and review it from an **architecture** lens: component boundaries, layer separation, data flow, integration with existing patterns, and system design coherence.

Focus on:
- Component structure and boundaries
- Dependency direction and encapsulation
- Integration with existing architectural patterns
- Data models and flow
- External system dependencies and isolation
- Scalability and extensibility concerns

Report your findings by calling `SendMessage` with:

```
[Architecture Review]
Fit: <One sentence on architectural soundness>
Concerns:
- <concern 1> (severity: critical|high|medium|low)
- <concern 2> (severity: ...)
- ...
Recommendations:
- <recommendation 1>
- <recommendation 2>
- ...
Architecture Review complete.
```

---

### Completeness Reviewer

Read the implementation plan at `<ABSOLUTE_PATH>` and review it from a **completeness** lens: are all necessary steps present? Are they specific enough to execute? Are critical files omitted? Is the path from start to finish unbroken?

Focus on:
- Step granularity and specificity
- File coverage (created, modified, deleted)
- Missing edge cases or scaffolding
- Acceptance criteria clarity and falsifiability
- Verification feasibility

Report your findings by calling `SendMessage` with:

```
[Completeness Review]
Completeness: <One sentence on specificity and coverage>
Gaps:
- <gap 1> (severity: critical|high|medium|low)
- <gap 2> (severity: ...)
- ...
Recommendations:
- <recommendation 1>
- <recommendation 2>
- ...
Completeness Review complete.
```

---

### Testability Reviewer

Read the implementation plan at `<ABSOLUTE_PATH>` and review it from a **testability** lens: are the changes properly tested? Is there an objective-verification test? Are acceptance criteria verifiable? Are test descriptions specific enough?

Focus on:
- Test coverage (unit, integration, E2E as appropriate)
- Objective-verification test presence and quality
- Acceptance criteria testability
- Test granularity and specificity
- Integration testing for multi-module changes

Report your findings by calling `SendMessage` with:

```
[Testability Review]
Test coverage: <One sentence on test sufficiency>
Gaps:
- <gap 1> (severity: critical|high|medium|low)
- <gap 2> (severity: ...)
- ...
Recommendations:
- <recommendation 1>
- <recommendation 2>
- ...
Testability Review complete.
```

---

### Risk Reviewer

Read the implementation plan at `<ABSOLUTE_PATH>` and review it from a **risk** lens: what could go wrong? Identify breaking changes, data safety issues, concurrency risks, dependency hazards, and rollback challenges.

Focus on:
- Breaking API or data contract changes
- Data safety and migration risk
- Concurrency and race condition hazards
- Dependency vulnerabilities or version risks
- Operational rollback feasibility
- Performance impact concerns

Report your findings by calling `SendMessage` with:

```
[Risk Review]
Risk level: <critical|high|medium|low>
Key risks:
- <risk 1> (severity: critical|high|medium|low)
- <risk 2> (severity: ...)
- ...
Mitigations:
- <mitigation 1>
- <mitigation 2>
- ...
Risk Review complete.
```

---

### Conventions Reviewer

Read the implementation plan at `<ABSOLUTE_PATH>` and review it from a **conventions** lens: do the proposed changes fit the project's patterns, naming style, file organization, and code structure?

Focus on:
- Naming consistency (camelCase, kebab-case, PascalCase)
- File organization and placement
- Code style and formatting
- Dependency and import organization
- Testing patterns and file naming
- Documentation and comment style

Report your findings by calling `SendMessage` with:

```
[Conventions Review]
Fit: <One sentence on pattern and style adherence>
Issues:
- <issue 1> (severity: critical|high|medium|low)
- <issue 2> (severity: ...)
- ...
Recommendations:
- <recommendation 1>
- <recommendation 2>
- ...
Conventions Review complete.
```

---

## Conditional Reviewers (spawned only when UI signals detected)

### UX Reviewer

Read the implementation plan at `<ABSOLUTE_PATH>` and review it from a **UX** lens: is the user experience clear, coherent, and frictionless? Are user flows, error states, and interactions well-thought-out?

**This reviewer runs only on plans that mention React, Vue, Svelte, buttons, modals, forms, or other UI signals.**

Focus on:
- User flows and happy-path clarity
- Error states and error recovery
- Loading and empty states
- Button labels, form fields, and call-to-action clarity
- Responsive design for mobile, tablet, desktop
- Feature discoverability and navigation

Report your findings by calling `SendMessage` with:

```
[UX Review]
User fit: <One sentence on experience quality>
Concerns:
- <concern 1> (severity: critical|high|medium|low)
- <concern 2> (severity: ...)
- ...
Recommendations:
- <recommendation 1>
- <recommendation 2>
- ...
UX Review complete.
```

---

### Accessibility Reviewer

Read the implementation plan at `<ABSOLUTE_PATH>` and review it from an **accessibility** lens: does it meet WCAG 2.1 AA standards? Are semantic HTML, keyboard navigation, screen reader support, and assistive technology needs addressed?

**This reviewer runs only on plans that mention React, Vue, Svelte, buttons, modals, forms, or other UI signals.**

Focus on:
- Keyboard navigation and focus management
- Screen reader support (roles, labels, live regions)
- Semantic HTML and proper element usage
- Color contrast and visual accessibility
- Touch target sizing (≥44×44px)
- Motion and animation (prefers-reduced-motion)
- Form accessibility and error handling

Report your findings by calling `SendMessage` with:

```
[Accessibility Review]
A11y compliance: <One sentence on WCAG AA fitness>
Issues:
- <issue 1> (severity: critical|high|medium|low)
- <issue 2> (severity: ...)
- ...
Recommendations:
- <recommendation 1>
- <recommendation 2>
- ...
Accessibility Review complete.
```
