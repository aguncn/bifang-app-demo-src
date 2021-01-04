package main

import (
	"fmt"
	"log"
	"net/http"
)

func doRequest(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello Golang!") //这个写入到w的是输出到客户端的
}
func main() {
	http.HandleFunc("/", doRequest)          //设置访问的路由
	err := http.ListenAndServe(":9090", nil) //设置监听的端口
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
