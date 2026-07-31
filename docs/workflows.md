# DNALinux / Tonina — Showcase Workflows

Below are six coherent workflows built from the 15 Tonina skills. Where a step needs a companion tool that lives in OmicsContainers but not in Tonina (e.g. `samtools`, `gatk`), it is marked **(companion)** so it is clear which steps are Tonina-driven vs. ecosystem-supported.

---

## Workflow 1 — Bacterial Resequencing & Variant-Calling Pipeline

**Purpose.** Take raw Illumina reads for a bacterial isolate, align them against a close reference, call variants, and produce a sample-specific consensus genome. This is the canonical "resequencing" use case and exercises the largest number of Tonina skills end-to-end.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Reference accession (e.g. `GCF_000005845.2`) | Reference FASTA (`.fna`) + annotation |
| 2 | **SRA Toolkit** (`fasterq-dump`) | SRA accession (`SRR…`) | Paired FASTQ (`_1.fastq`, `_2.fastq`) |
| 3 | **FastQC** | Raw FASTQ | QC report (HTML + `summary.txt`) |
| 4 | **Fastp** | Raw R1/R2 FASTQ | Trimmed R1/R2 FASTQ + JSON/HTML report |
| 5 | **FastQC** (again) | Trimmed FASTQ | Post-cleaning QC report (verification) |
| 6 | **BWA-MEM** | Reference FASTA + trimmed FASTQ | `aligned.sam` |
| 7 | *(companion)* `samtools` | `aligned.sam` | Sorted, indexed `aligned.bam` |
| 8 | **BCFtools** (`consensus`) | Reference FASTA + VCF | Per-sample consensus FASTA |
| 9 | **Tabix** | bgzipped VCF | `.tbi` index → fast region queries |

**Order.** Retrieve reference → retrieve reads → QC raw → trim → QC cleaned → index reference → align → sort/index BAM → call variants → index VCF → build consensus.

---

## Workflow 2 — De Novo Bacterial Genome Assembly

**Purpose.** Assemble a small genome (bacterium, plasmid, or single-cell MDA) without relying on a reference. Showcases SPAdes and the QC/trimming chain that feeds it.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **SRA Toolkit** | SRA accession | Paired FASTQ |
| 2 | **SeqSample** (optional) | Large FASTQ | Subsampled FASTQ (for a quick test run) |
| 3 | **FastQC** | Raw FASTQ | QC report |
| 4 | **Fastp** | R1/R2 FASTQ | Trimmed FASTQ |
| 5 | **PEAR** (optional) | Trimmed R1/R2 | `*.assembled.fastq` (merged reads) |
| 6 | **SPAdes** | Trimmed (and optionally merged) FASTQ | `contigs.fasta`, `scaffolds.fasta`, assembly graph (GFA) |

**Order.** Download reads → (optional) subsample for a dry run → QC → trim → (optional) merge pairs → assemble. SPAdes can also take long reads (`--pacbio`/`--nanopore`) for a hybrid assembly if you also fetch long-read data via SRA Toolkit.

---

## Workflow 3 — Comparative Genomics & Primer Design from Conserved Regions

**Purpose.** Pull homologous genes/genomes from NCBI, align them to find conserved blocks, then design PCR primers inside those conserved blocks. A wet-lab-oriented workflow.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Gene symbol or taxon (e.g. `BRCA1`, `Escherichia coli`) | FASTA of CDS/protein/genome |
| 2 | **SeqSample** | Many sequences | Subset of N representative sequences |
| 3 | **Clustal Omega** *or* **MUSCLE** | Unaligned FASTA (≥3 seqs) | Aligned FASTA / AFA |
| 4 | **Primer3** | Conserved region (DNA template + `SEQUENCE_TARGET`) | Forward/reverse primer sequences, Tm, GC%, positions |

**Order.** Retrieve sequences → subsample if large → multiple sequence alignment → inspect conserved block → feed template + target region into Primer3 → report primer candidates.

