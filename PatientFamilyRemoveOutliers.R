# Script to remove outliers from patient sample list.
# Generates table of patient data to be considered

# Run this in the console:
# rm(list = ls())
# source("dev/PatientFamilyRemoveOutliers.R") 

library(ggplot2)
library(plyr)

# savepng -- function to save png
savepng <- function(img, fname) {
  print(img)
  dev.off()
  ggsave(fname, width=6, height=4, dpi=600)
  return()
}

# Workflow A. =============================================

# load patient family mapping table
family.list <- read.table("dev/inmr.fam.list", header = FALSE)
colnames(family.list) =c("familyId", "id", "paternalId", "maternalId", "gender", "md")
family.list$gender[family.list$gender == 2] <- "F"
family.list$gender[family.list$gender == 1] <- "M"
family.list$md[family.list$md == 1] <- F
family.list$md[family.list$md == 2] <- T
family.list$paternalId[family.list$paternalId == '.'] <- NA
family.list$maternalId[family.list$maternalId == '.'] <- NA

# Part 1. Count total number of retrogene insertion positions per sample and remove outliers.

# all results from gencode
all.gencode <- read.table("wc.gencode.bed.txt", header=FALSE, sep=" ")
colnames(all.gencode) = c("count","id");

img.b1.1 <- qplot(all.gencode$count, geom="histogram", binwidth=50) + ggtitle(paste0("Number of gencode entries in the samples (n = ", length(all.gencode$id), ")")) + ylab("Number of samples") + xlab("Total number of retrogene insertions") + scale_x_continuous(breaks = scales::pretty_breaks(n = 10))
savepng(img.b1.1, "dev/rsave/workflow.b1.1.png")

# outliers
outliers <- as.vector(all.gencode[all.gencode$count < 100 | all.gencode$count > 500, ]$id)
# outliers in family data
outliers.family <- unique(family.list[family.list$id %in% outliers | family.list$paternalId %in% outliers | family.list$maternalId %in% outliers, ]$familyId)
# add outlier family members
outliers <- unique(c(as.vector(family.list[family.list$familyId %in% outliers.family, ]$id), outliers))
filtered.gencode <- all.gencode[!all.gencode$id %in% outliers, ]

img.b1.2 <- qplot(filtered.gencode$count, geom="histogram", binwidth=20) + ggtitle(paste0("Number of gencode entries in the samples (n = ", length(filtered.gencode$id), ")")) + ylab("Number of samples") + xlab("Total number of retrogene insertions");
savepng(img.b1.2, "dev/rsave/workflow.b1.2.png")

# continue to remove more outliers
outliers <- as.vector(all.gencode[all.gencode$count < 200 | all.gencode$count > 350, ]$id)
outliers.family <- as.vector(unique(family.list[family.list$id %in% outliers | family.list$paternalId %in% outliers | family.list$maternalId %in% outliers, ]$familyId))
outliers <- unique(c(as.vector(family.list[family.list$familyId %in% outliers.family,]$id), outliers))

# resulting samples to retain
filtered.gencode <- all.gencode[!all.gencode$id %in% outliers, ];
img.b1.3 <- qplot(filtered.gencode$count, geom="histogram", binwidth=20) + ggtitle(paste0("Number of gencode entries in the samples (n = ", length(filtered.gencode$id), ")")) + ylab("Number of samples") + xlab("Total number of retrogene insertions") + scale_x_continuous(breaks = scales::pretty_breaks(n = 5))
savepng(img.b1.3, "dev/rsave/workflow.b1.3.png")


# Part 2. Count total number of genes per sample and remove outliers.
all.genecount <- read.table("results.genecount.txt", header=FALSE, sep=" ")
colnames(all.genecount) = c("count","id")

img.b2.1 <- qplot(all.genecount$count, geom="histogram", binwidth=20) + ggtitle(paste0("Number of affected genes in the samples (n = ", length(all.genecount$id), ")")) + ylab("Number of samples") + xlab("Sum of genes affected by retrogene insertion") + scale_x_continuous(breaks = scales::pretty_breaks(n = 10))
savepng(img.b2.1, "dev/rsave/workflow.b2.1.png")

# samples to retain are in filtered.genecount. remove outliers from Part 1.
filtered.genecount <- all.genecount[!all.genecount$id %in% outliers, ]

img.b2.2 <- qplot(filtered.genecount$count, geom="histogram", binwidth=20) + ggtitle(paste0("Number of affected genes in the samples (n = ", length(filtered.genecount$id), ")")) + ylab("Number of samples") + xlab("Sum of genes affected by retrogene insertion") + scale_x_continuous(breaks = scales::pretty_breaks(n = 10))
savepng(img.b2.2, "dev/rsave/workflow.b2.2.png")

# remove outliers identified from histogram above
outliers = unique(c(outliers, as.vector(filtered.genecount[filtered.genecount$count > 170, ]$id)))
# remove family members as well
outliers.family <- as.vector(unique(family.list[family.list$id %in% outliers | family.list$paternalId %in% outliers | family.list$maternalId %in% outliers, ]$familyId))
outliers <- unique(c(as.vector(family.list[family.list$familyId %in% outliers.family,]$id), outliers))

filtered.genecount <- all.genecount[!all.genecount$id %in% outliers, ]
img.b2.3 <- qplot(filtered.genecount$count, geom="histogram", binwidth=20) + ggtitle(paste0("Number of affected genes in the samples (n = ", length(filtered.genecount$id), ")")) + ylab("Number of samples") + xlab("Sum of genes affected by retrogene insertion") + scale_x_continuous(breaks = scales::pretty_breaks(n = 10));
savepng(img.b2.3, "dev/rsave/workflow.b2.3.png")

# patient family list is what we have data for
patient.ids <- as.vector(filtered.genecount$id)
patients.list <- family.list[family.list$id %in% patient.ids | family.list$paternalId %in% patient.ids | family.list$maternalId %in% patient.ids, ]
patients.list <- patients.list[order(patients.list$familyId), ]

# remove samples that are not part of a trio
family.numbers <- count(patients.list, "familyId")
family.trio <- as.vector(family.numbers[family.numbers$freq >=3, ]$familyId)
patients.family <- patients.list[patients.list$familyId %in% family.trio, ]

# export data to csv
write.table(patients.family, "dev/rsave/patients.csv", sep=",")


