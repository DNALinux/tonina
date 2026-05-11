---
name: primer3
description: "Uses primer3 docker to calculate primers."
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

# Primer3 Skill


Primer3 is the industry-standard software tool for designing PCR primers.

## Primer3 Usage

Operating Primer3 involves two main steps: configuring an input file with the necessary DNA sequence and parameters, then executing the software against that file.

The input file is a text file (Boulder-IO record), this is an example:

```text
SEQUENCE_ID=example
SEQUENCE_TEMPLATE=GTAGTCAGTAGACNATGACNACTGACGATGCAGACNACACACACACACACAGCACACAGGTATTAGTGGGCCATTCGATCCCGACCCAAATCGATAGCTACGATGACG
SEQUENCE_TARGET=37,21
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=1
PRIMER_PICK_INTERNAL_OLIGO=1
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=18
PRIMER_MIN_SIZE=15
PRIMER_MAX_SIZE=21
PRIMER_MAX_NS_ACCEPTED=1
PRIMER_PRODUCT_SIZE_RANGE=75-100
P3_FILE_FLAG=1
SEQUENCE_INTERNAL_EXCLUDED_REGION=37,21
PRIMER_EXPLAIN_FLAG=1
=
```

This is the way to run primer3:

Provided the input file is named `inputfile` the command is:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/primer3:2.6.1 /bin/bash -c "cd /ftmp/ && primer3_core < /ftmp/inputfile"
```

If the user provides this sequece:

```text
GTAGTTTCCCGCCCTTGGGGGCGCGGGGACAAATTCCTTGACCCGAGGAGGATAGGGATGTGGCCTTCGG
TCTTTCCTCGCAGCTCCGGGGCAAGCTAGGAGTGGGATGGAAGTCGAGGTCCCTAATTTTTTAAGGGGAG
GGTGCGGGGAGAAGGGGTAGTATGCGGAAACAGAGCGGGTATGAAGCTGGCTAACGCCGCGCGCCCCCTC
CCAGGACCCGCTCCTGCCCCGCGCCGGCCGGTCCTGGGGGCCCGCTTTTTTATGGAAATGAGGAGGGGGG
GCCGGGGCCGGGGGCGGGGAGCCGGGAGCCGTCCCCGCTCGCTCACTGCGGCTTTCTCTCTCGCTCCCCT
CTCCCCGCTCCCTGCCGCGCTCACTCTCCGCTTCCCCCTCCCGCTCTCCCAGAGTCGATCCCGGAGCCCG
GCCGCGGGGAGAGGTTCTCGGCAGAGAAGACAAAGCCCGCAGCAGCGATGGGGGGAGAGCTGGGCTCTGC
GTGTTGTGGGGGCCAGGAAAGGGTGCCAGGCTGGGGCTGGAACCCCCTGGCAAAGGATGGGGTCCCCTCA
TCCCTAAACAGCAAGCCATCTCCCCTCGCCCGCCCCCCGCCCCCCCAGTCTCGGAGATCTCAGAGGCACC
GACTGGGAGGTGAGTTAGTTCACGTCCTTCTGCTCGGTGGAGGGGGTCGGGAGGGCGGTGGAGTGATGAA
GTGCAGAGGTTGAAGGAGTGCAGGGACAGAACTGGGGGTCGGACGGAGAGTGGGCAGGCAGGAAAAGTCT
```

And a optimal primer size between 18 and 22 with an optimal primer size of 20, with a requested product size from 300 to 400, and the target sequence starts at 120 and has a length of 300. Always use `PRIMER_EXPLAIN_FLAG=1` and `P3_FILE_FLAG=1`. You should contruct this input file and save it as `inputfile`:

```text
SEQUENCE_ID=example
SEQUENCE_TEMPLATE=GTAGTTTCCCGCCCTTGGGGGCGCGGGGACAAATTCCTTGACCCGAGGAGGATAGGGATGTGGCCTTCGGTCTTTCCTCGCAGCTCCGGGGCAAGCTAGGAGTGGGATGGAAGTCGAGGTCCCTAATTTTTTAAGGGGAGGGTGCGGGGAGAAGGGGTAGTATGCGGAAACAGAGCGGGTATGAAGCTGGCTAACGCCGCGCGCCCCCTCCCAGGACCCGCTCCTGCCCCGCGCCGGCCGGTCCTGGGGGCCCGCTTTTTTATGGAAATGAGGAGGGGGGGCCGGGGCCGGGGGCGGGGAGCCGGGAGCCGTCCCCGCTCGCTCACTGCGGCTTTCTCTCTCGCTCCCCTCTCCCCGCTCCCTGCCGCGCTCACTCTCCGCTTCCCCCTCCCGCTCTCCCAGAGTCGATCCCGGAGCCCGGCCGCGGGGAGAGGTTCTCGGCAGAGAAGACAAAGCCCGCAGCAGCGATGGGGGGAGAGCTGGGCTCTGCGTGTTGTGGGGGCCAGGAAAGGGTGCCAGGCTGGGGCTGGAACCCCCTGGCAAAGGATGGGGTCCCCTCATCCCTAAACAGCAAGCCATCTCCCCTCGCCCGCCCCCCGCCCCCCCAGTCTCGGAGATCTCAGAGGCACCGACTGGGAGGTGAGTTAGTTCACGTCCTTCTGCTCGGTGGAGGGGGTCGGGAGGGCGGTGGAGTGATGAAGTGCAGAGGTTGAAGGAGTGCAGGGACAGAACTGGGGGTCGGACGGAGAGTGGGCAGGCAGGAAAAGTCT
PRIMER_TASK=generic
SEQUENCE_TARGET=120,300
PRIMER_PICK_LEFT_PRIMER=1
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=20
PRIMER_MIN_SIZE=18
PRIMER_MAX_SIZE=22
PRIMER_MAX_NS_ACCEPTED=1
P3_FILE_FLAG=1
PRIMER_PRODUCT_SIZE_RANGE=300-400
PRIMER_EXPLAIN_FLAG=1
=
```

Then run primer3 using Docker calling this file:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/primer3:2.6.1 /bin/bash -c "cd /ftmp/ && primer3_core < /ftmp/inputfile"
```

