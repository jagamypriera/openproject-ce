web: bundle exec rails server -p ${PORT:="8080"} -b ${HOST:="127.0.0.1"} --env ${RAILS_ENV:="development"}
assets: cd frontend && RAILS_ENV=${RAILS_ENV:="development"} npm run webpack-watch
worker: bundle exec rake jobs:work