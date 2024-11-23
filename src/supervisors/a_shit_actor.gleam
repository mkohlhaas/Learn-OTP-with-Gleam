import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/otp/actor
import prng/random

pub fn start(
  _input: Nil,
  supervisor: Subject(Subject(Message)),
) -> Result(Subject(Message), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      // Create a new subject and send it to the parent process,
      // so that the parent process can send us messages.
      let actor = process.new_subject()
      process.send(supervisor, actor)

      // Initialize the actor.
      // Notice we provide a selector rather than a simple subject.
      //
      // We can send out multiple subjects on startup if we want, 
      // so the actor can be communicated with from multiple processes.
      // The selector allows us to handle messages as they come in, no
      // matter which subject they were sent to.
      //
      // In our case, we only send out the one subject though.

      let selector =
        process.new_selector()
        |> process.selecting(actor, function.identity)

      actor.Ready(Nil, selector)
    },
    // You might call other processes to start up your actor,
    // so we set a timeout to prevent the supervisor from
    // waiting forever for the actor to start.
    init_timeout: 1000,
    // This is the function that will be called when the actor
    // get's sent a message. We'll define it below.
    loop: handle_message,
  ))
}

/// We provide this function in case we want to manually stop the actor,
/// but in reality the supervisor will handle that for us.
pub fn shutdown(subject: Subject(Message)) -> Nil {
  actor.send(subject, Shutdown)
}

/// This is how we play the game.
/// We are at the whim of the child as to whether we are a 
/// humble duck or the mighty goose.
pub fn play_game(
  game: Subject(Message),
) -> Result(String, process.CallError(String)) {
  let msg_gen = random.weighted(#(999.0, Duck), [#(1.0, Goose)])
  let msg = random.random_sample(msg_gen)
  process.try_call(game, msg, 1000)
}

pub opaque type Message {
  Duck(client: Subject(String))
  Goose(client: Subject(String))
  Shutdown
}

fn handle_message(message: Message, _state: Nil) -> actor.Next(Message, Nil) {
  case message {
    Duck(caller) -> {
      actor.send(caller, "duck")
      actor.continue(Nil)
    }
    Goose(_) -> panic as "Oh shit it's a fucking goose!!!!"
    Shutdown -> actor.Stop(process.Normal)
  }
}
