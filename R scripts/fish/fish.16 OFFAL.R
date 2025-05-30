library(dplyr)
library(data.table)
library(future)
library(furrr)
library(tidyverse)
library(progressr)

Files <- list.files(path = "./Data/Fiskeridirektoratet/Open_data",
                    pattern = "*.csv",
                    full.names = T) # Get a list of files to import

plan(multisession)

handlers("progress")


gear <- read.csv("./Data/MiMeMo_gears.csv", check.names = FALSE)                                    # Import gear names

guild <- read.csv("./Data/MiMeMo fish guilds.csv", check.names = F) %>%                        # Import guild names
  dplyr::select(Guild, FAO) %>%
  drop_na() %>%
  distinct() %>%
  group_by(FAO) %>%
  slice_head() %>%
  ungroup()

landings_target <- expand.grid(Guild = unique(read.csv("./Data/MiMeMo fish guilds.csv")$Guild), # reintroduces guilds not in FAO 
                               Aggregated_gear = unique(gear$Aggregated_gear))

options(future.globals.maxSize = 2 * 1024 ^ 3)
with_progress({
  p <- progressor(along = Files)
  Offals <- future_map(Files, ~ {
    p()
    # For each csv
    fread(.x, , sep = ";", dec = ",") %>%
      select(
        `Redskap (kode)`,
        `Art FAO (kode)`,
        `Rundvekt`,
        `Produktvekt`,
        `Lon (lokasjon)`,
        `Lat (lokasjon)`
      ) %>%
      filter(`Rundvekt` != 0) %>%
      mutate(
        Offal = (`Rundvekt` - `Produktvekt`) / `Rundvekt`,                      # We calculate the offal by substracting the round weight by the final product weight 
                                                                                #and dividing by the round weight again for the percentage
        Gear_code = `Redskap (kode)`,
        FAO = `Art FAO (kode)`
      ) %>%
      filter(between(`Lat (lokasjon)`, 62, 75),                                 # Keep fishing location in the Norwegian Sea
             between(`Lon (lokasjon)`, -7, 16)) %>%
      select(Offal, Gear_code, FAO) %>%
      as.data.frame()                                                           # Convert to data frame to play nicely with rasters
  })%>%
    data.table::rbindlist() %>%                                                 # Create one big data frame
    mutate(Gear_code = as.character(Gear_code)) %>%
    left_join(gear) %>%                                                         # Attach gear labels
    left_join(guild) %>%                                                        # Attach guild labels
    filter(Aggregated_gear != "Dropped") %>%                                    # Remove dropped gear
    select(Aggregated_gear, Guild, Offal) %>%
    group_by(Aggregated_gear, Guild) %>%
    filter(is.na(Aggregated_gear) == FALSE, is.na(Guild) == FALSE) %>%          # Remove missing data
    summarise(Offal = mean(Offal, na.rm = TRUE)) %>%                            # Mean the offal percentage for each gear and guild
    ungroup() %>%
    right_join(landings_target)%>%
    pivot_wider(names_from =Guild , values_from = Offal) %>%                    # Spread dataframe to look like a matrix
    column_to_rownames('Aggregated_gear') %>%                                   # Remove character column
    as.matrix() %>%                                                             # Convert to matrix
    .[order(row.names(.)), order(colnames(.))]
})


Offals[is.na(Offals)] <- 0

#We consider the same rates of offal for all countries considering the lack of data

rows_to_copy <- Offals[rownames(Offals) %in% c("Pelagic_Seiners", "Pelagic_Trawlers"), , drop = FALSE]
rownames(rows_to_copy) <- c("Pelagic_Seiners_NORW", "Pelagic_Trawlers_NORW")
Offals <- rbind(Offals, rows_to_copy)
rownames(Offals)[rownames(Offals) == "Pelagic_Seiners"] <- "Pelagic_Seiners_ALIEN"
rownames(Offals)[rownames(Offals) == "Pelagic_Trawlers"] <- "Pelagic_Trawlers_ALIEN"

Offals <- Offals[order(rownames(Offals)), , drop = FALSE]

saveRDS(Offals, "./Target/offals.rds")



