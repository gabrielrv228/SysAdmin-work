#!/bin/bash
sudo apt-get update
#Install dependencies
sudo apt-get install -y default-jre  nginx
#Create and mount volume for elasticsearch
sudo parted /dev/sdc mklabel gpt
sudo parted /dev/sdc mkpart p ext4 1 3000

sudo pvcreate /dev/sdc1
sudo vgcreate elastic /dev/sdc1
sudo lvcreate -l 100%FREE elastic -n flex

sudo mkfs.ext4  /dev/mapper/elastic-flex 
mkdir /var/lib/elasticsearch
mount /dev/mapper/elastic-flex /var/lib/elasticsearch
#Set volume  to mount at reboot
cat <<\EOF >/etc/fstab
LABEL=cloudimg-rootfs   /        ext4   defaults        0 1
/dev/mapper/elastic-flex  /var/lib/elasticsearch   ext4  defaults   00
EOF


#Add repo elastic
sudo wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
cd /
sudo echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

#Install dependencies elastic
sudo apt-get update
sudo apt-get install -y elasticsearch
sudo apt-get install -y filebeat
sudo apt-get install -y logstash
sudo apt-get install  -y kibana
sudo apt-get install -y apache2-utils

#Allow port for the logs
sudo ufw allow 5044

#Logstash configuration
#Entrada de datos
cat <<EOF >/etc/logstash/conf.d/02-beats-input.conf
input {
 beats {
   port => 5044
 }
}
EOF
#Log filter
cat <<EOF >/etc/logstash/conf.d/10-syslog-filter.conf
filter {
 if [fileset][module] == "system" {
   if [fileset][name] == "auth" {
     grok {
       match => { "message" => ["%{SYSLOGTIMESTAMP:[system][auth][timestamp]}
%{SYSLOGHOST:[system][auth][hostname]}
sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]}
%{DATA:[system][auth][ssh][method]} for (invalid user
)?%{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]} port
%{NUMBER:[system][auth][ssh][port]} ssh2(:
%{GREEDYDATA:[system][auth][ssh][signature]})?",
                 "%{SYSLOGTIMESTAMP:[system][auth][timestamp]}
%{SYSLOGHOST:[system][auth][hostname]}
sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]}
user %{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]}",
                 "%{SYSLOGTIMESTAMP:[system][auth][timestamp]}
%{SYSLOGHOST:[system][auth][hostname]}
sshd(?:\[%{POSINT:[system][auth][pid]}\])?: Did not receive identification string
                   from %{IPORHOST:[system][auth][ssh][dropped_ip]}",
"%{SYSLOGTIMESTAMP:[system][auth][timestamp]}
%{SYSLOGHOST:[system][auth][hostname]}
sudo(?:\[%{POSINT:[system][auth][pid]}\])?: \s*%{DATA:[system][auth][user]} :(
%{DATA:[system][auth][sudo][error]} ;)? TTY=%{DATA:[system][auth][sudo][tty]} ;
PWD=%{DATA:[system][auth][sudo][pwd]} ; USER=%{DATA:[system][auth][sudo][user]} ;
COMMAND=%{GREEDYDATA:[system][auth][sudo][command]}",
                 "%{SYSLOGTIMESTAMP:[system][auth][timestamp]}
%{SYSLOGHOST:[system][auth][hostname]}
groupadd(?:\[%{POSINT:[system][auth][pid]}\])?: new group:
name=%{DATA:system.auth.groupadd.name}, GID=%{NUMBER:system.auth.groupadd.gid}",
                 "%{SYSLOGTIMESTAMP:[system][auth][timestamp]}
%{SYSLOGHOST:[system][auth][hostname]}
useradd(?:\[%{POSINT:[system][auth][pid]}\])?: new user:
name=%{DATA:[system][auth][user][add][name]},
UID=%{NUMBER:[system][auth][user][add][uid]},
GID=%{NUMBER:[system][auth][user][add][gid]},
home=%{DATA:[system][auth][user][add][home]},
shell=%{DATA:[system][auth][user][add][shell]}$",
                 "%{SYSLOGTIMESTAMP:[system][auth][timestamp]}
