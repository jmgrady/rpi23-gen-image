logger -t "rc.firstboot" "Adding user to 'sudo' group"

# Check if sudo is installed
dpkg -l sudo 2>&1 >/dev/null
if [ $? -eq 0 ] ; then
  usermod -aG sudo %SUDOUSER%
fi
