
## Set repeated commands specific to the project region
## This version is parameterised for the Norwegian Basin
implementation <- "Norwegian_Basin_MA"

library(sf)
library(tidyr)

#EPSG <- rgdal::make_EPSG()
#EPSG2 <- filter(EPSG, str_detect(note, "Cape"))
crs <- 3035                                                              # Specify the map projection for the project

lims <- c(xmin = 3318999, xmax = 4733343, ymin = 4206509, ymax = 5741137)# Specify limits of plotting window, also used to clip data grids

zoom <- coord_sf(xlim = c(lims[["xmin"]], lims[["xmax"]]), ylim = c(lims[["ymin"]], lims[["ymax"]]), expand = FALSE) # Specify the plotting window for SF maps in this region

ggsave_map <- function(filename, plot) {
  ggsave(filename, plot, scale = 1, width = 12, height = 10, units = "cm", dpi = 500)
  
}                             # Set a new default for saving maps in the correct size
pre <- list(scale = 1, width = 12, height = 10, units = "cm", dpi = 500) # The same settings if you need to pass them to a function in MiMeMo.tools

SDepth <- 60                  # Shallow deep boundary
DDepth <- 600                 # Maximum depth
ODepth <- 700

domain_size<-readRDS("./Data//Domains.rds")%>%
  st_union()%>%
  st_area()

#### bathymetry.5 MODEL DOMAIN ####

shape <- function(matrix) {
  
shape <-  matrix %>% 
  list() %>% 
  st_polygon() %>% 
  st_sfc() %>% 
  st_sf(Region = implementation, geometry = .)
  st_crs(shape) <- st_crs(4326)                                        
  shape <- st_transform(shape, crs = crs)
  return(shape)
  
}                      # Convert a matrix of lat-lons to an sf polygon

Region_mask <- matrix(c(16.23, 70,
                        20.25, 68.5,
                        10, 60,
                        6, 58.5,
                        4.5, 59,
                        4.25, 60.5,
                        2.5, 63,
                        10, 70,
                        16.23, 70),
                       ncol = 2, byrow = T) %>% 
  list() %>% 
  st_polygon() %>% 
  st_sfc() %>% 
  st_sf(Region = implementation,.)
st_crs(Region_mask) <- st_crs(4326)                                        
Region_mask <- st_transform(Region_mask, crs = crs)

## Fix straggly bit of the offshore zone

trim  <- matrix(c(8.2, 16, 16, 8.2, 8.2,    # Longitudes
                  66.95, 66, 69, 67.05, 66.95), ncol = 2, byrow = F) %>% 
  shape() %>% 
  st_transform(crs = 4326)

#### bounds.2 MAKE TRANSECTS ####

## Polygons to mark which transects are along the open ocean-inshore boundary

Inshore_ocean_boundaries  <- matrix(c(0, 5.2, 5.2, 0, 0,    # Longitudes
                                      61.95, 61.95, 62.05, 62.5, 61.95), ncol = 2, byrow = F) %>% 
  shape()

#### expand polygon for sampling rivers ####

river_expansion <- matrix(c(5, 62,
                            1, 62,
                            1, 68,
                            10, 68.4,
                            15, 68,
                            5, 62),
                          ncol = 2, byrow = T) %>% 
  list() %>% 
  st_polygon() %>% 
  st_sfc() %>% 
  st_sf(Region = implementation,.)
st_crs(river_expansion) <- st_crs(4326)                                          
river_expansion <- st_transform(river_expansion, crs = 3035)


