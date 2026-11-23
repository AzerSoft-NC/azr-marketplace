# Shared vendor pins + allow/deny lists for install-skills.sh and check-vendor-drift.sh.
# shellcheck shell=bash
# Sourced only — do not execute.

SUPERPOWERS_URL="https://github.com/obra/superpowers.git"
SUPERPOWERS_REF="8ca22dba9a94f28898bbce59f2537ff4d87c747d"  # v6.4.2

MATT_URL="https://github.com/mattpocock/skills.git"
MATT_REF="abeeaf95660ba9e8b7c753eb38f441ca707a8823"  # main @ abeeaf9 (post-v1.3.2)

SKILLSPECTOR_URL="https://github.com/NVIDIA/skillspector.git"
SKILLSPECTOR_REF="3c8e4b958fda9602e0044885f766be0e49f03585"  # v2.12.0-584

# Matt skills to install (engineering/ + productivity/ only). Paths relative to skills/.
MATT_ALLOWLIST=(
  engineering/ask-matt
  engineering/setup-matt-pocock-skills
  engineering/grill-with-docs
  engineering/domain-modeling
  engineering/to-spec
  engineering/to-tickets
  engineering/implement
  engineering/implement-spec
  engineering/wayfinder
  engineering/triage
  engineering/prototype
  engineering/research
  engineering/wizard
  engineering/retro
  engineering/pr
  engineering/codebase-design
  engineering/improve-codebase-architecture
  engineering/code-review
  productivity/grilling
  productivity/grill-me
  productivity/wait-what
)

# Matt skills deliberately not installed (collision or house owns the job).
MATT_EXCLUDE=(
  engineering/tdd
  engineering/diagnosing-bugs
  productivity/teach
  productivity/handoff
  productivity/writing-for-agents
  productivity/to-questionnaire
)

# Superpowers skills never installed (hooks / ownership collisions).
SUPERPOWERS_DENYLIST=(
  using-superpowers
  requesting-code-review
  brainstorming
)
