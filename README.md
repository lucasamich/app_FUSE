# Running FUSE Software

To build the model, use the following command (inside the repository folder):
```bash
docker build -t <image_name> .
```

## 1. Model Specifications

After building the image, run the model using `docker run`. Utilize the `--model_type` flag to choose the desired model type. Currently, the available models are: "geographical", "feature", or "mixture".

## 2. Running the Model (Sampling and Prediction)

Running the model involves executing MCMC sampling and then performing predictions in a single run within the Docker container. To save the generated objects from the run, utilize a [volume](https://docs.docker.com/storage/volumes/) or a bind mount.


For instance, to run the mixture model using a bind mount, execute the following command:
```bash
docker run <image_name> -v <path/in/host>:/app/data <image_name> --model_type mixture
```