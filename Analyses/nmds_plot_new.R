# Load the required libraries
library(vegan)
library(ggplot2)
library(ggpubr)
library(tidyverse)
# Load the dataset (example: compound data)
chem <- read.csv("data/Mike_Trees_herbivores2.csv")

summary(chem)
chem <- mutate(chem, treatment.1 = ifelse(treatment.1 == "minus", "removed", "replaced"))
# Perform NMDS with "treatment" as the grouping variable
nmds <- metaMDS(chem[, 5:37], distance = "bray", k = 2)



# Add the "treatment" variable to the NMDS result
nmds_data <- data.frame(nmds$points, treatment = chem$treatment, 
                        exclusion = chem$treatment.1, 
                        taxon = chem$ploem.feeder)

# Calculate centroid for each treatment
centroids <- nmds_data |> group_by(exclusion, taxon, treatment) |> 
  summarize(MDS1 = mean(MDS1), MDS2 = mean(MDS2))

# Generate NMDS plot with color coding for treatments and connecting lines
 plot_nmds <- ggplot(nmds_data, aes(x = MDS1, y = MDS2, 
                                    colour = taxon , shape = exclusion)) +
  geom_point(size = 2, show.legend=FALSE) +
  geom_point(data = centroids, size = 4) +
  geom_segment(data = nmds_data,
                aes(xend = centroids$MDS1[match(treatment, centroids$treatment)], 
                    yend = centroids$MDS2[match(treatment, centroids$treatment)]), 
                linetype = "dashed") +
  labs(x = "NMDS1", y = "NMDS2", shape = "Treatment", color = "Taxon") +
  scale_shape_manual(values=c(1, 16)) +
  theme_classic()

# Display the NMDS plot
print(plot_nmds)


