
oc project NAMESPACE
# Create a private key to use for your internal certificate authority
mkdir -p MQ/tls
openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 -out MQ/tls/ca.key

# Issue a self-signed certificate for your internal certificate authority
openssl req -x509 -new -nodes -key MQ/tls/ca.key -sha512 -days 397 -subj "/CN=selfsigned-ca" -out MQ/tls/ca.crt

# Create a private key and certificate signing request for a queue manager
openssl req -new -nodes -out MQ/tls/mqtt.csr -newkey rsa:4096 -keyout MQ/tls/mqtt.key -subj '/CN=mqtt' -addext "subjectAltName = DNS:registrymqtt-ibm-mq-qm-cp4i.apps.66276a8f7e0fed001ed97497.cloud.techzone.ibm.com"

# Sign the queue manager key with your internal certificate authority
openssl x509 -req -in MQ/tls/mqtt.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/mqtt.crt -days 396 -sha512

# Create a Kubernetes secret with the queue manager key and certificate
oc delete secret mq-mqtt-tls
oc create secret generic mqtt-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/mqtt.key --from-file=tls.crt=MQ/tls/mqtt.crt --from-file=ca.crt=MQ/tls/ca.crt 

#Create a private key and certificate signing request for an application
openssl req -new -nodes -out MQ/tls/app1.csr -newkey rsa:4096 -keyout MQ/tls/app1.key -subj '/CN=app1'
openssl req -new -nodes -out MQ/tls/mqm.csr -newkey rsa:4096 -keyout MQ/tls/mqm.key -subj '/CN=mqm'

#create the application certificate with your internal certificate authority
openssl x509 -req -in MQ/tls/app1.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/app1.crt -days 396 -sha512
openssl x509 -req -in MQ/tls/mqm.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/mqm.crt -days 396 -sha512

openssl pkcs12 -export -in "MQ/tls/app1.crt" -name "ibmwebspheremqmqtt" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/app1.key" -out "MQ/tls/app1.p12" -passout pass:password
openssl pkcs12 -export -in "MQ/tls/mqm.crt" -name "ibmwebspheremqmqtt" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/mqm.key" -out "MQ/tls/mqm.p12" -passout pass:password
openssl pkcs12 -export -in "MQ/tls/mqtt.crt" -name "ibmwebspheremqmqtt" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/mqtt.key" -out "MQ/tls/mqtt.p12" -passout pass:password
oc delete secret mqtt-app1-tls
oc create secret generic mqtt-app1-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/app1.key --from-file=tls.crt=MQ/tls/app1.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/app1.p12 --from-literal password=password
oc delete sts mqtt-ibm-mq
oc delete pvc data-mqtt-ibm-mq-0
oc delete secret mqtt-mqm-tls
oc create secret generic mqtt-mqm-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/mqm.key --from-file=tls.crt=MQ/tls/mqm.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/mqm.p12 --from-literal password=password
oc delete service mqtt-ibm-mq 
oc delete sa mqtt-ibm-mq
oc delete route mqtt-ibm-mq-qmtt mqtt-ibm-mq-web mqtt-ibm-mq-qm
oc delete image $(oc get image | grep mqtt | awk '{ print $1 }')

oc delete secret mqtt-tls
oc create secret generic mqtt-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/mqtt.key --from-file=tls.crt=MQ/tls/mqtt.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/mqtt.p12 --from-literal password=password
