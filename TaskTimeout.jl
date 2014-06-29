module TaskTimeout
    # Base.consume must be imported to be overloaded

    import Base: consume

    # Exports

    export TimedTask, consume, TaskTimeoutException

    ###
    #   TaskTimeoutException
    #       Thrown (to the task) by the timer when the task has timed out.
    ###

    type TaskTimeoutException <: Exception
    end

    ###
    #   CancelTimeoutException
    #       Thrown (to the timer) by the task when the task has completed.
    ###

    type CancelTimeoutException <: Exception
    end

    ###
    #   TimedTask
    #       A type for tasks with a life expectancy.
    #
    #       Accepts either a function or a task as the first argument, for the task to be executed.
    #
    #       The second parameter is the task's target maximum duration, in seconds.
    ###

    type TimedTask
        task::Task
        timeout::Int
        result

        TimedTask(task::Task) = new (task, 30)
        TimedTask(task::Task, timeout::Int) = new (task, timeout)
        TimedTask(task_function::Function) = new (Task(task_function), 30)
        TimedTask(task_function::Function, timeout::Int) = new (Task(task_function), timeout)
    end

    ###
    #   consume(timed_task::TimedTask)
    #       Execute the task with the specified timeout.
    ###

    function consume(timed_task::TimedTask)
        time_keeper = Task(function ()
            sleep(timed_task.timeout)

            timed_task.task.exception = TaskTimeoutException()

            yieldto(timed_task.task)
        end)

        @async begin
            try
                consume(time_keeper)
            catch exception
                if (!isa(exception, CancelTimeoutException))
                    rethrow(exception)
                end
            end
        end

        @sync begin
            @async begin
                timed_task.result = consume(timed_task.task)

                time_keeper.exception = CancelTimeoutException()
            end
        end

        return timed_task.result
    end

### End of module

end