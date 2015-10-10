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

Then fire off some jobs.  This one waits a bit then ROT-13s its input.

```ruby
job = pool.launch("sleep 5; tr A-Za-z N-ZA-Mn-za-m", "the secrets")
pool.count       => 1
job.output       => ""
                 (after five seconds...)
pool.count       => 0
job.output       => "gur frpergf"
```

You can specify IO objects to read from and write to:

TODO: this works, but it closes your stdout!  That's problematic.
Need to add a mode that doesn't close the output stream when you're done.

TODO: should specify args using keywords rather than position.

```ruby
pool.launch 'gzcat', File.open('contents.txt.gz'), STDOUT
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
