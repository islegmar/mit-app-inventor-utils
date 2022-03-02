#!/bin/bash
# -u  Treat unset variables as an error when substituting.
set -u

# =================================================
# Variables
# =================================================
silent=0
image=""
dstDir=""
# If split done once
doSplitOnce=0
splitOnceMode="rows"

tmpDir="/tmp/$(basename $0).$$"
inDir="$tmpDir/in"
workDir="$tmpDir/work"
debugDir="$tmpDir/debug"

# Color used dor mark the empyt : white (FFFFFF) or black (000000)
COLOR_WHITE='#FFFFFF'
COLOR_BLACK='#000000'
COLOR_EMPTY=${COLOR_BLACK}

# =================================================
# Functions
# =================================================
function help() {
  cat<<EOF
NAME
       `basename $0` - Split an image in boxes containing the composed images, 
                       removing empty lines marked with the color : ${COLOR_EMPTY}

SYNOPSIS
       `basename $0` [-s] -i file -d dir [-S] [-m rows|cols]

DESCRIPTION
       Split an image in boxes containing the composed images, removing blanks

       -i file
              Image

       -d dir
              Folder where the images are stored

       -S
              Split is executed once. By default done until all white is removed

       -m R|C
              If the split is executed once, this is done in Rows or Columns (def: $splitOnceMode)

EOF
}

function trace() {
  [ $silent -eq 0 ] && echo $* >&2
}

function rebuildDir() {
  local _dir=$1

  [ -d ${_dir} ] && rm -fR ${_dir}
  [ ! -d ${_dir} ] && mkdir -p ${_dir}
}

# Given an image return a string containing the characters W and C 
# (eg. WWWCCCCWWCWWC) indicating (depending on mode) if the 
# ROWS/COLS are ALL White (W) or there are some non-white (C)
# This is useful for detecting "empty" ROWS/COLS and remove them (margins) 
# to know where we can split the image
function getImageWC() {
  local _image=$1
  local _mode=$2

  trace "getImageWC(${_image}, ${_mode})"

  local _str=""
  local _tmpFile="$tmpDir/getImageWC"

  local _tot=0
  case ${_mode} in
    # Colapse to one column
    rows) 
      _tot=$(identify -format "%h" ${_image}) 
      convert ${_image} -strip -resize "1x${_tot}!" ${_tmpFile}
      ;;
    # Colapse to one row
    *)    
      _tot=$(identify -format "%w" ${_image}) 
      convert ${_image} -strip -resize "${_tot}x1!" ${_tmpFile}
      ;;
  esac
  trace "  _tot : ${_tot}"

  # Loop through all rows/cols
  local _ind=0
  for ((_ind=0; _ind<_tot; _ind++))
  do
     local _num=0
     case ${_mode} in
       rows) _num=$(convert ${_tmpFile}[1x1+0+${_ind}] txt: | grep -v enumeration | grep -c "${COLOR_EMPTY}") ;;
       *)    _num=$(convert ${_tmpFile}[1x1+${_ind}+0] txt: | grep -v enumeration | grep -c "${COLOR_EMPTY}") ;;
     esac

     # trace "  _ind : ${_ind}, _num : ${_num}"

     if [ ${_num} -eq 1 ]
     then
       _str="${_str}W"
     else
       _str="${_str}C"
     fi
  done
   
  echo "${_str}"
}

# Given a string with W/C (eg. WWWCCCCWWCCWW) return the values of the limits at both sides with W;
# e.g "3 2" (there are 3 Whites in the beginning and 2 W at the end)
function getHeadTot() {
  local _str=$1

  local _frg=$(echo ${_str}|sed -e 's/\(^W*\).*/\1/')

  echo ${#_frg}
}

function getTailTot() {
  local _str=$1

  local _frg=$(echo ${_str}|rev|sed -e 's/\(^W*\).*/\1/')

  echo ${#_frg}
}

# Given an image, remove the empty blanks top/bottom/left/right
function removeMargins() {
  local _image=$1
  local _dstImage=$2

  local _rows=$(getImageWC $_image "rows")
  local _cols=$(getImageWC $_image "cols")

  # find the limits top, bottom, left, right
  local _top=$(getHeadTot $_rows)
  local _bottom=$(getTailTot $_rows)
  local _left=$(getHeadTot $_cols)
  local _right=$(getTailTot $_cols)

  convert $_image -strip -crop +${_left}+${_top} -crop -${_right}-${_bottom} $_dstImage
}

# Given an image, split in rows/columns and keep the non-white portions in dstDir
function splitImg() {
  local _image=$1
  local _mode=$2
  local _dstDir=$3

  # Get the name of the image (without extension) and the extension.
  # They will be used to generate the name of the files produced
  local _imgName="$_dstDir/$(basename $_image|sed -e 's/\..*//')"
  local _imgExt=$(basename $_image|sed -e 's/.*\.//')

  local _str=""
  case $_mode in
    rows) _str=$(getImageWC $_image "rows") ;;
    *)    _str=$(getImageWC $_image "cols") ;;
  esac

  # Make a copy or the image because we're goint to modify it
  local _myImg="$tmpDir/$(basename $image)"
  cp $_image $_myImg

  local _index=0
  while [ ${#_str} -ne 0 ]
  do
    # Get in _frg a chunk of characters that are equals.
    # Fex. if _str=WWCCCWWWW then
    # - _frg = WW (first chunck)
    # - _str = CCCWWWW (the rest)
    local _ch=${_str:0:1} 
    local _frg=$(echo $_str|sed -e "s/\(^${_ch}*\).*/\1/")
    _str=$(echo $_str|sed -e "s/^${_ch}*//")

    trace "frg:$_frg"

    # Block is non white => keep it
    if [ "$_ch" == "C" ]
    then
      local _file=${_imgName}-${_index}.${_imgExt}
      case $_mode in
        rows) convert $_myImg -strip -crop x${#_frg}+0+0 $_file ;;
        *)    convert $_myImg -strip -crop ${#_frg}x+0+0 $_file ;;
      esac
      _index=$(($_index+1)) 
    fi

    # Remove block from the original image
    case $_mode in
      rows) convert $_myImg -strip -chop 0x${#_frg}+0+0 $_myImg ;;
      *)    convert $_myImg -strip -chop ${#_frg}x0+0+0 $_myImg ;;
    esac
  done
}

# =================================================
# Arguments
# =================================================
while getopts "hsd:i:Sm:" opt
do
  case $opt in
    s) silent=1 ;;
    h)
      help
      exit 0
      ;;
    i) image=$OPTARG ;;
    d) dstDir=$OPTARG ;;
    S) doSplitOnce=1 ;;
    m) splitOnceMode=$OPTARG ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# --- Check Arguments
