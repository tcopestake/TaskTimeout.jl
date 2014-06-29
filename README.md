# TaskTimeout.jl

A small Julia module for creating [tasks](http://julia.readthedocs.org/en/latest/stdlib/base/#tasks) with a maximum execution time.

It is recommended that you read the [limitations](#limitations) below.

### Table of contents
* [Usage](#usage)
    * [Creating a task](#creating-task)
    * [Running a task](#running-task)
    * [Retrieving the result](#retrieving-result)
    * [Handling a timeout](#handling-timeout)
    * [Example](#example-a)
* [Limitations](#limitations)

<a name="usage">

### Usage

To use this module in your project, download the TaskTimeout.jl file and include it with:

```
using TaskTimeout
```

<a name="creating-task">

#### Creating a task

Tasks are contained within the **`TimedTask`** type. The constructor options are:


_**TimedTask(function [ , timeout=30 ])**_

or

_**TimedTask(task [ , timeout=30 ])**_

where **`function`** is either a named or anonymous function, **`task`** is of type **`Task`** and the optional **`timeout`** is an integer specifying the number of seconds that the task is permitted to run, with a default of 30 seconds.

<a name="running-task">

#### Running a task

Timed tasks are expected to be started using the **`consume`** function. Other methods of starting a task are not currently able to enforce the task's time restriction.

<a name="retrieving-result">

#### Retrieving the result

The task's **`return`** / **`produce`** value will be returned by the call to **`consume`** and will also be available in the **`TimedTask`**'s **`result`** field.

<a name="handling-timeout">

#### Handling a timeout

If the task times out before it is finished executing, a **`TaskTimeoutException`** exception will be thrown by the call to **`consume`**.

<a name="example-a">

#### Example

The below example creates a task which is programmed to sleep for 30 seconds, with a timeout of 3 seconds.

    using TaskTimeout

    function do_something()
        println("Sleeping for 30 seconds...")

        sleep(30)

        println("Finished sleeping.")

        return 12
    end

    try
        task = TimedTask(do_something, 3)

        task_value = consume(task)

        print("Task returned: ")
        println(task_value)
    catch exception
        if (isa(exception, TaskTimeoutException))
            println("Timed out.")
        else
            rethrow(exception)
        end
    end

As the task times out before the 30 second sleep is finished, the output is:

> Sleeping for 30 seconds...  
> Timed out.

Changing the timeout to 30 seconds and the sleep time to 5 seconds, the output is:

> Sleeping for 5 seconds...  
> Finished sleeping.  
> Task returned: 12

<a name="limitations">  

### Limitations

* __Julia currently has no clean and reliable method of terminating a task.__ This module works by throwing the `TaskTimeoutException` exception within the task, with the hope that the exception will bubble to the top and cause the task to stop running. However, there's a danger that this exception will be caught by any try/catch blocks within the task, in which case the task may continue running and the timeout exception may never reach the caller. (See also: [issue #6283](https://github.com/JuliaLang/julia/issues/6283))

* As tasks all share one thread, the timeout can only be enforced when the timekeeper is given a chance to execute by Julia's task scheduler e.g. during blocking operations or following a **`yield`**. This also means that:
    * The timeout duration isn't guaranteed to be 100% accurate. For example, a task with a 30-second timeout may in fact be terminated after 40 seconds, if that's the timekeeper's first opportunity to enforce the timeout.
    * The timeout will have no effect against infinite loops, unless operations within the loop **`yield`**, **`sleep`** or perform operations such as printing or reading from streams.

* Calling the **`consume`** function is currently the only supported method of running a task. For the most part, this shouldn't be an issue.