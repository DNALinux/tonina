---
name: ncbidatasets
description: "Uses ncbi-datasets docker to download genomes."
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
---

# NCBI Datasets


NCBI Datasets is a tool for downloading genomes from NCBI. It can also be used to find genome accessions.


## Datasets Usage

When the user needs to download a genome, use the ncbi-datasets docker container to download the genome.

If the user provides a genome accession, use the ncbi-datasets docker container to download it:

```bash
docker run --network=host -v $(pwd):/ftmp dnalinux/ncbi-datasets:18.18.0 /bin/bash -c "/datasets download genome accession GCA_000005845.2 --filename /ftmp/GCA_000005845.2.zip"
```

If the user provides a genome name, you first need to find the genome accession. You can do this by using the ncbi-datasets docker with summary command to search for the genome name:

```bash
docker run --network=host -v $(pwd):/ftmp dnalinux/ncbi-datasets:18.18.0 /bin/bash -c "/datasets summary genome taxon 'Escherichia coli' --reference"
```

If the user provided a proper name, this will return a JSON object with the genome information. You can then use the accession from the JSON object to download the genome.
If there are multiple genomes that match the name, you should ask the user which one they want to download.

If the user provided an ambiguous name, like "E. coli", you will get a list of genomes that match the name:

```bash
docker run --network=host -v $(pwd):/ftmp dnalinux/ncbi-datasets:18.18.0 /bin/bash -c "/datasets summary genome taxon 'E. coli' --reference"
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

In this case, you should ask the user which one they want to download.


## Uncompressed files

The files downloaded by ncbi-datasets are compressed. If the user wants uncompressed files, you should use the `unzip` command to unzip the files. Once uncompressed, the files will be in a directory called `ncbi_dataset\data` and then the accession. The sequence file will be the one with the extension `.fna`.


## Sample accessions

This is a list of accessions for common organisms:


| **Common Name**           | **Scientific Name**            | **GCA (GenBank)**    | **GCF (RefSeq)**     | **Assembly / Notes**                                                |
| ------------------------- | ------------------------------ | -------------------- | -------------------- | ------------------------------------------------------------------- |
| **E. coli** (K-12 MG1655) | *Escherichia coli* K-12 MG1655 | **GCA_000005845.2**  | **GCF_000005845.2**  | Standard non-pathogenic lab strain.                                 |
| **Human**                 | *Homo sapiens*                 | **GCA_000001405.29** | **GCF_000001405.40** | GRCh38.p14 reference genome.                                        |
| **Mouse**                 | *Mus musculus*                 | **GCA_000001635.9**  | **GCF_000001635.27** | GRCm39 reference genome.                                            |
| **Rat**                   | *Rattus norvegicus*            | —                    | **GCF_036323735.1**  | GRCr8 reference genome.                                             |
| **Zebrafish**             | *Danio rerio*                  | **GCA_000002035.4**  | **GCF_000002035.6**  | GRCz11 reference genome.                                            |
| **Fruit fly**             | *Drosophila melanogaster*      | **GCA_000001215.4**  | **GCF_000001215.4**  | BDGP Release 6 (ISO1).                                              |
| **C. elegans**            | *Caenorhabditis elegans*       | **GCA_000002985.3**  | **GCF_000002985.3**  | WBcel235 reference.                                                 |
| **Yeast**                 | *Saccharomyces cerevisiae*     | **GCA_000146045.2**  | **GCF_000146045.2**  | R64 reference.                                                      |
| **Arabidopsis**           | *Arabidopsis thaliana*         | **GCA_000001735.1**  | **GCF_000001735.4**  | TAIR10 reference.                                                   |
| **Chicken**               | *Gallus gallus*                | **GCA_000002315.5**  | **GCF_000002315.5**  | GRCg6a reference genome.([NCBI][1])                                 |
| **Pig**                   | *Sus scrofa*                   | **GCA_000003025.6**  | **GCF_000003025.6**  | Sscrofa11.1 reference genome.([National Genomics Data Center][2])   |
| **Cow**                   | *Bos taurus*                   | **GCA_002263795.4**  | **GCF_002263795.3**  | ARS-UCD2.0 reference genome.([animalgenome.org][3])                 |
| **Frog** (Western clawed) | *Xenopus tropicalis*           | **GCA_000004195.4**  | **GCF_000004195.4**  | UCB_Xtro_10.0 reference genome.([UCSC Genome Browser Downloads][4]) |

[1]: https://www.ncbi.nlm.nih.gov/grc/chicken?utm_source=chatgpt.com "Chicken Genome Overview - Genome Reference Consortium"
[2]: https://ngdc.cncb.ac.cn/gwh/ncbi_assembly/34632/show?utm_source=chatgpt.com "Genome Warehouse - National Genomics Data Center"
[3]: https://www.animalgenome.org/QTLdb/doc/genome_versions?utm_source=chatgpt.com "Animal QTL database: genome versions information"
[4]: https://hgdownload.cse.ucsc.edu/gbdb/xenTro10/html/description.html?utm_source=chatgpt.com "hgdownload.cse.ucsc.edu"


