# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Install Script for CP4MCM
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
echo " ${CYAN}${rocket} Cloud Pak for Multicloud Management${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "  "
echo " ${CYAN} Install MultiCloud Manager (MCM) for OpenShift 4.3 on IBM Cloud${NC}"
echo "  "
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

        while getopts "t:d:h:p:s:" opt
        do
          case "$opt" in
              t ) INPUT_TOKEN="$OPTARG" ;;
              d ) INPUT_PATH="$OPTARG" ;;
              h ) INPUT_CLUSTER_NAME="$OPTARG" ;;
              p ) INPUT_PWD="$OPTARG" ;;
              s ) INPUT_SC="$OPTARG" ;;
          esac
        done



        if [[ $INPUT_TOKEN == "" ]];
        then
        echo "       ${RED}ERROR${NC}: Please provide the Registry Token"
        echo "       USAGE: $0 -t <REGISTRY_TOKEN> [-h <CLUSTER_NAME>] [-p <MCM_PASSWORD>] [-d <TEMP_DIRECTORY>] [-s <STORAGE_CLASS_BLOCK>]"
        exit 1
        else
          echo "       ${GREEN}Token OK:${NC}                           $INPUT_TOKEN"
          ENTITLED_REGISTRY_KEY=$INPUT_TOKEN
        fi


        if [[ $INPUT_PWD == "" ]];          
        then
          echo "       ${ORANGE}No Password provided, using${NC}         $MCM_PWD"
        else
          echo "       ${GREEN}Password OK:${NC}                        ********"
          MCM_PWD=$INPUT_PWD
        fi



        if [[ $INPUT_PATH == "" ]];
        then
          echo "       ${ORANGE}No Path provided, using${NC}             $TEMP_PATH"
        else
          echo "       ${GREEN}Path OK:${NC}                            $INPUT_PATH"
          TEMP_PATH=$INPUT_PATH
        fi



        if [[ $INPUT_SC == "" ]];
        then
          echo "       ${ORANGE}No Storage Class provided, using${NC}    $STORAGE_CLASS_BLOCK"
        else
          echo "       ${GREEN}Storage Class OK:${NC}                   $INPUT_SC"
          STORAGE_CLASS_BLOCK=$INPUT_SC
        fi


        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          echo "       ${ORANGE}No Cluster Name provided${NC}            ${NC}will be determined from Kubeconfig${NC}"
        else
          echo "       ${GREEN}Cluster OK:${NC}                           $INPUT_CLUSTER_NAME"
          CLUSTER_NAME=$INPUT_CLUSTER_NAME
        fi


        if [[ ($INPUT_CLUSTER_NAME == "") ]];
        then
          getClusterFQDN
        fi


        if [[ ($MASTER_HOST == "0.0.0.0") ]];
        then
        getHosts
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

        assignHosts
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "





# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# CONFIG SUMMARY
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
echo "${GREEN}***************************************************************************************************************************${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}${healthy} MultiCloud Manager (MCM) will be installed in Cluster ${ORANGE}'$CLUSTER_NAME'${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo " ${CYAN} ${magnifying} Your configuration${NC}"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}CLUSTER :${NC}               $CLUSTER_NAME"
echo "    ${GREEN}REGISTRY TOKEN:${NC}         $ENTITLED_REGISTRY_KEY"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}MCM User Name:${NC}          $MCM_USER"
echo "    ${GREEN}MCM User Password:${NC}      ********"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}STORAGE CLASS:${NC}          $STORAGE_CLASS_BLOCK"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}MASTER COMPONENTS:${NC}      $MASTER_COMPONENTS"
echo "    ${GREEN}PROXY COMPONENTS:${NC}       $PROXY_COMPONENTS"
echo "    ${GREEN}MANAGEMENT COMPONENTS:${NC}  $MANAGEMENT_COMPONENTS"
echo "    ---------------------------------------------------------------------------------------------------------------------"
echo "    ${GREEN}INSTALL PATH:${NC}           $INSTALL_PATH"
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
echo " ${PURPLE}${wrench} Getting MCM Inception Container${NC} - ${ORANGE}This may take some time${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"

        docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY"

        DOCKER_PULL=$(docker pull $ENTITLED_REGISTRY/cp/icp-foundation/mcm-inception:$MCM_VERSION 2>&1)
        #echo $DOCKER_PULL

        if [[ $DOCKER_PULL =~ "pull access denied" ]];
        then
          echo "${RED}ERROR${NC}: Not entitled for Registry or not reachable"
          echo "${RED}${cross}  Installation Aborted${NC}"
          exit 1
        fi
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "



echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${wrench} Running Prerequisites${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"


        echo " ${wrench} Create Config Directory"
          rm -r $INSTALL_PATH/* 
          mkdir -p $INSTALL_PATH 
          cd $INSTALL_PATH
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        

        echo " ${wrench} Patching Route"
          oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}' 2>&1
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        
        echo " ${wrench} Create Secret for Registry"
          #docker login "$ENTITLED_REGISTRY" -u "$ENTITLED_REGISTRY_USER" -p "$ENTITLED_REGISTRY_KEY"
          oc create secret docker-registry entitled-registry --docker-server=$ENTITLED_REGISTRY --docker-username=$ENTITLED_REGISTRY_USER --docker-password=$ENTITLED_REGISTRY_KEY --docker-email=nikh@ch.ibm.com
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        
        echo " ${wrench} Creating config file"
          docker run --rm -v $(pwd):/data:z -e LICENSE=accept --security-opt label:disable $ENTITLED_REGISTRY/cp/icp-foundation/mcm-inception:$MCM_VERSION cp -r cluster /data
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        

        echo " ${wrench} Copy kubeconfig"
          oc config view > $INSTALL_PATH/cluster/kubeconfig
        echo "    ${GREEN}  OK${NC}"
        echo "  "
        
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "





echo "${CYAN}***************************************************************************************************************************${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${PURPLE}${telescope} Adapt config file${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"


        cd $INSTALL_PATH

        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Backup vanilla config
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        cp cluster/config.yaml cluster/config.yaml.vanilla


        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        # Adapt Config FIle
        # ---------------------------------------------------------------------------------------------------------------------------------------------------"
        ${SED} -i "s/<your-openshift-dedicated-node-to-deploy-master-components>/$MASTER_COMPONENTS/" cluster/config.yaml
        ${SED} -i "s/<your-openshift-dedicated-node-to-deploy-proxy-components>/$PROXY_COMPONENTS/" cluster/config.yaml
        ${SED} -i "s/<your-openshift-dedicated-node-to-deploy-management-components>/$MANAGEMENT_COMPONENTS/" cluster/config.yaml

        ${SED} -i "s/<storage class available in OpenShift>/$STORAGE_CLASS_BLOCK/" cluster/config.yaml

        ${SED} -i "s/notary: disabled/notary: enabled/" cluster/config.yaml
        ${SED} -i "s/cis-controller: disabled/cis-controller: enabled/" cluster/config.yaml
        ${SED} -i "s/mutation-advisor: disabled/mutation-advisor: enabled/" cluster/config.yaml

        echo "image_repo: $ENTITLED_REGISTRY/cp/icp-foundation"  >> cluster/config.yaml
        echo "private_registry_enabled: true"  >> cluster/config.yaml
        echo "docker_username: ekey"  >> cluster/config.yaml
        echo "docker_password: $ENTITLED_REGISTRY_KEY"  >> cluster/config.yaml

        echo "default_admin_password: $MCM_PWD" >> cluster/config.yaml
        echo "password_rules:" >> cluster/config.yaml
        echo "- '(.*)'" >> cluster/config.yaml

        echo "helm_timeout: 1800" >> cluster/config.yaml


        if [[ $CLUSTER_NAME =~ "appdomain.cloud" ]];
        then
          echo " ${GREEN}Adapt config file for ROKS on IBM Cloud${NC}"
          ${SED} -i "s/roks_enabled: false/roks_enabled: true/" cluster/config.yaml
          ${SED} -i "s/<roks_url>/$CLUSTER_NAME/" cluster/config.yaml
        fi
        echo " ${GREEN}OK${NC}"
echo "${CYAN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${CYAN}***************************************************************************************************************************${NC}"
echo "  "
echo "  "
echo "  "
echo "  "
echo "  "
echo "  "
echo "  "
echo "  "


echo "${GREEN}***************************************************************************************************************************{NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}Current config file for installation${NC}"
echo " ${GREEN}Please Check if it looks OK${NC}"
echo " ${ORANGE}vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv${NC}"
echo "  "
        cat cluster/config.yaml
echo "  "
echo " ${ORANGE}^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^${NC}"
echo " ${GREEN}Current config file for installation${NC}"
echo " ${GREEN}Please Check if it looks OK${NC}"
echo "${GREEN}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************${NC}"
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
echo " ${RED} Installing MultiCloud Manager (MCM) into Cluster '$CLUSTER_NAME'${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${ORANGE}---------------------------------------------------------------------------------------------------------------------------${NC}"

        cd cluster 
        docker run -t --net=host -e LICENSE=accept -v $(pwd):/installer/cluster:z -v /var/run:/var/run:z -v /etc/docker:/etc/docker:z --security-opt label:disable $ENTITLED_REGISTRY/cp/icp-foundation/mcm-inception:$MCM_VERSION install-with-openshift
    
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo " ${GREEN}${healthy} MultiCloud Manager (MCM) Installation.... DONE${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}----------------------------------------------------------------------------------------------------------------------------------------------------${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"
echo "${GREEN}***************************************************************************************************************************************************${NC}"








