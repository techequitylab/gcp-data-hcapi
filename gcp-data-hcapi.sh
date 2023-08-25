#!/bin/bash
# 
# Copyright 2019 Shiyghan Navti. Email shiyghan@gmail.com
#
#################################################################################
###         Explore Streaming HL7 to FHIR Data with Healthcare API           ####
#################################################################################

# User prompt function
function ask_yes_or_no() {
    read -p "$1 ([y]yes to preview, [n]o to create, [d]del to delete): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        n|no)  echo "no" ;;
        d|del) echo "del" ;;
        *)     echo "yes" ;;
    esac
}

function ask_yes_or_no_proj() {
    read -p "$1 ([y]es to change, or any key to skip): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

clear
MODE=1
export TRAINING_ORG_ID=$(gcloud organizations list --format 'value(ID)' --filter="displayName:techequity.training" 2>/dev/null)
export ORG_ID=$(gcloud projects get-ancestors $GCP_PROJECT --format 'value(ID)' 2>/dev/null | tail -1 )
export GCP_PROJECT=$(gcloud config list --format 'value(core.project)' 2>/dev/null)  

echo
echo
echo -e "                        👋  Welcome to Cloud Sandbox! 💻"
echo 
echo -e "              *** PLEASE WAIT WHILE LAB UTILITIES ARE INSTALLED ***"
sudo apt-get -qq install pv > /dev/null 2>&1
echo 
export SCRIPTPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

function join_by { local IFS="$1"; shift; echo "$*"; }

mkdir -p `pwd`/gcp-data-hcapi > /dev/null 2>&1
export SCRIPTNAME=gcp-data-hcapi.sh
export PROJDIR=`pwd`/gcp-data-hcapi

if [ -f "$PROJDIR/.env" ]; then
    source $PROJDIR/.env
else
cat <<EOF > $PROJDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=us-central1
export GCP_ZONE=us-central1-b
EOF
source $PROJDIR/.env
fi

export GCP_CLUSTER=gcp-data-hcapi

# Display menu options
while :
do
clear
cat<<EOF
====================================================================
Menu for Exploring Streaming HL7 to FHIR Data with Healthcare API
--------------------------------------------------------------------
Please enter number to select your choice:
 (1) Enable APIs
 (2) Create PubSub topics and subscriptions
 (3) Create BigQuery dataset for FHIR data
 (4) Create Healthcare API dataset and datastores
 (5) Create GCS buckets for mapping configs
 (6) Create service account and add IAM binding
 (7) Update configurations HC API datastores
 (8) Create GKE Cluster
 (9) Create deployment and service for MLLP adapter and SimHospital 
(10) Validate HL7 Data Creation
 (G) Launch user guide
 (Q) Quit
--------------------------------------------------------------------
EOF
echo "Steps performed${STEP}"
echo
echo "What additional step do you want to perform, e.g. enter 0 to select the execution mode?"
read
clear
case "${REPLY^^}" in

"0")
start=`date +%s`
source $PROJDIR/.env
echo
echo "Do you want to run script in preview mode?"
export ANSWER=$(ask_yes_or_no "Are you sure?")
cd $HOME
if [[ ! -z "$TRAINING_ORG_ID" ]]  &&  [[ $ORG_ID == "$TRAINING_ORG_ID" ]]; then
    export STEP="${STEP},0"
    MODE=1
    if [[ "yes" == $ANSWER ]]; then
        export STEP="${STEP},0i"
        MODE=1
        echo
        echo "*** Command preview mode is active ***" | pv -qL 100
    else 
        if [[ -f $PROJDIR/.${GCP_PROJECT}.json ]]; then
            echo 
            echo "*** Authenticating using service account key $PROJDIR/.${GCP_PROJECT}.json ***" | pv -qL 100
            echo "*** To use a different GCP project, delete the service account key ***" | pv -qL 100
        else
            while [[ -z "$PROJECT_ID" ]] || [[ "$GCP_PROJECT" != "$PROJECT_ID" ]]; do
                echo 
                echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
                gcloud auth login  --brief --quiet
                export ACCOUNT=$(gcloud config list account --format "value(core.account)")
                if [[ $ACCOUNT != "" ]]; then
                    echo
                    echo "Copy and paste a valid Google Cloud project ID below to confirm your choice:" | pv -qL 100
                    read GCP_PROJECT
                    gcloud config set project $GCP_PROJECT --quiet 2>/dev/null
                    sleep 3
                    export PROJECT_ID=$(gcloud projects list --filter $GCP_PROJECT --format 'value(PROJECT_ID)' 2>/dev/null)
                fi
            done
            gcloud iam service-accounts delete ${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com --quiet 2>/dev/null
            sleep 2
            gcloud --project $GCP_PROJECT iam service-accounts create $GCP_PROJECT 2>/dev/null
            gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$GCP_PROJECT@$GCP_PROJECT.iam.gserviceaccount.com --role=roles/owner > /dev/null 2>&1
            gcloud --project $GCP_PROJECT iam service-accounts keys create $PROJDIR/.${GCP_PROJECT}.json --iam-account=${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com 2>/dev/null
            gcloud --project $GCP_PROJECT storage buckets create gs://$GCP_PROJECT > /dev/null 2>&1
        fi
        export GOOGLE_APPLICATION_CREDENTIALS=$PROJDIR/.${GCP_PROJECT}.json
        export PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT --format="value(projectNumber)" 2>/dev/null) 
        export COMPUTE_SA=${PROJECT_NUMBER}-compute # to set default compute service account
        export LOCATION=$GCP_REGION
        export DEFAULT_ZONE=$GCP_ZONE
        export ERROR_BUCKET=${GCP_PROJECT}-df-pipeline/error/
        export MAPPING_BUCKET=${GCP_PROJECT}-df-pipeline/mapping
        export GCP_CLUSTER=gcp-gke-hcapi
        export DATASET_ID=datastore # to set dataset ID
        export FHIR_STORE_ID=fhirstore
        export FHIR_TOPIC=fhirtopic
        export HL7_TOPIC=hl7topic
        export HL7_SUB=hl7subscription
        export HL7_STORE_ID=hl7v2store
        export BQ_FHIR=fhirdata
        export PSSAN=pubsub-svc
        export FILENAME=svca-key
        cat <<EOF > $PROJDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=$GCP_REGION
export GCP_ZONE=$GCP_ZONE
EOF
        gsutil cp $PROJDIR/.env gs://${GCP_PROJECT}/${SCRIPTNAME}.env > /dev/null 2>&1
        echo
        echo "*** Google Cloud project is $GCP_PROJECT ***" | pv -qL 100
        echo "*** Google Cloud region is $GCP_REGION ***" | pv -qL 100
        echo "*** Google Cloud zone is $GCP_ZONE ***" | pv -qL 100
        echo
        echo "*** Update environment variables by modifying values in the file: ***" | pv -qL 100
        echo "*** $PROJDIR/.env ***" | pv -qL 100
        if [[ "no" == $ANSWER ]]; then
            MODE=2
            echo
            echo "*** Create mode is active ***" | pv -qL 100
        elif [[ "del" == $ANSWER ]]; then
            export STEP="${STEP},0"
            MODE=3
            echo
            echo "*** Resource delete mode is active ***" | pv -qL 100
        fi
    fi
else 
    if [[ "no" == $ANSWER ]] || [[ "del" == $ANSWER ]] ; then
        export STEP="${STEP},0"
        if [[ -f $SCRIPTPATH/.${SCRIPTNAME}.secret ]]; then
            echo
            unset password
            unset pass_var
            echo -n "Enter access code: " | pv -qL 100
            while IFS= read -p "$pass_var" -r -s -n 1 letter
            do
                if [[ $letter == $'\0' ]]
                then
                    break
                fi
                password=$password"$letter"
                pass_var="*"
            done
            while [[ -z "${password// }" ]]; do
                unset password
                unset pass_var
                echo
                echo -n "You must enter an access code to proceed: " | pv -qL 100
                while IFS= read -p "$pass_var" -r -s -n 1 letter
                do
                    if [[ $letter == $'\0' ]]
                    then
                        break
                    fi
                    password=$password"$letter"
                    pass_var="*"
                done
            done
            export PASSCODE=$(cat $SCRIPTPATH/.${SCRIPTNAME}.secret | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:$password 2> /dev/null)
            if [[ $PASSCODE == 'AccessVerified' ]]; then
                MODE=2
                echo && echo
                echo "*** Access code is valid ***" | pv -qL 100
                if [[ -f $PROJDIR/.${GCP_PROJECT}.json ]]; then
                    echo 
                    echo "*** Authenticating using service account key $PROJDIR/.${GCP_PROJECT}.json ***" | pv -qL 100
                    echo "*** To use a different GCP project, delete the service account key ***" | pv -qL 100
                else
                    while [[ -z "$PROJECT_ID" ]] || [[ "$GCP_PROJECT" != "$PROJECT_ID" ]]; do
                        echo 
                        echo "$ gcloud auth login --brief --quiet # to authenticate as project owner or editor" | pv -qL 100
                        gcloud auth login  --brief --quiet
                        export ACCOUNT=$(gcloud config list account --format "value(core.account)")
                        if [[ $ACCOUNT != "" ]]; then
                            echo
                            echo "Copy and paste a valid Google Cloud project ID below to confirm your choice:" | pv -qL 100
                            read GCP_PROJECT
                            gcloud config set project $GCP_PROJECT --quiet 2>/dev/null
                            sleep 3
                            export PROJECT_ID=$(gcloud projects list --filter $GCP_PROJECT --format 'value(PROJECT_ID)' 2>/dev/null)
                        fi
                    done
                    gcloud iam service-accounts delete ${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com --quiet 2>/dev/null
                    sleep 2
                    gcloud --project $GCP_PROJECT iam service-accounts create $GCP_PROJECT 2>/dev/null
                    gcloud projects add-iam-policy-binding $GCP_PROJECT --member serviceAccount:$GCP_PROJECT@$GCP_PROJECT.iam.gserviceaccount.com --role=roles/owner > /dev/null 2>&1
                    gcloud --project $GCP_PROJECT iam service-accounts keys create $PROJDIR/.${GCP_PROJECT}.json --iam-account=${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com 2>/dev/null
                    gcloud --project $GCP_PROJECT storage buckets create gs://$GCP_PROJECT > /dev/null 2>&1
                fi
                export GOOGLE_APPLICATION_CREDENTIALS=$PROJDIR/.${GCP_PROJECT}.json
                export PROJECT_NUMBER=$(gcloud projects describe $GCP_PROJECT --format="value(projectNumber)") > /dev/null 2>&1
                export COMPUTE_SA=${PROJECT_NUMBER}-compute # to set default compute service account
                export LOCATION=$GCP_REGION
                export DEFAULT_ZONE=$GCP_ZONE
                export ERROR_BUCKET=${GCP_PROJECT}-df-pipeline/error/
                export MAPPING_BUCKET=${GCP_PROJECT}-df-pipeline/mapping
                export GCP_CLUSTER=gcp-gke-hcapi
                export DATASET_ID=datastore # to set dataset ID
                export FHIR_STORE_ID=fhirstore
                export FHIR_TOPIC=fhirtopic
                export HL7_TOPIC=hl7topic
                export HL7_SUB=hl7subscription
                export HL7_STORE_ID=hl7v2store
                export BQ_FHIR=fhirdata
                export PSSAN=pubsub-svc
                export FILENAME=svca-key
                gcloud --project $GCP_PROJECT iam service-accounts create $GCP_PROJECT 2>/dev/null
                gcloud --project $GCP_PROJECT iam service-accounts keys create $PROJDIR/.${GCP_PROJECT}.json --iam-account=${GCP_PROJECT}@${GCP_PROJECT}.iam.gserviceaccount.com 2>/dev/null
                export GOOGLE_APPLICATION_CREDENTIALS=$PROJDIR/.${GCP_PROJECT}.json
                cat <<EOF > $PROJDIR/.env
export GCP_PROJECT=$GCP_PROJECT
export GCP_REGION=$GCP_REGION
export GCP_ZONE=$GCP_ZONE
EOF
                gsutil cp $PROJDIR/.env gs://${GCP_PROJECT}/${SCRIPTNAME}.env > /dev/null 2>&1
                echo
                echo "*** Google Cloud project is $GCP_PROJECT ***" | pv -qL 100
                echo "*** Google Cloud region is $GCP_REGION ***" | pv -qL 100
                echo "*** Google Cloud zone is $GCP_ZONE ***" | pv -qL 100
                echo
                echo "*** Update environment variables by modifying values in the file: ***" | pv -qL 100
                echo "*** $PROJDIR/.env ***" | pv -qL 100
                if [[ "no" == $ANSWER ]]; then
                    MODE=2
                    echo
                    echo "*** Create mode is active ***" | pv -qL 100
                elif [[ "del" == $ANSWER ]]; then
                    export STEP="${STEP},0"
                    MODE=3
                    echo
                    echo "*** Resource delete mode is active ***" | pv -qL 100
                fi
            else
                echo && echo
                echo "*** Access code is invalid ***" | pv -qL 100
                echo "*** You can use this script in our Google Cloud Sandbox without an access code ***" | pv -qL 100
                echo "*** Contact support@techequity.cloud for assistance ***" | pv -qL 100
                echo
                echo "*** Command preview mode is active ***" | pv -qL 100
            fi
        else
            echo
            echo "*** You can use this script in our Google Cloud Sandbox without an access code ***" | pv -qL 100
            echo "*** Contact support@techequity.cloud for assistance ***" | pv -qL 100
            echo
            echo "*** Command preview mode is active ***" | pv -qL 100
        fi
    else
        export STEP="${STEP},0i"
        MODE=1
        echo
        echo "*** Command preview mode is active ***" | pv -qL 100
    fi
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"1")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},1i"
    echo
    echo "$ gcloud services enable --project=\$GCP_PROJECT compute.googleapis.com container.googleapis.com dataflow.googleapis.com datapipelines.googleapis.com datastore.googleapis.com bigquery.googleapis.com pubsub.googleapis.com healthcare.googleapis.com # to enable APIs" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},1"
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1 
    echo
    echo "$ gcloud services enable --project=$GCP_PROJECT compute.googleapis.com container.googleapis.com dataflow.googleapis.com datapipelines.googleapis.com datastore.googleapis.com bigquery.googleapis.com pubsub.googleapis.com healthcare.googleapis.com # to enable APIs" | pv -qL 100
    gcloud services enable --project=$GCP_PROJECT compute.googleapis.com container.googleapis.com dataflow.googleapis.com datapipelines.googleapis.com datastore.googleapis.com bigquery.googleapis.com pubsub.googleapis.com healthcare.googleapis.com
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},1x"
    echo
    echo "*** Nothing to delete ***" | pv -qL 100
