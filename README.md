# Sysadmin Practical work
Deploy the ELK stack
## Description:
- This work consists in the automation of a deployment that consists 2 virtual machines. One of them with worpress and mysql the other one with Elastic Search and Kibana for monitoring.
- It makes use of a Vagrant file with one shell script for each machine to install and configure all requiered dependencies and creates 2 persistent volumes, one for the database and other for the logs.
- It implemets too a proxy autentication for accessing the kibana interface.
- It is fully configurable, you only need to replate the values with your desired ones on the shell scripts or on the vagrant file.
## Instructions:


### To run the applications:

>Install virtualbox and vagrant in case you don't have them.

>Clone the repository.

>Position yourself in the repository folder.

>Run vagrant up and wait for the 2 machines to boot.

### To access the applications:
>Once the 2 machines have loaded:

>You will be able to start configuring your wordpress page in [Wordpress](http://localhost:8085). 

>You will be able to see the logs in [Kibana](http://localhost:8081)  


>This is a proxy access, so you will need a USER: **"admin "** and a PASSWORD: **"pass "**.

>Then you will be redirected to the kibana interface, where you will be able to see the logs of your website.  

>wordpress URL:http://localhost:8085

>kibana URL:http://localhost:8081
![Screenshot from 2021-12-17 18-34-19](https://user-images.githubusercontent.com/95095337/179399247-58b13481-c341-40ff-9334-69c40a05717e.png)


