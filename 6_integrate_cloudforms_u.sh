# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Install Script for CloudForms Integration
#
# V1.0 
#
# ©2020 nikh@ch.ibm.com
#
# https://cloud.ibm.com/docs/cloud-pak-multicloud-management?topic=cloud-pak-multicloud-management-cf-getting-started
#
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"

source ./0_variables.sh
# export CLIENT_ID=YWRtaW51c2Vy   # adminuser
export CLIENT_ID=ZGVtbw==              
#export CLIENT_SECRET="bXlzdXBlcnNlY3RyZXQ="   # mysupersectret
export CLIENT_SECRET="UDRzc3cwcmQh"
export CF_IP=52.117.8.177




# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Do Not Edit Below
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo " ${CYAN} CloudForms Integration for OpenShift 4.3${NC}"
echo "  "
echo "${GREEN}***************************************************************************************************************************************************${NC}"
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
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Input Parameters${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"

        while getopts "d:h:p:x:i:" opt
        do
          case "$opt" in
              x ) INPUT_CONSOLE_PREFIX="$OPTARG";;
              d ) INPUT_PATH="$OPTARG" ;;
              h ) INPUT_CLUSTER_NAME="$OPTARG" ;;
              p ) INPUT_PWD="$OPTARG" ;;
              i ) INPUT_IP="$OPTARG" ;;
          esac
        done


echo $INPUT_IP

        if [[ $INPUT_CONSOLE_PREFIX == "" ]];
        then
          echo "    ${RED}ERROR${NC}: Please provide the OCP console prefix (for example console)"
          echo "    USAGE: $0 -x <OCP_CONSOLE_PREFIX> -i <CF IP> [-h <CLUSTER_NAME>] [-p <MCM_PASSWORD>] [-d <TEMP_DIRECTORY>] "
          exit 1
        else
          echo "    ${GREEN}Console Prefix OK:${NC}                  $INPUT_CONSOLE_PREFIX"
          OCP_CONSOLE_PREFIX=$INPUT_CONSOLE_PREFIX
        fi


        if [[ $INPUT_IP == "" ]];
        then
          echo "    ${RED}ERROR${NC}: Please provide the IP address of the CF instance"
          echo "    USAGE: $0 -x <OCP_CONSOLE_PREFIX> -i <CF IP> [-h <CLUSTER_NAME>] [-p <MCM_PASSWORD>] [-d <TEMP_DIRECTORY>] "
          exit 1
        else
          echo "    ${GREEN}CF IP:${NC}                              $INPUT_IP"
          CF_IP=$INPUT_IP
        fi



        if [[ $INPUT_PWD == "" ]];          
        then
          echo "    ${ORANGE}No Password provided, using${NC}         $MCM_PASSWORD"
        else
          echo "    ${GREEN}Password OK:${NC}                        '********"
          MCM_PASSWORD=$INPUT_PWD
        fi



        if [[ $INPUT_PATH == "" ]];
        then
          echo "    ${ORANGE}No Path provided, using${NC}             $TEMP_PATH"
        else
          echo "    ${GREEN}Path OK:${NC}                            $INPUT_PATH"
          TEMP_PATH=$INPUT_PATH
        fi


        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          getClusterFQDN
        fi


echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PRE-INSTALL CHECKS
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Pre-Install Checks${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"

        checkCloudctlExecutable

        checkOpenshiftReachable

        checkKubeconfigIsSet

echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "



# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Define some Stuff
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Define some Stuff${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"

        getInstallPath

        export CF_HOSTNAME=https://$CF_IP

echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# CONFIG SUMMARY
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN} CloudForms will be integrated into Cluster ${ORANGE}'$CLUSTER_NAME'${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo " ${PURPLE}Your configuration${NC}"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CLUSTER :${NC}             $CLUSTER_NAME"
echo "    ------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}MCM Server:${NC}           $MCM_SERVER"
echo "    ${GREEN}MCM Proxy:${NC}            $MCM_PROXY"
echo "    ${GREEN}Client ID:${NC}            $MCM_USER"
echo "    ${GREEN}Client Secret:${NC}        ************"
echo "    ---------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CF IP:${NC}                $CF_IP"
echo "    ------------------------------------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}INSTALL PATH:${NC}         $INSTALL_PATH"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${RED}Continue Installation with these Parameters? [y,N]${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
        read -p "[y,N]" DO_COMM
        if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then
          echo "${GREEN}Continue...${NC}"
        else
          echo "${RED}Installation Aborted${NC}"
          exit 2
        fi
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PREREQUISITES
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${CYAN}Running Prerequisites${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"

        echo "---------------------------------------------------------------------------------------------------------------------------"

        export SCRIPT_PATH=$(pwd)

        echo "---------------------------------------------------------------------------------------------------------------------------"
        echo " Create Config Directory"
          rm -r $INSTALL_PATH/* 
          mkdir -p $INSTALL_PATH 
          cd $INSTALL_PATH
        echo "    ${GREEN}  OK${NC}"
        echo "  "

echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${CYAN}Adapt config file${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"

        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Get registration.json template
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        cp $SCRIPT_PATH/tools/cloudforms/registration.json ./registration.json

        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Adapt registration.json FIle
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${GREEN}Adapt Adapt registration.json File${NC}"

        ${SED} -i "s@ICP_PROXY_URL@$MCM_PROXY@" registration.json
        ${SED} -i "s/ICP_PROXY_PORT/443/" registration.json
        ${SED} -i "s@ICP_ENDPOINT_URL@$MCM_SERVER@" registration.json
        ${SED} -i "s/ICP_ENDPOINT_PORT/443/" registration.json
        ${SED} -i "s/CLIENT_ID/$CLIENT_ID/" registration.json
        ${SED} -i "s/CLIENT_SECRET/$CLIENT_SECRET/" registration.json
        ${SED} -i "s@CF_HOSTNAME@$CF_HOSTNAME@" registration.json


        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Get manageiq-external-auth-openidc.conf template
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        cp $SCRIPT_PATH/tools/cloudforms/manageiq-external-auth-openidc.conf ./manageiq-external-auth-openidc.conf

        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Adapt manageiq-external-auth-openidc.conf FIle
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        echo " ${GREEN}Adapt Adapt manageiq-external-auth-openidc.conf File${NC}"

        ${SED} -i "s@CF_HOSTNAME@$CF_HOSTNAME@" manageiq-external-auth-openidc.conf
        ${SED} -i "s@MCM_PASSWORD@$MCM_PASSWORD@" manageiq-external-auth-openidc.conf
        ${SED} -i "s/CLIENT_SECRET/$CLIENT_SECRET/" manageiq-external-auth-openidc.conf
        ${SED} -i "s@MCM_SERVER@$MCM_SERVER@" manageiq-external-auth-openidc.conf
        ${SED} -i "s/CLIENT_ID/$CLIENT_ID/" manageiq-external-auth-openidc.conf



echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "





echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${GREEN}Current registration.json file for installation${NC}"
echo " ${GREEN}Please Check if it looks OK${NC}"
echo " ${ORANGE}vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv${NC}"
echo "  "
        cat registration.json
echo "  "
echo " ${ORANGE}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^${NC}"
echo " ${ORANGE}vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv${NC}"
echo "  "
        cat manageiq-external-auth-openidc.conf
echo "  "
echo " ${ORANGE}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^${NC}"
echo " ${GREEN}Current registration.json file for installation${NC}"
echo " ${GREEN}Please Check if it looks OK${NC}"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "  "
echo "  "
echo "  "
echo "  "




# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INSTALL
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"
echo " ${ORANGE}Do you want to integrate CloudForms into Cluster '$CLUSTER_NAME' with the above configuration?${NC}"
echo ""
echo "---------------------------------------------------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------------------------------------------------"

read -p "Install? [y,N]" DO_COMM
if [[ $DO_COMM == "y" ||  $DO_COMM == "Y" ]]; then


        echo " ${GREEN}Login to MCM Cluster${NC}"  
          LOGIN_OK=$(cloudctl login -a ${MCM_SERVER} --skip-ssl-validation -u ${MCM_USER} -p ${MCM_PWD} -n kube-system)
          if [[ $LOGIN_OK =~ "Error response from server" ]];
          then
            echo "    ${RED}ERROR${NC}: Could not login to MCM Hub on Cluster '$CLUSTER_NAME'. Aborting."
            exit 2
          else
            #cloudctl iam oauth-client-register -f registration.json
            echo "    ${GREEN}  OK${NC}"
            echo "  "
          fi

        echo " ${GREEN}Register OAUTH Client${NC}"
          cloudctl iam oauth-client-delete $CLIENT_ID
          cloudctl iam oauth-client-register -f $INSTALL_PATH/registration.json
        echo " ${GREEN}    OK${NC}"


        echo " ${GREEN}Get Cluster CA cert${NC}"
          kubectl get secret -n kube-public ibmcloud-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode | sed 's/CERTIFICATE/TRUSTED CERTIFICATE/' > $INSTALL_PATH/ibm-mcm-ca.crt
        echo " ${GREEN}    OK${NC}"

        echo " ${GREEN}Upload files to CF Instance${NC}"
        echo " ${ORANGE}   Enter your admin password for the CF Server if asked for${NC}"
          scp $INSTALL_PATH/ibm-mcm-ca.crt $INSTALL_PATH/manageiq-external-auth-openidc.conf $SCRIPT_PATH/tools/cloudforms/register_host.sh root@$CF_IP:/root
        echo " ${GREEN}    OK${NC}"


        echo " ${GREEN}Register on CF Instance${NC}"
        echo " ${ORANGE}   Enter your admin password for the CF Server if asked for${NC}"
          ssh root@$CF_IP /root/register_host.sh
        echo " ${GREEN}    OK${NC}"

        echo " ${GREEN}Adapt MCM navigation menu${NC}"
          $SCRIPT_PATH/tools/navigation/automation-navigation-updates.sh -c https://$CF_IP
        echo " ${GREEN}    OK${NC}"

    echo ""
    echo ""
    echo ""
    echo ""
    echo ""
    echo ""

else
    echo "${RED}Installation Aborted${NC}"
fi



echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN} CloudForms Integration.... DONE${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"