else
    export STEP="${STEP},1i"
    echo
    echo "1. Enable APIs" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"2")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},2i"   
    echo
    echo "$ gcloud pubsub topics create \$HL7_TOPIC # to create topic" | pv -qL 100
    echo
    echo "$ gcloud pubsub subscriptions create \$HL7_SUB --topic=\$HL7_TOPIC # to create subscription" | pv -qL 100
    echo
    echo "$ gcloud pubsub topics create \$FHIR_TOPIC # to create topic" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},2"   
    echo
    echo "$ gcloud pubsub topics create $HL7_TOPIC # to create topic" | pv -qL 100
    gcloud pubsub topics create $HL7_TOPIC
    echo
    echo "$ gcloud pubsub subscriptions create $HL7_SUB --topic=$HL7_TOPIC # to create subscription" | pv -qL 100
    gcloud pubsub subscriptions create $HL7_SUB --topic=$HL7_TOPIC
    echo
    echo "$ gcloud pubsub topics create $FHIR_TOPIC # to create topic" | pv -qL 100
    gcloud pubsub topics create $FHIR_TOPIC
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},2x"   
    echo
    echo "$ gcloud pubsub topics delete $FHIR_TOPIC # to delete topic" | pv -qL 100
    gcloud pubsub topics delete $FHIR_TOPIC
    echo
    echo "$ gcloud pubsub subscriptions delete $HL7_SUB # to delete subscription" | pv -qL 100
    gcloud pubsub subscriptions delete $HL7_SUB
    echo
    echo "$ gcloud pubsub topics delete $HL7_TOPIC # to delete topic" | pv -qL 100
    gcloud pubsub topics delete $HL7_TOPIC
