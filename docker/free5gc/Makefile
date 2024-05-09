NFs = amf ausf chf nrf nssf pcf smf udm udr n3iwf upf chf udsf
PREFIX = towards5gs/free5gc
TAG = 3.3.0

base:
	docker build -t $(PREFIX)-base:$(TAG) ./free5gc-base --no-cache

nfs:
	for NF in $(NFs) ; do \
		docker build -t $(PREFIX)-$$NF:$(TAG) ./free5gc-$$NF --no-cache ; \
	done
webui:
	docker build -t $(PREFIX)-webui:$(TAG) ./free5gc-webui

clean:
	docker rmi $$(docker images | grep $(PREFIX) | awk '{print $3}')

