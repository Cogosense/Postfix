at := @
TAG := $(shell which git > /dev/null && git describe --match '[0-9]*\.[0-9]*\.[0-9]*' || echo unknown)
REGISTRY = 053262612181.dkr.ecr.us-west-2.amazonaws.com
IMAGE = $(REGISTRY)/postfix
STAGE ?= dev

all : build
full : build-no-cache

build :
	$(at)docker build --pull -t $(IMAGE):$(STAGE) src

build-no-cache :
	$(at)docker build --pull --no-cache -t $(IMAGE):$(STAGE) src

tag : build
	$(at)if [ x"$(TAG)" != xunknown ] ; then \
		docker tag $(IMAGE):$(STAGE) $(IMAGE):$(TAG) ; \
	fi

push : tag
	$(at)if [ x"$(TAG)" != xunknown ] ; then \
		if which -s aws ; then \
			eval $$(aws ecr get-login --no-include-email --region us-west-2) ; \
			docker push $(IMAGE):$(STAGE) ; \
			docker push $(IMAGE):$(TAG) ; \
		else \
			echo "AWS CLI must be installed to push images to AWS ECR". ; \
			echo "https://aws.amazon.com/cli" ; \
		fi ; \
	fi

devprd opsqa opsprd :
	$(MAKE) STAGE=$@ build push

