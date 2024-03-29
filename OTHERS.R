library(readr)
library(sjPlot)
library(Rmisc)
library(ggplot2)
library(tidyverse)
library(hrbrthemes)
library(viridis)
library(plotly)
library(htmlwidgets)
library(heatmaply)
# Remove all variables in environment
rm(list=ls())
# Read data
OTHERS = read_csv("C:/Users/mingz/Documents/mouse/mouse_project/OTHERS.csv")
# Subset useful features
OTHERS = data.frame(OTHERS$`MOUSE ID`, OTHERS$`ALL ORGANS`, OTHERS$HEART, OTHERS$KIDNEYS, OTHERS$`URINARY BLADDER`, OTHERS$...11)
OTHERS = OTHERS[OTHERS$OTHERS..MOUSE.ID. != "Average", ]
OTHERS = OTHERS[(!is.na(OTHERS$OTHERS..MOUSE.ID.)) & (OTHERS$OTHERS..MOUSE.ID. != "???????"), ]
colnames(OTHERS) = c("MOUSE ID", "ALL ORGANS", "HEART", "KIDNEYS", "BLADDER", "lymphoid hyperplasia")
split_mouse_id = matrix(unlist(strsplit(OTHERS$`MOUSE ID`, "-")), ncol = 2, byrow = T)
cc_id = split_mouse_id[ , 1]
gender_group = gsub("[[:digit:]]","",split_mouse_id[ , 2])
gender = substr(gender_group, 1, 1)
group = substr(gender_group, 2, 2)
strainind = groupind = rep(NA, length(group))
groupind[group == "I"] = 1
groupind[group == "C"] = 0
extra = substr(gender_group, 4, 6)
OTHERS = cbind(cc_id, gender, groupind, strainind, OTHERS[ , -1])
# OTHERS = OTHERS[extra != "(I)", ]
OTHERS = OTHERS[as.numeric(rownames(OTHERS)) <= 351, ]
OTHERS = OTHERS[OTHERS$cc_id != "042", ]
OTHERS$groupind[as.numeric(rownames(OTHERS)) == 49] = 1
# Set features as numeric
OTHERS$`ALL ORGANS` = as.numeric(OTHERS$`ALL ORGANS`)
OTHERS$HEART = as.numeric(OTHERS$HEART)
OTHERS$KIDNEYS = as.numeric(OTHERS$KIDNEYS)
OTHERS$BLADDER = as.numeric(OTHERS$BLADDER)
OTHERS$`lymphoid hyperplasia` = as.numeric(OTHERS$`lymphoid hyperplasia`)
# Correct typo in original dataset
OTHERS$groupind[rownames(OTHERS) == "49"] = 1
OTHERS$cc_id[rownames(OTHERS) == "262"] = "044"
write.csv(OTHERS, 'cleaned_OTHERS.csv')

# Regression for pair-wise comparison between strains.
unique_cc_id = unique(OTHERS$cc_id)
l_unique_cc_id = length(unique_cc_id)
data_mat=matrix(NA, l_unique_cc_id, l_unique_cc_id)
rownames(data_mat) = colnames(data_mat) = unique_cc_id

for (ind in 5:9) {
  for (c1 in 1:l_unique_cc_id) {
    for (c2 in 1:l_unique_cc_id) {
      if (c1!=c2) {
        data = OTHERS[OTHERS$cc_id == unique_cc_id[c1] | OTHERS$cc_id == unique_cc_id[c2], ]
        data$strainind[data$cc_id == unique_cc_id[c1]] = 0
        data$strainind[data$cc_id == unique_cc_id[c2]] = 1
        data_mat[c1, c2]=summary(lm(data[ ,ind]~strainind+groupind+strainind*groupind, data=data))$coef[4, 4]
      }
    }
  }
  mat_name = gsub(" ", "_", names(OTHERS)[ind])
  mat_name = gsub("/", "_", mat_name)
  write.csv(data_mat, paste0(mat_name, ".csv"))
  assign(mat_name,
          heatmaply(data_mat, dendrogram = "none",
                    main = paste("Pair-wise p-value for ", mat_name),
                    margins = c(60,100,40,20),
                    grid_color = "white",
                    grid_width = 0.00001,
                    titleX = TRUE,
                    hide_colorbar = FALSE,
                    branches_lwd = 0.1,
                    label_names = c("Row strain:", "Column strain:", "p-value:"),
                    fontsize_row = 10, fontsize_col = 10,
                    labCol = colnames(data_mat),
                    labRow = rownames(data_mat),
                    heatmap_layers = theme(axis.line=element_blank())
          ))
  saveWidget(get(mat_name), file = paste0(mat_name, ".html"))
}

