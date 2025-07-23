# Sample app for judoscale-rails gem

This is a minimal Rails app to test the judoscale-rails gem.

## Prerequisites

- Ruby
- Node
- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)

## Set up the app

Run `./bin/setup` install necessary dependencies. This will...

- Run `bundle install` to install gems

## Run the app

Run `./bin/dev` to run the app in development mode. This will...

- Use `heroku local` and a `Procfile` to start the following processes:
  - A [tiny proxy server](https://github.com/judoscale/judoscale-adapter-proxy-server) that adds the `X-Request-Start` request header so we can test request queue time reporting.
  - The Rails server.

## How to use this sample app

Open https://judoscale-ruby.requestcatcher.com in a browser. The sample app is configured to use this endpoint as a mock for the Judoscale Adapter API. This page will monitor all API requests sent from the adapter.

Run the app. As soon as it boots up, an initial request to the API is sent, and can be inspected via request catcher.

Access http://localhost:5006 and continue to reload it to collect and report more request metrics.

## Deploy this app to Heroku

From this directory, run the following to create a new git repo and push it to Heroku:

```sh
git init
git add .
git commit -m "prep for Heroku"
heroku create
git push heroku main
```

To install Judoscale:

```sh
heroku addons:create judoscale
```
