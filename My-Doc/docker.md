# Docker
Docker is a program that create, deploy and run applications by utilising container. Developers can package a application with all the required libraries and dependencies in a container which can be virtually run anywhere.

## Install Docker CE
To use Docker, let's do an [installation for Docker CE (Community Edition)](https://docs.docker.com/install/linux/docker-ce/debian/#set-up-the-repository). Follow the instructions from the link and Docker CE should be now installed.

Test it out by running `docker run hello-world`
The output of the command should show:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

## Common Docker Commands
Here are some of the common docker commands:

To fetch a docker image from the Docker registry:

`docker pull imagethatyouwant`



To list the docker images in your system:

`docker images`

To run a docker image:

`docker run imagethatyouwanttorun`

Some of the common [options](https://docs.docker.com/engine/reference/commandline/run/) when running `docker run`:
* `-d` allow the container to run in detach mode. This option allow the container to run at the background and you can continue to use the terminal after the command.
* `-p port:port` exposed the port from the container to the external port. Example `-p 80:5000` Port 5000 used inside the container will be exposed to the external Port 80
* `-e` run the container with environment variable.

To list the current running container:

`docker ps`

add the option `-a` and this will show the running container and container that was ran. From the list, you should be able to see which container has exited or running.

To stop a running container:

`docker stop containerID`

The container ID is shown at the first column when running the command `docker ps` or `docker ps -a`.

To interact and run command in the container:

`docker run -it yourcontainer sh`

Once the container exited, try to always remove the container as it takes up disk space.

To remove container:

`docker rm containerID`

If you like to remove a list of exited containers without having to copy every single container ID, simply run this command:

`docker rm $(docker ps -a -q -f status=exited)`

Alternatively, you can run `docker container prune` to achieve the same result in removing all the exited containers.

To connect to a running container:

`docker exec -it containername/containerID /bin/bash`

With this command, it allows user to enter the bash shell in the container.

At times, environment variables are needed when running a container, and this environment variables can be stored in a file.

Create a file named `.env` and store the values of each environment variables that you want.

To run the container with environment variables:

`docker run --env-file=.env yourcontainer`

Most of information was referenced from [here](https://docker-curriculum.com).

## Building Customise image
Customisation can be done with the original image and with your own configuration. Configuration files from the local machine can be copy to the original image. This allow you to build a image with your own configuration.

To create a image, a `Dockerfile` is needed. Create a directory and store all the configurations along with the `Dockerfile` inside.

Store the configuration files in a sub directory to have a better organisation on the files.

let's build a image with [your own configuration with Nginx based image](https://www.nginx.com/blog/deploying-nginx-nginx-plus-docker/). An example of a `Dockerfile` is shown below.
```bash
FROM nginx
COPY content /usr/share/nginx/html
COPY conf /etc/nginx
```
* First line indicates the image that will be pull from either locally or docker hub
* The next line is to do a copy from the local folder `content` contents into the Nginx based image /usr/share/nignx/html. Note that the `content` and `conf` folder are both located within the same directory with Dockerfile

Next, run the following command to build your own image.

`docker build -t mynginx .`

The name of the image will be named as `mynginx` and the `.` is to indicate the current working directory with all the folders and Dockerfile.

The customised image should be built. Try to run this image and test if the container is working with your configuration.
