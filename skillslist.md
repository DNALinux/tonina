# list of containers/skills in docker with those in tonina crossed off
Note: seqsample in tonina does not correspond to a container in OmicsContainer

- ~~bcftools~~
- ~~spades~~
- ~~fastp~~
- ~~fastqc~~
- ~~sra-toolkit~~
- bwa-mem2
- ~~minimap2~~
- bwa
- bedgraphtobigwig
- ~~ncbi-datasets~~
- ncbi-tools-bin
- samtools
- ~~primer3~~
- jbrowse2
- pear
- tabix
- jbrowse
- takollama
- biopython
- repeatmasker
- nanocaller
- pythonnogil
- dipy
- allhic
- jellyfish
- quast
- antismash
- kofamscan
- diamond
- hifiasm
- gatk
- 3ddna
- metal
- hmmer
- redundans
- trimmomatic
- mitohifi-code
- funannotate-gmes-ascomycota
- allofplos
- orthofinder
- interproscan
- funannotate-gmes-dikarya
- funannotate-gmes
- funannotate-dikarya-gmes
- funannotate-dikarya
- mitohifi-base
- mitohifibase
- funannotate
- pilon
- lr_gapcloser
- sspace_longread
- gfatools
- dorado
- anvio
- cvtree
- bedtools
- clustalo
- muscle
- bowtie2
- phylip
- blast-static

# potential skill groupings

## no summary
- bcftools
- ncbi-datasets
- ncbi-tools-bin
- jbrowse2
- jbrowse
- tabix
- takollama
- dipy
- diamond
- 3ddna

## bwa- same name
- bwa-mem2
- bwa2

## funannotate- same name
- funannotate-gmes-ascomycota
- funannotate-gmes-dikarya
- funannotate-gmes
- funannotate-dikarya-gmes
- funannotate-dikarya
- funannotate

## mitohifi- same name
- mitohifi-code
- mitohifi- base
- mitohifibase

## toolkits
- sra-toolkit
- samtools
- gatk

## python
- biopython
- pythonnogil

## comparative analysis
- hmmer
- blast-static

## phylogenetic trees
- cvtree
- phylip

## long reads
- sspace_longread
- lr_gapcloser

## assembly
- spades
- hifiasm
- redundans
- mitohifi-code
- mitohifi-base
- mitohifibase
- pilon

# potential skill groupings from AI- Google Gemini

## 1. Data Retrieval & Core Utilities

* **sra-toolkit**: Essential for downloading, converting, and analyzing high-throughput sequencing data (FASTQ, SAM) from the NCBI Sequence Read Archive.
* **ncbi-datasets**: Command-line utility used to easily download genomic data, metadata, and structures directly from NCBI databases.
* **ncbi-tools-bin**: A collection of core software libraries and binaries provided by NCBI for processing biological data.
* **allofplos**: Used for downloading, updating, and maintaining a local repository of all PLOS XML open-access article files for text-mining or reference.

## 2. Quality Control & Preprocessing

* **fastqc**: Conducts quick quality control checks on raw sequence data to identify potential artifacts or systematic sequencing errors.
* **fastp**: An all-in-one, ultra-fast FASTQ preprocessor written in C++ that handles QC, adapter trimming, and filtering.
* **trimmomatic**: A flexible tool specifically tailored for trimming Illumina paired-end and single-end data based on quality scores.
* **pear**: An ultrafast, memory-efficient, and highly accurate tool to merge forward and reverse paired-end reads into longer single reads.

## 3. Read Alignment & Sequence Mapping

* **bwa**: Maps low-divergent short sequences against a large reference genome using three algorithms (BWA-backtrack, BWA-SW, and BWA-MEM).
* **bwa-mem2**: The heavily optimized next-generation version of bwa-mem, producing identical alignments but running up to 3x faster.
* **bowtie2**: An ultrafast, memory-efficient tool optimized for aligning short sequencing reads to long reference genomes.
* **minimap2**: A highly versatile sequence alignment program designed to map both DNA and mRNA sequences against large databases.

