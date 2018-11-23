# Container
Container
* Guest Operating System is not needed
* Only consist of application and services
* Share Host Operating System Kernel
* Uses lesser resources and only consume the resources required for the application when the container starts
* A ready-to-use application can run anywhere as long as the host system runs container. Making container portable
* Fastest to start up
* Has its own libraries and dependencies  

Virtual machine
* Guest Operating System is needed
* Requires more resources from host machine
* Any OS can be used on the VM

Pros and Cons
* VM is a better option when running a applications that require all of the OS functionality and resources
* VM has a better isolation as compared to container
* Container takes a few seconds to start up as compared to VM which can take minutes to start
