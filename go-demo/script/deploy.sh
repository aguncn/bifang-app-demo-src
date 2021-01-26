#!/bin/sh

# app名称
APP_NAME=$1
# release发布单参数
RELEASE=$2
# env环境参数
ENV=$3
# app压缩包名参数
ZIP_PACKAGE_NAME=$4
# app压缩包的网络下载地址
ZIP_PACKAGE_URL=$5
# port服务端口参数
PORT=$6
# action服务启停及部署参数
ACTION=$7

# app可执行文件名或包名
PACKAGE_NAME="go-demo"
# app部署根目录
APP_ROOT_HOME="/app"
# 可执行文件所有目录
BIN_PATH="./bin"
# app软件包保存根目录
LOCAL_ROOT_STORE="/var/ops"


APP_HOME="$APP_ROOT_HOME/$APP_NAME"
LOCAL_STORE="$LOCAL_ROOT_STORE/$APP_NAME/current"
LOCAL_BACK="$LOCAL_ROOT_STORE/$APP_NAME/backup"
LOG="$APP_HOME/$APP_NAME.log"
RETVAL=0
   
UP() {
    ps aux |grep "${PACKAGE_NAME}"|grep -v "salt"|grep -v "grep"|awk '{print $2}'
}   

# 先建立相关目录，备份上次部署的软件包，再从构件服务器上获取软件包，保存到指定目录。
# 只支持一次回滚，想回滚多次，最好再重新部署之前的发布单
fetch() {
    if [ ! -d $APP_HOME  ];then
        mkdir -p $APP_HOME
    fi
    if [ ! -d $LOCAL_STORE  ];then
        mkdir -p $LOCAL_STORE
    fi
    if [ ! -d $LOCAL_BACK  ];then
        mkdir -p $LOCAL_BACK
    fi
    # 删除上上次备份的软件包(无多次回滚)
    if [ -f "$LOCAL_BACK/$ZIP_PACKAGE_NAME" ];then
        mv $LOCAL_BACK/$ZIP_PACKAGE_NAME /tmp/
    fi
    # 备份上次的软件包
    if [ -f "$LOCAL_STORE/$ZIP_PACKAGE_NAME" ];then
        mv $LOCAL_STORE/$ZIP_PACKAGE_NAME $LOCAL_BACK/$ZIP_PACKAGE_NAME
    fi
    # 获取本次的部署包
    wget -q -P $LOCAL_STORE $ZIP_PACKAGE_URL

    echo "APP_NAME: $APP_NAME prepare success." 
}

# 回滚，从BACKUP目录解压恢复
rollback() {
    rm -rf $APP_HOME/*
    tar -xzvf $LOCAL_BACK/$ZIP_PACKAGE_NAME -C $APP_HOME
    echo "APP_NAME: $APP_NAME rollback success."
}
 
# 清除目录已有文件，将CURRENT解压到运行目录
deploy() {
    rm -rf $APP_HOME/*
    tar -xzf $LOCAL_STORE/$ZIP_PACKAGE_NAME -C $APP_HOME
    echo "APP_NAME: $APP_NAME deploy success."
} 
#启动应用，传递了port和env参数
start() {
    pid=`UP`
    if [ -n "$pid" ]; then
        echo "Project: $APP_NAME is running, kill first or restart, failure start."
        RETVAL=1
    fi
 
    start=$(date +%s)
    
    cd "$APP_HOME"

    #此处为真正启动命令
    nohup $BIN_PATH/$PACKAGE_NAME >/dev/null 2>&1 &
	RETVAL=$?
	# 启动后，多等几秒，这个脚本放在开发维护，就可以根据不同的应用，作不同的启动调整，不能统一处理
	cnt=3
    while [ $cnt -gt 0 ]; do
        sleep 1
        ((cnt--))
    done
    
    if [ $RETVAL = 0 ]; then
        end=$(date +%s)
        echo "APP_NAME:  $APP_NAME is start success in $(( $end - $start )) seconds. \n"
    else
        echo "APP_NAME:  $APP_NAME is Start failure, please check LOG. \n"
    fi
}
   
stop() {
    pid=`UP`
    # 先杀进程，如果还有进程，等几秒
    [ -n "$pid" ] && kill -9 $pid

    echo $pid
    RETVAL=$?
    cnt=3
    while [ $RETVAL = 0 -a $cnt -gt 0 ] &&
        { UP > /dev/null ; } ; do
        sleep 1
        ((cnt--))
    done
	pid=`UP`
    if [ -n "$pid" ]; then
        echo "APP_NAME: $APP_NAME is failure stop."
    else
        echo "APP_NAME: $APP_NAME is success stop."
    fi
}
   
start_status() {
    pid=`UP`
    if [ -n "$pid" ]; then
        echo "APP_NAME: $APP_NAME is success on running."
    else
        echo "APP_NAME: $APP_NAME is failure on running."
    fi
}

stop_status() {
    pid=`UP`
    if [ -n "$pid" ]; then
        echo "APP_NAME: $APP_NAME is failure on stop."
    else
        echo "APP_NAME: $APP_NAME is success on stop."
    fi
}

health_check() {
	echo "APP_NAME: $APP_NAME is success health."
}
   
case "$ACTION" in
    fetch)
        fetch
        ;;
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    stop_status)
        stop_status
        ;;
	start_status)
        start_status
        ;;
	health_check)
		health_check
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo $"Usage: $0 {7 args}"
        RETVAL=1
esac

exit $RETVAL
