import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/set.{type Set}

const timeout = 5000

// ########## Public API ##########

// The functions all take a `Subject(Message)` as their first argument. 
// It matches how working with normal data in Gleam usually works too

/// Create a new pantry actor.
/// If the actor starts successfully, we get back an
/// `Ok(subject)` which we can use to send messages to the actor.
/// Return value = Subject(Message) is the pantry_actor.
pub fn new() -> Result(Subject(Message), actor.StartError) {
  actor.start(set.new(), handle_message)
}

/// Add an item to the pantry.
pub fn add_item(pantry_actor: Subject(Message), item: String) -> Nil {
  actor.send(pantry_actor, AddItem(item))
}

/// Take an item from the pantry.
pub fn take_item(
  pantry_actor: Subject(Message),
  item: String,
) -> Result(String, Nil) {
  // The `_` is a placeholder for the reply subject = caller. It will be injected for us.
  // Caller process will be injected as a subject into TakeItem(caller_subject, item)
  actor.call(pantry_actor, TakeItem(_, item), timeout)
}

/// Close the pantry.
pub fn close(pantry_actor: Subject(Message)) -> Nil {
  actor.send(pantry_actor, Shutdown)
}

/// The messages that the pantry actor can receive.
/// Constructors are private.
pub opaque type Message {
  AddItem(item: String)
  TakeItem(reply_to: Subject(Result(String, Nil)), item: String)
  Shutdown
}

fn handle_message(
  message: Message,
  pantry: Set(String),
) -> actor.Next(Message, Set(String)) {
  case message {
    Shutdown -> actor.Stop(process.Normal)
    AddItem(item) -> actor.continue(set.insert(pantry, item))
    TakeItem(caller_subject, item) ->
      case set.contains(pantry, item) {
        False -> {
          process.send(caller_subject, Error(Nil))
          actor.continue(pantry)
        }
        True -> {
          process.send(caller_subject, Ok(item))
          actor.continue(set.delete(pantry, item))
        }
      }
  }
}