else
    export STEP="${STEP},2i"
    echo
    echo "1. Create topics and subscriptions" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"3")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},3i"
    echo
    echo "$ bq mk --dataset --location=\$LOCATION --project_id=\$GCP_PROJECT --description HCAPI-FHIR-dataset \$GCP_PROJECT:\$BQ_FHIR # to create dataset" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},3"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ bq mk --dataset --location=$LOCATION --project_id=$GCP_PROJECT --description HCAPI-FHIR-dataset $GCP_PROJECT:$BQ_FHIR # to create dataset" | pv -qL 100
    bq mk --dataset --location=$LOCATION --project_id=$GCP_PROJECT --description HCAPI-FHIR-dataset $GCP_PROJECT:$BQ_FHIR
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},3x"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ bq rm -r -f -d $GCP_PROJECT:$BQ_FHIR # to delete dataset" | pv -qL 100
    bq rm -r -f -d $GCP_PROJECT:$BQ_FHIR
else
    export STEP="${STEP},3i"   
    echo
    echo "1. Create BigQuery dataset" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"4")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},4i"
    echo
    echo "$ gcloud healthcare datasets create \$DATASET_ID --location=\$LOCATION # to create dataset" | pv -qL 100
    echo
    echo "$ gcloud beta healthcare hl7v2-stores create \$HL7_STORE_ID --dataset=\$DATASET_ID --location=\$LOCATION --pubsub-topic=projects/\$GCP_PROJECT/topics/\$HL7_TOPIC # to create datastore" | pv -qL 100
    echo
    echo "$ gcloud healthcare fhir-stores create \$FHIR_STORE_ID --dataset=\$DATASET_ID --location=\$LOCATION --version=R4 --pubsub-topic=projects/\$GCP_PROJECT/topics/\$FHIR_TOPIC --disable-referential-integrity --enable-update-create # to create datastore" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},4"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gcloud healthcare datasets create $DATASET_ID --location=$LOCATION # to create dataset" | pv -qL 100
    gcloud healthcare datasets create $DATASET_ID --location=$LOCATION
    echo
    echo "$ gcloud beta healthcare hl7v2-stores create $HL7_STORE_ID --dataset=$DATASET_ID --location=$LOCATION --pubsub-topic=projects/$GCP_PROJECT/topics/$HL7_TOPIC # to create datastore" | pv -qL 100
    gcloud beta healthcare hl7v2-stores create $HL7_STORE_ID --dataset=$DATASET_ID --location=$LOCATION --pubsub-topic=projects/$GCP_PROJECT/topics/$HL7_TOPIC
    echo
    echo "$ gcloud healthcare fhir-stores create $FHIR_STORE_ID --dataset=$DATASET_ID --location=$LOCATION --version=R4 --pubsub-topic=projects/$GCP_PROJECT/topics/$FHIR_TOPIC --disable-referential-integrity --enable-update-create # to create datastore" | pv -qL 100
    gcloud healthcare fhir-stores create $FHIR_STORE_ID --dataset=$DATASET_ID --location=$LOCATION --version=R4 --pubsub-topic=projects/$GCP_PROJECT/topics/$FHIR_TOPIC --disable-referential-integrity --enable-update-create
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},4x"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gcloud healthcare fhir-stores delete $FHIR_STORE_ID --dataset=$DATASET_ID --location=$LOCATION # to delete datastore" | pv -qL 100
    gcloud healthcare fhir-stores delete $FHIR_STORE_ID --dataset=$DATASET_ID --location=$LOCATION
    echo
    echo "$ gcloud beta healthcare hl7v2-stores delete $HL7_STORE_ID --dataset=$DATASET_ID --location=$LOCATION # to delete datastore" | pv -qL 100
    gcloud beta healthcare hl7v2-stores delete $HL7_STORE_ID --dataset=$DATASET_ID --location=$LOCATION
    echo
    echo "$ gcloud healthcare datasets delete $DATASET_ID --location=$LOCATION # to delete dataset" | pv -qL 100
    gcloud healthcare datasets delete $DATASET_ID --location=$LOCATION
