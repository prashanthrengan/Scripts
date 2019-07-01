#!/bin/bash

##################################################################################################################################################
#Purpose : Script to determine the current table name and its corresponding HDFS location for the given table view.
#          The output of the script will be consumed by the talend jobs to extract the necessary context variable.
#
#Parameter Initialization

START_TIME=$(date +"%x %r %Z")
processDate=$(date +%Y-%m-%d)
DIRPATH=/export/projects/$2/data
STDERR=/export/projects/$2/log/project_stats.err_`date +%Y_%m_%d_%H%M%S`

# Check if the cfg files exists in the path

if [[  "$1" ]]; then

        source $DIRPATH/$1.cfg

                if [[ $? -eq 0 ]]; then

                        FILE=$DIRPATH/$1_input.cfg

                        CONF_FILE=$DIRPATH/$1.cfg
                else
                        echo "Either Input parameter is incorrect or file $1.cfg file is not present in $DIRPATH.Please Check and rerun..aborting.">${STDERR}
                        exit 1
                fi
fi
#Function to Begin Script log capturing

BeginRunning()
{
    echo  "$START_TIME : ====== BEGIN THE PROGRAM : project_stats.sh ========="> ${LOG}
}

#End Function

#Function to check if conf file is empty

doesFileExist()
{
    echo "Entering doesFileExist Function" >>${LOG}

     if [[ ! -s $FILE ]] ; then

            echo "Input file is empty in the path : /export/projects/$2/data/ .Please check ..aborting." >>${LOG}

    exit 1

    else

             echo "$FILE exist" >>${LOG}
    fi
}

#End Function

#Function to capture the end logs

EndRunning()
{
    echo "$END_TIME : ========= END OF THE PROGRAM : project_stats.sh ===========" >> ${LOG}

}

#End Function

BeginRunning;

doesFileExist;

#Remove the previous output file in the dir path
/bin/rm -f $OUTPUT

#Create OUTPUT FILE in dir path

echo "=========OUTPUT FILE=============" >>${LOG}
                echo " Output File written to the path: $OUTPUT"
                

#Read info File
echo $FILE

/bin/cat $FILE | while read LINE

do
        DB_NAME=$(echo $LINE | /bin/cut -d '.' -f1)

        TAB_NAME=$(echo $LINE | /bin/cut -d '.' -f2)

#Condition to check if the input is table view

        if [[ $TAB_NAME == *tv ]] ; then

                TABLE_TV=$(echo $LINE | /bin/cut -d '.' -f2)

                /usr/bin/hive -S -e "describe extended $DB_NAME.$TABLE_TV" > $DIRPATH/temp_$1.txt

echo  $DB_NAME $TABLE_TV

#Check if the hive connectivity and table view exists

                        if [[ ! -s $DIRPATH/temp_$1.txt ]] ; then

                                echo " temp File is not created , check the hive connectivity and table View name $TABLE_TV"  >>${LOG}

                                exit 1
                        else
                                echo " Hive connectivity successfully and Table View for $TABLE_TV information found" >>${LOG}
                        fi

                echo "===========Description of Table View $TABLE_TV===========" >>${LOG}

                                /bin/cat $DIRPATH/temp_$1.txt >> ${LOG}

#Get DB and Table name from the temp file

                DB=$(/bin/cat $DIRPATH/temp_$1.txt  | tail -1 | rev | cut -c1-100 | rev | sed 's/[#\$%^&*()`,]//g' | tr '[A-Z]' '[a-z]' | awk -F "from" '{print $2}' | awk -F "." '{print $1}')

                table=$(/bin/cat $DIRPATH/temp_$1.txt | tail -1 | rev | cut -c1-100 | rev | sed 's/[#\$%^&*()`,]//g' | tr '[A-Z]' '[a-z]'| awk -F "from" '{print $2}' | awk -F "." '{print $2}' | awk -F " " '{print $1}')

echo $DB $table
               /usr/bin/hive -S -e "describe formatted $DB.$table" > $DIRPATH/temp1_$1.txt

#Check if table exists
                         if [[ ! -s $DIRPATH/temp1_$1.txt ]] ; then

                                echo " temp File is not created for table name $table"  >>${LOG}

                                exit 1
                        else
                                echo " $table Table information found" >>${LOG}
                        fi

                echo "===========Description of Table $table===========" >>${LOG}

                                /bin/cat $DIRPATH/temp1_$1.txt >> ${LOG}

#Extracting HDFS Location from the file

                                location=$(/bin/cat $DIRPATH/temp1_$1.txt | /bin/egrep -o 'hdfs://[^,]+')

                echo "=================================" >>${LOG}
                echo "=========OUTPUT FILE=============" >>${LOG}

                echo " Output File wriiten to the path: $OUTPUT"

#Check if the values are populated

                                echo "$TABLE_TV"_table=$table >>${OUTPUT}

                                echo "$TABLE_TV"_file_loc=$location >>${OUTPUT}

                                        if [[ -z $table || -z $location ]]; then

                                                echo Table view or HDFS file_loc is incorrect or empty .. Please check .. Terminating >> ${LOG}

                                                exit 1
                                        else

                                                echo "$TABLE_TV"_table=$table >>${LOG}

                                                 echo "$TABLE_TV"_file_loc=$location >>${LOG}
                                        fi

#Removing temp files for this iteration

                /bin/rm -f $DIRPATH/temp_$1.txt $DIRPATH/temp1_$1.txt

        else

#Else condition if the input is table

                 TABLE1=$(echo $LINE | /bin/cut -d '.' -f2)

echo $DB_NAME $TABLE1

#Check if the table exists

                 /usr/bin/hive -S -e "describe formatted $DB_NAME.$TABLE1" > $DIRPATH/temp2_$1.txt

                         if [[ ! -s $DIRPATH/temp2_$1.txt ]] ; then

                                echo " temp File is not created , check the hive connectivity and table name $TABLE1"  >>${LOG}

                                exit 1
                        else
                                echo " Hive connectivity successfully and Table for $TABLE1 information found" >>${LOG}
                        fi

#Extract HDFS Location from the table

                echo "===========Description of Table $TABLE1===========" >>${LOG}

                                /bin/cat $DIRPATH/temp2_$1.txt >> ${LOG}

                                LOCATION=$(/bin/cat $DIRPATH/temp2_$1.txt | /bin/egrep -o 'hdfs://[^,]+')

                echo "=================================" >>${LOG}

                echo "=========OUTPUT FILE=============" >>${LOG}

                echo " Output File wriiten to the path: $OUTPUT"


#Check if the values are populated

                                echo "$TABLE1"_table=$TABLE1 >>${OUTPUT}

                                echo "$TABLE1"_file_loc=$LOCATION >>${OUTPUT}

                                        if [[ -z $TABLE1 || -z $LOCATION ]]; then

                                                  echo 'Table Name or HDFS file_loc is incorrect or empty .. Please check .. Terminating' >>${LOG}

                                                  exit 1
                                        else
                                                echo  "$TABLE1"_table=$TABLE1 >>${LOG}

                                                echo "$TABLE1"_file_loc=$LOCATION >>${LOG}

                                        fi

#Remove temp files for this iteration

                /bin/rm -f  $DIRPATH/temp2_$1.txt

        fi

done

if [ $? != 0 ]

then

  echo "***ERROR*** Aborting the program ... !" >>${LOG}

  exit 1

else

END_TIME=$(date +"%x %r %Z")

EndRunning;

fi
