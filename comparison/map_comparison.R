#!/usr/bin/env Rscript
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

## \brief Validates genetic maps, compare distances and produces plots.

options(warn=1)
library("ggplot2")
library("data.table")
library("magrittr")

figpath <- "figures"

argv <- commandArgs()
argc <- length(argv)
argi <- match("--args", argv)

## If the session is interactive, the build is read from the command line
if(!interactive()) {
    argv <- commandArgs()
    argc <- length(argv)
    argi <- match("--args", argv) + 1
    if(argc<argi || !grep("^build=", argv[argi]))
        stop("Missing 'build=<build code>'")
    
    build <- sub("^build=(.*)", "\\1", argv[argi])
} else {
    build <- "b37"
}
    

path_maps_from_shapeit <- paste0("maps/shapeit4_", build)
path_maps_from_eagle   <- paste0(path_maps_from_shapeit, "_from_eagle2_", build)

readmap <- function(...) fread(cmd=paste0(...),
                               header=TRUE,
                               sep="\t",
                               stringsAsFactors=FALSE)

## Checks if a vector is monotonically non-decreasing.
is_mono_inc <- function(vec) all(diff(vec)>=0)

# Computes properties for a shapeit4 formatted genetic mapcm
## The results below depend on the map having monotonically non-decreasing positions and distances.
## That is the expected format for the map, hence no need to perform further sorting.
get_map_props <- function(dt) {
    list(
        is_pos_sorted=is_mono_inc(dt$pos),
        is_mono_inc=is_mono_inc(dt$cM),
        posini=first(dt)$pos,
        posend=last(dt)$pos
    )
}

## Convenience function, mostly for making sure I recall how to get the unevaluated dot-dot-dot values passed to a function.
get_props_for_maps <- function(...) {
    ## Captures the variables unevaluated and convert their names to strings
    mapnames <- eval(substitute(alist(...))) %>% Map(deparse, .)

    Map(get_map_props, list(...)) %>%
        setattr("names", mapnames) %>%
        rbindlist(idcol="map")
}

get_nice_lims <- function(ini, end) {
    alim <- c(ini, end)
    aint <- diff(alim)/5
    aint <- ceil_signif(aint, 10^round(log10(aint)))
    alim[1] <- floor_signif(alim[1], 10^floor(log10(aint)))
    alim[2] <- ceil_signif(alim[2], 10^floor(log10(aint)))
    aint <- diff(alim)/5
    aint <- ceil_signif(aint, 10^round(log10(aint)))
    return(c(alim, aint))
}

ceil_signif <- function(x, d) {
    ceiling(x/d)*d
}

floor_signif <- function(x, d) {
    floor(x/d)*d
}

