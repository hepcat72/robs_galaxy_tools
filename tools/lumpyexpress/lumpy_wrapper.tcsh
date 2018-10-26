#!/bin/tcsh

#USAGE:   lumpy_pipeline.tcsh PAIREDENDRUN OUTVCF    BAMS
#EXAMPLE: lumpy_pipeline.tcsh 1            lumpy.vcf *.bam

#PAIREDENDRUN - 1=paired end 0=single end
#BAMS - Any bam files (will be sorted if not sorted & indexed if not indexed)

#REQUIRED DEPENDENCIES:
#lumpy
#samtools
#samblaster

setenv PAIREDENDRUN `echo $argv | cut -f 1 -d " "`
setenv OUTVCF       `echo $argv | cut -f 2 -d " "`
setenv MYARGV       `echo $argv | cut -f 3-999 -d " "`

setenv BAMS ''
setenv SPLTS ''
setenv DSCDS ''
setenv SPLTOPTS ''

##
## The following is a work-around to a condition that causes a segfault in lumpy from lumpyexpress due to a new min_element threshold.
## This is a kluge, but hopefully the segfault issue with lumpyexpress will be fixed soon.
##

setenv LUMPYEXPRESSSCPT lumpyexpress
setenv LUMPYEXPRESSLOC  `which lumpyexpress`
setenv LUMPYDIR         `dirname $LUMPYEXPRESSLOC`
setenv LUMPYCONFIG      lumpyexpress.config
setenv DISTROSCPT       pairend_distro.py
setenv DISTROLOC        `which $LUMPYDIR/../*/*/*/$DISTROSCPT`
perl -e 'while(<STDIN>){s/min_elements = 10+/min_elements = 1/;print}' < $DISTROLOC > ./$DISTROSCPT
perl -e 'while(<STDIN>){s/PAIREND_DISTRO=.*/PAIREND_DISTRO=$ARGV[0]/;print}' `pwd`/$DISTROSCPT < $LUMPYDIR/$LUMPYCONFIG > ./$LUMPYCONFIG
chmod 555 ./$DISTROSCPT

foreach b ( $MYARGV )

  echo
  echo Preparing $b

  echo
  echo Parsing sample name
  set SAMPLE=`echo $b | perl -e 'while(<>){s/\.bam//;print}'`

  if ( $status ) then
    echo "Unable to parse sample name in $b"
    exit 1
  endif

  echo
  echo "Checking BAM $b"
  samtools view -H $b | perl -e '$y=0;while(<>){if(/SO:coordinate/){$y=1;}}if($y == 0){exit(2)}'
  
  if ( $status ) then
    echo
    echo "Sorting BAM $b"
    samtools sort -o $b.sort -O BAM $b
    if ( $status ) then
      echo "Error sorting BAM $b"
      exit 2
    endif
    mv -f $b.sort $b
    if ( $status ) then
      echo "Error renaming BAM $b.sort $b"
      exit 3
    endif
  endif

  perl -e 'unless(-e "$ARGV[0].bai"){exit(3)}' $b
  if ( $status ) then
    echo
    echo "Indexing BAM $b"
    samtools index -b $b
    if ( $status ) then
      echo "Error indexing BAM"
      exit 4
    endif
  endif

  echo
  echo Getting splitters
  samtools sort -n -O sam $b | samblaster -q -s /dev/stdout -o /dev/null | samtools view -Sb - | samtools sort - -o ${SAMPLE}.splitters.bam

  if ( $status ) then
    echo "Getting splitters from $b failed"
    exit 5
  endif

  echo
  echo Indexing splitters
  samtools index -b ${SAMPLE}.splitters.bam

  if ( $status ) then
    echo "Indexing discordants in $b failed"
    exit 6
  endif

  if ( $PAIREDENDRUN ) then
    echo
    echo Getting discordants
    samtools view -b -F 1294 $b | samtools sort - -o ${SAMPLE}.discordants.bam

    if ( $status ) then
      echo "Getting discordants from $b failed"
      exit 7
    endif

    echo
    echo Indexing discordants
    samtools index -b ${SAMPLE}.discordants.bam

    if ( $status ) then
      echo "Indexing discordants in $b failed"
      exit 8
    endif

    if ( ${?DSCDS} > 0 && ${%DSCDS} > 0 )   setenv DSCDS "$DSCDS,${SAMPLE}.discordants.bam"
    if ( ${?DSCDS} == 0 || ${%DSCDS} == 0 ) setenv DSCDS ${SAMPLE}.discordants.bam

    if ( ${?SPLTS} > 0 && ${%SPLTS} > 0 )   setenv SPLTS "$SPLTS,${SAMPLE}.splitters.bam"
    if ( ${?SPLTS} == 0 || ${%SPLTS} == 0 ) setenv SPLTS ${SAMPLE}.splitters.bam

  else

    if ( ${?SPLTOPTS} > 0 && ${%SPLTOPTS} > 0 )   setenv SPLTOPTS "$SPLTOPTS -sr id:${SAMPLE},bam_file:${SAMPLE}.splitters.bam,back_distance:10,weight:1,min_mapping_threshold:20"
    if ( ${?SPLTOPTS} == 0 || ${%SPLTOPTS} == 0 ) setenv SPLTOPTS "-sr id:${SAMPLE},bam_file:${SAMPLE}.splitters.bam,back_distance:10,weight:1,min_mapping_threshold:20"

  endif

  if ( ${?BAMS} > 0 && ${%BAMS} > 0 )     setenv BAMS  "$BAMS,$b"
  if ( ${?BAMS} == 0 || ${%BAMS} == 0 )   setenv BAMS  $b

end

if ( $PAIREDENDRUN ) then

  echo
  echo "Running: $LUMPYEXPRESSSCPT -K `pwd`/$LUMPYCONFIG -B $BAMS -S $SPLTS -D $DSCDS -o $OUTVCF"
  $LUMPYEXPRESSSCPT -K `pwd`/$LUMPYCONFIG -B $BAMS -S $SPLTS -D $DSCDS -o $OUTVCF

  if ( $status ) then
    echo "lumpyexpress failed"
    exit 9
  endif

else

  echo
  echo "Running lumpy: lumpy -mw 4 -tt 0 $SPLTOPTS > $OUTVCF"
  lumpy -mw 4 -tt 0 $SPLTOPTS > $OUTVCF

  if ( $status ) then
    echo "lumpy failed"
    exit 10
  endif

endif

echo
echo DONE
