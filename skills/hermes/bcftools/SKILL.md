---
name: bcftools
description: Generate pseudo-genome consensus assemblies by applying VCF variants onto a reference genome
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, variant-calling, vcf, consensus, genomics]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# BCFtools Consensus Assembly

BCFtools consensus generates personalized pseudo-genome assemblies by applying variant calls (SNPs and Indels from a VCF file) onto a reference genome. The result is a sample-specific FASTA sequence reflecting the individual's genomic variants.

## When to Use

Use this workflow when you have:

**Input requirements:**
- Reference genome (FASTA format)
- VCF files with called variants (SNPs, Indels)
- Sufficient RAM for reference indexing

**Appropriate scenarios:**
- Resequencing projects where samples are close to a known reference (bacteria, plant cultivars, animal breeds)
- Population genomics requiring individualized genome sequences for downstream analysis (phylogenetics, comparative genomics)
- Per-sample consensus sequences without performing de novo assembly

**Not suitable for:**
- Samples highly divergent from the reference → Use de novo assembly (SPAdes)
- Structural variant reconstruction beyond simple SNPs/Indels
- Samples lacking a suitable reference genome

## Procedure

### 1. Index input VCF files

Each VCF must be indexed before merging or querying. Skip if `.vcf.gz.tbi` files already exist:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/bcftools:1.23.1 index /ftmp/snps_filtered.vcf.gz
docker run --rm -v $(pwd):/ftmp dnalinux/bcftools:1.23.1 index /ftmp/indels_filtered.vcf.gz
```

**Output:** `.tbi` (tabix) index file alongside each `.vcf.gz` file.

### 2. Merge SNP and Indel VCFs

Combine separate SNP and Indel files into a single sorted, deduplicated VCF:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 concat -a --rm-dups all \
  /ftmp/snps_filtered.vcf.gz \
  /ftmp/indels_filtered.vcf.gz \
  -O z -o /ftmp/combined_filtered.vcf.gz
```

**Flags:**
- `-a` / `--allow-overlaps` — Handles overlapping records between files
- `--rm-dups all` — Removes duplicate records after merging
- `-O z` — Output in bgzip-compressed VCF format
- `-o` — Output file path

Then index the merged file:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 index combined_filtered.vcf.gz
```

**Skip Steps 1-2** if your variants are already in a single, indexed VCF file.

### 3. Verify sample names

List the samples present in the VCF to confirm exact identifiers:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 query -l combined_filtered.vcf.gz
```

### 4. Index the reference FASTA

BCFtools consensus requires the reference to be indexed with `samtools faidx`:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/samtools samtools faidx reference.fa
```

**Output:** `reference.fa.fai` index file.

**Skip if `.fai` index already exists.**

**Note:** Use uncompressed FASTA (`.fa`). If gzipped (`.fa.gz`), decompress first: `gunzip reference.fa.gz`

### 5. Generate per-sample consensus assemblies

Run `bcftools consensus` once per sample:

**Single sample:**
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 consensus \
  -f /ftmp/reference.fa \
  -s "SAMPLE_NAME" \
  -o /ftmp/SAMPLE_NAME_assembly.fasta \
  /ftmp/combined_filtered.vcf.gz
```

**Multiple samples (loop):**
```bash
for SAMPLE in Sample1 Sample2 Sample3 Sample4; do
  docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 consensus \
    -f /ftmp/reference.fa \
    -s "${SAMPLE}" \
    -o /ftmp/${SAMPLE}_assembly.fasta \
    /ftmp/combined_filtered.vcf.gz
done
```

**Key flags:**
- `-f` — Path to uncompressed, indexed reference FASTA
- `-s` — Sample name as it appears in VCF header (from Step 3)
- `-o` — Output FASTA file for this sample

## Pitfalls

**Reference must be uncompressed FASTA:**
`bcftools consensus` requires `.fa` not `.fa.gz`. Decompress gzipped references before use.

**Sample name must match exactly:**
The `-s` sample name must match the VCF header exactly. Use `bcftools query -l` to list valid names.

**Missing index files:**
Both VCF (`.vcf.gz.tbi`) and reference (`.fa.fai`) must be indexed. BCFtools will fail with cryptic errors if indexes are missing.

**Heterozygous site handling:**
Default behavior applies IUPAC ambiguity codes at heterozygous sites. Use `-H 1` or `-H 2` to select a specific haplotype (1 = REF, 2 = ALT).

## Verification

Successful run produces:
- One FASTA file per sample with variants applied
- Chromosome/scaffold names inherited from reference

Quick validation:
```bash
# Check output file was created
ls -lh SAMPLE_NAME_assembly.fasta

# Count sequences
grep -c "^>" SAMPLE_NAME_assembly.fasta

# Compare file sizes (consensus should be similar to reference)
wc -c reference.fa SAMPLE_NAME_assembly.fasta
```

## Key Parameters

### Input/Output
| Flag | Description |
|------|-------------|
| `-f FILE` | Indexed reference FASTA (uncompressed) |
| `-s NAME` | Sample name in VCF |
| `-o FILE` | Output consensus FASTA |
| Input VCF | Final positional argument |

### Haplotype Selection
| Flag | Description |
|------|-------------|
| `-H 1` | Output REF allele at heterozygous sites |
| `-H 2` | Output ALT allele at heterozygous sites |
| Default | Apply IUPAC ambiguity codes |

### Filtering and Masking
| Flag | Description |
|------|-------------|
| `-m FILE.bed` | Mask regions with N characters |
| `-e 'FILTER!="PASS"'` | Exclude non-PASS variants |
| `--absent N` | Replace absent sites with N instead of reference base |
| `-c chain.txt` | Write chain file for coordinate liftover |

## Citation

Danecek, P., Bonfield, J.K., Liddle, J., Marshall, J., Ohan, V., Pollard, M.O., Whitwham, A., Keane, T., McCarthy, S.A., Davies, R.M. and Li, H., 2021. Twelve years of SAMtools and BCFtools. GigaScience, 10(2), p.giab008. doi.org/10.1093/gigascience/giab008
