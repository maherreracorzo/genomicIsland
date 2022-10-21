#!/bin/sh
#SBATCH --account=plantpath
#SBATCH --qos=plantpath-b
#SBATCH --job-name=ah_job_example_jun23 # job name
#SBATCH --mail-type=END,FAIL # mail events
#SBATCH --mail-user=marianaherreraco@ufl.edu  # where to send
#SBATCH --nodes=1   # one node
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8g
#SBATCH --time=24:00:00  ##time limit
#SBATCH --output=ah_%j.out  #standard error output and error

ml prokka
ml perl
ml bedtools
ml seqtk
ml alienhunter/1.7

#SETTING UP LOGGER FILE
echo "" > run_log.txt

echo "PROGRAM BEGINS"
echo "PROGRAM BEGINS" >> run_log.txt

#CHANGE TO PARENT DIRECTORY
cd ..

##list1 is a list of the name of your genomes
cat ./All_Xp_Strains.txt | while read x
do

echo "ITERATION $x"
echo "ITERATION $x" >> ./genomicIsland/run_log.txt;


##concatenate contigs
#ls $x".fasta"
#sed 's/^>.*$/NNN/g' $x".fasta" | awk 'BEGIN { ORS=""; print ">contigs\n" } { print }' > $x"cat_contigs.fasta"

##prokka
prokkafile=`echo "replacecat_contigs.fasta" | sed -r 's/replace/'${x}'/g'`
echo "$prokkafile"
prokka --cpus 8 --locustag $x --outdir "prokka_"$x --prefix ${x} $prokkafile

##alien_hunter

alien_hunter ${x}cat_contigs.fasta ${x}

##grep the genes overlappimg the islands

grep mis ${x}.sco | sed 's/\../\t/g' | sed 's/FT/contigs/g' |sed 's/\misc_feature/\t/g' | sed 's/ //g' >  ${x}island.bed
 

cat /blue/goss/marianaherreraco/alien_hunter-1.7/Concat_annot_ah/examplejun23/prokka_${x}/${x}.gff | grep -v '#'|grep '^contigs' | cut -f 1,4,5,9 > /blue/goss/marianaherreraco/alien_hunter-1.7/Concat_annot_ah/examplejun23/prokka_${x}/${x}_1.gff

bedtools intersect -a prokka_${x}/${x}_1.gff -b ${x}island.bed > ${x}_islanders.gff


cat ${x}_islanders.gff | cut -f 4 | cut -f 1 -d ";" | sed 's/ID=//g' > ${x}_islanders_ID.tab
sort ${x}_islanders_ID.tab | uniq  > ${x}_islandersuniq.tab
seqtk subseq prokka_${x}/${x}.faa  ${x}_islanders_ID.tab > ${x}_islanders_ID.faa

echo "ITERATION END FOR $x"
echo "ITERATION END FOR $x" >> ./genomicIsland/run_log.txt

done

echo "PROGRAM FINISHED"
echo "PROGRAM FINISHED :)" >> ./genomicIsland/run_log.txt
