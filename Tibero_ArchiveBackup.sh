#!/bin/sh


# !! Check !!
# Mandatory 1,2,3 must be checked by the DBA or Administrator

# Mandatory 1 : Backup shell Environment parameters
# Mandatory 2 : Datafile copy CASE
# Mandatory 3 : Archive Backup CASE

################################################################################
#                     Shell Environment
################################################################################

################################################################################
#                                                                              #
# (Mandatory 1)                                                                #
#                                                                              #
# TB_USER : Tibero user installed on OS                                        #
# TB_HOME : TB_HOME of the user with Tibero installed                          #
# ARCH_DIR : Path to the archive log                                           #
# WORK_DIR : Fullbackup path                                                   #
#                                                                              #
################################################################################

# (Mandatory 1)
TB_USER=tibero
TB_HOME=/tibero/tibero6
CONN_STRING=sys/tibero

ARCH_DIR=/tbarch01
#ARCH_DIR=/tbarch01/QSBPOLESDBS01
WORK_DIR=/tbbackup/archivebackup

# (Optional)
BACKUP_DIR=$WORK_DIR/`date +%y%m%d_%H%M`
BACKUP_CTL=$BACKUP_DIR/control.ctl.bak
LIST_DIR=$WORK_DIR/list
TMP_DIR=$WORK_DIR/tmp
LOG_DIR=$WORK_DIR/log
LOG=$LOG_DIR/`uname -n`_`date +%m%d`_archive.log
TABLESPACES=$LIST_DIR/TABLESPACES.LIST
FILE_LIST=$LIST_DIR/FILES.LIST
DB_LIST=$LIST_DIR/DB.LIST
TMP_FILE=$TMP_DIR/tmp_file.txt


su - $TB_USER -c "mkdir $BACKUP_DIR"
su - $TB_USER -c "mkdir $LIST_DIR"
su - $TB_USER -c "mkdir $TMP_DIR"
su - $TB_USER -c "mkdir $LOG_DIR"
su - $TB_USER -c "touch $LOG"

if [[ -d $BACKUP_DIR && (-w $BACKUP_DIR) ]];
then
  echo '$BACKUP_DIR' is $BACKUP_DIR setting.
else
  echo ' ERROR !! ' '$BACKUP_DIR' is $BACKUP_DIR not setting. Check is $BACKUP_DIR
  exit 1
fi

if [[ -d $LIST_DIR && (-w $LIST_DIR) ]];
then
  echo '$LIST_DIR' is $LIST_DIR setting.
else
  echo ' ERROR !! ' '$LIST_DIR' is $LIST_DIR not setting. Check is '$LIST_DIR'
  exit 1
fi

if [[ -d $TMP_DIR && (-w $TMP_DIR) ]];
then
  echo '$TMP_DIR' is $TMP_DIR setting.
else
  echo ' ERROR !! ' '$TMP_DIR' is $TMP_DIR not setting. Check is '$TMP_DIR'
  exit 1
fi

if [[ -d $LOG_DIR && (-w $LOG_DIR) ]];
then
  echo '$LOG_DIR' is $LOG_DIR setting.
else
  echo ' ERROR !! ' '$LOG_DIR' is $LOG_DIR not setting. Check is '$LOG_DIR'
  exit 1
fi

if [ -w $LOG ];
then
  echo '$LOG' is $LOG setting.
else
  echo ' ERROR !! ' '$LOG' is $LOG not setting. Check is '$LOG'
  exit 1
fi

\rm $LIST_DIR/* $TMP_DIR/*


echo "################################################################################" >> $LOG
echo "#####    ArchiveBackup Begin"                                                     >> $LOG
echo "#####    Begin Time : `date`"                                                     >> $LOG
echo "#####"                                                                            >> $LOG




BACKUP_ARCHIVE() {

################################################################################
#                 Archive and Controlfile backup
################################################################################

echo "#####        Archive and Controlfile backup Begin" >> $LOG
echo "#####"                                             >> $LOG

# Controlfile backup
# CHECK!! SQL (alter system switch logfile;) runs as many redo log groups (ex script. redo log 3 groups)

su - $TB_USER -c "tbsql $CONN_STRING<<EOF >> /dev/null
  alter system switch logfile;
  alter system switch logfile;
  alter system switch logfile;
  alter database backup controlfile to trace as '$BACKUP_DIR/control.ctl.bak' reuse noresetlogs;
 exit
EOF"


################################################################################
#                                                                              #
# (Mandatory 3)                                                                #
# Archive Backup                                                               #
#                                                                              #
# CASE 1. Using CP backup                                                 #
#                                                                              #
# CASE 2. Using Veritas NetBackup Solution backup                         #
#                                                                              #
# Select CASE. But enter # in front of other case command.                     #
#                                                                              #
################################################################################

##############################################################
# CASE 1. Using CP backup                               #
##############################################################

#cp  $ARCH_DIR/*.arc $BACKUP_DIR >>$LOG

##############################################################

##############################################################
# CASE 2.Using Veritas NetBackup Solution backup       #
##############################################################
find $ARCH_DIR/*.arc -type f > $LIST_DIR/archive.list


#ls -ld $BACKUP_CTL_NORESET | awk '{print $9}' >> $LIST_DIR/archive.list
#ls -ld $BACKUP_CTL_RESET | awk '{print $9}' >> $LIST_DIR/archive.list

echo "##### FILE LIST ##### "                                    >> $LOG
cat $LIST_DIR/archive.list >> $LOG
echo "###################### "                                    >> $LOG
#/usr/openv/netbackup/bin/bpbackup -p TIBERO_E3500-NEW -s ARCHIVE -w -f $LIST_DIR/archive.list

## Return Error Code. Confirm Backup Success.
#

if [ $? = 0 ]
then
  echo "#####  Result : Backup Success.  " >> $LOG
else
  echo "##### Error  : Backup Fail. Return Code = $?  " >> $LOG
  exit 1
fi

##############################################################

echo "#####        Archive and Controlfile backup End"                                  >> $LOG
echo "#####"                                                                            >> $LOG

}


BACKUP_ARCHIVE

echo "#####"                                                                            >> $LOG
echo "#####    ALL Backup Complete!!!!"                                                 >> $LOG
echo "#####    End Time : `date`"                                                       >> $LOG
echo "################################################################################" >> $LOG
echo " "                                                                                >> $LOG