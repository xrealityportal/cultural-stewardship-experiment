import Layout from "@/components/Layout";

const Events = () => {
  return (
    <Layout>
      <div className="space-y-8 max-w-2xl mx-auto" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
      <h1 className="text-4xl font-bold tracking-tight md:text-4xl">Upcoming...</h1>
        <div className="space-y-4">
          {[
             { title: "Simulation Session #1", date: "Stay tuned...", link: "" },
            { title: "Simulation Session #2", date: "Stay tuned...", link: "" },
            { title: "Simulation Session #3", date: "Stay tuned...", link: "" },
          ].map((event) => (
            <div key={event.title} className={`border border-foreground/20 p-6 ${event.date.includes("Stay tuned") ? "opacity-40" : "opacity-100"}`}>
              {event.link ? (
                <a href={event.link} target="_blank" rel="noopener noreferrer" className="block hover:opacity-70 transition-opacity">
                  <h2 className="text-sm tracking-widest uppercase">{event.title}</h2>
                  <p className="text-xs opacity-50 mt-2">{event.date}</p>
                </a>
              ) : (
                <>
                  <h2 className="text-sm tracking-widest uppercase">{event.title}</h2>
                  <p className="text-xs opacity-50 mt-2">{event.date}</p>
                </>
              )}
            </div>
          ))}
        </div>
      </div>
    </Layout>
  );
};

export default Events;
