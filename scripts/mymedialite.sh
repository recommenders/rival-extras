#!/bin/bash



prog_rbr='mono --debug ./mymedialite-3.10/lib/mymedialite/rating_based_ranking.exe'
prog_ir='mono --debug ./mymedialite-3.10/lib/mymedialite/item_recommendation.exe'
while read line
do
	case $line in
		mymedialite.rec.ib*)
			ibrec=`echo $line | cut -f2 -d=`
			;;
		mymedialite.rec.ub*)
			ubrec=`echo $line | cut -f2 -d=`
			;;
		mymedialite.rec.svd*)
			svdrec=`echo $line | cut -f2 -d=`
			;;
		mymedialite.sim*)
			similarity=`echo $line | cut -f2 -d=`
			;;
		svd.iterations*)
			iterations=`echo $line | cut -f2 -d=`
			;;
		neighborhood*)
			n=`echo $line | cut -f2 -d=`
			;;
		input*)
			input=`echo $line | cut -f2 -d=`
			;;
		output*)
			output=`echo $line | cut -f2 -d=`
			;;
		""*)
			;;
		*)
			echo "This line not parsed: \n $line"
	esac
done < $1


prog=$prog_rbr
input_test=`find $input -type f | grep .test`
input_train=`find $input -type f | grep .train`
inputs=(`echo $input_train | tr " " "\n"`)
if [ ! -f $output ]; then
	mkdir $output
fi


function itemBased(){
if [[ -n "$ibrec" ]]; then
	sims=(`echo $similarity | tr "," "\n"`)
	for sim in ${sims[@]}; do
		if [[ $sim == "Cosine" ]]; then
			program=$prog_ir
		else
			program=$prog_rbr
		fi
		for inpt in ${inputs[@]}; do
			testfile=`echo $inpt | sed 's/train/test/g'`
			#echo $testfile
			outfile=${inpt##*/}
			outfile=${outfile%.*}
			outfile=`echo "$output/$outfile.$ibrec.$sim.csv"`
			#echo $outfile
			if [ -f $outfile ]
			then
				echo "Already recommended $outfile for this data"
			else
				$program --training-file=$inpt --file-format=default --test-file=$testfile --recommender=$ibrec --all-items --prediction-file=$outfile --recommender-options=correlation=$sim
			fi
		done
	done
fi
}


function userBased() {

if [[ -n "$ubrec" ]]; then
	sims=(`echo $similarity | tr "," "\n"`)
	for sim in ${sims[@]}; do
		if [[ $sim == "Cosine" ]]; then
			program=$prog_ir
		else
			program=$prog_rbr
		fi
		for inpt in ${inputs[@]}; do
			testfile=`echo $inpt | sed 's/train/test/g'`
			outfile=${inpt##*/}
			outfile=${outfile%.*}
			nn=(`echo $n | tr "," "\n"`)
			for ns in ${nn[@]}; do
				outputfile=`echo "$output/$outfile.$ubrec.$sim.$ns.csv"`
				if [ -f $outputfile ]
				then
					echo "Already recommended $outfile for this data"
				else
					$program --training-file=$inpt --file-format=default --test-file=$testfile --recommender=$ubrec --all-items --prediction-file=$outputfile --recommender-options="correlation=$sim k=$ns"
				fi
			done
		done
	done
fi
}


function svdBased(){
if [[ -n "$svdrec" ]]; then
	for inpt in ${inputs[@]}; do
		testfile=`echo $inpt | sed 's/train/test/g'`
		outfile=${inpt##*/}
		outfile=${outfile%.*}
		nn=(`echo $n | tr "," "\n"`)
		for ns in ${nn[@]}; do
			outputfile=`echo "$output/$outfile.$svdrec.$ns.csv"`
			if [ -f $outputfile ]
			then
				echo "Already recommended $outfile for this data"
			else
				$prog_rbr --training-file=$inpt --file-format=default --test-file=$testfile --recommender=$svdrec --all-items --prediction-file=$outputfile --recommender-options="num_factors=$ns num_iter=50"
			fi
		done
	done
fi
}

itemBased
userBased
svdBased
