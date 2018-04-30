#!/bin/bash

#确保已安装curl
#centos7可能需安装ifconfig (yum install net-tools)


#参数
#Cloudflare API调用地址（默认官网）
CLOUDFLARE_API="https://api.cloudflare.com"
#根域名zone id
ZONE_ID="zone id" 
#要使用ddns的域名
DOMAIN="domain"
#Cloudflare账号的API Key
API_KEY="api key"
#Cloudflare账号的注册邮箱
EMAIL="email"
#公网ip绑定的网卡(比如eth0)
INTERFACE="eth0"


#使用API得到返回参数

RESULT=$(curl -s --insecure -X GET "$CLOUDFLARE_API/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN&page=1&per_page=20&order=type&direction=desc&match=all" -H "X-Auth-Email: $EMAIL" -H "X-Auth-Key: $API_KEY" -H "Content-Type: application/json")

#判断域名或zone id是否出错

if [ "$(echo $RESULT | awk -F ':' '{print $2}'| awk -F ',' '{print $1}')" = "[]" ];then
        echo "Requested domain not exist or incorrect zone id"
		exit 
#判断邮箱是否出错		

        elif [ "$(echo $RESULT | awk -F ':' '{print $2}'| awk -F ',' '{print $1}')" = "false" ];then
        echo $RESULT | awk -F '"' '{print $10}'
		exit
else

#获取域名ID

        SUB_DOMAIN_ID=$(echo $RESULT | awk -F '"' '{print $6}')

fi

#获取本机ip地址
if [ ! -n "$(ifconfig $INTERFACE | grep "inet addr:")" ]; then

IP_ADDR=$(ifconfig $INTERFACE | grep "inet" | head -n 1 | awk -F " " '{print $2}')

else

IP_ADDR=$(ifconfig $INTERFACE | grep "inet addr:" | head -n 1 | awk -F ":" '{print $2}' | awk -F " " '{print $1}')

fi


#修改域名A记录为本机ip地址

curl --insecure -X PUT "$CLOUDFLARE_API/client/v4/zones/$ZONE_ID/dns_records/$SUB_DOMAIN_ID" -H "X-Auth-Email: $EMAIL" -H "X-Auth-Key: $API_KEY" -H "Content-Type: application/json" --data '{"type":"A","name":"'$DOMAIN'","content":"'$IP_ADDR'","ttl":120, "proxied":false}' 
