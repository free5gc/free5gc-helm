NFs = amf ausf nrf nssf pcf smf udm udr n3iwf upf
PREFIX = towards5gs/free5gc
TAG = 3.3.0

all: $(NFs) webui

$(NFs):
	docker build -t $(PREFIX)-$@:$(TAG) --build-arg NF=$@ --build-arg FREE5GC_VER=v$(TAG) . --no-cache

webui:
	docker build -t $(PREFIX)-webui:$(TAG) -f ./free5gc-webui/Dockerfile .

clean:
	for NF in $(NFs); do \
		docker rmi $$(docker images | grep $(PREFIX)-$(NF) | awk '{print $1}') ; \
	done

