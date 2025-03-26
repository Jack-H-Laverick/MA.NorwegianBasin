
## Add estimates of harvest ratios 

library(tidyverse)
source("./R scripts/@_Region file.R")

#### reformat data ####

## Import Tanguy's object
Harvest_ratios <- readRDS("I:/Science/MS/users/academics/Laverick_Jack/i-Documents/M-atlantic/Norwegian Basin/Data/Fishing_objects_01_25_TG/Data/Norwegian_sea_Tanguy2/Norwegian_sea/2010-2019/Object/Harvest_ratios2.rds") %>% 
  .[-c(5,6,12)]


Harvest_ratios["Macrophyte"] <- 0                                               # Overwrite NA

names(Harvest_ratios) <- c("Benthos_carn-scav",                                 # Changes names to match target file
                           "Benthos_susp-dep",
                           "Birds",
                           "Cetaceans",
                           "Macrophytes",
                           "Migratory_fish",
                           "Pinnipeds",
                           "Planktivorous_fish",
                           "Zooplankton_carn",
                           "Demersal_fish"
                           )

Harvest_ratios <- Harvest_ratios[c("Planktivorous_fish",                        # Change order to match target file
                                   "Demersal_fish",
                                   "Migratory_fish",
                                   "Benthos_susp-dep",
                                   "Benthos_carn-scav",
                                   "Zooplankton_carn",
                                   "Birds",
                                   "Pinnipeds",
                                   "Cetaceans",
                                   "Macrophytes")]

#### Save out ####

target <- read.csv("./StrathE2E/Norwegian_Basin_MA/2010-2019/Target/region_harvest_r_NOW_SEA_2010-2019.csv") %>% 
  mutate(Regional_harvest_ratio = as.numeric(Harvest_ratios),
         Comments = "Assembled by Tanguy")


write.csv(target, str_glue("./StrathE2E/Norwegian_Basin_MA/2010-2019/Target/region_harvest_r_{toupper(implementation)}_2010-2019.csv"), 
          row.names = FALSE)
