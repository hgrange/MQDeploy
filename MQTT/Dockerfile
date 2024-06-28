FROM icr.io/ibm-messaging/mq:9.4.0.0-r1

COPY --chown=1001:0 MQSeriesXRService-9.4.0-0.x86_64.rpm /tmp/
RUN rpm -i /tmp/MQSeriesXRService-9.4.0-0.x86_64.rpm --nodeps && rm /tmp/MQSeriesXRService-9.4.0-0.x86_64.rpm
