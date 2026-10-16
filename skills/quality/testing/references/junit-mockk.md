# JUnit & MockK

- Detect the runner: `useJUnitPlatform()` → JUnit5 (`@Test` from `org.junit.jupiter`);
  otherwise JUnit4 (`@Test` from `org.junit`). Match the existing one — never mix.
- MockK: `mockk<T>()`, `every { x() } returns v`, `coEvery { susp() } returns v`,
  `verify(exactly = 1) { x() }`, `coVerify { }`. Use `relaxed = true` sparingly.
- Prefer fakes for stateful collaborators (a `FakeRepository` backed by a `MutableMap` is
  clearer and less brittle than a stack of `every` stubs).

## Attribution
Synthesized by Agnidia from `new-silvermoon`, `piyushverma0`, Google `android/skills`
(Apache License 2.0). Apache-2.0. No verbatim copying.
