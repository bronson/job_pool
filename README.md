# JobPool

Fork processes to work in the background.  Feed them data, read their results, kill them.  You're the master.


## Installation

Add this line to your Gemfile:

```ruby
gem 'job_pool'
```

## Usage

First, create a job pool:

```ruby
pool = JobPool.new
```

Then fire off some jobs:

```ruby
job = pool.launch(...)
pool.first == job
```


## License

MIT, enjoy!


## Contributing

Please submit issues and patches on
[GitHub](https://github.com/bronson/job_pool/).
