#!/bin/sh
v -keepc . -o plchldr || { echo -e "\x1b[31mCompilation Failed\x1b[0m"; exit 1; }
for i in test/*.pr; do
	echo -e "\x1b[33mTesting $i\x1b[0m"
	./plchldr $i || echo -e "\x1b[31mFailed: $i\x1b[0m"
done
./plchldr pr/main.pr || echo -e "\x1b[31mFailed: pr/main.pr\x1b[0m"
