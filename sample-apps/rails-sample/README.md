# Sample app for judoscale(-rails) gem

This is a minimal Rails app to test the judoscale (soon to be judoscale-rails) gem.

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

Open https://judoscale-adapter-mock.requestcatcher.com in a browser. The sample app is configured to use this endpoint as a mock for the Judoscale Adapter API. This page will monitor all API requests sent from the adapter.

With the app running, open http://localhost:5000 to start the reporter (TODO: reporter should be started when the app starts).

Continue to reload http://localhost:5000 to collect and report more request metrics.
