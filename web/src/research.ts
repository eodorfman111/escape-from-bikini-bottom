export const sources = [
  { title: "SpongeBob's house · Encyclopedia SpongeBobia", url: "https://spongebob.fandom.com/wiki/SpongeBob_SquarePants%27_house" },
  { title: "SpongeBob's house · SpongePedia", url: "http://en.spongepedia.org/index.php?title=Spongebob%E2%80%99s_House" },
  { title: "Squidward's house · Encyclopedia SpongeBobia", url: "https://spongebob.fandom.com/wiki/Squidward_Tentacles%27_house" },
  { title: "Squidward's house · SpongeBob Wiki", url: "https://spongebobwiki.org/wiki/Squidward%27s_house" },
  { title: "Patrick's house · Encyclopedia SpongeBobia", url: "https://spongebob.fandom.com/wiki/Patrick_Star%27s_house" },
  { title: "Patrick's house · SpongePedia", url: "http://en.spongepedia.org/index.php?title=Patrick%E2%80%99s_House" },
  { title: "Boating School · transcript", url: "https://spongebob.fandom.com/wiki/Boating_School/transcript" },
]

export const houseNotes = [
  {
    name: 'The pineapple', address: '124 CONCH STREET', color: '#f5ad45',
    floors: [
      ['GROUND FLOOR', 'Living room → kitchen · green stairs'],
      ['SECOND FLOOR', 'Library → bathroom · workout nook'],
      ['THIRD FLOOR', 'Bedroom → rooftop hatch'],
      ['ROOFTOP', 'Leaf crown · lookout'],
    ],
    evidence: 'Jellyfishing: blue bamboo living room, inflatable sofa and diving-helmet TV. Boating School: library and bedroom. Suds: bathroom. Help Wanted: stacked-mattress bed, foghorn and workout equipment. Something Smells: pipe organ. Jellyfish Jam: roof access.',
    decision: 'We use the three-story arrangement described by Encyclopedia SpongeBobia. SpongePedia puts the bedroom on the second floor and library on a mezzanine. Room dimensions, door connections and staircase landings are gameplay choices. The library is represented on one level; the laundry, garage, closets, attic and one-off rooms are omitted.',
  },
  {
    name: 'The moai', address: '122 CONCH STREET', color: '#7ecbd1',
    floors: [
      ['GROUND FLOOR', 'Living room → kitchen + dining room'],
      ['SECOND FLOOR', 'Canopy bedroom → art studio + bathroom'],
    ],
    evidence: 'Employee of the Month: bedroom and alarm-clock storage. Squidward the Unfriendly Ghost: elevator and artwork. House Fancy / Choir Boys: bathroom fixtures. Recurring details include a green living room, pink floor, jazz records, canopy bed, clamshell dining light and self-portraits.',
    decision: 'The bathroom changes floors in the series. Here it sits upstairs beside the bedroom and red art studio. A stair landing connects the floors in place of an elevator; the precise room dimensions and openings are reconstructed. Extra backrooms and storage are omitted.',
  },
  {
    name: 'The rock', address: '120 CONCH STREET', color: '#f4a9b2',
    floors: [
      ['BELOW THE ROCK', 'Living area → sand kitchen + sleeping nook'],
    ],
    evidence: "I'm with Stupid: a separate kitchen. The Pink Purloiner: stairs. The Donut of Shame: bathroom, no attic. Growth Spout: sand refrigerator and sand food. Rise and Shine is a reference for Patrick's home routine. Early episodes use ordinary furniture; later ones use sand.",
    decision: 'Patrick’s home ranges from a single empty space to several rooms, and Shell Games gives the rock a different origin. We choose a recessed, sand-furnished living space with kitchen and sleeping areas. The rock stays propped open as an entrance; the bathroom and transformations are omitted.',
  },
]

export function researchMarkup() {
  return `
    <p class="eyebrow">THE CONCH STREET FIELD GUIDE</p>
    <h2>Familiar places.<br><em>A little cartoon logic.</em></h2>
    <p class="guide-intro">The show does not have a single fixed floor plan. This is a source-informed, playable reconstruction of recurring rooms—not an exact model verified against every episode. Research used fan-maintained house references and an episode transcript, not a complete viewing of the series.</p>
    <div class="house-notes">${houseNotes.map(h => `
      <article style="--house-color:${h.color}">
        <span class="eyebrow">${h.address}</span><h3>${h.name}</h3>
        <div class="floor-list">${h.floors.map(([floor, rooms]) => `<div><b>${floor}</b><span>${rooms}</span></div>`).join('')}</div>
        <h4>Episode references</h4><p>${h.evidence}</p>
        <h4>How we connected it</h4><p>${h.decision}</p>
      </article>`).join('')}</div>
    <h3>Keep exploring</h3>
    <div class="source-links">${sources.map(s => `<a href="${s.url}" target="_blank" rel="noopener noreferrer">${s.title} ↗</a>`).join('')}</div>
    <p class="guide-footnote">An unofficial fan-made game. SpongeBob SquarePants and related characters belong to their respective owners. All game models are built procedurally; no episode footage or audio is bundled.</p>
  `
}
