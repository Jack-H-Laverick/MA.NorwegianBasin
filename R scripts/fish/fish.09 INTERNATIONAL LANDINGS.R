
## Combine EU and Norwegian landings, then inflate by missing Russian landings to get International landings

#### Set up ####

rm(list=ls())                                                               # Wipe the brain

packages <- c("tidyverse")                                                  # List packages
lapply(packages, library, character.only = TRUE)                            # Load packages

domain_size <- readRDS("./Objects/Domains.rds") %>%                         # We need landings as tonnes per m^2
  sf::st_union() %>% 
  sf::st_area() %>% 
  as.numeric()

eez_size <- 2.385178e+12 #Norwegian fishing zone


  
Guilds <- unique(read.csv("./Data/MiMeMo fish guilds.csv",check.names = FALSE)$Guild)           # Get vector of guilds

Inflation <- readRDS("./Objects/ICES landings inflation.rds") %>%           # Rule to convert non-russian to international landings from ICES
  right_join(data.frame(Guild = Guilds)) %>%                                # Introduce missing guilds
  replace_na(replace = list(Inflation = 1)) %>%                             # Any unrepresented guild shouldn't be inflated
  arrange(Guild)                                                            # Alphabetise to match matrices later

IMR <- readRDS("./Objects/IMR landings by gear and guild.rds") # Import corrected IMR landings

EU <- readRDS("./Objects/EU landings by gear and guild.rds")

Iceland <- readRDS("./Objects/Iceland landings by gear and guild.rds")
Faroe<- readRDS("./Objects/Faroe landings by gear and guild.rds")

Dredge <-readRDS("./Objects/Mollusc dredge landings.rds") #add mollusc dredge landings unavailablein IM or EU data

Nor_algae<-readRDS("./Objects/fiskeridirektoratet landings by gear and guild.rds")

Norway<-t(IMR+Dredge+Nor_algae)/domain_size


# Import corrected EU landings
  
#### Combine EU and IMR landings then inflate to international ####

Alien <- t(((EU + IMR) *                                            # Sum EU and IMR + kelp + Dredge landings
                     Inflation$Inflation)+Nor_algae+Dredge)/                                 # then inflate by Russian activity,
                     domain_size +  t(Faroe+Iceland)/eez_size-Norway                                        # add Faroe and Iceland and convert to per m^2

#Add International and Norwegian guilds for Norway
rownames(Norway) <- ifelse(
  rownames(Norway) == "Pelagic_Trawlers", "Pelagic_Trawlers_NORW",
  ifelse(rownames(Norway) == "Pelagic_Seiners", "Pelagic_Seiners_NORW", rownames(Norway))
)
empty_matrix<-matrix(rep(0,24), nrow = 2, byrow = TRUE)
Norway<-rbind(Norway,empty_matrix)

rownames(Norway)[(nrow(Norway) - 1):nrow(Norway)] <- c("Pelagic_Trawlers_ALIEN","Pelagic_Seiners_ALIEN")
Norway<-Norway[order(rownames(Norway)),]

#Add International and Norwegian guilds for International

rownames(Alien) <- ifelse(
  rownames(Alien) == "Pelagic_Trawlers", "Pelagic_Trawlers_ALIEN",
  ifelse(rownames(Alien) == "Pelagic_Seiners", "Pelagic_Seiners_ALIEN", rownames(Alien))
)
empty_matrix<-matrix(rep(0,24), nrow = 2, byrow = TRUE)
Alien<-rbind(Alien,empty_matrix)

rownames(Alien)[(nrow(Alien) - 1):nrow(Alien)] <- c("Pelagic_Trawlers_NORW","Pelagic_Seiners_NORW")
Alien<-Alien[order(rownames(Alien)),]

International <- Norway+Alien

International["Shelf_Trawlers_Seiners", "Macrophyte"] <- 0                                  # There's one tiny bit of seaweed we think should be removed.
International["Recreational", "Demersal (quota limited)"] <- 18493 / domain_size # Add recreational fishing activity.
International["Recreational", "Migratory"] <- 69.42 / domain_size              # Add recreational fishing activity.

heatmap(International)
saveRDS(International, "./Objects/International landings.rds")
write.csv(International,"./Target/TARGET_raw_landings_t_m2_y_NORWEGIAN_SEA_2011-2019.csv")
#International<-readRDS( "./Objects/International landings.rds")
