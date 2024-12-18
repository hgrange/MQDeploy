oc project NAMESPACE
# Create a private key to use for your internal certificate authority
mkdir -p MQ/tls
openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 -out MQ/tls/ca.key

# Issue a self-signed certificate for your internal certificate authority
openssl req -x509 -new -nodes -key MQ/tls/ca.key -sha512 -days 397 -subj "/CN=selfsigned-ca" -out MQ/tls/ca.crt

# Create a private key and certificate signing request for a queue manager
domain=$(oc whoami --show-console | awk -F: '{ print $2 }' | sed 's|//console-openshift-console.||')
openssl req -new -nodes -out MQ/tls/qm1.csr -newkey rsa:4096 -keyout MQ/tls/qm1.key -subj "/CN=qm1-ibm-mq-qm-NAMESPACE.$domain" -addext "subjectAltName = DNS:qm1-ibm-mq-qm-NAMESPACE.$domain"
# Sign the queue manager key with your internal certificate authority
openssl x509 -req -in MQ/tls/qm1.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/qm1.crt -days 396 -sha512

#Create a private key and certificate signing request for an application
openssl req -new -nodes -out MQ/tls/app1.csr -newkey rsa:4096 -keyout MQ/tls/app1.key -subj '/CN=app1' -addext "subjectAltName = DNS:qm1-ibm-mq-qm-NAMESPACE.$domain"
openssl req -new -nodes -out MQ/tls/mqm.csr -newkey rsa:4096 -keyout MQ/tls/mqm.key -subj '/CN=mqm'    -addext "subjectAltName = DNS:qm1-ibm-mq-qm-NAMESPACE.$domain"

#create the application certificate with your internal certificate authority
openssl x509 -req -in MQ/tls/app1.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/app1.crt -days 396 -sha512
openssl x509 -req -in MQ/tls/mqm.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/mqm.crt -days 396 -sha512

openssl pkcs12 -export -in "MQ/tls/app1.crt" -name "app1" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/app1.key" -out "MQ/tls/app1.p12" -passout pass:password
openssl pkcs12 -export -in "MQ/tls/mqm.crt" -name "mqm" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/mqm.key" -out "MQ/tls/mqm.p12" -passout pass:password
openssl pkcs12 -export -in "MQ/tls/qm1.crt" -name "ibmwebspheremqqm1" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/qm1.key" -out "MQ/tls/qm1.p12" -passout pass:password

oc delete queuemanager qm1
oc delete sa qm1-ibm-mq
oc delete secret qm1-mqm-tls
oc delete secret qm1-tls
oc delete secret qm1-app1-tls
oc delete pvc data-qm1-ibm-mq-0 data-qm1-ibm-mq-1 data-qm1-ibm-mq-2
oc delete cm qm1-config

# Create a Kubernetes secret with the queue manager key and certificate

oc create secret generic qm1-app1-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/app1.key --from-file=tls.crt=MQ/tls/app1.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/app1.p12 --from-literal password=password

oc create secret generic qm1-mqm-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/mqm.key --from-file=tls.crt=MQ/tls/mqm.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/mqm.p12 --from-literal password=password

oc create secret generic qm1-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/qm1.key --from-file=tls.crt=MQ/tls/qm1.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/qm1.p12 --from-literal password=password
