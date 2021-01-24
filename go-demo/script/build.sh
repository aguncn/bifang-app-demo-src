#!/bin/sh

echo 'beging build demo-go app...'


go build -o bin/go-demo main/main.go 

tar -zcvf go-demo.tar.gz env/ bin/

echo 'finish build demo-go app...'