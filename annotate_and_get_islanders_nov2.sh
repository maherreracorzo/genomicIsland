#!/bin/sh
#SBATCH --account=plantpath
#SBATCH --qos=plantpath-b
#SBATCH --job-name=ah_job_from_prokka_nov2 # job name
#SBATCH --mail-type=END,FAIL # mail events
#SBATCH --mail-user=marianaherreraco@ufl.edu  # where to send
#SBATCH --nodes=1   # one node
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8g
#SBATCH --time=96:00:00  ##time limit
#SBATCH --output=ah_%j.out  #standard error output and error

ml prokka
ml perl
ml bedtools
ml seqtk
ml alienhunter/1.7


results = "$(date +"%Y-%m-%d")"
##DELETING INTERMEDIATE FILES

#DELETE BED
cd bed
rm *
mkdir -p $results
cd ..

#DELETE GFF
cd gff
rm *_islanders.gff
mkdir -p $results
cd ..

#DELETE TAB
cd tab
rm *
mkdir -p $results
cd ..

#DELETE CONTIGS FASTA
cd contigsFasta
rm *
mkdir -p $results
cd ..

##CREATING RESULTS FOLDER
cd faa
mkdir -p $results
cd ..

#SETTING UP LOGGER FILE
echo "" > run_log.txt

echo "PROGRAM BEGINS"
echo "PROGRAM BEGINS" >> run_log.txt

#CHANGE TO PARENT DIRECTORY
#cd ..

##list1 is a list of the name of your genomes
cat All_Xp_Strains.txt | while read x
do

echo "ITERATION $x"
echo "ITERATION $x" >> run_log.txt;
x=`echo $x | sed 's/\\r//g'`
	
##concatenate contigs
#ls $x".fasta"
#sed 's/^>.*$/NNN/g' $x".fasta" | awk 'BEGIN { ORS=""; print ">contigs\n" } { print }' > $x"cat_contigs.fasta"

##prokka
#x=`echo $x | sed 's/\\r//g'`
#prokka --cpus 8 --locustag $x --outdir "prokka_"$x --prefix ${x} ${x}cat_contigs.fasta

##alien_hunter

#alien_hunter ${x}cat_contigs.fasta ${x}

##grep the genes overlappimg the islands

grep misc_feature alienHunt/${x} | sed 's/\../\t/g' | sed 's/FT/contigs/g' |sed 's/\misc_feature/\t/g' | sed 's/ //g' >  bed/${x}island.bed
 

cat /blue/goss/marianaherreraco/alien_hunter-1.7/Concat_annot_ah/Prokka/prokka_${x}/${x}.gff | grep -v '#'|grep '^contigs' | cut -f 1,4,5,9 > /blue/goss/marianaherreraco/alien_hunter-1.7/Concat_annot_ah/Prokka/prokka_${x}/${x}_1.gff

bedtools intersect -a Prokka/prokka_${x}/${x}_1.gff -b bed/${x}island.bed > gff/${x}_islanders.gff


cat gff/${x}_islanders.gff | cut -f 4 | cut -f 1 -d ";" | sed 's/ID=//g' > tab/${x}_islanders_ID.tab
sort tab/${x}_islanders_ID.tab | uniq  > tab/${x}_islandersuniq.tab
seqtk subseq Prokka/prokka_${x}/${x}.faa  tab/${x}_islandersuniq.tab > ./faa/${results}/${x}_islanders_ID.faa

echo "ITERATION END FOR $x"
echo "ITERATION END FOR $x" >> run_log.txt

done

echo "PROGRAM FINISHED"
echo "PROGRAM FINISHED :)" >> run_log.txt