else
    export STEP="${STEP},4i"   
    echo
    echo "1. Create Healthcare API dataset and datastores" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"5")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},5i"
    echo
    echo "$ gcloud iam service-accounts create \$PSSAN # to create Healthcare API service account" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\${PSSAN}@\${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/pubsub.subscriber # to enable pubsub access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\${PSSAN}@\${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/healthcare.hl7V2Ingest # to enable HC API Datastore access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\${PSSAN}@\${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/monitoring.metricWriter # to enable cloud monitoring access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:service-\${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.dataEditor # to enable BigQuery access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:service-\${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.jobUser # to enable BigQuery access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:service-\${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/storage.objectAdmin # to enable Cloud Storage access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:service-\${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.datasetAdmin # to enable BigQuery access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:service-\${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.dicomStoreAdmin # to enable Healthcare API access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/pubsub.subscriber # to enable PubSub access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.hl7V2Consumer # to enable Healthcare API access" | pv -qL 100
    echo
    echo "$ gcloud projects add-iam-policy-binding \$GCP_PROJECT --member=serviceAccount:\${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.fhirResourceEditor # to enable Healthcare API access" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},5"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gcloud iam service-accounts create $PSSAN # to create Healthcare API service account" | pv -qL 100
    gcloud iam service-accounts create $PSSAN
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/pubsub.subscriber # to enable pubsub access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/pubsub.subscriber
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/healthcare.hl7V2Ingest # to enable HC API Datastore access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/healthcare.hl7V2Ingest
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/monitoring.metricWriter # to enable cloud monitoring access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/monitoring.metricWriter
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.dataEditor # to enable BigQuery access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.dataEditor
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.jobUser # to enable BigQuery access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.jobUser
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/storage.objectAdmin # to enable Cloud Storage access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/storage.objectAdmin
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.datasetAdmin # to enable BigQuery access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.datasetAdmin
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.dicomStoreAdmin # to enable Healthcare API access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.dicomStoreAdmin
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/pubsub.subscriber # to enable PubSub access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/pubsub.subscriber
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.hl7V2Consumer # to enable Healthcare API access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.hl7V2Consumer
    echo
    echo "$ gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.fhirResourceEditor # to enable Healthcare API access" | pv -qL 100
    gcloud projects add-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.fhirResourceEditor 
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},5x"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/pubsub.subscriber # to revoke pubsub access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/pubsub.subscriber
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/healthcare.hl7V2Ingest # to revoke HC API Datastore access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/healthcare.hl7V2Ingest
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/monitoring.metricWriter # to revoke cloud monitoring access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com --role=roles/monitoring.metricWriter
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.dataEditor # to revoke BigQuery access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.dataEditor
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.jobUser # to revoke BigQuery access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/bigquery.jobUser
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/storage.objectAdmin # to revoke Cloud Storage access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/storage.objectAdmin
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.datasetAdmin # to revoke BigQuery access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.datasetAdmin
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.dicomStoreAdmin # to revoke Healthcare API access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-healthcare.iam.gserviceaccount.com --role=roles/healthcare.dicomStoreAdmin
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/pubsub.subscriber # to revoke PubSub access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/pubsub.subscriber
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.hl7V2Consumer # to revoke Healthcare API access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.hl7V2Consumer
    echo
    echo "$ gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.fhirResourceEditor # to revoke Healthcare API access" | pv -qL 100
    gcloud projects remove-iam-policy-binding $GCP_PROJECT --member=serviceAccount:${COMPUTE_SA}@developer.gserviceaccount.com --role=roles/healthcare.fhirResourceEditor 
    echo
    echo "$ gcloud iam service-accounts delete ${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com  # to delete Healthcare API service account" | pv -qL 100
    gcloud iam service-accounts delete ${PSSAN}@${GCP_PROJECT}.iam.gserviceaccount.com 
