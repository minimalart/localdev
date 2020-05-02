# Local environment for development

## Installation
1. Download and install Docker
2. Build php custom image `docker build -t devel-php .`
3. Up the container `docker-compose up -d`
4. Get the mysql image name from `docker ps`
5. Create database
6. Update `wp-config.php` file
7. Browse to `localhost`or `127.0.0.1` or `wordpress.local` and install
 