compare_map <- function(chr) {
    warning("Processing chromosome ", chr)
    maps <- readmap("zcat ", path_maps_from_shapeit, "/chr", chr, ".", build, ".gmap.gz")
    mape <- readmap("zcat ", path_maps_from_eagle, "/chr", chr, ".", build, ".gmap_from_eagle2.gz")

    mapprops <- get_props_for_maps(maps, mape)

    for(x in mapprops$map) {
        if(!mapprops[map==x, is_pos_sorted]) warning("Positions for ", x, " are not sorted")
        if(!mapprops[map==x, is_mono_inc]) warning("Distances for ", x, " are not monotonically increasing")
    }
    
    if(diff(mapprops$posini)) {
        warning("Initial pos mismatch for chr", chr)
        posinimm <- TRUE
    }
    
    if(diff(mapprops$posend)) {
        warning("Last pos mismatch for chr", chr)
        posendmm <- TRUE
    }

    
    ## Using hyman interpolation because the curves are monotonically increasing.
    len <- 100001
    ## Workaround to simplify code and avoid issues when the beginning does not coincide.
    if(!chr %in% c("X", "X_par2")) { 
        mapsi <- as.data.table(spline(c(0, maps$pos), c(0, maps$cM), n=len, method="hyman"))
        mapei <- as.data.table(spline(c(0, mape$pos), c(0, mape$cM), n=len, method="hyman"))
    } else {
        ## Not using the work around for Non-PAR and PAR2 region. I
        ## could have set their initial position with 0cM, but that's
        ## unnecessary by their construction.
        mapsi <- as.data.table(spline(maps$pos, maps$cM, n=len, method="hyman"))
        mapei <- as.data.table(spline(mape$pos, mape$cM, n=len, method="hyman"))
    }
    

    ## Preparing data table for plotting genetic maps, subsampling and scaling positions to Mbp.
    mapse <- mapsi[seq(1, len, 10)][, x:=x/1E6][, setnames(.SD, c("pos", "SHAPEIT4"))]
    mapse[, EAGLE2:=mapei[seq(1, len, 10), y]]
    mapse <- melt(mapse, id.vars="pos", measure.vars=c("SHAPEIT4", "EAGLE2"), variable.name="map", value.name="cM")


    ## Computing nice limits and intervals for shortening tick labels.
    xlim <- get_nice_lims(min(mapse$pos), max(mapse$pos))
    ylim <- get_nice_lims(min(mapse$cM), max(mapse$cM))

    ggplot(data = mapse, aes(x=pos, y=cM)) +
        geom_line(aes(color=map)) +
        scale_colour_manual(values=c("red", "blue")) +
        ggtitle(paste0("Comparison of genetic maps for chromosome ", chr, "\ndistributed with SHAPEIT4 and EAGLE2 for build ", build)) +
        xlab("Position (Mbp)") +
        ylab("Genetic distance (cM)") +
        scale_x_continuous(limits=xlim[1:2], breaks=seq(xlim[1], xlim[2], xlim[3]), expand=c(0,0)) +
        scale_y_continuous(limits=ylim[1:2], breaks=seq(ylim[1], ylim[2], ylim[3]), expand=c(0,0)) +
        theme(plot.title = element_text(hjust = 0.5),
              panel.background = element_blank(),
              plot.margin = margin(1,1,1,1, "cm"),
              legend.title = element_blank(),
              axis.line = element_line(),
              legend.position = c(0.1, 0.9))
    
    ggsave(paste0(figpath, "/chr", chr, ".", build, ".genetic_map_shaprit4_vs_eagle2.png"))

    ## Preparing data with difference between genetic maps.
    mapdiff <- dcast(mapse, pos ~ map, value.var="cM")[, diff:=SHAPEIT4-EAGLE2][, c("SHAPEIT4", "EAGLE2"):=NULL]
    
    ylim <- get_nice_lims(min(mapdiff$diff), max(mapdiff$diff))
    
    ggplot(data = mapdiff, aes(x=pos, y=diff, color="green")) +
        geom_line() +
        ggtitle(paste0("Difference for chromosome ", chr, "\nof the genetic distances distributed with SHAPEIT4 and EAGLE2 for build ", build)) +
        xlab("Position (Mbp)") +
        ylab("Genetic distance difference\nSHAPEIT4 - EAGLE2 (cM)") +
        scale_x_continuous(limits=xlim[1:2], breaks=seq(xlim[1], xlim[2], xlim[3]), expand=c(0,0)) +
        scale_y_continuous(limits=ylim[1:2], breaks=seq(ylim[1], ylim[2], ylim[3]), expand=c(0,0)) +
        theme(plot.title = element_text(hjust = 0.5),
              panel.background = element_blank(),
              plot.margin = margin(1,1,1,1, "cm"),
              axis.line = element_line())

    ggsave(paste0(figpath, "/chr", chr, ".", build, ".genetic_map_difference_shaprit4_vs_eagle2.png"), width=16, height=8, units="cm")

    return(mapdiff)
}


mapdiffs <- Map(compare_map, c(1:22, "X_par1", "X", "X_par2"))

tabdiffs <- rbindlist(mapdiffs, idcol="chr")

ggplot(data = tabdiffs, aes(x=chr, y=diff, color=chr)) +
    geom_boxplot(outlier.colour="black", outlier.shape=16, outlier.size=2, notch=TRUE) +
    coord_flip() +
    ggtitle(paste0("Distribution of genetic-distance differences per chromosome\nbetween SHAPEIT4 and  EAGLE2 genetic maps for build ", build)) +
    xlab("Chromosome") +
    ylab("Genetic distance difference (cM)") +
    scale_x_discrete(limits=c(1:22, "X_par1", "X", "X_par2")) +
    theme(plot.title = element_text(hjust = 0.5),
          panel.background = element_blank(),
          plot.margin = margin(1,1,1,1, "cm"),
          axis.line = element_line(),
          legend.position = "none")

ggsave(paste0(figpath, "/All.", build, ".genetic_map_difference_shaprit4_vs_eagle2.png"))
