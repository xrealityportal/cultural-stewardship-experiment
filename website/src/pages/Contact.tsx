import Layout from "@/components/Layout";

const Contact = () => {
  return (
    <Layout>
      <div className="space-y-10">
        <h1 className="text-4xl font-bold tracking-tight md:text-4xl">
         Correspondence
        </h1>

        <p className="text-sm opacity-50 tracking-wider max-w-xl mx-auto">This address is available for general correspondence.</p>

        <div className="space-y-6 max-w-xl mx-auto">
          <div className="border-2 border-foreground p-6 space-y-4">
            <div className="space-y-1">
              <p className="text-xs tracking-widest opacity-50">EMAIL</p>
              <a href="mailto:hello@enterhere.io" className="text-lg hover:opacity-60 transition-opacity border-b-2 border-foreground pb-1">
                hello@enterhere.io
              </a>
            </div>


          </div>
        </div>
      </div>
    </Layout>
  );
};

export default Contact;