## 4. Genome Assembly, Scaffolding, & Gap Closing

* **spades**: A versatile de novo genome assembler designed for single-cell, isolate, RNA, plasmid, and standard bacterial data sets.
* **hifiasm**: A fast, haplotype-resolved de novo assembler optimized for highly accurate PacBio HiFi and ultralong Oxford Nanopore reads.
* **mitohifi-code**: Part of the MitoHiFi pipeline used to assemble and annotate mitochondrial genomes from Pacbio HiFi data.
* **mitohifi-base**: Base installation and dependencies required to run the MitoHiFi mitochondrial assembly workflow.
* **mitohifibase**: Core package variation for assembling mitochondrial genomes from PacBio HiFi data.
* **quast**: Quality Assessment Tool for Genome Assemblies; evaluates the quality of genomic assemblies by comparing them to close references or analyzing structural properties.
* **pilon**: Automated tool to improve draft assemblies (polishing) and detect variants using alignment data.
* **lr_gapcloser**: A tool that uses long reads to fill in unsequenced gaps within pre-existing genome assemblies.
* **sspace_longread**: A stand-alone program for scaffolding pre-assembled contigs using long-read sequencing data.
* **allhic**: Handles genome scaffolding specifically by leveraging Hi-C proximity data, which is highly effective for complex, polyploid, or heterozygous genomes.
* **3ddna**: A pipeline designed to automate chromosome-length genome assembly and scaffolding utilizing Hi-C data.
* **redundans**: A specialized pipeline that simplifies and assists in the assembly of highly heterozygous genomes by collapsing redundant contigs.
* **gfatools**: A utility suite for manipulating and converting sequence graphs format (GFA/rGFA) into standard FASTA/BED formats.

## 5. Variant Calling & File Manipulation

* **samtools**: The fundamental suite of utilities for converting, sorting, indexing, merging, and manipulating alignments in SAM, BAM, and CRAM formats.
* **bcftools**: A companion to samtools used for variant calling and manipulating VCF (Variant Call Format) and BCF files.
* **tabix**: A generic indexer for TAB-delimited genome position files, making it incredibly fast to query specific genomic regions in large VCF or BED files.
* **gatk**: The industry-standard package developed by the Broad Institute focusing on high-accuracy variant discovery, genotyping, and data quality assurance.
* **nanocaller**: A deep-learning convolutional neural network approach for accurate SNP and Indel detection specifically using long-read sequencing data.

## 6. Functional Annotation & Feature Analysis

* **antismash**: Rapidly identifies, annotates, and analyzes secondary metabolite biosynthesis gene clusters in bacterial and fungal genomes.
* **funannotate**: A genome prediction, structural annotation, and comparison package custom-tailored for small eukaryotes and fungal genomes.
* **funannotate-gmes-ascomycota**: Funannotate pipeline component customized with GeneMark-ES for Ascomycota fungal genome annotation.
* **funannotate-gmes-dikarya**: Funannotate pipeline component customized with GeneMark-ES for Dikarya fungal genome annotation.
* **funannotate-gmes**: Funannotate pipeline integrated with GeneMark-ES for automated structural gene prediction.
* **funannotate-dikarya-gmes**: Funannotate pipeline variant optimized specifically for Dikarya fungi using GeneMark-ES.
* **funannotate-dikarya**: Automated pipeline optimized specifically for the structural and functional annotation of Dikarya fungal genomes.
* **kofamscan**: A gene function annotation tool utilizing KEGG Orthology and Hidden Markov Models (HMM) to assign biological pathways.
* **interproscan**: Integrates multiple protein feature databases to provide an overarching functional classification, detecting domains, families, and active sites.
* **diamond**: An ultra-fast, local sequence aligner optimized for matching protein or translated DNA sequences against massive databases.
* **hmmer**: Uses profile Hidden Markov Models (HMMs) to perform highly sensitive sequence database searches to find remote protein homologs.

## 7. Comparative Genomics & Phylogenetics

