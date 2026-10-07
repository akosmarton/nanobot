FROM docker.io/library/python:3.14-alpine

RUN pip install --no-cache-dir nanobot-ai==0.3.5

VOLUME ["/root/.nanobot"]

RUN nanobot onboard

CMD ["nanobot", "gateway"]