%{SYSLOGHOST:[system][auth][hostname]}
%{DATA:[system][auth][program]}(?:\[%{POSINT:[system][auth][pid]}\])?:
%{GREEDYMULTILINE:[system][auth][message]}"] }
       pattern_definitions => {
         "GREEDYMULTILINE"=> "(.|\n)*"
       }
       remove_field => "message"
     }
     date {
       match => [ "[system][auth][timestamp]", "MMM d HH:mm:ss", "MMM dd
HH:mm:ss" ]
     }
     geoip {
       source => "[system][auth][ssh][ip]"
       target => "[system][auth][ssh][geoip]"
     }
   }
   else if [fileset][name] == "syslog" {
     grok {
       match => { "message" => ["%{SYSLOGTIMESTAMP:[system][syslog][timestamp]}
%{SYSLOGHOST:[system][syslog][hostname]}
%{DATA:[system][syslog][program]}(?:\[%{POSINT:[system][syslog][pid]}\])?:
%{GREEDYMULTILINE:[system][syslog][message]}"] }
       pattern_definitions => { "GREEDYMULTILINE" => "(.|\n)*" }
       remove_field => "message"
     }
     date {
       match => [ "[system][syslog][timestamp]", "MMM d HH:mm:ss", "MMM dd
HH:mm:ss" ]
     }
   }
 }
}
EOF
#Data output
cat <<EOF >/etc/logstash/conf.d/30-elasticsearch-output.conf
output {
 elasticsearch {
   hosts => ["localhost:9200"]
   manage_template => false
   index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
 }
}
EOF

#Kibana configuration
cat <<\EOF >/etc/kibana/kibana.yml
# Kibana is served by a back end server. This setting specifies the port to use.
server.port: 5601

# Specifies the address to which the Kibana server will bind. IP addresses and host names are both valid values.
# The default is 'localhost', which usually means remote machines will not be able to connect.
# To allow connections from remote users, set this parameter to a non-loopback address.
server.host: "0.0.0.0"

# Enables you to specify a path to mount Kibana at if you are running behind a proxy.
# Use the `server.rewriteBasePath` setting to tell Kibana if it should remove the basePath
# from requests it receives, and to prevent a deprecation warning at startup.
# This setting cannot end in a slash.
#server.basePath: ""

# Specifies whether Kibana should rewrite requests that are prefixed with
# `server.basePath` or require that they are rewritten by your reverse proxy.
# This setting was effectively always `false` before Kibana 6.3 and will
# default to `true` starting in Kibana 7.0.
#server.rewriteBasePath: false

# Specifies the public URL at which Kibana is available for end users. If
# `server.basePath` is configured this URL should end with the same basePath.
#server.publicBaseUrl: ""

# The maximum payload size in bytes for incoming server requests.
#server.maxPayload: 1048576

# The Kibana server's name.  This is used for display purposes.
#server.name: "your-hostname"

# The URLs of the Elasticsearch instances to use for all your queries.
#elasticsearch.hosts: ["http://localhost:9200"]

# Kibana uses an index in Elasticsearch to store saved searches, visualizations and
# dashboards. Kibana creates a new index if the index doesn't already exist.
#kibana.index: ".kibana"

# The default application to load.
#kibana.defaultAppId: "home"

# If your Elasticsearch is protected with basic authentication, these settings provide
# the username and password that the Kibana server uses to perform maintenance on the Kibana
# index at startup. Your Kibana users still need to authenticate with Elasticsearch, which
# is proxied through the Kibana server.
#elasticsearch.username: "kibana_system"
#elasticsearch.password: "pass"

# Kibana can also authenticate to Elasticsearch via "service account tokens".
# If may use this token instead of a username/password.
# elasticsearch.serviceAccountToken: "my_token"

# Enables SSL and paths to the PEM-format SSL certificate and SSL key files, respectively.
# These settings enable SSL for outgoing requests from the Kibana server to the browser.
#server.ssl.enabled: false
#server.ssl.certificate: /path/to/your/server.crt
#server.ssl.key: /path/to/your/server.key

# Optional settings that provide the paths to the PEM-format SSL certificate and key files.
# These files are used to verify the identity of Kibana to Elasticsearch and are required when
# xpack.security.http.ssl.client_authentication in Elasticsearch is set to required.
#elasticsearch.ssl.certificate: /path/to/your/client.crt
#elasticsearch.ssl.key: /path/to/your/client.key

# Optional setting that enables you to specify a path to the PEM file for the certificate
# authority for your Elasticsearch instance.
#elasticsearch.ssl.certificateAuthorities: [ "/path/to/your/CA.pem" ]

# To disregard the validity of SSL certificates, change this setting's value to 'none'.
#elasticsearch.ssl.verificationMode: full

# Time in milliseconds to wait for Elasticsearch to respond to pings. Defaults to the value of
# the elasticsearch.requestTimeout setting.
#elasticsearch.pingTimeout: 1500

# Time in milliseconds to wait for responses from the back end or Elasticsearch. This value
# must be a positive integer.
#elasticsearch.requestTimeout: 30000

# List of Kibana client-side headers to send to Elasticsearch. To send *no* client-side
# headers, set this value to [] (an empty list).
#elasticsearch.requestHeadersWhitelist: [ authorization ]

# Header names and values that are sent to Elasticsearch. Any custom headers cannot be overwritten
# by client-side headers, regardless of the elasticsearch.requestHeadersWhitelist configuration.
#elasticsearch.customHeaders: {}

# Time in milliseconds for Elasticsearch to wait for responses from shards. Set to 0 to disable.
#elasticsearch.shardTimeout: 30000

# Logs queries sent to Elasticsearch. Requires logging.verbose set to true.
#elasticsearch.logQueries: false

# Specifies the path where Kibana creates the process ID file.
#pid.file: /run/kibana/kibana.pid

# Enables you to specify a file where Kibana stores log output.
#logging.dest: stdout

# Set the value of this setting to true to suppress all logging output.
#logging.silent: false

# Set the value of this setting to true to suppress all logging output other than error messages.
#logging.quiet: false

# Set the value of this setting to true to log all events, including system usage information
# and all requests.
#logging.verbose: false

# Set the interval in milliseconds to sample system and process performance
# metrics. Minimum is 100ms. Defaults to 5000.
#ops.interval: 5000

# Specifies locale to be used for all localizable strings, dates and number formats.
# Supported languages are the following: English - en , by default , Chinese - zh-CN .
#i18n.locale: "en"
EOF

#Elastic permissions
sudo chown elasticsearch /var/lib/elasticsearch
sudo chmod 764  /var/lib/elasticsearch

#Enable services
sudo systemctl enable elasticsearch --now
sudo systemctl enable logstash --now
sudo systemctl enable kibana --now
sudo systemctl enable filebeat --now

#Configure nginx authentication
cat <<EOF >/etc/nginx/sites-available/default
# Managed by installation script - Do not change
server {
   listen 80;
   server_name kibana.demo.com localhost;
   auth_basic "Restricted Access";
   auth_basic_user_file /etc/nginx/htpasswd.users;
   location / {
       proxy_pass http://localhost:5601;
       proxy_http_version 1.1;
       proxy_set_header Upgrade \$http_upgrade;
       proxy_set_header Connection 'upgrade';
       proxy_set_header Host \$host;
       proxy_cache_bypass \$http_upgrade;
   }
}
EOF
#SET NGINX PASSWORD COMMAND HERE



#Demo password for kibana.
#PASSWORD = pass
sudo htpasswd -c /etc/nginx/htpasswd.users 
cat <<\EOF >//etc/nginx/htpasswd.users
admin:$apr1$V9iP4TdZ$gEZg22w9m9HW6kARPhJJX/
EOF

sudo systemctl restart kibana
sudo systemctl restart nginx
#Command to set another password:
#sudo bash -c "openssl passwd -apr1  >> /etc/nginx/.htpasswd"









