                       Upgrade Pi-Star Bookworm to Trixie!
                                  In Place!

Yes, you read that right! You CAN upgrade a working (or new build) image of Pi-Star
from its current Debian Bookworm implementation to a Debian Trixie implementation
in place.  But... there's always a butt ... there's no quarantee the upgrade will
work in all cases, just because.

                -- For experienced Pi-Star/Linux users only! --

Because an in-place upgrade such as this is involved/complicated, this undertaking
should not be taken lightly.  You need to have a good working knowledge of Linux
and the Linux CLI as well as some understanding of how Pi-Star works.

The intended audience here are those who want to get a leg up on the next Debian
platform for Pi-Star and are willing to spend the time testing the resulting upgrade,
looking for problems and possible solutions, and otherwise contribute feedback and
suggestions to make this kind of upgrade a success for everyone.

(You can, of course, simply wait until an official release of Pi-Star/Trixie is
announced, or you can join the crowd at the forefront of the coming changes.)

Presented herein is a BASH script that automates (organizes) the steps involved.
It assumes you are working with the lastest Pi-Star version (4.3.4) or similar variants.

This upgrade was worked out on RPI 3/4/5B systems with USB and NVME drives with direct
ethernet connections. Upgrading using a micro-SD should be possible but will be vary slow
and has not been tested. Wireless over WiFi may be problematic as the process may
disconnect as components are replaced/restarted so that has not been fully tested.

As always, make a backup - or use a clone - of your system before attempting this
upgrade.

Here are the basic steps taken to upgrade from Bookworm to Trixie, adapted from the
steps given here, but with additions to handle Pi-Star specifically:

   <https://forums.raspberrypi.com/viewtopic.php?t=392376>
   <https://linux.how2shout.com/how-to-upgrade-debian-12-bookworm-to-13-trixie/>

Outline:
   (Modify boot for generic devices?)
   
   Shutdown key Pi-Star processes so they don't interfer with the update process

   Bring the current Bookworm system up-to-date:
        sudo apt update
        sudo apt upgrade

   Modify the APT source files to point to Trixie

   Start the transition to Trixie:
        sudo apt update
        sudo apt upgrade --without-new-pkgs

   Complete the upgrade:
        sudo apt full-upgrade

   Remove obsolete/unneeded programs:
        sudo apt autoremove

   Complete installation of new PHP/FPM 8.4 (install missing components)
   Modify NGINX config for new PHP

   Set up to use current Python (3.13)

   Fix up various configs (deprecations)

   Fix non-compliant Pi-Star Python programs? (deprecation warnings)

   Restart key Pi-Star process previously stopped

Installation:

   Start by downloading and placing the BASH script file in the /home/pi-star
   directory:

      rpi-rw
      wget 'https://raw.githubusercontent.com/kn2tod/pistar-trixie-upgrade/main/Trixie-Upgrade.sh'

   and then execute it:

      sudo bash Trixie-Upgrade.sh [x]

   [x] may be any character; omit the argument if you want to see ALL of the
   messages issued by the APT process.

   The installation will take about 25-30 minutes for a typical SSD/NVME; about 1.5 hours for a
   typical USB.  Note that you will be required to respond to various prompts during that time.

   At the end, your system should be up and running on Trixie; check out the
   dashboard and make sure everything looks ok; reboot to confirm a clean start
   and check again.

Post-Installation:

   The Raspbian system will update as usual with fixes being propogated for 
   Trixie; updates to Pi-Star (either from a manual update request or via the 
   nightly processing) will break some things with python programs that will 
   require manual intervention:

   (tbc)

