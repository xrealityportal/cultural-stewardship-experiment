import Layout from "@/components/Layout";
import tshirtImage from "@/assets/tshirt-participant.png";

const Garments = () => {
  return (
    <Layout>
      <div className="space-y-10 max-w-2xl mx-auto text-center" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
        <h1 className="text-4xl font-bold">The garment engineering department™ presents:</h1>
        <div className="space-y-6 pt-4">
          <img
            src={tshirtImage}
            alt="Participant T-shirt"
            className="w-full max-w-sm mx-auto aspect-square object-cover"
          />

          <div className="space-y-1">
            <h2 className="text-lg">T-Shirt</h2>
             <p className="text-sm opacity-60">x ​100 physical editions</p>
            <p className="text-sm opacity-80 pt-2">1 ETH</p>
          </div>

          <button
            type="button"
            disabled
            className="group relative inline-block text-xs tracking-widest px-4 py-2 bg-foreground text-background opacity-60 cursor-not-allowed"
          >
            <span className="invisible">BUY WITH ETHEREUM →</span>
            <span className="absolute inset-0 flex items-center justify-center group-hover:hidden">BUY WITH ETHEREUM →</span>
            <span className="absolute inset-0 hidden group-hover:flex items-center justify-center">Stay tuned...</span>
          </button>
        </div>
      </div>
    </Layout>
  );
};

export default Garments;