#!/bin/bash
yum update -y
yum install -y nginx
systemctl enable --now nginx

mkdir -p /home/ec2-user/scripts
aws s3 cp s3://dev-maksimecv-8828/index.html /usr/share/nginx/html/index.html --region us-east-1
aws s3 cp s3://dev-maksimecv-8828/ /home/ec2-user/scripts/ --recursive --exclude "*.html" --region us-east-1

chown -R ec2-user: /home/ec2-user/scripts
chmod +x /home/ec2-user/scripts/*.sh
systemctl restart nginx
