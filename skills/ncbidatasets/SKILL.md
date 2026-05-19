---
name: NCBIDatasets
description: "Search NCBI and download genomes, genes, proteins or annotations with NCBI Datasets."
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker", "unzip"]
    install:
      - id: apt-docker
        kind: apt
        package: podman-docker
        bins: ["podman", "docker"]
        label: "Install Docker"
      - id: apt-unzip
        kind: apt
        package: unzip
        bins: ["unzip"]
        label: "Install Unzip"
      - id: apt-jq
        kind: apt
        package: jq
        bins: ["jq"]
        label: "Install jq (for parsing summary JSON)"
---

# NCBI Datasets

NCBI Datasets is a CLI for searching NCBI and downloading genomes, genes, proteins, RNAs, annotations and taxonomy data. It exposes two binaries: `datasets` (search/download) and `dataformat` (convert the bundled JSONL reports into TSV/CSV).

This skill targets the `dnalinux/ncbi-datasets:latest` docker image. The container needs internet access (default Docker networking is fine - do **not** pass `--network=host` or `--network=none`).

## Datasets Usage

When the user needs to download a genome, use the ncbi-datasets docker container.

If the user provides a genome accession, download it directly:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets download genome accession GCA_000005845.2 --filename /ftmp/GCA_000005845.2.zip
```

If the user provides a genome name, find the accession first with the `summary` subcommand:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets summary genome taxon 'Escherichia coli' --reference
```

`summary` returns JSON. Pipe it through `jq` to extract a single field, e.g. the first reported accession:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets summary genome taxon 'Escherichia coli' --reference \
  | jq -r '.reports[0].accession'
```

Note on `--reference`: it filters to genomes flagged as RefSeq references. Many taxa have no RefSeq reference; in that case omit `--reference` and (optionally) add `--assembly-level chromosome` to keep finished assemblies.

If there are multiple genomes that match the name, ask the user which one to download.

If the user provided an ambiguous name, like "E. coli", you will get a list of candidate taxids:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets summary genome taxon 'E. coli' --reference
```

will return:

```text
Error: The taxonomy name 'E. coli' is not exact. Try using one of the suggested taxids:
Escherichia coli W (strain, taxid: 566546, E. coli W)
Escherichia phage vB_EcoD_Mishu (no-rank, taxid: 2894792, E. coli phage vB_EcoD_Mishu)
Escherichia phage vB_EcoS_FFH_1 (no-rank, taxid: 1446489, E. coli O157:H7 phage vB_EcoS_FFH1)
Escherichia phage PEC04 (no-rank, taxid: 1647412, E. coli O157:H7 Bacteriophage PEC04)
Escherichia phage HY03 (no-rank, taxid: 1654926, E. coli O157:H7 Bacteriophage HY03)
Escherichia phage FFH2 (no-rank, taxid: 1446490, E. coli O157:H7 phage vB_EcoM_FFH2)
Escherichia phage HY01 (no-rank, taxid: 1434323, E. coli O157:H7 Bacteriophage HY01)
Escherichia phage HY02 (no-rank, taxid: 1527531, E. coli O157:H7 Bacteriophage HY02)
Escherichia coli (species, taxid: 562, enterobacteria)
Enterovirus E (no-rank, taxid: 12064, viruses)

Use datasets summary genome taxon <command> --help for detailed help about a command.
```

In this case, ask the user which taxon they want, then re-run with the unambiguous name (`--taxon "Escherichia coli"`) or the taxid (`--taxon txid562`).

## Choosing what to download (`--include`)

By default `datasets download genome` only includes the genome FASTA. To include annotations or proteins, pass a comma-separated `--include` list:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets download genome accession GCF_000005845.2 \
  --include genome,gff3,protein,cds \
  --filename /ftmp/ecoli.zip
```

Common `--include` values: `genome`, `rna`, `protein`, `cds`, `gff3`, `gtf`, `gbff`, `seq-report`.

## Large genomes: dehydrated download + rehydrate

For very large datasets (e.g. the human reference) prefer the two-step dehydrated workflow, which downloads only metadata first and then fetches sequence data over HTTPS in parallel:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets download genome accession GCF_000001405.40 \
  --dehydrated --filename /ftmp/human.zip
unzip /ftmp/human.zip -d /ftmp/human
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets rehydrate --directory /ftmp/human
```

## Genes and taxonomy

Download all RNAs / proteins / CDS for a gene symbol:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets download gene symbol BRCA1 --taxon human --filename /ftmp/brca1.zip
```

Query taxonomy:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /datasets summary taxonomy taxon human
```

## Convert the bundled JSONL with `dataformat`

