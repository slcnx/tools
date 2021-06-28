#!/bin/bash
#
#********************************************************************
#Author:                songliangcheng
#QQ:                    2192383945
#Date:                  2021-03-22
#FileName：             install.sh
#URL:                   http://www.magedu.com
#Description：          A test toy
#Copyright (C):        2021 All rights reserved
#********************************************************************
tar xvf node_exporter-1.1.2.linux-amd64.tar.gz -C /usr/local/
ln -sv /usr/local/node_exporter-1.1.2.linux-amd64/ /usr/local/node_exporter
cp node-exporter.service /etc/systemd/system/node-exporter.service 
systemctl daemon-reload
systemctl start node-exporter
systemctl enable node-exporter
systemctl status node-exporter
lsof -i:9100
