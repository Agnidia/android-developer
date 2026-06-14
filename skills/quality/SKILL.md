---
name: quality
description: Android testing quality: JUnit/MockK unit tests, Turbine Flow tests, Compose UI tests, and screenshot tests. Use when adding tests, filling coverage gaps, or defining the QA gate.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [testing, junit, mockk, turbine, compose-ui-test, screenshot, android]
---

# Quality (domain index)

Thin router for the quality skill domain.

| Skill | Use when |
|-------|----------|
| [testing](testing/SKILL.md) | JUnit/MockK unit tests, Turbine flow tests, Compose UI tests, Roborazzi/Paparazzi screenshots |

## Core principle

Follow the test pyramid: many fast unit tests (ViewModels, use-cases, mappers), a focused
band of integration/UI tests, a thin layer of screenshot/E2E checks for critical screens.
Tests are deterministic — injected dispatchers, in-memory DBs, no real clocks or network.

## Attribution

Synthesized by IGRSoft from community testing references (`new-silvermoon`, `piyushverma0`)
blended with patterns from Google's official `android/skills` (**Apache License 2.0 —
Google android/skills**). Licensed Apache-2.0; no content copied verbatim.
