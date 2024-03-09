# 把 /maps 中的文件软连接到游戏的 addons 目录中
# /maps 最好作为一个挂载点
main() {
    # 删除死链
    for i in $(ls ./); do
        if [ $(deadlink $i) = "1" ]; then
            rm $i;
        fi
    done
    # 重新链接
    for i in $(ls /map/*); do
        ln -sf $i l4d2/left4dead2/addons/
    done
}

# $1 是一个软连接，此函数检测该链接所指向的文件是否存在
# + 存在，返回 0
# + 不存在，返回 1
deadlink() {
    if [ -d $1 ]; then
        echo "0";
    else
        test -e $1 && test -L $1 && echo "0" || echo "1";
    fi
}

main
