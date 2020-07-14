#!/bin/bash

# 'Copyright (c) 2009,2010,2020 Delphix, All Rights Reserved.'

#RFE:  Dynamically get the ssh key from the engine(s)
#RFE:  Check the package requirements with grep, rather than just reporting them
#RFE:  Warn if oratab is missing or empty
#RFE:  Allow Password flag, but only if not Quiet
#RFE:  Allow Key Flag



#Defaults
#USERNAME="delphix_os"
USERNAME="ranzo2"
HOMEDIR=/home/${USERNAME}
TOOLKIT=${HOMEDIR}/toolkit
NFS_LOCATION=/u01/app/delphix_os/mnt
KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCnI9i9CAP96qeDAIYWDVFdVvchxfCmHoTQ70UiOffLmI5msDv1xIt+OKzeBsAxt8ZYFbR6xxSiLlMfT/C1GaKZVIvW5RyuUhQMMtvTWGagb4S+61xOoJ/zPhMb+8uLcbYw6zCUXgIDS9v19DGau4I0/d0T4nUcMg1F8oonfkVLzI9JghsbPwkL5C2mVwdoOa8pUqcvuHb3oQ7ULLq7+RyoQbpLA2Gsmg55ThXsa4smb/ueOfF9XUfZW+DOQ/qo5olGQCoSH1CKBe8S1w/CYOqJZSvaD72nRjTR1aJKvQdA+gCjKEZ3tl+pmXnoD0AbctEJIZBMB/h27uwzuoLfdTPV root@ip-10-234-194-100"

MOUNT="/bin/mount /u01/app/delphix_os/mnt/*, /bin/mount * /u01/app/delphix_os/mnt/*"
UMOUNT="/bin/umount /u01/app/delphix_os/mnt/*, /bin/umount * /u01/app/delphix_os/mnt/*"
MKDIR="/bin/mkdir -p -m 755 /u01/app/delphix_os/mnt/*, /bin/mkdir -p /u01/app/delphix_os/mnt/*, /bin/mkdir /u01/app/delphix_os/mnt/*"
RMDIR="/bin/rmdir /u01/app/delphix_os/mnt/*"
PS="/bin/ps"

#Command Flag Defaults
CREATEUSER=false
#We leave AUTHTYPE unset
SUDO=false
KERNEL=false
QUIET=false

# Set the PATH
PATH=${PWD}:/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:${PATH}; export PATH

# Set NOW
NOW=$(date +"%m%d%Y%H%m%s")

# The current user ID
CURRENT_USER=`id | awk -F'=' '{print $2}' | cut -d'(' -f2 | cut -d')' -f1`


# Functions
# Function to read a Y/N option from the user
yes_or_no() {
    option=""
    if [ ${QUIET} = "true" ]; then 
      option=Y
    else
      read option
      while [ "${option}" != "Y" ] && [ "${option}" != "N" ] && [ "${option}" != "y" ] && [ "${option}" != "n" ]; do
          echo "Continue ? (Y/N)"
          read option
      done
    fi

#    if [ "${option}" = "N" ] || [ "${option}" = "n" ]; then
#        #exit 0
#      return
#    fi
}

#Function to print a help message
usage() { 
  echo
  echo 'Copyright (c) 2009,2010,2020 Delphix, All Rights Reserved.'
  echo
  echo "Usage: $0 -t source|target [ -a key|passwd ] [ -u ] [ -k ] [ -s ] [ -q ]" 
  echo
  echo "-t : Type <source or target>.  REQUIRED PARAMETER"
  echo 
  echo "-u : Create User. OPTIONAL"
  echo
  echo "-a : Auth Type <key or passwd>. OPTIONAL"
  echo "     key: Add SSH Public Key for Delphix Engine to authorized_keys for the user."
  echo "     passwd: Add a password using the passwd utility.  Not compatible with quiet mode"
  echo "     If you don't do either one, you'll be left with a user that cannot login, but you could su as root."
  echo
  echo "-s : sudo privs. OPTIONAL"
  echo "     Delphix targets require some kind of elevated privilege"
  echo "     Delphix sources only require elevated privilege if you use a non default TNS_ADMIN"
  echo "     If you don't use sudo for privilege elevation, you must use Privilege Elevation Profiles which isn't covered by this script."
  echo 
  echo "-k : kernel parameters. This only works for targets.  Highly Recommended for Delphix Targets. OPTIONAL"
  echo 
  echo "-q : Quiet.  Automatically says "Y" to all prompts and accepts defaults.  Specify -y for full automation. OPTIONAL"
}

#Function to exit and print Usage
exit_abnormal() { 
  echo
  echo
  usage
  exit 1
}

