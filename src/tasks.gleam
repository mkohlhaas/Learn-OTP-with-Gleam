//// Tasks are one-off processes meant to easily make synchronous work async.
//// They're really straightforward to use. Just fire them off and check back later.

import birl
import birl/duration
import gleam/dict.{type Dict}
import gleam/erlang
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/task
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let handle: task.Task(Nil) =
    task.async(fn() {
      process.sleep(500)
      io.println("Task is done")
    })

  io.println("I will execute right away")

  task.await(handle, 1000)

  io.println("I won't execute until the task is done.")

  let handle: task.Task(Nil) = task.async(fn() { process.sleep(1000) })

  case task.try_await(handle, 500) {
    Ok(_) -> io.println("Task finished successfully")
    Error(_) -> io.println("Task timed out!")
  }

  let assert Error(_) = erlang.rescue(fn() { panic })

  let assert Error(_) =
    task.await(task.async(fn() { erlang.rescue(fn() { panic }) }), 1000)

  let handle: task.Task(Result(Int, Nil)) =
    task.async(fn() { list.at([1, 2, 3], 99) })

  case task.await(handle, 1000) {
    Ok(val) -> io.println("The 100th item is" <> int.to_string(val))
    Error(Nil) -> io.println_error("The list has fewer than 100 items")
  }

  // Letter Frequency

  use workload: String <- result.try(simplifile.read(
    from: "./src/tasks/king_james_bible.txt",
  ))
  let workload = string.to_utf_codepoints(workload)

  let linear_freq =
    time("linear frequency", fn() { linear_letter_frequency(workload) })

  let parallel_freq =
    time("parallel frequency", fn() {
      parallel_letter_frequency(workload, 100_000)
    })

  case linear_freq == parallel_freq {
    True ->
      io.println(
        "Our parallel and linear frequency functions produced the same output",
      )
    False ->
      io.println(
        "Our parallel and linear frequency functions produced different output",
      )
  }

  Ok(Nil)
}

fn linear_letter_frequency(input: List(UtfCodepoint)) -> Dict(UtfCodepoint, Int) {
  use dict, letter <- list.fold(input, dict.new())
  use entry <- dict.update(dict, update: letter)
  case entry {
    Some(n) -> n + 1
    None -> 1
  }
}

fn parallel_letter_frequency(
  input: List(UtfCodepoint),
  chunk_size: Int,
) -> Dict(UtfCodepoint, Int) {
  let handles =
    list.map(list.sized_chunk(input, chunk_size), fn(chunk) {
      task.async(fn() { linear_letter_frequency(chunk) })
    })

  // Fold over the handles to the tasks to await their results
  use total_freq_dict, partial_freq_handle <- list.fold(handles, dict.new())
  let partial_freq_dict = task.await(partial_freq_handle, 1000)
  use total_freq, letter, count <- dict.fold(partial_freq_dict, total_freq_dict)
  use entry <- dict.update(total_freq, letter)
  case entry {
    Some(counter) -> counter + count
    None -> count
  }
}

// This is just a little timer function to help us see the results of our work.
fn time(name: String, f: fn() -> a) -> a {
  let start = birl.now()
  let x = f()
  let end = birl.now()
  let difference =
    birl.difference(end, start) |> duration.blur_to(duration.MilliSecond)
  io.println(name <> " took: " <> int.to_string(difference) <> "ms")
  x
}
