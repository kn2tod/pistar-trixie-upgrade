#!/bin/bash
# ===========================================================================================================
# Upgrade Pi-Star Bookworm system to Trixie in-place:
#
# ref: https://forums.raspberrypi.com/viewtopic.php?t=392376
#      https://linux.how2shout.com/how-to-upgrade-debian-12-bookworm-to-13-trixie/
#
# Basic updates/changes:
#   1) bring current (Bookworm) system up-to-date
#   2) modify APT files for Trixie, run the update/upgrade APT process
#   3) complete the full upgrade
#   4) correct links for Python; install missing PHP/FPM components
#   5) apply minor fixes and reconfigurations for new version of various apts
#
# Assumptions:
#   Starting from a current Raspbian/Pi-Star BOOKWORM system: all applicable updates applied
#   Dormant system: system should not be actively running: mmdvm, cron, etc. i.e. Pi-Star should be "down"
#    (at a minimum, the NGINX, PISTAR-WATCHDOG, PISTAR-REMOTE, and MMDVMHOST tasks should be stopped)
#   python programs previously updated to spec
#   Tested on a fully-wired (ethernet) system
#
# Prelims:
#   If starting with a (working) fresh image:
#   - timezone may need to be set (e.g. sudo timedatectl set-timezone 'America/New_York')   # !!!!!!!
#     or set timezone/language in Pi-Star's config panel
#   - run Pi-Star's update/upgrade to bring app up-to-date
#   - run APT update/upgrade to bring system up-to-date
#
# Pre/Post-Install Anomalies:
#   1) Pi-Star's task to remount read-only at 17 past may need to be temporarily stopped
#   2) new version of Python requires changes to PISTAR-REMOTE/WATCHDOG programs
#   3) may need to readjust PHP-FPM params
#
# This process can be restarted from the top but with caution
#
# Testing:
#   Rpi-3B+, wired, USB, unconfigured new Pi-Star image (approx 1hour 15 mins)
#   Rpi-5B, wired, NVME, unconfigured new Pi-Star image (approx 20 mins)
#
# ===========================================================================================================
q=${1:-"-qq"}       # invoke script with an argument ("x") to supress APT messages
echo $q

t1=$SECONDS

echo "===============================> Start in-place Bookworm -> Trixie update process:"
if [ ! "$(grep -i "bookworm\|trixie" /etc/os-release)" ]; then
  echo "Only BOOKWORM/TRIXIE systems can be upgraded"
  exit 1
fi

#rpi-rw:
sudo mount -o remount,rw / 2>/dev/null
sudo mount -o remount,rw /boot$(sed -n "s|/dev/.*/boot\(.*\) [ve].*|\1|p" /proc/mounts) 2>/dev/null

echo "===============================> Initial OS info:"
cat /etc/os-release
echo "==="
cat /etc/debian_version         # display current system/version
echo "==="
hostnamectl                     # display debian codename
echo "==="
lsb_release -a
echo "==="
uname -mrs
echo "==="
cat /boot/cmdline.txt
echo "==="
cat /etc/fstab
echo "==="
cat /etc/crontab
echo "==="
read -p "-- press any key to continue --" ipq

echo "===============================> Stopping Pi-Star services:"
sudo systemctl stop cron                    #2>/dev/null

sudo systemctl stop pistar-remote           #2>/dev/null
sudo systemctl stop pistar-remote.timer     #2>/dev/null
sudo systemctl stop pistar-watchdog         #2>/dev/null
sudo systemctl stop pistar-watchdog.timer   #2>/dev/null
sudo systemctl stop mmdvmhost.timer         #2>/dev/null
sudo systemctl stop mmdvmhost.service       #2>/dev/null
sudo systemctl stop nextiondriver.service   #2>/dev/null

read -p "-- press any key to continue --" ipq

echo "===============================> Make it up-to-date:"
#if [ ! "$(grep trixie /etc/apt/sources.list)" ]; then   # (skip if this proc has been restarted)

phpp=$(php -v 2> /dev/null | sed -n "s/PHP \([0-9].[0-9]\).*/\1/p")  # save current php version for later
echo "-- Current PHP version: ${phpp}"
py=$(python -V 3>&1 1>&2 2>&3 3>&1 1>&2)
echo "-- Current Python version: ${py}"
echo " "

