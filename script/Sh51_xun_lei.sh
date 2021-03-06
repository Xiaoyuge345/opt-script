#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
xunleis=`nvram get xunleis`
[ -z $xunleis ] && xunleis=0 && nvram set xunleis=0
if [ "$xunleis" != "0" ] ; then
#nvramshow=`nvram showall | grep '=' | grep xunlei | awk '{print gensub(/'"'"'/,"'"'"'\"'"'"'\"'"'"'","g",$0);}'| awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow

xunleis_dir=`nvram get xunleis_dir`

xunleis_renum=`nvram get xunleis_renum`
xunleis_renum=${xunleis_renum:-"0"}
cmd_log_enable=`nvram get cmd_log_enable`
cmd_name="迅雷下载"
cmd_log=""
if [ "$cmd_log_enable" = "1" ] || [ "$xunleis_renum" -gt "0" ] ; then
	cmd_log="$cmd_log2"
fi
fi

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep xun_lei)" ]  && [ ! -s /tmp/script/_xun_lei ]; then
	mkdir -p /tmp/script
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /tmp/script/_xun_lei
	chmod 777 /tmp/script/_xun_lei
fi

xunleis_restart () {

relock="/var/lock/xunleis_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set xunleis_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		logger -t "【迅雷下载】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		exit 0
	fi
	xunleis_renum=${xunleis_renum:-"0"}
	xunleis_renum=`expr $xunleis_renum + 1`
	nvram set xunleis_renum="$xunleis_renum"
	if [ "$xunleis_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		logger -t "【迅雷下载】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get xunleis_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set xunleis_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
nvram set xunleis_status=0
eval "$scriptfilepath &"
exit 0
}

xunlei_get_status () {

A_restart=`nvram get xunleis_status`
B_restart="$xunleis$xunleis_dir"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	nvram set xunleis_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

xunlei_check () {

xunlei_get_status
if [ "$xunleis" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "`pidof ETMDaemon`" ] && logger -t "【迅雷下载】" "停止 xunleis" && xunlei_close
	{ kill_ps "$scriptname" exit0; exit 0; }
fi
if [ "$xunleis" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		xunlei_close
		xunlei_start
	else
		[ -z "`pidof ETMDaemon`" ] && xunleis_restart
	fi
fi
}

xunlei_keep () {
sleep 15
wgetcurl.sh "/tmp/xunlei.info" "http://127.0.0.1:9000/getsysinfo" "http://127.0.0.1:9001/getsysinfo" N
if [ ! -s /tmp/xunlei.info ] ; then
	sleep 15
	wgetcurl.sh "/tmp/xunlei.info" "http://127.0.0.1:9000/getsysinfo" "http://127.0.0.1:9001/getsysinfo" N
	[ ! -s /tmp/xunlei.info ] && { wgetcurl.sh "/tmp/xunlei.info" "http://`nvram get lan_ipaddr`:9002/getsysinfo" "http://`nvram get lan_ipaddr`:9003/getsysinfo" N ; }
fi
logger -t "【迅雷下载】" "启动 xunlei, 绑定设备页面【http://yuancheng.xunlei.com】"
logger -t "【迅雷下载】" "在浏览器中输入【http://`nvram get lan_ipaddr`:9000/getsysinfo】"
logger -t "【迅雷下载】" "显示错误则输入【http://`nvram get lan_ipaddr`:9001/getsysinfo】"
logger -t "【迅雷下载】" "会看到类似如下信息："
logger -t "【迅雷下载】" "`cat /tmp/xunlei.info | sed s/[[:space:]]//g `"
nvram set xunleis_sn=`cat /tmp/xunlei.info | sed s/[[:space:]]//g | sed s/"\["//g | sed s/"\]"//g`
logger -t "【迅雷下载】" "其中有用的几项为："
logger -t "【迅雷下载】" "①: 0表示返回结果成功"
logger -t "【迅雷下载】" "②: 1表示检测网络正常, 0表示检测网络异常"
logger -t "【迅雷下载】" "④: 1表示已绑定成功, 0表示未绑定"
logger -t "【迅雷下载】" "⑤: 未绑定的情况下, 为绑定的需要的激活码"
logger -t "【迅雷下载】" "⑥: 1表示磁盘挂载检测成功, 0表示磁盘挂载检测失败"
logger -t "【迅雷下载】" "如果出现错误可以手动启动, 输入以下命令测试"
logger -t "【迅雷下载】" "export LD_LIBRARY_PATH=$xunleis_dir/xunlei/lib:/lib:/opt/lib ; cd $xunleis_dir/xunlei ; $xunleis_dir/xunlei/portal"
logger -t "【迅雷下载】" "守护进程启动 $xunleis_dir/xunlei"
if [ -s /tmp/script/_opt_script_check ]; then
sed -Ei '/【迅雷下载】|^$/d' /tmp/script/_opt_script_check
cat >> "/tmp/script/_opt_script_check" <<-OSC
	NUM=\`grep "/xunlei/lib/" /tmp/ps | grep -v grep |wc -l\` # 【迅雷下载】
	if [ "\$NUM" -le "2" ] || [ ! -s "$xunleis_dir/xunlei/portal" ] ; then # 【迅雷下载】
		logger -t "【迅雷下载】" "重新启动\$NUM" # 【迅雷下载】
		nvram set xunleis_status=00 && eval "$scriptfilepath &" && sed -Ei '/【迅雷下载】|^$/d' /tmp/script/_opt_script_check # 【迅雷下载】
	fi # 【迅雷下载】
OSC
return
fi

while true; do
	if [ ! -s "$xunleis_dir/xunlei/portal" ] ; then
		logger -t "【迅雷下载】" "找不到文件 $xunleis_dir/xunlei/portal"
		xunleis_restart
	fi
	running=$(ps -w | grep "/xunlei/lib/" | grep -v "grep" | wc -l)
	if [ $running -le 2 ] ; then
		logger -t "【迅雷下载】" "重新启动$running"
		xunleis_restart
	fi
sleep 251
done
}

xunlei_close () {
kill_ps "$scriptname keep"
sed -Ei '/【迅雷下载】|^$/d' /tmp/script/_opt_script_check
killall ETMDaemon EmbedThunderManager vod_httpserver portal
killall -9 ETMDaemon EmbedThunderManager vod_httpserver portal
rm -f "/opt/etc/init.d/$scriptname"
kill_ps "/tmp/script/_xun_lei"
kill_ps "_xun_lei.sh"
kill_ps "$scriptname"
}

xunlei_start () {
check_webui_yes
SVC_PATH="$xunleis_dir/xunlei/portal"
if [ ! -s "$SVC_PATH" ] ; then
	ss_opt_x=`nvram get ss_opt_x`
	upanPath=""
	[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep -E "$(echo $(/usr/bin/find /dev/ -name 'mmcb*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/sd | grep -E "$(echo $(/usr/bin/find /dev/ -name 'sd*') | sed -e 's@/dev/ /dev/@/dev/@g' | sed -e 's@ @|@g')" | grep "/media" | awk '{print $NF}' | sort -u | awk 'NR==1' `"
	if [ "$ss_opt_x" = "5" ] ; then
		# 指定目录
		opt_cifs_dir=`nvram get opt_cifs_dir`
		if [ -d $opt_cifs_dir ] ; then
			upanPath="$opt_cifs_dir"
		else
			logger -t "【opt】" "错误！未找到指定目录 $opt_cifs_dir"
		fi
	fi
	if [ "$ss_opt_x" = "6" ] ; then
		opt_cifs_2_dir=`nvram get opt_cifs_2_dir`
		# 远程共享
		if mountpoint -q "$opt_cifs_2_dir" && [ -d "$opt_cifs_2_dir" ] ; then
			upanPath="$opt_cifs_2_dir"
		else
			logger -t "【opt】" "错误！未找到指定远程共享目录 $opt_cifs_2_dir"
		fi
	fi
	echo "$upanPath"
	if [ -z "$upanPath" ] ; then 
		logger -t "【迅雷下载】" "未挂载储存设备, 请重新检查配置、目录，10 秒后自动尝试重新启动"
		sleep 10
		xunleis_restart x
		exit 0
	fi
	xunleis_dir="$upanPath"
	nvram set xunleis_dir="$upanPath"
	SVC_PATH="$xunleis_dir/xunlei/portal"
fi
SVC_PATH="$xunleis_dir/xunlei/portal"
mkdir -p "$xunleis_dir/xunlei/"
[ -f "$SVC_PATH" ] && portal_md5=`md5sum "$SVC_PATH" | awk -F ' ' '{print $1}'`
xunleimd5="86f8c2c931687c4876bdd8ca5febe038"
if [ ! -s "$SVC_PATH" ] || [ $portal_md5 != $xunleimd5 ] ; then
	logger -t "【迅雷下载】" "找不到 $SVC_PATH ，安装 Xware1.0.31_mipsel_32_uclibc 程序"
	Xware1="$hiboyfile/Xware1.0.31_mipsel_32_uclibc.tgz"
	wgetcurl.sh "$xunleis_dir/xunlei/Xware1.tgz" "$hiboyfile/Xware1.0.31_mipsel_32_uclibc.tgz" "$hiboyfile2/Xware1.0.31_mipsel_32_uclibc.tgz"
	untar.sh "$xunleis_dir/xunlei/Xware1.tgz" "$xunleis_dir/xunlei" "$SVC_PATH"
fi
if [ ! -s "$SVC_PATH" ] ; then
	logger -t "【迅雷下载】" "找不到 $SVC_PATH ，需要手动安装 Xware1.0.31_mipsel_32_uclibc"
	logger -t "【迅雷下载】" "启动失败, 10 秒后自动尝试重新启动" && sleep 10 && xunleis_restart x
fi
chmod 777 "$xunleis_dir/xunlei" -R
logger -t "【迅雷下载】" "启动程序"
cd "$xunleis_dir/xunlei"
export LD_LIBRARY_PATH="$xunleis_dir/xunlei/lib:/lib:/opt/lib"
eval "$xunleis_dir/xunlei/portal $cmd_log" &
sleep 2
export LD_LIBRARY_PATH="/lib:/opt/lib"
sleep 5
[ ! -z "$(ps -w | grep "/xunlei/lib/" | grep -v grep )" ] && logger -t "【迅雷下载】" "启动成功" && xunleis_restart o
[ -z "$(ps -w | grep "/xunlei/lib/" | grep -v grep )" ] && logger -t "【迅雷下载】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && xunleis_restart x
initopt
xunlei_get_status
eval "$scriptfilepath keep &"
exit 0
}

initopt () {
optPath=`grep ' /opt ' /proc/mounts | grep tmpfs`
[ ! -z "$optPath" ] && return
if [ ! -z "$(echo $scriptfilepath | grep -v "/opt/etc/init")" ] && [ -s "/opt/etc/init.d/rc.func" ] ; then
	{ echo '#!/bin/sh' ; echo $scriptfilepath '"$@"' '&' ; } > /opt/etc/init.d/$scriptname && chmod 777  /opt/etc/init.d/$scriptname
fi

}

case $ACTION in
start)
	xunlei_close
	xunlei_check
	;;
check)
	xunlei_check
	;;
stop)
	xunlei_close
	;;
keep)
	#xunlei_check
	xunlei_keep
	;;
*)
	xunlei_check
	;;
esac

