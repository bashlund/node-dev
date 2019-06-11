# Develop with node without needing to install it
If you do not want to install `nodejs/npm` in your OS, you can instead run those programs within a Docker container to get some isolation.  

Motivation: see [NPM backdoors](https://duckduckgo.com/?q=npm+backdoors).

This module runs by default the container image `node:10`, but that can be customized using the `-e image=` parameter.

First install [Space](https://space.sh), if you haven't already.

Then run a new container as:  
```sh
space -m github.com/Bashlund/node-dev /run/
```  

This will spawn a new container with the same name as the directory and with the directory mounted to `/home/node/project`.  
The name can be customized with the `-e name=` parameter.  


To enter a shell inside the container:  
```sh
space -m github.com/Bashlund/node-dev /exec/
```

To run a shell command inside the container:  
```sh
space -m github.com/Bashlund/node-dev /exec/ -- sh '-c "cd truffle && yarn"'
```

To get the IP address of the container:  
```sh
space -m github.com/Bashlund/node-dev /get_ip/
```

To remove the container:  
```sh
space -m github.com/Bashlund/node-dev /rm/
```  

Note: The current working directory from where you issue this command must be the same as from where you started it, since the container name is taken from the directory name.
