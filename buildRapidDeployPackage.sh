#!/bin/bash


if [ -z "$RAPIDDEPLOY_URL" ];
then
  echo "RapidDeploy URL is not set. Job failed";
  exit -1;
fi
if [ -z "$RAPIDDEPLOY_AUTH_TOKEN" ];
then
  echo "Authentication token not set. Job failed";
  exit -1;
fi
if [ -z "$RAPIDDEPLOY_PROJECT" ];
then
  echo "RapidDeploy project name is not set. Job failed";
  exit -1;
fi
if [ -z "$RAPIDDEPLOY_PACKAGE_NAME" ];
then
  echo "RapidDeploy package name is not set. Job failed";
  exit -1;
fi
if [ -z "$RAPIDDEPLOY_ARCHIVE_EXTENSION" ];
then
  echo "RapidDeploy archive extension is not set. Job failed";
  exit -1;
fi

curl -X PUT -i -H "Authorization: $RAPIDDEPLOY_AUTH_TOKEN" $RAPIDDEPLOY_URL/ws/deployment/$RAPIDDEPLOY_PROJECT/package/create?packageName=$RAPIDDEPLOY_PACKAGE_NAME&archiveExtension=$RAPIDDEPLOY_ARCHIVE_EXTENSION > response.out



#curl -X PUT -i -H "Authorization: $RAPIDDEPLOY_AUTH_TOKEN" $RAPIDDEPLOY_URL/ws/deployment/$RAPIDDEPLOY_PROJECT/runjob/deploy/$RAPIDDEPLOY_SERVER/$RAPIDDEPLOY_ENVIRONMENT/$RAPIDDEPLOY_APPLICATION > response.out
awk '{for (I=1;I<=NF;I++) if ($I == "Id") {print $(I+1)};}' response.out > id.out
#rm -rf response.out
id=$(cat id.out | egrep -o '[^][]+')
if [ -z "$id" ]
then
      echo "It was not possible to retrieve job id from RapidDeploy. Check if all parameters for REST call are correct"
      exit -1
fi
success=1
echo "$id"
runningJob=1
echo "$runningJob"
milisToSleep=5
while [ $runningJob -eq 1 ]
 do
   sleep $milisToSleep
   curl -X GET -i -H "Authorization: $RAPIDDEPLOY_AUTH_TOKEN" $RAPIDDEPLOY_URL/ws/deployment/display/job/$id > jobDetails.out
      jobDetailsResponseString=$(cat jobDetails.out)
      if [[ "$string" == *"$substring"* ]]; then
          echo "'$string' contains '$substring'";
      else
          echo "'$string' does not contain '$substring'";
      fi
      if [[ "$jobDetailsResponseString" == *"STARTING"* ]]; then
          echo "Job STARTING, next check in 30 seconds...";
      elif [[ "$jobDetailsResponseString" == *"DEPLOYING"* ]]; then
          echo "Job DEPLOYING, next check in 30 seconds...";
      elif [[ "$jobDetailsResponseString" == *"EXECUTING"* ]]; then
          echo "Job EXECUTING, next check in 30 seconds...";
      elif [[ "$jobDetailsResponseString" == *"QUEUED"* ]]; then
          echo "Job QUEUED, next check in 30 seconds...";
      elif [[ "$jobDetailsResponseString" == *"REQUESTED"* ]]; then
          echo "Job in a REQUESTED state. Approval may be required in RapidDeploy to continue with the execution, next check in 30 seconds...";
      elif [[ "$jobDetailsResponseString" == *"REQUESTED_SCHEDULED"* ]]; then
          echo "Job in a REQUESTED_SCHEDULED state. Approval may be required in RapidDeploy to continue with the execution, next check in 30 seconds...";
      elif [[ "$jobDetailsResponseString" == *"SCHEDULED"* ]]; then
          echo "Job in a SCHEDULED state, the execution will start in a future date, next check in 5 minutes...";
          milisToSleep=300;
      else
          runningJob=0;
          if [[ "$jobDetailsResponseString" != *"COMPLETED"* ]]; then
              success=0;
              echo "RapidDeploy job failed. Please check the output.";
          else
              echo "JOB COMPLETED succesfully";
          fi

      fi
 done

 curl -X GET -i -H "Authorization: $RAPIDDEPLOY_AUTH_TOKEN" $RAPIDDEPLOY_URL/ws/deployment/showlog/job/$id > jobLogs.out
 jobLogsResponseString=$(cat jobLogs.out)
 echo "$jobLogsResponseString"
 if [ $success -eq 0 ]; then
   exit -1;
fi
