#!/bin/bash
#plots all Wannier orbitals of a series(spin-pol)
#P.Wissgott 10/01/10

if [ $# -eq 1 ] && [ "$1" == "-h" ]; then
    echo "plots all Wannier orbitals of a series(spin-pol. calculation)"
    echo "the number of Wannier orbitals is read from wout[up/dn] file"
    echo "the squared values |w_m(r)|^2 are stored to case_m.psink[up/dn]"
    echo "the phases phi(w_m(r)) are stored to case_m.psiarg[up/dn]"
    echo "Usage: prepare_plotssp.sh -up/-sodn case"
    echo "e.g.: prepare_plotssp.sh -up CeIn3"
    exit 0
else
  if [ "$1" == "-up" ]; then
     SP="up"
  elif [ "$1" == "-dn" ]; then
     SP="dn"
  else
     echo "Usage: prepare_plotssp.sh -up/-dn case"
     exit 0
  fi
  
fi


filename=$2
filename_wout="${filename}"".wout$SP"
echo "read number of wannier functions from $filename_wout"
tmp=$(grep "Number of Wannier Functions" $filename_wout)
echo $tmp
num_wann=$(echo ${tmp:47:30})
echo "number of Wannier functions is $num_wann"
for (( idx = 1;  idx <= num_wann;idx++    )) do
   
  echo "compute Wannier function $idx ......."

  wplotsp $1 ${filename} $idx
  cp "${filename}.psiarg$SP" "${filename}""_""$idx"".psiarg$SP"
  cp "${filename}"".psink$SP" "${filename}""_""$idx"".psink$SP"
done
