# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Install Script for Monitoring Module (APM)
#
# V1.0 
#
# ©2020 nikh@ch.ibm.com
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"

source ./0_variables.sh

# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Do Not Edit Below
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo " ${CYAN} Install Monitoring Module (APM) for OpenShift 4.3${NC}"
echo "  "
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "



# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# GET PARAMETERS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${magnifying} Input Parameters${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        while getopts "t:d:h:p:s:x:" opt
        do
          case "$opt" in
              t ) INPUT_TOKEN="$OPTARG" ;;
              d ) INPUT_PATH="$OPTARG" ;;
              h ) INPUT_CLUSTER_NAME="$OPTARG" ;;
              p ) INPUT_PWD="$OPTARG" ;;
              s ) INPUT_SC="$OPTARG" ;;
              x ) INPUT_CONSOLE_PREFIX="$OPTARG";;
          esac
        done



        if [[ $INPUT_TOKEN == "" ]];
        then
        echo "    ${RED}ERROR${NC}: Please provide the Registry Token"
        echo "    USAGE: $0 -t <REGISTRY_TOKEN> -x <OCP_CONSOLE_PREFIX> [-h <CLUSTER_NAME>] [-p <MCM_PASSWORD>] [-d <TEMP_DIRECTORY>] [-s <STORAGE_CLASS_BLOCK>]"
        exit 1
        else
          echo "    ${GREEN}Token OK:${NC}                           $INPUT_TOKEN"
          ENTITLED_REGISTRY_KEY=$INPUT_TOKEN
        fi


        if [[ $INPUT_CONSOLE_PREFIX == "" ]];
        then
            echo "    ${RED}ERROR${NC}: Please provide the OCP console prefix (for example console)"
            echo "    USAGE: $0 -t <REGISTRY_TOKEN> -x <OCP_CONSOLE_PREFIX> [-h <CLUSTER_NAME>] [-p <MCM_PASSWORD>] [-d <TEMP_DIRECTORY>] [-s <STORAGE_CLASS_BLOCK>]"
            exit 1
        else
          echo "    ${GREEN}Console Prefix OK:${NC}                  $INPUT_CONSOLE_PREFIX"
          OCP_CONSOLE_PREFIX=$INPUT_CONSOLE_PREFIX
        fi


        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          echo "    ${ORANGE}No Cluster Name provided${NC}            ${GREEN}will be determined from Kubeconfig${NC}"
        else
          echo "    ${GREEN}Cluster OK:${NC}                           $INPUT_CLUSTER_NAME"
          CLUSTER_NAME=$INPUT_CLUSTER_NAME
        fi



        if [[ $INPUT_PWD == "" ]];          
        then
          echo "    ${ORANGE}No Password provided, using${NC}         $MCM_PWD"
        else
          echo "    ${GREEN}Password OK:${NC}                        '********"
          MCM_PWD=$INPUT_PWD
        fi



        if [[ $INPUT_PATH == "" ]];
        then
          echo "    ${ORANGE}No Path provided, using${NC}             $TEMP_PATH"
        else
          echo "    ${GREEN}Path OK:${NC}                            $INPUT_PATH"
          TEMP_PATH=$INPUT_PATH
        fi



        if [[ $INPUT_SC == "" ]];
        then
          echo "    ${ORANGE}No Storage Class provided, using${NC}    $STORAGE_CLASS_BLOCK"
        else
          echo "    ${GREEN}Storage Class OK:${NC}                   $INPUT_SC"
          STORAGE_CLASS_BLOCK=$INPUT_SC
        fi

        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          getClusterFQDN
          #CLUSTER_FQDN=$? 
        fi

echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "





# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Define some Stuff
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${memo} Define some Stuff${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        getInstallPath

echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CONFIG SUMMARY
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${GREEN}***************************************************************************************************************************${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}${healthy} APM will be installed in Cluster ${ORANGE}'$CLUSTER_NAME'${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo " ${CYAN} ${magnifying} Your configuration${NC}"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CLUSTER :${NC}             $CLUSTER_NAME"
echo "    ${GREEN}REGISTRY TOKEN:${NC}       $ENTITLED_REGISTRY_KEY"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}MCM Server:${NC}           $MCM_SERVER"
echo "    ${GREEN}MCM User Name:${NC}        $MCM_USER"
echo "    ${GREEN}MCM User Password:${NC}    ************"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}STORAGE CLASS:${NC}        $STORAGE_CLASS_BLOCK"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}INSTALL PATH:${NC}         $INSTALL_PATH"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "



# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PREREQUISITES
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${wrench} Install Prerequisites${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        export SCRIPT_PATH=$(pwd)

        echo "---------------------------------------------------------------------------------------------------------------------------"
        echo " Create ${CYAN}Config Directory${NC}"
        rm -r $INSTALL_PATH/* 
        mkdir -p $INSTALL_PATH 
        cd $INSTALL_PATH
        echo "    ${GREEN}  OK${NC}"

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " Create ${CYAN}Secret${NC}"
        kubectl delete secret -n kube-system apmsecret
        kubectl create secret docker-registry apmsecret --docker-username="$ENTITLED_REGISTRY_USER" --docker-password="$ENTITLED_REGISTRY_KEY" --docker-email="test@us.ibm.com" --docker-server="cp.icr.io" -n kube-system
        #kubectl describe secret -n kube-system apmsecret
        echo "    ${GREEN}  OK${NC}"
        echo "  "

        echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " Create ${CYAN}Service Account${NC}"
        kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "apmsecret"}]}' -n kube-system
        echo "    ${GREEN}  OK${NC}"
        #kubectl describe serviceaccount default -n kube-system

echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "



# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# HELM CHART
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${wrench} Helm Chart${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        helm repo update

        CHART_EXISTS=$(ls 2>&1)

        if [[ $CHART_EXISTS =~ $APM_VERSION ]];
        then
          echo "    ${GREEN}OK - Chart already Downloaded${NC}"
        else 
          echo "    ${GREEN}Downloading Chart${NC}"
          #echo "cloudctl login -a ${MCM_SERVER} --skip-ssl-validation -u ${MCM_USER} -p ${MCM_PWD} -n kube-system"
          LOGIN_OK=$(cloudctl login -a ${MCM_SERVER} --skip-ssl-validation -u ${MCM_USER} -p ${MCM_PWD} -n kube-system)
          if [[ $LOGIN_OK =~ "Error response from server" ]];
          then
                echo "    ${RED}ERROR${NC}: Could not login to MCM Hub on Cluster '$CLUSTER_NAME'. Aborting."
                exit 2
          else
            $HELM_BIN init --client-only
            $HELM_BIN repo add ibm-entitled-charts https://raw.githubusercontent.com/IBM/charts/master/repo/entitled/
            $HELM_BIN repo update
            $HELM_BIN fetch ibm-entitled-charts/ibm-cloud-appmgmt-prod --version $APM_VERSION
          fi
        fi

echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "








# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INSTALL
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${RED} Installing Monitoring Module (APM) into Cluster '$CLUSTER_NAME'${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"

            $HELM_BIN install --name $APM_HELM_RELEASE_NAME ibm-cloud-appmgmt-prod-$APM_VERSION.tgz \
            --namespace kube-system  \
            --set global.license="accept"  \
            --set global.ingress.domain="icp-console.$CLUSTER_NAME"  \
            --set global.ingress.port="443"  \
            --set global.icammcm.ingress.domain="icp-proxy.$CLUSTER_NAME"  \
            --set global.masterIP="icp-console.$CLUSTER_NAME"  \
            --set global.masterPort="443"  \
            --set ibm-cem.icpbroker.adminusername="admin"  \
            --set global.image.pullSecret=apmsecret  \
            --set createTLSCerts="true"  \
            $HELM_TLS & 2>&1

            echo ""
            echo ""
            echo ""
            echo ""
            echo ""
            echo ""
          

        sleep 120


echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"

echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}${healthy} Monitoring Module (APM) Installation.... DONE${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"



