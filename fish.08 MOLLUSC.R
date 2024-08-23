rm(list=ls())                                                                 # Wipe the brain
packages <- c("tidyverse", "sf", "raster")                   # List packages
lapply(packages, library, character.only = TRUE)  