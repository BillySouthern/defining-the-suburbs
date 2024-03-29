#1/22, initiated by BS
#Goal:  To isolate suburban tracts and highlight whether they were developed in the pre/post-CR era

#Post-Civil Rights suburbs (Pfeiffer, 2016)

#Libraries
library(tigris)
library(tidycensus)
library(tidyverse)
library(sf)

options(tigris_use_cache = TRUE)

#Select the state, scale/geography, year, CBSA, and central city
#(We include bordering states as many CBSAs cross boundaries)
ST = c("PA", "OH", "WV", "NC", "SC", "OR", "WA")
GEOG = "tract"
YR = 2011

CBSA = c("Pittsburgh|Portland-Vancouver|Charlotte-Gastonia|Charlotte-Concord")
CENTRAL_CITY = c("Pittsburgh city|Portland city|Charlotte city")


#2011

#Download housing data
#Table B25034 - Year Structure Built
#Filter Pre- and Post-CR housing
#Rename raw variables with codebook labels
HousingData_2011 <- get_acs(year = YR,
                geography = GEOG,
                state = ST,
                table = "B25034",
                summary_var = "B25034_001",
                geometry = TRUE) %>%
  mutate(Era = case_when(
    variable == "B25034_001" ~ "Total",
    variable >= "B25034_008" ~ "PreCR",
    variable <= "B25034_007" ~ "PostCR")) %>%
  mutate(variable = case_when(
    variable == "B25034_001" ~ "Total",
    variable == "B25034_002" ~ "2011orlater",
    variable == "B25034_003" ~ "2010to2014",
    variable == "B25034_004" ~ "2000to2009",
    variable == "B25034_005" ~ "1990to1999",
    variable == "B25034_006" ~ "1980to1989",
    variable == "B25034_007" ~ "1970to1979",
    variable == "B25034_008" ~ "1960to1969",
    variable == "B25034_009" ~ "1950to1959",
    variable == "B25034_010" ~ "1940to1949",
    variable == "B25034_011" ~ "1939orbefore")) %>%
  mutate(PercentofHousing = 100 * (estimate / summary_est)) %>%
  group_by(GEOID, Era) %>%
  mutate(CR_HousingStock=sum(PercentofHousing)) %>%
  ungroup %>%
  mutate(PostCRsuburb = case_when(
    Era == "PostCR" & CR_HousingStock >= 75 ~ "Yes",
    Era == "PostCR" & CR_HousingStock <= 75 ~ "No",
    Era == "PreCR" ~ "No"))
 
#Download geographies of interest (in this case, the CBSA)
CBSA_2011 <- core_based_statistical_areas(resolution = "500k", year = 2011) %>%
  filter(str_detect(NAME, CBSA))

#Spatial filter of tracts for the city of interest
HousingData_2011 <- HousingData_2011[CBSA_2011, ]

#Acquiring the central city geographies
CentralCities_2011 <- places(state = ST, year = YR) %>%
  filter(str_detect(NAMELSAD, CENTRAL_CITY)) 

#Removing the central city tracts from the Housing Data
HousingData_2011 <-  HousingData_2011[lengths(st_intersects(HousingData_2011,CentralCities_2011))==0,]

#Tidy the dataset
HousingData_2011 <- HousingData_2011 %>%
  separate(
    NAME,
    into = c("Tract", "County", "State"),
    sep = ", "
  ) %>%
  rename(Age = variable) %>%
  select(GEOID, County, State, PostCRsuburb, Era, estimate, moe, PercentofHousing, Age, CR_HousingStock, geometry) %>%
  filter(!Age == "Total")

#Erase water bodies, rivers, lakes
HousingData_2011 <- erase_water(HousingData_2011)

#Creating an object of post-CR tracts
PostCR_suburbs_2011 <- HousingData_2011 %>%
  select(GEOID, County, State, PostCRsuburb, geometry)

#save(PostCR_suburbs_2011,file = "~/OneDrive - The Pennsylvania State University/Suburban typologies Paper/Post-CR suburbs/PostCRsuburbs_2011.Rdata")


#For genereal visualization of Charlotte, NC
ggplot() + 
  geom_sf(data = PostCR_suburbs_2011[PostCR_suburbs_2011$State == c("North Carolina", "South Carolina"), ], 
          aes(fill = PostCRsuburb), linewidth = 0.1, color = "white") + 
  theme_void() +
  scale_fill_manual(values=c("#BFBFBF", "#1A1A1A"), 
                    labels=c("Pre-Civil Rights", "Post-Civil Rights"),
                    na.translate = F,
                    guide = "none") +
  theme(legend.title=element_blank(),
        legend.position=c("bottom")) + 
  guides(color = guide_legend(title.position = "top", 
                              title.hjust = 0.5,
                              label.position = "bottom",
                              override.aes = list(size=1)))

