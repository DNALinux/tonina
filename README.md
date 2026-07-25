# Tonina

**Tonina** is a curated collection of bioinformatics tools packaged as reusable **Skills** designed to work with AI agents like [Hermes](https://toyoko.io/). These modular, well-documented tools enable genomic analysis and sequence processing through intelligent agent-driven workflows, including sequence quality control, genome assembly, alignment, and annotation.

Tonina is optimized to run on Linux and macOS. It integrates seamlessly with [DNALinux](https://dnalinux.com/), a specialized Linux environment developed by [Toyoko](https://toyoko.io/) to provide a complete bioinformatics stack with agent support.

## Overview

Tonina is part of the [DNALinux](https://dnalinux.com/) ecosystem and serves as a complementary project to [OmicsContainers](https://github.com/DNALinux/OmicsContainers). While OmicsContainers provides containerized versions of bioinformatics software, Tonina offers lightweight, self-contained implementations and integrations designed for direct use with AI agents, enabling seamless integration into intelligent analysis pipelines.

### What's a Skill?

A **Skill** in Tonina is a self-contained tool or utility designed to be invoked by AI agents (such as Hermes), documented with:
- A clear description of its purpose and use cases
- CLI reference and usage examples
- Implementation details (Docker-based or native)
- When and how to use it in your workflow
- Structured metadata for agent discovery and execution

Each Skill is located in its own directory within `/skills/` and comes with a `SKILL.md` documentation file that includes machine-readable metadata enabling agents to understand and execute the tool appropriately.

Tonina runs wherever Hermes runs, making it ideal for both local development and production environments in Linux/macOS systems and the [DNALinux](https://dnalinux.com/) platform.

## Available Skills

Tonina includes the following skills for bioinformatics analysis:

### Sequence Quality & Processing

- **[FastQC](skills/fastqc/SKILL.md)** — Quality control for raw sequencing data; identifies potential artifacts and systematic errors
- **[Fastp](skills/fastp/SKILL.md)** — All-in-one FASTQ preprocessor for adapter trimming, filtering, and QC
- **[SeqSample](skills/seqsample/SKILL.md)** — Lightweight Python utility to subsample or generate FASTA/FASTQ sequences for testing and validation

### Sequence Alignment & Mapping

- **[BWA-MEM](skills/bwamem/SKILL.md)** — Map short reads to reference genomes with high accuracy
- **[Minimap2](skills/minimap2/SKILL.md)** — Versatile sequence alignment for DNA, mRNA, and long reads against large databases

### Genome Assembly

- **[SPAdes](skills/spades/SKILL.md)** — De novo genome assembler for bacteria, plasmids, single-cell, and metagenomic data

### Sequence Analysis & Primer Design

- **[Primer3](skills/primer3/SKILL.md)** — Design PCR primers, hybridization probes, and sequencing primers from DNA sequences

### Clustering & Alignment

- **[Clustal Omega](skills/clustalo/SKILL.md)** — Multiple sequence alignment for proteins and nucleotides at large scale
- **[MUSCLE](skills/muscle/SKILL.md)** — Fast and accurate multiple sequence alignment

### Data Retrieval & Processing

- **[NCBI Datasets](skills/ncbidatasets/SKILL.md)** — Download genomic data and metadata from NCBI databases
- **[SRA Toolkit](skills/sra-toolkit/SKILL.md)** — Retrieve, convert, and analyze sequencing data from the NCBI Sequence Read Archive

### File Manipulation & Coordinate Operations

- **[Tabix](skills/tabix/SKILL.md)** — Fast indexing and querying of TAB-delimited genomic position files
- **[BCFtools](skills/bcftools/SKILL.md)** — Variant calling and VCF/BCF file manipulation

## Relationship to OmicsContainers

[OmicsContainers](https://github.com/DNALinux/OmicsContainers) is a comprehensive, curated collection of Docker containers for bioinformatics tools, maintained as part of the DNALinux project. It provides **containerized implementations** of 70+ bioinformatics tools with consistent, reproducible environments.

**How Tonina relates to OmicsContainers:**

- **OmicsContainers** provides Docker images for a large suite of bioinformatics tools available from Docker Hub (e.g., `dnalinux/spades`, `dnalinux/bwa`, etc.)
- **Tonina** offers a smaller, curated subset of tools with **detailed, practical documentation** and **Skill-based abstraction**
- Many Tonina skills are built on top of OmicsContainers Docker images but add:
  - Step-by-step usage guides with real examples
  - Common parameter configurations and best practices
  - Integration points for multi-step workflows
  - Lightweight native implementations (where appropriate, like SeqSample)

**Finding a tool:**
- If you need a specific bioinformatics tool → Check [OmicsContainers](https://github.com/DNALinux/OmicsContainers) for the containerized version
- If you need practical guidance on how to use a tool → Check Tonina Skills for documentation and workflow examples

## Getting Started

### Prerequisites

Most Tonina Skills require either:
- **Docker** — for containerized tools (e.g., SPAdes, Fastp)
- **Python 3.7+** — for native Python implementations (e.g., SeqSample)

### Using a Skill

1. Navigate to the skill's directory:
   ```bash
   cd skills/<skill-name>/
   ```

2. Read the documentation:
   ```bash
   cat SKILL.md
   ```

3. Follow the usage examples in the skill's `SKILL.md` file

### Example: Quality Check and Subsample

Here's a typical workflow using multiple Tonina Skills:

```bash
# 1. Check quality of raw sequencing data
cd skills/fastqc
docker run ... dnalinux/fastqc reads.fastq.gz

# 2. Subsample reads for testing (using SeqSample)
cd ../seqsample
python3 main.py -i reads.fastq.gz -u 10000 -o subset.fastq

# 3. Align to reference (using BWA-MEM)
cd ../bwamem
docker run ... dnalinux/bwa-mem2 mem reference.fasta subset.fastq > aligned.sam
```

## Testing Data

The `TestingData/` directory contains sample data for validation and testing:

- **Reference genomes** — _Deinococcus radiodurans_ genome (FASTA)
- **Sequencing reads** — Short-read Illumina FASTQ files

These are useful for:
- Testing skill implementations
- Learning how to structure input/output
- Validating your bioinformatics pipeline setup

See `TestingData/readme.md` for details.

## Implementation Notes

### Docker-Based Skills

Most Tonina Skills leverage Docker images from [OmicsContainers](https://hub.docker.com/r/dnalinux). When using containerized tools:

- Ensure Docker is installed and running
- Use volume mounts (`-v`) to access files on your host system
- Consult individual skill documentation for container-specific parameters

### Native Python Skills

SeqSample is a native Python implementation with no external dependencies (other than Python 3.7+). This makes it:
- Fast and lightweight
- Easy to integrate into scripts
- Ideal for quick testing and data generation

## License

Tonina is licensed under the [GNU General Public License v3 (GPL-3.0)](LICENSE). See the LICENSE file for details.

## Contributing

We welcome contributions! To add a new skill or improve existing documentation:

1. Create a new directory under `skills/` with your tool name
2. Add a `SKILL.md` file following the documentation structure of existing skills
3. Include practical examples and clear use cases
4. Submit a pull request

## Related Resources

- **OmicsContainers** — https://github.com/DNALinux/OmicsContainers
- **DNALinux** — https://dnalinux.com/
- **BioContainers** — https://github.com/BioContainers/containers

## Support

For issues, questions, or requests:

- **Report a bug or request a feature** — Open an [issue on GitHub](https://github.com/DNALinux/tonina/issues)
- **Contact** — dnalinux@toyoko.io
