#!/bin/bash

#This is a script to grab job names from a text file based on Autosys server and job parameters. The main function is placing jobs on hold. 


#Source the profile...
  . opt/CA/WorkloadAutomationAE/autouser



# Step through the jobs in joblist.txt
for job in $(<joblist.txt)

do
	
	echo "Processing job ${job}..."
	
	releaseTheJob="true"

# Get array of conditional jobs
	
	conditionalJobs=( $(jr ${job} -q | awk -F: '/^condition:/ {print $2}' | sed 's/&/\n/g' | sed 's/ //g') ) 

	

# Step through conditional jobs to check that they have achieved the required status
	
	for conditionalJob in ${conditionalJobs[@]}
	
	do
		
		conditionalJobStatus="$(echo ${conditionalJob} | awk -F\( '{print $1}')"
		
		conditionalJobName="$(echo ${conditionalJob} | awk -F\( '{print $2}' | sed 's/)//g')"
		
		conditionalJobState="$(jr ${conditionalJobName} | grep "^${conditionalJobName}" | awk '{ if (NF==8) {print $6} else if (NF==6) {print $5} }')"
		

		if [[ ("${conditionalJobStatus}" == "s"  &&  "${conditionalJobState}" = "SU" )]] || [[( "${conditionalJobStatus}" == "n"  &&  "${conditionalJobState}" != "RU") ]]
		
		then
			
			echo "  Conditional job ${conditionalJobName} is reflecting required status"
		
		else
			
			echo "  Conditional job ${conditionalJobName} does not reflect required status!!!"

			
			
# Offset these by two spaces so the output looks cleaner... 
	
			(
			
			printf "\n===== Failing outputs for ${job}/${conditionalJobName} =====\n"
			
			#jr ${job} -q
			
			jr ${conditionalJobName}
			
			printf "===============================================================\n\n"
			
			) | sed 's/^/  /'
	
		
			
			#echo "Do you wish to release anyway?"

			
# Allow user to choose to release or not - commented out for ~automated version~

			#select yesOrNo in "Yes, release the job" "No, don't release the job"
			
			#do
				
			  #	case ${yesOrNo} in 
				
			    #	"Yes, release the job") releaseTheJob="true"; break;; 
				
			    #	"No, don't release the job") releaseTheJob="false"; break;; 
				
			  #	esac
			
			#done
			
			#echo
		
		fi
	
	  done

	

# If we got past all the conditional jobs being successful, release the main job
	
	if [[ "${releaseTheJob}" == "true" ]]
	
	then
		
		echo "  ** Releasing job ${job} **"
		
		sendevent -E JOB_OFF_HOLD -J ${job}
	
	else
		
		echo "  !! Not releasing the job ${job} !!"
	
	fi

done
  
