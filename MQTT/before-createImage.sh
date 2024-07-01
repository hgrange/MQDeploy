
oc project NAMESPACE

oc delete secret mqtt-app1-tls
oc delete queuemanager mqtt
oc delete secret mqtt-mqm-tls
oc delete service mqtt-ibm-mq 
oc delete sa mqtt-ibm-mq
oc delete route mqtt-ibm-mq-qmtt mqtt-ibm-mq-web mqtt-ibm-mq-qm
oc delete image $(oc get image | grep mqtt | awk '{ print $1 }')
oc delete secret mqtt-tls
