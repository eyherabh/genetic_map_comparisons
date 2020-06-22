#!/bin/bash
##
## Copyright (c) 2020 Ph.D. Hugo Gabriel Eyherabide
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

## \brief Builds tables with row counts.

set -eo pipefail

mkdir -p stats
cd stats

get_row_counts() {
	for i in "$1"/*.gz; do
		chr="${i#*chr}"
		chr="${chr%%.*}"
		printf "$chr\t"
		zcat "$i" | wc -l
	done | sort -V
}

for build in b37 b38; do
	printf "chr\tSHAPEIT4\tEAGLE2\n" > "$build.rows.tsv"
	join -j 1 -t $'\t' \
	<(get_row_counts "../maps/shapeit4_${build}") \
	<(get_row_counts "../maps/shapeit4_${build}_from_eagle2_${build}") \
	>> "$build.rows.tsv"
done

