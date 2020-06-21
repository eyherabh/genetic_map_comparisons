#!/usr/bin/mawk -f
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
 
    
function print_usage() {
	print ""
	print "NAME"
	print "\t" ENVIRON["_"] " - Converts the genetic maps distributed with Eagle2 into the format of those distributed with Shapeit4."
	print ""
	print "SYNOPSIS"
	print "\tzcat <gzip-compressed input genetic map> | " ENVIRON["_"] " [ build=[b37|b38] | par1end=<INT> par2ini=<INT> ] [out-prefix=<STR>] [out-suffix=<STR>]"
	print ""
	print "where <INT> and <STR> denote integer and string values, respectively."
	print ""
	print "OPTIONS"
	print "\tbuild      : It can be 'b37' or 'b38'"
	print "\tpar1end    : Last 1-based position within the PAR1 region. Ignored if the option 'build' is given."
	print "\tpar2ini    : First 1-based position within the PAR2 region. Ignored if the option 'build' is given."
	print "\tout-prefix : Prefix to be used for the output files. Defaults to ''."
	print "\tout-suffix : Suffix to be used for the output files. Defaults to '.gmap_from_eagle2'"
	print ""
	exit 0
}

function fail(msg) {
	print msg
	exit 1
}

function get_par_limits(build, lims) {
	if (build=="b37") {
		lims["par1end"] = 2699520
		lims["par2ini"] = 154931044
	} else if (build=="b38") {
		lims["par1end"] = 2781479
		lims["par2ini"] = 155701383
	} else {
		fail( "Unrecognized build code " build )
	}
}

function is_integer(val) {
	return val == int(val)
}

function check_par_int(parname) {
	if (!is_integer(pars[parname]))
		fail( "Parameter '" parname "' must be an integer")
}

BEGIN {
	if(ARGC==1) print_usage()

	# Parsing PAR region boundaries
	pars["build"]=""
	pars["par1end"]=""
	pars["par2ini"]=""
	pars["out-suffix"]=".gmap_from_eagle2"
	pars["out-prefix"]=""
	
	for(i=1; i<ARGC; i++) {
		if (split(ARGV[i], keyval, "=")!=2)
			fail( "Expected key-value pair in parameter " i " but found " ARGV[i] )

		if (!keyval[1] in pars)
			fail( "Unrecognized parameter " keyval[1] )

		pars[keyval[1]] = keyval[2]
	}

	if(pars["build"]) 
		get_par_limits(pars["build"], pars)
	
	# May seem redundant if "build" is set, but better check twice to make sure I didn't make a mistake
	check_par_int("par1end")
	check_par_int("par2ini")
	
	FS="[ ]"
	OFS="\t"
}


NF != 4 {
	fail("Eagle2 genetic maps are expected to contain 4 columns")
}

NR == 1 {
	fr = "chr position COMBINED_rate(cM/Mb) Genetic_Map(cM)"
	if ($0 != fr)
		fail("Unexpected first row for an Eagle2 genetic map." \
		     "Expected\n\n" fr "\n\nbut found\n\n" $0)
}

NR > 1 {
	if ($1==23) {
		if ($2<=pars["par1end"]) {
			chrnow="X_par1"
		} else if ($2<pars["par2ini"]) {
			chrnow="X"
		} else {
			chrnow="X_par2"
		}
		$1 = "X"
	} else {
		chrnow=$1
	}
	
	if (!chrfile[chrnow]) {
		chrfile[chrnow]=pars["out-prefix"] "chr" chrnow "." pars["build"] pars["out-suffix"]
		print "pos", "chr", "cM" > chrfile[chrnow]

		# The first value is not consistently zero for all chromosomes and builds.
		# Hence, performing offset correction only for chromosome X due to splitting.
		if ($1=="X")
			offset = $4
		else
			offset = 0
	}
	
	print $2, $1, $4-offset >> chrfile[chrnow]
}




