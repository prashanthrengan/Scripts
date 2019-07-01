#!/bin/bash
################################################################################
# DESCRIPTION: This script deletes the table logs connecting to AMC tables
# Set PATH
export PATH=$PATH:/usr/bin:/usr/tools/bin:/usr/lib

# Export the base name of the executing script
export SELF=`basename $0`
echo $SELF

START_TIME=$(date +"%x %r %Z")
END_TIME=$(date +"%x %r %Z")
echo " started at "$START_TIME"."

#Setting up the paths and global variables

DIRPATH=/export/ws/projects/global
FILEPATH=$DIRPATH/data
LOGPATH=/export/ws/projects/global/log
LOGFILE=$LOGPATH/clean_up_mysql_db_history_$(date +%Y%m%d_%H%M%S).log
FILE=$FILEPATH/clean_up_mysql_db_history-config.properties

#Function to Begin Script log capturing

BeginRunning()
{
echo  " : ====== BEGIN THE PROGRAM=====  : $START_TIME" > $LOGFILE
}

#End Function

EndRunning()
{
echo  " : ====== END THE PROGRAM======  : $END_TIME" >> $LOGFILE
}

BeginRunning;

if [[ ! -f $FILE ]] ; then
  echo " clean_up_mysql_db_history-config.properties file not found. Exiting.."  >>$LOGFILE
  exit 1
else
  echo " clean_up_mysql_db_history-config.properties file found. Continuing .."  >>$LOGFILE
fi

#Parse config file to get hostname , user and password for DB connection

function getFileConfig()
{
    file_config="/export/ws/clean_up_mysql_db_history-config.properties"
    echo ${file_config}
}

function getDBHost()
{
    db_hostname="`cat $file_config | awk -F '~' '{print $1}'`"; export db_hostname
    echo ${db_hostname}
}

function getDBuser()
{
    db_user="`cat $file_config | awk -F '~' '{print $2}'`"; export db_user
    echo ${db_user}
}

function getpasswd()
{
    db_passwd="`cat $file_config | awk -F '~' '{print $3}'`"; export db_passwd
    echo ${db_passwd}
}

#Source clean_up_table.txt to table name variables

if [[ ! -f $FILEPATH/clean_up_table.txt ]] ; then
  echo " clean_up_table.txt file not found. Exiting.."  >>$LOGFILE
  exit 1
else
  echo " clean_up_table.txt file found. Continuing .."  >>$LOGFILE
fi

source $FILEPATH/clean_up_table.txt

main()
{
   getFileConfig;
   #Connect to DB and fetch database names
   showDB=$(mysql -h $(getDBHost) -u $(getDBuser) -p$(getpasswd) -e "show databases")
   echo "$showDB" | egrep -v 'Database'| grep $DATABASE > $FILEPATH/temp_show_db.txt

     if [[ $? -ne 0 ]]
        then
        echo "Connection unsuccessful .Aborting the program ... !" >>$LOGFILE
        exit 1
     else
             echo "Connection to mysql database is succes.Proceeding to next step" >>$LOGFILE
     fi

   #Read database details from temp file
   echo "Starting to read Database details from the file  " >>$LOGFILE
   echo "++++++++++++++++++++++++++++++++++++++" >>$LOGFILE
   echo "Total Databases available :" >>$LOGFILE
   cat "$FILEPATH/temp_show_db.txt" >>$LOGFILE
   echo "+++++++++++++++++++++++++++++++++++++++" >>$LOGFILE
   /bin/cat $FILEPATH/temp_show_db.txt | while read database
   do
    if [[ "$database" == "" ]]
        then
        exit
    else
   echo "Detail of the Database : $database " >>$LOGFILE
     for LINE in ${TABLE[@]};
     #echo "Detail of table : $database.$LINE" >>$LOGFILE
     do
       count=$(mysql -h $(getDBHost) -u $(getDBuser) -p$(getpasswd) $database -e "select count(*) from $LINE WHERE  moment < DATE_SUB(CURDATE(),INTERVAL $DAYS DAY)")
       Table_logs=$(mysql -h $(getDBHost) -u $(getDBuser) -p$(getpasswd) $database -e "select * from $LINE WHERE  moment < DATE_SUB(CURDATE(),INTERVAL $DAYS DAY)")
     #  mysql -h $(getDBHost) -u $(getDBuser) -p$(getpasswd) $database -e "delete from $database.$LINE WHERE  moment < DATE_SUB(CURDATE(),INTERVAL $DAYS DAY)"
      # echo "$Table_logs">>$FILEPATH/temp_results.txt
         if [[ -z "$Table_logs" ]]
            then
             echo "$database.$LINE is not present or no records are present to delete that are greater than $DAYS" >>$LOGFILE
            else
              echo "Total count of records identified for deletion in $database.$LINE: $count" >>$LOGFILE
              echo "Deletion completed on the records.Continuing.." >>$LOGFILE
         fi
     done
         echo "+++++++++++++++++++++++++++++++++++++++" >>$LOGFILE
    fi
   done
   echo "All  databases are scanned sucessfully and exiting gracefully.. !" >>$LOGFILE
}
main
rm -f $FILEPATH/temp_show_db.txt $FILEPATH/temp_results.txt
EndRunning;
