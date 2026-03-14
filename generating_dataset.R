##### 1. Library #####

library(haven)
library(dplyr)
library(stringr)

##### 2. Loading dataset #####

rep2024 <- read_dta("rep_01_2024.dta")

##### 3. Selecting the first last name and the state #####

rep2024 <- rep2024 %>%
  mutate(first_lastname = sub(" .*", "", full_name)) %>%
  select(state_id, first_lastname)

##### 4. Counting the last name by state and order by number #####

lastname_state_counts <- rep2024 %>%
  count(state_id, first_lastname)

lastname_state_counts %>%
  arrange(state_id, desc(n))

##### 5. Saving the dataset #####

write.csv(lastname_state_counts, "lastname_state_counts.csv", row.names = FALSE)


##### 6. Loading the produced dataset #####

lastnamesbystate2024 <- read.csv("lastname_state_counts.csv")

lastnamesbystate2024 <- lastnamesbystate2024 %>%
  select(first_lastname, n)

lastnamesbystate2024 <- lastnamesbystate2024 %>%
  group_by(first_lastname)
  summarize(total_n = sum(as.numeric(n), na.rm = TRUE))
