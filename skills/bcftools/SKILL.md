---
name: VCF Consensus Assembly
description: "Generate pseudo-genome consensus assemblies by applying VCF variants onto a reference genome with bcftools."
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

# VCF Consensus Assembly Skill

This skill generates personalized pseudo-genome assemblies by applying variant calls (SNPs and Indels from a VCF file) onto a reference genome using `bcftools consensus`. The result is a sample-specific FASTA sequence that reflects the individual's genomic variants relative to the reference.

## When This Skill Is Used

Use this workflow when you have:

- A reference genome (FASTA) and one or more VCF files with called variants (SNPs, Indels)
- A need for per-sample consensus sequences without performing de novo assembly
- Population genomics studies requiring individualized genome sequences for downstream analysis (e.g., phylogenetics, comparative genomics)
- Resequencing projects where samples are closely related to a known reference (bacteria, plant cultivars, animal breeds)

This approach is **not** suitable for:
- Samples highly divergent from the reference (use de novo assembly instead, e.g., SPAdes)
- Structural variant reconstruction beyond simple SNPs/Indels
- Samples lacking a suitable reference genome

## Input Types

- **Reference genome** — Uncompressed FASTA (`.fa`). If your reference is gzip-compressed (`.fa.gz`), decompress it first with `gunzip reference.fa.gz`.
- **SNP VCF** — Filtered SNP calls in bgzip-compressed VCF (`.vcf.gz`) with a tabix index (`.vcf.gz.tbi`)
- **Indel VCF** — Filtered Indel calls in the same format (can be omitted if variants are already merged)
- **Multi-sample VCFs** — Supported; a sample name is specified at consensus generation time with `-s`

---

## Workflow

### Step 1: Index Input VCF Files

Each VCF must be indexed before it can be merged or queried. If your files are not yet indexed:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/bcftools:1.23.1 index /ftmp/snps_filtered.vcf.gz
docker run --rm -v $(pwd):/ftmp dnalinux/bcftools:1.23.1 index /ftmp/indels_filtered.vcf.gz
```

- Produces a `.tbi` (tabix) index alongside each `.vcf.gz` file.
- Skip this step if index files already exist.

### Step 2: Merge SNP and Indel VCFs

Combine the separate SNP and Indel files into a single sorted, deduplicated VCF:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 concat -a --rm-dups all \
  /ftmp/snps_filtered.vcf.gz \
  /ftmp/indels_filtered.vcf.gz \
  -O z -o /ftmp/combined_filtered.vcf.gz
```

- `-a` / `--allow-overlaps`: Handles overlapping records between the two files.
- `--rm-dups all`: Removes duplicate records after merging.
- `-O z`: Output in bgzip-compressed VCF format.
- `-o`: Output file path.

Then index the merged file:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 index combined_filtered.vcf.gz
```

> **Skip Steps 1–2** if your variants are already in a single, indexed VCF file.

### Step 3: Verify Sample Names

List the samples present in the VCF to confirm the exact identifiers to use in Step 5:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 query -l combined_filtered.vcf.gz
```

### Step 4: Index the Reference FASTA

`bcftools consensus` requires the reference FASTA to be indexed with `samtools faidx`:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/samtools samtools faidx reference.fa
```

- Produces a `reference.fa.fai` index file alongside the reference.
- Skip this step if the `.fai` index already exists.

### Step 5: Generate Per-Sample Consensus Assemblies

Run `bcftools consensus` once per sample, substituting each sample name:

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

Key flags:
- `-f`: Path to the uncompressed, indexed reference FASTA.
- `-s`: Sample name as it appears in the VCF header (from Step 3).
- `-o`: Output FASTA file for this sample.

---

## Output

Each run of `bcftools consensus` produces one file per sample:

- `SAMPLE_NAME_assembly.fasta` — The pseudo-genome FASTA with all high-confidence variants from the VCF applied onto the reference sequence. Chromosome/scaffold names are inherited from the reference.

---

## Additional Useful Parameters

These can be added to the `bcftools consensus` command:

- `-H 1` / `-H 2`: Select which haplotype to output for heterozygous sites (1 = REF allele, 2 = ALT allele). Default applies IUPAC ambiguity codes.
- `-m mask.bed`: Mask specific regions (e.g., low-complexity or low-coverage regions) with `N` characters.
- `-e 'FILTER!="PASS"'`: Exclude variants not tagged as PASS before applying them (useful if the VCF was not pre-filtered).
- `--absent N`: Replace sites absent from the VCF with `N` instead of copying the reference base.
- `-c chain.txt`: Write a chain file recording coordinate changes introduced by Indels (useful for liftover).

**Example with haplotype selection and region masking:**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bcftools:1.23.1 consensus \
  -f /ftmp/reference.fa \
  -s "SAMPLE_NAME" \
  -H 2 \
  -m /ftmp/low_coverage_mask.bed \
  -o /ftmp/SAMPLE_NAME_assembly.fasta \
  /ftmp/combined_filtered.vcf.gz
```

---

## Citation

If the user asks for a citation for bcftools, provide the following:

Danecek, P., Bonfield, J.K., Liddle, J., Marshall, J., Ohan, V., Pollard, M.O., Whitwham, A., Keane, T., McCarthy, S.A., Davies, R.M. and Li, H., 2021. Twelve years of SAMtools and BCFtools. GigaScience, 10(2), p.giab008.
doi.org/10.1093/gigascience/giab008
