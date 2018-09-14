#!/bin/bash
#!/usr/bin/bash
BLU='\033[0;34m'
GRE='\033[0;32m'
YEL='\033[0;33m'
RED='\033[0;31m'
LRED='\033[0;91m'
LGRE='\033[0;92m'
NC='\033[0m' # No Color
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
IP=$(cat $SCRIPTPATH/cfg)

rename()
{
for x in *
do 
new_filename=$(echo "$x" | sed 's/-/\./' | sed 's/-/\./' | sed 's/-/\./')
mv $x $new_filename 2>/dev/null
done
}

###Scriptstart###
files=$(ls .)
echo -e "${RED}$files ${NC}"
echo " "  
echo -e "Change ${YEL}-${NC} to ${YEL}.${NC} in these filenames?"
read -p "Answer [yes] or [no]" yn
case $yn in
    [Yy]* ) rename;;
    [Nn]* ) echo "Exiting script, bye bye"; exit;;
        * ) echo "Please answer yes or no.";;
esac
