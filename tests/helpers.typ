// Minimal assertion helpers for the test suite.
//
// Tests are plain Typst documents: a failed assertion panics, so the compiler
// exit status is the test result. `tests/run.sh` compiles them all and reports.
// This keeps the suite dependency-free; an image-regression runner such as
// tytanic can be layered on top later without changing these files.

#let checks = state("tablature-test-checks", 0)

/// Assert a condition, reporting `msg` on failure.
#let ok(cond, msg) = {
  checks.update(n => n + 1)
  if not cond { panic("FAILED: " + msg) }
}

/// Assert equality, showing both values on failure.
#let eq(actual, expected, msg) = {
  checks.update(n => n + 1)
  if actual != expected {
    panic("FAILED: " + msg + "\n  expected: " + repr(expected) + "\n  actual:   " + repr(actual))
  }
}

/// Assert that `body` panics, and that its message contains `substring`.
///
/// Typst cannot catch panics, so this documents intent rather than executing
/// the failing call; error-path coverage is driven from `run.sh`, which compiles
/// dedicated failing fixtures and matches their stderr.
#let expect-error(substring) = [/* checked by run.sh: #substring */]

/// Print the check count, so a test that silently ran nothing is visible.
#let report(name) = context [#name: #checks.final() checks passed]
