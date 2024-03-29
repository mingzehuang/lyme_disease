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
JOINTS = read_csv("C:/Users/mingz/Documents/mouse/mouse_project/JOINTS.csv")
# Subset useful features
JOINTS = data.frame(JOINTS$`Mouse ID`, JOINTS$...5, JOINTS$...6, JOINTS$...7, JOINTS$...8, JOINTS$...9)
JOINTS = JOINTS[JOINTS$JOINTS..Mouse.ID. != "Average", ]
JOINTS = JOINTS[!is.na(JOINTS$JOINTS..Mouse.ID.), ]
colnames(JOINTS) = c("Mouse ID", "Adapted overall score (including all criteria)", "Synovial hyperplasia", "Exudate within joint and/or tendon sheath", "Superficial inflammation of bone", "Overall inflammation (whole tissue)")
split_mouse_id = matrix(unlist(strsplit(JOINTS$`Mouse ID`, "-")), ncol = 2, byrow = T)
cc_id = split_mouse_id[ , 1]
gender_group = gsub("[[:digit:]]","",split_mouse_id[ , 2])
gender = substr(gender_group, 1, 1)
group = substr(gender_group, 2, 2)
strainind = groupind = rep(NA, length(group))
groupind[group == "I"] = 1
groupind[group == "C"] = 0
JOINTS = cbind(cc_id, gender, groupind, strainind, JOINTS[ , -1])
# Set feature values as numeric
JOINTS$`Adapted overall score (including all criteria)` = as.numeric(JOINTS$`Adapted overall score (including all criteria)`)
JOINTS$`Synovial hyperplasia` = as.numeric(JOINTS$`Synovial hyperplasia`)
JOINTS$`Exudate within joint and/or tendon sheath` = as.numeric(JOINTS$`Exudate within joint and/or tendon sheath`)
JOINTS$`Superficial inflammation of bone` = as.numeric(JOINTS$`Superficial inflammation of bone`)
JOINTS$`Overall inflammation (whole tissue)` = as.numeric(JOINTS$`Overall inflammation (whole tissue)`)
write.csv(JOINTS,'cleaned_JOINTS.csv')

# Regression for pair-wise comparison between strains.
unique_cc_id = unique(JOINTS$cc_id)
l_unique_cc_id = length(unique_cc_id)
data_mat=matrix(NA, l_unique_cc_id, l_unique_cc_id)
rownames(data_mat) = colnames(data_mat) = unique_cc_id

