#!/bin/bash +x
#
# Copyright justtry.com Corp. All Rights Reserved.
#


#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="justtry"}
echo $CHANNEL_NAME

export CHAIN_ROOT=/apps/justtry
export CHAIN_BIN=$CHAIN_ROOT/bin
export CHAIN_CONFIG=$CHAIN_ROOT/config
export FABRIC_CFG_PATH=$CHAIN_CONFIG
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')

## Using docker-compose template replace private key file names with constants
function replacePrivateKey () {
        ARCH=`uname -s | grep Darwin`
        if [ "$ARCH" == "Darwin" ]; then
                OPTS="-it"
        else
                OPTS="-i"
        fi

        cp docker-compose-e2e-template.yaml docker-compose-e2e.yaml

        CURRENT_DIR=$PWD
        cd crypto-config/peerOrganizations/org1.justtry.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
        cd crypto-config/peerOrganizations/org2.justtry.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
}

## Generates Org certs using cryptogen tool
function generateCerts (){
		CRYPTOGEN=$CHAIN_BIN/cryptogen
		
        if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
        fi

        echo
        echo "##########################################################"
        echo "##### Generate certificates using cryptogen tool #########"
        echo "##########################################################"
        # crypto-config Ŀ¼�����û���ǰĿ¼�´�����Ϊ��ʹ�䴴����ָ��Ŀ¼��ʹ��cd ��ת��Ȼ���ڻص��û�ִ�е�Ŀ¼
        workPath=$PWD
        cd $CHAIN_CONFIG
        $CRYPTOGEN generate --config=$CHAIN_CONFIG/crypto-config.yaml
        cd $workPath
        echo
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {
        CONFIGTXGEN=$CHAIN_BIN/configtxgen
        
        if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
        fi
        
        mkdir $CHAIN_CONFIG/channel-artifacts/

        echo "##########################################################"
        echo "#########  Generating Orderer Genesis block ##############"
        echo "##########################################################"
        # Note: For some unknown reason (at least for now) the block file can't be
        # named orderer.genesis.block or the orderer will fail to launch!
        $CONFIGTXGEN -profile TwoOrgsOrdererGenesis -outputBlock $CHAIN_CONFIG/channel-artifacts/genesis.block

        echo
        echo "#################################################################"
        echo "### Generating channel configuration transaction 'channel.tx' ###"
        echo "#################################################################"
        $CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx $CHAIN_CONFIG/channel-artifacts/channel.tx -channelID $CHANNEL_NAME

        echo
        echo "#################################################################"
        echo "#######    Generating anchor peer update for Org1MSP   ##########"
        echo "#################################################################"
        $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate $CHAIN_CONFIG/channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

        echo
        echo "#################################################################"
        echo "#######    Generating anchor peer update for Org2MSP   ##########"
        echo "#################################################################"
        $CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate $CHAIN_CONFIG/channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
        echo
}

generateCerts
# replacePrivateKey
generateChannelArtifacts