#Function to tell the user what the script will do, based on their inputs
info() {
echo "Running for Type: ${TYPE}"
if [ ${QUIET} = "true" ]; then echo "Quiet: ON"; else echo "Quiet: OFF"; fi
if [ ${CREATEUSER} = "true" ]; then echo "Create User: ON"; else echo "Create User: OFF"; fi
if [ -n "${AUTHTYPE}" ]; then echo "Authorization Type: ${AUTHTYPE}"; else echo "Authorization Type: NO LOGIN"; fi
if [ ${SUDO} = "true" ]; then echo "Perform Sudo: ON"; else echo "Perform Sudo: OFF"; fi
if [ ${KERNEL} = "true" ]; then echo "Perform Kernel Tuning: ON"; else echo "Perform Kernel Tuning: OFF"; fi
echo
echo "Default Variable Values:"
echo "USERNAME=${USERNAME}"
echo "HOMEDIR=${HOMEDIR}"
echo "TOOLKIT=${TOOLKIT}"
echo "NFS_LOCATION=${NFS_LOCATION}"
echo "KEY=${KEY}"
echo "MOUNT=${MOUNT}"
echo "UMOUNT=${UMOUNT}"
echo "MKDIR=${MKDIR}"
echo "RMDIR=${RMDIR}"
echo "PS=${PS}"
echo
echo "Derived Values"
echo "PATH=${PATH}"
echo "NOW=${NOW}"
echo "CURRENT_USER=${CURRENT_USER}"
echo
}



#Function to gather some info about this system
facts() {
echo "Gathering Information about this system..."

if [ ${TYPE} = "target" ]; then
  echo "NFS, RPC, gcc RPM needed as a prerequisites for Delphix targets."
  echo "Note: This script will NOT install packages!! It will only list what is already installed."
  echo "Listing those on this system:"
  rpm -qa | grep  compat-libstdc++
  rpm -qa | grep nfs
  rpm -qa | grep rpc
  rpm -qa | grep gcc
  echo
fi

echo "Memory in Kilobytes is as below:"
grep MemTotal /proc/meminfo | awk '{print $2}'
echo

echo "Listener HOME on this server"
ps -ef | grep lsnr|grep -v grep|awk '{print $8}'| awk -F- '{print$1}'
echo

echo "Databases running on this server"
ps -ef | grep smon|grep -v grep|awk '{print $8}'| awk -F_ '{print$3}'
echo
}