read -p "--update current system: (Y/n)? " ipq
if [ "$ipq" == "Y" ]; then
# pre-migration/prep: bring system update-to-date; clean:
sudo apt update
read -p "-- press any key to continue --" ipq
echo "==="
sudo apt upgrade --fix-missing --fix-broken -y
read -p "-- press any key to continue --" ipq
echo "==="
sudo apt dist-upgrade
read -p "-- press any key to continue --" ipq
echo "==="
#sudo apt purge -y raspberrypi-ui-mods   # ?????
#echo "==="
echo "===============================> Cleanup:"
sudo apt autoremove -y
echo "==="
sudo apt autoclean
echo "==="
echo "===============================> Preliminary updates finished"
read -p "-- press any key to continue --" ipq
fi
# redirect: bookworm --> trixie:
echo "===============================> Mod APT source lists for new OS:"
sudo sed -i 's/bookworm/trixie/g' /etc/apt/{sources.list,sources.list.d/*}
cat /etc/apt/{sources.list,sources.list.d/*} | grep -v "#"
echo "==="
sudo sync; sudo sync
read -p "-- press any key to continue --" ipq

echo "===============================> Start OS update:"
sudo apt update -y $q
echo "==="

#sudo apt install debian-keyring raspbian-archive-keyring   # ????

read -p "-- press any key to continue --" ipq
echo "===============================> Start OS upgrade:"

sudo apt upgrade --without-new-pkgs --fix-missing --fix-broken -y $q
echo "==="
read -p "-- press any key to continue --" ipq
sudo apt full-upgrade --fix-missing --fix-broken -y $q
echo "==="
read -p "-- press any key to continue --" ipq
#sudo apt autoremove --purge
sudo apt autoremove -y
echo "==="
read -p "-- press any key to continue --" ipq
sudo apt autoclean
echo "==="
sudo sync; sudo sync
read -p "-- press any key to continue --" ipq

# post-migration:
sudo apt list --upgradable
echo "==="
read -p "-- press any key to continue --" ipq

# set link to latest Python:
sudo ln -fs /usr/bin/python3.13 /usr/bin/python
python -V
echo "==="

# install extra PHP modules needed by Pi-Star:
phpv=$(php -v 2> /dev/null | sed -n "s/PHP \([0-9].[0-9]\).*/\1/p")  # ????
echo "$(php -v 2>/dev/null| sed -n "s/\(PHP [0-9.]*\) .*/\1/p" 2>/dev/null)"
sudo apt install php${phpv}-fpm      -y
echo "==="
sudo apt install php${phpv}-mbstring -y
echo "==="
sudo apt install php${phpv}-zip      -y
echo "==="

# reset pm.* settings for PHP-FPM:
sudo sed -i "s/^\(pm =\).*$/\1 dynamic/g"              /etc/php/${phpv}/fpm/pool.d/www.conf
sudo sed -i "s/^\(pm.max_children =\).*$/\1 15/g"      /etc/php/${phpv}/fpm/pool.d/www.conf
sudo sed -i "s/^\(pm.start_servers =\).*$/\1 8/g"      /etc/php/${phpv}/fpm/pool.d/www.conf
sudo sed -i "s/^\(pm.min_spare_servers =\).*$/\1 4/g"  /etc/php/${phpv}/fpm/pool.d/www.conf
sudo sed -i "s/^\(pm.max_spare_servers =\).*$/\1 8/g"  /etc/php/${phpv}/fpm/pool.d/www.conf

sudo systemctl restart php${phpv}-fpm
echo "==="
sudo systemctl status  php${phpv}-fpm
echo "==="

read -p "-- press any key to continue --" ipq

# Point NGINX to proper FPM:
sudo sed -i "s/\/php${phpp}-fpm.sock/\/php${phpv}-fpm.sock/g" /etc/nginx/default.d/php.conf
#sudo sed -i 's/ssl_protocols TLSv1 TLSv1.1 TLSv1.2/ssl_protocols TLSv1.2 TLSv1.3/p' /etc/nginx/nginx.conf   # ????
cat /etc/nginx/default.d/p/php.conf
echo "==="
sudo nginx -t                          # config check
read -p "-- press any key to continue --" ipq

sudo truncate -s 0 /var/log/nginx/error.log   # clear eroneous msgs that occur during upgrade

sudo systemctl restart nginx           # restart just-in-case
sudo systemctl status  nginx
sudo systemctl restart php${phpv}-fpm  # restart just-in-case
sudo systemctl status  php${phpv}-fpm

sudo systemctl disable exim4.service   # reactivated by migration?!?
sudo systemctl mask exim4.service
echo "==="
sudo sync; sudo sync
read -p "-- press any key to continue --" ipq

# sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0E98404D386FA1D9
lsb_release -a
echo "==="
cat /etc/debian_version
echo "==="
uname -a
echo "==="

#sudo apt install debian-keyring debian-archive-keyring
#sudo apt install debian-keyring raspbian-archive-keyring   # ????
sudo apt install debian-keyring -y
echo "==="

# Fix deprecated SSH config options:
sudo sed -i 's/^UsePrivilegeSeparation/# &/g'  /etc/ssh/sshd_config
sudo sed -i 's/^KeyRegenerationInterval/# &/g' /etc/ssh/sshd_config
sudo sed -i 's/^ServerKeyBits/# &/g'           /etc/ssh/sshd_config
sudo sed -i 's/^RSAAuthentication/# &/g'       /etc/ssh/sshd_config
sudo sed -i 's/^RhostsRSAAuthentication/# &/g' /etc/ssh/sshd_config

sudo sync; sudo sync
echo "==============================> End of Bookworm-Trixie upgrade"
echo " "

echo "==============================> restart Pi-Star services"
sudo systemctl start pistar-remote           #2>/dev/null
sudo systemctl start pistar-remote.timer     #2>/dev/null
sudo systemctl start pistar-watchdog         #2>/dev/null
sudo systemctl start pistar-watchdog.timer   #2>/dev/null
sudo systemctl start mmdvmhost.timer         #2>/dev/null
sudo systemctl start mmdvmhost.service       #2>/dev/null
sudo systemctl start nextiondriver.service   #2>/dev/null

sudo systemctl start cron                    #2>/dev/null

t2=$SECONDS
echo "--- (time to complete upgrade: " $(($t2-$t1)) "secs)"

#debn=$(hostnamectl 2>/dev/null | sed -n "s/.* System: .* (\([a-zA-Z0-9]*\))/\u\1/p")
debn=$(cat /etc/os-release | sed -n 's/VERSION_CODENAME=\(.*\)/\u\1/p')
#echo "..kernel:" $(sed -n "s|Linux version \([0-9A-Za-z.+-]*\).*|\1|p" /proc/version)
bits=$(od -An -t x1 -j 4 -N 1 "$(readlink -f /sbin/init)")
arch=(? 32 64)
echo " "
echo "..kernel:" $(uname -r) "("${arch[$bits]}-bit") ${debn}"
echo "..cpu:   " $(sed -n "s|^Model.*: ||p" /proc/cpuinfo)
echo "..       " $(sed -n "s|^Hardware.*: ||p" /proc/cpuinfo) "-" $(sed -n "s|^Revision.*: ||p" /proc/cpuinfo) "-" $(sed -n "s|^Serial.*: ||p" /proc/cpuinfo)
echo " "
unset debn bits arch
#reboot

read -p "--check configs: (Y/n)? " ipq
if [ "$ipq" == "Y" ]; then
diffr='sudo diff -a -y -t -B -b -Z --suppress-common-lines --strip-trailing-cr --ignore-trailing-space'
echo "=== /etc/issue"
$diffr /etc/issue                    /etc/issue.dpkg-dist
read -p "-- press any key to continue --" ipq

echo "=== /etc/dhcpcd.conf"
$diffr /etc/dhcpcd.conf              /etc/dhcpcd.conf.dpkg-dist                 # review?
read -p "-- press any key to continue --" ipq

echo "=== /etc/dhcp/.../resolvconf"
$diffr /etc/dhcp/dhclient-enter-hooks.d/resolvconf /etc/dhcp/dhclient-enter-hooks.d/resolvconf.dpkg-dist
read -p "-- press any key to continue --" ipq

echo "=== /etc/systemd/journald.conf"
$diffr /etc/systemd/journald.conf    /etc/systemd/journald.conf.dpkg-dist
read -p "-- press any key to continue --" ipq

echo "=== /etc/crontab"
$diffr /etc/crontab                  /etc/crontab.dpkg-dist                     # review?
read -p "-- press any key to continue --" ipq

echo "=== /etc/dnsmasq.conf"
$diffr /etc/dnsmasq.conf             /etc/dnsmasq.conf.dpkg-dist                # review?
read -p "-- press any key to continue --" ipq

echo "=== /etc/bash.bashrc"
$diffr /etc/bash.bashrc              /etc/bash.bashrc.dpkg-dist                 # review?
read -p "-- press any key to continue --" ipq

echo "=== /etc/nginx/nginx.conf"
$diffr /etc/nginx/nginx.conf         /etc/nginx/nginx.conf.dpkg-dist            # review?
read -p "-- press any key to continue --" ipq

echo "=== etc/ntpsec/ntp.conf"
$diffr /etc/ntpsec/ntp.conf          /etc/ntpsec/ntp.conf.dpkg-dist             # review?
read -p "-- press any key to continue --" ipq

echo "=== /etc/cron.hourly/fake-hwclock"
$diffr /etc/cron.hourly/fake-hwclock /etc/cron.hourly/fake-hwclock.dpkg-dist
read -p "-- press any key to continue --" ipq

echo "=== /etc/default/hostapd"
$diffr /etc/default/hostapd          /etc/default/hostapd.dpkg-dist
read -p "-- press any key to continue --" ipq

echo "=== /etc/sudoers"
$diffr /etc/sudoers                  /etc/sudoers.dpkg-dist
read -p "-- press any key to continue --" ipq

#echo "=== 50unattneded-upgrades"
#$diffr /usr/share/unattended-upgrades/50unattended-upgrades /etc/apt/apt.conf.d/
#read -p "-- press any key to continue --" ipq

#echo "=== /etc/smartd.conf"
#$diffr /etc/smartd.conf              /etc/smartd.conf.dpkg-dist
#read -p "-- press any key to continue --" ipq

#echo "=== /etc/nanorc"
#$diffr /etc/nanorc                   /etc/nanorc.dpkg-old

unset diffr
fi

# Are we done now?!?!
echo "  DONE!  "
