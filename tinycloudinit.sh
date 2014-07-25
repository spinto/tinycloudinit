#!/bin/bash
#Tiny contextualization script, supporting a minimal set of Cloud-init syntax.
#It requires linux core utils or busybox and bash

#Retreive contextualization information
CS=/tmp/$RANDOM$RANDOM.cinit
rm -f $CS

##OpenNebula
echo -n "Trying OpenNebula datasource..."
mkdir -p $CS.rom
lsblk -niro NAME,LABEL,FSTYPE | while read name label type; do
  if [[ $label == CONTEXT || $label == CDROM ]] && [ $type == "iso9660" ]; then
    mount -o ro -t iso9660 /dev/$name $CS.rom
    if [ -f $CS.rom/context.sh ]; then
      sed -n "s|^ *USER_DATA *= *[\"']*\(.*\)[\"']$|\1|p" $CS.rom/context.sh > $CS
    fi
    umount $CS.rom
  fi
done
rmdir $CS.rom
echo "Got it!"

##OpenStack

##Amazon EC2

#If user data is not provided, nothing to be done
if [[ ! -s $CS ]]; then
  echo "Cannot find any userdata or userdata is empty. Nothing to do..."
  exit 0
fi

#Decode user data (if not already decoded)
if ! [[ "`head -c 12 $CS`" == "Content-Type" || "`head -c 1 $CS`" == "#" ]]; then
  echo "Data source seems to be encoded in base64. I will decode it."
  base64 -d $CS > $CS.new
  mv $CS.new $CS
fi

#Parse MIME encoding if present
BOUNDARY=`head -1 $CS | sed -n "s|^Content-Type: *multipart/mixed; *boundary *= *[\"']*\([^\"']*\)[\"']*$|\1|p"`
if [[ -n "$BOUNDARY" ]]; then
  echo "Data source seems to be encoded in MIME format. I will decode it."
  awk -v B="$BOUNDARY" -v F="$CS." '{if($0=="--"B"--"){exit}if($0=="--"B){k=k+1;f=F k;getline;s=1;printf "" > f};if(s==1)print $0 >> f}' $CS
  rm -f $CS
fi

#Execute contextualization commands
for f in $CS*; do

  #Skip content-type (if present)
  FIRST_LINE="`head -1 $f`"
  if [[ "$FIRST_LINE" =~ ^Content-Type: ]]; then
    awk '{if($0==""){s=1;getline;}if(s==1)print $0}' $f > $f.new
    mv $f.new $f
  fi
  
  #Skip files not containing #
  FIRST_LINE="`head -1 $f`"
  [[ "$FIRST_LINE" =~ ^# ]] || continue

  #Execute contextualization command
  if [[ "$FIRST_LINE" == "#!/bin/bash" ]]; then
    #This is a bash script, let's just execute it
    echo "Executing Bash contextualization script..."
    bash $f
  elif [[ "$FIRST_LINE" == "#!/bin/sh" ]]; then
    #This is a shell script, let's just execute it
    echo "Executing Shell contextualization script..."
    sh $f
  elif [ "$FIRST_LINE" == "#cloud-config" ]; then
    #This is a YAML Cloud config script, we need to parse it. This is only partially implemented here
    function newuser(){
      echo -n "Creating user $1..."
      un="$1"
      ud=
      i=0
      while [ $# -gt 0 ]; do
        case $1 in
          -k) uk="$uk$2\n"; shift 2;;
          -S) uS="$2"; shift 2;;
          -g) ud="$ud $1 $2"; groupadd -f $2; shift 2;;
          -G) ud="$ud $1 $2"; for g in ${2//,/ }; do groupadd -f $g; done; shift 2;;
          *) ud="$ud $1"; shift 1;;
        esac
      done
      id $un &>/dev/null
      if [ $? -eq 0 ]; then
        echo -n "already exists..."
      else
        useradd $ud
      fi
      ung="`id -g $un &>/dev/null`"
      if [ $? -ne 0 ]; then
        echo "error!"
        return
      fi
      unh=`eval echo ~${un}`
      if [[ -n "$uk" ]]; then
        mkdir -p $unh/.ssh/
        echo -e "$uk" >> $unh/.ssh/authorized_keys
        chown $un:$ung -R $unh/.ssh
        chmod og-rwx $unh/.ssh        
      fi
      if [[ -n "$uS" ]]; then
        [ "$uS" == "ALL=(ALL)NOPASSWD" ] && uS="ALL=(ALL) NOPASSWD:ALL"
        [ "$uS" == "ALL=(ALL)ALL" ] && uS="ALL=(ALL) ALL"
        grep -q -F "$un $uS" /etc/sudoers ||  echo "$un $uS" >> /etc/sudoers
      fi
      echo "ok!"
    }

    tr -d ' \t' < tmpp4 | awk 'BEGIN{FS=":|-"}{if($1=="users"){u=1}if(u==1){if(ua!=""){if($1=="gecos")ua=ua" -c \""$2"\"";if($1=="primary-group")ua=ua" -g \""$2"\"";if($1=="groups")ua=ua" -G \""$2"\"";if($1=="sudo")ua=ua" -S \""$2"\"";if($1=="passwd")ua=ua" -p \""$2"\"";if($1=="ssh"&&$2=="authorized"){while(1){getline;if($1!=""||$3!="")break;ua=ua" -k \""$2"\""}}}if($1==""&&$2=="name"){if(ua!=""){print "newuser "ua;}ua=$3;}}}END{if(ua!=""){print "newuser "ua;}}' | while read line; do
      eval $line
    done
    
  else
    #Other formats are unsupported
    echo "Ignoring script starting with `head -1 $f | head -c 100`. Not supported."
  fi

done

exit 0
