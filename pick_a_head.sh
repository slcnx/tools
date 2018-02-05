#!/bin/bash
#
students=(Lilei Hanmeimei Lucy Lily Tom Jerry John Polly UncleWang)
# ---------------------- premise ----------------------------
[ $# -eq 1 ] || exit
[[ "$1" =~ [1-9] ]] || exit
[ $1 -ge 1 -a $1 -le 9 ] || exit

# ---------------------- Cycle $1 times --------------------
for ((i=1;i<=$1;i++)); do
	total=${#students[@]}
	rand=$(expr $RANDOM % $total)
	choice[${#choice[@]}]=${students[$rand]}
	unset students[$rand]=${students[$rand]}
	# --- exclude array student pace ---- #
	unset unspace
	for j in ${students[@]}; do
		[ -z "$j" ] && countinue
		unspace[${#unspace[@]}]=$j
	done
	students=(${unspace[@]})
	  #######                    #######
done
echo "Choice student: ${choice[@]}"
