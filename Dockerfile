# Install R-version 4.3.2 as image
FROM r-base:4.3.2

WORKDIR /app

RUN apt-get update -qq && apt-get install -y libglpk-dev

# Install required libraries
RUN R -e "install.packages('FNN')"
RUN R -e "install.packages('Matrix')"
RUN R -e "install.packages('methods')"
RUN R -e "install.packages('StatMatch')"
RUN R -e "install.packages('FastKNN')"
RUN R -e "install.packages('parallelDist')"
RUN R -e "install.packages('nimble')"
RUN R -e "install.packages('smile')"

COPY packages/petroGeo2_0.2.9.tar.gz ./app/petroGeo2_0.2.9.tar.gz
COPY data/train_data.csv ./app/train_data.csv
COPY data/predict_data.csv ./app/predict_data.csv
COPY main.R ./app/main.R
COPY utils.R ./app/utils.R

RUN R CMD INSTALL ./app/petroGeo2_0.2.9.tar.gz

CMD ["Rscript", "./app/main.R"]