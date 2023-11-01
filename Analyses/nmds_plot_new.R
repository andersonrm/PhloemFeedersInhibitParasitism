# Load the required libraries
library(vegan)
library(ggplot2)
library(ggpubr)
library(tidyverse)


# Load the dataset (example: compound data)
chem <- read.csv("data/Mike_Trees_herbivores2.csv")


# functions

veganCovEllipse<-function (cov, center = c(0, 0), scale = 1, npoints = 100) 
{
  theta <- (0:npoints) * 2 * pi/npoints
  Circle <- cbind(cos(theta), sin(theta))
  t(center + scale * t(Circle %*% chol(cov)))
}



############################

summary(chem)
chem <- mutate(chem,
               treatment.1 = ifelse(treatment.1 == "minus", "removed", "replaced"))
# Perform NMDS with "treatment" as the grouping variable
nmds <- metaMDS(chem[, 5:37], distance = "bray", k = 2)



# Add the "treatment" variable to the NMDS result
nmds_data <- data.frame(nmds$points, treatment = chem$treatment, 
                        exclusion = chem$treatment.1, 
                        taxon = chem$ploem.feeder,
                        sites = 1:16,
                        row.names = "sites")

# Calculate centroid for each treatment
centroids <- nmds_data |> group_by(exclusion, taxon, treatment) |> 
  summarize(MDS1 = mean(MDS1), MDS2 = mean(MDS2))

# Generate NMDS plot with color coding for treatments and connecting lines
 plot_nmds <- ggplot(nmds_data, aes(x = MDS1, y = MDS2, 
                                    colour = taxon , shape = exclusion)) +
  geom_point(size = 2, show.legend=FALSE) +
  geom_point(data = centroids, size = 4) +
  geom_segment(data = nmds_data,
                aes(xend = centroids$MDS1[match(treatment,
                                                centroids$treatment)], 
                    yend = centroids$MDS2[match(treatment,
                                                centroids$treatment)]), 
                linetype = "dashed") +
  labs(x = "NMDS1", y = "NMDS2", shape = "Treatment", color = "Taxon") +
  scale_shape_manual(values=c(1, 16)) +
  theme_classic(base_size = 20)

# Display the NMDS plot
print(plot_nmds)



################################
# ellipses
nmds_data <- nmds_data %>% 
  unite(treatment, c("exclusion", "taxon"))

nmdsmeta <- data.frame(
  MDS1 = nmds$points[,1],
  MDS2 = nmds$points[,2],
  group = nmds_data$treatment
)

nmdsmeta$group <- as.factor(nmdsmeta$group)

plot(nmds)
ord <- ordiellipse(nmds,
                   nmds_data$treatment,
                   display = "sites",
                   kind = "se", conf = 0.95, label = T)

df_ell <- data.frame()
for(g in levels(nmdsmeta$group)){
  df_ell <- rbind(df_ell,
                  cbind(
                    as.data.frame(with(
                      nmdsmeta[nmdsmeta$group==g,],
                      veganCovEllipse(ord[[g]]$cov,ord[[g]]$center,ord[[g]]$scale)))
                                ,group=g))
}

df_ell <- df_ell %>% 
  mutate(exclusion = if_else(grepl("replaced", group), "replaced", "removed"),
         taxon = if_else(grepl("membracid", group), "membracid", "coccid"))

nmds_data <- nmds_data %>% 
  separate_wider_delim(treatment, delim = "_",
                       names = c("exclusion", "taxon"))

#########################################
# test

ell.fig <- ggplot(nmds_data, aes(x = MDS1, y = MDS2, 
                                   colour = taxon , shape = exclusion)) +
  geom_point(size = 2, show.legend=FALSE) +
  geom_point(data = centroids, size = 5) +
  geom_polygon(data = df_ell,
            aes(x = NMDS1, y = NMDS2, fill = taxon), 
            alpha = 0.1, color = NA) +
  labs(x = "NMDS1", y = "NMDS2", shape = "Treatment", color = "Taxon") +
  scale_shape_manual(values=c(1, 16)) +
  scale_fill_discrete(guide = "none") +
  theme_classic(base_size = 15)


ell.fig.color <- ggplot(nmds_data, aes(x = MDS1, y = MDS2, 
                      fill = taxon, 
                      color = taxon,
                      shape = exclusion)) +
  geom_point(size = 2, show.legend=F) +
  geom_point(data = centroids, size = 5, show.legend = T) +
  geom_polygon(data = df_ell,
               aes(x = NMDS1, y = NMDS2, fill = taxon), 
               alpha = 0.3, color = NA,
               show.legend = F) +
  labs(x = "NMDS1", y = "NMDS2", shape = "Treatment", color = "Taxon") +
  scale_shape_manual(values=c(1, 16)) +
  # scale_color_discrete(guide = "none") +
  theme_classic(base_size = 15) +
  scale_fill_manual(values = c("#D55E00", "#56B4E9")) +
  scale_color_manual(values = c("#D55E00", "#56B4E9"))

######
# print the fig
print(ell.fig)

print(ell.fig.color)
