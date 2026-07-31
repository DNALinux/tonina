# Tonina Skills Refactoring Plan

## Objective
Refactor all skills in the Tonina repository to support both Hermes and OpenClaw platforms with platform-specific formatting.

## Current Status
✅ Created `skills/hermes/` and `skills/openclaw/` directories
✅ Copied all 20 skills to both directories
✅ Retrieved format specifications for both platforms

## Skills to Refactor (20 total)
1. bcftools
2. bedgraphtobigwig
3. biopython
4. bwamem
5. clustalo
6. cvtree
7. fastp
8. fastqc ✅ (STARTED)
9. gatk
10. jellyfish
11. minimap2
12. muscle
13. ncbidatasets
14. pear
15. primer3
16. samtools
17. seqsample
18. spades
19. sra-toolkit
20. tabix

## Format Specifications

### Hermes Format
```yaml
---
name: skill-name
description: Brief description (one line, <160 chars)
version: 1.0.0
platforms: [macos, linux]  # optional
metadata:
  hermes:
    tags: [tag1, tag2, tag3]
    category: category-name
    requires_toolsets: [terminal]  # optional
    fallback_for_toolsets: []  # optional
    config:  # optional
      - key: setting.name
        description: "What it controls"
        default: "value"
---

# Skill Title

## When to Use
Clear trigger conditions and use cases.

## Procedure
Step-by-step instructions:
1. Step one
2. Step two
3. Step three

## Pitfalls (optional)
- Known failure modes
- Common mistakes
- How to fix them

## Verification (optional)
How to confirm the skill worked correctly.
```

### OpenClaw Format
```yaml
---
name: skill-name
description: Brief one-line description
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker"]  # required binaries
      env: ["API_KEY"]  # optional env vars
    primaryEnv: "API_KEY"  # optional
---

# Skill Title

## When to use it
Brief trigger conditions.

## Usage/Procedure
Concise step-by-step commands and instructions.

## Output
What the skill produces.

## Additional Parameters (optional)
Extra flags and options.

## Citation (optional)
Reference if academic tool.
```

## Key Differences

| Aspect | Hermes | OpenClaw |
|--------|--------|----------|
| **Metadata** | `metadata.hermes` | `metadata.openclaw` |
| **Structure** | More detailed sections | More concise |
| **Gating** | `requires_toolsets`, `fallback_for_toolsets` | `requires.bins`, `requires.env` |
| **Versioning** | Explicit `version` field | No version field |
| **Platforms** | Explicit `platforms` array | Implicit (all platforms) |
| **Tags** | `metadata.hermes.tags` | Not used |
| **Category** | `metadata.hermes.category` | Not used |
| **Emoji** | Not used | `metadata.openclaw.emoji` |

## Refactoring Strategy

For each skill:

### Hermes Version
1. Update frontmatter:
   - Add `version: 1.0.0`
   - Add `platforms: [macos, linux]`
   - Change `metadata.openclaw` → `metadata.hermes`
   - Add `tags` and `category`
   - Convert `requires.bins` → `requires_toolsets: [terminal]`
2. Reorganize content:
   - Keep "When to use it" → "When to Use"
   - Consolidate usage into "Procedure" section
   - Add "Pitfalls" if error handling exists
   - Add "Verification" if testing info exists

### OpenClaw Version
1. Simplify frontmatter:
   - Keep `metadata.openclaw` structure
   - Remove unnecessary fields
   - Keep `emoji` and `requires.bins`
2. Keep content concise:
   - Maintain existing structure
   - Focus on actionable commands
   - Remove excessive explanation

## Next Steps
1. ✅ Complete fastqc refactoring (both versions)
2. Refactor remaining 19 skills systematically
3. Test one skill from each platform to validate format
4. Update README.md to reflect new structure
5. Add platform selection guide for users

## Automation Opportunity
Consider creating a migration script that:
- Reads current SKILL.md
- Applies transformation rules
- Outputs both Hermes and OpenClaw versions
- Validates against format schemas
