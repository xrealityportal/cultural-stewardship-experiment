import { Link, useLocation } from "react-router-dom";


const navItems = [
{ path: "/", label: "ABOUT" },
 { path: "/door", label: "DOOR" },
  { path: "/sessions", label: "SESSIONS" },
 { path: "/garments", label: "GARMENTS" },
{ path: "/correspondence", label: "CORRESPONDENCE" }];


 const footerLinks = [
 { path: "/project", label: "ABOUT" },
  { path: "/correspondence", label: "CORRESPONDENCE" }];


const Layout = ({ children }: {children: React.ReactNode;}) => {
  const location = useLocation();

  return (
    <div className="min-h-screen flex flex-col text-center">
      <header className="border-b-2 border-foreground">
        <div className="container max-w-4xl py-6">
          <Link to="/" className="inline-block hover:opacity-60 transition-opacity">
            <video src="/videos/ascii-art-2.mp4" autoPlay loop muted playsInline className="max-w-[200px] mx-auto w-full" />
          </Link>
          <nav className="mt-4 flex gap-1 sm:gap-2 flex-nowrap justify-center" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
            {navItems.map((item) => <Link
              key={item.path}
              to={item.path}
              className={`text-[10px] sm:text-xs tracking-wider px-2 sm:px-3 py-1 sm:py-1.5 transition-opacity bg-foreground text-background hover:opacity-80 ${
              location.pathname === item.path ?
              "opacity-100" :
              "opacity-70"}`
              }>
                {item.label}
              </Link>
            )}
          </nav>
        </div>
      </header>

      <main className="flex-1 container max-w-4xl py-12">
        {children}
      </main>

      <footer className="border-t-2 border-foreground">
        <div className="container max-w-4xl py-6 space-y-3 flex flex-col items-center text-center">
          <div className="text-xs opacity-50" style={{ fontFamily: "'Times New Roman', Times, serif" }}>
            This work is shared under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
          </div>
        </div>
      </footer>
    </div>);

};

export default Layout;