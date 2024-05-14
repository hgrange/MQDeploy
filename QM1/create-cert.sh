oc project NAMESPACE
# Create a private key to use for your internal certificate authority
mkdir -p MQ/tls
openssl genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 -out MQ/tls/ca.key

# Issue a self-signed certificate for your internal certificate authority
openssl req -x509 -new -nodes -key MQ/tls/ca.key -sha512 -days 397 -subj "/CN=selfsigned-ca" -out MQ/tls/ca.crt

# Create a private key and certificate signing request for a queue manager
openssl req -new -nodes -out MQ/tls/qm1.csr -newkey rsa:4096 -keyout MQ/tls/qm1.key -subj '/CN=qm1-ibm-mq-qm-cp4i.apps.66276a8f7e0fed001ed97497.cloud.techzone.ibm.com'

# Sign the queue manager key with your internal certificate authority
openssl x509 -req -in MQ/tls/qm1.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/qm1.crt -days 396 -sha512

# Create a Kubernetes secret with the queue manager key and certificate
oc delete secret mq-qm1-tls
oc create secret generic qm1-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/qm1.key --from-file=tls.crt=MQ/tls/qm1.crt --from-file=ca.crt=MQ/tls/ca.crt 

#Create a private key and certificate signing request for an application
openssl req -new -nodes -out MQ/tls/app1.csr -newkey rsa:4096 -keyout MQ/tls/app1.key -subj '/CN=app1'
openssl req -new -nodes -out MQ/tls/mqm.csr -newkey rsa:4096 -keyout MQ/tls/mqm.key -subj '/CN=mqm'

#create the application certificate with your internal certificate authority
openssl x509 -req -in MQ/tls/app1.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/app1.crt -days 396 -sha512
openssl x509 -req -in MQ/tls/mqm.csr -CA MQ/tls/ca.crt -CAkey MQ/tls/ca.key -CAcreateserial -out MQ/tls/mqm.crt -days 396 -sha512

openssl pkcs12 -export -in "MQ/tls/app1.crt" -name "ibmwebspheremqqm1" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/app1.key" -out "MQ/tls/app1.p12" -passout pass:password
openssl pkcs12 -export -in "MQ/tls/mqm.crt" -name "ibmwebspheremqqm1" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/mqm.key" -out "MQ/tls/mqm.p12" -passout pass:password
openssl pkcs12 -export -in "MQ/tls/qm1.crt" -name "ibmwebspheremqqm1" -certfile "MQ/tls/ca.crt" -inkey "MQ/tls/qm1.key" -out "MQ/tls/qm1.p12" -passout pass:password
oc delete secret qm1-app1-tls
oc create secret generic qm1-app1-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/app1.key --from-file=tls.crt=MQ/tls/app1.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/app1.p12 --from-literal password=password
oc delete queuemanager qm1
oc delete secret qm1-mqm-tls
oc create secret generic qm1-mqm-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/mqm.key --from-file=tls.crt=MQ/tls/mqm.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/mqm.p12 --from-literal password=password
oc delete secret qm1-tls
oc create secret generic qm1-tls -n NAMESPACE --type="kubernetes.io/tls" --from-file=tls.key=MQ/tls/qm1.key --from-file=tls.crt=MQ/tls/qm1.crt --from-file=ca.crt=MQ/tls/ca.crt --from-file=tls.p12=MQ/tls/qm1.p12 --from-literal password=password
