export const sources = [
  { title: "Pineapple interior still guide · Jellyfishing / Boating School / Suds", url: "https://spongebob.fandom.com/wiki/SpongeBob_SquarePants%27_house/gallery" },
  { title: "Squidward interior still guide · Squid Wood / Unfriendly Ghost / Squid’s Visit", url: "https://spongebob.fandom.com/wiki/Squidward_Tentacles%27_house/gallery" },
  { title: "Patrick interior still guide · Pink Purloiner / Donut of Shame / Growth Spout", url: "https://spongebob.fandom.com/wiki/Patrick_Star%27s_house/gallery" },
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
    evidence: 'Episode stills show cyan bamboo walls, a small Gary portrait, striped lure, green inflatable couch, red lifebuoy chair and diving-helmet TV. The kitchen repeatedly uses a broad arch, porthole refrigerator, crooked-pipe stove, bucket sink and barrel cupboards. The bedroom uses red woven and blue riveted walls, life-ring bed, flower blanket, foghorn, ladder and hatch. The library references show curved stacks, green floor, woven rug, hanging chair, shell-like arches, lower door, upper slide, three bent organ pipes and a conch fireplace.',
    decision: 'The ground floor now follows the recurring living-room-to-kitchen arch, with the orange stair opening opposite it. The curved library is a dedicated walkable floor, connected to the bedroom by its observed slide motif. The three-story connection remains a composite: room dimensions and exact destinations vary or go unshown. The library portrait itself changes between episodes, so this reconstruction displays the directly observed jellyfish version.',
  },
  {
    name: 'The moai', address: '122 CONCH STREET', color: '#7ecbd1',
    floors: [
      ['GROUND FLOOR', 'Living room → kitchen + dining room'],
      ['SECOND FLOOR', 'Canopy bedroom → art studio + bathroom'],
    ],
    evidence: 'Squid Wood stills establish a dedicated library with gold bamboo shelves, dark olive backing, muted book spines, blue ceiling, mauve parquet, arched door, blue bamboo chair, oval rug and shell lamps. Squidward the Unfriendly Ghost and related stills show a red/salmon art room with gray parquet, stool, easel, palette, nautical elevator and many distinct self-portraits, including top-hat, mosaic, geometric and blue-relief motifs.',
    decision: 'The upstairs hall now opens into a separate library, portrait-filled studio, bedroom and bathroom. This arrangement combines rooms the series shows independently; their exact floor and adjacency are not established. The varied self-portraits are original redrawings of recurring motifs rather than repeated rectangles. Bold and Brash appears as a clearly labeled bonus exhibit because its permanent placement in the ordinary house is not verified.',
  },
  {
    name: 'The rock', address: '120 CONCH STREET', color: '#f4a9b2',
    floors: [
      ['BELOW THE ROCK', 'Living area → sand kitchen + sleeping nook'],
    ],
    evidence: "Stills show the whole reddish-brown rock lifting on a brass rim hinge over an excavated pit, with grooved pale sand walls and stairs on the right. Recurring furnishings include a sand sofa, plant, CRT, rotary phone, round table, rolled-arm chair, refrigerator, fake food and toilet. I'm with Stupid supports a separate kitchen; The Pink Purloiner shows stairs; The Donut of Shame shows the bathroom; Growth Spout shows the refrigerator and sand food.",
    decision: 'The exterior now lifts the entire rock lid and the interior entrance descends at the right. The recessed home combines the living area, arched kitchen and sleeping nook, while keeping the research-supported secret box, sand food and donut gags. Bed, toilet and kitchen placement varies, so their combined arrangement remains a game reconstruction.',
  },
]

export function researchMarkup() {
  return `
    <p class="eyebrow">THE CONCH STREET FIELD GUIDE</p>
    <h2>Familiar places.<br><em>A little cartoon logic.</em></h2>
    <p class="guide-intro">The show does not have a single fixed floor plan. This is a source-informed, playable reconstruction of recurring rooms—not a universal blueprint. The revision compares episode stills for the rooms and props below with fan-maintained episode indexes; it does not claim a complete viewing of every episode.</p>
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
