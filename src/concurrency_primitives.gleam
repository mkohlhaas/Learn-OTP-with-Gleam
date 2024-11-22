import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/io
import gleam/string

pub fn main() {
  let pid: process.Pid = process.self()
  io.println("Current process id: " <> string.inspect(pid))

  let child_pid =
    process.start(
      running: fn() -> Nil {
        let pid = process.self()
        io.println("New process id: " <> string.inspect(pid))
      },
      linked: True,
    )
  io.println("New process id: " <> string.inspect(child_pid))

  let subj: Subject(String) = process.new_subject()
  io.debug(subj)

  process.start(
    running: fn() { process.send(subj, "hello, world") },
    linked: True,
  )

  let assert Ok("hello, world") = process.receive(from: subj, within: 1000)

  let subj2 = process.new_subject()

  process.start(
    running: fn() {
      process.send(subj, "goodbye, mars")
      process.send(subj2, "whats up, pluto")
    },
    linked: True,
  )

  let assert Ok("goodbye, mars") = process.receive(subj, 1000)
  let assert Ok("whats up, pluto") = process.receive(subj2, 1000)

  let subject: Subject(String) = process.new_subject()

  process.start(
    running: fn() { process.send(subject, "hello from some rando process") },
    linked: True,
  )

  let assert Ok("hello from some rando process") =
    process.receive(subject, 1000)

  let subject1: Subject(Int) = process.new_subject()
  let subject2: Subject(String) = process.new_subject()
  let selector =
    process.new_selector()
    |> process.selecting(subject1, int.to_string)
    |> process.selecting(subject2, function.identity)

  process.start(fn() { process.send(subject1, 1) }, True)
  process.start(fn() { process.send(subject2, "2") }, True)

  let assert Ok(some_str) = process.select(selector, 1000)
  io.println("Received: " <> some_str)
  let assert Ok(some_str_2) = process.select(selector, 1000)
  io.println("Received: " <> some_str_2)
}
