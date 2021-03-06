#!/bin/bash
#
# make-qhull_qh.sh [libqhull_r] [sed-only] [files] -- Derive src/qhull-qh/ from src/libqhull_r with 'qh' macros
#
# $Id: //main/2019/qhull/eg/make-qhull_qh.sh#2 $$Change: 2672 $
# $DateTime: 2019/06/06 15:21:49 $$Author: bbarber $

if [[ "$1" == "" ]]; then
    echo "eg/make-qhull_qh.sh libqhull_r | sed-only | <directory-file-list> -- convert 'qh->' to macro 'qh'"
    echo "  creates 'src/qhull_qh/' unless 'DEST=destination eg/make-qhull_qh.sh ..."
    exit
fi
# set -v
SEDONLY=0
if [[ "$1" == "libqhull_r" ]]; then
    SOURCES="src/libqhull_r src/qconvex src/qdelaunay src/qhalf src/qhull src/qvoronoi src/rbox src/testqset_r src/user_eg src/user_eg2"
    DEST=${DEST:-src/qhull_qh}
    if [[ $# -gt 1 ]]; then
        echo "eg/make-qhull_qh.sh: 'libqhull_r' does not take source directories.  It converts qhull files in '$SOURCES' to '$DEST'"
        exit 1
    fi
elif [[ "$1" == "sed-only" ]]; then
    SEDONLY=1
    DEST=${DEST:-.}
    if [[ $# -gt 1 ]]; then
        echo "eg/make-qhull_qh.sh: 'sedonly' does not take source directories.  It converts qhull files in '$DEST' from 'qh->' to the macro 'qh'"
        exit 1
    fi
else
    SOURCES="$@"
    DEST=${DEST:-src/qhull_qh}
fi

if [[ $SEDONLY -ne 1 ]]; then
    if [[ -d $DEST ]]; then
        echo "To rebuild '$DEST' from '$SOURCES'"
        if [[ "$DEST" == "src/qhull_qh" ]]; then
            echo "    make cleanall; eg/make-qhull_qh.sh $@"
        else
            echo "    rm -rf '$DEST'; eg/make-qhull_qh.sh $@"
        fi
        exit 1
    fi
    for F in $SOURCES; do
        if [[ ! -d $F && ! -r $F ]]; then
            echo "eg/make-qhull_qh.sh: source '$F' not found.  Execute make-qhull_qh.sh from a Qhull directory with $SOURCES"
            exit 1
        fi
    done
    echo eg/make-qhull_qh.sh: Create "'$DEST/' from '$SOURCES'"
    mkdir $DEST || exit 1
    echo -e "eg/make-qhull_qh.sh created '$DEST' to compare reentrant with non-reentrant Qhull" >$DEST/README.txt
    echo -e "\nSource directories and files -- $SOURCES" >>$DEST/README.txt
    echo -e "\n'make cleanall' deletes 'src/qhull_qh/'\n" >>$DEST/README.txt
    date >>$DEST/README.txt
    for X in $SOURCES; do
        if [[ -d $X ]]; then
            for F in $X/*_r.* $X/*_ra.*  $X/*.def; do
                if [[ -f $F ]]; then
                    G="$(echo ${F##*/} | sed -e 's/_r\././'  -e 's/_ra\./_a./')"
                    # echo "$F => $DEST/$G"
                    cp -p $F $DEST/$G || exit 1
                 fi
            done
            if [[ -f $X/Makefile && ! -f $DEST/Makefile ]]; then
                cp -p $X/Makefile $DEST/ || exit 1
            fi
            if [[ -f $X/index.htm && ! -f $DEST/index.htm ]]; then
                cp -p $X/index.htm $DEST/ || exit 1
            fi
        elif [[ -f $X ]]; then
            G="$(echo ${X##*/} | sed -e 's/_r\././' -e 's/_ra\./_a./')"
            # echo "$X => $DEST/$G"
            cp -p $X $DEST/$G || exit 1
        fi
    done
fi

echo Convert 'qh->' to 'qh ', etc.
if [[ -w $DEST/Makefile ]]; then
    sed -i -r \
        -e 's/_r$//' \
        -e 's/_r / /g' \
        -e 's|_r/|/|g' \
        -e 's/_r\.a/.a/g' \
        -e 's/_r\.c/.c/g' \
        -e 's/_r\.h/.h/g' \
        -e 's/_r\.o/.o/g' \
        -e 's/_ra\.h/_a.h/g' \
        $DEST/Makefile || exit 1
fi
for F in $DEST/*.c $DEST/*.h; do
    sed -i -r \
        -e 's/\(qhT \*qh, /(/' \
        -e ' /ifdef __cplusplus/,/^$/ d' \
        -e 's/\(qhT \*qh(.*)\)/(void\1)/' \
        -e 's/_r$//' \
        -e 's/_r([ /:])/\1/g' \
        -e 's/_r\.c/.c/g' \
        -e 's/_r\.h/.h/g' \
        -e 's/_r\.o/.o/g' \
        -e 's/_ra\.h/_a.h/g' \
        -e 's/ \|\| \!qh\)/)/' \
        -e 's/_rbox\(qh, qh->/_rbox(rbox./' \
        -e ' /QHULL_UNUSED\(qh\)/ d' \
        -e 's/qh->rbox_([^c])/rbox.\1/g' \
        -e 's/\(qh, (.*) \)$/( \1 )/' \
        -e 's/\(qh, (.*) \) \{ \.\.\. \}$/( \1 ) { ... }/' \
        -e 's/\(qh *\)$/( )/' \
        -e 's/\(qhB?, /(/g' \
        -e 's/\(qhB?\)/()/g' \
        -e 's/\(qh /(/g' \
        -e 's/qh->qhmem/qhmem/g' \
        -e 's/qh->qhstat\./qhstat /g' \
        -e 's/qh->/qh /g' \
        -e 's/qhull_r-/qhull-/g' \
        -e "s/Needed for qhT in libqhull.h/Needed for qhT in libqhull_r.h.  Here for compatibility/" \
        -e ' /ifdef __cplusplus/,/^$/ d' \
        -e ' /qh may be NULL/ d' \
        -e ' /For libqhull_r,/ d' \
        -e ' /reentrant only/ d' \
        -e ' /assumes qh defined/ d' \
        -e ' /^ *\/\*.*\.cpp -- / d' \
        $F
        # sed requires space before search expressions, /.../
    if which u2d >/dev/null 2>&1; then
        u2d $F
    fi
done
for F in $DEST/*.htm; do
    sed -i -r \
        -e 's|_r/|/|g' \
        -e 's/_r\.c/.c/g' \
        -e 's/_r\.h/.h/g' \
        -e 's/_ra\.h/_a.h/g' \
        $F
    if which u2d >/dev/null 2>&1; then
        u2d $F
    fi
done
echo -e "\nCompare '$DEST' to 'src/libqhull', 'src/qdelaunay', etc.  Do not ignore minor differences."
