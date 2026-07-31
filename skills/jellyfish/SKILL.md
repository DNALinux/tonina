---
name:  Jellyfish
description: Jellyfish is a tool for fast, memory-efficient counting of k-mers in DNA. A k-mer is a substring of length k, and counting the occurrences of all such substrings is a central step in many analyses of DNA sequence. Jellyfish can count k-mers using an order of magnitude less memory and an order of magnitude faster than other k-mer counting packages by using an efficient encoding of a hash table and by exploiting the "compare-and-swap" CPU instruction to increase parallelism.
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

# Jellyfish - k-mer DNA Counting Skill 

This skill does fast, memory-efficient counting of k-mers in DNA.

## When This Skill Is Used

Use this workflow when you have:
- At least one FASTA file
- A need to count the occurrences of all k-mers, or substrings of length k, of a DNA sequence. 

This approach is **not** suitable for:
- Pairwise assignment tasks
- Aligning genomic structural variants, whole chromosomes, or sequencing reads against a reference genome

## Input Types

- **DNA files** — FASTA or FASTQ files containing DNA sequences (`.fasta` or `.fa`) or (`.fastq` or `.fq`).
- Note: Jellyfish only reads FASTA or FASTQ formatted input files. By reading from pipes, jellyfish can read compressed files, like this:
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
bash -c '
zcat *.fastq.gz | jellyfish count /dev/fd/0
'
```

# Jellyfish Task Router

Select a specific operational path to jump directly to its complete configuration and parameters:

- **Counting K-mers**
  - [Count All K-mers] -- see heading "Workflow: Count All K-mers with jellyfish count"
  - [Count Only High-Frequency K-mers using One Pass Method ] -- see heading "Workflow: Count Only High-Frequency K-mers using One Pass Method with jellyfish count"
  - [Count Only High-Frequency K-mers using Two Pass Method ] -- see heading "Workflow: Count Only High-Frequency K-mers using Two Pass Method with jellyfish bc and jellyfish count"
- **K-mer Analysis**
  - [Compute Historgram] -- see heading "Workflow: Compute Histogram with jellyfish histo"
  - [Query Counts Of Particular K-mer] -- see heading "Workflow: Query Counts Of Particular K-mer using jellyfish query"
  - [Output All Counts For All K-mers] -- see heading "Workflow: Output All Counts For All K-mers using jellyfish dump"

---

## Workflows

### Workflow: Count All K-mers with jellyfish count

- Note: In sequencing reads, it is unknown which strands of the DNA is sequenced. As a consequence, a k-mer or its reverse complement are essentially equivalent. The canonical representative of a k-mer m is by definition m or the reverse complement of m, whichever comes first lexicographically. The -C switch instructs to save in the hash only canonical k-mers, while the count is the number of occurrences of both a k-mer and it reverse complement.
- Note: In an actual genome or finished sequence, a k-mer and its reverse complement are not equivalent, hence using the -C switch does not make sense. In addition, the size for the hash can be set directly to the size of the genome.

### Step 1: Count All K-mers

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
count \
-m 21 \
-s 100M \
-t $(nproc) \
-o mer_counts.jf \
-C \
reads.fasta
```

- `-m`: Length of mer
- `-s`: Hash size
- `-t`: Number of threads (1)
- `-o`: Output file
- `-C`: Count both strands, canonical representation (false)

**Note on Hash Size:**
- Set -s to roughly the number of distinct k-mers you expect to count, and for short-read data multiply by ~1.5 for safety.
- More concretely:
  - Single genome or assembled FASTA
    - Estimate for -s: Genome size in bp (or 2× if not using -C)
  - 30× whole-genome resequencing
    - Estimate for -s: Total distinct k-mers ≈ total sequenced bases. For a 3 Gbp genome at 30×, that's ~90 Gbp, so use -s 90G if counting everything.
  - High-frequency only (e.g., >1×, with Bloom filter)
    - Estimate for -s: Use the expected genome size, not the read volume. For human, -s 3G is standard.
  - Bacterial genome (~5 Mbp)
    - Estimate for -s: -s 10M to -s 50M is plenty.
- Quick formula
  - -s ≈ (genome_size × ploidy × coverage / coverage_threshold) × safety_factor
  - Where:
    - genome_size = haploid genome length
    - ploidy = 2 for diploid, 1 for haploid
    - coverage_threshold = minimum count you keep (e.g., 2 if you discard singletons)
    - safety_factor = 1.5 to 2.0 to avoid rehashing
- Example
  - Human genome, 3 Gbp, diploid, 30× coverage, keeping k-mers seen ≥2 times:
  - -s ≈ (3 Gbp × 2 × 30 / 2) × 1.5 ≈ 135 G
  - So -s 100G to -s 150G is reasonable.
- If you set -s too small, Jellyfish will still work but will rehash multiple times, slowing down the run. If you set it too large, it simply allocates more memory than needed. The error message "Too many k-mers in hash" means the hash filled up and you should increase -s or use a Bloom filter.