---

## Workflow 4 — Long-Read Alignment & Genome-Browser Track Generation

**Purpose.** Map Oxford Nanopore or PacBio long reads to a reference and produce a coverage track viewable in IGV/JBrowse. Showcases the long-read side of the ecosystem.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Reference accession | Reference FASTA |
| 2 | **SRA Toolkit** | ONT/PacBio SRA accession | Long-read FASTQ |
| 3 | **Minimap2** (`-x map-ont` / `map-hifi`) | Reference + long reads | `alignment.sam` (or PAF) |
| 4 | *(companion)* `samtools` | `alignment.sam` | Sorted BAM + `.bai` |
| 5 | *(companion)* `bedtools genomecov` | Sorted BAM | `coverage.bedGraph` |
| 6 | **bedGraphToBigWig** | Sorted `bedGraph` + `chrom.sizes` | `coverage.bw` (binary, indexed) |

**Order.** Get reference → get long reads → align with the right minimap2 preset → sort/index BAM → compute coverage → convert to bigWig for visualization.

---

## Workflow 5 — Population Pangenome / Multi-Sample Consensus

**Purpose.** Process several isolates from the same species, build a per-sample pseudo-genome for each, then align those pseudo-genomes to compare them. Demonstrates the multi-sample loop pattern around BCFtools.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Reference accession | Reference FASTA |
| 2 | **SRA Toolkit** | Multiple `SRR` accessions | FASTQ per sample |
| 3 | **Fastp** (loop) | R1/R2 per sample | Trimmed FASTQ per sample |
| 4 | **BWA-MEM** (loop) | Reference + trimmed reads | SAM per sample |
| 5 | *(companion)* `samtools`/`gatk` | SAM/BAM | VCF per sample |
| 6 | **BCFtools** (`concat` + `consensus`) | Per-sample VCFs + reference | Per-sample consensus FASTA |
| 7 | **Tabix** | Each bgzipped VCF | `.tbi` indexes |
| 8 | **MUSCLE** *or* **Clustal Omega** | Set of consensus FASTAs | Whole-genome MSA for comparison |

**Order.** Reference → per-sample: trim → align → call → consensus → then align all consensus genomes together.

---

## Workflow 6 — Rapid Pipeline Prototyping on Test Data

**Purpose.** The smallest useful demo of DNALinux: use the bundled `TestingData/` (*Deinococcus radiodurans* genome + Illumina reads) to validate that the stack works end-to-end without downloading anything. Showcases `SeqSample` as a development aid.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **SeqSample** | `TestingData/SRR9438221.fastq.gz` | Subsampled `subset.fastq` (10k reads) |
| 2 | **FastQC** | `subset.fastq` | QC report |
| 3 | **Fastp** | `subset.fastq` | Cleaned FASTQ |
| 4 | **BWA-MEM** | `GCA_011604825.1.fasta` + cleaned reads | `aligned.sam` |
| 5 | **BCFtools** | Reference + called VCF | Consensus FASTA |
| 6 | **Primer3** | A contig/region from the consensus | Primer pair for a target locus |

**Order.** Subsample → QC → trim → align to the *D. radiodurans* reference → call/apply variants → design primers against a locus of interest. Ideal for a tutorial or CI smoke test.

---

## Notes on gaps (intentional)

- **Variant calling itself** (SNP/indel discovery from BAM) is the one step Tonina does not yet cover directly; the `bcftools` skill is documented only for `consensus`. Until a `bcftools call` / `gatk` skill is added, that step relies on the OmicsContainers images (`dnalinux/gatk`, `dnalinux/samtools`).
- **SAM→BAM conversion/sorting** relies on `samtools` (OmicsContainers), referenced explicitly in the BWA-MEM and BCFtools SKILL docs.
- **Coverage track generation** (Workflow 4) needs `bedtools` (OmicsContainers); `bedgraphtobigwig` is the Tonina-side finishing step.