If using `example` in the `SEQUENCE_ID` file, you should have files like this:

```text
example.for
example.rev
```

NOTE: The `PRIMER_PRODUCT_SIZE_RANGE` is the range of the product size in base pairs, the minimum value is at least the length of the target sequence. For example if the target sequence is 300 base pairs long, the minimum value of `PRIMER_PRODUCT_SIZE_RANGE` is 300. If the user enters a value lower than the length of the target sequence, you should ask the user to enter a value higher than the length of the target sequence. For example if `SEQUENCE_TARGET=120,300`, this means the target sequence starts at 120 and has a length of 300, so the minimum value of `PRIMER_PRODUCT_SIZE_RANGE` is 300. If the user enters a value lower than 300, you should ask the user to enter a value higher than 300 in this case.

## Internal primer

If the user request an internal primer, you should set `PRIMER_PICK_INTERNAL_OLIGO=1` in the input file.
In this case, there will be a file called `example.int` as output.


## OUTPUT TAGS

For each Boulder-IO record passed into Primer3 via stdin, exactly one Boulder-IO record comes out of Primer3 on stdout. If a settings file is provided and the option to echo the settings file is given on the command line, then the contents of the settings file will also be part of the output. Two additional tags are used to indicate where the records of the settings file begin and end: P3_SETTINGS_FILE_USED specifies the path to the settings file that was provided, P3_SETTINGS_FILE_END does not have any value and it just indicates the end of the settings records.

The output records contain everything that the input record contains, plus a subset of the following tag/value pairs. Unless noted by (*), each tag appears for each primer pair returned.

Tags are of the form PRIMER_{LEFT,RIGHT,INTERNAL,PAIR}_<j>_<tag_name> where <j> is an integer from 0 to n, where n is at most the value of PRIMER_NUM_RETURN. In the documentation the output number 4 is shown as for example: PRIMER_LEFT_4_TM.

In the descriptions below, 'i,n' represents a start/length pair, 's' represents a string, x represents an arbitrary integer, and f represents a float.

PRIMER_ERROR=s (*)

s describes user-correctable errors detected in the input (separated by semicolons). This tag is absent if there are no errors.

