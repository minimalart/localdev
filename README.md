# Local environment for wordpress development

## Setup and configuration

A `.env-example` file has been included to more easily set docker-compose variables without having to modify the docker-compose.yml file itself.

Default values have been provided as a means of getting up and running quickly for testing purposes. It is up to the user to modify these to best suit their deployment preferences.

Create a file named .env from the .env_example file and adjust to suit your deployment

    cp .env-example .env

## Edit yout host file

    sudo vim /etc/hosts

Add the line:
    
    127.0.0.1   dev.local

## Create Self-Signed Certificates
**Do not use self-signed certificates in production !**
For online certificates, use Let's Encrypt instead.


### Certificate authority (CA)

Generate `RootCA.pem`, `RootCA.key` & `RootCA.crt`:

    openssl req -x509 -nodes -new -sha256 -days 1024 -newkey rsa:2048 -keyout ./certs/RootCA.key -out ./certs/RootCA.pem -subj "/C=US/CN=Devlocal-Root-CA"
	
    openssl x509 -outform pem -in ./certs/RootCA.pem -out ./certs/RootCA.crt
  
Note that `Devlocal-Root-CA` is an example, you can customize the name.

### Domain name certificate

Let's say you have two domains `fake1.local` and `fake2.local` that are hosted on your local machine
for development (using the `hosts` file to point them to `127.0.0.1`).

First, create a file `domains.ext` inside the `certs` directory that lists all your local domains:

    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    subjectAltName = @alt_names
    [alt_names]
    DNS.1 = localhost
    DNS.2 = dev.local
    DNS.3 = fake2.local

Generate `localhost.key`, `localhost.csr`, and `localhost.crt`:

    openssl req -new -nodes -newkey rsa:2048 -keyout ./certs/localhost.key -out ./certs/localhost.csr -subj "/C=US/ST=BA/L=AV/O=Local-Certificates/CN=localhost.local"
    
    openssl x509 -req -sha256 -days 360 -in ./certs/localhost.csr -CA ./certs/RootCA.pem -CAkey ./certs/RootCA.key -CAcreateserial -extfile ./certs/domains.ext -out ./certs/localhost.crt

Note that the country / state / city / name in the first command  can be customized.  

### Create a a strong Diffie-Hellman group 

While we are using OpenSSL, we should also create a strong Diffie-Hellman group, which is used in negotiating Perfect Forward Secrecy with clients:

    openssl dhparam -out ./certs/dhparam.pem 2048

## Configuring Nginx to Use SSL

First, let’s create a new Nginx configuration snippet in the /etc/nginx/snippets directory.

    vim ./nginx/snippets/ssl.conf

Within this file, we need to set the `ssl_certificate` directive to our certificate file and the `ssl_certificate_key` to the associated key. In our case, this will look like this:

    ssl_certificate /etc/ssl/certs/localhost.crt;
    ssl_certificate_key /etc/ssl/private/localhost.key;

### Creating a Configuration Snippet with Strong Encryption Settings

Next, we will create another snippet that will define some SSL settings. This will set Nginx up with a strong SSL cipher suite and enable some advanced features that will help keep our server secure.

The parameters we will set can be reused in future Nginx configurations, so we will give the file a generic name:

    vim /nginx/snippets/ssl-params.conf

Copy the following into your `ssl-params.conf` snippet file:

    ssl_protocols TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/certs/dhparam.pem;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off; # Requires nginx >= 1.5.9
    ssl_stapling on; # Requires nginx >= 1.3.7
    ssl_stapling_verify on; # Requires nginx => 1.3.7
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    # Disable strict transport security for now. You can uncomment the following
    # line if you understand the implications.
    # add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

## Trust the local CA

At this point, the site would load with a warning about self-signed certificates.
In order to get a green lock, your new local CA has to be added to the trusted Root Certificate Authorities.

### Chrome & Edge

You can right-click on `RootCA.crt` > `Install` to open the import dialog.

Make sure to select "Trusted Root Certification Authorities" and confirm.

### Firefox

Import the certificate by going to `about:preferences#privacy` > `Certificats` > `Import` > `RootCA.pem` > `Confirm for websites`.