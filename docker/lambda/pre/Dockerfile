
# begin pre

RUN apt-get update -y && \
    apt-get install -y g++ make cmake unzip libcurl4-openssl-dev 2>&1 \
    | grep -v "debconf: delaying package configuration, since apt-utils is not installed"

ARG FUNCTION_DIR
RUN useradd -md  ${FUNCTION_DIR} function
WORKDIR ${FUNCTION_DIR}
USER function

RUN export PIP_DISABLE_PIP_VERSION_CHECK=1 && pip install pip --upgrade --no-warn-script-location
RUN pip install --target ${FUNCTION_DIR} awslambdaric

COPY requirements.txt ${FUNCTION_DIR}/requirements.txt
RUN pip3 install --target ${FUNCTION_DIR} -r ${FUNCTION_DIR}/requirements.txt
RUN rm ${FUNCTION_DIR}/requirements.txt && rm -Rf ${FUNCTION_DIR}/.local

USER root

# end pre