* **orthofinder**: A comprehensive comparative genomics platform that finds orthogroups/orthologs and infers rooted gene trees to track evolutionary duplications.
* **jellyfish**: A parallelized, memory-efficient k-mer counter used for estimating genome size and identifying unique sequence patterns.
* **blast-static**: The local, standalone binary version of NCBI BLAST used to find regions of local similarity between biological sequences.
* **clustalo**: A multiple sequence alignment tool that scales well to thousands of protein or nucleotide sequences using seeded guide trees.
* **muscle**: A highly popular and accurate software package for making multiple sequence alignments of amino acid or nucleotide strings.
* **phylip**: A classical, comprehensive package of programs used for inferring evolutionary/phylogenetic trees.
* **cvtree**: Reconstructs whole-genome based phylogenetic trees without requiring sequence alignment by employing a Composition Vector (CV) method.

## 8. Visualization & Coordinate Tracking

* **jbrowse**: A fast, embeddable web genome browser built with JavaScript and HTML5 for visualizing diverse genomic tracks.
* **jbrowse2**: The next-generation, highly pluggable web genome browser designed to interactively visualize structural variants and multiple linear or circular views.
* **bedtools**: The swiss-army knife of genomics utilities, allowing you to intersect, merge, count, and manipulate genomic features across BED, GFF, and BAM formats.
* **bedgraphtobigwig**: Converts standard text-based bedGraph files into compressed, binary bigWig files ideal for fast rendering in genome browsers.
* **repeatmasker**: Screens DNA sequences for interspersed repeats and low-complexity regions, masking them out so they do not skew downstream alignments.
* **primer3**: A highly specialized and widely utilized program for designing PCR primers, hybridization probes, and sequencing primers.

## 9. Programming, AI, & Specialized Domains

* **biopython**: A comprehensive library of free Python tools for biological computation (parsing files, interacting with databases, translating sequences).
* **pythonnogil**: A specialized precompiled build of Python with the Global Interpreter Lock (GIL) removed, allowing for true multi-threaded parallel performance.
* **takollama**: A specialized library built on top of Ollama, often utilized to query genomics databases using AI language models via Retrieval-Augmented Generation (RAG).
* **dorado**: A high-performance, open-source production basecaller developed by Oxford Nanopore Technologies for real-time signal processing.
* **anvio**: An advanced, interactive computational platform designed for analyzing and visualizing microbial 'omics data, pangenomes, and metagenomes.
* **dipy**: Diffusion Imaging in Python; a scientific library focused on analyzing and visualizing 3D medical neuroimaging data.
* **metal**: A command-line program designed to facilitate the meta-analysis of massive genome-wide association study (GWAS) datasets.

