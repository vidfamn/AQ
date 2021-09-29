###############
### Builder ###
###############
FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04 AS builder

COPY . /src
WORKDIR /src

RUN mkdir libs
RUN tar -zxf ./debs/TensorRT-7.0.0.11.Ubuntu-18.04.x86_64-gnu.cuda-10.0.cudnn7.6.tar.gz -C ./libs
RUN rm -rf ./debs

ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/src/libs/TensorRT-7.0.0.11/lib"
ENV LIBRARY_PATH="$LIBRARY_PATH:/src/libs/TensorRT-7.0.0.11/lib/stubs"
ENV CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/src/libs/TensorRT-7.0.0.11/include"

RUN make

RUN apt update && apt install -y --no-install-recommends wget
RUN mkdir downloads
RUN wget -nv -P ./downloads https://github.com/ymgaq/AQ/releases/download/v4.0.0/AQ_linux.tar.gz
RUN tar -xzf ./downloads/AQ_linux.tar.gz -C ./downloads AQ/engine/model_cn.uff AQ/engine/model_jp.uff
RUN mv ./downloads/AQ/engine/model_cn.uff ./engine/model_cn.uff
RUN mv ./downloads/AQ/engine/model_jp.uff ./engine/model_jp.uff
RUN rm -rf ./downloads

##############
### Runner ###
##############

FROM nvidia/cuda:10.0-cudnn7-runtime-ubuntu18.04

WORKDIR /AQ
COPY --from=builder /src/AQ /AQ/AQ
COPY --from=builder /src/config.txt /AQ/config.txt
COPY --from=builder /src/prob /AQ/prob
COPY --from=builder /src/engine /AQ/engine
COPY --from=builder /src/libs /AQ/libs

ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/AQ/libs/TensorRT-7.0.0.11/lib"

ENTRYPOINT [ "/AQ/AQ" ]
