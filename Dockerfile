FROM amd64/dart:3.5.2

ADD . /opt/

WORKDIR /opt

RUN dart --verbose pub get

RUN chmod +x *.sh

CMD dart bin/main.dart