#Function to create Delphix OS User like Oracle User
create_delphix_os() {
echo
echo "This script will create a local Delphix OS user to be used for managing this host from a Delphix Engine."
echo "The current user \"${CURRENT_USER}\" should have the privilege to create a OS user on this machine."

echo "Continue ? (Y/N)"
yes_or_no
if [ "${option}" = "N" ] || [ "${option}" = "n" ]; then
  return
fi

# OS user name
echo
echo "Enter the name of the Delphix OS user to be created [default : ${USERNAME}]: If you want default just hit enter"
if [ ${QUIET} = "false" ]; then
  read username
  if [ "${username}" != "" ]; then
    USERNAME=${username}
  fi
fi


echo
echo "The Delphix OS user \"${USERNAME}\" should be part of all OS groups which own Oracle homes (on this host) intended to be used with Delphix."

# Primary Group
PGROUP=`id -Gn oracle | awk {'print $1}'`
echo
echo "Primary Group for user \"${USERNAME}\" [default : ${PGROUP}] :"
if [ ${QUIET} = "false" ]; then
  read pgroup
  if [ "${pgroup}" != "" ]; then
    PGROUP=${pgroup}
  fi
fi

# Supplementary Groups
SGROUPS=`id -Gn oracle | cut -s -d' ' -f2- --output-delimiter=','`
echo
echo "Supplementary Groups for user \"${USERNAME}\" [default : ${SGROUPS}] :"
if [ ${QUIET} = "false" ]; then
  read sgroups
  if [ "${sgroups}" != "" ]; then
    SGROUPS=${sgroups}
  fi
fi

# Home Directory
HOMEDIR=/home/${USERNAME}        #Reset in case the user has chosen a non-default Username
echo
echo "Home directory for the user \"${USERNAME}\" [default : ${HOMEDIR}] :"
if [ ${QUIET} = "false" ]; then
  read homedir
  if [ "${homedir}" != "" ]; then
    HOMEDIR=${homedir}
  fi
fi

# Toolkit Directory
TOOLKIT=${HOMEDIR}/toolkit       #Reset in case the user has chosen a non-default or home directory
echo
echo "Delphix Toolkit Location [default : ${TOOLKIT}] :"
if [ ${QUIET} = "false" ]; then
  read toolkit
  if [ "${toolkit}" != "" ]; then
    TOOLKIT=${toolkit}
  fi
fi


#ONLY IF TARGET
if [ ${TYPE} = "target" ]; then
  echo
  echo "Delphix Mount Point [default : ${NFS_LOCATION}] :"
  if [ ${QUIET} = "false" ]; then
    read nfs_location
    if [ "${nfs_location}" != "" ]; then
      NFS_LOCATION=${nfs_location}
    fi
  fi
fi


# Validate if the parent directory for the home exists
PARENT_DIR=`dirname ${HOMEDIR} 2>/dev/null`
if [ ! -d ${PARENT_DIR} ]; then
    echo "Parent directory \"${PARENT_DIR}\" for the home doesn't exist and will be created."
    echo "Continue ? (Y/N):"
    yes_or_no ${option}
    if [ "${option}" = "N" ] || [ "${option}" = "n" ]; then
     exit 0
    fi
fi

# When here, we are ready to create the user. Confirm with user
echo
echo "Here are the details of the user to be created:"
echo "Username : ${USERNAME}"
echo "Primary Group : ${PGROUP}"
echo "Supplementary Group(s) : ${SGROUPS}"
echo "Home Directory : ${HOMEDIR}"
echo "Toolkit location : ${TOOLKIT}"
if [ ${TYPE} = "target" ]; then
  echo "Delphix Mount Point: ${NFS_LOCATION}"
fi
echo "Set umask 022 for delphix user same as oracle"
echo
echo "Continue ? (Y/N):"
yes_or_no ${option}
if [ "${option}" = "N" ] || [ "${option}" = "n" ]; then
  exit
fi

# Fire the command to create the user
if [ ${SGROUPS} ];  then
    useradd -d ${HOMEDIR} -g ${PGROUP} -G ${SGROUPS} ${USERNAME}
    if [ $? -ne 0 ]; then
        echo "Failed to create user \"${USERNAME}\" with command \"useradd -d ${HOMEDIR} -g ${PGROUP} -G ${SGROUPS} ${USERNAME}\". Please review errors and retry."
        exit 1
    fi
else
    useradd -d ${HOMEDIR} -g ${PGROUP} ${USERNAME}
    if [ $? -ne 0 ]; then
        echo "Failed to create user \"${USERNAME}\" with command \"useradd -d ${HOMEDIR} -g ${PGROUP} ${USERNAME}\". Please review errors and retry."
        exit 1
    fi
fi



echo "Created user \"${USERNAME}\"."

echo "Setting umask for \"${USERNAME}\" to 022 ..."
umask 022 ${USERNAME}
if [ $? -ne 0 ]; then
    echo "\"umask 022 ${USERNAME}\" failed; aborting..."
    exit 1
fi

echo "Creating \"toolkit\"..."
mkdir -p ${TOOLKIT}
if [ $? -ne 0 ]; then
    echo "\"mkdir ${TOOLKIT}\" failed; aborting..."
    exit 1
fi

echo "Setting permissions on \"toolkit\"..."
chown -R ${USERNAME}:${pgroup} ${TOOLKIT}
chmod 770 ${TOOLKIT}
if [ $? -ne 0 ]; then
    echo "\"chmod 770 ${TOOLKIT}\" failed; aborting..."
    exit 1
fi

echo "Setting permissions on \"${HOMEDIR}\" home directory for \"${USERNAME}\" to 755 ..."
chmod 755 ${HOMEDIR}
if [ $? -ne 0 ]; then
    echo "\"chmod 755 ${HOMEDIR}\" failed; aborting..."
    exit 1
fi

echo "Setting ownership of \"${HOMEDIR}\" home directory to \"${USERNAME}\" account and primary group \"${PGROUP}\"..."
chown -R ${USERNAME}:${PGROUP} ${HOMEDIR}
if [ $? -ne 0 ]; then
    echo "\"chown -R ${USERNAME}:${PGROUP} ${HOMEDIR}\" failed; aborting..."
    exit 1
fi


#ONLY FOR TARGET
if [ ${TYPE} = "target" ]; then
  echo "Making Directory on the target host that will be used as a container for the NFS mount point \"${NFS_LOCATION}\"..."
  if [ ! -d ${NFS_LOCATION} ]; then
      mkdir -p ${NFS_LOCATION}
      if [ $? -ne 0 ]; then
          echo "\"mkdir -p ${NFS_LOCATION}\" failed; aborting..."
          exit 1
      fi
  fi 
  echo

  echo "Setting ownership of \"${NFS_LOCATION}\" to \"${USERNAME}\" account and primary group \"${PGROUP}\"..."
  chown -R ${USERNAME}:${PGROUP} ${NFS_LOCATION}
  if [ $? -ne 0 ]; then
    echo "\"chown -R ${USERNAME}:${PGROUP} ${NFS_LOCATION}\" failed; aborting..."
    exit 1
  fi 
  echo

  echo "Setting permissions on \"${NFS_LOCATION}\" to 0770 ..."
  chmod 0770 ${NFS_LOCATION}
  if [ $? -ne 0 ]; then
    echo "\"chmod 0770 ${NFS_LOCATION}\" failed; aborting..."
    exit 1
  fi
  echo


  if [ -f "/etc/oratab" ]; then
    ORA_FILE=/etc/oratab
  else 
    ORA_FILE=/var/opt/oracle/oratab
  fi

  echo "Insure we have group Write permission to the ORACLE_HOME/dbs directory:"
  #To get ORACLE_HOME detail from /etc/oratab in linux and changing the permission of ORACLE_HOME/dbs
  grep -v "^#" $ORA_FILE > /tmp/oratab
  awk -F: '{print $2}' /tmp/oratab > /tmp/oratab1
  for line in $(cat /tmp/oratab1)
  do
    echo "Trying \"chmod g+w ${line}/dbs\"..." 
    chmod g+w ${line}/dbs
    if [ $? -ne 0 ]; then
        echo "\"chmod g+w ${line}/dbs\" failed; aborting..."
        exit 1
    fi
  done
  echo

fi



echo
if [ ${TYPE} = "target" ]; then
  echo "User is Created, Toolkit and NFS Mount created with proper permissions." 
else
  echo "User is Created, Toolkit created with proper permissions."
fi
echo
}

