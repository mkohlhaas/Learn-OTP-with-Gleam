import actors/pantry

pub fn main() {
  let assert Ok(pantry_actor) = pantry.new()
  let assert Error(Nil) = pantry.take_item(pantry_actor, "flour")

  pantry.add_item(pantry_actor, "flour")
  pantry.add_item(pantry_actor, "sugar")

  let assert Ok("flour") = pantry.take_item(pantry_actor, "flour")
  let assert Ok("sugar") = pantry.take_item(pantry_actor, "sugar")

  pantry.close(pantry_actor)
}
