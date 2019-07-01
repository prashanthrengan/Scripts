#!/bin/bash
################################################################################
# DESCRIPTION: This script deletes the logs and temp files for each application
###############################################################################

# Set PATH
export PATH=$PATH:/usr/bin:/usr/tools/bin:/usr/lib

# Export the base name of the executing script
export SELF=`basename $0`
echo $SELF

START_TIME=$(date +"%x %r %Z")
END_TIME=$(date +"%x %r %Z")
echo " started at "$START_TIME"."

#Setting up the paths and global variables

DIRPATH=/ws/projects/global
FILEPATH=$DIRPATH/data
LOGPATH=/ws/projects/global/log
LOGFILE=$LOGPATH/clean_up_log_$(date +%Y%m%d_%H%M%S).log
FILE=$FILEPATH/clean_up_log.txt

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

############################################################################################################
#Sourcing the conf file to read the path where log files needs to be purged and check if the conf file exists
#
############################################################################################################

BeginRunning;

if [[ ! -f $FILE ]] ; then
  echo " clean_up_log.txt file not found. Exiting.."  >>$LOGFILE
  exit 1
else
  echo " clean_up_log.txt file found. Continuing .."  >>$LOGFILE
fi
source $FILEPATH/clean_up_log.txt

main()
{

#get the current directory in an array
echo "Reading the conf file and forming a temp file with the files present in the path" >>$LOGFILE
for LINE in ${DELETE_FILES[@]};
do
 cd $LINE
#capture the files present in the working directory and redirect to a temp file containing all the application paths with all file details
 find $PWD -type f>> $FILEPATH/temp_purge_path_$SELF.txt
done
       if [[ $? -ne 0 ]]
       then
         echo "***ERROR*** Issue with creating temp_purge_path file.Please investigate.Aborting the program ... !" >>$LOGFILE
       exit 1
       else
         echo "temp_purge_path files successfully created.Continuing" >>$LOGFILE
       fi
#Read the temp_purge_path details and filter the common file patterns

 /bin/cat $FILEPATH/temp_purge_path_$SELF.txt | while read TEMP_LINE
  do
     VAR=$(echo $TEMP_LINE |rev|awk -F'[._]' '{print $2$3}'| rev)
     re='^[0-9]+$'
     if  [[ "$VAR" =~ $re ]] ; then
        echo $TEMP_LINE | rev | cut -c 20- | rev | sed 's/$//g' >> $FILEPATH/temp_file_pattern_$SELF.txt
     fi
 done
          if [[ $? -ne 0 ]]
               then
               echo "***ERROR*** Issue with creating temp_file_pattern file. Please investigate.Aborting the program ... !" >>$LOGFILE
               exit 1
          else
              echo "temp_file_pattern file successfully created.Continuing" >>$LOGFILE
          fi
#Read temp_file_pattern.txt and filter out unique records

 /bin/cat $FILEPATH/temp_file_pattern_$SELF.txt | sort -u >> $FILEPATH/temp_unique_$SELF.txt
       if [[ $? -ne 0 ]]
       then
         echo "***ERROR*** Issue with creating $FILEPATH/temp_unique_$SELF.txt file. Please investigate.Aborting the program ... !" >>$LOGFILE
       exit 1
       else
         echo "temp_unique file successfully created.Continuing" >>$LOGFILE
       fi
#Read temp_unique.txt and identify the records and delete all but 10 newest files

echo "Details of the files Deleted" >>$LOGFILE

 /bin/cat $FILEPATH/temp_unique_$SELF.txt | while read TEMP_LINES
  do
   ls -1tr $TEMP_LINES[0-9]*| head -n -${FILE_RETENTION_COUNT} >> $LOGFILE
   ls -1tr $TEMP_LINES[0-9]*| head -n -${FILE_RETENTION_COUNT} | xargs -d '\n' rm -f
  done
       if [[ $? -ne 0 ]]
       then
         echo "***ERROR*** Issue with deleteing files.Please investigate.Aborting the program ... !" >>$LOGFILE
       exit 1
       else
         echo "Log files successfully deleted.Continuing" >>$LOGFILE
       fi

#Removing temp files for this iteration

  /bin/rm -f $FILEPATH/temp_purge_path_$SELF.txt $FILEPATH/temp_file_pattern_$SELF.txt $FILEPATH/temp_unique_$SELF.txt

          if [[ $? -ne 0 ]]
               then
               echo "***ERROR*** Issue with deleting the temp files. Please investigate.Aborting the program ... !" >>$LOGFILE
               exit 1
          else
               echo "Cleaning up all the temp files created during this execution. Successfull completion of the program" >>$LOGFILE

          fi

}
main
echo " Ended at "$END_TIME"."
EndRunning;
