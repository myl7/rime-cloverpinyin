#!/bin/bash
set -eo pipefail

SHELL_FOLDER=$(dirname $(readlink -f "$0"))


minfreq=100
[ "$1" ] && minfreq="$1"


find_downloader(){
	# 寻找下载器
	#   会设置 $downloader 和 $down_out_op 变量

	# 寻找 wget
	if type wget >/dev/null 2>&1; then
		downloader=wget
		down_out_op=-O
		return
	fi

	# 寻找 curl
	if type curl >/dev/null 2>&1; then
		downloader=curl
		down_out_op=-o
		return
	fi

	# 寻找 aria2c
	# Preferring aria2 causes "address already in use" when there is existing aria2 instance
	# So move it to the end of the searching list
	if type aria2c >/dev/null 2>&1; then
		downloader=aria2c
		down_out_op=-o
		return
	fi

	echo "未找到合适的下载器，请安装 aria2c/wget/curl 之一后重试。" >&2
}

find_extractor(){
	# 寻找解压工具
	#   会设置 $extractor 和 $extra_op 变量

	# 寻找 unzip
	if type unzip >/dev/null 2>&1; then
		extractor=unzip
		extra_op=-o
		return
	fi

	# 寻找 bsdtar
	if type bsdtar >/dev/null 2>&1; then
		extractor=bsdtar
		extra_op=xf
		return
	fi

	# 寻找 7z
	if type 7z >/dev/null 2>&1; then
		extractor=7z
		extra_op=x
		extra_op1=-y
		return
	fi
}

down(){
	# 下载一个文件
	# $1 下载链接（url）
	# $2 本地保存的文件

	# 检查下载器
	[ ${downloader} ] || find_downloader
	[ ${downloader} ] || exit 1

	$downloader "$1" $down_out_op "$2"
}

extract(){
	# 解压一个文件
	# $1 要解压的文件

	# 检查解压工具
	[ ${extractor} ] || find_extractor
	[ ${extractor} ] || exit 2

	if [ "$extra_op1" ]; then
		$extractor "$extra_op" "$extra_op1" "$1"
	elif [ "$extra_op" ]; then
		$extractor "$extra_op" "$1"
	else
		$extractor "$1"
	fi
}


cd $SHELL_FOLDER
mkdir -p cache || exit
cd cache

# 下载并解压文件
cat "$SHELL_FOLDER/src/file_list.txt" | while read line; do
	[ "$line" ] || continue
	url="$(echo "$line" | cut -f1)"
	[ "$url" ] || continue
	md5="$(echo "$line" | cut -f2)"
	name="$(echo "$line" | cut -f3)"
	dst="$(echo "$line" | cut -f4)"
	commit="$(echo "$line" | cut -f5)"

	if [ ! -f "$name" ]; then
		down "$url" "$name" || exit
	fi

	echo "url = $url"
	echo "md5 = $md5"
	echo "name = $name"
	echo "dst = $dst"
	echo "commit = $commit"
	echo "$md5  $name" | md5sum -c || exit

	if [ $dst ]; then
		rm -rf "$dst-$commit" "$dst"
		echo $name
		extract "$name" || exit
		mv "$dst-$commit" "$dst" || exit
	fi
done
extract 360万中文词库+词性+词频.zip || exit
ln -sf rime-essay/essay.txt essay.txt || exit
ln -sf rime-pinyin-simp/pinyin_simp.dict.yaml pinyin_simp.dict.yaml || exit

# 生成符号列表
cd rime-symbols || exit
mkdir -p opencc || exit
cd opencc || exit
../rime-symbols-gen || exit
cd ../.. || exit

# 生成符号词汇
cat */opencc/*.txt | opencc -c t2s.json | uniq > symbols.txt

# 开始生成词典
../src/clover-dict-gen --minfreq=$minfreq || exit
for i in THUOCL/data/THUOCL_*; do
	echo "转换 $i"
	../src/thuocl2rime $i || exit
done
cp ../src/sogou_new_words.dict.yaml .
./libscel/scel.py >> sogou_new_words.dict.yaml || exit

# 生成 data 目录
mkdir -p ../data || exit
cp ../src/*.yaml ../data || exit
mv clover.*.yaml THUOCL_*.yaml sogou_new_words.dict.yaml ../data || exit

cd ../data

# 生成 opencc 目录
mkdir -p opencc
cp ../cache/rime-emoji/opencc/* opencc
sed -i '/污染\t污染 🏭️/d' opencc/emoji_word.txt
cp ../cache/rime-symbols/opencc/* opencc
sed -i '/\t ㏍/d' opencc/symbol_word.txt
sed -i '/\t ㏎/d' opencc/symbol_word.txt

echo 开始构建部署二进制
rime_deployer --compile clover.schema.yaml . /usr/share/rime-data || exit
rm -rf build/*.txt