errors=""

if [[ -z "$image" ]]
then
  errors="${errors}An image must be specified. "
fi

if [[ -z "$dstDir" ]]
then
  errors="${errors}A folder must be specified. "
fi

if [[ ! -z "$errors" ]]
then
  trace $errors
  exit 1
fi

# =================================================
# main
# =================================================

rebuildDir $tmpDir
rebuildDir $inDir
rebuildDir $workDir
rebuildDir $debugDir
rebuildDir $dstDir

if [ $doSplitOnce -eq 1 ]
then
  splitImg $image $splitOnceMode $dstDir
else
  if [ $silent -eq 0 ]
  then
    cat<<EOD
in : $inDir
work : $workDir
tmp : $tmpDir
dst : $dstDir
EOD
  fi

  # The loop consist in 5 phases for every image
  # 1) Remove margins
  # 2) Split Rows
  #    - Changes : for every image repeat loop
  #    - No Chages:
  # 3) Split in Cols
  #    - Changes : for every image repeat loop
  #    - No Chages: Final image, ypu can keep it
  cp $image $inDir
  
  # There are folders used in the current process:
  # - inDir    : <tmp>/in
  # - workDir  : <tmp>/work
  # - debugDir : <tmp>/debug
  # - dstDir   : No temporary (parameter). It is where the final images will
  #              be kept.
  #
  # 'files' are the files in inDir.
  # - First time (step=0) is the initial image
  # - Later (step>0) are the images cut

  # Loop over all the images in $inDir
  files=$(ls -1 $inDir/* 2>/dev/null)
  # For debugging ir execute a limited number of times
  step=0
  while [ ! -z "$files" ]
  do
    step=$(($step+1))
    # Here we start with the step=1,2, ..... and it consists in
    # - Process a list of 'files' that are the input files that the 
    #   previoys step put in <tmp>/in
    # - Split in cols/row and put the results in the folder <tmp>/work
    # - To improve the process, if one of the images has not been changed
    #   (it is final), mmove it to dstDir.
    for f in $files
    do
      trace "Processing $f..."
  
      trace "Splitting in ROWS ..."
  
      # Split in rows
      rm $workDir/* 2>/dev/null
      splitImg $f "rows" $workDir
    
      # Check if has generates new images
      # For a strane reason diff says there are changes when not ..
      changed=1
    
      if [[ $(ls -1 $workDir/*|wc -l) -eq 1 && "$(identify -format "%wx%h" $f)" == "$(identify -format "%wx%h" $workDir/*)" ]]
      then
        changed=0
      fi
    
      if [ $changed -eq 1 ]
      then
        trace "[ROWS] : Generated $(ls -1 $workDir/*)"
      # No Changes? Try Split H
      else
        trace "Split in COLS ..."
  
        rm $workDir/*
        splitImg $f "cols" $workDir
    
        # Check if the image has changed
        changed=1
    
        if [[ $(ls -1 $workDir/*|wc -l) -eq 1 && "$(identify -format "%wx%h" $f)" == "$(identify -format "%wx%h" $workDir/*)" ]]
        then
          changed=0
        fi
  
        # No changes? Keep if
        if [ $changed -eq 1 ]
        then
          trace "[COLS] : Generated $(ls -1 $workDir/*)"
          trace "Generated new images split in columns!"
        else
          trace "Keeping image $workDir/*"
          mv $workDir/* $dstDir
        fi 
      fi
  
      # Copy the files , we must process them
      cp $workDir/* $inDir 2>/dev/null
      # Remove the file
      rm $f
    done # for files in inDir

    # Keep "what I have done" 
    # - <tmp>/<debug>/<step>/IN   : The input images used
    # - <tmp>/<debug>/<step>/WORK
    # - <tmp>/<debug>/<step>/OUT  : The final images obtained
    # the data we get p
    mkdir -p $debugDir/$step
    cp -r $inDir    $debugDir/$step/IN    2>/dev/null
    cp -r $workDir  $debugDir/$step/WORK  2>/dev/null
    cp -r $dstDir   $debugDir/$step/OUT   2>/dev/null
    # Debug

    # Split Once
    if [ $step -eq 1 ]
    then
      cp $workDir/* $dstDir
      break
    fi
  
    files=$(ls -1 $inDir/* 2>/dev/null)
  done
fi # doSplitOnce
