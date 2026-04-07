# no-branch-refs-in-release-examples

## mistake

Changed example module `source` refs to a feature branch
(`?ref=issue-31-create-tf-modules-gcp`) in both `main.tf` files and README docs
inside `gcp/terraform/examples/`. Feature branches are ephemeral; once the PR
is merged the ref becomes stale, ambiguous, and points nowhere useful for anyone
trying to consume the example.

## scolding

> "Your README and examples are pointing at the branch, but when we merge the PR
> that will all be inaccurate and unusable. You are producting things for final
> release not this branch."

## avoid

- Using a Git branch name in any `?ref=` value that appears in a release-facing
  example or README.
- Shipping examples or docs that instruct users to pin to a branch rather than a
  version tag.
- Treating a feature-branch ref as "good enough for now" — it never is; the
  artifact outlives the branch.

## instead

- Use a pinned semver tag in every example `source` ref, e.g.
  `?ref=v0.3.0`.
- If the release tag does not exist yet at the time of development, coordinate
  the tag plan (agree on the next version number) and update all refs to that tag
  **before** the PR is merged / before the artifact ships.
- Keep a `TODO(release): update ref to vX.Y.Z` comment locally during
  development, but never merge it — resolve it to the real tag first.

## patterns

Files and patterns to audit before any GCP-related PR is merged:

```
# source lines in examples
gcp/terraform/examples/**/main.tf
  → search: source = ".*\?ref=[^v][^0-9]"   # catches non-semver refs

# README prose
gcp/terraform/examples/**/README.md
  → search: \?ref=(?!v\d)                    # any ref that isn't vX...

# General rule across all clouds
{aws,azure,thousandeyes,gcp}/terraform/examples/**/main.tf
  → every `source` line that references this repo must end with `?ref=vX.Y.Z`
```

The AGENTS.md rule that already exists:
> "Pin module `source` refs to a semver tag (`?ref=v0.2.0`), **never a branch**."

This memory exists because that rule was violated in practice. Treat any
`?ref=<non-semver>` in an example as a blocking review issue.
