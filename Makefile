.PHONY:  tests prepare clean all push ecr lambda-test lambda-deploy

user?=${USER}
profile?=default

debian?=buster
version?=3.9-slim
arch?=amd64

HANDLER?=main.lambda_handler
FUNCTION_DIR?="/function"

NAME:=$(shell basename $$(dirname "$$(pwd)"../) | tr '[:upper:]' '[:lower:]')
IMAGE:=python:$(version)-$(debian)
TAG=$(shell cat ../.tag | head -n1 | tr -d "\n")

AWS_ACCOUNT:=$$(cat ~/.aws/config |grep "\[ *profile *"$(profile)" *\]" -A 3|grep "role_arn *= *arn:aws:iam:"|cut -d ":" -f5)
AWS_REGION_PROFILE:=$$(cat ~/.aws/config |grep "\[ *profile *"$(profile)" *\]" -A 5|grep "region *="|tr -d " "|cut -d "=" -f2)
AWS_REGION_DEFAULT:=$$(cat ~/.aws/config |grep "region *="|tr -d " "|cut -d "=" -f2|head -n 1)
AWS_REGION:=$$(echo $(AWS_REGION_PROFILE)\\n$(AWS_REGION_DEFAULT)\\n"eu-west-3"|grep -v "^$$"|head -n 1)


tests: prepare ../venv
	cd ../tests && . ../venv/bin/activate && export PYTHONPATH="../:." && \
		coverage run --omit test_*,*/site-packages/* -m unittest test_main.py && \
		coverage html -d ./coverage

../venv:
	cd .. && python3 -m venv venv
	cp ../tests/requirements.txt ../venv/requirements-tests.txt ; cp ../requirements.txt ../venv/
	. ../venv/bin/activate && export PIP_DISABLE_PIP_VERSION_CHECK=1 && \
		pip3 install pip --upgrade && \
		pip3 install -r tests/requirements.txt && \
		pip3 install -r ../venv/requirements.txt && \
		pip3 install -r ../venv/requirements-tests.txt

prepare:
	# main.py (lambda)
	if [ ! -f ../main.py ] ; then \
  		echo "def lambda_handler(event, context):\n    return {'result': str(event)}" >> ../main.py ; fi
  	# requirements
	touch ../requirements.txt && chmod 644 ../requirements.txt
	# test_main.py
	if [ ! -f ../tests/test_main.py ] ; then cp tests/test_main.py ../tests/test_main.py ; fi
	# tests requirements
	mkdir -p ../tests && touch ../tests/requirements.txt
	mkdir -p ../venv && touch ../venv/requirements.txt
	# need reset ?
	if ! diff ../requirements.txt ../venv/requirements.txt > /dev/null ; then rm -Rf ../venv ; true ; fi
	if ! diff ../tests/requirements.txt ../venv/requirements-tests.txt > /dev/null ; then rm -Rf ../venv ; true ; fi
	cd .. && touch hash && HASH=$$(find . -name "*.py" -not -path "./venv/*" -exec bash -c "FILE={} && \
		echo COPY {} $(FUNCTION_DIR)\$${FILE:1} > .tmp_files ; cat {} | md5" \; | md5) && echo "$$HASH" > .tmp_hash
	if ! diff ../hash ../.tmp_hash > /dev/null ; then rm ../Dockerfile ; rm ../venv.tgz ; true ; fi

clean:
	rm ../Dockerfile ../venv/requirements.txt ../.tmp_* 2> /dev/null ; true

all: tests ../Dockerfile lambda-test

../Dockerfile:
	# docker pre
	echo 'ARG FUNCTION_DIR=$(FUNCTION_DIR)' >  ../Dockerfile
	echo "FROM $(IMAGE) as build-image" >> ../Dockerfile
	cat ./docker/lambda/pre/Dockerfile >> ../Dockerfile
	cat ../.tmp_files >> ../Dockerfile
	# docker post
	echo "FROM $(IMAGE)" >> ../Dockerfile
	cat ./docker/lambda/post/Dockerfile >> ../Dockerfile
	if [ -f "../apt.txt" ] ; then \
		echo "RUN apt-get update && apt-get install -yq $$(cat ../apt.txt)" >> ../Dockerfile ; fi
	echo "CMD [ \"$(HANDLER)\" ]" >> ../Dockerfile
	# docker build
	cd .. && docker build --platform linux/$(arch) -t $(NAME) .
	# docker tag
	NEW_TAG=$$(cd .. && git update-index --refresh > /dev/null ; \
		if [ "$$?" == "0" ] ; then git show -s --format=%h ; else date +%s ; fi) ; \
		echo "$$NEW_TAG" > ../.tag ; \
		docker tag $(NAME):latest $(NAME):$$NEW_TAG
	# hash
	cp ../.tmp_hash ../hash
	rm ../.tmp_hash && rm ../.tmp_files
	# cleanup
	docker rmi -f $$(docker images -f "dangling=true" -q) 2>/dev/null ; true

../venv.tgz:
	cd .. && docker run --rm -i -t -v $$(pwd):/var/task --entrypoint /bin/bash $(NAME) -c \
		"cd $(FUNCTION_DIR) && tar -czf /var/task/venv.tgz * && chmod 666 /var/task/venv.tgz"

push:
	docker login
	docker tag $(NAME):$(TAG) $(user)/$(NAME):$(TAG)
	docker image push $(user)/$(NAME):$(TAG)

~/.aws-lambda-rie:
	mkdir -p ~/.aws-lambda-rie

~/.aws-lambda-rie/aws-lambda-rie-amd64: ~/.aws-lambda-rie
	curl -Lo ~/.aws-lambda-rie/aws-lambda-rie-amd64 https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie
	chmod +x ~/.aws-lambda-rie/aws-lambda-rie-amd64

~/.aws-lambda-rie/aws-lambda-rie-arm64: ~/.aws-lambda-rie
	curl -Lo ~/.aws-lambda-rie/aws-lambda-rie-arm64 https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64
	chmod +x ~/.aws-lambda-rie/aws-lambda-rie-arm64

ecr:
	aws ecr get-login-password --profile $(profile) --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
	docker tag $(NAME):$(TAG) ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/$(NAME):$(TAG)
	docker push ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/$(NAME):$(TAG)

lambda-test: ~/.aws-lambda-rie/aws-lambda-rie-$(arch)
	docker stop $(NAME) ; sleep 3
	docker run --rm -d -v ~/.aws-lambda-rie:/aws-lambda -p 9000:8080 \
		--entrypoint /aws-lambda/aws-lambda-rie-$(arch) --name $(NAME) $(NAME):latest \
		/usr/local/bin/python -m awslambdaric $(HANDLER)
	sleep 3
	echo -e "\n\n----------------------------------------------------------------------\nLambda test\n" ; \
		if [ -f ../event.txt ] ; then EVENT=$$(cat ../event.txt) ; else EVENT='{}' ; fi && \
		curl -XPOST "http://127.0.0.1:9000/2015-03-31/functions/function/invocations" -d "$$EVENT" && \
		echo "\n"
	docker stop $(NAME)

lambda-deploy: ecr
	aws lambda update-function-code --profile $(profile) --region ${AWS_REGION} --function-name $(NAME) --image-uri ${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/$(NAME):$(TAG)
