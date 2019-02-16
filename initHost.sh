#!/bin/bash

##################################################
# Shell script to initialize a raspberry pi
# image that was created using the tools at
# https://github.com/michaelfranzl/rpi23-gen-image
#
# Initialization will install lxde (if specified)
# will setup the Raspberry Pi to run the SIL Ansible
# scripts
##################################################

INSTALL_LXDE=0
LF_REPO="https://github.com/sillsdev/web-languageforge.git"

printUsage()
{
  cat <<.EOM
Usage: $0 [options]

Options:
   --lxde
      Install the LXDE desktop environment before other setup tasks.
   --repo=<repository URL>
      Use the specified repository instead of the default SIL repo
   --saaz
      Shortcut for --repo=grady@10.0.0.32:/home/grady/projects/sil/xForge/web-languageforge

The script sets up a target to be ready to run the SIL ansible playbooks.
It will:
 * update the apt cache and upgrade all installed packages
 * install the LXDE desktop environment (if specified)
 * add the ansible PPA to sources
 * add the ansible repo key
 * install git and ansible
 * install nodejs 8.X and latest npm
 * clone the web-languageforge repository into ~/src
.EOM
  exit 2
}

##################################################
#
#   M A I N
#
##################################################


while [ "$#" -gt 0 ] ;
do
    case "$1" in
  	--lxde)   INSTALL_LXDE=1;;
    --repo=*) if [[ "$1" =~ --repo=(.*) ]] ; then
                LF_REPO=${BASH_REMATCH[1]}
              else
                echo -e "Could not find repository name."
              fi;;
    --saaz)   LF_REPO="grady@10.0.0.32:/home/grady/projects/sil/xForge/web-languageforge";;
	  -?)			  printUsage;;
	  --help)		printUsage;;
	  *)        echo -e "Unknown Option: $1";;
    esac
    shift
done

if [ "$INSTALL_LXDE" -eq "1" ] ; then
  sudo apt-get install lxde lxsession-logout lightdm lightdm-gtk-greeter
fi

sudo apt-get update
sudo apt-get -y install software-properties-common python-software-properties apt-transport-https
sudo add-apt-repository ppa:ansible/ansible
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 # TODO move this to Ansible
sudo apt-get update
sudo apt-get -y install git ansible

echo Install NodeJS 8.X and latest npm
wget -O- https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt-get install -y nodejs

# Runs the rest of the script as vagrant
set -eux

[ -d ~/src ] || mkdir ~/src

cd ~/src
if [ ! -d "web-languageforge" ]; then
  git clone --recurse-submodules ${LF_REPO}
else
  cd web-languageforge
  git pull --ff-only --recurse-submodules
fi

cd ~/src
[ -d web-scriptureforge ] || ln -s web-languageforge web-scriptureforge

cd ~/src/web-languageforge/deploy/
git checkout master
