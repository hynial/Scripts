#!/bin/bash

# 39f83883
fromVersion=$1
toVersion=$2
echo "from:$fromVersion, to:$toVersion"

codeDir=/Users/IDEA-WS/eaf
buildDir=/Users/IDEA-WS/PA/eaf/target/classes
resultDir=/Users/Scripts
zipFile="$resultDir/patch-$(date +%Y%m%d).zip"
buildResult=/Users/BuildResult
buildResultClass="$buildResult/BOOT-INF/classes"

if test -f "$zipFile"; then
    rm -f $zipFile
fi

shopt -s nocasematch

cd $codeDir
counterJava=0
counterZip=0
extJava=java
extClass=class
# 纯修改 ： git ls-files --modified
# 两版本：  git diff $fromVersion $toVersion --name-only
for deployFile in $(git diff $fromVersion $toVersion --name-only)
do
	extName=${deployFile##*.}
	fileName=${deployFile%.*}
	if [ "${extName}" = "${extJava}" ]; then
		((counterJava++))
		# echo "${deployFile%.*}---${deployFile##*.}"

		com=$(echo "${deployFile%.*}.${extClass}" | awk -F '/java/' '{print $2}')
		targetCom="$buildDir/$com"
		targetName=${targetCom%.*}
		targetExt=${targetCom##*.}

		if test -f "$targetCom"; then
		    echo "$targetCom"
		    cd $buildDir
		    zip $zipFile $com
		    ((counterZip++))
		    cd -
		else
			continue
		fi

		counterDollar=1
		while [ $counterDollar -le 10 ]
		do
			dollarFile="$targetName\$$counterDollar.$targetExt"
			if test -f "$dollarFile"; then
			    echo "$dollarFile"
			    cd $buildDir
			    comName="${com%.*}\$$counterDollar.$targetExt"
			    zip $zipFile $comName
			    ((counterZip++))
			    cd -
			else
			    break
			fi

			(( counterDollar++ ))
		done
	fi

  configArray=(xml yml properties)
  for c in "${configArray[@]}"; do
    if [[ "$c" = "${extName}" ]]; then
      resourcesAfter=$(echo "${deployFile%.*}.${extName}" | awk -F '/resources/' '{print $2}')
      targetYml="$buildDir/$resourcesAfter"
      if test -f "$targetYml"; then
          cd $buildDir
          zip $zipFile $resourcesAfter
          ((counterZip++))
          cd -
      else
        continue
      fi

      break
    fi
  done

done

echo "java:$counterJava"
echo "zips:$counterZip"

if test -f "$zipFile"; then
	if [ -d "$buildResult/BOOT-INF" ]; then
		if [ "$buildResult/BOOT-INF" != "/" ]; then
			rm -rf "$buildResult/BOOT-INF"
		fi
	fi

	mkdir -p $buildResultClass
	unzip -o $zipFile -d $buildResultClass

	patchBoot="$buildResult/patch-boot-$(date +%Y%m%d).zip"
	if [ -f "$patchBoot" ]; then
		if [ "$patchBoot" != "/" ]; then
			rm -f "$patchBoot"
		fi
	fi

	cd $buildResult
	zip -r $patchBoot BOOT-INF
	cd -
else
	echo "zipFileMissing"
fi

open $buildResult
# no contains jar\pom.xml
# usage :
# sh mvn-spring-boot-patch.sh v1 v2
# unzip -l patch-boot-20191226.zip | awk -F 'BOOT-INF/' '{print $2}' | sed '/\/$/d' | xargs -I% echo "BOOT-INF/%"
# zip eaf.jar $(unzip -l patch-boot-20191226.zip | awk -F 'BOOT-INF/' '{print $2}' | sed '/\/$/d' | xargs -I% echo "BOOT-INF/%")