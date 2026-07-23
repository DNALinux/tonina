---
name: Tabix
description: "tabix – Generic indexer for TAB-delimited genome position files."
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker"]
    install:
      - id: apt
        kind: apt
        package: podman-docker
        bins: ["podman", "docker"]
        label: "Install Docker"
---

# Tabix – Generic Indexer For TAB-delimited Genome Position Files

This skill indexes bgzipped TAB-delimited genome position files and queries them by genomic region.

## When This Skill Is Used

Use this workflow when you have:
- An input data file that is **position sorted** and **compressed with bgzip**
- A need to create an index for fast region lookup
- A need to quickly retrieve data lines overlapping regions

This approach is **not** suitable for:
- Files that are NOT position sorted
- Files that are NOT compressed with bgzip

## Prerequisites

- The input file must already be **bgzipped** (`.bgz` or `.gz`). Use `bgzip file.bed` first if needed.

## Input Types

- **Sorted and bgzipped TAB-delimited genome position file** — e.g. `file.bed.gz`, `file.vcf.gz`, `file.gff.gz`

---

## Workflow

### Steps

a. **Extract variables from the user prompt:**
  - `<INPUT_FILE>`: The input filename or path provided by the user.
  - `<REGIONS>`: One or more space-separated genomic regions provided by the user (e.g., `chr1:10,000,000-20,000,000`, `1:500-1200`, `chrX`).
  - **WARNING: Important: If your file is not a standard VCF, BED, GFF, or SAM file — or if it has extra columns before the position columns, you must specify -p and optionally -s, -b, -e (sequence name, start, end column numbers). Without this, tabix may create a broken index while exiting with code 0.**

b. **Validate arguments and fill missing inputs:**
  - If `<INPUT_FILE>` is missing from the user request, prompt the user for it.
  - If the user wants to **Query (Step 2)** but did not specify any chromosomes, positions, or regions:
    1. Instruct the agent to run `tabix -l <INPUT_FILE>` first to inspect the available chromosomes.
    2. Prompt the user: *"I found the following chromosomes in your file: [list]. Which chromosome, start position, and end position would you like to query?"*

c. **Normalize Regions format:**
   - Ensure commas are removed from positions before running the command (e.g., change `10,000,000` to `10000000`) so the bash command does not break.
   - Separate multiple regions with a space.

d. **Determine optional flags based on user request:**
   - Append any requested optional parameters (e.g., `--csi`, `--preset`, `-h` for headers) from **Additional Useful Parameters**.

### Step 1: Run Indexing

This step creates an index file (`<INPUT_FILE>.tbi` or `<INPUT_FILE>.csi`). After indexing, tabix can quickly retrieve data lines overlapping regions specified in the format `chr:beginPos-endPos`. (Coordinates are 1-based and inclusive.)

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
tabix \
--force \
--threads $(nproc) \
<INPUT_FILE>
```

- `--force`: Forces file overwriting if the index already exists.
- `--threads`: Set number of threads to use for the operation. The default is 0, where no extra threads are used.

### Step 2: Querying with index file

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
tabix \
<INPUT_FILE> \
<REGIONS>
```

## Output

- **Step 1 (Indexing):** Produces `<INPUT_FILE>.tbi` or `<INPUT_FILE>.csi`
- **Step 2 (Querying):** Prints matching genomic regions to stdout

---

## Additional Useful Parameters

These can be added to the `tabix` command:

**For indexing:**
- `--csi`: Use CSI index instead of TBI. Required if positions may exceed 512 Mbp (2^29).
- `--preset <format>`: Input format for indexing. Valid values: `gff`, `bed`, `sam`, `vcf`.

**For querying:**
- `--list-chroms`: List the sequence names stored in the index file.
- `--print-header`: Print also the header/meta lines.

**Example with (`--csi`) and (`--preset`):**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  --csi \
  --force \
  --preset vcf \
  --threads $(nproc) \
  my.vcf.gz
```

**Example with (`--list-chroms`):**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  --list-chroms <INPUT_FILE>
```

**Example with (`--print-header`):**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  --print-header <INPUT_FILE>
```

## Citation

If the user asks for a citation for tabix, provide the following:

Li, Heng (March 1, 2011). "Tabix: fast retrieval of sequence features from generic TAB-delimited files". Bioinformatics. 27 (5): 718–719. doi:10.1093/bioinformatics/btq671