# # Calculate corresponding difference between infection group and control group for each strain each sex
# for (cc in unique(OTHERS$cc_id)) {
#   for (g in unique(OTHERS$gender)) {
#     OTHERS[OTHERS$cc_id == cc & OTHERS$gender == g & OTHERS$group == "I", 4:8] =
#       OTHERS[OTHERS$cc_id == cc & OTHERS$gender == g & OTHERS$group == "I", 4:8] - rbind(OTHERS[OTHERS$cc_id == cc & OTHERS$gender == g & OTHERS$group == "C", 4:8], OTHERS[OTHERS$cc_id == cc & OTHERS$gender == g & OTHERS$group == "C", 4:8])
#   }
# }
# OTHERS_DIFF = OTHERS[OTHERS$group == "I", ]
# OTHERS_DIFF = subset(OTHERS_DIFF, select = - group)
# # Remove rows with all NAs.
# OTHERS_DIFF = OTHERS_DIFF[!(is.na(OTHERS_DIFF$`ALL ORGANS`) & is.na(OTHERS_DIFF$HEART) & is.na(OTHERS_DIFF$KIDNEYS) & is.na(OTHERS_DIFF$BLADDER) & is.na(OTHERS_DIFF$`lymphoid hyperplasia`)), ]
# write.csv(OTHERS_DIFF, 'cleaned_OTHERS_DIFF.csv')
# # Take strain IDs
# cc_ids = unique(OTHERS_DIFF$cc_id)
# l_cc_id = length(cc_ids)
# # Generate p_value mat for inter-sex comparison
# p_value_mat = data.frame(matrix(NA, nrow = l_cc_id, ncol = 5))
# for (ind in 3:7) {
#   for (cc in 1:l_cc_id) {
#     skip_to_next <- FALSE
#     p_value_mat[cc, (ind - 2)] = as.numeric(tryCatch(t.test(OTHERS_DIFF[OTHERS_DIFF$cc_id == cc_ids[cc] & OTHERS_DIFF$gender == "M", ind], OTHERS_DIFF[OTHERS_DIFF$cc_id == cc_ids[cc] & OTHERS_DIFF$gender == "F", ind], alternative = "two.sided", pair = F)$p.value, error = function(e) {skip_to_next <- NA}))
#     if(is.na(skip_to_next)) {next}     
#   }
# }
# # Put on feature names and strain IDs
# colnames(p_value_mat) = names(OTHERS_DIFF)[3:7]
# rownames(p_value_mat) = cc_ids
# # Remove rows with all NAs.
# p_value_mat = p_value_mat[!(is.na(p_value_mat$`ALL ORGANS`) & is.na(p_value_mat$HEART) & is.na(p_value_mat$KIDNEYS) & is.na(p_value_mat$BLADDER) & is.na(p_value_mat$`lymphoid hyperplasia`)), ]
# # Transpose for display
# t_p_value_mat = t(p_value_mat)
# write.csv(t_p_value_mat,'intersex_OTHERS.csv')
# assign("intersex_OTHERS_heatmap",
#        heatmaply(t_p_value_mat, dendrogram = "none",
#                  main = "Intersex p-value for OTHERS",
#                  margins = c(60,100,40,20),
#                  grid_color = "white",
#                  grid_width = 0.00001,
#                  titleX = TRUE,
#                  hide_colorbar = FALSE,
#                  branches_lwd = 0.1,
#                  label_names = c("Indicator:", "Strain:", "Intersex p-value:"),
#                  fontsize_row = 10, fontsize_col = 10,
#                  labCol = colnames(t_p_value_mat),
#                  labRow = rownames(t_p_value_mat),
#                  heatmap_layers = theme(axis.line=element_blank())
#        ))
# saveWidget(intersex_OTHERS_heatmap, file = "intersex_OTHERS.html")
# 
# # Generate overall inter-sex p-value
# p_value_vec = data.frame(matrix(NA, 1, 5))
# average_vec = matrix(NA, 2, 5)
# rownames(average_vec) = c("M", "F")
# average_vec = data.frame(average_vec)
# 
# for (ind in 3:7) {
#   skip_to_next <- FALSE
#   p_value_vec[1, (ind - 2)] = as.numeric(tryCatch(t.test(as.numeric(OTHERS_DIFF[OTHERS_DIFF$gender == "M", ind]), as.numeric(OTHERS_DIFF[OTHERS_DIFF$gender == "F", ind]), alternative = "two.sided", pair = F)$p.value, error = function(e) {skip_to_next <- NA}))
#   average_vec[1, (ind - 2)] = mean(as.numeric(OTHERS_DIFF[OTHERS_DIFF$gender == "M", ind]), na.rm = TRUE)
#   average_vec[2, (ind - 2)] = mean(as.numeric(OTHERS_DIFF[OTHERS_DIFF$gender == "F", ind]), na.rm = TRUE)
#   if(is.na(skip_to_next)) {next}     
# }
# colnames(p_value_vec) = colnames(average_vec) = names(OTHERS_DIFF)[3:7]
# write.csv(p_value_vec,'intersex_OTHERS_overall.csv')
# write.csv(average_vec, 'OTHERS_average_by_sex.csv')
# 
# # Calculate pairwise p-values
# p_value_pairwise = array(NA, c(l_cc_id, l_cc_id, 5))
# for (ind in 3:7) {
#   for (cc_1 in 1:l_cc_id) {
#     for (cc_2 in 1:l_cc_id) {
#       skip_to_next <- FALSE
#       p_value_pairwise[cc_1, cc_2, (ind - 2)] = as.numeric(tryCatch(t.test(as.numeric(OTHERS_DIFF[OTHERS_DIFF$cc_id == cc_ids[cc_1], ind]), as.numeric(OTHERS_DIFF[OTHERS_DIFF$cc_id == cc_ids[cc_2], ind]), alternative = "two.sided", pair = F)$p.value, error = function(e) {skip_to_next <- NA}))
#       if(is.na(skip_to_next)) {next}     
#     }
#   }
# }
# # Visualize pairwise p-values by heatmap
# for (ind in 3:7) {
#   data_mat = p_value_pairwise[ , , (ind - 2)]
#   cp = rowSums(is.na(data_mat)) != ncol(data_mat)
#   data_mat = data_mat[cp, cp]
#   rownames(data_mat) = colnames(data_mat) = cc_ids[cp]
#   mat_name = gsub(" ", "_", names(OTHERS_DIFF)[ind])
#   mat_name = gsub("/", "_", mat_name)
#   write.csv(data_mat, paste0(mat_name, ".csv"))
#   assign(mat_name,
#          heatmaply(data_mat, dendrogram = "none",
#                    main = paste("Pair-wise p-value for ", mat_name),
#                    margins = c(60,100,40,20),
#                    grid_color = "white",
#                    grid_width = 0.00001,
#                    titleX = TRUE,
#                    hide_colorbar = FALSE,
#                    branches_lwd = 0.1,
#                    label_names = c("Row strain:", "Column strain:", "p-value:"),
#                    fontsize_row = 10, fontsize_col = 10,
#                    labCol = colnames(data_mat),
#                    labRow = rownames(data_mat),
#                    heatmap_layers = theme(axis.line=element_blank())
#          ))
#   saveWidget(get(mat_name), file = paste0(mat_name, ".html"))
# }
# average_p_value = matrix(NA, l_cc_id, l_cc_id)
# for (i in 1:l_cc_id){
#   for (j in 1:l_cc_id){
#     average_p_value[i, j] = mean(p_value_pairwise[i,j,], na.rm = TRUE)
#   }
# }
# colnames(average_p_value) = rownames(average_p_value) = cc_ids
# write.csv(average_p_value, "average_p_value_OTHERS.csv")
# assign("average_p_value_heatmap",
#        heatmaply(average_p_value, dendrogram = "none",
#                  main = "Average p-value for OTHERS",
#                  margins = c(60,100,40,20),
#                  grid_color = "white",
#                  grid_width = 0.00001,
#                  titleX = TRUE,
#                  hide_colorbar = FALSE,
#                  branches_lwd = 0.1,
#                  label_names = c("Row strain:", "Column strain:", "Average p-value:"),
#                  fontsize_row = 10, fontsize_col = 10,
#                  labCol = colnames(average_p_value),
#                  labRow = rownames(average_p_value),
#                  heatmap_layers = theme(axis.line=element_blank())
#        ))
# saveWidget(average_p_value_heatmap, file = "average_p_value_OTHERS.html")


