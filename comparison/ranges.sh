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

get_ranges() {
	for i in "$1"/*.gz; do
		chr="${i#*chr}"
		chr="${chr%%.*}"
		printf "$chr\t"
		zcat "$i" | awk 'NR==2 { printf $1 "\t" } END { print $1 }'
	done | sort -V
}

for build in b37 b38; do
	file="$build.ranges.tsv"
	printf "chr\tSHAPEIT4_INI\tSHAPEIT4_END\tEAGLE2_INI\tEAGLE2_END\n" > "$file" 
	join -j 1 -t $'\t' \
		<(get_ranges "../maps/shapeit4_${build}") \
		<(get_ranges "../maps/shapeit4_${build}_from_eagle2_${build}") \
		>> "$file"
done

