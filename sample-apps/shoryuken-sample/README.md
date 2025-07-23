# Sample app for judoscale-shoryuken gem

This is a minimal Rails app to test the judoscale-shoryuken gem.

## Prerequisites

- Ruby
- Node
- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
- AWS Credentials / Region

## Set up the app

Run `./bin/setup` install necessary dependencies. This will...

- Run `bundle install` to install gems

### Shoryuken / SQS setup

You also need to pass AWS credentials and an AWS region for SQS. Those can be added to a `.env` file in the repo, with the following:

```
AWS_ACCESS_KEY_ID=<key>
AWS_SECRET_ACCESS_KEY=<secret>
AWS_REGION=<region>
```

Note that AWS credentials can be setup in a few different ways. More information can be found in [Shoryuken's wiki](https://github.com/ruby-shoryuken/shoryuken/wiki/Configure-the-AWS-Client).

Shoryuken requires the SQS queues to be setup upfront. There's no need to create them via AWS console UI if you don't want to, since Shoryuken provides some helpful commands to create them, so run the following as necessary:

```bash
bundle exec dotenv shoryuken sqs create default
bundle exec dotenv shoryuken sqs create low
bundle exec dotenv shoryuken sqs create high
```

Note that we're using `dotenv` to load the `.env` file with the AWS ENV vars for Shoryuken, to be able to run these `shoryuken sqs` commands. There's a few other useful SQS commands, like `delete` and `purge`. Use `shoryuken sqs help` to learn more.

## Run the app

Run `./bin/dev` to run the app in development mode. This will...

- Use `heroku local` and a `Procfile` to start the following processes:
  - A [tiny proxy server](https://github.com/judoscale/judoscale-adapter-proxy-server) that adds the `X-Request-Start` request header so we can test request queue time reporting.
  - The Rails server.
  - The Shoryuken server to process jobs.

## How to use this sample app

Open https://judoscale-ruby.requestcatcher.com in a browser. The sample app is configured to use this endpoint as a mock for the Judoscale Adapter API. This page will monitor all API requests sent from the adapter.

Run the app. Both the Rails and Shoryuken processes will send an initial request to the API once the app boots up. These can be inspected via request catcher.

Open http://localhost:5006 to see how many jobs are waiting on each of the available queues, and to enqueue sample jobs on those queues that will be processed by the Shoryuken server slowly.

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
# scale up a worker dyno before doing this so Judoscale picks it up
heroku ps:scale heroku_shoryuken=1
heroku addons:create judoscale
```
