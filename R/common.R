
library(tidyverse)
library(RColorBrewer)
library(stringr)
library(here)

options(dplyr.summarise.inform = FALSE) 


### Commenting these out - not used in more recent scripts, but might still need them for old work
# set the Mazu shortcuts based on operating system
# dir_M <- c('Windows' = '//mazu.nceas.ucsb.edu/ohi',
#            'Darwin'  = '/Volumes/ohi',    ### connect (cmd-K) to smb://mazu/ohi
#            'Linux'   = '/home/shares/ohi')[[ Sys.info()[['sysname']] ]] %>%
#   path.expand()
# 
# dir_O <- c('Windows' = '//mazu.nceas.ucsb.edu/ohara',
#            'Darwin'  = '/Volumes/ohara',    ### connect (cmd-K) to smb://mazu/ohara
#            'Linux'   = '/home/ohara')[[ Sys.info()[['sysname']] ]] %>%
#   path.expand()


### Set up some options
# options(scipen = "999")           ### Turn off scientific notation
options(stringsAsFactors = FALSE) ### Ensure strings come in as character types


### generic theme for all plots
ggtheme_plot <- function(base_size = 9) {
  theme(axis.ticks = element_blank(),
        text       = element_text(family = 'Helvetica', color = 'gray30', size = base_size),
        axis.text  = element_text(size = rel(0.8)),
        axis.title = element_text(size = rel(1.0)),
        plot.title = element_text(size = rel(1.25), hjust = 0, face = 'bold'),
        panel.background = element_blank(),
        strip.background = element_blank(),
        strip.text       = element_text(size = base_size, face = 'italic'),
        legend.position  = 'right',
        panel.border     = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = 'grey90', size = .25),
        # panel.grid.major = element_blank(),
        legend.key       = element_rect(colour = NA, fill = NA),
        axis.line        = element_blank() # element_line(colour = "grey30", size = .5)
)}

### generic theme for maps
ggtheme_map <- function(base_size = 9) {
  theme(text             = element_text(family = 'Helvetica', color = 'gray30', size = base_size),
        plot.title       = element_text(size = rel(1.25), hjust = 0, face = 'bold'),
        panel.background = element_blank(),
        legend.position  = 'right',
        panel.border     = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),
        # panel.grid.major = element_blank(),
        axis.ticks       = element_blank(),
        axis.text        = element_blank(),
        axis.title       = element_blank(),
        legend.key       = element_rect(colour = NA, fill = NA),
        axis.line        = element_blank()) # element_line(colour = "grey30", size = .5)) +
}

show_dupes <- function(x, y, na.rm = FALSE) {
  if(na.rm)
    x <- x[!is.na(x[[y]]), ]

  # x is data frame, y is field (as character) within that dataframe
  z <- x[x[[y]] %in% x[[y]][duplicated(x[[y]])], ]
}

get_rgn_names <- function() {
  x <- foreign::read.dbf('~/github/ohibc/prep/_spatial/ohibc_rgn.dbf', as.is = TRUE) %>%
    dplyr::select(rgn_id, rgn_name, rgn_code) %>%
    bind_rows(data.frame(rgn_id   = 0,
                         rgn_name = 'British Columbia',
                         rgn_code = 'BC'))
}

clean_df_names <- function(df) {
  df <- df %>%
    setNames(tolower(names(.)) %>%
               str_replace_all('[^a-z0-9]+', '_') %>%
               str_replace_all('^_+|_+$', ''))
  return(df)
}

ditch_mac_cruft <- function() {
  all_files <- list.files(getwd(), all.files = TRUE,
                          recursive = TRUE, full.names = TRUE)

  cruft <- all_files[stringr::str_detect(basename(all_files), pattern = '^\\._|^.DS_Store')]
  message('ditching mac cruft files: \n  ', paste0(cruft, collapse = '\n  '))
  unlink(cruft)
}

### a keyed datatable join for speed
dt_join <- function(df1, df2, by, type) {
  a <- case_when(type == 'left' ~ c(FALSE, TRUE, FALSE), ### all, all.x, all.y
                 type == 'full' ~ c(TRUE, TRUE, TRUE),
                 type == 'inner' ~ c(FALSE, FALSE, FALSE))
  
  ### if all = FFF, behaves like inner join; if all = TTT,
  ### behaves like full join; if all = FTF, behaves like left_join?
  dt1 <- data.table::data.table(df1, key = by)
  dt2 <- data.table::data.table(df2, key = by)
  dt_full <- merge(dt1, dt2, all = a[1], all.x = a[2], all.y = a[3])
  return(as.data.frame(dt_full))
}
