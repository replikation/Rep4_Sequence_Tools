#!/bin/bash
#!/usr/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
#scriptname
SCRIPTNAME=$(basename -- "$0")
RED='\033[0;31m'
BLU='\033[0;34m'
GRE='\033[0;32m'
YEL='\033[0;33m'
NC='\033[0m' # No Color
###############
##  Modules  ##
###############
Userinput()
{
echo -e "${YEL}Please state what beta-lactamase you want to analyse${NC}"
echo "Write the name in all captial letters (e.g. SHV or TEM)"
read userinput_bla
echo "Give the reference sequence (e.g. SHV-1 or TEM-1)"
read userinput_bla_reference
echo " "
}

dependencies()
{
echo -e "${YEL}Checking if dependencies can be found:${NC}"
type esearch >/dev/null 2>&1 || { echo -e >&2 "${RED}esearch not found. Aborting.${NC}"; exit 1; }
    echo "esearch identified"
type clustalo >/dev/null 2>&1 || { echo -e >&2 "${RED}clustalo not found, install with 'sudo apt install clustalo'. Aborting.${NC}"; exit 1; }
    echo "clustalo identified"
type showalign >/dev/null 2>&1 || { echo -e >&2 "${RED}showalign not found, its part of EMBOSS. Aborting.${NC}"; exit 1; }
    echo "showalign identified"
echo " "
} 

download()
{
    echo "downloading all CDS of 313047[BioProject] to "
    echo "$SCRIPTPATH/temp_sequences_storage/coding_regions.fasta"
    mkdir -p $SCRIPTPATH/temp_sequences_storage/ 2> /dev/null
    rm $SCRIPTPATH/temp_sequences_storage/* 2> /dev/null
    esearch -db nucleotide -query "313047[BioProject]" | efetch -format fasta_cds_aa > $SCRIPTPATH/temp_sequences_storage/coding_regions.fasta
    #Location of files (as temp data
    echo "download complete"
}

one_liner_fasta()
{
sed -e 's/\(^>.*$\)/#\1#/' $SCRIPTPATH/temp_sequences_storage/coding_regions.fasta | tr -d "\r" | tr -d "\n" | sed -e 's/$/#/' | tr "#" "\n" | sed -e '/^$/d' > $SCRIPTPATH/temp_sequences_storage/oneliner.fasta
}

get_userinput_blas()
{
grep -A1 --no-group-separator "bla$userinput_bla" $SCRIPTPATH/temp_sequences_storage/oneliner.fasta > $SCRIPTPATH/temp_sequences_storage/$userinput_bla.fasta
}

alignment()
{
echo "Aligning...."
clustalo --force --wrap=2000 -i $SCRIPTPATH/temp_sequences_storage/${userinput_bla}.fasta -o $SCRIPTPATH/temp_sequences_storage/${userinput_bla}_align.fasta
echo "done" 
#get reference number for pretty alignment using the userinput
acc_ref_number=$(grep -w "$userinput_bla_reference" $SCRIPTPATH/temp_sequences_storage/${userinput_bla}.fasta | cut -f1 -d " " | cut -f2 -d "|")
#make alignment pretty
showalign -show=N -sequence $SCRIPTPATH/temp_sequences_storage/${userinput_bla}_align.fasta  -outfile $SCRIPTPATH/temp_sequences_storage/${userinput_bla}_align.showalign -refseq $acc_ref_number -width 2000 -nosimilarcase
}

converting()
{
echo "creating excel file"
alignment=$(tail -n+3 $SCRIPTPATH/temp_sequences_storage/${userinput_bla}_align.showalign) #add user input to SHV
echo "name;broad spectrum;extended spectrum;inhibitor resistant;" > $SCRIPTPATH/${userinput_bla}_results.csv #add userinput to filename
        
while IFS='' read -r line || [[ -n "$line" ]]; do
    accnumber=$(echo "$line" | cut -f1 -d" ")
    sequence=$(echo "$line" | cut -f2 -d" ")
    bla_type=$(grep -w "$accnumber" $SCRIPTPATH/temp_sequences_storage/${userinput_bla}.fasta | cut -f3 -d"]" | rev | cut -f1 -d " " | rev)
    seq_description=$(grep -w "$accnumber" $SCRIPTPATH/temp_sequences_storage/${userinput_bla}.fasta)
    if grep -wq "extended" <<< "$seq_description"; then extended=extended; else extended=" "; fi
    if grep -wq "inhibitor-resistant" <<< "$seq_description"; then inhibR=inhibitor-resistant; else inhibR=" "; fi
    if grep -wq "broad-spectrum" <<< "$seq_description"; then broad_spectrum=broad-spectrum; else broad_spectrum=" "; fi
    modified_sequence=$(echo "$sequence" | awk '$1=$1' FS= OFS=";")
echo "$bla_type;$broad_spectrum;$extended;$inhibR;$modified_sequence" >> $SCRIPTPATH/${userinput_bla}_results.csv
                       
done < <(printf '%s\n' "$alignment")
echo -e "${GRE}Results saved under $SCRIPTPATH/${userinput_bla}_results.csv ${NC}"  
}



############################
# Start of script OUTERLOOP#
############################
echo "                                               _____________________________"
echo "______________________________________________/ Created by Christian Brandt \___"
echo " "
while true; do
    echo -e "${YEL}This tool creates excel sheets to view Pointmutations.${NC}"
    echo "What do you want to do? [f] [d] [a] [e]"
    read -p "full_pipeline[f] download_only[d] analysis_only[a] exit[e]: " fdae
    case $fdae in
        [Ff]* ) dependencies; Userinput; download; one_liner_fasta; get_userinput_blas; alignment; converting; break;;
        [Dd]* ) download; break;;
        [Aa]* ) dependencies; Userinput; one_liner_fasta; get_userinput_blas; alignment; converting; break;;
        [Ee]* ) echo "  Exiting script, bye bye"; exit;;
        * ) echo "  Please answer [f] [d] [a] or [e].";;
    esac
done