#Function to do Sudo Privs
sudo_privs() {
echo "Next is the sudo permissions.  You should skip this if you're using an alternative privilege elevation technique."
echo
echo "Continue ? If you say N we will skip sudo permissions. (Y/N):"
yes_or_no ${option}
if [ "${option}" = "N" ] || [ "${option}" = "n" ]; then
  return
fi

echo "This script will add the following lines in /etc/sudoers for \"${USERNAME}\""
if [ ${TYPE} = "target" ]; then
  echo "#Delphix Target Permissions"
  echo "Defaults:${USERNAME} !requiretty"
  echo "${USERNAME} ALL=NOPASSWD:${MOUNT},${UMOUNT},${MKDIR},${RMDIR},${PS}"
else
  echo "#Delphix Source Permissions"
  echo "Defaults:${USERNAME} !requiretty" 
  echo "${USERNAME} ALL=NOPASSWD:${PS}" 
fi
echo
echo "Checking existing sudoers file syntax..."
visudo -c
if [ $? -ne 0 ]; then
    echo "Initial \"visudo -c\" failed; aborting..."
    exit 1
fi
cp /etc/sudoers /tmp/sudoers.bak.$NOW
#Old Code to add comments for username
#value=$(cat /tmp/sudoers.bak| grep $USERNAME| wc -l )
#if [ $value -ge 1 ]; then
#    sed -i "/$USERNAME/ s/^/# /" /etc/sudoers
#fi
if [ ${TYPE} = "target" ]; then
  echo "#Delphix Target Permissions" >> /etc/sudoers
  echo "Defaults:${USERNAME} !requiretty" >> /etc/sudoers
  echo "${USERNAME} ALL=NOPASSWD:${MOUNT},${UMOUNT},${MKDIR},${RMDIR},${PS}" >> /etc/sudoers
else
  echo "#Delphix Source Permissions" >> /etc/sudoers
  echo "Defaults:${USERNAME} !requiretty" >> /etc/sudoers
  echo "${USERNAME} ALL=NOPASSWD:${PS}" >> /etc/sudoers
fi

visudo -c
if [ $? -ne 0 ]; then
    echo "Final \"visudo -c\" failed; aborting..."
    echo "We put a copy of the original at /tmp/sudoers.bak.$NOW"
    exit 1
fi


echo "Done with the sudo configuration."
echo
}

