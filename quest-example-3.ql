World
  Location Forest
  Location Desert
  Location Tundra
  NPC Player at Forest
  NPC Wolf at Forest
  Item Sword at Desert
  Item Amulet at Tundra

World
  Wolf Vulnerable to (Sword)

Subquest RoundTrip (location, item)
  let firstLoc = getloc Player
  goto location
  get item
  goto firstLoc

Subquest RoundTripTwice (locationA, itemA, locationB, itemB)
  run RoundTrip (locationA, itemA)
  run RoundTrip (locationB, itemB)

Quest
  run RoundTrip (Location Tundra, Item Amulet)
  run RoundTrip (Location Desert, Item Sword)
  require Amulet
  kill Wolf

Quest
  run RoundTripTwice (Location Tundra, Item Amulet, Location Desert, Item Sword)
  kill Wolf
  require [Wolf is Alive]