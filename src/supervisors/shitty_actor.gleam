import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/otp/actor
import prng/random

pub type GameChannel =
  Subject(Message)

pub type SupervisorChannel =
  Subject(GameChannel)

pub fn start(
  _input: Nil,
  supervisor: SupervisorChannel,
) -> Result(GameChannel, actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      // tell supervisor which process to monitor
      let game = process.new_subject()
      process.send(supervisor, game)

      let selector =
        process.new_selector()
        |> process.selecting(game, function.identity)

      actor.Ready(Nil, selector)
    },
    init_timeout: 1000,
    loop: handle_message,
  ))
}

pub fn play_game(game: GameChannel) -> Result(String, process.CallError(String)) {
  let msg_gen = random.weighted(#(99.0, Duck), [#(1.0, Goose)])
  let msg: fn(Caller) -> Message = random.random_sample(msg_gen)
  // try_call injects caller into msg
  process.try_call(game, msg, 1000)
}

type Caller =
  Subject(String)

pub opaque type Message {
  Duck(caller: Caller)
  Goose(caller: Caller)
}

fn handle_message(message: Message, state: Nil) -> actor.Next(Message, Nil) {
  case message {
    Goose(_) -> panic as "Oh shit it's a fucking goose!!!!"
    Duck(caller) -> {
      actor.send(caller, "duck")
      actor.continue(state)
    }
  }
}
