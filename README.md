# Jan-Hendrik's shell docker

## Usage

* docker build --no-cache -t shell .
* docker run -d -t --name shell --hostname shell --volume /data:/data shell

# Upload new version:

* docker tag shell jheuing/shell:v0.1
* docker push jheuing/shell:v0.1