### Workflow: Compute Histogram with jellyfish histo

### Step 1: Compute Histogram

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
histo mer_counts.jf
```

### Workflow: Query Counts Of Particular K-mer using jellyfish query

### Step 1: Query Counts Of Particular K-mer

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
query mer_counts.jf AACGTTG
```

### Workflow: Output All Counts For All K-mers using jellyfish dump

### Step 1: Output All Counts For All K-mers

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
dump mer_counts.jf > mer_counts_dumps.fa
```

### Workflow: Count Only High-Frequency K-mers using One Pass Method with jellyfish count

### Step 1: Count Only High-Frequency K-mers using One Pass Method with jellyfish count
- This example code specifically covers counting 25-mers in human reads at 30x coverage.
- Note: The drawback of this method is some percentage of the k -mer that should not be reported (because they occur only once) are reported. This is due to the random nature of the Bloom filter data structure. The percentage is <1% by default and can be changed with the `--bf-fp` switch.

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
count \
-m 25 \
-s 3G \
--bf-size 100G \
-t $(nproc) \
homo_sapiens.fa
```

- `--bf-size`: First inserts all k-mers first into a Bloom filter and only insert into the hash the k-mers which have already been seen at least once. The argument should be the total number of k-mer expected in the data set.
- `--size`: Number of k -mers occurring more than once.

### Workflow: Count Only High-Frequency K-mers using Two Pass Method with jellyfish bc and jellyfish count

### Step 1: Count Only High-Frequency K-mers using Two Pass Method with jellyfish bc and jellyfish count
- In the two pass method, first a Bloom counter is created from the reads with jellyfish bc. Then this Bloom counter is given to the jelllyfish count command and only the k-mers which have been seen twice in the first pass will be inserted in the hash. For example, with a human data set similar that in section One pass method:
- The advantage of this method is that the counts reported for the k-mers are all correct. Most count 1 k-mer are not reported, except for a small percentage (set by the false positive rate, -f switch of the bc subcommand) of them which are reported (correctly with count 1). All other k-mers are reported with the correct count.
- The drawback of this method is that it requires to parse the entire reads data set twice and the memory usage of the Bloom counter is greater than that of the Bloom filter (slightly less than twice as much).

#### Step 1a: Create a Bloom counter from the reads with jellyfish bc
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
bc \
-m 25 \
-s 100G \
-t $(nproc) \
-o homo_sapiens.bc \
homo_sapiens.fa
```

#### Step 1b: Pass bloom counter to jellyfish count to count high-frequency k-mers 
- Note: Due to the bloom counter, only the k-mers which have been seen twice in the first pass will be inserted in the hash.

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
count \
-m 25 \
-s 3G \
-t $(nproc) \
--bc homo_sapiens.bc \
homo_sapiens.fa
```
- `--bc`: Input bloom counter file

## Output

Each run of `jellyfish` produces at least one file:

- `mer_counts.jf` — k-mer counts in a binary format, which can be translated into a human-readable text format using the "jellyfish dump" command, or queried for specific k-mers with "jellyfish query". 
- `mer_counts_dumps.fa` —  list of all the k-mers in the file associated with their count. By default, the output is in FASTA format, where the header line contains the count of the k-mer and the sequence part is the sequence of the k-mer. Only produced if jellyfish dump is run.
- `homo_sapiens.bc` —  Bloom counter/filter so that only the k-mers which have been seen twice in the first pass will be inserted in the hash. Only produced if jellyfish bc is run.

---

## Additional Useful Parameters

These can be added to the `jellyfish count` command:

- `--if`: count the number of occurrences of only a subset of predefined k-mers
  - Input to `jellyfish count` will still be the main input being scanned.
  - Input to the `--if` flag will be the whitelist: only k-mers present here are counted in input genome file to jellyfish count. The output jellyfish file contains counts for k-mers that appear in both files.
  - Note that k-mers in chr20.fa must have the same length as -m. Whitelisted k-mers that do not occur in the input genome file to jellyfish count will still appear in the output with count 0.

**Example: Counting a subset of k-mers- Count the number of occurrences of the 20-mers of chromosome 20 in chromosome 1 of human**
- chr1.fa is the main input being scanned.
- chr20.fa is the whitelist: only k-mers present here are counted in chr1.fa. The output chr1_shared_with_chr20.jf contains counts for k-mers that appear in both files.
- Important: k-mers in chr20.fa must have the same length as -m (20 in this example). Whitelisted k-mers that do not occur in chr1.fa will still
appear in the output with count 0.

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
jellyfish \
count \
-m 20 \
-s 100M \
-C \
-t $(nproc) \
-o chr1_shared_with_chr20.jf \
--if chr20.fa \
chr1.fa
```

## Citation

If the user asks for a citation for jellyfish, provide the following:

Guillaume Marcais and Carl Kingsford, A fast, lock-free approach for efficient parallel counting of occurrences of k-mers. Bioinformatics (2011) 27(6): 764-770 (first published online January 7, 2011) doi:10.1093/bioinformatics/btr011