#!/data/data/com.termux/files/usr/bin/bash
folder=manjaro-fs
dlink="https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/Pacman/Manjaro"
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
tarball="manjaro.tar.xz"
if [ "$first" != 1 ];then
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "Decompressing Rootfs, please be patient."
	proot --link2symlink tar -xf ${cur}/$tarball --exclude='dev'|| :
	cd "$cur"
fi
mkdir -p manjaro-binds
bin=start-manjaro.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A manjaro-binds)" ]; then
    for f in manjaro-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b manjaro-fs/root:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=en_US.UTF-8"
command+=" LC_ALL=C"
command+=" LANGUAGE=en_US"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "fixing permissions for manjaro"
chmod 755 -R manjaro-fs

#DE installation

rm -rf $folder/root/.bash_profile
wget $dlink/lxqt_de.sh -O $folder/root/lxqt_de.sh
rm -rf $folder/etc/resolv.conf
echo " #!/bin/bash
echo 'nameserver 1.1.1.1' >> /etc/resolv.conf
pacman-mirrors -g && pacman -Syyuu --noconfirm && pacman -S wget sudo --noconfirm mkdir -p ~/.vnc
clear
if [ ! -f /root/lxqt_de.sh ]; then
    wget --tries=20 $dlink/lxqt_de.sh -O /root/lxqt_de.sh
    bash ~/lxqt_de.sh
else
    bash ~/lxqt_de.sh
fi
clear
if [ ! -f /usr/local/bin/vncserver-start ]; then
    wget --tries=20  $dlink/XFCE4/vncserver-start -O /usr/local/bin/vncserver-start 
    wget --tries=20 $dlink/XFCE4/vncserver-stop -O /usr/local/bin/vncserver-stop
    chmod +x /usr/local/bin/vncserver-stop
    chmod +x /usr/local/bin/vncserver-start
fi
if [ ! -f /usr/bin/vncserver ]; then
    pacman -S tigervnc --noconfirm > /dev/null
fi
clear
rm -rf ~/.bash_profile" > $folder/root/.bash_profile 

bash $bin