#Function to do Target Kernel Parameter Tuning
kernel_parms() {
echo "Next is the Target Kernel Parameter Tunings.  This is optional but highly recommended."
echo
echo "Continue ? If you say N we will skip target tunings. (Y/N):"
yes_or_no ${option}
if [ "${option}" = "N" ] || [ "${option}" = "n" ]; then
  return
fi

echo "Tuning TCP Buffer Sizes - Parameters should be as below"
echo
echo "This script takes the recommended vendor approach of creating a file in /usr/lib/sysctl.d and running \"sysctl -p\""
echo "----"
echo "net.ipv4.tcp_timestamps = 1"
echo "net.ipv4.tcp_sack = 1"
echo "net.ipv4.tcp_window_scaling = 1"
echo "net.ipv4.tcp_rmem = 4096 16777216 16777216"
echo "net.ipv4.tcp_wmem = 4096 4194304 16777216"

cat /dev/null > /usr/lib/sysctl.d/60-sysctl.conf
echo "#Delphix Settings" >> /usr/lib/sysctl.d/60-sysctl.conf
echo "net.ipv4.tcp_timestamps = 1" >> /usr/lib/sysctl.d/60-sysctl.conf
echo "net.ipv4.tcp_sack = 1" >> /usr/lib/sysctl.d/60-sysctl.conf
echo "net.ipv4.tcp_window_scaling = 1" >> /usr/lib/sysctl.d/60-sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 16777216 16777216" >> /usr/lib/sysctl.d/60-sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 4194304 16777216" >> /usr/lib/sysctl.d/60-sysctl.conf

/sbin/sysctl -p /usr/lib/sysctl.d/60-sysctl.conf
if [ $? -ne 0 ]; then
    echo "Command \"sysctl -p /usr/lib/sysctl.d/60-sysctl.conf\" failed; aborting..."
    echo "We put a copy of the original at /tmp/sysctl.conf.$NOW"
    exit 1
fi

echo
}

#Function to add keys
add_ssh_keys() {
echo
echo "Creating and Adding Key to \"${USERNAME}\" authorized_keys file"
mkdir ${HOMEDIR}/.ssh
echo "${KEY}" >> ${HOMEDIR}/.ssh/authorized_keys
chown -R ${USERNAME}:${PGROUP} ${HOMEDIR}/.ssh
chmod 600 ${HOMEDIR}/.ssh/authorized_keys
}

#Function to run passwd
add_passwd() {

echo
echo "Setting password for user \"${USERNAME}\". Enter the password when prompted."
passwd ${USERNAME}
if [ $? -ne 0 ]; then
    echo "Failed to set password for user \"${USERNAME}\". Please review errors and set the password manually."
    exit 1
fi
}







while getopts "kst:quha:" OPTION; do
    case $OPTION in
    k)
        KERNEL=true
        ;;
    s)
        SUDO=true
        ;;
    t)
        TYPE=$OPTARG
        if [ $TYPE != "source" ] && [ $TYPE != "target" ]; then
            echo "-t Type must be \"source\" or \"target\""
            exit_abnormal
        fi
        ;;
    q)
        QUIET=true
        ;;
    u)
        CREATEUSER=true
        ;;
    a)
        AUTHTYPE=$OPTARG
        if [ $AUTHTYPE != "key" ] && [ $AUTHTYPE != "passwd" ]; then
            echo "-a Authorization Type must be \"key\" or \"passwd\""
            exit_abnormal
        fi
        ;;
    h)
        usage
        exit 0
        ;;
    :) 
        echo "Missing option argument for -$OPTARG" >&2
        exit_abnormal
        ;;
    *)
        echo "Incorrect options provided"
        exit_abnormal
        ;;
    esac
done

#Define Mandatory Parameters
if [ -z "$TYPE" ]; then
  echo "You must specify -t <source|target>"
  exit_abnormal
fi

#Define Invalid Parameter Combinations
if [ ${TYPE} = "source" ] && [ ${KERNEL} = "true" ]; then
   echo "It's an invalid combination to use -k and -t source."
   exit_abnormal
fi

if [ ${AUTHTYPE} = "passwd" ] && [ ${QUIET} = "true" ]; then
   echo "It's an invalid combination to use -a passwd and -q (quiet) because the passwd function is interactive."
   exit_abnormal
fi

#Main Action of the script

info                                   #Tell the user what the script will do, based on arguments and default parameters
facts                                  #Report some basic facts about the system
if [ ${CREATEUSER} = true ]; then
  create_delphix_os                    #Create the User
fi
if [ -n "$AUTHTYPE" ]; then
  if [ ${AUTHTYPE} = "key" ]; then
    add_ssh_keys                         #Add Key(s) to .ssh authorized_keys file
  elif [ ${AUTHTYPE} = "passwd" ]; then
    add_passwd                         #Run passwd function
  fi
fi
if [ ${SUDO} = true ]; then            #Add sudo privs
  sudo_privs  
fi
if [ ${KERNEL} = true ]; then          #Modify Kernel Parameters
  kernel_parms
fi

exit 0
#Script ends here
