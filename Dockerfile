FROM php:fpm
RUN apt-get update
RUN apt-get install -y libzip-dev zip && docker-php-ext-install zip
RUN docker-php-ext-install iconv mysqli zip
