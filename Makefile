at := @
TAG := $(shell which git > /dev/null && git describe --match '[0-9]*\.[0-9]*\.[0-9]*' || echo unknown)
REGISTRY = 053262612181.dkr.ecr.us-west-2.amazonaws.com
IMAGE = $(REGISTRY)/postfix
STAGE ?= dev

all : build tag
full : build-no-cache tag

build :
	$(at)docker build -t $(IMAGE) src

build-no-cache :
	$(at)docker build --no-cache -t $(IMAGE) src

tag : build
	$(at)if [ x"$(TAG)" != x ] ; then \
		docker tag $(IMAGE) $(IMAGE):$(TAG) ; \
		docker tag $(IMAGE) $(IMAGE):dev ; \
	fi

push : tag
	$(at)if [ x"$(TAG)" != xunknown ] ; then \
		if which -s aws ; then \
			eval $$(aws ecr get-login --no-include-email --region us-west-2) ; \
			docker push $(IMAGE):dev ; \
		else \
			echo "AWS CLI must be installed to push images to AWS ECR". ; \
			echo "https://aws.amazon.com/cli" ; \
		fi ; \
	fi

devprd opsqa opsprd : push
	docker tag $(IMAGE) $(IMAGE):$@
	docker push $(IMAGE):$@

