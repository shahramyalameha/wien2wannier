#!/bin/bash

### wien2wannier/compile_wien2wannier.sh
###
###    A primitive compile script for wien2wannier
###
### Copyright 2014-2015 Elias Assmann
###
### $Id: compile_wien2wannier.sh 385 2015-06-01 13:08:18Z assmann $

w2wdir=$(dirname $0)

ask_continue () {
    echo
    read -p "continue? "
    [[ $REPLY = [yY] ]] || exit 1
    echo
}

if [[ ! -d SRC_w2w ]]; then
    echo "./SRC_w2w/ not found.  Have you extracted \`wien2wannier.tar'?"

    ask_continue
fi

if [[ ! -s OPTIONS ]]; then
    echo "This script is meant to be run from your \`\$WIENROOT' directory"
    echo "after Wien2k has been configured.  It seems this is not the case"
    echo "[file ./OPTIONS not found]."
    echo
    echo "(If you have run \`expand_lapw' but not yet \`siteconfig_lapw', you"
    echo "do not need this script, wien2wannier will be configured and"
    echo "compiled with Wien2k.)"

    ask_continue
fi

if ! diff -q $w2wdir/WIEN-VERSION ./VERSION; then
    echo "WARNING: unpacking wien2wannier overwrites the Wien2k script \`x_lapw'."
    echo "If your Wien2k version (given in \$WIENROOT/VERSION) does not match"
    echo "the version wien2wannier is compatible with (given in WIEN-VERSION),"
    echo "this is dangerous!  (You can revert to the standard x_lapw from SRC.tar.)"
    echo
    echo "Versions found:"
    echo -n "     Wien2k:       "; cat VERSION
    echo -n " vs. wien2wannier: "; cat $w2wdir/WIEN-VERSION

    ask_continue
fi

echo -e 'O\n\nS\n\nQ\n' | ./siteconfig || exit

make -C SRC_w2w all || exit
cp SRC_w2w/w2w{,c} .

make -C SRC_wplot all || exit
cp SRC_wplot/wplot{,c} .

make -C SRC_trig clean all


## Time-stamp: <2015-06-01 12:38:19 assman@faepop23.tu-graz.ac.at>