module load miniconda3
source activate qiime2-2019.10


echo 'importing'

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path ../seqs/ \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path ./demux-pairedend-end.qza

echo 'cutadapt'

qiime cutadapt trim-paired \
  --i-demultiplexed-sequences ./demux-pairedend-end.qza \
  --p-cores 8\
  --p-anywhere-f 'GTGTCAGCMGCCGCGGTAA'\
  --p-anywhere-r 'CCGYCAATTTYMTTTRAGTTT'\
  --output-dir cutadapt_out/

echo 'dada2'
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ./cutadapt_out/trimmed_sequences.qza \
  --p-trunc-len-f 270 \
  --p-trunc-len-r 120 \
  --p-chimera-method 'consensus' \
  --p-n-threads 8 \
  --p-min-fold-parent-over-abundance 2\
  --verbose \
  --o-representative-sequences ./dada2-paired-end-rep-seqs.qza \
  --o-table ./dada2-paired-end-table.qza \
  --o-denoising-stats ./dada2-paired-end-stats.qza


echo ' tabulate'

qiime metadata tabulate \
  --m-input-file dada2-paired-end-stats.qza \
  --o-visualization dada2-paired-end-stats.qzv

echo 'phylo_tree'

qiime alignment mafft \
  --p-n-threads 'auto' \
  --p-parttree \
  --i-sequences dada2-paired-end-rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza

qiime alignment mask \
  --i-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza

qiime phylogeny fasttree \
  --i-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza

qiime phylogeny midpoint-root \
  --i-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

echo 'assign taxonomy'

qiime feature-classifier classify-sklearn \
  --i-classifier silva-138-99-nb-classifier.qza \
  --i-reads dada2-paired-end-rep-seqs.qza \
  --p-n-jobs -1 \
  --p-read-orientation 'auto' \
  --o-classification silva_taxonomy-paired-end.qza \
  --verbose
  
qiime feature-classifier classify-sklearn \
  --i-classifier gg_2022_10_backbone_full_length.nb.qza \
  --i-reads dada2-paired-end-rep-seqs.qza \
  --p-n-jobs -1 \
  --p-read-orientation 'auto' \
  --o-classification greengenes2_taxonomy-paired-end.qza \
  --verbose
  
  
qiime feature-classifier classify-sklearn \
  --i-classifier ./full-length-soil-non-saline-classifier.qza\
  --i-reads dada2-paired-end-rep-seqs.qza \
  --p-reads-per-batch 'auto' \
  --p-n-jobs -1 \
  --p-read-orientation 'auto' \
  --o-classification weigted_soil_taxonomy-paired-end.qza \
  --verbose
  
  
  

echo 'Exporting'

qiime tools export --input-path dada2-paired-end-table.qza --output-path exported
qiime tools export --input-path taxonomy-paired-end.qza --output-path exported
qiime tools export --input-path dada2-paired-end-rep-seqs.qza --output-path exported

unzip -p rooted-tree.qza > exported/exportd_rooted_tree.tre

sed -i.tsv "1 s/^.*$/'#OTUID   taxonomy    confidence'/" exported/taxonomy.tsv

biom add-metadata \
  -i exported/feature-table.biom \
  -o exported/feature-table-w-taxonomy.biom \
  --observation-metadata-fp exported/taxonomy.tsv.tsv \
  --observation-header OTUID,taxonomy,confidence \
  --sc-separated taxonomy

biom convert \
-i exported/feature-table-w-taxonomy.biom \
-o exported/otu_table.txt \
--to-tsv --header-key taxonomy --table-type="OTU table"



echo 'END'
