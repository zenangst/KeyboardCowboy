#!/bin/zsh

RED='\033[0;31m'
GREEN='\033[0;32m'
LIGHT_PURPLE='\e[1;35m'
NC='\033[0m' # No Color

PIPELINE_PATH="Scripts/release_pipeline"
PIPELINE=`ls -1 $PIPELINE_PATH`

sh configure.sh

for x in $PIPELINE
do
  printf "${LIGHT_PURPLE}Running:${NC} $x\n"
  OUTPUT=`sh $PIPELINE_PATH/$x`

  if [ $? -eq 0 ]
  then
    printf "$OUTPUT"
    printf "\n"
    echo "${GREEN}Succeeded:${NC} $x\n" >&2
  else
    echo "${RED}Failed:${NC}\n" >&2
    echo "Re-run the failed step:\n\n >\t sh $PIPELINE_PATH/$x\n\n"
    break
  fi
done
