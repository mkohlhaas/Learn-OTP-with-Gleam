import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/set.{type Set}

// Cookbook:
// 1. Define state of actor
// 2. Define Messages
//    For messages with return values a caller param is needed.
// 3. Define message handling function:
//    pub fn start(
//      state: state,
//      loop: fn(msg, state) -> Next(msg, state),
//    ) -> Result(Subject(msg), StartError) {
//      case message {...}
//    }
// 4. Start actor
// 5. Define a nice public interface
//    Use 'send' for not having return values: (NIL)
//    Use 'call' for     having return values: (Result(...))

const timeout = 5000

// ########## Public API ##################################################
pub type PantryChannel =
  Subject(Message)

// 4. Start actor

/// Create a new pantry.
pub fn new() -> Result(PantryChannel, actor.StartError) {
  actor.start(set.new(), handle_message)
}

// 5. Define a nice public interface

/// Add an item to the pantry.
pub fn add_item(pantry: PantryChannel, item: String) -> Nil {
  actor.send(pantry, AddItem(item))
}

/// Take an item from the pantry.
pub fn take_item(pantry: PantryChannel, item: String) -> Result(String, Nil) {
  // The `_` is a placeholder for the caller.
  // It will be injected for us (finally in 'try_call' - follow the invokations).
  actor.call(pantry, TakeItem(_, item), timeout)
}

pub fn num_items(pantry: PantryChannel) -> Result(Int, Nil) {
  actor.call(pantry, NumItems(_), timeout)
}

/// Close the pantry.
pub fn close(pantry: PantryChannel) -> Nil {
  actor.send(pantry, Shutdown)
}

// ########## Internals ################################################## 

// 1. Define state of actor
type Pantry =
  Set(String)

// 2. Define Messages
pub opaque type Message {
  AddItem(item: String)
  TakeItem(caller: Subject(Result(String, Nil)), item: String)
  NumItems(caller: Subject(Result(Int, Nil)))
  Shutdown
}

// 3. Define message handling function:
fn handle_message(
  message: Message,
  pantry: Pantry,
) -> actor.Next(Message, Pantry) {
  case message {
    Shutdown -> actor.Stop(process.Normal)
    NumItems(caller) -> {
      process.send(caller, Ok(set.size(pantry)))
      actor.continue(pantry)
    }
    AddItem(item) -> actor.continue(set.insert(pantry, item))
    TakeItem(caller, item) ->
      case set.contains(pantry, item) {
        False -> {
          process.send(caller, Error(Nil))
          actor.continue(pantry)
        }
        True -> {
          process.send(caller, Ok(item))
          actor.continue(set.delete(pantry, item))
        }
      }
  }
}
