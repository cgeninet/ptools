
# begin post

ARG FUNCTION_DIR
WORKDIR ${FUNCTION_DIR}
ENV LAMBDA_TASK_ROOT=${FUNCTION_DIR}

COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
RUN chown root:root -R ${FUNCTION_DIR}
RUN cd ${FUNCTION_DIR} && chmod -R a+r * && chmod a+X * && chmod -R a+x **/*.py

ENTRYPOINT ["/usr/local/bin/python", "-m", "awslambdaric"]

# end post
