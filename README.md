# Sysadmin Practical work
Deploy the ELK stack
## Description:
This work consists in the automation of a deployment with 2 virtual machines. One of them with worpress and mysql the other one with Elastic Search and Kibana for monitoring.
It makes use of a Vagrant file with one shell script for each machine to install and configure all requiered  dependencies and creates 2 persistent volumes, one for the database and other for the logs.
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
[photo1](./photos/ph1.jpg)

