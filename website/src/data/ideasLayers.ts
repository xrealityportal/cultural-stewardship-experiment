export type IdeasLayer = {
  n: number;
  title: string;
  actions: number;
  participants: number;
  uriDescription: string;
};

export const ideasLayers: IdeasLayer[] = [
  { n: 1, title: "Seeing", actions: 17, participants: 12, uriDescription: "URI description: visual art, curation, film, moving image, screen culture" },
  { n: 2, title: "Making", actions: 24, participants: 19, uriDescription: "URI description: craft, fabrication, fashion, wearable tech, architecture, spatial design" },
  { n: 3, title: "Listening", actions: 12, participants: 8, uriDescription: "URI description: music, sound art, club culture, dance, performance" },
  { n: 4, title: "Telling", actions: 29, participants: 23, uriDescription: "URI description: journalism, fiction, poetry, publishing, print, zines" },
  { n: 5, title: "Remembering", actions: 18, participants: 14, uriDescription: "URI description: heritage, archives, oral history, ritual, ceremony, sacred practice, identity, diaspora" },
  { n: 6, title: "Imagining", actions: 21, participants: 27, uriDescription: "URI description: speculative design, futures, games, interactive media, creative tech, digital art" },
  { n: 7, title: "Tending", actions: 14, participants: 6, uriDescription: "URI description: ecology, food culture, wellness, care, somatic practice, community, conviviality" },
];