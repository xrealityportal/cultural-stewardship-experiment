import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import Index from "./pages/Index.tsx";
import ScrollToTop from "./components/ScrollToTop";

import Contact from "./pages/Contact.tsx";
import DaoPortal from "./pages/DaoPortal.tsx";
import Form from "./pages/Form.tsx";
import Events from "./pages/Events.tsx";
import PrimaryDao from "./pages/PrimaryDao.tsx";
import DigitalDao from "./pages/DigitalDao.tsx";
import IdeasDao from "./pages/IdeasDao.tsx";
import PhysicalDao from "./pages/PhysicalDao.tsx";
import Garments from "./pages/Garments.tsx";
import NotFound from "./pages/NotFound.tsx";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <ScrollToTop />
        <Routes>
          <Route path="/" element={<Index />} />
          
          <Route path="/correspondence" element={<Contact />} />
          <Route path="/door" element={<DaoPortal />} />
          <Route path="/form" element={<Form />} />
          <Route path="/sessions" element={<Events />} />
          <Route path="/primary-layer" element={<PrimaryDao />} />
          <Route path="/digital-layer" element={<DigitalDao />} />
          <Route path="/idea-layer" element={<IdeasDao />} />
          <Route path="/convergence-layer" element={<PhysicalDao />} />
          <Route path="/garments" element={<Garments />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
