#!/bin/bash
#
# Copyright justtry.com Corp. All Rights Reserved.
#

echo
echo " ____    _____      _      ____    _____  "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _| "
echo "\___ \    | |     / _ \   | |_) |   | |   "
echo " ___) |   | |    / ___ \  |  _ <    | |   "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|   "
echo

CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="justtry"}
: ${TIMEOUT:="60"}
COUNTER=1
MAX_RETRY=5
#Not TLS
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/justtry.com/orderers/orderer.justtry.com/msp/cacerts/ca.justtry.com-cert.pem
# TLS
#ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/justtry.com/orderers/orderer.justtry.com/msp/tlscacerts/tlsca.justtry.com-cert.pem

echo "Channel name : "$CHANNEL_NAME

verifyResult () {
        if [ $1 -ne 0 ] ; then
                echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
                echo
                exit 1
        fi
}

setGlobals () {

        if [ $1 -eq 0 -o $1 -eq 1 ] ; then
                CORE_PEER_LOCALMSPID="Org1MSP"
                CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.justtry.com/peers/peer0.org1.justtry.com/tls/ca.crt
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.justtry.com/users/Admin@org1.justtry.com/msp
                if [ $1 -eq 0 ]; then
                        CORE_PEER_ADDRESS=peer0.org1.justtry.com:7051
                else
                        CORE_PEER_ADDRESS=peer91.org1.justtry.com:7051
                        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.justtry.com/users/Admin@org1.justtry.com/msp
                fi
        else
                CORE_PEER_LOCALMSPID="Org2MSP"
                CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.justtry.com/peers/peer0.org2.justtry.com/tls/ca.crt
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.justtry.com/users/Admin@org2.justtry.com/msp
                if [ $1 -eq 2 ]; then
                        CORE_PEER_ADDRESS=peer0.org2.justtry.com:7051
                else
                        CORE_PEER_ADDRESS=peer1.org2.justtry.com:7051
                fi
        fi

        env |grep CORE
}

createChannel() {
        setGlobals 0

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
        		peer channel create -o orderer.justtry.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
                #peer channel create -o orderer.justtry.com:7050 -c $CHANNEL_NAME -b ./channel-artifacts/genesis.block -f ./channel-artifacts/channel.tx >&log.txt
        else
                peer channel create -o orderer.justtry.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
        fi
        res=$?
        cat log.txt
        verifyResult $res "Channel creation failed"
        echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
        echo
}

updateAnchorPeers() {
        PEER=$1
        setGlobals $PEER

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                peer channel update -o orderer.justtry.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx >&log.txt
        else
                peer channel update -o orderer.justtry.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
        fi
        res=$?
        cat log.txt
        verifyResult $res "Anchor peer update failed"
        echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
        echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
        peer channel join -b $CHANNEL_NAME.block  >&log.txt
        #peer channel join -b ./channel-artifacts/genesis.block  >&log.txt
        res=$?
        cat log.txt
        if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
                COUNTER=` expr $COUNTER + 1`
                echo "PEER$1 failed to join the channel, Retry after 2 seconds"
                sleep 2
                joinWithRetry $1
        else
                COUNTER=1
        fi
        verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
        for ch in 1; do
                setGlobals $ch
                joinWithRetry $ch
                echo "===================== PEER$ch joined on the channel \"$CHANNEL_NAME\" ===================== "
                sleep 2
                echo
        done
}

installChaincode () {
        PEER=$1
        setGlobals $PEER
        peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >&log.txt
        res=$?
        cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
        echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
        echo
}

instantiateChaincode () {
        PEER=$1
        setGlobals $PEER
        # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
        # lets supply it directly as we know it using the "-o" option
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                peer chaincode instantiate -o orderer.justtry.com:7050 -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR        ('Org1MSP.member','Org2MSP.member')" >&log.txt
        else
                peer chaincode instantiate -o orderer.justtry.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR      ('Org1MSP.member','Org2MSP.member')" >&log.txt
        fi
        res=$?
        cat log.txt
        verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
        echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
        echo
}

installChaincodeQbcc () {
        PEER=$1
        setGlobals $PEER
        peer chaincode install -n qbcc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/qbcc >&log.txt
        res=$?
        cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
        echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
        echo
}

instantiateChaincodeQbcc () {
        PEER=$1
        setGlobals $PEER
        # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
        # lets supply it directly as we know it using the "-o" option
        echo "CORE_PEER_TLS_ENABLED="$CORE_PEER_TLS_ENABLED
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                peer chaincode instantiate -o orderer.justtry.com:7050 -C $CHANNEL_NAME -n qbcc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR        ('Org1MSP.member','Org2MSP.member')" >&log.txt
        else
                peer chaincode instantiate -o orderer.justtry.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n qbcc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR      ('Org1MSP.member','Org2MSP.member')" >&log.txt
        fi
        res=$?
        cat log.txt
        verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
        echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
        echo
}

chaincodeQuery () {
  PEER=$1
  echo "===================== Querying on PEER$PEER on channel '$CHANNEL_NAME'... ===================== "
  setGlobals $PEER
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while test "$(($(date +%s)-starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
     sleep 3
     echo "Attempting to Query PEER$PEER ...$(($(date +%s)-starttime)) secs"
     peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >&log.txt
     test $? -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
     test "$VALUE" = "$2" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0 ; then
        echo "===================== Query on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
  else
        echo "!!!!!!!!!!!!!!! Query result on PEER$PEER is INVALID !!!!!!!!!!!!!!!!"
        echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
        echo
        exit 1
  fi
}

chaincodeInvoke () {
        PEER=$1
        setGlobals $PEER
        # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
        # lets supply it directly as we know it using the "-o" option
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                peer chaincode invoke -o orderer.justtry.com:7050 -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
        else
                peer chaincode invoke -o orderer.justtry.com:7050  --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >&log.txt
        fi
        res=$?
        cat log.txt
        verifyResult $res "Invoke execution on PEER$PEER failed "
        echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
        echo
}

## Create channel
#echo "Creating channel..."
#createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
#echo "Updating anchor peers for org1..."
#updateAnchorPeers 0
#echo "Updating anchor peers for org2..."
#updateAnchorPeers 2

#echo "Install chaincode qbcc on org0/peer1..."
#installChaincodeQbcc 0
echo "Install chaincode qbcc on org0/peer91..."
installChaincodeQbcc 1
#echo "Install chaincode qbcc on org2/peer2..."
#installChaincodeQbcc 2

#echo "Instantiating chaincode qbcc on org0/peer1..."
#instantiateChaincodeQbcc 0
echo "Instantiating chaincode qbcc on org0/peer91..."
instantiateChaincodeQbcc 1
# echo "Instantiating chaincode qbcc on org2/peer2..."
# instantiateChaincodeQbcc 2

#Query on chaincode on Peer3/Org2, check if the result is 90
# echo "Querying chaincode on org2/peer3..."
# chaincodeQuery 3 90

echo
echo "===================== All GOOD, execution completed ===================== "
echo

exit 0
