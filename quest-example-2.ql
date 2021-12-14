World
  Location Forest
  Location Desert
  Location Tundra
  NPC Player at Forest
  NPC Wolf at Forest
  Item Sword at Desert
  Wolf Vulnerable to (Sword)
  Item Amulet at Tundra

Subquest RoundTrip (location, item)
  let firstLoc = getloc Player
  goto location
  get item
  goto firstLoc

Quest
  run RoundTrip (Location Tundra, Item Amulet)
  run RoundTrip (Location Desert, Item Sword)
  require Amulet
  kill Wolf