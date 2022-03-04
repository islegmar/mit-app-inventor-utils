#!/bin/bash

# =================================================
# Variables
# =================================================
silent=0
tmpFile=/tmp/$(basename $0)
dirOut=./data/out
fileIn=./data/blocks.png
fileOut=./doc.pdf
doSplit=0
doCompose=0

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Split a single image in individual blocks

SYNOPSIS
       `basename $0` [-s] [-h] [-d out_dir] [-f input_image] [-o output_file] [-S] [-C]

DESCRIPTION
       INFO

       -s
              Silent mode

       -h
              Show this help

       -f input_image
              If -S, file with the image of all the blocks downloaded from the site (def: $fileIn)

       -d our_dir
              Folder where the single images are kept (def: $dirOut)

       -o output_file
              If -C, output file with the images (def: $fileOut)

       -S
              Split the image (it takes time)

       -C
              Compose a document with all the splitted images
EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $* >&2
}

# =================================================
# Arguments
# =================================================
while getopts "hsSCf:o:d:" opt
do
  case $opt in
    h)
      help
      exit 0
      ;;
    s) silent=1 ;;
    S) doSplit=1 ;;
    C) doCompose=1 ;;
    f) fileIn=$OPTARG ;;
    o) fileOut=$OPTARG ;;
    d) dirOut=$OPTARG ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
shift $(( OPTIND - 1 ))

# --- Check Arguments
errors=""

[[ -z "$dirOut" ]] && errors="${errors}A folder must be specified. "
if [[ $doSplit -eq 1 && -z "$fileIn" ]] 
then
  errors="${errors}A file with the initial image must be specified. "
fi
if [[ $doCompose -eq 1 ]] 
then
  if [[ -z "$fileOut" ]] 
  then
    errors="${errors}An output file must be specified. "
  fi

  if [[ ! -d "$dirOut" ]] 
  then
    errors="${errors}The output folder ${dirOut} does not exists. "
  fi
fi

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================
rm ${tmpFile}* 2>/dev/null

if [[ $doSplit -eq 1 ]]
then
  [[ ! -d ${dirOut} ]] && mkdir -p ${dirOut}
  
  if [ $silent -eq 0 ]
  then
    ./split.sh -i $fileIn -d $dirOut
  else
    ./split.sh -s -i $fileIn -d $dirOut
  fi
  echo "Image ${fileIn} splitted in ${dirOut}!"
fi

if [[ $doCompose -eq 1 ]]
then
  [[ -f ${fileOut} ]] && rm ${fileOut}
  rm ${dirOut}/new_*.png 2>/dev/null
  # TODO : this should be a parameter but let's suppose the final canvas is 
  # an A4 8.27 × 11.69 inches with resolution 300 ppi (we leave some borders)
  resolution=300
  canvasW=$(echo "8.27*$resolution"|bc -l)
  canvasH=$(echo "11.69*$resolution"|bc -l)
  imageW=$(echo "${canvasW} * 0.95"|bc -l)
  imageH=$(echo "${canvasH} * 0.95"|bc -l)
  for f in $(find ${dirOut} -name '*.png')
  do
    convert $f{} -resize ${imageW}x${imageH} -background white -gravity center -extent ${canvasW}x${canvasH} ${dirOut}/new_$(basename $f) 
  done

  convert ${dirOut}/new_*.png ${fileOut}
  echo "File ${fileOut} created!"
fi

rm ${tmpFile}* 2>/dev/null

