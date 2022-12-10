FROM dart:2.18

ADD . /opt/

WORKDIR /opt

RUN dart pub get

RUN chmod +x *.sh

CMD dart bin/main.dart

