import Layout from "@/components/Layout";
import { useNavigate } from "react-router-dom";
import doorImage from "@/assets/door.png";
import roleBadges from "@/assets/role-badges.png";

const DaoPortal = () => {
  const navigate = useNavigate();

  return (
    <Layout>
      <div className="space-y-10" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
        <header className="space-y-4 text-center max-w-2xl mx-auto">
          <h1 className="text-4xl font-bold tracking-tight md:text-4xl">
            Enter the forum via the Door...
          </h1>
          <p className="text-base opacity-70">
            Two ways to begin. Choose your entry point below.
          </p>
        </header>

        {/* Primary action cards */}
        <div className="grid gap-6 md:grid-cols-2 max-w-4xl mx-auto items-stretch">
          {/* Card 1 — Browse Ideas */}
          <div className="border border-foreground/20 p-8 flex flex-col items-center text-center">
            <div className="space-y-3 flex-grow">
              <h2 className="text-2xl font-bold">Step 1 — New here?</h2>
              <p className="text-base opacity-80">
                Browse the Idea Layers, choose one that interests you, and submit a short form. A member of that layer will review your application.
              </p>
            </div>
            <a
              href="/idea-layer"
              className="mt-6 bg-foreground text-background border-2 border-foreground px-8 py-4 text-base tracking-wider hover:opacity-80 transition-colors w-full md:w-auto"
            >
              → BROWSE IDEAS
            </a>
            <p className="mt-4 text-xs opacity-50">
              You may apply to more than one Idea Layer.
            </p>
          </div>

          {/* Card 2 — Go to Forum */}
          <div className="border border-foreground/20 p-8 flex flex-col items-center text-center">
            <div className="space-y-3 flex-grow">
              <h2 className="text-2xl font-bold">Step 2 — Already approved?</h2>
              <p className="text-base opacity-80">
                Step through the Door into the blockchain-integrated forum where conversation, proposals, and coordination unfold together.
              </p>
            </div>
            <div
              className="group relative mt-6 bg-foreground text-background border-2 border-foreground px-8 py-4 text-base tracking-wider w-full md:w-auto cursor-not-allowed select-none"
            >
              <span className="group-hover:invisible">→ GO TO FORUM</span>
              <span className="invisible group-hover:visible absolute inset-0 flex items-center justify-center">
                Stay tuned...
              </span>
            </div>
            <p className="mt-4 text-xs opacity-50">
              Opens the forum in a new tab.
            </p>
          </div>
        </div>

        {/* Supporting imagery and context */}
        <img
          src={doorImage}
          alt="Glowing doorway with silhouetted figures gathered before it"
          className="w-full h-auto max-w-3xl mx-auto"
        />

        <div className="max-w-2xl mx-auto space-y-4 text-center">
          <h2 className="text-2xl font-bold">A note before entering:</h2>
          <p className="leading-relaxed text-lg whitespace-pre-line">
            By proceeding, the Participants are choosing to engage with this space in their own capacity. All interaction remains voluntary. No organisation is entered, and no status is assumed; this is because at present, the experiment exists within a fictional scenario, as being deployed on Ethereum Sepolina (Sepolia is Ethereum’s primary public testnet, the default environment for smart contract and dApp testing) where no real financial assets are at stake. Once the system is debugged, participants may choose to deploy the structure on Ethereum's mainnet within the context of a real-life scenario.
          </p>
        </div>

        <figure className="space-y-2 max-w-2xl mx-auto">
          <div className="w-full overflow-hidden border border-foreground/15">
            <img
              src={roleBadges}
              alt="Rows of suspended name badges hanging in a softly lit space — representing the roles Participants take on within the experiment."
              className="w-full h-auto"
            />
          </div>
          <figcaption className="text-xs opacity-50 leading-relaxed text-center">
            Every Participant takes on a role. Choose an Idea Layer to step into.
          </figcaption>
        </figure>
      </div>
    </Layout>
  );
};

export default DaoPortal;
