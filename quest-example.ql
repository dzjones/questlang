World
  Location Forest
  Location Desert
  NPC Player at Forest
  NPC Wolf at Forest
  Item Sword at Desert
  Wolf Vulnerable to (Sword)

Subquest RoundTrip (location, item)
  let firstLoc = getloc Player
  goto location
  get item
  goto firstLoc

Quest
  run RoundTrip (Location Desert, Item Sword)
  kill Wolf