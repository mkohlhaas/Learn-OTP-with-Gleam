import actors/pantry.{type PantryChannel}
import gleam/int
import gleam/io

pub fn main() {
  let assert Ok(pantry) = pantry.new()
  let assert Error(Nil) = pantry.take_item(pantry, "flour")

  print_number_of_items(pantry)

  pantry.add_item(pantry, "flour")
  pantry.add_item(pantry, "sugar")

  print_number_of_items(pantry)

  let assert Ok("flour") = pantry.take_item(pantry, "flour")
  let assert Error(Nil) = pantry.take_item(pantry, "flour")
  let assert Ok("sugar") = pantry.take_item(pantry, "sugar")
  let assert Error(Nil) = pantry.take_item(pantry, "sugar")

  print_number_of_items(pantry)

  pantry.close(pantry)
}

fn print_number_of_items(pantry: PantryChannel) {
  let assert Ok(n) = pantry.num_items(pantry)
  io.println("Number of Items: " <> int.to_string(n))
}
