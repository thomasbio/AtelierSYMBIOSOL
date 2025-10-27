rm(list=ls())  #Clean memory

library(Tax4Fun2) #import library

setwd("~/OneDrive - Université Laval/Trabalho/Cours/Ateliers_Bioinformatique/Atelier2_Funguild/data_Tax4Fun2/")  # central path


# 1. Run the reference blast

runRefBlast(path_to_otus = "dna-sequences.fasta", 
            path_to_reference_data = "~/Documents/Tax4Fun2_ReferenceData_v2/", 
            path_to_temp_folder = "Ref99NR", 
            database_mode = "Ref99NR",
            use_force = T, num_threads = 24)
            
            
# 2) Predicting functional profiles

# O documento precisa ser convertido em tsv.

table <- read.delim("~/Library/CloudStorage/OneDrive-UniversitéLaval/Trabalho/Cours/Ateliers_Bioinformatique/Atelier2_Funguild/data_Tax4Fun2/otu_table_2.txt")

#"#OTU_ID"	
write.table(x = table[-length(table)],file = "otu_table_tax4fun.tsv",sep = "\t")

makeFunctionalPrediction(path_to_otu_table = "otu_table_tax4fun.tsv", 
                         path_to_reference_data = "~/Documents/Tax4Fun2_ReferenceData_v2/", 
                         path_to_temp_folder = "./Ref99NR", 
                         database_mode = "Ref99NR", 
                         normalize_by_copy_number = TRUE, 
                         min_identity_to_reference = 0.99, normalize_pathways = TRUE)


#Step 4: Calculating (multi-)functional redundancy indices (experimental)
#calculates phylogentic distributions of KEGG functions (High FRI -> high redundancy, low FRI -> function is less redundant and #might get lost with community change)

####VERY LONG#####

calculateFunctionalRedundancy(path_to_otu_table = "./otu_table_tax4fun.tsv", 
                              path_to_reference_data = "~/Documents/Tax4Fun2/Tax4Fun2_ReferenceData_v2/", 
                              path_to_temp_folder = "Ref99NR", 
                              database_mode = "Ref99NR", 
                              min_identity_to_reference = 0.99)