Every downloaded zip contains an `assembly_data_report.jsonl` (or equivalent) under `ncbi_dataset/data/`. The companion `dataformat` tool turns it into TSV:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/ncbi-datasets:latest \
  /dataformat tsv genome \
  --inputfile /ftmp/ecoli/ncbi_dataset/data/assembly_data_report.jsonl \
  --fields accession,assminfo-name,organism-name,assmstats-total-sequence-len
```

## Uncompressed files

The files downloaded by `datasets` are zipped. Unzip with the host's `unzip`:

```bash
unzip GCA_000005845.2.zip -d GCA_000005845.2
```

The extracted layout is:

```text
GCA_000005845.2/
  README.md
  ncbi_dataset/
    data/
      assembly_data_report.jsonl
      GCA_000005845.2/
        GCA_000005845.2_*_genomic.fna   # genome FASTA
        genomic.gff                     # only if --include gff3 was used
        protein.faa                     # only if --include protein was used
        ...
```

The genome sequence file always has the `.fna` extension.


## Sample accessions

This is a list of accessions for common organisms:


| **Common Name**           | **Scientific Name**            | **GCA (GenBank)**    | **GCF (RefSeq)**     | **Assembly / Notes**                                                |
| ------------------------- | ------------------------------ | -------------------- | -------------------- | ------------------------------------------------------------------- |
| **E. coli** (K-12 MG1655) | *Escherichia coli* K-12 MG1655 | **GCA_000005845.2**  | **GCF_000005845.2**  | Standard non-pathogenic lab strain.                                 |
| **Human**                 | *Homo sapiens*                 | **GCA_000001405.29** | **GCF_000001405.40** | GRCh38.p14 reference genome.                                        |
| **Mouse**                 | *Mus musculus*                 | **GCA_000001635.9**  | **GCF_000001635.27** | GRCm39 reference genome.                                            |
| **Rat**                   | *Rattus norvegicus*            | **GCA_036323735.1**  | **GCF_036323735.1**  | GRCr8 reference genome.                                             |
| **Zebrafish**             | *Danio rerio*                  | **GCA_000002035.4**  | **GCF_000002035.6**  | GRCz11 reference genome.                                            |
| **Fruit fly**             | *Drosophila melanogaster*      | **GCA_000001215.4**  | **GCF_000001215.4**  | BDGP Release 6 (ISO1).                                              |
| **C. elegans**            | *Caenorhabditis elegans*       | **GCA_000002985.3**  | **GCF_000002985.3**  | WBcel235 reference.                                                 |
| **Yeast**                 | *Saccharomyces cerevisiae*     | **GCA_000146045.2**  | **GCF_000146045.2**  | R64 reference.                                                      |
| **Arabidopsis**           | *Arabidopsis thaliana*         | **GCA_000001735.1**  | **GCF_000001735.4**  | TAIR10 reference.                                                   |
| **Chicken**               | *Gallus gallus*                | **GCA_016699485.2**  | **GCF_016699485.2**  | GRCg7b reference genome.([NCBI][1])                                 |
| **Pig**                   | *Sus scrofa*                   | **GCA_000003025.6**  | **GCF_000003025.6**  | Sscrofa11.1 reference genome.([National Genomics Data Center][2])   |
| **Cow**                   | *Bos taurus*                   | **GCA_002263795.4**  | **GCF_002263795.3**  | ARS-UCD2.0 reference genome.([animalgenome.org][3])                 |
| **Frog** (Western clawed) | *Xenopus tropicalis*           | **GCA_000004195.4**  | **GCF_000004195.4**  | UCB_Xtro_10.0 reference genome.([UCSC Genome Browser Downloads][4]) |

[1]: https://www.ncbi.nlm.nih.gov/grc/chicken "Chicken Genome Overview - Genome Reference Consortium"
[2]: https://ngdc.cncb.ac.cn/gwh/ncbi_assembly/34632/show "Genome Warehouse - National Genomics Data Center"
[3]: https://www.animalgenome.org/QTLdb/doc/genome_versions "Animal QTL database: genome versions information"
[4]: https://hgdownload.cse.ucsc.edu/gbdb/xenTro10/html/description.html "hgdownload.cse.ucsc.edu"

## Citation

If the user asks for a citation, provide the following:

O'Leary NA, Cox E, Holmes JB, Anderson WR, Falk R, Hem V, Tsuchiya MTN, Schuler GD, Zhang X, Torcivia J, Ketter A, Breen L, Cothran J, Bajwa H, Tinne J, Meric PA, Hlavina W, Schneider VA. Exploring and retrieving sequence and metadata for species across the tree of life with NCBI Datasets. Sci Data. 2024 Jul 5;11(1):732. doi: 10.1038/s41597-024-03571-y. PMID: 38969627; PMCID: PMC11226681.