else
    export STEP="${STEP},5i"   
    echo
    echo "1. Create service accounts and add IAM binding" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"6")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},6i"
    echo
    echo "$ gsutil mb gs://\${GCP_PROJECT}-df-pipeline # to create GCS bucket" | pv -qL 100
    echo
    echo "$ gsutil -m cp -r \$PROJDIR/mapping_configs gs://\${GCP_PROJECT}-df-pipeline/mapping/mapping_configs # to upload modified files into GCS bucket" | pv -qL 100
    echo
    echo "$ gsutil cp \$PROJDIR/empty.txt gs://\${GCP_PROJECT}-df-pipeline/error/empty.txt # to copy files to GCS bucket" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},6"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gsutil mb gs://${GCP_PROJECT}-df-pipeline # to create GCS bucket" | pv -qL 100
    gsutil mb gs://${GCP_PROJECT}-df-pipeline
    echo
    echo "$ git clone https://github.com/GoogleCloudPlatform/healthcare-data-harmonization /tmp/healthcare-data-harmonization # to clone git repo" | pv -qL 100
    git clone https://github.com/GoogleCloudPlatform/healthcare-data-harmonization /tmp/healthcare-data-harmonization
    echo
    echo "$ cp -rf /tmp/healthcare-data-harmonization/mapping_configs $PROJDIR # to copy configs" | pv -qL 100
    cp -rf /tmp/healthcare-data-harmonization/mapping_configs $PROJDIR
    echo
    echo "$ sed -i 's|\\\$MAPPING_ENGINE_HOME|gs://'\"${MAPPING_BUCKET}\"'|g' $PROJDIR/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto # to customize mapping file" | pv -qL 100
    sed -i 's|\$MAPPING_ENGINE_HOME|gs://'"${MAPPING_BUCKET}"'|g' $PROJDIR/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
    echo
    echo "$ sed -i 's|local_path|gcs_location|g' $PROJDIR/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto # to customize mapping file" | pv -qL 100
    sed -i 's|local_path|gcs_location|g' $PROJDIR/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
    echo
    echo "$ gsutil -m cp -r $PROJDIR/mapping_configs gs://${GCP_PROJECT}-df-pipeline/mapping/mapping_configs # to upload modified files into GCS bucket" | pv -qL 100
    gsutil -m cp -r $PROJDIR/mapping_configs gs://${GCP_PROJECT}-df-pipeline/mapping/mapping_configs
    echo
    touch $PROJDIR/empty.txt
    echo "$ gsutil cp $PROJDIR/empty.txt gs://${GCP_PROJECT}-df-pipeline/error/empty.txt # to copy files to GCS bucket" | pv -qL 100
    gsutil cp $PROJDIR/empty.txt gs://${GCP_PROJECT}-df-pipeline/error/empty.txt
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},6x"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gcloud storage rm --recursive gs://${GCP_PROJECT}-df-pipeline # to delete GCS bucket" | pv -qL 100
    gcloud storage rm --recursive gs://${GCP_PROJECT}-df-pipeline
else
    export STEP="${STEP},6i"   
    echo
    echo "1. Create GCS buckets for mapping configs" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"7")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},7i"
    echo
    echo "$ gcloud iam service-accounts keys create \$PROJDIR/\${GCP_PROJECT}.json --iam-account=\${GCP_PROJECT}@\${GCP_PROJECT}.iam.gserviceaccount.com # to create key required to generate and print an access token" | pv -qL 100
    echo
    echo "$ gsutil mb gs://\${GCP_PROJECT}-df-pipeline # to create GCS bucket" | pv -qL 100
    echo
    echo "$ curl -X PATCH -H \"Authorization: Bearer \$(gcloud auth application-default print-access-token)\" -H \"Content-Type: application/json; charset=utf-8\" --data \"{
     'parserConfig': {
       'schema': {
         'schematizedParsingType': 'HARD_FAIL',
         'ignoreMinOccurs' :true,
         'unexpectedSegmentHandling' : 'PARSE'
       }
     }
   }\" \"https://healthcare.googleapis.com/v1beta1/projects/\${GCP_PROJECT}/locations/\${LOCATION}/datasets/\${DATASET_ID}/hl7V2Stores/\${HL7_STORE_ID}?updateMask=parser_config.schema\" # to patch the respective datastores to modify behaviors" | pv -qL 100
    echo
    echo "$ curl -X PATCH -H \"Authorization: Bearer \$(gcloud auth application-default print-access-token)\" -H \"Content-Type: application/json; charset=utf-8\" --data \"{
 'streamConfigs': [
   { 'bigqueryDestination': {
     'datasetUri': 'bq://\${GCP_PROJECT}.\${BQ_FHIR}', 'schemaConfig': {
       'schemaType': 'ANALYTICS'
       }
     }
   }
 ]
}\" \"https://healthcare.googleapis.com/v1/projects/\${GCP_PROJECT}/locations/\${LOCATION}/datasets/\${DATASET_ID}/fhirStores/\${FHIR_STORE_ID}?updateMask=streamConfigs\" # to enable streaming from FHIR Store to BigQuery" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},7"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gsutil mb gs://${GCP_PROJECT}-df-pipeline # to create GCS bucket" | pv -qL 100
    echo
    echo "$ curl -X PATCH -H \"Authorization: Bearer \$(gcloud auth application-default print-access-token)\" -H \"Content-Type: application/json; charset=utf-8\" --data \"{
     'parserConfig': {
       'schema': {
         'schematizedParsingType': 'HARD_FAIL',
         'ignoreMinOccurs' :true,
         'unexpectedSegmentHandling' : 'PARSE'
       }
     }
   }\" \"https://healthcare.googleapis.com/v1beta1/projects/${GCP_PROJECT}/locations/${LOCATION}/datasets/${DATASET_ID}/hl7V2Stores/${HL7_STORE_ID}?updateMask=parser_config.schema\" # to patch the respective datastores to modify behaviors" | pv -qL 100
