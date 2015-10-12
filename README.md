# JobPool

Launch commands to run in the background.  Feed them data, read their results, kill them, set timeouts.

[![Build Status](https://travis-ci.org/bronson/job_pool.svg?branch=master)](https://travis-ci.org/bronson/job_pool)
[![Gem Version](https://badge.fury.io/rb/job_pool.svg)](http://badge.fury.io/rb/job_pool)


## Installation

Add this line to your Gemfile:

```ruby
gem 'job_pool'
```

## Usage

Start like this if you want to try these examples in irb.

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

Then fire off a job.  This one waits a bit and then ROT-13s its input.

```ruby
job = pool.launch("sleep 5; tr A-Za-z N-ZA-Mn-za-m", stdin: "the secrets")
pool.count       => 1
job.output       => ""
           (after five seconds)
pool.count       => 0
job.output       => "gur frpergf"
```

#### IO Objects

You can specify IO objects to read from and write to:

```ruby
source = File.open('contents.txt.gz')
desdtination = File.open('/tmp/out', 'w')
pool.launch 'gunzip --to-stdout', stdin: source, stdout: destination
```

Note that if you specify STDIN or STDOUT, job_pool will close the stream
when the child terminates.  This is almost certainly not what you want.
TODO: add an option... `keep_open: :stdout`, `keep_open: [:stdin, :stdout]`

#### Killing a Job

If you want to terminate a job, just kill it:

```ruby
job = pool.launch("sleep 600")
job.killed?     => false
job.kill
job.killed?     => true
```

JobPool first sends the process a nice TERM
signal and waits a bit.  If the process is still running, it sends a KILL signal.
Pass the number of seconds to wait, default is 2 seconds.


#### Timeouts

TODO: add a timeout example

#### Limiting Running Processes

Pass the maximum number of running jobs when creating the
job pool:

```ruby
pool = JobPool.new(max_jobs: 2)
pool.launch("sleep 5")
pool.launch("sleep 5")
pool.launch("sleep 5")      => raises JobPool::TooManyJobsError
```

### Error Handling

TODO: describe process result

job.success?

TODO: describe stderr

TODO: friggin documentation!


### Job Queues

TODO: include an example of a job queue


## Documentation

I tried to use Ruby's automated documentation tools but it didn't stick.
RDoc didn't have reliable markdown support and lacked param name checking.
YARD produces uglier output (especially noframes) and its lack of :nodoc:
makes my docs too noisy.  For now I'll just write documentation how I want
to see it and hope some tool catches up.


## License

MIT, enjoy!


## Contributing

Submit patches and issues on
[GitHub](https://github.com/bronson/job_pool/).
