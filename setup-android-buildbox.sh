#!/bin/bash
#
# Will setup build environment on Debian 7.x (Wheezy) for Android
#
# Created By: Ryan Wilson (rjwil1086@gmail.com)
#

# Install sudo and add user to sudo group if not already setup
# This requires ROOT access to the vm
if [ ! -e /usr/bin/sudo ]
then
 # Sudo isn't installed. Lets install it
 echo "Sudo isn't installed. Let's install is real quick"
 echo "You will need the password to the root user to continue"
 user=$(whoami)
 su -c "apt-get -y install sudo ; usermod -a -G sudo $user" -m root
 echo "OK sudo is setup. Login again and re-run the script to continue"
 login $user
fi

# Ask what java version to install
clear
echo "**"
echo "* Which version of Java do you want?"
echo "* Java 1.6 is for CyanogenMod 11 and older"
echo "* Java 1.7 is for CyanogenMod 12"
echo "*"
echo "* 1) Oracle Java JDK 1.6"
echo "* 2) OpenJDK 1.6"
echo "* 3) OpenJDK 1.7"
echo "**"
read javaversion
sudo apt-get update

if [ $javaversion -eq 1 ]
then
 echo " Installing Oracle Sun JDK 1.6"
 echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | sudo tee /etc/apt/sources.list.d/webupd8team-java.list
 echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main" | sudo tee -a /etc/apt/sources.list.d/webupd8team-java.list
 sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
 sudo apt-get update
 sudo apt-get -y install oracle-java6-installer
 java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c 1-3)
 if [ $java_version -ne 1.6 ]
 then
  echo "We installed Sun JDK 1.6, but it isn't the version being used. You will have to select Sun JDK 1.6 from the alternatives"
  read -p "Press [Enter] to continue"
  update-alternatives --config java
  update-alternatives --config javac
 fi
elif [ $javaversion -eq 2 ]
then
 echo " Installing Open JDK 1.6"
 sudo apt-get -y install openjdk-6-jdk
 java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c 1-3)
 if [ $java_version -ne 1.6 ]
 then
  echo "We installed Open JDK 1.6, but it isn't the version being used. You will have to select JDK 1.7 from the alternatives"
  read -p "Press [Enter] to continue"
  update-alternatives --config java
  update-alternatives --config javac
 fi
else
 echo " Installing Open JDK 1.7"
 sudo apt-get -y install openjdk-7-jdk
 java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -c 1-3)
 if [ $java_version -ne 1.7 ]
 then
  echo "We installed Open JDK 1.7, but it isn't the version being used. You will have to select JDK 1.7 from the alternatives"
  read -p "Press [Enter] to continue"
  update-alternatives --config java
  update-alternatives --config javac
 fi
fi

# Install all necesary software
sudo apt-get -y install git gnupg flex bison gperf build-essential \
  zip curl libc6-dev libncurses5-dev x11proto-core-dev \
  libx11-dev libreadline6-dev libgl1-mesa-glx \
  libgl1-mesa-dev g++-multilib mingw32 tofrodos \
  python-markdown libxml2-utils xsltproc zlib1g-dev \
  schedtool lib32z1 lib32z1-dev htop

# create folders and setup variables
cp ~/.bashrc .bashrc_old
mkdir ~/ccache
mkdir ~/bin

# Add USE_CCACE to .bashrc if it isn't already there
if ! grep -Fq "USE_CCACHE" ~/.bashrc
then
echo 'export USE_CCACHE=1' >> ~/.bashrc
fi

# Add CCACHE_DIR to .bashrc if it isn't already there
if ! grep -Fq "CCACHE_DIR" ~/.bashrc
then
echo 'export CCACHE_DIR=~/ccache' >> ~/.bashrc
fi

if ! grep -Fq "PATH=$PATH:~/bin" ~/.bashrc
then
echo 'PATH=$PATH:~/bin' >> ~/.bashrc
fi

source ~/.bashrc

clear
echo "Lets setup git"
echo ""
if [ ! -e ~/.gitconfig ]
then
 echo "Please enter your name"
 read proper_name
 git config --global user.name "$proper_name"
 echo "Please enter your email address"
 read email_address
 git config --global user.email "$email_address"
fi


# Download and setup repo
if [ ! -e ~/bin/repo ]
then
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
fi

# Choose which source code to use
clear
echo ""
echo "Please choose which source you want: "
echo " 1. AOSP"
echo " 2. CyanogenMod"
echo " 3. OmniROM"
echo " 4. NONE"
echo ""
echo "** Remember this will take a long time depending on your internet **"
read source_name
omni="https://github.com/omnirom/android"
cyan="https://github.com/CyanogenMod/android"
aosp="https://android.googlesource.com/platform/manifest"
branch="cm-12.0"
has_source=false
if [ $source_name -eq 1 ]
then
 has_source=true
 mkdir /tmp/git
 cd /tmp/git
 git init
 git remote add temp $aosp
 clear
 echo "** Distro Branch List **"
 git ls-remote --heads temp | sed -r 's/^.{52}//'
 cd ~/
 rm -rf /tmp/git
 echo "**"
 echo "** Type in the branch you want to sync"
 echo "**"
 read branch
 mkdir $branch
 cd $branch
 source_code="$aosp -b $branch"
elif [ $source_name -eq 2 ]
then
 has_source=true
 mkdir /tmp/git
 cd /tmp/git
 git init
 git remote add temp $cyan
 clear
 echo "** Distro Branch List **"
 git ls-remote --heads temp | sed -r 's/^.{52}//'
 cd ~/
 rm -rf /tmp/git
 echo "**"
 echo "** Type in the branch you want to sync"
 echo "**"
 read branch
 mkdir $branch
 cd $branch
 source_code="$cyan -b $branch"
elif [ $source_name -eq 3 ]
then
 has_source=true
 mkdir /tmp/git
 cd /tmp/git
 git init
 git remote add temp $omni
 clear
 echo "** Distro Branch List **"
 git ls-remote --heads temp | sed -r 's/^.{52}//'
 cd ~/
 rm -rf /tmp/git
 echo "**"
 echo "** Type in the branch you want to sync"
 echo "**"
 read branch
 mkdir $branch
 cd $branch
 source_code="$omni -b $branch"
elif [ $source_name -eq 4 ]
then
 echo "FINE!  Download your own sources :)"
else
 has_source=true
 source_code="$cyan -b $branch"
 cd ~/
 mkdir $branch
 cd $branch
 echo "Defaulting to CM12"
fi

if $has_source
then
# Initialize the repo and begin sync
clear
cd ~/$branch
echo "You are about to sync [$source_code] into [~/$branch]"
echo "This will take a while so go grab a cub of joe and sit back"
echo ""
read -p "Press [Enter] to continue..."
if [ ! -d ~/$branch ]
then
repo init -u $source_code
fi
repo sync 2>&1
fi

# Configure CCACHE
clear
echo "** Configure CCACHE"
echo "*"
echo "* How big do you want CCACHE to be?"
echo "* 50GB should be your starting point for 1 device"
echo "* If you plan on building for multiple devices"
echo "* COnsider adding more"
echo "*"
echo "* Input e.x. [50G] or [100G]"
read ccache_size
export CCACHE_DIR=~/ccache/
cd ~/$branch/prebuilts/misc/linux-x86/ccache/
./ccache -M $ccache_size

# Process complete
clear
echo "You have completely configured your Android Build Box."
echo "Conrats and have fun learning"
