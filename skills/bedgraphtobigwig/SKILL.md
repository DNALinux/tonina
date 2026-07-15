---
name: bedGraph to bigWig Conversion
description: "Convert a text-based bedGraph file into a binary, indexed bigWig file for efficient visualization and genomic analysis."
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

# bedGraph to bigWig Conversion Skill

This skill converts a text-based bedGraph file into a binary bigWig (.bw) file using the UCSC utility bedGraphToBigWig. This conversion reduces file size dramatically and enables rapid, remote, and interactive visualization in genome browsers (like the UCSC Genome Browser, IGV, or JBrowse) without loading the entire dataset into memory.

## When This Skill Is Used

Use this workflow when you have:

- Continuous genomic data (e.g., RNA-seq read coverage, ChIP-seq signal strength, methylation levels) in bedGraph format.
- A requirement to upload coverage tracks to web-based genome browsers or share them with collaborators.
- Large files that cause performance lag in local visualization tools.

This approach is *not* suitable for:
- Discrete genomic features with non-continuous data (e.g., gene annotations, exons, transcription factor binding sites). Use bedToBigBed or Keep them as .bed files instead.
- bedGraph files that have not been sorted. The tool will fail if the input is unsorted.

## Input Types

- **bedGraph file** — A four-column, tab-delimited text file (`.bedGraph`). It must be sorted by chromosome, then by start position.
- **Chromosome sizes file** — A two-column, tab-delimited text file (`chrom.sizes`) containing chromosome/scaffold names in the first column and their total base pair lengths in the second column (e.g., chr1  248956422).
---

## Workflow

### Step 1: Sort the bedGraph File

The bedGraphToBigWig utility strictly requires the input bedGraph file to be sorted. You can easily sort it using standard Linux commands:

```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 sh -c \ "LC_COLLATE=C sort -k1,1 -k2,2n input.bedGraph > sorted.bedGraph"
```

- Skip this step if bedgraph file is already sorted.

### Step 2: Prepare the Chromosome Sizes File

The tool needs to know the exact boundary limits of each chromosome. If you do not have a chrom.sizes file, you can generate one using one of the options below:

# Option A: Generate from a reference FASTA index (.fai)
If you have your reference genome indexed with samtools faidx

```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 sh -c \ "cut -f1,2 reference.fa.fai > chrom.sizes"
```

# Option B: Option B: Download from UCSC (e.g., for Human hg38)

```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 sh -c \ "wget -qO- http://hgdownload.cse.ucsc.edu/goldenpath/hg38/bigZips/hg38.chrom.sizes > chrom.sizes"
```

### Step 3: Step 3: Run the bedGraphToBigWig Conversion

Execute the Docker container to perform the conversion:

```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 bedGraphToBigWig \\
  /data/sorted.bedGraph \\
  /data/chrom.sizes \\
  /data/output.bw
  ```

## Output

Running this tool successfully generates a single binary file:

- `output.bw` — A highly compressed, indexed binary BigWig file, ready to be hosted on an HTTP/FTP server or loaded directly into IGV.

---

## Additional Useful Parameters

These can be added to the `bedGraphToBigWig` command:

- `-blockSize=N` — Size of parameter blocks (default is 256). Higher values speed up queries on local files but might increase network overhead for remote files.

- `-itemsPerSlot=N` — Number of data points grouped together (default is 1024). Lower values can improve zoom resolution but increase file size.

- `-unc` — Disable compression. Useful only for debugging purposes as it produces much larger files.

**Example with custom block size:**

```bash
docker run --rm -v $(pwd):/data -w /data bedgraphtobigwig:2.10 bedGraphToBigWig \\
  -blockSize=512 \\
  /data/sorted.bedGraph \\
  /data/chrom.sizes \\
  /data/output.bw
```
---

## Citation

If using bedGraphToBigWig in published work, please cite:

Kent, W. J., Zweig, A. S., Barber, G., Hinrichs, A. S., & Karolchik, D. (2010). BigWig and BigBed: enabling browsing of large distributed datasets. Bioinformatics, 26(17), 2204–2207.
https://doi.org/10.1093/bioinformatics/btq351
"""
