# Comparison of the genetic maps distributed with SHAPEIT4 and EAGLE2

Ph.D. Hugo Gabriel Eyherabide

22 June 2020

## Introduction

Phasing and imputation require the use of genetic recombination maps, typically distributed with phasing and imputation tools. Recently, [SHAPEIT4](https://github.com/odelaneau/shapeit4) and [IMPUTE5](https://jmarchini.org/impute5/) have been released with genetic maps that, as I here show, differ from those used by [SHAPEIT2](https://mathgen.stats.ox.ac.uk/genetics_software/shapeit/shapeit.html), [IMPUTE2](https://mathgen.stats.ox.ac.uk/impute/impute_v2.html) and [EAGLE2](https://data.broadinstitute.org/alkesgroup/Eagle/https://data.broadinstitute.org/alkesgroup/Eagle/). This article explores these differences to shed light on potential compatibility and comparability issues.


## Position ranges and sampling density

The initial positions coincide for most genetic maps except for chromosomes 4, 7, 11, 13 and 16 in both b37 and b38, and for chromosome 22 in b38. In all cases, the maps of SHAPEIT4 start earlier than those of EAGLE2. The last positions never differ (see [stats/b37.ranges.txt](stats/b37.ranges.txt) and [stats/b38.ranges.txt](stats/b38.ranges.txt)). 

The number of samples is larger in the maps of SHAPEIT 4 for all chromosomes except for chromosome X_par1 and X (see [stats/b37.rows.txt](stats/b37.rows.txt) and [stats/b38.rows.txt](stats/b38.rows.txt)).



<!-- # References -->

<!-- + Original article: [https://adamdrake.com/command-line-tools-can-be-235x-faster-than-your-hadoop-cluster.html] -->
<!-- + Bash reference manual: [https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html] -->
<!-- + MAWK website: [https://invisible-island.net/mawk/mawk.html#related_mawk] -->
<!-- + MAWK pitfalls: [https://brenocon.com/blog/2009/09/dont-mawk-awk-the-fastest-and-most-elegant-big-data-munging-language/] -->
<!-- + AWK user guide: [https://www.gnu.org/software/gawk/manual/gawk.html] -->
<!-- + PGN format: [https://en.wikipedia.org/wiki/Portable_Game_Notation] -->
<!-- + PGN standard: [http://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm] -->
<!-- + Chess-game data repository: [https://github.com/rozim/ChessData] -->
<!-- + Useless use of cat award: [http://porkmail.org/era/unix/award.html] -->
