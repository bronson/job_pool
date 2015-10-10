# JobPool

Fork off jobs to run in the background.  Feed them data, read their results, kill them, set timeouts.


## Installation

Add this line to your Gemfile:

```ruby
gem 'job_pool'
```

## Usage

Do this if you want to try the examples in irb:

```bash
$ git clone https://github.com/bronson/job_pool
$ cd job_pool
$ irb -Ilib
```

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

(after five seconds...)
job.output   => "ab lbh gbhpun zl frpergf"
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