PRIMER_WARNING=s (*)

s lists warnings generated by Primer3` (separated by semicolons); this tag is absent if there are no warnings.

PRIMER_LEFT_NUM_RETURNED=i
PRIMER_RIGHT_NUM_RETURNED=i
PRIMER_INTERNAL_NUM_RETURNED=i
PRIMER_PAIR_NUM_RETURNED=i

i is the number of primers or primer pairs returned on standard output. These tags are always generated under IO version 4 if there are no internal errors and if PRIMER_ERROR is not present.

If primer pairs were requested, PRIMER_LEFT_NUM_RETURNED and PRIMER_RIGHT_NUM_RETURNED will be equal to the number of pairs returned, even if the actual number of distinct left or right primers was lower than the number of pairs. If primer pairs with internal oligos were requested, PRIMER_INTERNAL_NUM_RETURNED will also be set to the number of pairs returned.

If only left or right primers or hybridization (internal) oligos were requested, PRIMER_PAIR_NUM_RETURNED will be 0 and only the relevant tag will have a non-zero value. For example, if only left primers were requested, PRIMER_RIGHT_NUM_RETURNED, PRIMER_INTERNAL_NUM_RETURNED and PRIMER_PAIR_NUM_RETURNED will be 0.

Some tasks, such as pick_sequencing_primers or pick_primer_list, return left and right primers that are not parts of primer pairs. In this case PRIMER_PAIR_NUM_RETURNED will be 0.

## How to show the output

The output of Primer3 is a Boulder-IO record that goes into the `stdout`.
Consider reporting the data from these fields:

PRIMER_LEFT_0_SEQUENCE=AGGAGTGGGATGGAAGTCGA
PRIMER_RIGHT_0_SEQUENCE=GGCTTTGTCTTCTCTGCCGA
PRIMER_LEFT_0=97,20
PRIMER_RIGHT_0=456,20
PRIMER_LEFT_0_TM=59.959
PRIMER_RIGHT_0_TM=60.321
PRIMER_LEFT_0_GC_PERCENT=55.000
PRIMER_RIGHT_0_GC_PERCENT=55.000
PRIMER_LEFT_EXPLAIN=considered 505, GC content failed 29, low tm 61, high tm 181, high hairpin stability 16, ok 218
PRIMER_RIGHT_EXPLAIN=considered 1577, GC content failed 124, low tm 179, high tm 674, high hairpin stability 91, long poly-x seq 23, ok 486
PRIMER_PAIR_EXPLAIN=considered 2023, unacceptable product size 2016, ok 7

Into a report like:

```text
Primer3 Results Summary

Selected Primer Pair (Pair 0)

Forward Primer (Left 0)

Sequence (5' → 3'): AGGAGTGGGATGGAAGTCGA
Position: 97
Length: 20 bp
Melting Temperature (Tm): 59.959 °C
GC Content: 55.0%

Reverse Primer (Right 0)

Sequence (5' → 3'): GGCTTTGTCTTCTCTGCCGA
Position: 456
Length: 20 bp
Melting Temperature (Tm): 60.321 °C
GC Content: 55.0%

Primer Screening Summary

Left Primer Candidates

Total considered: 505
Rejected – GC content: 29
Rejected – Low Tm: 61
Rejected – High Tm: 181
Rejected – High hairpin stability: 16
Accepted (OK): 218

Right Primer Candidates

Total considered: 1577
Rejected – GC content: 124
Rejected – Low Tm: 179
Rejected – High Tm: 674
Rejected – High hairpin stability: 91
Rejected – Long poly-X sequence: 23
Accepted (OK): 486

Primer Pair Evaluation

Total pairs considered: 2023
Rejected – Unacceptable product size: 2016
Accepted (OK): 7
```
# To cite

If the user asks for a citation, provide the following:

Untergasser A, Cutcutache I, Koressaar T, Ye J, Faircloth BC, Remm M, Rozen SG. Primer3--new capabilities and interfaces. Nucleic Acids Res. 2012 Aug;40(15):e115. doi: 10.1093/nar/gks596. Epub 2012 Jun 22. PMID: 22730293; PMCID: PMC3424584.
