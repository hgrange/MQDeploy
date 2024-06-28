FROM icr.io/ibm-messaging/mq:9.4.0.0-r1
USER 0
COPY --chown=1001:0 mqtt.bin /tmp/
RUN rpm -i /tmp/mqtt.bin --nodeps && rm /tmp/mqtt.bin