curl -X PATCH -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H "Content-Type: application/json; charset=utf-8" --data "{
     'parserConfig': {
       'schema': {
         'schematizedParsingType': 'HARD_FAIL',
         'ignoreMinOccurs' :true,
         'unexpectedSegmentHandling' : 'PARSE'
       }
     }
   }" "https://healthcare.googleapis.com/v1beta1/projects/${GCP_PROJECT}/locations/${LOCATION}/datasets/${DATASET_ID}/hl7V2Stores/${HL7_STORE_ID}?updateMask=parser_config.schema" | pv -qL 100
    echo
    echo "$ curl -X PATCH -H \"Authorization: Bearer \$(gcloud auth application-default print-access-token)\" -H \"Content-Type: application/json; charset=utf-8\" --data \"{
 'streamConfigs': [
   { 'bigqueryDestination': {
     'datasetUri': 'bq://${GCP_PROJECT}.${BQ_FHIR}', 'schemaConfig': {
       'schemaType': 'ANALYTICS'
       }
     }
   }
 ]
}\" \"https://healthcare.googleapis.com/v1/projects/${GCP_PROJECT}/locations/${LOCATION}/datasets/${DATASET_ID}/fhirStores/${FHIR_STORE_ID}?updateMask=streamConfigs\" # to enable streaming from FHIR Store to BigQuery" | pv -qL 100
curl -X PATCH -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" -H "Content-Type: application/json; charset=utf-8" --data "{
 'streamConfigs': [
   { 'bigqueryDestination': {
     'datasetUri': 'bq://${GCP_PROJECT}.${BQ_FHIR}', 'schemaConfig': {
       'schemaType': 'ANALYTICS'
       }
     }
   }
 ]
}" "https://healthcare.googleapis.com/v1/projects/${GCP_PROJECT}/locations/${LOCATION}/datasets/${DATASET_ID}/fhirStores/${FHIR_STORE_ID}?updateMask=streamConfigs"
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},7x"   
    echo
    echo "*** Nothing to delete ***" | pv -qL 100
else
    export STEP="${STEP},7i"   
    echo
    echo "1. Update configuration HC API datastores" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"8")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},8i"
    echo
    echo "$ gcloud beta container clusters create \$GCP_CLUSTER --project \$GCP_PROJECT --zone \$GCP_ZONE --machine-type e2-standard-8 --scopes https://www.googleapis.com/auth/cloud-platform --num-nodes 1 --enable-autoscaling --min-nodes 1 --max-nodes 2 # to create GKE cluster to run SimulatedHospital, Dataflow Job Creator and MLLP Adapter containers" | pv -qL 100
    echo
    echo "$ gcloud container clusters get-credentials \$GCP_CLUSTER # to retrieve cluster credentials" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},8"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ gcloud beta container clusters create $GCP_CLUSTER --project $GCP_PROJECT --zone $GCP_ZONE --machine-type e2-standard-8 --scopes https://www.googleapis.com/auth/cloud-platform --num-nodes 1 --enable-autoscaling --min-nodes 1 --max-nodes 2 # to create GKE cluster to run SimulatedHospital, Dataflow Job Creator and MLLP Adapter containers" | pv -qL 100
    gcloud beta container clusters create $GCP_CLUSTER --project $GCP_PROJECT --zone $GCP_ZONE --machine-type e2-standard-8 --scopes https://www.googleapis.com/auth/cloud-platform --num-nodes 1 --enable-autoscaling --min-nodes 1 --max-nodes 2
    echo
    echo "$ gcloud container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE # to retrieve cluster credentials" | pv -qL 100
    gcloud container clusters get-credentials $GCP_CLUSTER --zone $GCP_ZONE 
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},8x"   
    echo
    echo "$ gcloud beta container clusters delete $GCP_CLUSTER --project $GCP_PROJECT --zone $GCP_ZONE # to delete GKE cluster" | pv -qL 100
    gcloud beta container clusters delete $GCP_CLUSTER --project $GCP_PROJECT --zone $GCP_ZONE
else
    export STEP="${STEP},8i"   
    echo
    echo "1. Create GKE cluster" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"9")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},9i"
    echo
    echo "$ cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: mllp-adapter-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: mllp-adapter
 template:
   metadata:
     labels:
       app: mllp-adapter
   spec:
     containers:
       - name: mllp-adapter
         imagePullPolicy: Always
         image: gcr.io/cloud-healthcare-containers/mllp-adapter
         ports:
           - containerPort: 2575
             protocol: TCP
             name: \"port\"
         command:
           - \"/usr/mllp_adapter/mllp_adapter\"
           - \"--port=2575\"
           - \"--hl7_v2_project_id=\${GCP_PROJECT}\"
           - \"--hl7_v2_location_id=\${LOCATION}\"
           - \"--hl7_v2_dataset_id=\${DATASET_ID}\"
           - \"--hl7_v2_store_id=\${HL7_STORE_ID}\"
           - \"--api_addr_prefix=https://healthcare.googleapis.com:443/v1\"
           - \"--logtostderr\"
           - \"--receiver_ip=0.0.0.0\" # to deploy MLLP Adapter deployment
EOF" | pv -qL 100
    echo
    echo "$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
 name: mllp-adapter-service
 annotations:
   cloud.google.com/load-balancer-type: \"Internal\"
spec:
 type: LoadBalancer
 ports:
 - name: port
   port: 2575
   targetPort: 2575
   protocol: TCP
 selector:
   app: mllp-adapter # to deploy MLLP Adapter service
