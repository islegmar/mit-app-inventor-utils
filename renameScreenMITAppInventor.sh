#!/bin/bash

# =================================================
# Variables
# =================================================
silent=0
tmpFile=/tmp/$(basename $0)
tmpDir=/tmp/$(basename $0).dir
fSrc="/home/islegmar/Escritorio/ICanBelieveIt.aia"
fDst="/home/islegmar/Escritorio/ICanBelieveIt.new.aia"
oldName="Screen1"
newName="scPlay"
# Actions
doUnzip=0
doZip=0
doChange=0
doClean=0
doAll=0

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - In a MIT App Invetor project renames a screen

SYNOPSIS
       `basename $0` [-s] [-h] [-u] [-z] [-c] [-C] -f src_ai_file -d dst_ai_file -o old_screen_name -n new_screen_name

DESCRIPTION
       STILL UNDER DEVELOPMENT

       -s
              Silent mode

       -h
              Show this help

       -a
              Do all actions below
      
       -u
              Unzip
      
       -z
              Zip
      
       -c
              Change
      
       -C
              Cleanup
EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $* >&2
}

# =================================================
# Arguments
# =================================================
while getopts "hsf:d:o:n:auzcC" opt
do
  case $opt in
    h)
      help
      exit 0
      ;;
    s) silent=1 ;;
    f) fSrc=$OPTARG ;;
    d) fDst=$OPTARG ;;
    o) oldName=$OPTARG ;;
    n) newName=$OPTARG ;;
    a) doAll=1 ;;
    u) doUnzip=1 ;;
    z) doZip=1 ;;
    c) doChange=1 ;;
    C) doClean=1 ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $(( OPTIND - 1 ))

# --- Check Arguments
errors=""

[[ -z "$fSrc" ]] && errors="${errors}A source ai file must be specified. "
[[ -z "$fDst" ]] && errors="${errors}A destination ai file must be specified. "
[[ -z "$oldName" ]] && errors="${errors}A old screen name must be specified. "
[[ -z "$newName" ]] && errors="${errors}A new screen name must be specified. "

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================
if [[ $doAll -eq 1 || $doClean -eq 1 ]]
then
  echo ">>> Clean"
  rm     ${tmpFile}*   2>/dev/null
  rm -fR ${tmpDir}*    
  [[ -f ${fDst} ]] && rm ${fDst}
fi

if [[ $doAll -eq 1 || $doUnzip -eq 1 ]]
then
  echo ">>> Unzip"
  unzip $fSrc -d ${tmpDir}
fi

if [[ $doAll -eq 1 || $doChange -eq 1 ]]
then
  echo ">>> Change"
  pushd ${tmpDir} &>/dev/null
  # Rename string
  find . -type f -exec sed -i -e "s#${oldName}#${newName}#g" {} \;
  # Rename files
  for f in $(find . -type f -name ${oldName}'*')
  do
    ext=$(basename $f|cut -d '.' -f 2,2)
    old_file="$(dirname $f)/${oldName}.${ext}"
    new_file="$(dirname $f)/${newName}.${ext}"
    mv -v ${old_file} ${new_file}
  done
  popd &>/dev/null
fi

if [[ $doAll -eq 1 || $doZip -eq 1 ]]
then
  echo ">>> Zip"
  pushd ${tmpDir} &>/dev/null
  zip -r $fDst *
  echo "File created: ${fDst}!"
  popd &>/dev/null
fi

echo "tmpDir : ${tmpDir}"

# rm     ${tmpFile}* 2>/dev/null
# rm -fR ${tmpDir}   2>/dev/null

