#!/bin/bash
#################################################################################################
#Purpose:Script to run the talend job script and captute the talend log in a log file
#################################################################################################

#Parameter Initialization
JOB=${0##*/}
export JOB
START_TIME=$(date +"%x %r %Z")
echo " started at "$START_TIME"."
today=`date +%Y-%m-%d.%H:%M:%S`
DIRPATH=/exp/proj/$2/data
LOGPATH=/exp/proj/$2/log
FILE=$DIRPATH/$1_run.txt

# Check if the text file exists in the path

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

# Check if the text file exists in the path

if [ "$#" -ne 2 ]; then
echo "Please pass two input arguments to run the script"
echo "Exitting the script"
exit 1
fi



if [ -f "$FILE" ]
then
        echo "$FILE found is available in the path"
else
        echo "$FILE not found."

echo "Exitting the script..."
exit 1
fi

#Inside the data folder of the application the text file is spotted using find command using its name

cd $DIRPATH | /bin/find . -name $1_run.txt


#The lines of the text file are read and stored in the variable SCRIPT_PATH


/bin/cat $FILE | while read LINE
do
SCRIPT_PATH=$(echo $LINE)
echo $LINE

#Function to check if text file is empty

doesFileExist()
{

     if [ -z "$SCRIPT_PATH" ] ; then

            echo "Input file is empty in the path  .Please check ..aborting."
            echo "Input file is empty in the path  .Please check ..aborting." >> $LOGFILE
    exit 1

    else

             echo "The input text file exists in the path"
             echo "The input text file exists in the path" >> $LOGFILE

    fi
}



#The name of the log file is extracted from the SCRIPT_PATH by taking the last 70 characters from the text file.
#The awk command is used to cut the text between "." and ".sh" and the result is sored in the variable log

log=$(echo $SCRIPT_PATH  | tail -1 | rev | cut -c1-70 | rev |awk -F "/" '{print $2}' | awk -F ".sh" '{print $1}' )

#The log file name containd the log variable name followed by the date and time

LOGFILE=$LOGPATH/$log.log_$today
echo $LOGFILE

#The start time is captured into the log file

BeginRunning;

doesFileExist;
echo "The script path is $SCRIPT_PATH" >> $LOGFILE
echo "The script path is $SCRIPT_PATH"
#The talend job script is ran and the log is captured in the same log file
echo "The script starts executing ...." >> $LOGFILE
echo "The script starts executing ...."
/$SCRIPT_PATH >>  $LOGFILE

exit_code=$?

if [ $exit_code -eq 0 ]; then
 echo "The talend job script ran successfully" >> $LOGFILE
 echo "The talend job script ran successfully"
else
 echo "The talend job script running failed" >> $LOGFILE
 echo "The talend job script running failed"
exit 1
fi
#The end time is captured into the log file

END_TIME=$(date +"%x %r %Z")

EndRunning;

echo " ended at "$END_TIME"."
done
