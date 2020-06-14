at := @
TAG := $(shell which git > /dev/null && git describe --match 'v[0-9]*\.[0-9]*\.[0-9]*' || echo unknown)
REGISTRY = 053262612181.dkr.ecr.us-west-2.amazonaws.com
IMAGE = $(REGISTRY)/postfix
STAGE ?= dev
AWSCLI_VERSION:=$(shell brew list --versions awscli | awk '{ gsub(/\..*/,"",$$2) ; print $$2 }')

all : build
full : build-no-cache

build : login$(AWSCLI_VERSION)
	$(at)docker build --pull -t $(IMAGE):$(STAGE) src

build-no-cache : login$(AWSCLI_VERSION)
	$(at)docker build --pull --no-cache -t $(IMAGE):$(STAGE) src

login :
	echo "AWS CLI must be installed to push images to AWS ECR". ; \
	echo "https://aws.amazon.com/cli" ; \
	exit 1

login1 :
	@echo Running AWS cli ECR login version 1
	eval $$(aws ecr get-login --no-include-email --region us-west-2) ; \

login2 :
	@echo Running AWS cli ECR login version 2
	aws ecr get-login-password \
    | docker login \
        --password-stdin \
        --username AWS \
		https://$(REGISTRY)

tag : build
	$(at)if [ x"$(TAG)" != xunknown ] ; then \
		docker tag $(IMAGE):$(STAGE) $(IMAGE):$(TAG) ; \
	fi

push : tag
	$(at)if [ x"$(TAG)" != xunknown ] ; then \
		docker push $(IMAGE):$(STAGE) ; \
		docker push $(IMAGE):$(TAG) ; \
	fi

devprd opsqa opsprd :
	$(MAKE) STAGE=$@ build push