EOF" | pv -qL 100
    echo
    echo "$ cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: simhospital-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: simhospital
 template:
   metadata:
     labels:
       app: simhospital
   spec:
     containers:
       - name: simhospital
         imagePullPolicy: Always
         image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/simhospital:latest
         ports:
           - containerPort: 8000
             protocol: TCP
             name: \"port\"
         command: [\"/health/simulator\"]
         args: [\"-output=mllp\", \"-mllp_destination=\$(kubectl get svc | grep mllp-adapter | awk {print'\$4'}):2575\"] # to deploy SimHospital application to generate fake HL7 test data
EOF" | pv -qL 100
    echo
    echo "$ cat <<EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
 labels:
   run: dataflow-pipeline
 name: dataflow-pipeline
spec:
 containers:
 - command:
   - /usr/local/openjdk-11/bin/java
   - -jar
   - /root/converter-0.1.0-all.jar
   - --pubSubSubscription=projects/\${GCP_PROJECT}/subscriptions/\${HL7_SUB}
   - --readErrorPath=gs://\${ERROR_BUCKET}read/read_error.txt
   - --writeErrorPath=gs://\${ERROR_BUCKET}write/write_error.txt
   - --mappingErrorPath=gs://\${ERROR_BUCKET}mapping/mapping_error.txt
   - --mappingPath=gs://\${MAPPING_BUCKET}/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
   - --fhirStore=projects/\${GCP_PROJECT}/locations/\${LOCATION}/datasets/\${DATASET_ID}/fhirStores/\${FHIR_STORE_ID}
   - --runner=DataflowRunner
   - --project=\${GCP_PROJECT}
   - --region=\${LOCATION}
   image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/dataflow-pipeline:v0.01
   imagePullPolicy: Always
   name: dataflow-pipeline
 restartPolicy: Never # to run Dataflow job
EOF" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},9"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: mllp-adapter-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: mllp-adapter
 template:
   metadata:
     labels:
       app: mllp-adapter
   spec:
     containers:
       - name: mllp-adapter
         imagePullPolicy: Always
         image: gcr.io/cloud-healthcare-containers/mllp-adapter
         ports:
           - containerPort: 2575
             protocol: TCP
             name: \"port\"
         command:
           - \"/usr/mllp_adapter/mllp_adapter\"
           - \"--port=2575\"
           - \"--hl7_v2_project_id=$GCP_PROJECT\"
           - \"--hl7_v2_location_id=$LOCATION\"
           - \"--hl7_v2_dataset_id=$DATASET_ID\"
           - \"--hl7_v2_store_id=$HL7_STORE_ID\"
           - \"--api_addr_prefix=https://healthcare.googleapis.com:443/v1\"
           - \"--logtostderr\"
           - \"--receiver_ip=0.0.0.0\" # to deploy MLLP Adapter deployment
EOF" | pv -qL 100
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: mllp-adapter-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: mllp-adapter
 template:
   metadata:
     labels:
       app: mllp-adapter
   spec:
     containers:
       - name: mllp-adapter
         imagePullPolicy: Always
         image: gcr.io/cloud-healthcare-containers/mllp-adapter
         ports:
           - containerPort: 2575
             protocol: TCP
             name: "port"
         command:
           - "/usr/mllp_adapter/mllp_adapter"
           - "--port=2575"
           - "--hl7_v2_project_id=$GCP_PROJECT"
           - "--hl7_v2_location_id=$LOCATION"
           - "--hl7_v2_dataset_id=$DATASET_ID"
           - "--hl7_v2_store_id=$HL7_STORE_ID"
           - "--api_addr_prefix=https://healthcare.googleapis.com:443/v1"
           - "--logtostderr"
           - "--receiver_ip=0.0.0.0"
EOF
    echo
    echo "$ kubectl wait --for=condition=available --timeout=600s deployment --all # to wait for the deployment" | pv -qL 100
    kubectl wait --for=condition=available --timeout=600s deployment --all    
    echo
    echo "$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
 name: mllp-adapter-service
 annotations:
   cloud.google.com/load-balancer-type: \"Internal\"
spec:
 type: LoadBalancer
 ports:
 - name: port
   port: 2575
   targetPort: 2575
   protocol: TCP
 selector:
   app: mllp-adapter # to deploy MLLP Adapter service
EOF" | pv -qL 100
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
 name: mllp-adapter-service
 annotations:
   cloud.google.com/load-balancer-type: "Internal"
spec:
 type: LoadBalancer
 ports:
 - name: port
   port: 2575
   targetPort: 2575
   protocol: TCP
 selector:
   app: mllp-adapter
EOF
    echo
    echo "$ cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: simhospital-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: simhospital
 template:
   metadata:
     labels:
       app: simhospital
   spec:
     containers:
       - name: simhospital
         imagePullPolicy: Always
         image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/simhospital:latest
         ports:
           - containerPort: 8000
             protocol: TCP
             name: \"port\"
         command: [\"/health/simulator\"]
         args: [\"-output=mllp\", \"-mllp_destination=\$(kubectl get svc | grep mllp-adapter | awk {print'\$4'}):2575\"] # to deploy SimHospital application to generate fake HL7 test data
EOF" | pv -qL 100
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
 name: simhospital-deployment
spec:
 replicas: 1
 selector:
   matchLabels:
     app: simhospital
 template:
   metadata:
     labels:
       app: simhospital
   spec:
     containers:
       - name: simhospital
         imagePullPolicy: Always
         image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/simhospital:latest
         ports:
           - containerPort: 8000
             protocol: TCP
             name: "port"
         command: ["/health/simulator"]
         args: ["-output=mllp", "-mllp_destination=$(kubectl get svc | grep mllp-adapter | awk {print'$4'}):2575"] 
EOF
    echo
    echo "$ kubectl wait --for=condition=available --timeout=600s deployment --all # to wait for the deployment" | pv -qL 100
    kubectl wait --for=condition=available --timeout=600s deployment --all    
    echo
    echo "$ cat <<EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
 labels:
   run: dataflow-pipeline
 name: dataflow-pipeline
spec:
 containers:
 - command:
   - /usr/local/openjdk-11/bin/java
   - -jar
   - /root/converter-0.1.0-all.jar
   - --pubSubSubscription=projects/\$GCP_PROJECT/subscriptions/\$HL7_SUB
   - --readErrorPath=gs://\${ERROR_BUCKET}read/read_error.txt
   - --writeErrorPath=gs://\${ERROR_BUCKET}write/write_error.txt
   - --mappingErrorPath=gs://\${ERROR_BUCKET}mapping/mapping_error.txt
   - --mappingPath=gs://\$MAPPING_BUCKET/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
   - --fhirStore=projects/\$GCP_PROJECT/locations/\${LOCATION}/datasets/\$DATASET_ID/fhirStores/\$FHIR_STORE_ID
   - --runner=DataflowRunner
   - --project=\$GCP_PROJECT
   - --region=\$LOCATION
   image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/dataflow-pipeline:v0.01
   imagePullPolicy: Always
   name: dataflow-pipeline
 restartPolicy: Never # to run Dataflow job
EOF" | pv -qL 100
cat <<EOF | kubectl replace --force -f -
apiVersion: v1
kind: Pod
metadata:
 labels:
   run: dataflow-pipeline
 name: dataflow-pipeline
spec:
 containers:
 - command:
   - /usr/local/openjdk-11/bin/java
   - -jar
   - /root/converter-0.1.0-all.jar
   - --pubSubSubscription=projects/$GCP_PROJECT/subscriptions/$HL7_SUB
   - --readErrorPath=gs://${ERROR_BUCKET}read/read_error.txt
   - --writeErrorPath=gs://${ERROR_BUCKET}write/write_error.txt
   - --mappingErrorPath=gs://${ERROR_BUCKET}mapping/mapping_error.txt
   - --mappingPath=gs://$MAPPING_BUCKET/mapping_configs/hl7v2_fhir_r4/configurations/main.textproto
   - --fhirStore=projects/$GCP_PROJECT/locations/$LOCATION/datasets/$DATASET_ID/fhirStores/$FHIR_STORE_ID
   - --runner=DataflowRunner
   - --project=$GCP_PROJECT
   - --region=$LOCATION
   image: us-docker.pkg.dev/qwiklabs-resources/healthcare-qwiklabs-resources/dataflow-pipeline:v0.01
   imagePullPolicy: Always
   name: dataflow-pipeline
 restartPolicy: Never # to run Dataflow job
EOF
elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},9x"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ kubectl delete service mllp-adapter-service # to delete service" | pv -qL 100
    kubectl delete service mllp-adapter-service
    echo
    echo "$ kubectl delete deployment mllp-adapter-deployment # to delete deployment" | pv -qL 100
    kubectl delete deployment mllp-adapter-deployment
    echo
    echo "$ kubectl delete deployment simhospital-deployment # to delete deployment" | pv -qL 100
    kubectl delete deployment simhospital-deployment
    echo
    echo "$ kubectl delete Pod dataflow-pipeline # to delete Pod" | pv -qL 100
    kubectl delete Pod dataflow-pipeline
else
    export STEP="${STEP},9i"   
    echo
    echo "1. Create deployment and service for MLLP adapter" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"10")
start=`date +%s`
source $PROJDIR/.env
if [ $MODE -eq 1 ]; then
    export STEP="${STEP},10i"
    echo
    echo "$ curl -X GET -H \"Authorization: Bearer \"\$(gcloud auth print-access-token) -H \"Content-Type: application/json; charset=utf-8\" \"https://healthcare.googleapis.com/v1beta1/projects/\$GCP_PROJECT/locations/\$LOCATION/datasets/\$DATASET_ID/hl7V2Stores/\$HL7_STORE_ID/messages\" # to make sure that HL7 data is stored in HL7 datastore" | pv -qL 100
elif [ $MODE -eq 2 ]; then
    export STEP="${STEP},10"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "$ curl -X GET -H \"Authorization: Bearer \"\$(gcloud auth print-access-token) -H \"Content-Type: application/json; charset=utf-8\" \"https://healthcare.googleapis.com/v1beta1/projects/$GCP_PROJECT/locations/$LOCATION/datasets/$DATASET_ID/hl7V2Stores/$HL7_STORE_ID/messages\" # to make sure that HL7 data is stored in HL7 datastore" | pv -qL 100
    curl -X GET -H "Authorization: Bearer "$(gcloud auth print-access-token) -H "Content-Type: application/json; charset=utf-8" "https://healthcare.googleapis.com/v1beta1/projects/$GCP_PROJECT/locations/$LOCATION/datasets/$DATASET_ID/hl7V2Stores/$HL7_STORE_ID/messages"
    echo
    echo "*** Confirm data has been ingested into FHIR datastore ***" | pv -qL 100
    echo "*** Healthcare -> FHIR viewer | FHIR Store >  datastore -> fhirstore | Resource type >  Patient ***" | pv -qL 100
    echo "*** BigQuery > Project ID >  fhirdata >  Patient_* table >  Preview  ***" | pv -qL 100
 elif [ $MODE -eq 3 ]; then
    export STEP="${STEP},10x"   
    gcloud config set project $GCP_PROJECT > /dev/null 2>&1
    echo
    echo "*** Nothing to delete ***" | pv -qL 100
else
    export STEP="${STEP},10i"   
    echo
    echo "1. Validate HL7 Data Creation" | pv -qL 100
fi
end=`date +%s`
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"R")
echo
echo "
  __                      __                              __                               
 /|            /         /              / /              /                 | /             
( |  ___  ___ (___      (___  ___        (___           (___  ___  ___  ___|(___  ___      
  | |___)|    |   )     |    |   )|   )| |    \   )         )|   )|   )|   )|   )|   )(_/_ 
  | |__  |__  |  /      |__  |__/||__/ | |__   \_/       __/ |__/||  / |__/ |__/ |__/  / / 
                                 |              /                                          
"
echo "
We are a group of information technology professionals committed to driving cloud 
adoption. We create cloud skills development assets during our client consulting 
engagements, and use these assets to build cloud skills independently or in partnership 
with training organizations.
 
You can access more resources from our iOS and Android mobile applications.

iOS App: https://apps.apple.com/us/app/tech-equity/id1627029775
Android App: https://play.google.com/store/apps/details?id=com.techequity.app

Email:support@techequity.cloud 
Web: https://techequity.cloud

Ⓒ Tech Equity 2022" | pv -qL 100
echo
echo Execution time was `expr $end - $start` seconds.
echo
read -n 1 -s -r -p "$ "
;;

"G")
cloudshell launch-tutorial $SCRIPTPATH/.tutorial.md
;;

"Q")
echo
exit
;;
"q")
echo
exit
;;
* )
echo
echo "Option not available"
;;
esac
sleep 1
done

"Q")
echo
exit
;;
"q")
echo
exit
;;
* )
echo
echo "Option not available"
;;
esac
sleep 1
done
