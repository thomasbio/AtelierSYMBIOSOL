module load miniconda3
source activate qiime2-2019.10


echo 'importing'

#qiime tools import \
#  --type 'SampleData[PairedEndSequencesWithQuality]' \
#  --input-path /home/tgumiere/project/tgumiere/ITS/sequences/ \
#  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
#  --output-path demux-single-end.qza

echo 'trim'

#qiime cutadapt trim-paired \
#  --i-demultiplexed-sequences demux-single-end.qza \
#  --p-adapter-f AATGATACGGCGACCACCGAGATCTACAC \
#  --p-front-f CTTGGTCATTTAGAGGAAGTAA \
#  --p-adapter-r CAAGCAGAAGACGGCATACGAGAT \
#  --p-front-r GCTGCGTTCTTCATCGATGC \
#  --o-trimmed-sequences demux-trimmed.qza

echo 'dada2'
#qiime dada2 denoise-paired \
#  --i-demultiplexed-seqs demux-trimmed.qza \
#  --p-trim-left-f 36 \
#  --p-trim-left-r 36 \
#  --p-trunc-len-f 200 \
#  --p-trunc-len-r 200 \
#  --p-chimera-method 'consensus' \
#  --p-n-threads 12 \
#  --verbose \
#  --o-representative-sequences dada2-paired-end-rep-seqs.qza \
#  --o-table dada2-paired-end-table.qza \
#  --o-denoising-stats dada2-paired-end-stats.qza


echo ' tabulate'

#qiime metadata tabulate \
#  --m-input-file dada2-paired-end-stats.qza \
#  --o-visualization dada2-paired-end-stats.qzv

echo 'phylo_tree'

#qiime alignment mafft \
#  --i-sequences dada2-paired-end-rep-seqs.qza \
#  --o-alignment aligned-rep-seqs.qza

#qiime alignment mask \
#  --i-alignment aligned-rep-seqs.qza \
#  --o-masked-alignment masked-aligned-rep-seqs.qza

#qiime phylogeny fasttree \
#  --i-alignment masked-aligned-rep-seqs.qza \
#  --o-tree unrooted-tree.qza

#qiime phylogeny midpoint-root \
#  --i-tree unrooted-tree.qza \
#  --o-rooted-tree rooted-tree.qza

echo 'assign taxonomy'

qiime feature-classifier classify-sklearn \
  --i-classifier /home/tgumiere/project/tgumiere/data_base_qiime/ITS_Unite_classifier/unite-ver8-99-classifier-02.02.2019.qza \
  --i-reads dada2-paired-end-rep-seqs.qza \
  --p-n-jobs -1 \
  --p-read-orientation 'auto' \
  --o-classification taxonomy-paired-end.qza

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
