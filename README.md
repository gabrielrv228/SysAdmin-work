# Sysadmin Practical work
## Description:
- This work consists in the automation of a deployment composed of 2 virtual machines. One of them with worpress and mysql other with Elastic Search and Kibana for monitoring purposes.
- It makes use of a Vagrantfile with one shell script for each machine to install and configure all the requiered dependencies and creates 2 persistent volumes, one for the database and one for the elasticsearch stack.
- It implemets too a proxy autentication for accessing the kibana interface.
- It is fully configurable, you only need to replate the values with your desired ones on the shell scripts or on the Vagrantfile.
## Instructions:


### To run the applications:

- Install virtualbox and vagrant in case you don't have them.

- Clone the repository.
 ```
 git clone https://github.com/gabrielrv228/SysAdmin-work/
 ```

- Position yourself in the repository folder.
```
cd SysAdmin-work
```

- Run vagrant up and wait for the 2 machines to boot.
```
vagrant up
```

### To access the applications:
- Once the 2 machines have loaded:

- You will be able to start configuring your wordpress page in [Wordpress](http://localhost:8085). 

- You will be able to see the logs in [Kibana](http://localhost:8081)  


- This is a proxy access, so you will need a USER: **"admin "** and a PASSWORD: **"pass "**.

- Then you will be redirected to the kibana interface, where you will be able to see the logs of your website.  

![Screenshot from 2021-12-17 18-34-19](https://user-images.githubusercontent.com/95095337/179399247-58b13481-c341-40ff-9334-69c40a05717e.png)


