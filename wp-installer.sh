###
#
# WordPress Bash setup script
#
# Author: Net Locomotion
# Website: https://netlocomotion.com
# Created: 2020-07-06
# Version: 1.0.0
#
###

# Load the conf file
source ./wp-installer.conf

# Set the bin paths
MYSQL=`which mysql`
TAR=`which tar`
WGET=`which wget`

# Passwordless access
if [ -z "$DBROOTPASS" ]
then
  DBROOTPASS=blank
fi

# Get the instance name
function getName {
  echo "What is the name of this instance?"
  read WPNAME
  if [ -z "$WPNAME" ]
  then
    getName
  fi
}
getName

# Should we automatically create a database?
if [ -n "$DBROOTUSER" ] && [ -n "$DBROOTPASS" ]
then
  echo -e "\nDo you want to create a new database now? [Y/n]"
  read NEWDB
  if [ "$NEWDB" == "Y" ] || [ "$NEWDB" == "y" ] || [ -z "$NEWDB" ]
  then
    # Generate a DB name
    DBNAME=`echo $WPNAME | tr -cd '[:alnum:]_'`
    DBNAME=${DBNAME:0:8}
    # Create the db
    $MYSQL -u${DBROOTUSER} -p${DBROOTPASS} -h${DBHOST} -e "CREATE DATABASE $DBNAME"

    # Generate a DB user?
    if [ -z "$DBUSER" ]
    then
      DBUSER="$DBNAME"
      DBPASS=`apg -M NSCL -m 16`
    fi

    # Prompt for the DB user
    if [ "$ALWAYSASK" == "yes" ] || [ "$ALWAYSASK" == "YES" ]
    then
      echo "Enter a database username [$DBUSER]"
      read DBUSERPROMPT
      if [ -n "$DBUSERPROMPT" ]
      then
        DBUSER="$DBUSERPROMPT"
      fi
      echo "Enter a database password [**********]"
      read DBPASSPROMPT
      if [ -n "$DBUPASSPROMPT" ]
      then
        DBPASS="$DBPASSPROMPT"
      fi
    fi

    # Add the user
    $MYSQL -u${DBROOTUSER} -p${DBROOTPASS} -h${DBHOST} -e "CREATE USER '$DBUSER'@'$WPHOST' IDENTIFIED BY '$DBPASS'"
    $MYSQL -u${DBROOTUSER} -p${DBROOTPASS} -h${DBHOST} -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER"
  fi
fi

# Where to install?
function getDir {
  echo "Where do you want to install WordPress? "
  if [ -n "BASEDIR" ]
  then
    echo -n "$BASEDIR/"
  fi
  read INSTALLDIR

  if [ -z "$INSTALLDIR" ]
  then
    getDir
  fi

  if [ -d "$BASEDIR/$INSTALLDIR" ]
  then
    echo "Directory already exists"
    getDir
  fi
}
getDir

# Download the file
echo "Downloading WordPress..."
cd /tmp
$WGET -nc --show-progress "https://wordpress.org/latest.tar.gz"
echo "Download complete"

echo "Copying to installation directory"
$TAR -zxf latest.tar.gz
mv wordpress/ "$BASEDIR/$INSTALLDIR"
cd "$BASEDIR/$INSTALLDIR"
mv wp-config-sample.php wp-config.php
sed -i "s/database_name_here/$DBNAME/" wp-config.php
sed -i "s/username_here/$DBUSER/" wp-config.php
sed -i "s/password_here/$DBPASS/" wp-config.php
sed -i "s/localhost/$DBHOST/" wp-config.php
sed -i "s/define( 'WP_DEBUG', false );/define( 'WP_DEBUG', false );\ndefine( 'FS_METHOD', 'direct' );/" wp-config.php