# in docker with summaries
bcftools- 
spades- De novo assembler for single-cell, isolate, RNA, plasmid genomes and metagenomes, SPAdes Genome Assembler is an open source tool for de novo sequencing. This application is designed to assemble small genomes from MDA single-cell and standard bacterial data sets. SPAdes supports paired-end reads, mate-pairs (including high quality Nextera Mate Pairs) and unpaired reads.
fastp- All in one FASTQ preprocessor, A tool designed to provide fast all-in-one preprocessing for FastQ files. This tool is developed in C++ with multithreading supported to afford high performance.
fastqc- Conduct quality control of raw sequence data, FastQC aims to provide a simple way to do some quality control checks on raw sequence data coming from high throughput sequencing pipelines. It provides a modular set of analyses which you can use to give a quick impression of whether your data has any problems of which you should be aware before doing any further analysis.
sra-toolkit- The SRA Toolkit and SDK from NCBI is a collection of tools for using data in the INSDC SRA, The SRA Toolkit is essential for downloading, converting, and analyzing high-throughput sequencing data (FASTQ, SAM) from the NCBI Sequence Read Archive
bwa-mem2- The tool bwa-mem2 is the next version of the bwa-mem algorithm in bwa, The tool bwa-mem2 is the next version of the bwa-mem algorithm in bwa. It produces alignment identical to bwa and is ~1.3-3.1x faster depending on the use-case, dataset and the running machine.
minimap2- Sequence alignment program that aligns DNA or mRNA sequences against a large reference database.
bwa- Mapping low-divergent sequences against a larger reference genome, BWA is a software package for mapping low-divergent sequences against a large reference genome, such as the human genome. It consists of three algorithms: BWA-backtrack, BWA-SW and BWA-MEM. 
bedgraphtobigwig- Convert bedGraph to bigWig file
ncbi-datasets-
ncbi-tools-bin- 
samtools- Suite of programs for interacting with high-throughput sequencing data, Samtools is a set of utilities that manipulate alignments in the SAM (Sequence Alignment/Map), BAM, and CRAM formats. It converts between the formats, does sorting, merging and indexing, and can retrieve reads in any regions swiftly.
primer3- Design PCR primers from DNA sequence, Primer3 is a widely used program for designing PCR primers (PCR = "Polymerase Chain Reaction"). PCR is an essential and ubiquitous tool in genetics and molecular biology. Primer3 can also design hybridization probes and sequencing primers.
jbrowse2- 
pear- Ultrafast, memory-efficient and highly accurate pair-end read merger
tabix- 
jbrowse- 
takollama- 
biopython- Biopython is a set of freely available tools for biological computation written in Python, Biopython is a set of freely available tools for biological computation written in Python by an international team of developers.
repeatmasker- Screening DNA sequences for interspersed repeats and low complexity sequences, RepeatMasker is a program that screens DNA sequences for interspersed repeats and low complexity DNA sequences. The output of the program is a detailed annotation of the repeats that are present in the query sequence as well as a modified version of the query sequence in which all the annotated repeats have been masked (default: replaced by Ns). On average, almost 50% of a human genomic DNA sequence currently will be masked by the program. Sequence comparisons in RepeatMasker are performed by the program cross_match, an efficient implementation of the Smith-Waterman-Gotoh algorithm developed by Phil Green.
nanocaller- Integrates long reads for the detection of SNPs/indels from long-read sequencing data, NanoCaller is a computational method that integrates long reads in deep convolutional neural network for the detection of SNPs/indels from long-read sequencing data. NanoCaller uses long-range haplotype structure to generate predictions for each SNP candidate variant site by considering pileup information of other candidate sites sharing reads. Subsequently, it performs read phasing, and carries out local realignment of each set of phased reads and the set of all reads for each indel candidate variant site to generate indel calling, and then creates consensus sequences for indel sequence prediction.
pythonnogil- Python precompiled with no-GIL (aka free-threading)
dipy- 
allhic- Genome scaffolding based on HiC data in heterozygous and high ploidy genomes, ALLHIC: Genome scaffolding based on Hi-C data, ALLHiC can be used to scaffold genomic contigs based on Hi-C data, which is particularly effectively for auto-polyploid or heterozygous diploid genomes.
jellyfish- count k-mers in DNA sequences, JELLYFISH is a tool for fast, memory-efficient counting of k-mers in DNA. A k-mer is a substring of length k, and counting the occurrences of all such substrings is a central step in many analyses of DNA sequence. JELLYFISH can count k-mers using an order of magnitude less memory and an order of magnitude faster than other k-mer counting packages by using an efficient encoding of a hash table and by exploiting the "compare-and-swap" CPU instruction to increase parallelism.
quast-
antismash- the antibiotics and Secondary Metabolite Analysis SHell, antiSMASH allows the rapid genome-wide identification, annotation and analysis of secondary metabolite biosynthesis gene clusters in bacterial and fungal genomes. It integrates and cross-links with a large number of in silico secondary metabolite analysis tools that have been published earlier.
kofamscan- KofamScan is a gene function annotation tool based on KEGG Orthology and hidden Markov model, KofamScan is a gene function annotation tool based on KEGG Orthology and hidden Markov model. You need KOfam database to use this tool. 
diamond- 
hifiasm- A haplotype-resolved assembler for accurate HiFi reads, Hifiasm is a fast haplotype-resolved de novo assembler initially designed for PacBio HiFi reads. Its latest release could support the telomere-to-telomere assembly by utilizing ultralong Oxford Nanopore reads. Hifiasm produces arguably the best single-sample telomere-to-telomere assemblies combing HiFi, ultralong and Hi-C reads, and it is one of the best haplotype-resolved assemblers for the trio-binning assembly given parental short reads. For a human genome, hifiasm can produce the telomere-to-telomere assembly in one day.
gatk- Genome analysis toolkit, The Genome Analysis Toolkit or GATK is a software package for analysis of high-throughput sequencing data, developed by the Data Science and Data Engineering group at the Broad Institute. The toolkit offers a wide variety of tools, with a primary focus on variant discovery and genotyping as well as strong emphasis on data quality assurance.
3ddna- 
metal- METAL is designed to facilitate meta-analysis of large datasets (such as several whole genome scans)
hmmer- Conduct sequence analysis and alignments using profile hidden Markov models, HMMER is a tool that conducts bio-sequence analysis using profile-hidden Markov models. HMMER searches through sequence databases to identify sequence homologs and conduct alignments using methods of probability statistics called profile hidden Markov models (HMMs). HMMER is designed to detect remote homologs with increased sensitivity, relying on probability statistics methods. Nowadays, HMMER has less computational expense and is as fast as BLAST.
redundans- Assists in the assembly of heterozygous genomes, Redundans is a pipeline that assists the assembly of heterozygous genomes. It takes as input assembled contigs, sequencing libraries and/or reference sequence and returns scaffolded homozygous genome assembly.
trimmomatic- Conducts trimming for illumina paired-end and single ended data, Note: There is data in /usr/share/trimmomatic/ Trimmomatic performs a variety of useful trimming tasks for illumina paired-end and single ended data.The selection of trimming steps and their associated parameters are supplied on the command line.
mitohifi-code- Assemble and annotate mitochondrial genes from Pacbio HiFi data, MitoHiFi is able to assemble mitochondrial genomes from a wide phylogenetic range of taxa from Pacbio HiFi data.
funannotate-gmes-ascomycota- A pipeline for fungal genome annotation, Funannotate is a genome prediction, annotation, and comparison software package. It was originally written to annotate fungal genomes (small eukaryotes ~ 30 Mb genomes), but has evolved over time to accomodate larger genomes. This is for the Ascomycota genome.
allofplos- Maintain a repository of all PLOS XML article files, This is for downloading/updating/maintaining a repository of all PLOS XML article files.
orthofinder- Platform for comparative genomics, OrthoFinder is a fast, accurate and comprehensive platform for comparative genomics. It finds orthogroups and orthologs, infers rooted gene trees for all orthogroups and identifies all of the gene duplication events in those gene trees.
interproscan- Genome-scale protein function classification, InterPro is a database which integrates together predictive information about proteins' function from a number of partner resources, giving an overview of the families that a protein belongs to and the domains and sites it contains.
funannotate-gmes-dikarya- A pipeline for fungal genome annotation, Funannotate is a genome prediction, annotation, and comparison software package. It was originally written to annotate fungal genomes (small eukaryotes ~ 30 Mb genomes), but has evolved over time to accomodate larger genomes. This is for the Dikarya genome.
funannotate-gmes- Annotate fungal genomes, Funannotate is a genome prediction, annotation, and comparison software package. It was originally written to annotate fungal genomes (small eukaryotes ~ 30 Mb genomes), but has evolved over time to accomodate larger genomes.
funannotate-dikarya-gmes- Annotate fungal genomes, Funannotate is a genome prediction, annotation, and comparison software package. It was originally written to annotate fungal genomes (small eukaryotes ~ 30 Mb genomes), but has evolved over time to accomodate larger genomes. This is for the Dikarya genome.
funannotate-dikarya- Fungal genome annotation, Funannotate is a genome prediction, annotation, and comparison software package. It was originally written to annotate fungal genomes (small eukaryotes ~ 30 Mb genomes), but has evolved over time to accomodate larger genomes. This is for the Dikarya genome.
mitohifi-base- Assemble mitogenomes from PacBio HiFi data, MitoHiFi is able to assemble mitochondrial genomes from a wide phylogenetic range of taxa from Pacbio HiFi data.
mitohifibase- Assemble mitogenomes from Pacbio HiFi data, MitoHiFi is able to assemble mitochondrial genomes from a wide phylogenetic range of taxa from Pacbio HiFi data.
funannotate- Annotate fungal genomes, Funannotate is a genome prediction, annotation, and comparison software package. It was originally written to annotate fungal genomes (small eukaryotes ~ 30 Mb genomes), but has evolved over time to accomodate larger genomes.
pilon- An automated genome assembly improvement and variant detection tool, Pilon is a software tool which can be used to: 1) Automatically improve draft assemblies and 2) Find variation among strains, including large event detection
lr_gapcloser- Gap closing tool in long read assemblies, LR_Gapcloser is a gap closing tool using long reads from studied species.
sspace_longread- Scaffolding pre-assembled contigs using long reads, SSPACE-LongRead is a stand-alone program for scaffolding pre-assembled contigs using long reads (e.g. PacBio RS reads).
gfatools- Manipulating sequence graphs in the GFA and rGFA formats, gfatools is a set of tools for manipulating sequence graphs in the GFA or the rGFA format. It has implemented parsing, subgraph and conversion to FASTA/BED. More functionality may be added in future.
dorado- Production basecaller (MinKNOW), Dorado is a high-performance, easy-to-use, open source basecaller for Oxford Nanopore reads.
anvio- An open-source, community-driven analysis and visualization platform for microbial 'omics, Anvi’o is a comprehensive platform that brings together many aspects of today’s cutting-edge computational strategies of data-enabled microbiology, including genomics, metagenomics, metatranscriptomics, pangenomics, metapangenomics, phylogenomics, and microbial population genetics in an integrated and easy-to-use fashion through extensive interactive visualization capabilities.
cvtree- Reconstructs whole-genome based phylogenetic trees, CVTree constructs whole-genome based phylogenetic trees without sequence alignment by using a Composition Vector (CV) approach.
bedtools- suite of utilities for comparing genomic features, Collectively, the bedtools utilities are a swiss-army knife of tools for a wide-range of genomics analysis tasks.
clustalo- Making accurate alignments of many protein sequences, Clustal Omega is a new multiple sequence alignment program that uses seeded guide trees and HMM profile-profile techniques to generate alignments between three or more sequences.
muscle- Multiple alignment sequences, MUSCLE is a program for creating multiple alignments of amino acid or nucleotide sequences.
bowtie2- Tool for aligning reads to long reference sequences, Bowtie 2 is an ultrafast and memory-efficient tool for aligning sequencing reads to long reference sequences.
phylip- Infer phylogenetic trees, PHYLIP (the PHYLogeny Inference Package) is a package of programs for inferring phylogenies (evolutionary trees).
blast-static- BLAST finds regions of similarity between biological sequences.

# in docker
bcftools
spades
fastp
fastqc
sra-toolkit
bwa-mem2
minimap2
bwa
bedgraphtobigwig
ncbi-datasets
ncbi-tools-bin
samtools
primer3
jbrowse2
pear
tabix
jbrowse
takollama
biopython
repeatmasker
nanocaller
pythonnogil
dipy
allhic
jellyfish
quast
antismash
kofamscan
diamond
hifiasm
gatk
3ddna
metal
hmmer
redundans
trimmomatic
mitohifi-code
funannotate-gmes-ascomycota
allofplos
orthofinder
interproscan
funannotate-gmes-dikarya
funannotate-gmes
funannotate-dikarya-gmes
funannotate-dikarya
mitohifi-base
mitohifibase
funannotate
pilon
lr_gapcloser
sspace_longread
gfatools
dorado
anvio
cvtree
bedtools
clustalo
muscle
bowtie2
phylip
blast-static

# in tonina
bcftools
fastp
fastqc
minimap2
ncbidatasets
primer3
seqsample
spades
sra-toolkit