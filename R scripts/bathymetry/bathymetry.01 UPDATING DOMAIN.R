
# Create a coarse basin-wide domain from the domains of the Norwegian shelf model.

#### Set up ####

packages <- c("tidyverse", "sf", "stars")                                   # List handy data packages
lapply(packages, library, character.only = TRUE)                            # Load packages
source("./R scripts/@_Region file.R")                                       # Define project region 

domains <- readRDS("./Data/Shelf domain.rds")

polygons <- read_sf("./Data/Norway management areas/") 

#### Crop Norwegian sea management area ####

Basin_mask <- matrix(c(-7, 71,
                       20, 75,
                       20, 60,
                       -7, 60,
                       -7, 71),
                     ncol = 2, byrow = T) %>% 
  shape() %>% 
  st_transform(4326)

sf_use_s2(FALSE)
basin <- st_intersection(st_transform(polygons, crs = 4326) %>% filter(navn_en == "The Norwegian Sea"), Basin_mask)
sf_use_s2(TRUE)                         

plot(basin)

#### Plot ####

# GEBCO <- read_stars("../Shared data/GEBCO_2020.nc", proxy = TRUE)
# st_crs(GEBCO) <- 4326
# 
# GEBCO <- GEBCO[st_transform(st_buffer(st_union(polygons), 50000), 4326)] %>%
#   st_as_stars(downsample = 6)
# 
# land <- units::set_units(0, "m")
# 
# GEBCO[[1]][GEBCO[[1]] >= land] <- NA
# 
# ggplot() +
#   geom_stars(data = GEBCO) +
#   viridis::scale_fill_viridis(name = "Elevation", option = "turbo", na.value = NA) +
#   geom_sf(data = domains %>% st_transform(4326), fill = "grey", colour = "grey") +
#   geom_sf(data = st_transform(polygons, crs = 4326) %>% filter(navn_en == "The Norwegian Sea"), 
#           colour = "black", fill = NA) +
#   theme_minimal() +
#   geom_sf(data = basin, colour = "black", fill = NA) +
#   labs(x =  "Longitude (E)", y = "Latitude (N)", 
#        caption = "Proposed Norwegian Sea divide into North (discarded) 
#        and South (modelled) in black. Current shelf model in grey") +
#   NULL
# 
# ggsave("./Figures/bathymetry/Norwegian Basin.png")

#### Build domains object ####


Inshore <- st_union(domains) %>% 
  st_sf(Region = "Norwegian Basin", Shore = "Inshore", geometry = .) %>% 
  st_transform(crs)

basin <- st_difference(basin %>% st_transform(crs), Inshore) %>%
  transmute(Region = "Norwegian Basin", Shore = "Offshore") %>% 
  st_difference(st_transform(trim, crs = crs)) %>%  
  select(-Region.1) %>% 
  rbind(Inshore) %>% 
  mutate(Elevation = exactextractr::exact_extract(raster::raster("../Shared data/GEBCO_2020.nc"), ., fun = "mean"),
         area = as.numeric(st_area(.)))                                 # Measure the size of each cell

plot(basin)
plot(filter(basin, Shore == "Offshore"))

saveRDS(basin, "./Objects/Domains.rds")