#ggsave("CharlotteCR_2011.png",
       path = "~/desktop",
       width = 6,
       height = 8,
       units = "in",
       dpi = 500)


-------
#2021
  
YR = 2021  
  
#Table B25034 - Year Structure Built
#Filter Pre- and Post-CR housing
#Rename raw variables with codebook labels
HousingData_2021 <- get_acs(year = YR,
                              geography = GEOG,
                              state = ST,
                              table = "B25034",
                              summary_var = "B25034_001",
                              geometry = TRUE) %>%
  mutate(Era = case_when(
    variable == "B25034_001" ~ "Total",
    variable >= "B25034_008" ~ "PreCR",
    variable <= "B25034_007" ~ "PostCR")) %>%
  mutate(variable = case_when(
    variable == "B25034_001" ~ "Total",
    variable == "B25034_002" ~ "2021orlater",
    variable == "B25034_003" ~ "2010to2014",
    variable == "B25034_004" ~ "2000to2009",
    variable == "B25034_005" ~ "1990to1999",
    variable == "B25034_006" ~ "1980to1989",
    variable == "B25034_007" ~ "1970to1979",
    variable == "B25034_008" ~ "1960to1969",
    variable == "B25034_009" ~ "1950to1959",
    variable == "B25034_010" ~ "1940to1949",
    variable == "B25034_011" ~ "1939orbefore")) %>%
  mutate(PercentofHousing = 100 * (estimate / summary_est)) %>%
  group_by(GEOID, Era) %>%
  mutate(CR_HousingStock=sum(PercentofHousing)) %>%
  ungroup %>%
  mutate(PostCRsuburb = case_when(
    Era == "PostCR" & CR_HousingStock >= 75 ~ "Yes",
    Era == "PostCR" & CR_HousingStock <= 75 ~ "No",
    Era == "PreCR" ~ "No"))

#Download geographies of interest (in this case, the CBSA)
CBSA_2021 <- core_based_statistical_areas(resolution = "500k", year = 2021) %>%
  filter(str_detect(NAME, CBSA))

#Spatial filter of tracts for the city of interest
HousingData_2021 <- HousingData_2021[CBSA_2021, ]

#Acquiring the central city geographies
CentralCities_2021 <- places(state = ST, year = YR) %>%
  filter(str_detect(NAMELSAD, CENTRAL_CITY)) 

#Removing the central city tracts from the Housing Data
HousingData_2021 <-  HousingData_2021[lengths(st_intersects(HousingData_2021,CentralCities_2021))==0,]

#Tidy the dataset
HousingData_2021 <- HousingData_2021 %>%
  separate(
    NAME,
    into = c("Tract", "County", "State"),
    sep = ", "
  ) %>%
  rename(Age = variable) %>%
  select(GEOID, County, State, PostCRsuburb, Era, estimate, moe, PercentofHousing, Age, CR_HousingStock, geometry) %>%
  filter(!Age == "Total")

#Erase water bodies, rivers, lakes
HousingData_2021 <- erase_water(HousingData_2021)

#Creating an object of post-CR tracts
PostCR_suburbs_2021 <- HousingData_2021 %>%
  select(GEOID, County, State, PostCRsuburb, geometry)


#save(PostCR_suburbs_2021,file = "~/OneDrive - The Pennsylvania State University/Suburban typologies Paper/Post-CR suburbs/PostCRsuburbs_2021.Rdata")

#For general visualization of Charlotte, NC
ggplot() + 
  geom_sf(data = PostCR_suburbs_2021[PostCR_suburbs_2021$State == c("North Carolina", "South Carolina"), ], 
          aes(fill = PostCRsuburb), linewidth = 0.1, color = "white") + 
  theme_void() +
  scale_fill_manual(values=c("#BFBFBF", "#1A1A1A"), 
                     labels=c("Pre-Civil Rights\nSuburbs", "Post-Civil Rights\nSuburbs"),
                    na.translate = F) +
  theme(legend.title=element_blank(),
        legend.position=c("bottom"),
        legend.key = element_rect(colour = NA, fill = NA)) + 
  guides(fill = guide_legend(title.position = "top", 
                              title.hjust = 0.5,
                              label.position = "bottom",
                              override.aes = list(size=1)))

#ggsave("CharlotteCR_2021.png",
       path = "~/desktop",
       width = 6,
       height = 8,
       units = "in",
       dpi = 500)
