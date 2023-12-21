# Install R-version 4.3.2 as image
FROM rocker/r-ver:4.3.2

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
RUN R -e "install.packages('data.table')"
RUN R -e "install.packages('dplyr')"
RUN R -e "install.packages('lubridate')"

COPY petroGeo2_0.2.9.tar.gz ./petroGeo2_0.2.9.tar.gz
COPY train_model.R ./train_model.R

RUN R CMD INSTALL petroGeo2_0.2.9.tar.gz

CMD ["Rscript", "./train_model.R"]
