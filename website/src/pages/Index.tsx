import Layout from "@/components/Layout";
import { Link } from "react-router-dom";
import primaryDao from "@/assets/primary-dao.png";
import digitalDao from "@/assets/digital-dao.png";
import ideasDao from "@/assets/ideas-dao.png";
import physicalDao from "@/assets/physical-dao.png";

const daoNodes = [
  {
    name: "Primary Layer",
    description: "This layer relates to access to the Safe and the allocation of shared resources. Participants may use it to determine whether resources are made available to support specific proposals.",
    image: primaryDao,
    path: "/primary-layer",
  },
  {
    name: "Digital Layer",
    description: "This layer relates to digital infrastructure, including code, interfaces, and online environments. Participants may engage here to create, maintain, or adapt digital tools.",
    image: digitalDao,
    path: "/digital-layer",
  },
  {
    name: "Idea Layer",
    description: "This layer remains open for free and experimental exploration of concepts. No shared resources are allocated here, and Participants may engage without constraint to develop and express ideas.",
    image: ideasDao,
    path: "/idea-layer",
  },
  {
    name: "Convergence Layer",
    description: "This layer facilitates tangible outcomes that manifest in physical or digital spaces. Participants can materialise ideas into concrete form through live sessions and interface with legal jurisdictions when needed.",
    image: physicalDao,
    path: "/convergence-layer",
  },
];

const Index = () => {
  return (
    <Layout>
      <div className="space-y-16">

        <div className="space-y-6">
          <video src="/videos/text.mp4" autoPlay loop muted playsInline className="max-w-xl mx-auto w-full" />

        </div>

        <section className="space-y-6 max-w-2xl mx-auto text-left" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
          <h2 className="text-xs tracking-widest opacity-50 uppercase">About the Experiment</h2>
          <p className="text-base leading-relaxed opacity-70 whitespace-pre-line">
            The experiment's multi-layered ecosystem is designed to foster an interplay between ideational concepts, physical spaces, and digital manifestations. Its primary aim is to act as a steward for cultural endeavours through a layered approach, ensuring a clear separation between different planning activities while facilitating their interactions as different departments within the organisation.
          </p>

          <div className="pt-4 space-y-2">
            <h2 className="text-xs tracking-widest opacity-50 uppercase">Explore the Layers</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
              {daoNodes.map((dao) => (
                <Link key={dao.name} to={dao.path} className="border border-foreground/15 p-4 space-y-3 block hover:border-foreground/40 transition-all">
                  {dao.image && (
                    <div className="w-full aspect-video overflow-hidden">
                      <img src={dao.image} alt={dao.name} className="w-full h-full object-cover" />
                    </div>
                  )}
                  <h3 className="text-xs tracking-widest opacity-60">{dao.name}</h3>
                  <p className="text-sm leading-relaxed opacity-60">{dao.description}</p>
                </Link>
              ))}
            </div>
          </div>

          
        </section>

        <section className="space-y-4 max-w-2xl mx-auto text-left" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
           <h2 className="text-xs tracking-widest opacity-50 uppercase">CONTEXT</h2>
          <p className="text-base leading-relaxed opacity-70 whitespace-pre-line">
            This experiment has emerged through ongoing exploration of distributed coordination, digital tools, and cultural practice. It reflects a growing interest in how people may organise, create, and interact without reliance on centralised structures, particularly within the context of funding cultural initiatives. The ideas and structures explored here are part of a wider conversation that continues to evolve across different spaces, both online and offline. 
          </p>
        </section>

        <section className="space-y-4 max-w-2xl mx-auto text-left" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
          <h2 className="text-xs tracking-widest opacity-50 uppercase">What is Powers Protocol?</h2>
          <p className="text-base leading-relaxed opacity-70">
            The experiment is built on Ethereum using Powers Protocol; a smart contract framework for on-chain governance architecture that enables trustless, institutional-style governance. Instead of simple token voting, communities can design custom governance systems using "Mandates" — roles with code-enforced boundaries and degrees of freedom. Working groups can act quickly within predefined limits, while voters only need to approve the scope of a Mandate once rather than signing off on every action. It also supports cross-chain and off-chain workflows, and can assign constrained roles to AI agents.
          </p>
        </section>

        <section className="space-y-4 max-w-2xl mx-auto text-left" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
           <h2 className="text-xs tracking-widest opacity-50 uppercase">NEXT PHASE</h2>
          <p className="text-base leading-relaxed opacity-70">
            A forthcoming phase involves Simulation Sessions, where Participants may explore the governance architecture in an online setting. These sessions invite individuals with no prior experience of the protocol to engage with its components, allowing coordination, discussion, and decision-making to emerge through interaction. Rather than testing for performance or outcome, these sessions provide an opportunity to observe how Participants interpret and apply the available tools in real time.
          </p>
          <p className="text-base leading-relaxed opacity-70">
            It should be noted that this experiment is not deployed on Ethereum mainnet. It runs on the Sepolia testnet, and no legal structure currently exists around it. For this reason, the Simulation Sessions will be conducted through fictional stories — imagined scenarios, characters, and proposals that allow Participants to engage meaningfully with the governance architecture without binding real-world assets, identities, or obligations.
          </p>
        </section>

        <section className="space-y-6 max-w-2xl mx-auto text-left" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
          <h2 className="text-xs tracking-widest opacity-50 uppercase">Timeline</h2>
          <ul className="space-y-0">
            {[
              { date: "15th May 2026", title: "Simulation Session #1" },
              { date: "29th March 2026", title: "The www.enterhere.io site reappears following a previous iteration" },
              { date: "10th March 2026", title: "Code related to this experiment becomes available via a public repository on Github" },
              { date: "20th January 2025", title: "Initial technical exploration of the governance architecture begins to take form" },
              { date: "22nd December 2025", title: "A visual representation of the governance architecture begins to take form in FigJam" },
            ].map((item, i) => (
              <li
                key={i}
                className="grid grid-cols-[110px_1fr] gap-4 py-3 border-b border-foreground/15 last:border-b-0"
              >
                <span className="text-xs tracking-wider opacity-50 uppercase pt-0.5">{item.date}</span>
                <span className="text-sm leading-relaxed opacity-80">{item.title}</span>
              </li>
            ))}
          </ul>
        </section>

        <section className="space-y-4 max-w-2xl mx-auto text-left" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
          <h2 className="text-xs tracking-widest opacity-50 uppercase">Open Source on GitHub</h2>
          <p className="text-base leading-relaxed opacity-70">
            The codebase, smart contracts, and documentation supporting this experiment are openly available on GitHub. Hosting the work in a public repository allows Participants, developers, and observers to inspect the underlying logic, propose changes, and contribute to its ongoing development. Transparency at the level of code is treated here as part of the governance architecture itself — what cannot be read cannot be meaningfully consented to.
          </p>
          <a
            href="https://github.com/4-0-productions"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block text-xs tracking-widest px-3 py-1.5 bg-foreground text-background hover:opacity-80 transition-opacity"
          >
            VIEW ON GITHUB →
          </a>
        </section>

      </div>
    </Layout>
  );
};

export default Index;