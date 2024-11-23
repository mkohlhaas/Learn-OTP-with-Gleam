import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/otp/supervisor
import supervisors/a_shit_actor as duckduckgoose

const runs = 10_000

pub fn main() {
  // We set up our worker, and we give the actor a subject for this process to send 
  // us messages with on init. Remember, it needs to send us back a subject so we 
  // can talk to it directly.
  let supervisor = process.new_subject()
  let actor_spec = supervisor.worker(duckduckgoose.start(_, supervisor))

  // We add the child worker/actor and start the supervisor.
  let assert Ok(_supervisor_subject) =
    supervisor.start(supervisor.add(_, actor_spec))

  // The actor's init function sent us a subject for us to be able
  // to send it messages
  let assert Ok(game) = process.receive(supervisor, 1000)

  // Let's play the game a bit
  play_game(supervisor, game, runs)
}

fn play_game(
  supervisor: Subject(Subject(duckduckgoose.Message)),
  game: Subject(duckduckgoose.Message),
  times n: Int,
) -> Nil {
  case n {
    // 0 -> Nil
    _ -> {
      case duckduckgoose.play_game(game) {
        // msg = "duck"
        Ok(msg) -> {
          io.println(msg)
          play_game(supervisor, game, n - 1)
        }
        Error(_) -> {
          io.println("Oh no, a goose crashed our actor!")
          // The supervisor should restart our actor for us,
          // but it'll be on a different process now! Don't 
          // worry though, the game's init function should
          // send us a new subject to use.
          let assert Ok(new_game) = process.receive(supervisor, 1000)
          play_game(supervisor, new_game, n - 1)
        }
      }
    }
  }
}