for (ind in 5:9) {
  for (c1 in 1:l_unique_cc_id) {
    for (c2 in 1:l_unique_cc_id) {
      if (c1!=c2) {
        data = JOINTS[JOINTS$cc_id == unique_cc_id[c1] | JOINTS$cc_id == unique_cc_id[c2], ]
        data$strainind[data$cc_id == unique_cc_id[c1]] = 0
        data$strainind[data$cc_id == unique_cc_id[c2]] = 1
        data_mat[c1, c2]=summary(lm(data[ ,ind]~strainind+groupind+strainind*groupind, data=data))$coef[4, 4]
      }
    }
  }
  mat_name = gsub(" ", "_", names(JOINTS)[ind])
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
# for (cc in unique(JOINTS$cc_id)) {
#   for (g in unique(JOINTS$gender)) {
#     JOINTS[JOINTS$cc_id == cc & JOINTS$gender == g & JOINTS$group == "I", 4:8] =
#       JOINTS[JOINTS$cc_id == cc & JOINTS$gender == g & JOINTS$group == "I", 4:8] - rbind(JOINTS[JOINTS$cc_id == cc & JOINTS$gender == g & JOINTS$group == "C", 4:8], JOINTS[JOINTS$cc_id == cc & JOINTS$gender == g & JOINTS$group == "C", 4:8])
#   }
# }
# JOINTS_DIFF = JOINTS[JOINTS$group == "I", ]
# JOINTS_DIFF = subset(JOINTS_DIFF, select = - group)
# # Remove rows with all NAs.
# JOINTS_DIFF = JOINTS_DIFF[!(is.na(JOINTS_DIFF$`Adapted overall score (including all criteria)`) & is.na(JOINTS_DIFF$`Synovial hyperplasia`) & is.na(JOINTS_DIFF$`Exudate within joint and/or tendon sheath`) & is.na(JOINTS_DIFF$`Superficial inflammation of bone`) & is.na(JOINTS_DIFF$`Overall inflammation (whole tissue)`)), ]
# write.csv(JOINTS_DIFF,'cleaned_JOINTS_DIFF.csv')
# # Take strain IDs
# cc_ids = unique(JOINTS_DIFF$cc_id)
# l_cc_id = length(cc_ids)
# # Generate p_value mat for inter-sex comparison
# p_value_mat = data.frame(matrix(NA, nrow = l_cc_id, ncol = 5))
# for (ind in 3:7) {
#   for (cc in 1:l_cc_id) {
#     skip_to_next <- FALSE
#     p_value_mat[cc, (ind - 2)] = as.numeric(tryCatch(t.test(as.numeric(JOINTS_DIFF[JOINTS_DIFF$cc_id == cc_ids[cc] & JOINTS_DIFF$gender == "M", ind]), as.numeric(JOINTS_DIFF[JOINTS_DIFF$cc_id == cc_ids[cc] & JOINTS_DIFF$gender == "F", ind]), alternative = "two.sided", paird = F)$p.value, error = function(e) {skip_to_next <- NA}))
#     if(is.na(skip_to_next)) {next}     
#   }
# }
# # Put on feature names and strain IDs
# colnames(p_value_mat) = names(JOINTS_DIFF)[3:7]
# rownames(p_value_mat) = cc_ids
# # Remove rows with all NAs.
# p_value_mat = p_value_mat[!(is.na(p_value_mat$`Adapted overall score (including all criteria)`) & is.na(p_value_mat$`Synovial hyperplasia`) & is.na(p_value_mat$`Exudate within joint and/or tendon sheath`) & is.na(p_value_mat$`Superficial inflammation of bone`) & is.na(p_value_mat$`Overall inflammation (whole tissue)`)), ]
# # Transpose for display
# t_p_value_mat = t(p_value_mat)
# write.csv(t_p_value_mat,'intersex_JOINTS.csv')
# assign("intersex_JOINTS_heatmap",
#        heatmaply(t_p_value_mat, dendrogram = "none",
#                  main = "Intersex p-value for JOINTS",
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
# saveWidget(intersex_JOINTS_heatmap, file = "intersex_JOINTS.html")
# 
# # Generate overall inter-sex p-value
# p_value_vec = data.frame(matrix(NA, 1, 5))
# average_vec = matrix(NA, 2, 5)
# rownames(average_vec) = c("M", "F")
# average_vec = data.frame(average_vec)
# 
# for (ind in 3:7) {
#   skip_to_next <- FALSE
#   p_value_vec[1, (ind - 2)] = as.numeric(tryCatch(t.test(as.numeric(JOINTS_DIFF[JOINTS_DIFF$gender == "M", ind]), as.numeric(JOINTS_DIFF[JOINTS_DIFF$gender == "F", ind]), alternative = "two.sided", pair = F)$p.value, error = function(e) {skip_to_next <- NA}))
#   average_vec[1, (ind - 2)] = mean(as.numeric(JOINTS_DIFF[JOINTS_DIFF$gender == "M", ind]), na.rm = TRUE)
#   average_vec[2, (ind - 2)] = mean(as.numeric(JOINTS_DIFF[JOINTS_DIFF$gender == "F", ind]), na.rm = TRUE)
#   if(is.na(skip_to_next)) {next}     
# }
# colnames(p_value_vec) = colnames(average_vec) = names(JOINTS_DIFF)[3:7]
# write.csv(p_value_vec,'intersex_JOINTS_overall.csv')
# write.csv(average_vec, 'JOINTS_average_by_sex.csv')
# 
# # Calculate pairwise p-values
# p_value_pairwise = array(NA, c(l_cc_id, l_cc_id, 5))
# for (ind in 3:7) {
#   for (cc_1 in 1:l_cc_id) {
#     for (cc_2 in 1:l_cc_id) {
#     skip_to_next <- FALSE
#     p_value_pairwise[cc_1, cc_2, (ind - 2)] = as.numeric(tryCatch(t.test(as.numeric(JOINTS_DIFF[JOINTS_DIFF$cc_id == cc_ids[cc_1], ind]), as.numeric(JOINTS_DIFF[JOINTS_DIFF$cc_id == cc_ids[cc_2], ind]), alternative = "two.sided", pair = F)$p.value, error = function(e) {skip_to_next <- NA}))
#     if(is.na(skip_to_next)) {next}     
#     }
#   }
# }
# # Visualize pairwise p-values by heatmap
# for (ind in 3:7) {
#   data_mat = p_value_pairwise[ , , (ind - 2)]
#   cp = rowSums(is.na(data_mat)) != ncol(data_mat)
#   data_mat = data_mat[cp, cp]
#   rownames(data_mat) = colnames(data_mat) = cc_ids
#   mat_name = gsub(" ", "_", names(JOINTS_DIFF)[ind])
#   mat_name = gsub("/", "_", mat_name)
#   write.csv(data_mat, paste0(mat_name, ".csv"))
#   assign(mat_name,
#   heatmaply(data_mat, dendrogram = "none",
#           main = paste0("Pair-wise p-value for ", mat_name),
#           margins = c(60,100,40,20),
#           grid_color = "white",
#           grid_width = 0.00001,
#           titleX = TRUE,
#           hide_colorbar = FALSE,
#           branches_lwd = 0.1,
#           label_names = c("Row strain:", "Column strain:", "p-value:"),
#           fontsize_row = 10, fontsize_col = 10,
#           labCol = colnames(data_mat),
#           labRow = rownames(data_mat),
#           heatmap_layers = theme(axis.line=element_blank())
# ))
#   saveWidget(get(mat_name), file = paste0(mat_name, ".html"))
# }
# average_p_value = matrix(NA, l_cc_id, l_cc_id)
# for (i in 1:l_cc_id){
#   for (j in 1:l_cc_id){
#     average_p_value[i, j] = mean(p_value_pairwise[i,j,], na.rm = TRUE)
#   }
# }
# colnames(average_p_value) = rownames(average_p_value) = cc_ids
# write.csv(average_p_value, "average_p_value_JOINTS.csv")
# assign("average_p_value_heatmap",
#        heatmaply(average_p_value, dendrogram = "none",
#                  main = "Average p-value for JOINTS",
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
# saveWidget(average_p_value_heatmap, file = "average_p_value_JOINTS.html")
