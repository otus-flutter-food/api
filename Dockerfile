FROM amd64/dart:latest

ADD . /opt/

WORKDIR /opt

RUN dart --verbose --dual_map_code=false pub get

RUN chmod +x *.sh

CMD dart bin/main.dart

