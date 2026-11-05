# Hermes Skills

This directory contains bioinformatics **Skills** in the Hermes format. Each subdirectory holds a self-contained skill documented in its `SKILL.md` file, which includes machine-readable metadata (including a `description`) enabling Hermes-capable agents to discover and execute the tool.

These skills follow the Hermes format (`metadata.hermes`), with the fuller `When to Use` / `Procedure` / `Pitfalls` / `Verification` structure. The OpenClaw variants (more concise, action-oriented) live under `skills/openclaw/`.

There are 27 skills in this directory.

## Skills

- **`bcftools`** — Generate pseudo-genome consensus assemblies by applying VCF variants onto a reference genome ([SKILL.md](bcftools/SKILL.md))
- **`bedgraphtobigwig`** — Convert bedGraph coverage files to binary bigWig format for efficient visualization ([SKILL.md](bedgraphtobigwig/SKILL.md))
- **`biopython`** — Comprehensive Python toolkit for molecular biology - sequence manipulation, file parsing, BLAST, phylogenetics, and structural bioinformatics ([SKILL.md](biopython/SKILL.md))
- **`bwamem`** — Map Illumina paired-end reads (70-100bp) to reference genomes using BWA-MEM alignment ([SKILL.md](bwamem/SKILL.md))
- **`clustalo`** — Multiple sequence alignment for protein and DNA/RNA sequences ([SKILL.md](clustalo/SKILL.md))
- **`cvtree`** — Generate phylogenetic trees from whole-genome sequences using composition vector analysis ([SKILL.md](cvtree/SKILL.md))
- **`fastp`** — Ultrafast all-in-one preprocessing and quality control for Illumina short-read FASTQ data ([SKILL.md](fastp/SKILL.md))
- **`fastqc`** — Quality control analysis for high-throughput sequencing data using FastQC docker container ([SKILL.md](fastqc/SKILL.md))
- **`gatk`** — Variant discovery in high-throughput sequencing data - SNP and indel calling for germline and somatic variants ([SKILL.md](gatk/SKILL.md))
- **`geo_download`** — Download the processed supplementary files of any GEO sample (GSM accession), e.g. 10x scRNA-seq count matrices (features.tsv.gz, barcodes.tsv.gz, matrix.mtx.gz) ([SKILL.md](geo_download/SKILL.md))
- **`jellyfish`** — Fast, memory-efficient counting of k-mers in DNA sequences ([SKILL.md](jellyfish/SKILL.md))
- **`minimap2`** — Align long/short reads or assemblies to a reference genome using minimap2 ([SKILL.md](minimap2/SKILL.md))
- **`muscle`** — Multiple sequence alignment for protein and nucleotide sequences with high accuracy ([SKILL.md](muscle/SKILL.md))
- **`ncbidatasets`** — Search NCBI and download genomes, genes, proteins or annotations with NCBI Datasets ([SKILL.md](ncbidatasets/SKILL.md))
- **`pear`** — Merge overlapping paired-end Illumina reads into single assembled sequences ([SKILL.md](pear/SKILL.md))
- **`primer3`** — Design PCR primers from a DNA template using the industry-standard Primer3 tool ([SKILL.md](primer3/SKILL.md))
- **`samtools`** — Manipulate, convert, sort, index, and query SAM, BAM, and CRAM alignment files ([SKILL.md](samtools/SKILL.md))
- **`seqsample`** — Sample or generate random sequences from FASTA or FASTQ files ([SKILL.md](seqsample/SKILL.md))
- **`seurat_annotate`** — Marker-driven cell-type annotation for clustered scRNA-seq data using AddModuleScore (scRNA-seq workflow Action 10); consumes integrated_clustered.rds from seurat-cluster ([SKILL.md](seurat_annotate/SKILL.md))
- **`seurat_cluster`** — Build the latent space and neighbor graph on the integrated object, then cluster (resolution scan toward a target cluster count) and compute t-SNE (scRNA-seq workflow Actions 8-9); consumes integrated.rds from seurat-integrate-rpca ([SKILL.md](seurat_cluster/SKILL.md))
- **`seurat_hvg_report`** — Extract, tabulate and visualize the highly variable genes selected in Action 5 (VST), per condition, with cross-condition membership comparison; consumes the .rds outputs of seurat-normalize-hvg ([SKILL.md](seurat_hvg_report/SKILL.md))
- **`seurat_integrate_rpca`** — Select shared integration features, run per-sample PCA, and perform RPCA anchor integration (scRNA-seq workflow Actions 6-7); consumes the .rds outputs of seurat-normalize-hvg; integration itself is a user-confirmed decision ([SKILL.md](seurat_integrate_rpca/SKILL.md))
- **`seurat_load_qc`** — Load 10x count matrices into Seurat, apply cell-level QC, and save per-condition QC'd .rds objects (scRNA-seq workflow Actions 1-3); manifest-driven, any files and any conditions; study parameters are confirmed with the user before running ([SKILL.md](seurat_load_qc/SKILL.md))
- **`seurat_normalize_hvg`** — Normalize each QC'd sample (LogNormalize) and select highly variable genes per sample (VST), scRNA-seq workflow Actions 4-5; consumes the .rds outputs of seurat-load-qc ([SKILL.md](seurat_normalize_hvg/SKILL.md))
- **`spades`** — De novo genome assembly from short and long reads for bacteria, small eukaryotes, and metagenomes ([SKILL.md](spades/SKILL.md))
- **`sra-toolkit`** — Download and convert NCBI SRA accessions to FASTQ/FASTA format ([SKILL.md](sra-toolkit/SKILL.md))
- **`tabix`** — Index and query TAB-delimited genome position files for fast region retrieval ([SKILL.md](tabix/SKILL.md))
