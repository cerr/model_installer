#!/bin/bash

function print_stratis_logo {
        #base64 -d <<<H4sIAApMMWYAA31QWwoDIRD79xT56y4UvJCQHiSHbyaztYWWDuKYx0QRoAvw+ijizbAN3zUwS5Qg2s1ehQ6emVGm1fmXHsqzq9qSkXAjHfVAo5k9qT6WZ+vBIxFnHPHhuPyqVKzcW2w8W/fUHHax0la9y5z7nWoU4cVybh2lU+PXJ/yrDuy/egIijh69aAEAAA== | gunzip
        base64 -d <<<H4sIACUzV2YAA43S2w3AIAgF0P87BRv47ywkbOLsVQHFRxNJ0/SE4LW2RK1EhGa9CP2e6sWj9yS4coq9nCQq8yH8zHmKivMhzDndvc9ppqrYulGgJNKfdPcmy5xqqy4C1diWbUkqn3W12lS3apP2nl02N1RqbYKb/Xxu8oMLAoWU0F11mdQfgEV4fI834QOhVOhJcwIAAA== | gunzip
        echo " "
        echo "Medical Physics Department, Memorial Sloan Kettering Cancer Center, New York, NY"
        echo " "
}

N_MODELS=12

function define_models {
        N=$1
        case ${N} in
           1)
                MODEL_NAME=CT_cardiac_structures_deeplab
                ;;
           2)
                MODEL_NAME=CT_LungOAR_incrMRRN
                ;;
           3)
                MODEL_NAME=MR_Prostate_Deeplab
                ;;
           4)
                MODEL_NAME=CT_Lung_SMIT
                ;;
           5)
                MODEL_NAME=MRI_Pancreas_Fullshot_AnatomicCtxShape
                ;;
           6)
                MODEL_NAME=CT_HeadAndNeck_OARs
                ;;
           7)
                MODEL_NAME=CT_HN_SMIT
                ;;
           8)
                MODEL_NAME=CT_HeartSubstruct_SMIT
                ;;
           9)
                MODEL_NAME=CT_WHOLEBODY_SMITplus
                ;;
          10)
                MODEL_NAME=MR_Rectum_GTV_SMIT
                ;;

          11)
                MODEL_NAME=MR_HN_Nodule_SMIT
                ;;
		      12)
                MODEL_NAME=CT_Lung_OAR_SMITplus
                ;;
           *)
                echo Error
                ;;
        esac

        echo $MODEL_NAME #${MODEL_GIT} ${MODEL_WEIGHTS} ${CONDAPACK}
}

function print_model_opts {
        N_MODELS=$1
        echo "The following are the list of available models. When passing the argument to installer, select the number of the model to download: "
        for N in `seq 1 ${N_MODELS}`
        do
                echo "                  ${N}.  `define_models ${N}`"
        done
}

function help_text {
        N_MODELS=$1
        echo "Usage Information: "
        echo "  Flags: "
        echo "          -i : Flag to run installer in interactive mode (no argument)"
        echo "          -m : [1-${N_MODELS}] Integer number to select model to install. For list of available options, see below. "
        echo "          -d : Directory to install model with network weights "
        echo "          -p : [P/C/N] Setup and install Python environment P: setup Conda env from python requirements.txt; C: Conda pack download; N: No install. " #User must already have Anaconda installed and initiated. "
        echo "          -n : [1-${N_MODELS}] Print the model name of number argument "		
	    echo "          -r : Provide URL to tar archive for model weights (optional) "
		echo "          -u : User credentials for private GitHub repo, format is user:token "
        echo "          -h : Print help menu "
        echo " "
        print_model_opts $N_MODELS
}

function intro_text {
        echo "Welcome to the CERR segmentation model installer! For usage information, run with -h flag"
        echo " "
}


print_stratis_logo $N_MODELS
intro_text $N_MODELS


#Initialize default options
IMODE=0
MODEL_NUM=1
MODEL_NAME="NONE"
INSTALLDIR="$HOME"
POPTION="N"


# parse input arguments
while getopts ":hm:d:ip:n:u:r:" opt; do
  case $opt in
    h)
        help_text $N_MODELS
        exit 0
      ;;
    m)
    MODEL_NUM=${OPTARG}
        MODEL_NAME=`define_models ${MODEL_NUM}`
        if [ "${MODEL_NAME}" == "Error" ]; then MODEL_NUM="NONE"; fi
      ;;
    d)
        INSTALLDIR=${OPTARG}
      ;;
    p)
        POPTION=${OPTARG}
        if [[ "${POPTION}" != "P" && "${POPTION}" != "C" && "${POPTION}" != "U" ]]; then POPTION="N"; echo "Selected -p Python option invalid, defaulting to N"; fi
      ;;

    i)
        IMODE=1
      ;;
    n)
        define_models ${OPTARG}
        exit 0
      ;;
    u)
        TOK=${OPTARG}
      ;;
    r)
        MODEL_WEIGHTS=${OPTARG}
      ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
       ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done



