# DNALinux / Tonina — Showcase Workflows

Below are eight coherent workflows built from the 27 Tonina skills. Where a step needs a tool that lives in OmicsContainers but not in Tonina (e.g. `bedtools`), it is marked **(companion)** so it is clear which steps are Tonina-driven vs. ecosystem-supported.

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
| 7 | **Samtools** | `aligned.sam` | Sorted, indexed `aligned.bam` (+ `.bai`) |
| 8 | **GATK** (`HaplotypeCaller`) | `aligned.bam` + reference FASTA/dict | `sample.g.vcf` / `variants.vcf` |
| 9 | **BCFtools** (`consensus`) | Reference FASTA + VCF | Per-sample consensus FASTA |
| 10 | **Tabix** | bgzipped VCF | `.tbi` index → fast region queries |

**Order.** Retrieve reference → retrieve reads → QC raw → trim → QC cleaned → index reference → align → sort/index BAM → call variants → consensus.

**Note.** `bcftools consensus` needs an uncompressed `.fa` reference and a `samtools faidx` index; GATK additionally needs a `.dict` (it creates one as step 1) and, for BQSR, a known-sites VCF.

---

## Workflow 2 — De Novo Bacterial Genome Assembly

**Purpose.** Assemble a small genome (bacterium, plasmid, or single-cell MDA) without relying on a reference. Showcases SPAdes and the QC/trimming chain that feeds it.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **SRA Toolkit** | SRA accession | Paired FASTQ |
| 2 | **SeqSample** (optional) | Large FASTQ | Subsampled FASTQ (for a quick test run) |
| 3 | **FastQC** | Raw FASTQ | QC report |
| 4 | **Fastp** | R1/R2 FASTQ | Trimmed R1/R2 FASTQ |
| 5 | **PEAR** (optional) | Trimmed R1/R2 | `*.assembled.fastq` (merged reads) |
| 6 | **SPAdes** | Trimmed (and optionally merged) FASTQ | `contigs.fasta`, `scaffolds.fasta`, assembly graph (GFA) |

**Order.** Download reads → (optional) subsample for a dry run → QC → trim → (optional) merge pairs → assemble. SPAdes accepts long reads (`--pacbio`/`--nanopore`) for a hybrid assembly if you also fetch long-read data via SRA Toolkit.

---

## Workflow 3 — Comparative Genomics & Primer Design from Conserved Regions

**Purpose.** Pull homologous genes/genomes from NCBI, align them to find conserved blocks, and design PCR primers inside those conserved blocks. A wet-lab-oriented workflow.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Gene symbol or taxon (e.g. `BRCA1`, `Escherichia coli`) | FASTA of CDS/protein/genome |
| 2 | **SeqSample** | Many sequences | Subset of N representative sequences |
| 3 | **Clustal Omega** *or* **MUSCLE** | Unaligned FASTA (≥3 seqs) | Aligned FASTA / AFA |
| 4 | **Biopython** (optional) | Aligned FASTA | Pairwise alignment, BLAST hits, tree parsing |
| 5 | **Primer3** | Conserved region (DNA template + `SEQUENCE_TARGET`) | Forward/reverse primer sequences, Tm, GC%, positions |

**Order.** Retrieve sequences → subsample if large → align → (optionally) inspect with Biopython → design primers inside conserved blocks.

---

## Workflow 4 — Long-Read Alignment & Genome-Browser Track Generation

**Purpose.** Map Oxford Nanopore or PacBio long reads to a reference and produce a coverage track viewable in IGV/JBrowse. Showcases the long-read side of the ecosystem.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Reference accession | Reference FASTA |
| 2 | **SRA Toolkit** | ONT/PacBio SRA accession | FASTQ |
| 3 | **Minimap2** (`-x map-ont` / `map-hifi`) | Reference + long reads | `alignment.sam` (or PAF) |
| 4 | **Samtools** | `alignment.sam` | Sorted BAM + `.bai` |
| 5 | *(companion)* `bedtools genomecov` | Sorted BAM | `coverage.bedGraph` |
| 6 | **bedGraphToBigWig** | Sorted `bedGraph` + `chrom.sizes` | `coverage.bw` (binary, indexed) |

**Order.** Get reference → get long reads → align with the right minimap2 preset → sort/index BAM → compute coverage → convert to bigWig for visualization.

---

## Workflow 5 — Population Pangenome / Multi-Sample Consensus

**Purpose.** Process several isolates from the same species, build a per-sample pseudo-genome from each, and then align those pseudo-genomes to compare them. Demonstrates the multi-sample loop pattern around BCFtools.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Reference accession | Reference FASTA |
| 2 | **SRA Toolkit** | Multiple `SRR` accessions | FASTQ per sample |
| 3 | **Fastp** (loop) | R1/R2 per sample | Trimmed R1/R2 per sample |
| 4 | **BWA-MEM** (loop) | Reference + trimmed reads | SAM per sample |
| 5 | **Samtools** / **GATK** (loop) | SAM/BAM | VCF per sample |
| 6 | **BCFtools** (`concat` + `consensus`) | Per-sample VCFs + reference | Per-sample consensus FASTA |
| 7 | **Tabix** | Each bgzipped VCF | `.tbi` indexes |
| 8 | **MUSCLE** *or* **Clustal Omega** | Set of consensus FASTAs | Whole-genome MSA for comparison |

