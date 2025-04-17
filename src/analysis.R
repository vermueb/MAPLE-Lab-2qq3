library(readr)
library(dplyr)
library(tidyr)
library(purrr)
library(jsonlite)
library(ggplot2)
df_raw <- read_csv("data/df_raw.csv")
df_tidy <- df_raw %>%
  mutate(
    val = map(val, ~ .x |> fromJSON() |> t() |> colSums()),
    filename = sub(".wav", "", filename)
  ) |>
  # Split filename into relevant info.
  separate_wider_delim(
    filename,
    names = c(
      "composer", "set", "performer", "chroma",
      "mode", "albumID", "manipulations", "levels"
    ),
    delim = "_"
  ) |>
  # Split up manipulations.
  separate_wider_delim(
    manipulations,
    names = c("manipulation1", "manipulation2"),
    delim = "+"
  ) |>
  # Split up levels.
  separate_wider_delim(
    levels,
    names = c("level1", "level2"),
    delim = "+"
  ) |>
  select(-c(composer, set, performer, albumID))

df_baseline <- df_tidy |>
  filter(level2 == '0' & level1 == '4U-Studio-Chateau-Grand-v1.0', level1 != 'NA') |>
  select(chroma, mode, val) |>
  rename(val_baseline = val)

df_plot <- df_tidy |>
  filter(level1 != 'NA') |>
  filter(!level1 %in% c("Guitar-Bass", "FM-Electric-Piano")) |>  # <-- filter out unwanted level1 values
  left_join(
    df_baseline,
    by = c("chroma", "mode")
  ) |>
  mutate(
    val = map2(val, as.numeric(level2), function(v, s) {
      s_mod <- s %% 12
      if (s_mod == 0) return(v)
      c(v[(s_mod + 1):length(v)], v[1:s_mod])
    }),
    mse = map2_dbl(val, val_baseline, ~ mean((.x - .y)^2))
  )


#Line Graph Averaged Across Pieces (3rd)
df_plot |>
  filter(level2 != 'NA' & level1 != 'NA', !level1 %in% c("Guitar-Bass", "FM-Electric-Piano")) |>
  group_by(level1,level2) |>
  summarize(mse=mean(mse))|>
  ggplot(
    aes(x = as.numeric(level2),
        y = mse,
        colour = level1,
        group = level1))+
  geom_vline(xintercept=0, colour = "lightgrey")+
  geom_line()+
  geom_point()+
  scale_color_manual(
    values = c(
      "honkytonk" = "salmon",
      "Nylon-and-Steeel-Guitars-4U-v2" = "turquoise",
      "4U-Studio-Chateau-Grand-v1.0" = "orchid",
      "Expressive-Flute-SSO-v1.2" = "orange",
      "harpsichord" = "skyblue",
      "organ" = "mediumseagreen"
    ),
    labels = c(
      "honkytonk" = "Honky Tonk Piano",
      "Nylon-and-Steeel-Guitars-4U-v2" = "Guitar",
      "4U-Studio-Chateau-Grand-v1.0" = "Grand Piano",
      "Expressive-Flute-SSO-v1.2" = "Flute", 
      "harpsichord" = "Harpsichord",
      "organ" = "Organ")
  ) +
  labs(x="Semitone Transposition", y="Mean Squared Error (avg across preludes)", colour = "Instrument/Soundfont",
       title= "Chopin's 24 Preludes: Interaction with SF & Transposition")+
  theme_classic()+
  theme(
    plot.title = element_text(size = 11),
  axis.title.x = element_text(size = 9),  # x-axis title font size
  axis.title.y = element_text(size = 9))+ # y-axis title font size
  theme(axis.text.y = element_blank(),   # removes y-axis tick labels
        axis.ticks.y = element_blank()   # removes y-axis tick marks
  )

  #theme(legend.position = "bottom")



#Line Graph Across Pieces Facetted (2nd)
df_plot |>
  mutate(piece = paste(chroma,mode))|>
  filter(level2 != 'NA' & level1 %in% c('Nylon-and-Steeel-Guitars-4U-v2', 'honkytonk'), piece == "9 minor" ) |>
  ggplot(
    aes(x = as.numeric(level2),
        y = mse,
        colour = level1))+
  geom_line()+
  geom_point()+ 
  scale_color_manual(
    values = c("honkytonk" = "salmon", "Nylon-and-Steeel-Guitars-4U-v2" = "turquoise"),
    labels = c("honkytonk" = "Honky Tonk Piano", "Nylon-and-Steeel-Guitars-4U-v2" = "Guitar")
  ) +
 # theme(legend.position="bottom")+
  labs(x="Chroma Transposition",y= "Mean Squared Error (MSE)",colour ="Instrument/Soundfont",
       title= "Chopin A minor Prelude: Guitar and Honky Tonk Piano")+
  theme_classic()+
  theme(axis.text.y = element_blank(),   # removes y-axis tick labels
        axis.ticks.y = element_blank()   # removes y-axis tick marks
  )



#Bar plot- 1st 
row <- df_plot |> 
  filter(chroma == 3, mode == "minor") |> 
  slice(105)
tibble(
  pitch_class = factor(0:11),  # or name them c("C", "C#", "D", ..., "B") if preferred
  Manipulated = unlist(row$val),
  Baseline = unlist(row$val_baseline)
) %>%
  pivot_longer(cols = c(Manipulated, Baseline), names_to = "type", values_to = "amplitude") |>
  ggplot(aes(x = pitch_class, y = amplitude, fill = type)) +
  geom_bar(stat = "identity", position = "dodge")+
  labs(x = "Rotated Pitch Class", y= "Energy", fill = "Condition", title = "Chopin E flat minor Prelude: Guitar & -2 Semitone Transposition")+
  theme_classic()+
  theme(axis.text.y = element_blank(),   # removes y-axis tick labels
    axis.ticks.y = element_blank()   # removes y-axis tick marks
  )






#Line Graph Averaged Across Pieces Facetted
df_plot |>
  filter(level2 != 'NA' & level1 != 'NA', !level1 %in% c("Guitar-Bass", "FM-Electric-Piano")) |>
  group_by(level1,level2) |>
  summarize(mse=mean(mse), sd=sd(mse))|>
  ggplot(
    aes(x = as.numeric(level2),
        y = mse,
        colour = level1))+
  geom_errorbar(aes(ymin=mse-sd, ymax=mse+sd),colour='black')+
  geom_line()+
  geom_point()+
  facet_wrap(~level1,scales='free')+
  theme(legend.position="none")
