#!/bin/sh
echo "准备开始PS"
/bin/ps -A | grep '/Library/Developer/CoreSimulator/Devices/' > ~/Library/Caches/ps.txt
