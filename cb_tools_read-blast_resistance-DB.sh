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
dependency()
{
echo -e "${YEL}                                               _____________________________${NC}"
echo -e "${YEL}______________________________________________/ Created by Christian Brandt \___${NC}"
echo " "
#checking for CPU and if commands are available
    blast_path=$(which cb_update_database.sh)
    blast_db=$(dirname "$blast_path")
    if [ -d "${blast_db}/db_bioprj_313047/" ]
      then echo -e "${GRE}database found${NC}"
      else echo -e  "${RED}database not found${NC}"
    fi
    echo "  Path to database:       $blast_db/db_bioprj_313047/resistance_db"
    CPU=$(lscpu -p | egrep -v '^#' | wc -l)
    echo "  Detected CPU cores:     $CPU"
    type blastn >/dev/null 2>&1 || { echo -e >&2 "${RED}blastn not found. Aborting.${NC}"; exit 1; }
    echo "  blastn identified"
    echo "________________________________________________________"
    echo "applying skript to the follwoing fastq read files:"
    ls *.fastq
    echo " "
}

converting()
{
  echo "Converting fastq to fasta..."
  for x in *.fastq; do sed -n '1~4s/^@/>/p;2~4p' $x > ${x%.fastq}.fasta ; done
  echo "Removing Reads smaller than 1000bp..."
  for x in *.fasta; do sed ':a;N;/^>/M!s/\n//;ta;P;D' $x > ${x%.fasta}_oneliner.fasta ; done
  for x in *_oneliner.fasta; do awk '/^>/ { getline seq } length(seq) >1000 { print $0 "\n" seq }' $x > ${x%_oneliner.fasta}_clean.fasta ; done
  echo -e "${YEL}Amount of Reads after converting:${NC}"
  grep -c ">" *.fasta
}

blast_reads()
{
  echo "________________________________________________________"
  for x in *_clean.fasta ; do
    echo -e "${GRE}Blasting the following reads: $x ${NC}"
    echo "$x"
      blastn -query $x -db $blast_db/db_bioprj_313047/resistance_db -out ${x%_clean.fasta}.blast -outfmt "6 qseqid length stitle evalue mismatch" -num_threads $CPU -culling_limit 1 -evalue 10E-70
  done
}

############################
# Start of script          #
############################
dependency
  read -p "Everything correct? [yes/no]: " yn
      case $yn in
          [Yy]* ) converting ; blast_reads ;;
          [Nn]* ) echo "Exiting script, bye bye"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
