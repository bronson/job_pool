# JobPool

Fork off jobs to process in the background.  Feed them data, read their results, kill them, set timeouts.


## Installation

Add this line to your Gemfile:

```ruby
gem 'job_pool'
```

## Usage

You can type these commands in irb to follow along (run `irb -Ilib` to
run in this repo).

First, create a job pool:

```ruby
require 'job_pool'
pool = JobPool.new
```

Then fire off some jobs.  This one waits a bit, then ROT-13s its input.

```ruby
input = StringIO.new("no you toucha my secrets")
job = pool.launch("sleep 5; tr A-Za-z N-ZA-Mn-za-m", input)
job.output   => ""
(after 5 seconds...)
job.output   => "ab lbh gbhpun zl frpergf"
```

TODO: why doesn't this work?

```ruby
job = pool.launch "sleep 3; tr A-Za-z N-ZA-Mn-za-m"
job.write "no you toucha my secrets"
```

You can specify IO objects:

```ruby
job = pool.launch 'zcat', File.open('report.txt.gz', STDOUT)
```

TODO: describe killing and timeouts


### Error Handling

TODO: describe process result

TODO: describe stderr


## License

MIT, enjoy!


## Contributing

Please submit issues and patches on
[GitHub](https://github.com/bronson/job_pool/).