**Order.** Reference → per-sample: trim → align → sort/index → call → consensus → then align all consensus genomes together.

---

## Workflow 6 — Rapid Pipeline Prototyping on Test Data

**Purpose.** The smallest useful demo of DNALinux: use the bundled `TestingData/` (*Deinococcus radiodurans* genome + Illumina reads) to validate that the stack works end-to-end without downloading anything. Showcases `SeqSample` as a development aid.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **SeqSample** | `TestingData/SRR9438221.fastq.gz` | Subsampled `subset.fastq` (10k reads) |
| 2 | **FastQC** | `subset.fastq` | QC report |
| 3 | **Fastp** | `subset.fastq` | Cleaned FASTQ |
| 4 | **BWA-MEM** | `GCA_011604825.1.fasta` + cleaned reads | `aligned.sam` |
| 5 | **Samtools** | `aligned.sam` | Sorted, indexed BAM |
| 6 | **BCFtools** | Reference + called VCF | Consensus FASTA |
| 7 | **Primer3** | A contig/region from the consensus | Primer pair for a target locus |

**Order.** Subsample → QC → trim → align to the *D. radiodurans* reference → sort/index → call/apply variants → design primers against a locus of interest. Ideal for a tutorial or CI smoke test.

---

## Workflow 7 — K-mer Profiling & Whole-Genome Phylogeny

**Purpose.** Characterize a set of genomes without any reference or multiple-sequence alignment: count k-mers to inspect sequence composition and estimate genome size, then build an alignment-free phylogeny from those genomes. Useful for quick triage of many isolates, and for taxonomic placement of novel organisms.

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **NCBI Datasets** | Taxon or assembly accessions | One FASTA per genome |
| 2 | **Jellyfish** | Genome FASTA(s) | k-mer counts (`.jf`) + histogram |
| 3 | **CVTree** | Genome list + per-genome FASTA | Composition vector tree |
| 4 | **Biopython** (optional) | `*.tree` / FASTA | Tree parsing and visualization |

**Order.** Fetch genomes → count k-mers and inspect the histogram (a bimodal or unexpected shape flags contamination or a collapsed repeat region) → run CVTree for the phylogeny → optionally render the tree.

**Note.** CVTree is alignment-free: it derives its own composition vectors from the raw genomes, so no multiple-sequence-alignment step is needed.

---

## Workflow 8 — Single-Cell RNA-seq with Seurat (10 actions, 7 skills)

**Purpose.** Take 10x count matrices from a public GEO study and carry them all the way to annotated cell types. This is the largest single workflow in Tonina and the only one that is Linux-only (all steps run in `dnalinux/scrnaseq_r_workflow`).

| # | Skill | Input | Output |
|---|-------|-------|--------|
| 1 | **GEO Sample Download** | GSM accession (e.g. `GSM5821748`) | `features.tsv.gz`, `barcodes.tsv.gz`, `matrix.mtx.gz` |
| 2 | **Seurat Load + QC** (Actions 1-3) | 10x trio + `samples.tsv` manifest | Per-condition `<condition>_qc.rds` |
| 3 | **Seurat Normalize + HVG** (Actions 4-5) | `<condition>_qc.rds` | Per-condition `<condition>_norm.rds` |
| 4 | **Seurat HVG Report** (Action 5 verification) | `<condition>_norm.rds` | Ranked HVG table, VariableFeaturePlot PNGs, cross-condition membership matrix |
| 5 | **Seurat Integration + RPCA** (Actions 6-7) | `<condition>_norm.rds` | `integrated.rds` (+ elbow plots) |
| 6 | **Seurat Clustering + t-SNE** (Actions 8-9) | `integrated.rds` | `integrated_clustered.rds` + review plots |
| 7 | **Seurat Cell-Type Annotation** (Action 10) | `integrated_clustered.rds` + `markers.tsv` | `integrated_annotated.rds`, `celltype_evidence.csv`, `tsne_celltypes.png` |

**Order.** Download the processed 10x files → per condition, load and QC → normalize and select HVGs → report on the HVGs → (optionally) integrate → cluster and embed → annotate cell types from a marker manifest.

**Gates worth knowing.** Steps 2-6 each end in a **user-confirmed parameter check** before the container run — study parameters, integration on/off, and the target cluster count are confirmed rather than assumed. Step 5 accepts `RUN_INTEGRATION=no`, which stops after per-sample PCA and preserves the unintegrated path. Step 7 flags weak or conflicting marker evidence for review instead of forcing a label.

**Note.** These skills are available in the Hermes tree only (`skills/hermes/seurat_*/SKILL.md`); there are no OpenClaw variants.

---

## Notes on gaps (intentional)

- **`bedtools genomecov`** in Workflow 4 is the one step Tonina does not cover directly; it lives in OmicsContainers. The Tonina-side finishing step is `bedGraphToBigWig`.
- **Raw reads vs. processed data in Workflow 8.** The GEO skill fetches *processed* supplementary files (count matrices). For raw FASTQ, use the SRA Toolkit skill on the SRR linked in the sample's Relations section.
- **Workflow 8 is Linux-only.** All seven skills declare `platforms: [linux]` and are Hermes-only.
- **`bcftools call` is still not a Tonina skill** — the `bcftools` skill covers `consensus` only. For SNP/indel discovery from BAM, use the GATK skill (Workflows 1 and 5).