# Interactive Mode
if [ "$IMODE" == "1" ]
then
        echo "Interactive installation mode selected."
        echo "======================================="

        echo " "
        echo "Press Ctrl-C at any time to exit"
        echo " "

        echo "Step 1. Model Selection"
        echo "***********************"
        echo " "

        print_model_opts $N_MODELS

        echo "Please select model to install on local machine [${MODEL_NUM}]: "

        read USR_ANS

        if [ "${USR_ANS}" != "" ]; then MODEL_NUM=${USR_ANS}; fi

        MODEL_STRING=`define_models ${MODEL_NUM}`
        MODEL_NAME=`echo ${MODEL_STRING}` #| awk '{ print $1 }'`
        #MODEL_GIT_HASH=`echo ${MODEL_STRING} | awk '{ print $2 }'`
        #MODEL_WEIGHTS_HASH=`echo ${MODEL_STRING} | awk '{ print $3 }'`
        #CONDAPACK_HASH=`echo ${MODEL_STRING} | awk '{ print $4 }'`

        if [ "${MODEL_NAME}" != "Error" ]
        then
                echo "Model selected is ${MODEL_NUM}. ${MODEL_NAME}"
        else
                echo "Error, no valid model selected [${MODEL_NUM}]"
                exit 1
        fi

        echo " "

        echo "Please provide GitHub access token if needed (format user:tokenstring), otherwise press [Enter]: "

        read USR_ANS
        TOK=${USR_ANS}

        echo "Step 2. Installation Directory"
        echo "******************************"
        echo " "
        echo "Please specify installation directory [${INSTALLDIR}]: "

        read USR_ANS

        if [ "${USR_ANS}" != "" ]; then INSTALLDIR=${USR_ANS}; fi

        echo "Installation directory selected is ${INSTALLDIR}"

        echo " "

        echo "Step 3. Python Option"
        echo "*********************"
        echo " "
        echo "Please select the option indicate if the installer should create the Python environment [${POPTION}]: " # [${PYSETUP}]: "
        echo "  P : Set up Conda environment from repository requirements.txt file"
        echo "  C : Download Conda-Pack environment"
        echo "  N : No Python setup"

        read USR_ANS

        if [ "${USR_ANS}" != "" ]
        then
                if [[ "${USR_ANS}" != "P" &&  ${USR_ANS} != "C" && "${USR_ANS}" != "U" ]]; then POPTION=N; else POPTION=${USR_ANS}; fi
        fi

        echo "Python setup option selected is ${POPTION}"


        echo "Proceeding with installation and setup"

else
    MODEL_NAME=`define_models ${MODEL_NUM}`
fi

# Verify all selected options

# Commence with install

mkdir -p ${INSTALLDIR}
cd ${INSTALLDIR}



if [ -z "$TOK" ]
then
        MODEL_GIT="https://github.com/cerr/${MODEL_NAME}.git"
else
        MODEL_GIT="https://${TOK}@github.com/cerr/${MODEL_NAME}.git"
fi

echo git clone ${MODEL_GIT}
git clone ${MODEL_GIT}



MODEL_FOLDER=${INSTALLDIR}/${MODEL_NAME}
cd ${MODEL_FOLDER}

if [ -z "${MODEL_WEIGHTS}" ]
then
	MODEL_WEIGHTS_HASH=`cat model.txt | grep MODEL_WEIGHTS | awk '{ print $2 }'`
	MODEL_WEIGHTS=`base64 -d <<<${MODEL_WEIGHTS_HASH} | gunzip`
fi


CONDAPACK_HASH=`cat model.txt | grep CONDAPACK | awk '{ print $2 }'`

echo wget -O model_weights.tar.gz -L ${MODEL_WEIGHTS}
wget -O model_weights.tar.gz -L ${MODEL_WEIGHTS}
echo tar xf model_weights.tar.gz
tar xf model_weights.tar.gz
rm model_weights.tar.gz

if [ "${POPTION}" == "C" ]
then
        #download conda-pack
        mkdir ${MODEL_FOLDER}/conda-pack
        cd ${MODEL_FOLDER}/conda-pack
        CONDAPACK=`base64 -d <<<${CONDAPACK_HASH} | gunzip`
        echo wget -O condapack.tar.gz -L ${CONDAPACK}
        wget -O condapack.tar.gz -L ${CONDAPACK}
        echo tar xf condapack.tar.gz
        tar xf condapack.tar.gz
        rm condapack.tar.gz
elif [ "${POPTION}" == "P" ]
then
         #set up Conda environment
        CONDAHOME=`conda info | grep "base environment" | awk '{ print $4 }'`
        if [ -z "${CONDAHOME}" ]
        then
                echo "Anaconda may not be installed; python setup cannot continue"
                echo "Exiting."
                exit 1
        fi
        conda deactivate
        conda env create -f ${MODEL_FOLDER}/environment.yml
        MODEL_NAME=`cat ${MODEL_FOLDER}/environment.yml | head -1 | awk '{ print $2 }'`        #conda activate ${MODEL_NAME}
elif [ "${POPTION}" == "U" ]
then
        echo "uv environment install option specified"
        cd ${MODEL_FOLDER}
        uv venv
        for REQ in `ls requirements/*.txt`
        do
          uv pip install -p .venv -r ${REQ}
        done
fi
