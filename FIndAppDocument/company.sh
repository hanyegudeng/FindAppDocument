#!/bin/sh
#配置ip、掩码、路由
networksetup -setmanual "Wi-Fi" 192.168.30.169 255.255.255.0 192.168.30.254
#配置dns
networksetup -setdnsservers "Wi-Fi" 202.96.209.5
