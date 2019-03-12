# Address Manager

Address Manager is a micro-service built with [Vapor](https://vapor.codes/), a server-side Swift framework. It is designed for storing and validating international address data.

## Setup

Start by forking and cloning the Address Manager repository. There are a few pre-requisets you will need before you can run it.

#### MySQL

The AddressManager project uses a MySQL database to store the address information. You can change this to Postgres (or any other database) if you want, but we won't be covering that now.

If you haen't installed MySQL yet, do that now. If you are running macOS, [Homebrew](https://brew.sh/) is a great way to do that:

```sh
brew install mysql
brew services start mysql
mysql -u root
```

In the MySQL command prompt, we will set the password for MySQL and create the databse that AddressManager connects to:

```mysql
ALTER USER root IDENTIFIED BY 'password';
CREATE DATABASE address_manager;
```

#### Google Geocoding API

The default address validator uses the [Google Geocoding API](https://developers.google.com/maps/documentation/geocoding/start) to get location information based on the address passed to the service. If you want to use this validator, you will need an API key for the geocoding API. Otherwise you can implement your own validator.

To get the API key, you can floow the instructions in the [API docs](https://developers.google.com/maps/documentation/geocoding/get-api-key). Then assign the key to an environment variable called `GOOGLE_MAPS_API_KEY`.

#### Done

You're all setup! You should be able to run the service without issues now!

# API Documentation

The REST API documentation has been generated from the Postman collection in the repository and has been [published here](https://documenter.getpostman.com/view/1912959/S17jWrqA).

# License

The Address Manager service is under the [MIT License agreement](https://github.com/SwiftCommerce/AddressManager/blob/master/LICENSE).